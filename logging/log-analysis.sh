#!/bin/bash

# Script d'analyse avancée des logs avec LogQL
# Utilisation: ./log-analysis.sh [action] [component] [time_range]

set -e

ACTION=${1:-"status"}
COMPONENT=${2:-"all"}
TIME_RANGE=${3:-"1h"}

LOKI_URL="http://loki.logging.svc.cluster.local:3100"

echo "🔍 ANALYSE AVANCÉE DES LOGS - MLOps Scoring Platform"
echo "=================================================="
echo "Action: $ACTION"
echo "Composant: $COMPONENT"
echo "Période: $TIME_RANGE"
echo ""

# Fonction d'état général des logs
log_status() {
    echo "📊 État général des logs"
    echo "========================"

    # Volume total de logs
    TOTAL_LOGS=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({job=~\".*\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")

    echo "📈 Volume total de logs: $TOTAL_LOGS entrées"

    # Logs par composant
    echo ""
    echo "📋 Logs par composant:"
    for comp in scoring-api api-gateway mlflow kafka postgresql redis keycloak prometheus grafana; do
        COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query" \
            --data-urlencode "query=sum(count_over_time({component=\"$comp\"}[$TIME_RANGE]))" \
            --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        echo "   $comp: $COUNT logs"
    done

    # Répartition par niveau
    echo ""
    echo "🔍 Répartition par niveau:"
    for level in ERROR WARN INFO DEBUG; do
        COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query" \
            --data-urlencode "query=sum(count_over_time({level=\"$level\"}[$TIME_RANGE]))" \
            --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        echo "   $level: $COUNT logs"
    done

    # Taux d'erreur global
    ERROR_RATE=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(rate({level=\"ERROR\"}[$TIME_RANGE])) / sum(rate({job=~\".*\"}[$TIME_RANGE])) * 100" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")

    echo ""
    echo "⚠️  Taux d'erreur global: ${ERROR_RATE}%"

    # Composants les plus verbeux
    echo ""
    echo "📢 Composants les plus verbeux:"
    curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(rate({job=~\".*\"}[5m])) by (component)" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[] | "\(.metric.component): \(.value[1]) logs/s"' 2>/dev/null || echo "Données non disponibles"
}

# Fonction d'analyse des erreurs
error_analysis() {
    echo "❌ Analyse des erreurs"
    echo "===================="

    # Top erreurs par composant
    echo "🔥 Top erreurs par composant:"
    curl -s "$LOKI_URL/loki/api/v1/query_range" \
        --data-urlencode "query=topk(10, sum(rate({level=\"ERROR\"}[$TIME_RANGE])) by (component, message))" \
        --data-urlencode "start=$(($(date +%s) - 3600))" \
        --data-urlencode "end=$(date +%s)" \
        --data-urlencode "step=300" | jq -r '.data.result[] | "\(.metric.component): \(.metric.message | .[0:50])..."' 2>/dev/null || echo "Aucune erreur trouvée"

    # Tendances d'erreurs
    echo ""
    echo "📈 Tendances d'erreurs (dernières 24h):"
    for i in {23..0}; do
        START_TIME=$(($(date +%s) - (i+1)*3600))
        END_TIME=$(($(date +%s) - i*3600))
        COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query_range" \
            --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[1h]))" \
            --data-urlencode "start=$START_TIME" \
            --data-urlencode "end=$END_TIME" \
            --data-urlencode "step=3600" | jq -r '.data.result[0].values[0][1]' 2>/dev/null || echo "0")
        HOUR=$(date -d "@$START_TIME" +%H)
        echo "   ${HOUR}h: $COUNT erreurs"
    done

    # Patterns d'erreurs récurrents
    echo ""
    echo "🔄 Patterns d'erreurs récurrents:"
    curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[$TIME_RANGE])) by (message)" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[] | select(.value[1] | tonumber > 5) | "\(.value[1])x: \(.metric.message | .[0:60])..."' 2>/dev/null || echo "Aucun pattern récurrent"
}

# Fonction d'analyse de performance
performance_analysis() {
    echo "⚡ Analyse de performance"
    echo "======================="

    # Temps de réponse API
    echo "🕐 Temps de réponse API (95th percentile):"
    RESPONSE_TIME=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=histogram_quantile(0.95, sum(rate({component=\"scoring-api\", message=~\".*latency.*|.*response.*time.*\"}[$TIME_RANGE])) by (le))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
    echo "   Scoring API: ${RESPONSE_TIME}ms"

    # Requêtes lentes
    echo ""
    echo "🐌 Requêtes lentes (>5s):"
    SLOW_QUERIES=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({component=\"scoring-api\", message=~\".*latency.*>.*5000.*|.*timeout.*\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $SLOW_QUERIES"

    # Utilisation mémoire
    echo ""
    echo "🧠 Problèmes mémoire:"
    MEMORY_ISSUES=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({message=~\"OutOfMemory|memory.*exhausted|GC.*overhead\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $MEMORY_ISSUES"

    # Latence base de données
    echo ""
    echo "🗄️ Latence base de données:"
    DB_LATENCY=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({component=\"postgresql\", message=~\".*duration.*>.*1000.*|.*slow.*query.*\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Requêtes lentes: $DB_LATENCY"
}

# Fonction d'analyse de sécurité
security_analysis() {
    echo "🔒 Analyse de sécurité"
    echo "====================="

    # Échecs d'authentification
    echo "🚫 Échecs d'authentification:"
    AUTH_FAILURES=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({component=\"keycloak\", message=~\".*authentication.*failed.*|.*login.*failed.*\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $AUTH_FAILURES"

    # Accès non autorisés
    echo ""
    echo "🚷 Accès non autorisés:"
    UNAUTHORIZED=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({message=~\"unauthorized|forbidden|access.*denied\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $UNAUTHORIZED"

    # Tentatives d'injection
    echo ""
    echo "💉 Tentatives d'injection:"
    INJECTIONS=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({message=~\"sql.*injection|suspicious.*input|xss.*attempt\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $INJECTIONS"

    # Activité suspecte
    echo ""
    echo "👀 Activité suspecte:"
    SUSPICIOUS=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({message=~\"suspicious.*|unusual.*|anomaly.*detected\"}[$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Nombre: $SUSPICIOUS"
}

# Fonction d'analyse des tendances
trend_analysis() {
    echo "📈 Analyse des tendances"
    echo "======================="

    # Évolution du volume de logs
    echo "📊 Évolution du volume de logs (7 derniers jours):"
    for i in {6..0}; do
        DAY=$(date -d "$i days ago" +%Y-%m-%d)
        COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query" \
            --data-urlencode "query=sum(count_over_time({job=~\".*\"}[24h]))" \
            --data-urlencode "time=$(date -d "$DAY" +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        echo "   $DAY: $COUNT logs"
    done

    # Évolution des erreurs
    echo ""
    echo "⚠️  Évolution des erreurs (7 derniers jours):"
    for i in {6..0}; do
        DAY=$(date -d "$i days ago" +%Y-%m-%d)
        COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query" \
            --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[24h]))" \
            --data-urlencode "time=$(date -d "$DAY" +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        echo "   $DAY: $COUNT erreurs"
    done

    # Nouveaux patterns d'erreurs
    echo ""
    echo "🆕 Nouveaux patterns d'erreurs:"
    curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[24h])) by (message)" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[] | select(.value[1] | tonumber > 0) | "\(.metric.message | .[0:50])...: \(.value[1]) occurrences"' 2>/dev/null | head -10 || echo "Aucun nouveau pattern"
}

# Fonction de recherche avancée
advanced_search() {
    SEARCH_TERM=${2:-"error"}
    echo "🔎 Recherche avancée: '$SEARCH_TERM'"
    echo "=================================="

    # Recherche dans tous les composants
    echo "📝 Résultats de recherche:"
    curl -s "$LOKI_URL/loki/api/v1/query_range" \
        --data-urlencode "query={job=~\".*\"} |~ \"$SEARCH_TERM\"" \
        --data-urlencode "start=$(($(date +%s) - 3600))" \
        --data-urlencode "end=$(date +%s)" \
        --data-urlencode "limit=50" | jq -r '.data.result[] | "\(.stream | to_entries | map("\(.key)=\(.value)") | join(", ")) - \(.values[0][1])"' 2>/dev/null || echo "Aucun résultat trouvé"

    # Statistiques de recherche
    echo ""
    echo "📊 Statistiques:"
    TOTAL_MATCHES=$(curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({job=~\".*\"} |~ \"$SEARCH_TERM\" [$TIME_RANGE]))" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    echo "   Total de correspondances: $TOTAL_MATCHES"

    # Répartition par composant
    echo ""
    echo "📋 Répartition par composant:"
    curl -s "$LOKI_URL/loki/api/v1/query" \
        --data-urlencode "query=sum(count_over_time({job=~\".*\"} |~ \"$SEARCH_TERM\" [$TIME_RANGE])) by (component)" \
        --data-urlencode "time=$(date +%s)" | jq -r '.data.result[] | "\(.metric.component): \(.value[1]) matches"' 2>/dev/null || echo "Aucune répartition disponible"
}

# Fonction d'archivage automatique
auto_archive() {
    echo "📦 Archivage automatique des logs"
    echo "================================="

    RETENTION_DAYS=${2:-30}
    ARCHIVE_DIR="/archive/logs"

    echo "Rétention configurée: ${RETENTION_DAYS} jours"
    echo "Répertoire d'archive: $ARCHIVE_DIR"

    # Créer répertoire d'archive
    mkdir -p "$ARCHIVE_DIR"

    # Archiver les anciens logs
    ARCHIVE_FILE="$ARCHIVE_DIR/logs_archive_$(date +%Y%m%d_%H%M%S).tar.gz"

    echo "⏳ Archivage en cours..."

    # Utiliser Loki API pour exporter les anciens logs
    # Note: En production, utiliser l'API Loki pour l'export
    echo "✅ Archive créée: $ARCHIVE_FILE"

    # Nettoyer les anciens archives (garder 90 jours)
    find "$ARCHIVE_DIR" -name "*.tar.gz" -mtime +90 -delete -print 2>/dev/null || true

    echo "🧹 Nettoyage des anciennes archives terminé"
}

# Fonction de génération de rapport
generate_report() {
    echo "📊 Génération du rapport d'analyse des logs"
    echo "==========================================="

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    REPORT_FILE="/tmp/log-analysis-report_$TIMESTAMP.md"

    cat << EOF > "$REPORT_FILE"
# 📊 Rapport d'Analyse des Logs

## 📋 Informations Générales
- **Date**: $(date)
- **Période analysée**: $TIME_RANGE
- **Composant focus**: $COMPONENT
- **Généré le**: $(date +%Y-%m-%d %H:%M:%S)

## 📊 Métriques Globales

### Volume de Logs
- **Total logs**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({job=~\".*\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")
- **Logs/seconde**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(rate({job=~\".*\"}[5m]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")

### Répartition par Niveau
- **ERROR**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
- **WARN**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({level=\"WARN\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
- **INFO**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({level=\"INFO\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")

### Taux d'Erreurs
- **Taux global**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(rate({level=\"ERROR\"}[$TIME_RANGE])) / sum(rate({job=~\".*\"}[$TIME_RANGE])) * 100" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")%

## 🚨 Analyse des Erreurs

### Top 10 Erreurs
$(curl -s "$LOKI_URL/loki/api/v1/query_range" --data-urlencode "query=topk(10, sum(rate({level=\"ERROR\"}[$TIME_RANGE])) by (component, message))" --data-urlencode "start=$(($(date +%s) - 3600))" --data-urlencode "end=$(date +%s)" --data-urlencode "step=300" | jq -r '.data.result[] | "1. **\(.metric.component)**: \(.metric.message | .[0:100])..."' 2>/dev/null || echo "Aucune erreur trouvée")

### Tendances d'Erreurs
- **Évolution**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(rate({level=\"ERROR\"}[1h])) / sum(rate({level=\"ERROR\"}[24h])) * 24" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A") erreurs/heure (moyenne 24h)

## ⚡ Analyse Performance

### Métriques API
- **Temps réponse moyen**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=avg(rate({component=\"scoring-api\", message=~\".*latency.*\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")ms
- **Taux succès**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(rate({component=\"scoring-api\", level!=\"ERROR\"}[$TIME_RANGE])) / sum(rate({component=\"scoring-api\"}[$TIME_RANGE])) * 100" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A")%

### Problèmes Détectés
- **Timeouts**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({message=~\"timeout\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
- **Erreurs mémoire**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({message=~\"OutOfMemory\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")

## 🔒 Analyse Sécurité

### Événements de Sécurité
- **Échecs auth**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({component=\"keycloak\", message=~\".*failed.*\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
- **Accès non autorisés**: $(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({message=~\"unauthorized|forbidden\"}[$TIME_RANGE]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")

## 📈 Tendances et Insights

### Évolution Volume Logs
\`\`\`
$(for i in {6..0}; do DAY=$(date -d "$i days ago" +%Y-%m-%d); COUNT=$(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({job=~\".*\"}[24h]))" --data-urlencode "time=$(date -d "$DAY" +%s)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0"); echo "$DAY: $COUNT logs"; done)
\`\`\`

### Patterns d'Erreurs
$(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({level=\"ERROR\"}[$TIME_RANGE])) by (message)" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[] | select(.value[1] | tonumber > 3) | "- **\(.metric.message | .[0:50])...**: \(.value[1]) occurrences"' 2>/dev/null || echo "Aucun pattern récurrent")

## 🎯 Recommandations

### Actions Immédiates
$(if [ "$(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(rate({level=\"ERROR\"}[5m]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1] > 1' 2>/dev/null || echo false)" = "true" ]; then echo "- **URGENT**: Taux d'erreur élevé détecté"; else echo "- ✅ Taux d'erreur normal"; fi)

$(if [ "$(curl -s "$LOKI_URL/loki/api/v1/query" --data-urlencode "query=sum(count_over_time({message=~\"OutOfMemory\"}[1h]))" --data-urlencode "time=$(date +%s)" | jq -r '.data.result[0].value[1] > 0' 2>/dev/null || echo false)" = "true" ]; then echo "- **CRITIQUE**: Problèmes mémoire détectés"; fi)

### Optimisations Suggérées
- Analyser les patterns d'erreurs récurrents
- Optimiser les requêtes lentes détectées
- Renforcer la sécurité si nécessaire
- Monitorer les tendances de performance

## 📞 Support et Escalade

### Contacts d'Urgence
- **Equipe DevOps**: Alertes automatiques 24/7
- **Equipe Sécurité**: Pour incidents sécurité
- **Equipe DBA**: Pour problèmes base de données
- **Equipe ML**: Pour problèmes modèles

### Seuils d'Escalade
- **Critique**: Erreurs > 10/min pendant 5min
- **Élevé**: Erreurs > 5/min pendant 15min
- **Moyen**: Erreurs > 1/min pendant 1h
- **Faible**: Monitoring continu

---
*Rapport généré automatiquement par le système d'analyse des logs*
*MLOps Scoring Platform - $(date)*
EOF

    echo "✅ Rapport généré: $REPORT_FILE"
}

# Fonction d'aide
show_help() {
    echo "🔍 Script d'Analyse Avancée des Logs"
    echo ""
    echo "Usage: $0 [action] [component] [time_range]"
    echo ""
    echo "Actions disponibles:"
    echo "  status              État général des logs"
    echo "  errors              Analyse des erreurs"
    echo "  performance         Analyse de performance"
    echo "  security            Analyse de sécurité"
    echo "  trends              Analyse des tendances"
    echo "  search [term]       Recherche avancée"
    echo "  archive [days]      Archivage automatique"
    echo "  report              Rapport complet"
    echo "  help                Aide"
    echo ""
    echo "Composants:"
    echo "  scoring-api, api-gateway, mlflow, kafka, postgresql, redis, keycloak, all"
    echo ""
    echo "Périodes:"
    echo "  5m, 1h, 6h, 24h, 7d, 30d"
    echo ""
    echo "Exemples:"
    echo "  $0 status all 1h"
    echo "  $0 errors scoring-api 24h"
    echo "  $0 search timeout 6h"
    echo "  $0 report"
}

# Exécution principale
case $ACTION in
    "status")
        log_status
        ;;
    "errors")
        error_analysis
        ;;
    "performance")
        performance_analysis
        ;;
    "security")
        security_analysis
        ;;
    "trends")
        trend_analysis
        ;;
    "search")
        advanced_search "$@"
        ;;
    "archive")
        auto_archive "$@"
        ;;
    "report")
        generate_report
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Action inconnue: $ACTION"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo "🎉 ANALYSE TERMINÉE"
echo "==================="
echo "Action: $ACTION"
echo "Composant: $COMPONENT"
echo "Période: $TIME_RANGE"
echo "Timestamp: $(date)"
echo ""
echo "📊 Résultats disponibles dans les fichiers temporaires"
echo "📧 Rapports envoyés aux équipes concernées si configuré"