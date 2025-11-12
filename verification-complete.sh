#!/bin/bash

# Script de vérification complète de la plateforme MLOps
# Scoring Automatique avec KYC/GDPR

echo "=========================================="
echo "🔍 VÉRIFICATION COMPLÈTE PLATEFORME MLOPS"
echo "=========================================="

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Vérification de l'état des pods
log "Vérification des pods Kubernetes..."
kubectl get pods --all-namespaces -o wide | head -20

# 2. Vérification des services
log "Vérification des services..."
kubectl get svc -n default

# 3. Vérification Kafka
log "Vérification Kafka..."
if kubectl get pods -n kafka | grep -q "my-cluster-kafka"; then
    success "Kafka cluster opérationnel"
    kubectl get kafkatopics -n kafka
else
    error "Kafka cluster non opérationnel"
fi

# 4. Vérification des connecteurs Kafka
log "Vérification des connecteurs Kafka..."
kubectl get kafkaconnector -n kafka

# 5. Vérification MinIO
log "Vérification MinIO..."
if kubectl get pods -n storage | grep -q "minio"; then
    success "MinIO opérationnel"
else
    warning "MinIO non vérifié"
fi

# 6. Vérification PostgreSQL
log "Vérification PostgreSQL..."
if kubectl get pods -n storage | grep -q "postgresql"; then
    success "PostgreSQL opérationnel"
else
    warning "PostgreSQL non vérifié"
fi

# 7. Vérification des services MLOps
log "Vérification des services MLOps..."

# MLflow
if kubectl get pods -n default | grep -q "mlflow"; then
    success "MLflow déployé"
else
    warning "MLflow non déployé"
fi

# API Scoring
if kubectl get pods -n default | grep -q "scoring-api"; then
    success "API Scoring déployée"
else
    warning "API Scoring non déployée"
fi

# 8. Vérification des interfaces utilisateur
log "Vérification des interfaces utilisateur..."

# Dashboard
if kubectl get pods -n default | grep -q "dashboard"; then
    success "Dashboard déployé"
else
    warning "Dashboard non déployé"
fi

# API Gateway
if kubectl get pods -n default | grep -q "api-gateway"; then
    success "API Gateway déployé"
else
    warning "API Gateway non déployé"
fi

# Rasa
if kubectl get pods -n default | grep -q "rasa"; then
    success "Chatbot Rasa déployé"
else
    warning "Chatbot Rasa non déployé"
fi

# 9. Vérification du monitoring
log "Vérification du monitoring..."

# Prometheus
if kubectl get pods -n default | grep -q "prometheus"; then
    success "Prometheus déployé"
else
    warning "Prometheus non déployé"
fi

# Grafana
if kubectl get pods -n default | grep -q "grafana"; then
    success "Grafana déployé"
else
    warning "Grafana non déployé"
fi

# 10. Vérification de l'audit et compliance
log "Vérification de l'audit et compliance..."

# Audit Collector
if kubectl get pods -n default | grep -q "audit-collector"; then
    success "Audit Collector déployé"
else
    warning "Audit Collector non déployé"
fi

# GDPR Monitor
if kubectl get pods -n default | grep -q "gdpr-monitor"; then
    success "GDPR Monitor déployé"
else
    warning "GDPR Monitor non déployé"
fi

# AML Monitor
if kubectl get pods -n default | grep -q "aml-monitor"; then
    success "AML Monitor déployé"
else
    warning "AML Monitor non déployé"
fi

# 11. Vérification des ressources DLQ/Retry
log "Vérification DLQ/Retry..."

if kubectl get pods -n default | grep -q "dlq-retry-handler\|retry-manager"; then
    success "Services DLQ/Retry déployés"
else
    warning "Services DLQ/Retry non déployés"
fi

# 12. Test des endpoints (si disponibles)
log "Test des endpoints API..."

# Test MLflow
if kubectl get svc mlflow-service -n default &>/dev/null; then
    log "Test MLflow endpoint..."
    # Port forward temporaire pour test
    kubectl port-forward svc/mlflow-service 5000:5000 -n default &
    PORT_FORWARD_PID=$!
    sleep 3

    if curl -s http://localhost:5000 > /dev/null; then
        success "MLflow accessible"
    else
        warning "MLflow non accessible"
    fi

    kill $PORT_FORWARD_PID 2>/dev/null
fi

# 13. Vérification des topics Kafka
log "Vérification des topics Kafka..."
TOPICS=$(kubectl get kafkatopics -n kafka --no-headers 2>/dev/null | wc -l)
if [ "$TOPICS" -gt 0 ]; then
    success "$TOPICS topics Kafka créés"
    kubectl get kafkatopics -n kafka
else
    error "Aucun topic Kafka trouvé"
fi

# 14. Résumé final
echo ""
echo "=========================================="
echo "📊 RÉSUMÉ DE LA VÉRIFICATION"
echo "=========================================="

# Compter les services opérationnels
TOTAL_SERVICES=15
OPERATIONAL=$(kubectl get pods -n default --no-headers 2>/dev/null | grep -c "Running\|Completed")
KAFKA_SERVICES=$(kubectl get pods -n kafka --no-headers 2>/dev/null | grep -c "Running\|Completed")
STORAGE_SERVICES=$(kubectl get pods -n storage --no-headers 2>/dev/null | grep -c "Running\|Completed")

TOTAL_OPERATIONAL=$((OPERATIONAL + KAFKA_SERVICES + STORAGE_SERVICES))

echo "Services opérationnels: $TOTAL_OPERATIONAL / $TOTAL_SERVICES"
echo ""

if [ "$TOTAL_OPERATIONAL" -ge 10 ]; then
    success "PLATEFORME GLOBALE OPÉRATIONNELLE !"
    echo "🎉 La plateforme MLOps de scoring automatique est prête !"
else
    warning "PLATEFORME REQUIERT ATTENTION"
    echo "Quelques services nécessitent vérification ou déploiement."
fi

echo ""
echo "=========================================="
echo "💡 PROCHAINES ÉTAPES RECOMMANDÉES:"
echo "=========================================="
echo "1. Augmenter ressources Minikube si nécessaire:"
echo "   minikube start --memory=4096 --cpus=2"
echo ""
echo "2. Tester le pipeline complet:"
echo "   - Envoyer données test vers Kafka"
echo "   - Vérifier traitement Spark"
echo "   - Tester API scoring"
echo ""
echo "3. Configurer monitoring avancé:"
echo "   - Dashboards Grafana personnalisés"
echo "   - Alertes Prometheus"
echo ""
echo "4. Tests de charge et performance"
echo "=========================================="