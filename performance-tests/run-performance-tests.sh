#!/bin/bash

# Script d'exécution des tests de performance
# Utilisation: ./run-performance-tests.sh [test-type] [environment]

set -e

# Configuration
TEST_TYPE=${1:-"load"}
ENVIRONMENT=${2:-"staging"}
DURATION=${3:-"300"}  # 5 minutes par défaut
USERS=${4:-"50"}

echo "🚀 TESTS DE PERFORMANCE - MLOps Scoring Platform"
echo "==============================================="
echo "Type: $TEST_TYPE"
echo "Environment: $ENVIRONMENT"
echo "Duration: $DURATION seconds"
echo "Users: $USERS"
echo ""

# Vérifier les prérequis
echo "1️⃣ Vérification des prérequis..."

if ! command -v locust &> /dev/null; then
    echo "❌ Locust n'est pas installé"
    echo "Installation: pip install locust"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️ jq n'est pas installé - rapports limités"
fi

echo "✅ Prérequis OK"

# Configuration selon l'environnement
echo "2️⃣ Configuration de l'environnement..."

case $ENVIRONMENT in
    "staging")
        BASE_URL="http://scoring-api-staging.example.com"
        FEAST_URL="http://feast-staging.example.com"
        ;;
    "production")
        BASE_URL="http://scoring-api.example.com"
        FEAST_URL="http://feast.example.com"
        ;;
    "local")
        # Démarrer les services locaux si nécessaire
        echo "Démarrage des services locaux..."

        # Port-forward pour les tests locaux
        kubectl port-forward svc/scoring-api-service 8000:8000 &
        PF1_PID=$!

        kubectl port-forward svc/feast-feature-server-service 6566:6566 &
        PF2_PID=$!

        kubectl port-forward svc/mlflow-service 5000:5000 &
        PF3_PID=$!

        sleep 5

        BASE_URL="http://localhost:8000"
        FEAST_URL="http://localhost:6566"
        ;;
    *)
        echo "❌ Environnement inconnu: $ENVIRONMENT"
        exit 1
        ;;
esac

echo "✅ Configuration OK"

# Configuration du test selon le type
echo "3️⃣ Configuration du test..."

case $TEST_TYPE in
    "smoke")
        USERS=5
        SPAWN_RATE=1
        DESCRIPTION="Smoke test - validation basique"
        ;;
    "load")
        USERS=50
        SPAWN_RATE=5
        DESCRIPTION="Load test - charge normale"
        ;;
    "stress")
        USERS=200
        SPAWN_RATE=10
        DESCRIPTION="Stress test - charge élevée"
        ;;
    "spike")
        USERS=500
        SPAWN_RATE=50
        DURATION=60
        DESCRIPTION="Spike test - pic de charge"
        ;;
    "endurance")
        USERS=30
        SPAWN_RATE=2
        DURATION=1800  # 30 minutes
        DESCRIPTION="Endurance test - charge prolongée"
        ;;
    "volume")
        USERS=20
        SPAWN_RATE=1
        DESCRIPTION="Volume test - gros volumes de données"
        ;;
    *)
        echo "❌ Type de test inconnu: $TEST_TYPE"
        echo "Types disponibles: smoke, load, stress, spike, endurance, volume"
        exit 1
        ;;
esac

echo "✅ Test configuré: $DESCRIPTION"

# Créer le répertoire de résultats
RESULTS_DIR="results/$(date +%Y%m%d_%H%M%S)_${TEST_TYPE}_${ENVIRONMENT}"
mkdir -p "$RESULTS_DIR"

echo "4️⃣ Exécution du test de performance..."

# Variables d'environnement pour Locust
export BASE_URL="$BASE_URL"
export FEAST_URL="$FEAST_URL"
export TEST_TYPE="$TEST_TYPE"
export ENVIRONMENT="$ENVIRONMENT"

# Exécuter Locust en mode headless
locust --headless \
       --users $USERS \
       --spawn-rate $SPAWN_RATE \
       --run-time ${DURATION}s \
       --host "$BASE_URL" \
       --csv "$RESULTS_DIR/results" \
       --logfile "$RESULTS_DIR/locust.log" \
       --html "$RESULTS_DIR/report.html"

echo "✅ Test exécuté"

# Nettoyer les port-forwards si locaux
if [ "$ENVIRONMENT" = "local" ]; then
    kill $PF1_PID $PF2_PID $PF3_PID 2>/dev/null || true
fi

# Analyse des résultats
echo "5️⃣ Analyse des résultats..."

if [ -f "$RESULTS_DIR/results_stats.csv" ]; then
    # Extraire les métriques principales
    STATS=$(tail -1 "$RESULTS_DIR/results_stats.csv")
    AVG_RESPONSE_TIME=$(echo $STATS | cut -d',' -f5)
    MEDIAN_RESPONSE_TIME=$(echo $STATS | cut -d',' -f6)
    REQUESTS_PER_SEC=$(echo $STATS | cut -d',' -f9)
    FAILURE_RATE=$(echo $STATS | cut -d',' -f13)

    echo "📊 RÉSULTATS PRINCIPAUX:"
    echo "   Temps de réponse moyen: ${AVG_RESPONSE_TIME}ms"
    echo "   Temps de réponse médian: ${MEDIAN_RESPONSE_TIME}ms"
    echo "   Requêtes/seconde: ${REQUESTS_PER_SEC}"
    echo "   Taux d'échec: ${FAILURE_RATE}%"

    # Évaluation des performances
    PERFORMANCE_STATUS="✅ BON"
    if (( $(echo "$AVG_RESPONSE_TIME > 2000" | bc -l 2>/dev/null || echo 1) )); then
        PERFORMANCE_STATUS="❌ MAUVAIS"
    elif (( $(echo "$AVG_RESPONSE_TIME > 1000" | bc -l 2>/dev/null || echo 0) )); then
        PERFORMANCE_STATUS="⚠️ ACCEPTABLE"
    fi

    RELIABILITY_STATUS="✅ BONNE"
    if (( $(echo "$FAILURE_RATE > 5" | bc -l 2>/dev/null || echo 0) )); then
        RELIABILITY_STATUS="❌ MAUVAISE"
    elif (( $(echo "$FAILURE_RATE > 1" | bc -l 2>/dev/null || echo 0) )); then
        RELIABILITY_STATUS="⚠️ ACCEPTABLE"
    fi

    echo ""
    echo "🎯 ÉVALUATION:"
    echo "   Performance: $PERFORMANCE_STATUS"
    echo "   Fiabilité: $RELIABILITY_STATUS"

else
    echo "❌ Fichier de résultats non trouvé"
fi

# Générer le rapport détaillé
echo "6️⃣ Génération du rapport..."

REPORT_FILE="$RESULTS_DIR/performance-report.md"

cat << EOF > "$REPORT_FILE"
# 📊 Rapport de Test de Performance

## 📋 Informations du Test
- **Date**: $(date)
- **Type**: $TEST_TYPE
- **Description**: $DESCRIPTION
- **Environnement**: $ENVIRONMENT
- **Durée**: ${DURATION} secondes
- **Utilisateurs**: $USERS
- **Taux de spawn**: $SPAWN_RATE users/sec

## 📊 Métriques Principales
- **Temps de réponse moyen**: ${AVG_RESPONSE_TIME:-N/A} ms
- **Temps de réponse médian**: ${MEDIAN_RESPONSE_TIME:-N/A} ms
- **Requêtes/seconde**: ${REQUESTS_PER_SEC:-N/A}
- **Taux d'échec**: ${FAILURE_RATE:-N/A}%

## 🎯 Évaluation
- **Performance**: $PERFORMANCE_STATUS
- **Fiabilité**: $RELIABILITY_STATUS

## 📈 Seuils de Référence
- **Temps de réponse**: < 1000ms (Excellent), < 2000ms (Bon), > 2000ms (À améliorer)
- **Taux d'échec**: < 1% (Excellent), < 5% (Bon), > 5% (À améliorer)
- **Throughput**: > 100 req/sec (Bon pour ce type d'application)

## 📁 Fichiers Générés
- \`results_stats.csv\`: Statistiques détaillées
- \`results_failures.csv\`: Échecs détaillés
- \`report.html\`: Rapport HTML complet
- \`locust.log\`: Logs d'exécution

## 🔍 Analyse Détaillée

### Distribution des Temps de Réponse
\`\`\`csv
$(head -1 "$RESULTS_DIR/results_stats.csv")
$(tail -1 "$RESULTS_DIR/results_stats.csv")
\`\`\`

### Recommandations
$(if (( $(echo "${AVG_RESPONSE_TIME:-0} > 2000" | bc -l 2>/dev/null || echo 0) )); then
  echo "- Optimiser les requêtes de base de données"
  echo "- Implémenter la mise en cache (Redis)"
  echo "- Réviser la configuration des ressources pods"
  echo "- Considérer l'ajout de réplicas"
else
  echo "- Performances dans les limites acceptables"
  echo "- Continuer le monitoring pour détecter les dégradations"
fi)

$(if (( $(echo "${FAILURE_RATE:-0} > 5" | bc -l 2>/dev/null || echo 0) )); then
  echo "- Investiguer les causes d'échec (logs applicatifs)"
  echo "- Vérifier la stabilité des services dépendants"
  echo "- Tester la résilience aux pannes"
else
  echo "- Taux d'erreur acceptable"
fi)

---
*Rapport généré automatiquement par le script de test de performance*
*MLOps Scoring Platform - $(date)*
EOF

echo "✅ Rapport généré: $REPORT_FILE"

# Sauvegarde des métriques pour monitoring
echo "7️⃣ Sauvegarde des métriques..."

METRICS_FILE="$RESULTS_DIR/metrics.json"
cat << EOF > "$METRICS_FILE"
{
  "test_info": {
    "type": "$TEST_TYPE",
    "environment": "$ENVIRONMENT",
    "timestamp": "$(date -Iseconds)",
    "duration_seconds": $DURATION,
    "users": $USERS,
    "spawn_rate": $SPAWN_RATE
  },
  "metrics": {
    "avg_response_time_ms": ${AVG_RESPONSE_TIME:-0},
    "median_response_time_ms": ${MEDIAN_RESPONSE_TIME:-0},
    "requests_per_second": ${REQUESTS_PER_SEC:-0},
    "failure_rate_percent": ${FAILURE_RATE:-0}
  },
  "evaluation": {
    "performance_status": "$PERFORMANCE_STATUS",
    "reliability_status": "$RELIABILITY_STATUS"
  }
}
EOF

echo "✅ Métriques sauvegardées"

# Nettoyage (optionnel)
echo "8️⃣ Nettoyage..."

# Supprimer les anciens résultats (garder les 10 derniers)
cd results
ls -t | tail -n +11 | xargs -r rm -rf
cd ..

echo ""
echo "🎉 TEST DE PERFORMANCE TERMINÉ"
echo "=============================="
echo "📁 Résultats: $RESULTS_DIR"
echo "📊 Rapport: $REPORT_FILE"
echo "📈 Métriques: $METRICS_FILE"
echo ""
echo "🔧 Commandes utiles:"
echo "   # Voir le rapport HTML"
echo "   open $RESULTS_DIR/report.html"
echo ""
echo "   # Analyser les métriques"
echo "   cat $METRICS_FILE | jq ."
echo ""
echo "   # Comparer avec les tests précédents"
echo "   ls -la results/"

echo ""
echo "📞 Prochaines étapes:"
echo "   1. Analyser les résultats détaillés"
echo "   2. Identifier les goulots d'étranglement"
echo "   3. Optimiser les performances si nécessaire"
echo "   4. Planifier les tests de régression"

echo ""
echo "🎯 Test de performance $TEST_TYPE terminé avec succès !"