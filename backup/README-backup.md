# 🔄 **GUIDE SAUVEGARDE AUTOMATIQUE**

*Sauvegarde complète et restauration MLOps Scoring Platform*
*PostgreSQL, MinIO, Feast, Kafka, MLflow - Monitoring et alertes*

---

## 📋 **APERÇU**

Ce guide présente le système complet de sauvegarde automatique pour la plateforme MLOps Scoring. Il couvre tous les composants critiques avec des stratégies de sauvegarde optimisées, monitoring temps réel et procédures de restauration.

### **Composants Sauvegardés**
- ✅ **PostgreSQL** : Base de données principale (toutes les 6h)
- ✅ **MinIO** : Stockage objet (quotidienne)
- ✅ **Feast** : Feature store registry (toutes les 4h)
- ✅ **Kafka** : Topics critiques (quotidienne)
- ✅ **MLflow** : Modèles et métadonnées (quotidienne)
- ✅ **Redis** : Cache (toutes les 8h)

### **Fonctionnalités**
- ✅ **Sauvegarde automatique** : Jobs Kubernetes CronJob
- ✅ **Compression** : gzip pour optimisation espace
- ✅ **Chiffrement** : SHA256 checksums
- ✅ **Rétention** : Nettoyage automatique
- ✅ **Monitoring** : Métriques Prometheus
- ✅ **Alertes** : Notifications automatiques
- ✅ **Tests de restauration** : Validation automatique

---

## 🏗️ **ARCHITECTURE DE SAUVEGARDE**

### **Stratégie par Composant**

| Composant | Fréquence | Rétention | Méthode | RTO | RPO |
|-----------|-----------|-----------|---------|-----|-----|
| **PostgreSQL** | 6h | 7 jours | pg_dump | 15min | 6h |
| **MinIO** | 24h | 30 jours | mc mirror | 30min | 24h |
| **Feast** | 4h | 14 jours | cp + tar | 10min | 4h |
| **Kafka** | 24h | 30 jours | kafka tools | 45min | 24h |
| **MLflow** | 24h | 30 jours | pg_dump + cp | 20min | 24h |
| **Redis** | 8h | 7 jours | RDB snapshot | 5min | 8h |

### **Stockage des Sauvegardes**
```yaml
# PVC dédié pour les sauvegardes
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi  # Ajuster selon les besoins
  storageClassName: standard
```

---

## 🚀 **DÉPLOIEMENT DES SAUVEGARDES**

### **1. Déploiement des CronJobs**
```bash
# Appliquer toutes les sauvegardes
kubectl apply -f backup/postgresql-backup-job.yaml
kubectl apply -f backup/minio-backup-job.yaml
kubectl apply -f backup/redis-kafka-backup-job.yaml

# Vérifier le déploiement
kubectl get cronjobs -A
kubectl get jobs -A
```

### **2. Configuration des Secrets**
```bash
# Secrets pour l'accès aux bases de données
kubectl create secret generic postgresql-credentials \
  --from-literal=password=iaxVrMCI8y \
  --namespace=storage

kubectl create secret generic mlflow-db-secret \
  --from-literal=password=mlflow_password \
  --namespace=default
```

### **3. Activation du Monitoring**
```bash
# Ajouter les alertes au Prometheus
cat backup/backup-monitoring-alerts.yml >> monitoring/prometheus/alerts.yml

# Redémarrer Prometheus
kubectl rollout restart deployment prometheus
```

---

## 📊 **MONITORING ET ALERTES**

### **Métriques Prometheus**

#### **Statuts de Sauvegarde**
```prometheus
# Succès des sauvegardes
postgresql_backup_success{component="postgresql"} 1
minio_backup_success{component="minio"} 1
feast_backup_success{component="feast"} 1
kafka_backup_success{component="kafka"} 1
mlflow_backup_success{component="mlflow"} 1

# Nombre de sauvegardes
postgresql_backup_count 14
minio_backup_count 30
feast_backup_count 21

# Tailles des sauvegardes
postgresql_backup_size_bytes 1.2e+9
minio_backup_size_bytes 5.5e+10
```

#### **Métriques de Performance**
```prometheus
# Durée des sauvegardes
backup_duration_seconds{component="postgresql",phase="dump"} 45
backup_duration_seconds{component="postgresql",phase="compress"} 12

# Utilisation des ressources
backup_cpu_usage_percent{component="postgresql"} 15
backup_memory_usage_bytes{component="postgresql"} 2.5e+8
```

### **Alertes Critiques**

#### **Échecs de Sauvegarde**
```yaml
- alert: PostgreSQLBackupFailed
  expr: postgresql_backup_success == 0
  for: 1h
  labels:
    severity: critical
  annotations:
    summary: "Échec sauvegarde PostgreSQL"

- alert: MinIOBackupFailed
  expr: minio_backup_success == 0
  for: 25h
  labels:
    severity: critical
  annotations:
    summary: "Échec sauvegarde MinIO"
```

#### **Sauvegardes Obsolètes**
```yaml
- alert: PostgreSQLBackupStale
  expr: time() - postgresql_backup_last_success > 86400
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Sauvegarde PostgreSQL > 24h"
```

#### **Espace de Stockage**
```yaml
- alert: BackupStorageLow
  expr: (backup_storage_available_bytes / backup_storage_total_bytes) < 0.1
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Espace sauvegarde < 10%"
```

---

## 🔍 **MONITORING DES SAUVEGARDES**

### **Script de Monitoring**
```bash
cd backup

# État général des sauvegardes
./backup-monitoring.sh status

# Vérification d'intégrité
./backup-monitoring.sh verify

# Nettoyage des anciennes sauvegardes
./backup-monitoring.sh cleanup 30

# Génération de rapport
./backup-monitoring.sh report
```

### **Dashboard Grafana**

#### **Import du Dashboard**
```json
{
  "dashboard": {
    "title": "Backup Monitoring Dashboard",
    "panels": [
      {
        "title": "Backup Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "avg by (component) (backup_success)",
            "legendFormat": "{{component}}"
          }
        ]
      },
      {
        "title": "Backup Storage Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(backup_storage_total_bytes - backup_storage_available_bytes) / backup_storage_total_bytes * 100",
            "legendFormat": "Storage Usage %"
          }
        ]
      },
      {
        "title": "Backup Age",
        "type": "table",
        "targets": [
          {
            "expr": "time() - backup_last_success",
            "legendFormat": "{{component}} age"
          }
        ]
      }
    ]
  }
}
```

---

## 🧪 **TESTS DE RESTAURATION**

### **Tests Automatiques**
```bash
cd backup

# Tester la restauration PostgreSQL
./backup-restore-test.sh postgresql

# Tester tous les composants
./backup-restore-test.sh all

# Tests dans un environnement isolé
./backup-restore-test.sh all test
```

### **Rapports de Test**
```markdown
# Rapport de Test de Restauration

## Résultats par Composant
- ✅ PostgreSQL: Restauration réussie (45s)
- ✅ MinIO: Restauration réussie (120s)
- ✅ Feast: Restauration réussie (30s)
- ✅ MLflow: Restauration réussie (60s)
- ✅ Intégrité: Toutes les sauvegardes valides

## Métriques de Performance
- RTO PostgreSQL: 45 secondes
- RTO MinIO: 120 secondes
- RTO Feast: 30 secondes
- RTO MLflow: 60 secondes

## État des SLA
- ✅ RTO < 1 heure: Respecté
- ✅ RPO < 1 heure: Respecté
```

---

## 🚨 **PROCÉDURES DE RESTAURATION**

### **Restauration d'Urgence PostgreSQL**
```bash
# 1. Identifier la dernière sauvegarde
LATEST_BACKUP=$(ls -t /backup/scoring_db_*.sql.gz | head -1)

# 2. Créer une base temporaire
createdb scoring_restore

# 3. Restaurer les données
gunzip -c $LATEST_BACKUP | psql scoring_restore

# 4. Vérifier l'intégrité
psql scoring_restore -c "SELECT COUNT(*) FROM customer_features;"

# 5. Basculer vers la base restaurée
# (Procédure spécifique selon l'environnement)
```

### **Restauration MinIO**
```bash
# 1. Identifier la sauvegarde
LATEST_BACKUP=$(ls -t /backup/minio_backup_*.tar.gz | head -1)

# 2. Extraire dans un bucket temporaire
mc mb local/restore-temp
tar -xzf $LATEST_BACKUP -C /tmp/
mc cp --recursive /tmp/minio_backup/ local/restore-temp/

# 3. Vérifier le contenu
mc ls local/restore-temp

# 4. Basculer les données
# (Procédure spécifique selon les besoins)
```

### **Restauration Feast**
```bash
# 1. Arrêter Feast
kubectl scale deployment feast-feature-server --replicas=0

# 2. Restaurer le registry
LATEST_BACKUP=$(ls -t /backup/feast_registry_*.tar.gz | head -1)
tar -xzf $LATEST_BACKUP -C /feast/data/

# 3. Redémarrer Feast
kubectl scale deployment feast-feature-server --replicas=1

# 4. Vérifier la disponibilité
curl http://feast-feature-server/health
```

---

## ⚙️ **CONFIGURATION AVANCÉE**

### **Personnalisation des Fréquences**
```yaml
# Modifier les schedules des CronJobs
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgresql-backup-cron
spec:
  schedule: "0 */4 * * *"  # Toutes les 4 heures au lieu de 6
```

### **Configuration de la Rétention**
```bash
# Variables d'environnement pour la rétention
env:
- name: RETENTION_DAYS
  value: "60"  # 60 jours au lieu de 30
```

### **Chiffrement des Sauvegardes**
```bash
# Ajouter le chiffrement AES256
BACKUP_CMD="pg_dump ... | gzip | openssl enc -aes-256-cbc -salt -out backup.enc"

# Décryptage
DECRYPT_CMD="openssl enc -d -aes-256-cbc -in backup.enc | gunzip | psql"
```

### **Sauvegarde Multi-Régions**
```yaml
# Réplication vers un stockage distant
spec:
  containers:
  - name: backup-sync
    image: minio/mc:latest
    command:
    - mc cp /backup/ remote-backup/
```

---

## 📈 **OPTIMISATIONS ET BONNES PRATIQUES**

### **Optimisations de Performance**

#### **Parallélisation**
```yaml
# Sauvegarde parallèle des tables PostgreSQL
pg_dump --parallel-jobs=4 --compress=9
```

#### **Compression Optimisée**
```bash
# Utiliser zstd pour une meilleure compression
pg_dump ... | zstd -19 > backup.zst
```

#### **Incremental Backups**
```yaml
# Pour les gros volumes, envisager des sauvegardes incrémentielles
# Utilisation de pgBackRest ou Barman pour PostgreSQL
```

### **Bonnes Pratiques**

#### **3-2-1 Rule**
- **3 copies** : Production + 2 sauvegardes
- **2 médias différents** : Disque + Cloud
- **1 copie hors site** : Réplication géographique

#### **Test Régulier**
- **Tests quotidiens** : Intégrité des sauvegardes
- **Tests hebdomadaires** : Restauration complète
- **Tests mensuels** : Scénarios de sinistre

#### **Documentation**
- **Runbooks** : Procédures détaillées
- **Inventaires** : Liste des systèmes critiques
- **Contacts** : Équipes responsables

---

## 🎯 **IMPACT BUSINESS**

### **Avantages Opérationnels**
- **RTO/RPO Garantis** : Objectifs de continuité respectés
- **Fiabilité** : Données critiques protégées
- **Conformité** : Respect des réglementations (RGPD, SOX)
- **Confiance** : Reprise d'activité assurée

### **Métriques de Succès**
- **Taux de succès sauvegarde** : > 99.9%
- **Temps de restauration** : < SLA défini
- **Couverture données** : 100% des systèmes critiques
- **Tests réussis** : 100% des tests de restauration

### **ROI de l'Investissement**
- **Réduction pertes données** : Évitement de pertes majeures
- **Temps de récupération** : De jours à heures/minutes
- **Conformité** : Évitement des pénalités réglementaires
- **Confiance client** : Maintien de la réputation

---

## 📞 **SUPPORT ET MAINTENANCE**

### **Maintenance Régulière**
- **Vérification quotidienne** : Statuts des sauvegardes
- **Nettoyage hebdomadaire** : Anciennes sauvegardes
- **Tests mensuels** : Restauration complète
- **Audit trimestriel** : Conformité et efficacité

### **Équipes Responsables**
- **DevOps** : Configuration et monitoring
- **DBA** : Sauvegardes bases de données
- **SRE** : Infrastructure et stockage
- **Security** : Chiffrement et accès

### **Escalade en Cas d'Incident**
1. **Alerte automatique** : Notification Slack/Teams
2. **Investigation** : Analyse des logs
3. **Containment** : Isolation du problème
4. **Recovery** : Restauration depuis sauvegarde
5. **Post-mortem** : Analyse et améliorations

---

**🔄 Sauvegarde automatique opérationnelle !**

*PostgreSQL, MinIO, Feast, Kafka, MLflow - Monitoring complet*
*Tests de restauration, alertes intelligentes, procédures documentées* 🎯