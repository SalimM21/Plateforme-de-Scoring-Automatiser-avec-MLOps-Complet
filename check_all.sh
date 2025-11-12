#!/bin/bash
# =============================================================================
# Script de vérification complète avec rapport : Plateforme de Scoring MLOps
# =============================================================================

# Couleurs terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

REPORT="verification_report.txt"
echo "Rapport de vérification - $(date)" > $REPORT
echo "====================================" >> $REPORT

check_service() {
  NAME=$1
  CMD=$2
  URL=$3

  echo -e "${YELLOW}Vérification: $NAME${NC}"
  echo "Service: $NAME" >> $REPORT
  if [ ! -z "$CMD" ]; then
    eval $CMD &>/dev/null
    STATUS=$?
  else
    STATUS=0
  fi

  if [ ! -z "$URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL)
    if [ "$HTTP_CODE" -eq 200 ]; then
      STATUS=0
    else
      STATUS=1
    fi
  fi

  if [ $STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "Status: ✅ OK" >> $REPORT
  else
    echo -e "${RED}❌ Problème détecté${NC}"
    echo "Status: ❌ Problème détecté" >> $REPORT
  fi
  echo "------------------------------------" >> $REPORT
}

# ================================
# 1. Cluster Minikube
# ================================
check_service "Minikube" "minikube status" ""

# ================================
# 2. Strimzi Operator
# ================================
check_service "Strimzi Operator" "kubectl get pods -n kafka -l name=strimzi-cluster-operator" ""

# ================================
# 3. Kafka Cluster
# ================================
check_service "Kafka Cluster" "kubectl get pods -n kafka -l strimzi.io/name=my-cluster" ""

# ================================
# 4. MinIO
# ================================
kubectl port-forward -n storage svc/minio 9000:9000 &>/dev/null &
MINIO_PID=$!
sleep 3
check_service "MinIO" "" "http://localhost:9000"
kill $MINIO_PID

# ================================
# 5. PostgreSQL
# ================================
POSTGRES_POD=$(kubectl get pods -n storage -l app=postgresql -o jsonpath='{.items[0].metadata.name}')
check_service "PostgreSQL" "kubectl exec -it -n storage $POSTGRES_POD -- psql -U postgres -c '\l'" ""

# ================================
# 6. Kafka Connect
# ================================
CONNECT_POD=$(kubectl get pods -n kafka -l app.kubernetes.io/name=strimzi-kafka-connect -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n kafka svc/kafka-connect 8083:8083 &>/dev/null &
CONNECT_PID=$!
sleep 3
check_service "Kafka Connect API" "" "http://localhost:8083/connectors"
kill $CONNECT_PID

# ================================
# 7. Spark
# ================================
SPARK_POD=$(kubectl get pods -n default -l app=spark-master -o jsonpath='{.items[0].metadata.name}')
check_service "Spark Master" "kubectl get pods -n default -l app=spark-master" ""

# ================================
# 8. Airflow
# ================================
kubectl port-forward -n airflow svc/airflow-webserver 8080:8080 &>/dev/null &
AIRFLOW_PID=$!
sleep 3
check_service "Airflow Webserver" "" "http://localhost:8080"
kill $AIRFLOW_PID

# ================================
# 9. API Gateway
# ================================
kubectl port-forward -n api svc/api-gateway 8000:8000 &>/dev/null &
API_PID=$!
sleep 3
check_service "API Gateway" "" "http://localhost:8000/docs"
kill $API_PID

# ================================
# 10. Dashboard React
# ================================
kubectl port-forward -n dashboard svc/dashboard 3000:3000 &>/dev/null &
DASH_PID=$!
sleep 3
check_service "Dashboard React" "" "http://localhost:3000"
kill $DASH_PID

# ================================
# 11. Rasa Chatbot
# ================================
RASA_POD=$(kubectl get pods -n chatbot -l app=rasa -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n chatbot svc/rasa 5005:5005 &>/dev/null &
RASA_PID=$!
sleep 3
check_service "Rasa Chatbot" "" "http://localhost:5005/status"
kill $RASA_PID

# ================================
# 12. Monitoring (Grafana / Prometheus / Loki)
# ================================
kubectl port-forward -n monitoring svc/grafana 3001:3000 &>/dev/null &
GRAF_PID=$!
sleep 3
check_service "Grafana" "" "http://localhost:3001"
kill $GRAF_PID

kubectl port-forward -n monitoring svc/prometheus 9090:9090 &>/dev/null &
PROM_PID=$!
sleep 3
check_service "Prometheus" "" "http://localhost:9090"
kill $PROM_PID

kubectl port-forward -n monitoring svc/loki 3100:3100 &>/dev/null &
LOKI_PID=$!
sleep 3
check_service "Loki" "" "http://localhost:3100"
kill $LOKI_PID

# ================================
# 13. MLflow
# ================================
kubectl port-forward -n mlops svc/mlflow 5000:5000 &>/dev/null &
MLFLOW_PID=$!
sleep 3
check_service "MLflow" "" "http://localhost:5000"
kill $MLFLOW_PID

# ================================
# 14. Keycloak
# ================================
kubectl port-forward -n auth svc/keycloak 8081:8080 &>/dev/null &
KEYCLOAK_PID=$!
sleep 3
check_service "Keycloak Admin" "" "http://localhost:8081"
kill $KEYCLOAK_PID

# ================================
# 15. Tests Unitaires
# ================================
pytest -v --maxfail=1 --disable-warnings -q
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les tests passent${NC}"
    echo "Tests: ✅ OK" >> $REPORT
else
    echo -e "${RED}❌ Certains tests ont échoué${NC}"
    echo "Tests: ❌ Problème détecté" >> $REPORT
fi

# ================================
# Résumé final
# ================================
echo -e "${YELLOW}\nRapport de vérification complet sauvegardé dans $REPORT${NC}"
cat $REPORT
