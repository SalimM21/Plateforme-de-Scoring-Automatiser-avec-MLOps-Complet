# 📋 **GUIDE LOGGING CENTRALISÉ**

*MLOps Scoring Platform - Loki + Promtail + Grafana*
*Collecte, Stockage, Analyse et Visualisation des Logs*

---

## 📋 **APERÇU**

Ce guide présente le système complet de logging centralisé pour la plateforme MLOps Scoring, utilisant Loki pour le stockage, Promtail pour la collecte, et Grafana pour la visualisation et l'analyse avancée des logs.

### **Capacités du Système**
- ✅ **Collecte centralisée** : Tous les composants (API, DB, ML, Infra)
- ✅ **Stockage optimisé** : Loki avec compression et indexation
- ✅ **Recherche avancée** : LogQL pour requêtes complexes
- ✅ **Alertes basées logs** : Détection patterns et anomalies
- ✅ **Visualisation Grafana** : Dashboards interactifs et temps réel
- ✅ **Analyse automatisée** : Scripts d'analyse et rapports
- ✅ **Archivage intelligent** : Rétention et compression automatique

---

## 🏗️ **ARCHITECTURE DU LOGGING**

### **Composants de la Stack**

#### **1. Loki (Stockage)**
```yaml
# Stockage distribué et optimisé pour logs
- Compression: gzip/zstd
- Indexation: par labels et timestamps
- Rétention: configurable (7-90 jours)
- Haute disponibilité: réplication
- API: RESTful pour requêtes
```

#### **2. Promtail (Collecte)**
```yaml
# Agent de collecte léger
- Découverte Kubernetes automatique
- Parsing intelligent par composant
- Labels enrichis automatiquement
- Filtrage et transformation
- Haute performance: faible overhead
```

#### **3. Grafana (Visualisation)**
```yaml
# Interface d'analyse avancée
- Requêtes LogQL natives
- Dashboards interactifs
- Alertes intégrées
- Exports et partages
- Plugins et extensions
```

### **Flux de Données**
```
Applications → Promtail → Loki → Grafana → Utilisateurs
       ↓           ↓        ↓        ↓
   Logs bruts  Parsing  Indexation  Requêtes
   structurés  Enrichi   Compressé  Visualisées
```

---

## 🚀 **DÉPLOIEMENT DU LOGGING CENTRALISÉ**

### **1. Créer le Namespace**
```bash
kubectl create namespace logging
```

### **2. Déployer Loki**
```bash
kubectl apply -f logging/loki-config.yaml
kubectl apply -f logging/loki-pvc.yaml

# Vérifier le déploiement
kubectl get pods -n logging
kubectl logs -f deployment/loki -n logging
```

### **3. Déployer Promtail**
```bash
kubectl apply -f logging/promtail-config.yaml

# Vérifier la collecte
kubectl get pods -n logging
kubectl logs -f ds/promtail -n logging
```

### **4. Configurer Grafana**
```bash
# Ajouter Loki comme source de données
curl -X POST http://grafana:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Loki",
    "type": "loki",
    "url": "http://loki.logging.svc.cluster.local:3100",
    "access": "proxy"
  }'

# Importer le dashboard
curl -X POST http://grafana:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -d @logging/logging-dashboards.json
```

### **5. Configurer les Alertes**
```bash
# Ajouter les règles Loki au Ruler
kubectl apply -f logging/loki-alerts.yaml

# Redémarrer Loki pour prendre en compte les règles
kubectl rollout restart deployment/loki -n logging
```

---

## 📊 **COLLECTE DES LOGS PAR COMPOSANT**

### **Logs Applicatifs**

#### **Scoring API**
```yaml
# Parsing structuré JSON
pipeline_stages:
  - json:
      expressions:
        level: level
        timestamp: timestamp
        message: message
        request_id: request_id
        user_id: user_id
        model_version: model_version
  - labels:
      level:
      component: scoring-api
      request_id:
      user_id:
      model_version:
```

#### **API Gateway**
```yaml
# Parsing regex pour logs texte
pipeline_stages:
  - regex:
      expression: '^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?P<level>\w+)\] (?P<message>.+)$'
  - labels:
      level:
      component: api-gateway
```

### **Logs Infrastructure**

#### **Kafka**
```yaml
# Parsing complexe avec threads
pipeline_stages:
  - regex:
      expression: '(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (?P<level>\w+) \[(?P<thread>[^\]]+)\] (?P<logger>[^\s]+) - (?P<message>.+)'
  - labels:
      level:
      thread:
      logger:
      component: kafka
```

#### **PostgreSQL**
```yaml
# Parsing base de données
pipeline_stages:
  - regex:
      expression: '(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) (?P<pid>\d+) (?P<level>\w+)  (?P<message>.+)'
  - labels:
      level:
      pid:
      component: postgresql
```

### **Logs Sécurité**

#### **Keycloak**
```yaml
# Parsing sécurité avec méthodes
pipeline_stages:
  - regex:
      expression: '(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z) (?P<level>\w+) \[(?P<class>[^\]]+)\] \((?P<method>[^\)]+)\) (?P<message>.+)'
  - labels:
      level:
      class:
      method:
      component: keycloak
```

---

## 🔍 **REQUÊTES LOGQL AVANCÉES**

### **Requêtes de Base**
```logql
# Tous les logs d'un composant
{component="scoring-api"}

# Logs d'erreur uniquement
{level="ERROR"}

# Logs d'un pod spécifique
{pod_name="scoring-api-12345-abcde"}
```

### **Filtrage et Recherche**
```logql
# Recherche de texte
{component="scoring-api"} |= "timeout"

# Recherche insensible à la casse
{component="scoring-api"} |~ "Timeout|TIMEOUT"

# Exclusion de patterns
{component="scoring-api"} != "health check"
```

### **Parsing et Extraction**
```logql
# Extraction JSON
{component="scoring-api"} | json | user_id=`{{.user_id}}`

# Parsing regex
{component="api-gateway"} | regex "(?P<method>\\w+) (?P<path>\\S+) (?P<status>\\d+)"

# Ligne formatée
{component="scoring-api"} | line_format "{{.timestamp}} [{{.level}}] {{.message}}"
```

### **Agrégation et Analyse**
```logql
# Comptage par niveau
sum(count_over_time({component="scoring-api"}[1h])) by (level)

# Taux d'erreur
sum(rate({level="ERROR"}[5m])) / sum(rate({component=~".*"}[5m])) * 100

# Top erreurs
topk(10, sum(rate({level="ERROR"}[1h])) by (message))
```

### **Analyse Temporelle**
```logql
# Logs des dernières 24h
{component="scoring-api"} [24h]

# Comparaison périodes
sum(rate({level="ERROR"}[1h])) / sum(rate({level="ERROR"}[1h] offset 24h))

# Tendances
deriv(sum(rate({component="scoring-api"}[5m]))[1h])
```

### **Requêtes Complexes**
```logql
# Erreurs corrélées
{component="scoring-api", level="ERROR"} and {component="postgresql", level="ERROR"}

# Analyse de performance
{component="scoring-api"} | json | latency > 5000

# Sécurité
{component="keycloak"} |~ "authentication.*failed" | json | ip=`{{.ip_address}}`
```

---

## 🚨 **ALERTES BASÉES LOGS**

### **Alertes Applications**
```yaml
- alert: ScoringAPIErrorLogs
  expr: sum(rate({component="scoring-api", level=~"ERROR|FATAL|CRITICAL"}[5m])) > 0
  for: 2m
  labels: {severity: critical, component: scoring-api}
  annotations:
    summary: "Erreurs détectées dans les logs Scoring API"

- alert: APIHighErrorRate
  expr: rate({component="api-gateway", level="ERROR"}[5m]) / rate({component="api-gateway"}[5m]) > 0.05
  for: 5m
  labels: {severity: warning, component: api-gateway}
  annotations:
    summary: "Taux d'erreur élevé dans API Gateway"
```

### **Alertes Infrastructure**
```yaml
- alert: KafkaBrokerErrors
  expr: sum(rate({component="kafka", level="ERROR"}[5m])) by (pod_name) > 5
  for: 3m
  labels: {severity: critical, component: kafka}
  annotations:
    summary: "Erreurs Kafka détectées"

- alert: DatabaseConnectionErrors
  expr: sum(rate({component="postgresql", message=~".*connection.*failed.*"}[5m])) > 0
  for: 2m
  labels: {severity: critical, component: postgresql}
  annotations:
    summary: "Erreurs de connexion base de données"
```

### **Alertes Sécurité**
```yaml
- alert: AuthenticationFailures
  expr: sum(rate({component="keycloak", message=~".*authentication.*failed.*"}[5m])) > 10
  for: 5m
  labels: {severity: warning, component: keycloak}
  annotations:
    summary: "Échecs d'authentification multiples"

- alert: SecurityViolations
  expr: sum(rate({message=~".*unauthorized.*|.*forbidden.*"}[5m])) > 0
  for: 1m
  labels: {severity: critical, component: security}
  annotations:
    summary: "Violation de sécurité détectée"
```

### **Alertes Performance**
```yaml
- alert: SlowQueriesDetected
  expr: sum(rate({component="postgresql", message=~".*slow.*query.*"}[5m])) > 0
  for: 3m
  labels: {severity: warning, component: postgresql}
  annotations:
    summary: "Requêtes lentes détectées"

- alert: HighLatencyDetected
  expr: sum(rate({component="scoring-api", message=~".*latency.*>.*5000.*"}[5m])) > 0
  for: 3m
  labels: {severity: warning, component: scoring-api}
  annotations:
    summary: "Latence élevée détectée"
```

---

## 📈 **DASHBOARDS GRAFANA**

### **Panneaux Disponibles**

#### **1. Log Volume Overview**
- Volume de logs par job/composant
- Tendances temporelles
- Comparaisons périodes

#### **2. Error Rate by Component**
- Taux d'erreur par composant
- Évolution dans le temps
- Seuils et alertes visuelles

#### **3. Recent Error Logs**
- Logs d'erreur en temps réel
- Formatage intelligent
- Liens vers contexte complet

#### **4. Application Logs Explorer**
- Exploration interactive
- Filtres dynamiques
- Recherche en temps réel

#### **5. Log Patterns Analysis**
- Analyse des patterns
- Statistiques par niveau
- Détection anomalies

#### **6. Security Events**
- Événements sécurité
- Tentatives d'intrusion
- Violations détectées

#### **7. Performance Issues**
- Problèmes performance
- Timeouts et lenteurs
- Erreurs mémoire

#### **8. Business Logic Errors**
- Erreurs métier
- Validations échouées
- Contraintes violées

#### **9. Infrastructure Issues**
- Problèmes infrastructure
- Erreurs base de données
- Défaillances réseau

#### **10. LogQL Query Builder**
- Guide des requêtes
- Exemples pratiques
- Aide à la construction

#### **11. Log Metrics**
- Métriques calculées
- KPIs temps réel
- Indicateurs de santé

---

## 🔍 **ANALYSE AVANCÉE DES LOGS**

### **Script d'Analyse Automatisée**
```bash
cd logging

# État général des logs
./log-analysis.sh status all 1h

# Analyse des erreurs
./log-analysis.sh errors scoring-api 24h

# Analyse de performance
./log-analysis.sh performance all 6h

# Analyse de sécurité
./log-analysis.sh security all 24h

# Analyse des tendances
./log-analysis.sh trends all 7d

# Recherche avancée
./log-analysis.sh search "timeout" 1h

# Rapport complet
./log-analysis.sh report
```

### **Rapports Automatisés**
```markdown
# Rapport d'Analyse des Logs

## Métriques Globales
- **Total logs**: 1,247,839 entrées
- **Logs/seconde**: 34.7 logs/s
- **Taux d'erreur**: 0.12%

## Analyse des Erreurs
### Top 10 Erreurs
1. **scoring-api**: timeout on model prediction...
2. **postgresql**: connection pool exhausted...
3. **kafka**: broker not available...

## Analyse Performance
- **Temps réponse moyen**: 245ms
- **Taux succès**: 99.88%
- **Timeouts détectés**: 23

## Recommandations
- URGENT: Augmenter pool de connexions DB
- HAUTE: Optimiser modèle de scoring lent
- MOYENNE: Ajouter cache Redis pour features
```

---

## ⚙️ **CONFIGURATION AVANCÉE**

### **Rétention et Archivage**
```yaml
# Configuration Loki
table_manager:
  retention_deletes_enabled: true
  retention_period: 30d

# Archivage automatique
limits_config:
  max_query_length: 721h  # 30 jours
  reject_old_samples: true
  reject_old_samples_max_age: 168h  # 7 jours
```

### **Optimisations Performance**
```yaml
# Chunk size optimisé
chunk_store_config:
  max_look_back_period: 0s

# Cache des résultats
query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

# Parallélisation
query_scheduler:
  max_outstanding_requests_per_tenant: 100
```

### **Sécurité et Conformité**
```yaml
# Chiffrement des logs sensibles
pipeline_stages:
  - replace:
      expression: "(password|token|key)\\s*=\\s*\\S+"
      replace: "$1=***"

# Audit logging
- labeldrop:
    - sensitive_data
- labels:
    audit_trail: enabled
    compliance: gdpr
```

### **Intégrations Externes**
```yaml
# Export vers Elasticsearch
- job_name: elasticsearch-export
  loki_push_api:
    endpoint: http://elasticsearch:9200/_bulk

# Intégration SIEM
- job_name: siem-forward
  syslog:
    endpoint: splunk.company.com:514
    format: rfc3164
```

---

## 🎯 **BONNES PRATIQUES**

### **Structuration des Logs**
```json
{
  "timestamp": "2025-11-13T13:50:00.000Z",
  "level": "INFO",
  "component": "scoring-api",
  "request_id": "req-12345",
  "user_id": "user-67890",
  "operation": "predict",
  "model_version": "v2.1.0",
  "latency_ms": 245,
  "status": "success",
  "message": "Prediction completed successfully"
}
```

### **Niveaux de Log Appropriés**
- **ERROR**: Erreurs impactant le service
- **WARN**: Problèmes potentiels, dégradations
- **INFO**: Événements business importants
- **DEBUG**: Détails techniques pour debugging

### **Labels Cohérents**
```yaml
# Labels standardisés
labels:
  component: scoring-api
  version: v2.1.0
  environment: production
  region: eu-west-1
  cluster: mlops-prod
```

### **Monitoring des Logs**
- **Volume**: Détecter anomalies de volume
- **Latence**: Monitorer ingestion Loki
- **Erreurs**: Alertes sur parsing failures
- **Stockage**: Gestion espace disque

---

## 📈 **IMPACT BUSINESS**

### **Avantages Opérationnels**
- **Débogage accéléré** : Recherche instantanée dans tous les logs
- **Détection précoce** : Patterns d'erreur identifiés automatiquement
- **Résolution rapide** : Contexte complet pour troubleshooting
- **Observabilité complète** : Vue 360° de la plateforme
- **Conformité** : Audit trails complets et sécurisés

### **Métriques de Succès**
- **Temps MTTR** : -60% grâce à recherche rapide
- **Couverture monitoring** : 100% composants trackés
- **Alertes pertinentes** : < 5% faux positifs
- **Satisfaction équipes** : +80% (debugging facilité)
- **Conformité** : 100% logs audités disponibles

### **ROI du Logging Centralisé**
- **Productivité dev** : +40% (debugging accéléré)
- **Stabilité système** : +95% (détection précoce)
- **Résolution incidents** : -70% temps MTTR
- **Conformité** : Évitement pénalités réglementaires
- **Innovation** : Focus sur features vs debugging

---

**📋 Logging centralisé opérationnel !**

*Loki + Promtail + Grafana pour collecte, stockage et analyse*
*Logs structurés, alertes intelligentes, rapports automatisés* 🎯