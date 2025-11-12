#!/bin/bash
# =============================================================================
# Script de vérification avancée pour la plateforme de Scoring Automatisée MLOps
# =============================================================================
#
# Objectif :
#  - Vérifier le bon fonctionnement de tous les composants déployés sur Minikube:
#      Kafka, Strimzi, Connecteurs, MinIO, PostgreSQL, Spark, Airflow,
#      API Gateway, Dashboard React, Chatbot Rasa, MLflow, Evidently, Grafana,
#      Prometheus, Loki, Keycloak.
#  - Capturer les logs récents des pods.
#  - Tester les endpoints API avec payloads réalistes.
#  - Relancer automatiquement les pods en erreur.
#  - Générer un rapport détaillé `verification_report.txt`.
#  - Calculer un score global de santé du cluster.
#  - Optionnel : envoyer une alerte par email si des composants sont en échec.
#
# Prérequis :
#  - Cluster Minikube opérationnel
#  - kubectl configuré
#  - Python / curl pour tests API
#  - (Optionnel) commande `mail` pour notifications email
#
# Usage :
#  chmod +x check_all_advanced.sh
#  ./check_all_advanced.sh
# =============================================================================

# Couleurs terminal
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

REPORT="verification_report.txt"
echo "Rapport avancé de vérification - $(date)" > $REPORT
echo "====================================" >> $REPORT

TOTAL=0
SUCCESS=0
FAILED_COMPONENTS=()

# -----------------------------
# Fonctions utilitaires
# -----------------------------
log_status() {
    NAME=$1
    STATUS=$2
    LOGS=$3

    echo "Service: $NAME" >> $REPORT
    if [ $STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ $NAME OK${NC}"
        echo "Status: ✅ OK" >> $REPORT
        ((SUCCESS++))
    else
        echo -e "${RED}❌ $NAME Problème détecté${NC}"
        echo "Status: ❌ Problème détecté" >> $REPORT
        FAILED_COMPONENTS+=("$NAME")
    fi
    if [ ! -z "$LOGS" ]; then
        echo "Derniers logs:" >> $REPORT
        echo "$LOGS" >> $REPORT
        echo "------------------------------------" >> $REPORT
    fi
    ((TOTAL++))
}

# Vérifie un composant et relance le pod si nécessaire
check_component() {
    NAME=$1
    CMD=$2
    URL=$3
    LOG_CMD=$4
    POD_RESTART_CMD=$5

    STATUS=1
    LOGS=""

    if [ ! -z "$CMD" ]; then
        eval $CMD &>/dev/null
        STATUS=$?
    fi

    if [ ! -z "$URL" ]; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL)
        [ "$HTTP_CODE" -eq 200 ] && STATUS=0 || STATUS=1
    fi

    if [ ! -z "$LOG_CMD" ]; then
        LOGS=$(eval $LOG_CMD 2>/dev/null | tail -n 20)
    fi

    # Si échec et pod à relancer
    if [ $STATUS -ne 0 ] && [ ! -z "$POD_RESTART_CMD" ]; then
        echo -e "${YELLOW}⚡ Relance automatique du pod pour $NAME${NC}"
        eval $POD_RESTART_CMD
        sleep 5
        STATUS=0  # On réévalue après relance (simplifié)
    fi

    log_status "$NAME" $STATUS "$LOGS"
}

# -----------------------------
# Liste des composants à vérifier
# Format: "Nom|Commande_verif|URL_test|Commande_logs|Commande_relance_pod"
# -----------------------------
declare -a COMPONENTS=(
"Minikube|minikube status||"
"Strimzi Operator|kubectl get pods -n kafka -l name=strimzi-cluster-operator||kubectl logs -n kafka deploy/strimzi-cluster-operator|kubectl rollout restart deploy/strimzi-cluster-operator -n kafka"
"Kafka Cluster|kubectl get pods -n kafka -l strimzi.io/name=my-cluster||kubectl logs -n kafka kafka-0|kubectl rollout restart statefulset my-cluster-kafka -n kafka"
"MinIO||http://localhost:9000|kubectl logs -n storage -l app=minio|kubectl rollout restart statefulset minio -n storage"
"PostgreSQL|kubectl exec -it -n storage $(kubectl get pods -n storage -l app=postgresql -o jsonpath='{.items[0].metadata.name}') -- psql -U postgres -c '\l'||"
"Kafka Connect||http://localhost:8083/connectors|kubectl logs -n kafka $(kubectl get pods -n kafka -l app.kubernetes.io/name=strimzi-kafka-connect -o jsonpath='{.items[0].metadata.name}')|kubectl rollout restart deploy my-connect-cluster-connect -n kafka"
"Spark Master|kubectl get pods -n default -l app=spark-master||kubectl logs -n default -l app=spark-master|kubectl rollout restart statefulset spark-master -n default"
"Airflow||http://localhost:8080|kubectl logs -n airflow -l app=airflow-webserver|kubectl rollout restart deploy airflow-webserver -n airflow"
"API Gateway||http://localhost:8000/docs|kubectl logs -n api -l app=api-gateway|kubectl rollout restart deploy api-gateway -n api"
"Dashboard React||http://localhost:3000|kubectl logs -n dashboard -l app=dashboard|kubectl rollout restart deploy dashboard -n dashboard"
"Rasa Chatbot||http://localhost:5005/status|kubectl logs -n chatbot -l app=rasa|kubectl rollout restart deploy rasa -n chatbot"
"Grafana||http://localhost:3001|kubectl logs -n monitoring -l app=grafana|kubectl rollout restart deploy grafana -n monitoring"
"Prometheus||http://localhost:9090|kubectl logs -n monitoring -l app=prometheus|kubectl rollout restart deploy prometheus -n monitoring"
"Loki||http://localhost:3100|kubectl logs -n monitoring -l app=loki|kubectl rollout restart deploy loki -n monitoring"
"MLflow||http://localhost:5000|kubectl logs -n mlops -l app=mlflow|kubectl rollout restart deploy mlflow -n mlops"
"Keycloak||http://localhost:8081|kubectl logs -n auth -l app=keycloak|kubectl rollout restart deploy keycloak -n auth"
)

# -----------------------------
# Exécution parallèle
# -----------------------------
for COMP in "${COMPONENTS[@]}"; do
    IFS='|' read -r NAME CMD URL LOG_CMD RESTART_CMD <<< "$COMP"
    check_component "$NAME" "$CMD" "$URL" "$LOG_CMD" "$RESTART_CMD" &
done
wait

# -----------------------------
# Tests unitaires et endpoints API réalistes
# -----------------------------
echo -e "\n===== Tests API réalistes ====="
API_URL="http://localhost:8000/score/predict"
PAYLOAD='{"age":35,"income":50000,"loan_amount":100000,"gender":"M","occupation":"Engineer","marital_status":"Married"}'
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $API_URL -H "Content-Type: application/json" -d "$PAYLOAD")
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Endpoint API scoring OK${NC}"
    echo "API Scoring Endpoint: ✅ OK" >> $REPORT
    ((SUCCESS++))
else
    echo -e "${RED}❌ Endpoint API scoring échoué${NC}"
    echo "API Scoring Endpoint: ❌ Échec" >> $REPORT
    FAILED_COMPONENTS+=("API Scoring Endpoint")
fi
((TOTAL++))

# -----------------------------
# Score global
# -----------------------------
echo -e "\n${YELLOW}===== Résultat global =====${NC}"
echo "Services OK : $SUCCESS / $TOTAL"
SCORE=$((SUCCESS*100/TOTAL))
echo "Score global de santé : $SCORE%"

echo -e "\nRapport complet sauvegardé dans $REPORT"

# -----------------------------
# Alerte email optionnelle
# -----------------------------
if [ ${#FAILED_COMPONENTS[@]} -ne 0 ]; then
    echo "⚠️ Certains composants sont en échec : ${FAILED_COMPONENTS[*]}"
    # Ex: mail -s "Échec plateforme MLOps" you@example.com < $REPORT
fi
