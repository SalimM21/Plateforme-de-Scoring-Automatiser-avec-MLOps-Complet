# 🚀 **GUIDE D'INSTALLATION**

*MLOps Scoring Platform - Installation Complète et Déploiement Automatisé*

---

## 📋 **APERÇU**

Ce guide fournit des instructions détaillées pour installer et déployer la plateforme MLOps Scoring dans différents environnements : développement local, cloud, et production.

### **⏱️ Durée d'installation**
- **Local (Minikube)** : 30-45 minutes
- **Cloud (AWS/GCP/Azure)** : 45-60 minutes
- **Production** : 60-90 minutes

### **🎯 Prérequis**
- ✅ Kubernetes 1.24+
- ✅ Helm 3.8+
- ✅ Docker 20.10+
- ✅ Python 3.9+
- ✅ Terraform 1.0+ (pour cloud)
- ✅ 16GB RAM minimum
- ✅ 50GB stockage disponible

---

## 🏠 **INSTALLATION LOCALE (MINIKUBE)**

### **Étape 1 : Préparation Environnement**

```bash
# Installation Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Installation kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Installation Helm
curl https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Démarrage Minikube
minikube start --memory=8192 --cpus=4 --disk-size=50g
minikube addons enable ingress
minikube addons enable metrics-server
```

### **Étape 2 : Clonage Repository**

```bash
# Clonage repository
git clone https://github.com/your-org/mlops-scoring-platform.git
cd mlops-scoring-platform

# Initialisation submodules
git submodule update --init --recursive

# Configuration environnement
cp .env.example .env
# Éditer .env avec vos paramètres locaux
```

### **Étape 3 : Déploiement Automatisé**

```bash
# Déploiement complet avec Make
make deploy-local

# Ou déploiement étape par étape
make deploy-infrastructure
make deploy-database
make deploy-messaging
make deploy-ml-services
make deploy-monitoring
make deploy-platform
```

### **Étape 4 : Vérification Déploiement**

```bash
# Vérification pods
kubectl get pods --all-namespaces

# Vérification services
kubectl get svc --all-namespaces

# Test API
curl http://$(minikube ip)/api/v1/health

# Accès dashboard
minikube service scoring-dashboard
```

---

## ☁️ **INSTALLATION CLOUD (AWS)**

### **Étape 1 : Configuration AWS**

```bash
# Configuration AWS CLI
aws configure

# Création VPC et EKS cluster avec Terraform
cd infrastructure/aws
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply

# Configuration kubectl pour EKS
aws eks --region us-east-1 update-kubeconfig --name scoring-platform-cluster
```

### **Étape 2 : Configuration Infrastructure**

```bash
# Installation NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# Installation cert-manager pour SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml

# Installation ExternalDNS
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns
```

### **Étape 3 : Déploiement Base de Données**

```bash
# RDS PostgreSQL
cd infrastructure/aws/rds
terraform apply

# ElastiCache Redis
cd infrastructure/aws/elasticache
terraform apply

# MSK Kafka (optionnel)
cd infrastructure/aws/msk
terraform apply
```

### **Étape 4 : Déploiement Plateforme**

```bash
# Déploiement avec Helm
helm repo add scoring-platform https://charts.scoring-platform.com
helm install scoring-platform scoring-platform/scoring-platform \
  --values values-aws.yaml \
  --namespace scoring-platform \
  --create-namespace

# Configuration secrets
kubectl create secret generic app-secrets \
  --from-literal=database-url=$DATABASE_URL \
  --from-literal=redis-url=$REDIS_URL \
  --namespace scoring-platform
```

### **Étape 5 : Configuration DNS et SSL**

```bash
# Route53 configuration
cd infrastructure/aws/route53
terraform apply

# Let's Encrypt certificates
kubectl apply -f cert-manager/cluster-issuer.yaml
kubectl apply -f cert-manager/certificates.yaml
```

---

## 🏗️ **INSTALLATION PRODUCTION**

### **Étape 1 : Architecture Haute Disponibilité**

```yaml
# architecture-prod.yaml
global:
  environment: production
  region: us-east-1

infrastructure:
  kubernetes:
    version: "1.24"
    nodes:
      min: 3
      max: 10
    instance_type: "m5.large"

  database:
    postgresql:
      version: "14"
      instances: 2
      storage: 100Gi
    redis:
      version: "6"
      instances: 3
      storage: 50Gi

  messaging:
    kafka:
      version: "3.0"
      brokers: 3
      storage: 200Gi

  monitoring:
    prometheus:
      retention: 30d
      storage: 100Gi
    grafana:
      storage: 20Gi
    elk:
      elasticsearch:
        storage: 500Gi
```

### **Étape 2 : Déploiement Infrastructure**

```bash
# Infrastructure as Code
cd infrastructure/production
terraform workspace select production
terraform apply

# Configuration réseau
kubectl apply -f network-policies/
kubectl apply -f ingress/production-ingress.yaml
```

### **Étape 3 : Déploiement Services**

```bash
# Déploiement base de données
helm install postgresql ./helm/postgresql \
  --values values-production.yaml \
  --namespace database

# Déploiement Redis cluster
helm install redis ./helm/redis \
  --values values-production.yaml \
  --namespace database

# Déploiement Kafka
helm install kafka ./helm/kafka \
  --values values-production.yaml \
  --namespace messaging
```

### **Étape 4 : Déploiement Application**

```bash
# API Gateway
helm install api-gateway ./helm/api-gateway \
  --values values-production.yaml \
  --namespace platform

# Scoring API
helm install scoring-api ./helm/scoring-api \
  --values values-production.yaml \
  --namespace platform

# ML Services
helm install ml-services ./helm/ml-services \
  --values values-production.yaml \
  --namespace platform

# Feature Store
helm install feature-store ./helm/feature-store \
  --values values-production.yaml \
  --namespace platform
```

### **Étape 5 : Déploiement Monitoring**

```bash
# Prometheus Stack
helm install monitoring ./helm/monitoring \
  --values values-production.yaml \
  --namespace monitoring

# Logging Stack
helm install logging ./helm/logging \
  --values values-production.yaml \
  --namespace monitoring

# Alerting
kubectl apply -f alerting/production-alerts.yaml
```

### **Étape 6 : Configuration Sécurité**

```bash
# Network Policies
kubectl apply -f security/network-policies.yaml

# Pod Security Standards
kubectl apply -f security/pod-security-standards.yaml

# RBAC
kubectl apply -f security/rbac-production.yaml

# Secrets Management
kubectl apply -f security/external-secrets.yaml
```

---

## 🔧 **CONFIGURATION AVANCÉE**

### **Configuration Base de Données**

```yaml
# database-config.yaml
postgresql:
  image:
    tag: "14.2"
  auth:
    postgresPassword: "change-me"
    username: "scoring"
    password: "change-me"
    database: "scoring_db"

  primary:
    persistence:
      enabled: true
      size: 50Gi
      storageClass: "gp3"

    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
```

### **Configuration Redis**

```yaml
# redis-config.yaml
redis:
  architecture: standalone
  auth:
    enabled: true
    password: "change-me"

  master:
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "gp3"

    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
```

### **Configuration Kafka**

```yaml
# kafka-config.yaml
kafka:
  image:
    tag: "3.0.0"
  controller:
    replicaCount: 3

  brokers:
    replicaCount: 3
    persistence:
      enabled: true
      size: 50Gi
      storageClass: "gp3"

  metrics:
    kafka:
      enabled: true
    jmx:
      enabled: true
```

### **Configuration Monitoring**

```yaml
# monitoring-config.yaml
prometheus:
  server:
    retention: "30d"
    persistence:
      enabled: true
      size: 50Gi

  alertmanager:
    enabled: true
    persistence:
      enabled: true
      size: 10Gi

grafana:
  adminPassword: "change-me"
  persistence:
    enabled: true
    size: 10Gi

  datasources:
    prometheus:
      url: "http://prometheus-server"
    loki:
      url: "http://loki-gateway"
```

---

## 🧪 **TESTS POST-INSTALLATION**

### **Tests de Santé**

```bash
# Test santé générale
make health-check

# Test API endpoints
make test-api-endpoints

# Test base de données
make test-database-connection

# Test messaging
make test-kafka-connection
```

### **Tests de Performance**

```bash
# Test charge API
make performance-test-api

# Test charge base de données
make performance-test-database

# Test charge messaging
make performance-test-messaging
```

### **Tests de Sécurité**

```bash
# Scan vulnérabilités
make security-scan

# Test conformité
make compliance-test

# Audit configuration
make configuration-audit
```

---

## 🚨 **DÉPANNAGE**

### **Problèmes Courants**

#### **Pods en CrashLoopBackOff**
```bash
# Vérifier logs
kubectl logs -f <pod-name> -n <namespace>

# Vérifier événements
kubectl describe pod <pod-name> -n <namespace>

# Vérifier ressources
kubectl top pods -n <namespace>
```

#### **Services Non Accessibles**
```bash
# Vérifier services
kubectl get svc -n <namespace>

# Vérifier endpoints
kubectl get endpoints -n <namespace>

# Test connectivité
kubectl exec -it <pod-name> -n <namespace> -- curl <service-url>
```

#### **Problèmes Base de Données**
```bash
# Vérifier connexion
kubectl exec -it <db-pod> -n database -- psql -U scoring -d scoring_db

# Vérifier métriques
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Accéder à http://localhost:9090/targets
```

#### **Problèmes Réseau**
```bash
# Vérifier network policies
kubectl get networkpolicies -n <namespace>

# Test DNS resolution
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>

# Vérifier ingress
kubectl describe ingress -n <namespace>
```

### **Logs et Diagnostics**

```bash
# Collecte logs complète
make collect-logs

# Diagnostic système
make system-diagnostic

# Rapport santé
make health-report
```

---

## 📞 **SUPPORT ET MAINTENANCE**

### **Mises à Jour**

```bash
# Mise à jour plateforme
make update-platform

# Mise à jour infrastructure
make update-infrastructure

# Rollback en cas de problème
make rollback-deployment
```

### **Sauvegarde et Récupération**

```bash
# Sauvegarde complète
make backup-all

# Sauvegarde base de données
make backup-database

# Récupération
make restore-from-backup
```

### **Monitoring Continu**

```bash
# Dashboard monitoring
make open-monitoring-dashboard

# Alertes actives
make check-active-alerts

# Rapport performance
make performance-report
```

---

## 📋 **CHECKLIST POST-INSTALLATION**

- [ ] **Infrastructure**
  - [ ] Kubernetes cluster opérationnel
  - [ ] Services réseau configurés
  - [ ] Stockage persistant disponible
  - [ ] Secrets et configurations appliqués

- [ ] **Base de Données**
  - [ ] PostgreSQL accessible
  - [ ] Redis opérationnel
  - [ ] Schémas créés
  - [ ] Migrations appliquées

- [ ] **Messaging**
  - [ ] Kafka brokers opérationnels
  - [ ] Topics créés
  - [ ] Schema Registry configuré
  - [ ] Connecteurs déployés

- [ ] **Plateforme**
  - [ ] APIs déployées et accessibles
  - [ ] Services ML opérationnels
  - [ ] Feature Store configuré
  - [ ] Dashboard accessible

- [ ] **Monitoring**
  - [ ] Métriques collectées
  - [ ] Dashboards configurés
  - [ ] Alertes fonctionnelles
  - [ ] Logs agrégés

- [ ] **Sécurité**
  - [ ] Authentification configurée
  - [ ] Autorisation appliquée
  - [ ] Chiffrement activé
  - [ ] Conformité validée

- [ ] **Tests**
  - [ ] Tests unitaires réussis
  - [ ] Tests intégration passés
  - [ ] Tests performance validés
  - [ ] Tests sécurité conformes

---

**✅ Installation terminée avec succès !**

*Plateforme MLOps Scoring opérationnelle et prête pour la production*
*Automated Deployment • High Availability • Enterprise Security* 🚀