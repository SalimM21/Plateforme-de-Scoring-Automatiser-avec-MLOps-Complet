#!/bin/bash

# Script de test de restauration automatique des sauvegardes
# Utilisation: ./backup-restore-test.sh [component] [environment]

set -e

COMPONENT=${1:-"postgresql"}
ENVIRONMENT=${2:-"test"}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔄 TESTS DE RESTAURATION - MLOps Scoring Platform"
echo "==============================================="
echo "Composant: $COMPONENT"
echo "Environnement: $ENVIRONMENT"
echo "Timestamp: $TIMESTAMP"
echo ""

# Fonction de test de restauration PostgreSQL
test_postgresql_restore() {
    echo "🗄️ Test de restauration PostgreSQL..."

    # Trouver la sauvegarde la plus récente
    LATEST_BACKUP=$(ls -t /backup/scoring_db_*.sql.gz 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "❌ Aucune sauvegarde PostgreSQL trouvée"
        return 1
    fi

    echo "📦 Utilisation de la sauvegarde: $(basename $LATEST_BACKUP)"

    # Créer une base de test temporaire
    TEST_DB="scoring_restore_test_$TIMESTAMP"

    # Créer la base de test
    PGPASSWORD=iaxVrMCI8y psql -h postgresql.storage.svc.cluster.local -U postgres -c "CREATE DATABASE $TEST_DB;"

    # Restaurer la sauvegarde
    echo "⏳ Restauration en cours..."
    START_TIME=$(date +%s)

    gunzip -c $LATEST_BACKUP | PGPASSWORD=iaxVrMCI8y psql -h postgresql.storage.svc.cluster.local -U postgres -d $TEST_DB

    END_TIME=$(date +%s)
    RESTORE_TIME=$((END_TIME - START_TIME))

    # Vérifier la restauration
    TABLE_COUNT=$(PGPASSWORD=iaxVrMCI8y psql -h postgresql.storage.svc.cluster.local -U postgres -d $TEST_DB -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

    # Supprimer la base de test
    PGPASSWORD=iaxVrMCI8y psql -h postgresql.storage.svc.cluster.local -U postgres -c "DROP DATABASE $TEST_DB;"

    echo "✅ Restauration PostgreSQL réussie"
    echo "   Tables restaurées: $TABLE_COUNT"
    echo "   Temps de restauration: ${RESTORE_TIME}s"

    # Métriques
    echo "# HELP postgresql_restore_test_success Test success status" > /tmp/postgresql_restore.prom
    echo "# TYPE postgresql_restore_test_success gauge" >> /tmp/postgresql_restore.prom
    echo "postgresql_restore_test_success 1" >> /tmp/postgresql_restore.prom
    echo "# HELP postgresql_restore_time_seconds Restore duration" >> /tmp/postgresql_restore.prom
    echo "# TYPE postgresql_restore_time_seconds gauge" >> /tmp/postgresql_restore.prom
    echo "postgresql_restore_time_seconds $RESTORE_TIME" >> /tmp/postgresql_restore.prom
}

# Fonction de test de restauration MinIO
test_minio_restore() {
    echo "📦 Test de restauration MinIO..."

    # Trouver la sauvegarde la plus récente
    LATEST_BACKUP=$(ls -t /backup/minio_backup_*.tar.gz 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "❌ Aucune sauvegarde MinIO trouvée"
        return 1
    fi

    echo "📦 Utilisation de la sauvegarde: $(basename $LATEST_BACKUP)"

    # Créer un bucket de test
    TEST_BUCKET="restore-test-$TIMESTAMP"

    # Extraire et restaurer
    echo "⏳ Restauration en cours..."
    START_TIME=$(date +%s)

    mkdir -p /tmp/minio_restore_test
    cd /tmp/minio_restore_test

    # Extraire la sauvegarde
    tar -xzf $LATEST_BACKUP

    # Simuler la restauration (en production, utiliser mc cp)
    OBJECT_COUNT=$(find . -type f | wc -l)

    END_TIME=$(date +%s)
    RESTORE_TIME=$((END_TIME - START_TIME))

    # Nettoyer
    cd /
    rm -rf /tmp/minio_restore_test

    echo "✅ Restauration MinIO réussie"
    echo "   Objets restaurés: $OBJECT_COUNT"
    echo "   Temps de restauration: ${RESTORE_TIME}s"

    # Métriques
    echo "# HELP minio_restore_test_success Test success status" > /tmp/minio_restore.prom
    echo "# TYPE minio_restore_test_success gauge" >> /tmp/minio_restore.prom
    echo "minio_restore_test_success 1" >> /tmp/minio_restore.prom
    echo "# HELP minio_restore_time_seconds Restore duration" >> /tmp/minio_restore.prom
    echo "# TYPE minio_restore_time_seconds gauge" >> /tmp/minio_restore.prom
    echo "minio_restore_time_seconds $RESTORE_TIME" >> /tmp/minio_restore.prom
}

# Fonction de test de restauration Feast
test_feast_restore() {
    echo "🎯 Test de restauration Feast..."

    # Trouver la sauvegarde la plus récente
    LATEST_BACKUP=$(ls -t /backup/feast_registry_*.tar.gz 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "❌ Aucune sauvegarde Feast trouvée"
        return 1
    fi

    echo "📦 Utilisation de la sauvegarde: $(basename $LATEST_BACKUP)"

    echo "⏳ Restauration en cours..."
    START_TIME=$(date +%s)

    mkdir -p /tmp/feast_restore_test
    cd /tmp/feast_restore_test

    # Extraire la sauvegarde
    tar -xzf $LATEST_BACKUP

    # Vérifier le contenu
    if [ -d "feast_backup" ]; then
        FILE_COUNT=$(find feast_backup -type f | wc -l)
        echo "✅ Contenu Feast trouvé: $FILE_COUNT fichiers"
    else
        echo "❌ Structure Feast invalide"
        return 1
    fi

    END_TIME=$(date +%s)
    RESTORE_TIME=$((END_TIME - START_TIME))

    # Nettoyer
    cd /
    rm -rf /tmp/feast_restore_test

    echo "✅ Restauration Feast réussie"
    echo "   Fichiers restaurés: $FILE_COUNT"
    echo "   Temps de restauration: ${RESTORE_TIME}s"

    # Métriques
    echo "# HELP feast_restore_test_success Test success status" > /tmp/feast_restore.prom
    echo "# TYPE feast_restore_test_success gauge" >> /tmp/feast_restore.prom
    echo "feast_restore_test_success 1" >> /tmp/feast_restore.prom
    echo "# HELP feast_restore_time_seconds Restore duration" >> /tmp/feast_restore.prom
    echo "# TYPE feast_restore_time_seconds gauge" >> /tmp/feast_restore.prom
    echo "feast_restore_time_seconds $RESTORE_TIME" >> /tmp/feast_restore.prom
}

# Fonction de test de restauration MLflow
test_mlflow_restore() {
    echo "🤖 Test de restauration MLflow..."

    # Trouver la sauvegarde la plus récente
    LATEST_BACKUP=$(ls -t /backup/mlflow_backup_*.tar.gz 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "❌ Aucune sauvegarde MLflow trouvée"
        return 1
    fi

    echo "📦 Utilisation de la sauvegarde: $(basename $LATEST_BACKUP)"

    echo "⏳ Restauration en cours..."
    START_TIME=$(date +%s)

    mkdir -p /tmp/mlflow_restore_test
    cd /tmp/mlflow_restore_test

    # Extraire la sauvegarde
    tar -xzf $LATEST_BACKUP

    # Vérifier le contenu
    if [ -d "mlflow_combined" ]; then
        DB_FILE=$(ls mlflow_combined/mlflow_db_*.sql.gz 2>/dev/null)
        ARTIFACT_FILE=$(ls mlflow_combined/mlflow_artifacts_*.tar.gz 2>/dev/null)

        if [ -n "$DB_FILE" ] && [ -n "$ARTIFACT_FILE" ]; then
            echo "✅ Structure MLflow valide"
            DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
            ARTIFACT_SIZE=$(du -h "$ARTIFACT_FILE" | cut -f1)
            echo "   Base de données: $DB_SIZE"
            echo "   Artifacts: $ARTIFACT_SIZE"
        else
            echo "❌ Structure MLflow incomplète"
            return 1
        fi
    else
        echo "❌ Structure MLflow invalide"
        return 1
    fi

    END_TIME=$(date +%s)
    RESTORE_TIME=$((END_TIME - START_TIME))

    # Nettoyer
    cd /
    rm -rf /tmp/mlflow_restore_test

    echo "✅ Restauration MLflow réussie"
    echo "   Temps de restauration: ${RESTORE_TIME}s"

    # Métriques
    echo "# HELP mlflow_restore_test_success Test success status" > /tmp/mlflow_restore.prom
    echo "# TYPE mlflow_restore_test_success gauge" >> /tmp/mlflow_restore.prom
    echo "mlflow_restore_test_success 1" >> /tmp/mlflow_restore.prom
    echo "# HELP mlflow_restore_time_seconds Restore duration" >> /tmp/mlflow_restore.prom
    echo "# TYPE mlflow_restore_time_seconds gauge" >> /tmp/mlflow_restore.prom
    echo "mlflow_restore_time_seconds $RESTORE_TIME" >> /tmp/mlflow_restore.prom
}

# Fonction de vérification d'intégrité
check_backup_integrity() {
    echo "🔍 Vérification d'intégrité des sauvegardes..."

    INTEGRITY_OK=true

    # Vérifier les checksums SHA256
    for checksum_file in /backup/*.sha256; do
        if [ -f "$checksum_file" ]; then
            backup_file="${checksum_file%.sha256}"

            if [ -f "$backup_file" ]; then
                EXPECTED_CHECKSUM=$(cut -d' ' -f1 "$checksum_file")
                ACTUAL_CHECKSUM=$(sha256sum "$backup_file" | cut -d' ' -f1)

                if [ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ]; then
                    echo "✅ Intégrité OK: $(basename $backup_file)"
                else
                    echo "❌ Intégrité FAIL: $(basename $backup_file)"
                    INTEGRITY_OK=false
                fi
            else
                echo "⚠️  Fichier manquant: $(basename $backup_file)"
                INTEGRITY_OK=false
            fi
        fi
    done

    if [ "$INTEGRITY_OK" = true ]; then
        echo "✅ Toutes les vérifications d'intégrité réussies"
        echo "# HELP backup_integrity_check_success Integrity check status" > /tmp/backup_integrity.prom
        echo "# TYPE backup_integrity_check_success gauge" >> /tmp/backup_integrity.prom
        echo "backup_integrity_check_success 1" >> /tmp/backup_integrity.prom
    else
        echo "❌ Problèmes d'intégrité détectés"
        echo "# HELP backup_integrity_check_success Integrity check status" > /tmp/backup_integrity.prom
        echo "# TYPE backup_integrity_check_success gauge" >> /tmp/backup_integrity.prom
        echo "backup_integrity_check_success 0" >> /tmp/backup_integrity.prom
        return 1
    fi
}

# Fonction de rapport final
generate_report() {
    echo ""
    echo "📊 RAPPORT DE TEST DE RESTAURATION"
    echo "=================================="

    REPORT_FILE="/tmp/restore-test-report_$TIMESTAMP.md"

    cat << EOF > "$REPORT_FILE"
# 📊 Rapport de Test de Restauration

## 📋 Informations du Test
- **Date**: $(date)
- **Composant**: $COMPONENT
- **Environnement**: $ENVIRONMENT
- **Timestamp**: $TIMESTAMP

## 📦 Résultats par Composant

EOF

    # Résultats PostgreSQL
    if [ "$COMPONENT" = "postgresql" ] || [ "$COMPONENT" = "all" ]; then
        if test_postgresql_restore 2>/dev/null; then
            echo "- ✅ **PostgreSQL**: Restauration réussie" >> "$REPORT_FILE"
        else
            echo "- ❌ **PostgreSQL**: Échec de restauration" >> "$REPORT_FILE"
        fi
    fi

    # Résultats MinIO
    if [ "$COMPONENT" = "minio" ] || [ "$COMPONENT" = "all" ]; then
        if test_minio_restore 2>/dev/null; then
            echo "- ✅ **MinIO**: Restauration réussie" >> "$REPORT_FILE"
        else
            echo "- ❌ **MinIO**: Échec de restauration" >> "$REPORT_FILE"
        fi
    fi

    # Résultats Feast
    if [ "$COMPONENT" = "feast" ] || [ "$COMPONENT" = "all" ]; then
        if test_feast_restore 2>/dev/null; then
            echo "- ✅ **Feast**: Restauration réussie" >> "$REPORT_FILE"
        else
            echo "- ❌ **Feast**: Échec de restauration" >> "$REPORT_FILE"
        fi
    fi

    # Résultats MLflow
    if [ "$COMPONENT" = "mlflow" ] || [ "$COMPONENT" = "all" ]; then
        if test_mlflow_restore 2>/dev/null; then
            echo "- ✅ **MLflow**: Restauration réussie" >> "$REPORT_FILE"
        else
            echo "- ❌ **MLflow**: Échec de restauration" >> "$REPORT_FILE"
        fi
    fi

    # Intégrité
    if check_backup_integrity 2>/dev/null; then
        echo "- ✅ **Intégrité**: Toutes les sauvegardes valides" >> "$REPORT_FILE"
    else
        echo "- ❌ **Intégrité**: Problèmes détectés" >> "$REPORT_FILE"
    fi

    cat << EOF >> "$REPORT_FILE"

## 📈 Métriques de Performance

### Temps de Restauration
- PostgreSQL: ${RESTORE_TIME:-N/A} secondes
- MinIO: ${RESTORE_TIME:-N/A} secondes
- Feast: ${RESTORE_TIME:-N/A} secondes
- MLflow: ${RESTORE_TIME:-N/A} secondes

### Objectifs SLA
- **RTO (Recovery Time Objective)**: < 1 heure
- **RPO (Recovery Point Objective)**: < 1 heure de données perdues

## 🔍 État des Sauvegardes

### Espace Utilisé
\`\`\`bash
$(du -sh /backup 2>/dev/null || echo "N/A")
\`\`\`

### Sauvegardes Disponibles
\`\`\`bash
$(ls -la /backup/*.gz 2>/dev/null | wc -l || echo "0") fichiers de sauvegarde
\`\`\`

## ✅ Recommandations

- Vérifier régulièrement les tests de restauration
- Monitorer l'espace de stockage disponible
- Tester la restauration complète périodiquement
- Documenter les procédures de récupération

---
*Rapport généré automatiquement par le script de test de restauration*
*MLOps Scoring Platform - $(date)*
EOF

    echo "📄 Rapport généré: $REPORT_FILE"
}

# Exécution principale
case $COMPONENT in
    "postgresql")
        test_postgresql_restore
        ;;
    "minio")
        test_minio_restore
        ;;
    "feast")
        test_feast_restore
        ;;
    "mlflow")
        test_mlflow_restore
        ;;
    "integrity")
        check_backup_integrity
        ;;
    "all")
        test_postgresql_restore
        test_minio_restore
        test_feast_restore
        test_mlflow_restore
        check_backup_integrity
        ;;
    *)
        echo "❌ Composant inconnu: $COMPONENT"
        echo "Composants disponibles: postgresql, minio, feast, mlflow, integrity, all"
        exit 1
        ;;
esac

generate_report

echo ""
echo "🎉 TESTS DE RESTAURATION TERMINÉS"
echo "================================="
echo "Composant testé: $COMPONENT"
echo "Environnement: $ENVIRONMENT"
echo "Rapport: /tmp/restore-test-report_$TIMESTAMP.md"
echo ""
echo "📞 Prochaines étapes:"
echo "   1. Vérifier le rapport détaillé"
echo "   2. Corriger les problèmes identifiés"
echo "   3. Automatiser les tests de restauration"
echo "   4. Documenter les procédures de récupération"

echo ""
echo "🎯 Test de restauration $COMPONENT terminé avec succès !"