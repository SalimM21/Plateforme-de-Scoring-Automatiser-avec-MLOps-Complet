#!/bin/bash
# =============================================================================
# Script de vérification complète : Plateforme de Scoring Automatisée avec MLOps
# Basé sur toutes les checklists et guides fournis
# =============================================================================

# Couleurs terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}=============================="
echo "1. Vérification Cluster Minikube"
echo "==============================${NC}"
minikube status
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -A

echo -e "${YELLOW}\n2. Vérification Strimzi / Kafka Operator"
echo "==============================${NC}"
helm list -n kafka
kubectl get pods -n kafka
kubectl get crd | grep kafka
kubectl logs -n kafka deploy/strimzi-cluster-operator --tail=20

echo -e "${YELLOW}\n3. Vérification Cluster Kafka"
echo "==============================${NC}"
kubectl get pods -n kafka
kubectl describe kafka my-cluster -n kafka
kubectl exec -it -n kafka kafka-0 -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

echo -e "${YELLOW}\n4. Vérification MinIO et PostgreSQL"
echo "==============================${NC}"
# MinIO
kubectl get pods -n storage -l app=minio
kubectl port-forward -n storage svc/minio 9000:9000 &>/dev/null &
MINIO_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9000
kill $MINIO_PID

# PostgreSQL
POSTGRES_POD=$(kubectl get pods -n storage -l app=postgresql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n storage $POSTGRES_POD -- psql -U postgres -c "\l"

echo -e "${YELLOW}\n5. Vérification Secrets & ConfigMaps"
echo "==============================${NC}"
kubectl get secrets -A
kubectl describe secret postgres-secret -n storage
kubectl get configmap -A

echo -e "${YELLOW}\n6. Vérification Kafka Connect & Connecteurs"
echo "==============================${NC}"
kubectl get pods -n kafka -l app.kubernetes.io/name=strimzi-kafka-connect
CONNECT_POD=$(kubectl get pods -n kafka -l app.kubernetes.io/name=strimzi-kafka-connect -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n kafka $CONNECT_POD --tail=20
kubectl port-forward -n kafka svc/kafka-connect 8083:8083 &>/dev/null &
CONNECT_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8083/connectors
kill $CONNECT_PID

echo -e "${YELLOW}\n7. Vérification Jobs Spark"
echo "==============================${NC}"
kubectl get pods -n default -l app=spark
SPARK_POD=$(kubectl get pods -n default -l app=spark-master -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n default $SPARK_POD --tail=20

echo -e "${YELLOW}\n8. Vérification Airflow"
echo "==============================${NC}"
kubectl get pods -n airflow
kubectl port-forward -n airflow svc/airflow-webserver 8080:8080 &>/dev/null &
AIRFLOW_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
kill $AIRFLOW_PID

echo -e "${YELLOW}\n9. Vérification API Gateway (FastAPI)"
echo "==============================${NC}"
kubectl get pods -n api -l app=api-gateway
kubectl logs -n api deploy/api-gateway --tail=20
kubectl port-forward -n api svc/api-gateway 8000:8000 &>/dev/null &
API_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/docs
kill $API_PID

echo -e "${YELLOW}\n10. Vérification Dashboard React"
echo "==============================${NC}"
kubectl get pods -n dashboard
kubectl port-forward -n dashboard svc/dashboard 3000:3000 &>/dev/null &
DASH_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000
kill $DASH_PID

echo -e "${YELLOW}\n11. Vérification Chatbot Rasa"
echo "==============================${NC}"
RASA_POD=$(kubectl get pods -n chatbot -l app=rasa -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n chatbot $RASA_POD --tail=20
kubectl port-forward -n chatbot svc/rasa 5005:5005 &>/dev/null &
RASA_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5005/status
kill $RASA_PID

echo -e "${YELLOW}\n12. Vérification Monitoring (Prometheus/Grafana/Loki)"
echo "==============================${NC}"
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/grafana 3001:3000 &>/dev/null &
GRAF_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3001
kill $GRAF_PID

kubectl port-forward -n monitoring svc/prometheus 9090:9090 &>/dev/null &
PROM_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9090
kill $PROM_PID

kubectl port-forward -n monitoring svc/loki 3100:3100 &>/dev/null &
LOKI_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3100
kill $LOKI_PID

echo -e "${YELLOW}\n13. Vérification MLOps (MLflow & Evidently)"
echo "==============================${NC}"
kubectl get pods -n mlops
kubectl port-forward -n mlops svc/mlflow 5000:5000 &>/dev/null &
MLFLOW_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5000
kill $MLFLOW_PID

kubectl port-forward -n mlops svc/evidently 8001:8001 &>/dev/null &
EVID_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8001
kill $EVID_PID

echo -e "${YELLOW}\n14. Vérification Authentification Keycloak"
echo "==============================${NC}"
kubectl get pods -n auth
kubectl port-forward -n auth svc/keycloak 8081:8080 &>/dev/null &
KEYCLOAK_PID=$!
sleep 3
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081
kill $KEYCLOAK_PID

echo -e "${YELLOW}\n15. Vérification Tests & CI/CD"
echo "==============================${NC}"
pytest -v --maxfail=1 --disable-warnings -q || echo -e "${RED}Certains tests ont échoué !${NC}"

echo -e "${GREEN}\n✅ Vérification complète terminée !"
echo "Vérifiez les codes HTTP (200 OK) et les logs pour chaque composant."
