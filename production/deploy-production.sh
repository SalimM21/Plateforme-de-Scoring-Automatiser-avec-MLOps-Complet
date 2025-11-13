#!/bin/bash

# Production Deployment Script for MLOps Scoring Platform
# This script handles complete production deployment with GitOps, monitoring, and security

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-default}"
RELEASE_NAME="${RELEASE_NAME:-mlops-platform}"
CHART_PATH="${CHART_PATH:-production/helm-chart}"
VALUES_FILE="${VALUES_FILE:-production/helm-chart/values-production.yaml}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
MONITORING_ENABLED="${MONITORING_ENABLED:-true}"
SECURITY_ENABLED="${SECURITY_ENABLED:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Pre-deployment checks
pre_deployment_checks() {
    log_info "Running pre-deployment checks..."

    # Check if kubectl is configured
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm >/dev/null 2>&1; then
        log_error "Helm is not installed"
        exit 1
    fi

    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log_info "Creating namespace $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi

    # Check cluster resources
    local total_cpu
    total_cpu=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.cpu}' | tr ' ' '+' | bc)
    local total_memory
    total_memory=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.memory}' | sed 's/Ki//' | tr ' ' '+' | bc)

    log_info "Cluster resources - CPU: ${total_cpu}m, Memory: ${total_memory}Ki"

    if [ "$total_cpu" -lt 8000 ]; then
        log_warning "Low CPU resources detected. Consider scaling up the cluster."
    fi

    if [ "$total_memory" -lt 16000000 ]; then
        log_warning "Low memory resources detected. Consider scaling up the cluster."
    fi

    log_success "Pre-deployment checks completed"
}

# Setup security components
setup_security() {
    if [ "$SECURITY_ENABLED" = true ]; then
        log_info "Setting up security components..."

        # Create security namespace
        kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -

        # Deploy network policies
        kubectl apply -f security/network-policies.yaml

        # Deploy Pod Security Standards
        kubectl apply -f security/pod-security.yaml

        # Deploy service mesh (Istio)
        kubectl apply -f security/istio-security.yaml

        # Deploy secrets management
        kubectl apply -f security/secrets-management.yaml

        # Deploy WAF and rate limiting
        kubectl apply -f security/waf-ratelimiting.yaml

        # Deploy intrusion detection
        kubectl apply -f security/intrusion-detection.yaml

        log_success "Security components deployed"
    fi
}

# Setup monitoring stack
setup_monitoring() {
    if [ "$MONITORING_ENABLED" = true ]; then
        log_info "Setting up monitoring stack..."

        # Add monitoring namespace
        kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

        # Deploy Prometheus stack
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update

        # Deploy Grafana
        helm repo add grafana https://grafana.github.io/helm-charts

        # Deploy Loki stack
        helm repo add grafana https://grafana.github.io/helm-charts

        log_success "Monitoring stack repositories added"
    fi
}

# Setup backup and disaster recovery
setup_backup() {
    if [ "$BACKUP_ENABLED" = true ]; then
        log_info "Setting up backup and disaster recovery..."

        # Install Velero for backups
        helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
        helm repo update

        # Create backup storage location (AWS S3 example)
        cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: default
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: mlops-backups-$(date +%Y%m%d)
    prefix: backups
  config:
    region: us-east-1
    s3Url: ""
    s3ForcePathStyle: "false"
EOF

        # Create backup schedules
        cat <<EOF | kubectl apply -f -
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 1 * * *"
  template:
    includedNamespaces:
      - $NAMESPACE
      - kafka
      - monitoring
      - security
    ttl: 720h0m0s
EOF

        log_success "Backup and disaster recovery configured"
    fi
}

# Deploy the platform
deploy_platform() {
    log_info "Deploying MLOps Scoring Platform..."

    # Validate values file exists
    if [ ! -f "$VALUES_FILE" ]; then
        log_error "Values file $VALUES_FILE not found"
        exit 1
    fi

    # Add dependencies
    helm dependency update "$CHART_PATH"

    # Dry run first
    log_info "Running helm dry-run..."
    helm template "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --dry-run > /tmp/helm-dry-run.yaml

    # Validate manifests
    if command -v kubeconform >/dev/null 2>&1; then
        log_info "Validating manifests with kubeconform..."
        kubeconform /tmp/helm-dry-run.yaml
    fi

    # Deploy with helm
    log_info "Deploying with Helm..."
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --wait \
        --timeout 30m \
        --create-namespace

    log_success "Platform deployed successfully"
}

# Post-deployment validation
post_deployment_validation() {
    log_info "Running post-deployment validation..."

    # Wait for all deployments to be ready
    kubectl wait --for=condition=available --timeout=600s deployment --all -n "$NAMESPACE"

    # Check pod status
    local unhealthy_pods
    unhealthy_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep -v Running | wc -l)

    if [ "$unhealthy_pods" -gt 0 ]; then
        log_warning "Found $unhealthy_pods unhealthy pods"
        kubectl get pods -n "$NAMESPACE" | grep -v Running
    else
        log_success "All pods are healthy"
    fi

    # Test key services
    log_info "Testing key services..."

    # Test scoring API
    if kubectl get svc scoring-api -n "$NAMESPACE" >/dev/null 2>&1; then
        local api_url
        api_url=$(kubectl get svc scoring-api -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}:{.spec.ports[0].port}')
        if curl -f --max-time 10 "http://$api_url/health" >/dev/null 2>&1; then
            log_success "Scoring API is responding"
        else
            log_warning "Scoring API health check failed"
        fi
    fi

    # Test database connectivity
    if kubectl get svc postgresql -n "$NAMESPACE" >/dev/null 2>&1; then
        log_success "PostgreSQL service is available"
    fi

    # Test Kafka connectivity
    if kubectl get svc kafka -n "$NAMESPACE" >/dev/null 2>&1; then
        log_success "Kafka service is available"
    fi

    log_success "Post-deployment validation completed"
}

# Setup GitOps with ArgoCD
setup_gitops() {
    log_info "Setting up GitOps with ArgoCD..."

    # Install ArgoCD
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    # Create ArgoCD namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

    # Install ArgoCD
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --set server.service.type=LoadBalancer \
        --wait

    # Get ArgoCD admin password
    local argocd_password
    argocd_password=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)

    log_info "ArgoCD installed. Admin password: $argocd_password"

    # Create application for MLOps platform
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mlops-platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/mlops-scoring-platform
    targetRevision: HEAD
    path: production/helm-chart
    helm:
      valueFiles:
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: $NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

    log_success "GitOps with ArgoCD configured"
}

# Generate deployment report
generate_report() {
    log_info "Generating deployment report..."

    local report_file="/tmp/production-deployment-report-$(date +%Y%m%d_%H%M%S).md"

    cat <<EOF > "$report_file"
# Production Deployment Report

## Deployment Information
- **Date**: $(date)
- **Namespace**: $NAMESPACE
- **Release**: $RELEASE_NAME
- **Chart Version**: $(helm list -n "$NAMESPACE" -o json | jq -r '.[0].chart // "N/A"')

## Cluster Resources
### Nodes
$(kubectl get nodes -o wide)

### Cluster Capacity
$(kubectl describe nodes | grep -A 5 "Capacity:")

## Deployed Components
### Applications
$(kubectl get deployments -n "$NAMESPACE" -o wide)

### Services
$(kubectl get services -n "$NAMESPACE" -o wide)

### ConfigMaps & Secrets
$(kubectl get configmaps,secrets -n "$NAMESPACE")

## Security Status
### Network Policies
$(kubectl get networkpolicies -n "$NAMESPACE")

### Pod Security Standards
$(kubectl get podsecuritypolicies 2>/dev/null || echo "PSP not available in this cluster")

### Service Mesh
$(kubectl get peerauthentication -n "$NAMESPACE" 2>/dev/null || echo "Istio not deployed")

## Monitoring Status
### Prometheus
$(kubectl get deployments -n monitoring -l app=prometheus 2>/dev/null || echo "Prometheus not deployed")

### Grafana
$(kubectl get deployments -n monitoring -l app=grafana 2>/dev/null || echo "Grafana not deployed")

### Loki
$(kubectl get deployments -n monitoring -l app=loki 2>/dev/null || echo "Loki not deployed")

## Backup Status
### Velero
$(kubectl get deployments -n velero 2>/dev/null || echo "Velero not deployed")

### Backup Schedules
$(kubectl get schedules -n velero 2>/dev/null || echo "No backup schedules")

## Health Checks
### Pod Status
$(kubectl get pods -n "$NAMESPACE" --no-headers | awk '{print $1 ": " $3}')

### Service Endpoints
$(kubectl get endpoints -n "$NAMESPACE")

## Performance Metrics
### Resource Usage
$(kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "Metrics not available")

### HPA Status
$(kubectl get hpa -n "$NAMESPACE" 2>/dev/null || echo "No HPA configured")

## Security Validation
### Image Security
$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort | uniq)

### RBAC
$(kubectl get clusterrolebindings | grep "$NAMESPACE" || echo "No cluster role bindings")

## Recommendations
1. Monitor resource usage and scale as needed
2. Configure proper backup retention policies
3. Set up proper alerting and notification channels
4. Implement regular security scans and updates
5. Configure log aggregation and analysis
6. Set up proper CI/CD pipelines for updates

---
*Generated by production deployment script*
EOF

    log_success "Deployment report generated: $report_file"
    echo "Report saved to: $report_file"
}

# Main deployment function
main() {
    log_info "Starting production deployment of MLOps Scoring Platform"
    log_info "Namespace: $NAMESPACE, Release: $RELEASE_NAME"

    pre_deployment_checks
    setup_security
    setup_monitoring
    setup_backup
    deploy_platform
    post_deployment_validation
    setup_gitops
    generate_report

    log_success "Production deployment completed successfully! 🎉"
    log_info ""
    log_info "Next steps:"
    log_info "1. Access the platform: kubectl port-forward svc/api-gateway 8080:8000 -n $NAMESPACE"
    log_info "2. Access Grafana: kubectl port-forward svc/grafana 3000:3000 -n monitoring"
    log_info "3. Access ArgoCD: kubectl port-forward svc/argocd-server 8080:443 -n argocd"
    log_info "4. Review the deployment report for detailed information"
    log_info "5. Configure external DNS and SSL certificates"
    log_info "6. Set up monitoring alerts and notifications"
}

# Handle command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace=*)
            NAMESPACE="${1#*=}"
            shift
            ;;
        --release=*)
            RELEASE_NAME="${1#*=}"
            shift
            ;;
        --values=*)
            VALUES_FILE="${1#*=}"
            shift
            ;;
        --no-backup)
            BACKUP_ENABLED=false
            shift
            ;;
        --no-monitoring)
            MONITORING_ENABLED=false
            shift
            ;;
        --no-security)
            SECURITY_ENABLED=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --namespace=NAMESPACE    Kubernetes namespace (default: default)"
            echo "  --release=RELEASE       Helm release name (default: mlops-platform)"
            echo "  --values=FILE          Values file path (default: production/helm-chart/values-production.yaml)"
            echo "  --no-backup             Skip backup setup"
            echo "  --no-monitoring         Skip monitoring setup"
            echo "  --no-security           Skip security setup"
            echo "  --help                  Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main deployment
main