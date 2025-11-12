#!/bin/bash
# =============================================================================
# Script de vérification complète de la plateforme de scoring automatisée avec MLOps
# Vérifie : Kubernetes, API, MLflow, Dashboard, Chatbot, Airflow, Monitoring, Logs
# =============================================================================

# Couleurs pour le terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}=============================="
echo "1. Vérification des pods Kubernetes"
echo "==============================${NC}"
kubectl get pods -A

echo -e "${YELLOW}\n2. Vérification des services Kubernetes"
echo "==============================${NC}"
kubectl get svc -A

echo -e "${YELLOW}\n3. Vérification des ingress"
echo "==============================${NC}"
kubectl get ingress -A

echo -e "${YELLOW}\n4. Vérification des PersistentVolumeClaims"
echo "==============================${NC}"
kubectl get pvc -A

echo -e "${YELLOW}\n5. Vérification API FastAPI (scoring)"
echo "==============================${NC}"
kubectl port-forward svc/api-scoring 8000:80 &>/dev/null &
API_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/docs
kill $API_PID

echo -e "${YELLOW}\n6. Vérification MLflow"
echo "==============================${NC}"
kubectl port-forward svc/mlflow 5000:5000 &>/dev/null &
MLFLOW_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5000
kill $MLFLOW_PID

echo -e "${YELLOW}\n7. Vérification Dashboard React"
echo "==============================${NC}"
kubectl port-forward svc/dashboard 3000:80 &>/dev/null &
DASH_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000
kill $DASH_PID

echo -e "${YELLOW}\n8. Vérification Chatbot Rasa"
echo "==============================${NC}"
kubectl logs deploy/chatbot-rasa --tail=10

echo -e "${YELLOW}\n9. Vérification Airflow"
echo "==============================${NC}"
kubectl port-forward svc/airflow-webserver 8080:8080 &>/dev/null &
AIRFLOW_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
kill $AIRFLOW_PID

echo -e "${YELLOW}\n10. Vérification Grafana / Prometheus / Loki"
echo "==============================${NC}"
kubectl port-forward svc/grafana 3000:3000 &>/dev/null &
GRAF_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000
kill $GRAF_PID

kubectl port-forward svc/prometheus 9090:9090 &>/dev/null &
PROM_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9090
kill $PROM_PID

kubectl port-forward svc/loki 3100:3100 &>/dev/null &
LOKI_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3100
kill $LOKI_PID

echo -e "${GREEN}\n✅ Vérification complète terminée !"
echo "Vérifiez les codes HTTP (200 OK) et les logs pour chaque composant."
