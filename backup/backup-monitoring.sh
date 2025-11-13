#!/bin/bash

# Script de monitoring des sauvegardes
# Utilisation: ./backup-monitoring.sh [action]

set -e

ACTION=${1:-"status"}

echo "📊 MONITORING SAUVEGARDES - MLOps Scoring Platform"
echo "================================================"

# Fonction d'état des sauvegardes
show_backup_status() {
    echo "📋 État des sauvegardes"
    echo "======================"

    # Espace de stockage
    if [ -d "/backup" ]; then
        TOTAL_SPACE=$(df -h /backup | tail -1 | awk '{print $2}')
        USED_SPACE=$(df -h /backup | tail -1 | awk '{print $3}')
        AVAILABLE_SPACE=$(df -h /backup | tail -1 | awk '{print $4}')
        USE_PERCENT=$(df -h /backup | tail -1 | awk '{print $5}')

        echo "💾 Espace de stockage:"
        echo "   Total: $TOTAL_SPACE"
        echo "   Utilisé: $USED_SPACE"
        echo "   Disponible: $AVAILABLE_SPACE"
        echo "   Utilisation: $USE_PERCENT"
        echo ""
    fi

    # PostgreSQL
    echo "🗄️ PostgreSQL:"
    PG_BACKUPS=$(ls -la /backup/scoring_db_*.sql.gz 2>/dev/null | wc -l)
    if [ "$PG_BACKUPS" -gt 0 ]; then
        LATEST_PG=$(ls -t /backup/scoring_db_*.sql.gz 2>/dev/null | head -1)
        LATEST_PG_DATE=$(stat -c %y "$LATEST_PG" 2>/dev/null | cut -d'.' -f1)
        LATEST_PG_SIZE=$(du -h "$LATEST_PG" 2>/dev/null | cut -f1)
        echo "   ✅ $PG_BACKUPS sauvegardes disponibles"
        echo "   📅 Dernière: $LATEST_PG_DATE"
        echo "   📏 Taille: $LATEST_PG_SIZE"
    else
        echo "   ❌ Aucune sauvegarde trouvée"
    fi
    echo ""

    # MinIO
    echo "📦 MinIO:"
    MINIO_BACKUPS=$(ls -la /backup/minio_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ "$MINIO_BACKUPS" -gt 0 ]; then
        LATEST_MINIO=$(ls -t /backup/minio_backup_*.tar.gz 2>/dev/null | head -1)
        LATEST_MINIO_DATE=$(stat -c %y "$LATEST_MINIO" 2>/dev/null | cut -d'.' -f1)
        LATEST_MINIO_SIZE=$(du -h "$LATEST_MINIO" 2>/dev/null | cut -f1)
        echo "   ✅ $MINIO_BACKUPS sauvegardes disponibles"
        echo "   📅 Dernière: $LATEST_MINIO_DATE"
        echo "   📏 Taille: $LATEST_MINIO_SIZE"
    else
        echo "   ❌ Aucune sauvegarde trouvée"
    fi
    echo ""

    # Feast
    echo "🎯 Feast:"
    FEAST_BACKUPS=$(ls -la /backup/feast_registry_*.tar.gz 2>/dev/null | wc -l)
    if [ "$FEAST_BACKUPS" -gt 0 ]; then
        LATEST_FEAST=$(ls -t /backup/feast_registry_*.tar.gz 2>/dev/null | head -1)
        LATEST_FEAST_DATE=$(stat -c %y "$LATEST_FEAST" 2>/dev/null | cut -d'.' -f1)
        LATEST_FEAST_SIZE=$(du -h "$LATEST_FEAST" 2>/dev/null | cut -f1)
        echo "   ✅ $FEAST_BACKUPS sauvegardes disponibles"
        echo "   📅 Dernière: $LATEST_FEAST_DATE"
        echo "   📏 Taille: $LATEST_FEAST_SIZE"
    else
        echo "   ❌ Aucune sauvegarde trouvée"
    fi
    echo ""

    # Kafka
    echo "📨 Kafka:"
    KAFKA_BACKUPS=$(ls -la /backup/kafka_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ "$KAFKA_BACKUPS" -gt 0 ]; then
        LATEST_KAFKA=$(ls -t /backup/kafka_backup_*.tar.gz 2>/dev/null | head -1)
        LATEST_KAFKA_DATE=$(stat -c %y "$LATEST_KAFKA" 2>/dev/null | cut -d'.' -f1)
        LATEST_KAFKA_SIZE=$(du -h "$LATEST_KAFKA" 2>/dev/null | cut -f1)
        echo "   ✅ $KAFKA_BACKUPS sauvegardes disponibles"
        echo "   📅 Dernière: $LATEST_KAFKA_DATE"
        echo "   📏 Taille: $LATEST_KAFKA_SIZE"
    else
        echo "   ❌ Aucune sauvegarde trouvée"
    fi
    echo ""

    # MLflow
    echo "🤖 MLflow:"
    MLFLOW_BACKUPS=$(ls -la /backup/mlflow_backup_*.tar.gz 2>/dev/null | wc -l)
    if [ "$MLFLOW_BACKUPS" -gt 0 ]; then
        LATEST_MLFLOW=$(ls -t /backup/mlflow_backup_*.tar.gz 2>/dev/null | head -1)
        LATEST_MLFLOW_DATE=$(stat -c %y "$LATEST_MLFLOW" 2>/dev/null | cut -d'.' -f1)
        LATEST_MLFLOW_SIZE=$(du -h "$LATEST_MLFLOW" 2>/dev/null | cut -f1)
        echo "   ✅ $MLFLOW_BACKUPS sauvegardes disponibles"
        echo "   📅 Dernière: $LATEST_MLFLOW_DATE"
        echo "   📏 Taille: $LATEST_MLFLOW_SIZE"
    else
        echo "   ❌ Aucune sauvegarde trouvée"
    fi
    echo ""

    # État des jobs Kubernetes
    echo "⚙️ État des jobs de sauvegarde:"
    kubectl get cronjobs -A 2>/dev/null | grep backup || echo "   Aucun job trouvé"
    echo ""

    # Alertes potentielles
    echo "🚨 Vérifications de santé:"

    # Vérifier l'âge des sauvegardes
    CURRENT_TIME=$(date +%s)
    PG_AGE=$((CURRENT_TIME - $(stat -c %Y "$LATEST_PG" 2>/dev/null || echo $CURRENT_TIME)))
    if [ $PG_AGE -gt 21600 ]; then  # 6 heures
        echo "   ⚠️  Sauvegarde PostgreSQL vieille (>6h)"
    else
        echo "   ✅ Sauvegarde PostgreSQL récente"
    fi

    # Vérifier l'espace disponible
    AVAILABLE_BYTES=$(df /backup 2>/dev/null | tail -1 | awk '{print $4}')
    if [ "$AVAILABLE_BYTES" -lt 1048576 ]; then  # 1GB
        echo "   ⚠️  Espace de stockage faible (<1GB)"
    else
        echo "   ✅ Espace de stockage suffisant"
    fi
}

# Fonction de nettoyage des anciennes sauvegardes
cleanup_old_backups() {
    echo "🧹 Nettoyage des anciennes sauvegardes"
    echo "===================================="

    RETENTION_DAYS=${2:-30}

    echo "Rétention configurée: ${RETENTION_DAYS} jours"
    echo ""

    COMPONENTS=("postgresql" "minio" "feast" "kafka" "mlflow")

    for component in "${COMPONENTS[@]}"; do
        echo "Nettoyage $component..."

        case $component in
            "postgresql")
                PATTERN="scoring_db_*.sql.gz"
                ;;
            "minio")
                PATTERN="minio_backup_*.tar.gz"
                ;;
            "feast")
                PATTERN="feast_registry_*.tar.gz"
                ;;
            "kafka")
                PATTERN="kafka_backup_*.tar.gz"
                ;;
            "mlflow")
                PATTERN="mlflow_backup_*.tar.gz"
                ;;
        esac

        DELETED=$(find /backup -name "$PATTERN" -mtime +$RETENTION_DAYS -delete -print 2>/dev/null | wc -l)
        REMAINING=$(ls /backup/${PATTERN} 2>/dev/null | wc -l)

        echo "   🗑️  Supprimé: $DELETED fichiers"
        echo "   📦 Conservé: $REMAINING fichiers"
        echo ""
    done

    # Nettoyer les fichiers de checksum orphelins
    find /backup -name "*.sha256" -exec sh -c 'test ! -f "${1%.sha256}" && echo "Suppression checksum orphelin: $1" && rm "$1"' _ {} \;

    echo "✅ Nettoyage terminé"
}

# Fonction de vérification d'intégrité
verify_integrity() {
    echo "🔍 Vérification d'intégrité des sauvegardes"
    echo "=========================================="

    INTEGRITY_OK=true
    TOTAL_FILES=0
    VALID_FILES=0

    for checksum_file in /backup/*.sha256; do
        if [ -f "$checksum_file" ]; then
            TOTAL_FILES=$((TOTAL_FILES + 1))
            backup_file="${checksum_file%.sha256}"

            if [ -f "$backup_file" ]; then
                EXPECTED_CHECKSUM=$(cut -d' ' -f1 "$checksum_file")
                ACTUAL_CHECKSUM=$(sha256sum "$backup_file" 2>/dev/null | cut -d' ' -f1)

                if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
                    echo "✅ $(basename $backup_file)"
                    VALID_FILES=$((VALID_FILES + 1))
                else
                    echo "❌ CORROMPU: $(basename $backup_file)"
                    INTEGRITY_OK=false
                fi
            else
                echo "⚠️  FICHIER MANQUANT: $(basename $backup_file)"
                INTEGRITY_OK=false
            fi
        fi
    done

    echo ""
    echo "📊 Résumé d'intégrité:"
    echo "   Total fichiers: $TOTAL_FILES"
    echo "   Fichiers valides: $VALID_FILES"
    echo "   Taux de succès: $((VALID_FILES * 100 / TOTAL_FILES))%"

    if [ "$INTEGRITY_OK" = true ]; then
        echo "✅ Toutes les sauvegardes sont intactes"
    else
        echo "❌ Problèmes d'intégrité détectés"
        exit 1
    fi
}

# Fonction de génération de rapport
generate_report() {
    echo "📊 Génération du rapport de sauvegarde"
    echo "====================================="

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    REPORT_FILE="/tmp/backup-report_$TIMESTAMP.md"

    cat << EOF > "$REPORT_FILE"
# 📊 Rapport de Monitoring des Sauvegardes

## 📋 Informations Générales
- **Date**: $(date)
- **Serveur**: $(hostname)
- **Répertoire**: /backup

## 💾 État du Stockage
\`\`\`
$(df -h /backup 2>/dev/null || echo "Stockage non disponible")
\`\`\`

## 📦 État des Sauvegardes par Composant

### PostgreSQL
- **Nombre de sauvegardes**: $(ls /backup/scoring_db_*.sql.gz 2>/dev/null | wc -l)
- **Dernière sauvegarde**: $(ls -t /backup/scoring_db_*.sql.gz 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d'.' -f1 || echo "N/A")
- **Taille totale**: $(du -sh /backup/scoring_db_*.sql.gz 2>/dev/null | cut -f1 || echo "0")

### MinIO
- **Nombre de sauvegardes**: $(ls /backup/minio_backup_*.tar.gz 2>/dev/null | wc -l)
- **Dernière sauvegarde**: $(ls -t /backup/minio_backup_*.tar.gz 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d'.' -f1 || echo "N/A")
- **Taille totale**: $(du -sh /backup/minio_backup_*.tar.gz 2>/dev/null | cut -f1 || echo "0")

### Feast
- **Nombre de sauvegardes**: $(ls /backup/feast_registry_*.tar.gz 2>/dev/null | wc -l)
- **Dernière sauvegarde**: $(ls -t /backup/feast_registry_*.tar.gz 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d'.' -f1 || echo "N/A")
- **Taille totale**: $(du -sh /backup/feast_registry_*.tar.gz 2>/dev/null | cut -f1 || echo "0")

### Kafka
- **Nombre de sauvegardes**: $(ls /backup/kafka_backup_*.tar.gz 2>/dev/null | wc -l)
- **Dernière sauvegarde**: $(ls -t /backup/kafka_backup_*.tar.gz 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d'.' -f1 || echo "N/A")
- **Taille totale**: $(du -sh /backup/kafka_backup_*.tar.gz 2>/dev/null | cut -f1 || echo "0")

### MLflow
- **Nombre de sauvegardes**: $(ls /backup/mlflow_backup_*.tar.gz 2>/dev/null | wc -l)
- **Dernière sauvegarde**: $(ls -t /backup/mlflow_backup_*.tar.gz 2>/dev/null | head -1 | xargs stat -c %y 2>/dev/null | cut -d'.' -f1 || echo "N/A")
- **Taille totale**: $(du -sh /backup/mlflow_backup_*.tar.gz 2>/dev/null | cut -f1 || echo "0")

## ⚙️ État des Jobs Kubernetes
\`\`\`
$(kubectl get cronjobs -A 2>/dev/null | grep backup || echo "Aucun job de sauvegarde trouvé")
\`\`\`

## 🚨 Alertes et Recommandations

EOF

    # Vérifications automatiques
    ALERTS=0

    # Vérifier l'âge des sauvegardes
    PG_AGE=$(($(date +%s) - $(stat -c %Y $(ls -t /backup/scoring_db_*.sql.gz 2>/dev/null | head -1) 2>/dev/null || echo $(date +%s))))
    if [ $PG_AGE -gt 21600 ]; then
        echo "- ⚠️ **Sauvegarde PostgreSQL vieille** (>6h)" >> "$REPORT_FILE"
        ALERTS=$((ALERTS + 1))
    fi

    # Vérifier l'espace disponible
    AVAILABLE_PERCENT=$(df /backup 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "${AVAILABLE_PERCENT:-0}" -gt 90 ]; then
        echo "- ⚠️ **Espace de stockage critique** (>90% utilisé)" >> "$REPORT_FILE"
        ALERTS=$((ALERTS + 1))
    fi

    # Vérifier l'intégrité
    if ! verify_integrity >/dev/null 2>&1; then
        echo "- ❌ **Problèmes d'intégrité détectés**" >> "$REPORT_FILE"
        ALERTS=$((ALERTS + 1))
    fi

    if [ $ALERTS -eq 0 ]; then
        echo "- ✅ **Aucune alerte active**" >> "$REPORT_FILE"
    fi

    cat << EOF >> "$REPORT_FILE"

## 📈 Métriques de Performance

### Fréquences de Sauvegarde
- **PostgreSQL**: Toutes les 6 heures
- **MinIO**: Quotidienne (2h)
- **Feast**: Toutes les 4 heures
- **Kafka**: Quotidienne (3h)
- **MLflow**: Quotidienne (4h)

### Rétention
- **PostgreSQL**: 7 jours
- **MinIO**: 30 jours
- **Feast**: 14 jours
- **Kafka**: 30 jours
- **MLflow**: 30 jours

### Objectifs RTO/RPO
- **RTO (Recovery Time Objective)**: < 1 heure
- **RPO (Recovery Point Objective)**: < 1 heure

## 🔧 Actions Recommandées

1. **Monitoring continu**: Vérifier régulièrement l'état des sauvegardes
2. **Tests de restauration**: Effectuer des tests périodiques
3. **Nettoyage automatique**: Configurer la rétention appropriée
4. **Alertes**: Mettre en place des notifications en cas de problème
5. **Documentation**: Maintenir les procédures de récupération à jour

## 📞 Contacts d'Urgence

- **Équipe DevOps**: Alertes automatiques via Slack
- **Support Base de données**: DBA Team
- **Support Infrastructure**: SRE Team

---
*Rapport généré automatiquement par le script de monitoring*
*MLOps Scoring Platform - $(date)*
EOF

    echo "📄 Rapport généré: $REPORT_FILE"
    echo "📧 Envoi du rapport par email..."
    # Ici on pourrait ajouter l'envoi par email
}

# Fonction d'aide
show_help() {
    echo "🔧 Script de Monitoring des Sauvegardes"
    echo ""
    echo "Usage: $0 [action] [options]"
    echo ""
    echo "Actions disponibles:"
    echo "  status              Afficher l'état des sauvegardes"
    echo "  cleanup [days]      Nettoyer les sauvegardes anciennes (défaut: 30 jours)"
    echo "  verify              Vérifier l'intégrité des sauvegardes"
    echo "  report              Générer un rapport complet"
    echo "  help                Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 status"
    echo "  $0 cleanup 15"
    echo "  $0 verify"
    echo "  $0 report"
}

# Exécution principale
case $ACTION in
    "status")
        show_backup_status
        ;;
    "cleanup")
        cleanup_old_backups "$@"
        ;;
    "verify")
        verify_integrity
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
echo "🎉 MONITORING TERMINÉ"
echo "===================="
echo "Action exécutée: $ACTION"
echo "Timestamp: $(date)"
echo ""
echo "📞 Pour plus d'informations:"
echo "   $0 help"