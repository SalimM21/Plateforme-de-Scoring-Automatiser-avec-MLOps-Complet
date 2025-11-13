# 🎯 **GUIDE UTILISATEUR**

*MLOps Scoring Platform - Guide d'utilisation pour développeurs et data scientists*

---

## 📋 **APERÇU**

Ce guide vous accompagne dans l'utilisation quotidienne de la plateforme MLOps Scoring, depuis l'intégration API jusqu'à la gestion des modèles ML en production.

### **🎯 Public Cible**
- **Développeurs** : Intégration API, déploiement services
- **Data Scientists** : Gestion modèles, feature engineering
- **DevOps Engineers** : Déploiement, monitoring, maintenance
- **Product Managers** : Suivi KPIs, analyse performance

---

## 🚀 **PREMIERS PAS**

### **Accès à la Plateforme**

```bash
# Variables d'environnement
export SCORING_API_URL="https://api.scoring-platform.com"
export SCORING_API_KEY="your-api-key"

# Test connexion
curl -H "Authorization: Bearer $SCORING_API_KEY" \
     $SCORING_API_URL/api/v1/health
```

### **Authentification**

```python
from scoring_platform import ScoringClient

# Initialisation client
client = ScoringClient(
    api_url="https://api.scoring-platform.com",
    api_key="your-api-key"
)

# Test authentification
health = client.health_check()
print(f"Status: {health['status']}")
```

---

## 🎯 **SCORING API**

### **Scoring Synchrone**

#### **Requête Individuelle**
```python
from scoring_platform import ScoringClient

client = ScoringClient()

# Données client
customer_data = {
    "customer_id": "CUST-001",
    "features": {
        "age": 35,
        "income": 75000,
        "credit_score": 720,
        "debt_ratio": 0.3,
        "employment_years": 8,
        "home_ownership": True,
        "marital_status": "married"
    }
}

# Scoring
result = client.score_customer(customer_data)

print(f"Customer ID: {result['customer_id']}")
print(f"Credit Score: {result['credit_score']}")
print(f"Risk Level: {result['risk_level']}")
print(f"Approved Amount: ${result['approved_amount']:,}")
print(f"Confidence: {result['confidence']:.2%}")
```

#### **Réponse API**
```json
{
  "customer_id": "CUST-001",
  "credit_score": 742,
  "risk_level": "LOW",
  "approved_amount": 85000,
  "confidence": 0.89,
  "model_version": "credit-scoring-v2.1",
  "processing_time_ms": 45,
  "timestamp": "2025-11-13T15:00:00Z",
  "feature_contributions": {
    "income": 0.25,
    "credit_score": 0.35,
    "debt_ratio": -0.15,
    "employment_years": 0.12
  }
}
```

### **Scoring par Lot**

#### **Traitement Batch**
```python
from scoring_platform import ScoringClient
import pandas as pd

client = ScoringClient()

# Chargement données batch
df = pd.read_csv("customers_batch.csv")

# Conversion en format API
batch_data = []
for _, row in df.iterrows():
    customer = {
        "customer_id": row["customer_id"],
        "features": {
            "age": row["age"],
            "income": row["income"],
            "credit_score": row["credit_score"],
            "debt_ratio": row["debt_ratio"],
            "employment_years": row["employment_years"]
        }
    }
    batch_data.append(customer)

# Scoring batch
batch_results = client.score_batch(batch_data, batch_size=50)

# Traitement résultats
for result in batch_results:
    if "error" in result:
        print(f"Error for {result['customer_id']}: {result['error']}")
    else:
        print(f"{result['customer_id']}: Score {result['credit_score']} ({result['risk_level']})")
```

#### **Optimisations Batch**
```python
# Configuration avancée
batch_config = {
    "batch_size": 100,
    "concurrency": 4,
    "timeout": 30,
    "retry_policy": {
        "max_retries": 3,
        "backoff_factor": 2
    }
}

results = client.score_batch_optimized(
    batch_data,
    config=batch_config
)
```

### **Scoring Asynchrone**

#### **Submission Job**
```python
# Soumission job asynchrone
job = client.submit_async_scoring(
    customer_data,
    callback_url="https://your-app.com/scoring-callback"
)

print(f"Job ID: {job['job_id']}")
print(f"Status: {job['status']}")
print(f"Estimated completion: {job['estimated_completion']}")
```

#### **Vérification Status**
```python
# Vérification status job
status = client.get_job_status(job_id)

if status["status"] == "completed":
    result = client.get_job_result(job_id)
    print(f"Scoring result: {result}")
elif status["status"] == "failed":
    print(f"Job failed: {status['error']}")
else:
    print(f"Job in progress: {status['progress']}%")
```

---

## 🤖 **GESTION MODÈLES ML**

### **Registry Modèles**

#### **Lister Modèles Disponibles**
```python
from scoring_platform import MLflowClient

mlflow = MLflowClient()

# Lister modèles
models = mlflow.list_models()

for model in models:
    print(f"Name: {model['name']}")
    print(f"Latest Version: {model['latest_version']}")
    print(f"Stage: {model['stage']}")
    print(f"Creation Time: {model['creation_timestamp']}")
    print("---")
```

#### **Détails Modèle**
```python
# Détails modèle spécifique
model_details = mlflow.get_model_details("credit-scoring")

print(f"Model: {model_details['name']}")
print(f"Description: {model_details['description']}")
print(f"Tags: {model_details['tags']}")

# Versions disponibles
for version in model_details['versions']:
    print(f"Version {version['version']}: {version['stage']} - {version['creation_timestamp']}")
```

### **Déploiement Modèles**

#### **Déploiement Nouveau Modèle**
```python
# Déploiement modèle en staging
deployment = mlflow.deploy_model(
    model_name="credit-scoring",
    version="2.1",
    stage="staging",
    resources={
        "cpu": "500m",
        "memory": "1Gi"
    }
)

print(f"Deployment ID: {deployment['deployment_id']}")
print(f"Endpoint: {deployment['endpoint']}")
print(f"Status: {deployment['status']}")
```

#### **Promotion Production**
```python
# Promotion en production avec canary
promotion = mlflow.promote_to_production(
    model_name="credit-scoring",
    version="2.1",
    canary_percentage=10,  # 10% traffic
    monitoring_window=3600  # 1h observation
)

print(f"Promotion ID: {promotion['promotion_id']}")
print(f"Canary deployment started")
```

#### **Rollback**
```python
# Rollback en cas de problème
rollback = mlflow.rollback_model(
    model_name="credit-scoring",
    target_version="2.0",
    reason="Performance degradation detected"
)

print(f"Rollback initiated: {rollback['rollback_id']}")
```

### **Monitoring Modèles**

#### **Métriques Performance**
```python
# Métriques modèle
metrics = mlflow.get_model_metrics(
    model_name="credit-scoring",
    version="2.1",
    time_range="24h"
)

print("Model Performance Metrics:")
print(f"Requests: {metrics['total_requests']}")
print(f"Latency P95: {metrics['latency_p95']}ms")
print(f"Error Rate: {metrics['error_rate']:.2%}")
print(f"Accuracy: {metrics['accuracy']:.2%}")
```

#### **Détection Drift**
```python
# Vérification drift
drift_analysis = mlflow.check_model_drift(
    model_name="credit-scoring",
    reference_data="training_data_2024",
    current_data_window="7d"
)

if drift_analysis["drift_detected"]:
    print("⚠️ Model drift detected!")
    print(f"Drift score: {drift_analysis['drift_score']}")
    print(f"Affected features: {drift_analysis['affected_features']}")

    # Déclencher retraining
    retrain_job = mlflow.trigger_retraining(
        model_name="credit-scoring",
        reason="drift_detected"
    )
```

---

## 📊 **FEATURE STORE**

### **Gestion Features**

#### **Enregistrement Features**
```python
from scoring_platform import FeatureStoreClient

fs = FeatureStoreClient()

# Définition feature
feature_definition = {
    "name": "customer_credit_score",
    "description": "Customer credit score from credit bureau",
    "data_type": "float",
    "tags": ["credit", "bureau", "risk"],
    "validation_rules": {
        "range": [300, 850],
        "required": True
    }
}

# Enregistrement
feature = fs.register_feature(feature_definition)
print(f"Feature registered: {feature['feature_id']}")
```

#### **Ingestion Données**
```python
# Ingestion batch
feature_data = [
    {
        "customer_id": "CUST-001",
        "timestamp": "2025-11-13T10:00:00Z",
        "features": {
            "credit_score": 720,
            "income": 75000,
            "debt_ratio": 0.3
        }
    },
    # ... plus de données
]

ingestion_result = fs.ingest_features(feature_data)
print(f"Ingested {ingestion_result['records_ingested']} records")
```

#### **Récupération Features**
```python
# Récupération features pour scoring
customer_features = fs.get_customer_features(
    customer_id="CUST-001",
    feature_names=["credit_score", "income", "debt_ratio"],
    as_of_date="2025-11-13"
)

print("Customer features:")
for feature_name, value in customer_features.items():
    print(f"  {feature_name}: {value}")
```

### **Feature Monitoring**

#### **Qualité Features**
```python
# Analyse qualité
quality_report = fs.analyze_feature_quality(
    feature_names=["credit_score", "income"],
    time_range="30d"
)

for feature_name, analysis in quality_report.items():
    print(f"Feature: {feature_name}")
    print(f"  Completeness: {analysis['completeness']:.1%}")
    print(f"  Freshness: {analysis['freshness_hours']}h")
    print(f"  Anomalies: {analysis['anomaly_count']}")
```

#### **Drift Features**
```python
# Détection drift features
drift_report = fs.detect_feature_drift(
    feature_names=["credit_score", "income"],
    reference_period="2025-10-01:2025-10-31",
    current_period="2025-11-01:2025-11-13"
)

for feature_name, drift in drift_report.items():
    if drift["drift_detected"]:
        print(f"⚠️ Drift detected in {feature_name}")
        print(f"  Drift score: {drift['drift_score']}")
        print(f"  Confidence: {drift['confidence']:.1%}")
```

---

## 📈 **EXPERIMENTATION A/B**

### **Configuration Tests A/B**

#### **Création Test**
```python
from scoring_platform import ABTestingClient

ab_client = ABTestingClient()

# Configuration test A/B
ab_test = {
    "name": "credit-scoring-model-comparison",
    "description": "Compare new ML model vs current production",
    "variants": [
        {
            "name": "control",
            "model": "credit-scoring-v2.0",
            "weight": 70  # 70% traffic
        },
        {
            "name": "treatment",
            "model": "credit-scoring-v2.1",
            "weight": 30  # 30% traffic
        }
    ],
    "metrics": [
        "approval_rate",
        "default_rate",
        "processing_time"
    ],
    "duration_days": 14,
    "target_sample_size": 10000
}

# Création test
test_id = ab_client.create_test(ab_test)
print(f"A/B test created: {test_id}")
```

#### **Suivi Test**
```python
# Métriques test en temps réel
metrics = ab_client.get_test_metrics(test_id)

print("A/B Test Results:")
for variant in metrics["variants"]:
    print(f"Variant: {variant['name']}")
    print(f"  Traffic: {variant['traffic_percentage']:.1%}")
    print(f"  Sample size: {variant['sample_size']}")
    print(f"  Approval rate: {variant['approval_rate']:.2%}")
    print(f"  Processing time: {variant['processing_time']:.0f}ms")

# Analyse statistique
if metrics["statistical_significance"] > 0.95:
    winner = metrics["winner_variant"]
    print(f"🎉 Statistically significant result! Winner: {winner}")
else:
    print("📊 Test still running - need more data")
```

### **Optimisation Dynamique**

#### **Rebalancing Automatique**
```python
# Ajustement dynamique des poids
if metrics["treatment_better"]:
    # Augmenter traffic vers meilleur variant
    ab_client.adjust_traffic(
        test_id=test_id,
        adjustments={
            "control": 50,    # Réduire à 50%
            "treatment": 50   # Augmenter à 50%
        }
    )
```

---

## 📊 **DASHBOARD ET MONITORING**

### **Tableaux de Bord**

#### **Dashboard Business**
- **Métriques Clés** : Volume scoring, taux approbation, taux défaut
- **Performance Temps Réel** : Latence API, disponibilité services
- **Tendances** : Évolution scoring sur 30 jours
- **Alertes** : Seuils dépassés, anomalies détectées

#### **Dashboard Technique**
- **Infrastructure** : CPU/Memory, utilisation stockage
- **Services** : Health checks, error rates, throughput
- **ML Models** : Performance modèles, drift detection
- **Data Quality** : Freshness données, anomalies

### **Accès Dashboards**

```bash
# Dashboard principal
open https://dashboard.scoring-platform.com

# Grafana (métriques techniques)
open https://grafana.scoring-platform.com

# Kibana (logs)
open https://kibana.scoring-platform.com
```

### **Alertes et Notifications**

#### **Configuration Alertes**
```yaml
# Configuration alertes personnalisées
alerts:
  - name: high_error_rate
    condition: error_rate > 0.05
    severity: critical
    channels: [slack, email, pager]
    cooldown: 300  # 5 minutes

  - name: model_performance_drop
    condition: model_accuracy < 0.8
    severity: warning
    channels: [slack]
    cooldown: 3600  # 1 heure

  - name: data_quality_issue
    condition: data_freshness > 24
    severity: warning
    channels: [email]
    cooldown: 1800  # 30 minutes
```

#### **Gestion Alertes**
```python
from scoring_platform import AlertingClient

alerts = AlertingClient()

# Lister alertes actives
active_alerts = alerts.get_active_alerts()

for alert in active_alerts:
    print(f"🚨 {alert['severity'].upper()}: {alert['message']}")
    print(f"   Service: {alert['service']}")
    print(f"   Triggered: {alert['triggered_at']}")

# Acquitter alerte
alerts.acknowledge_alert(alert_id="alert-123", comment="Investigating issue")
```

---

## 🔧 **OUTILS DÉVELOPPEUR**

### **CLI Tools**

```bash
# Outil CLI plateforme
scoring-platform --help

# Gestion modèles
scoring-platform model list
scoring-platform model deploy --name credit-scoring-v2 --env staging
scoring-platform model promote --name credit-scoring-v2 --to production

# Tests
scoring-platform test run --type integration
scoring-platform test performance --endpoint /api/v1/scoring --concurrency 100

# Monitoring
scoring-platform monitor status
scoring-platform monitor logs --service scoring-api --tail 100

# Debug
scoring-platform debug api-call --endpoint /api/v1/scoring --data sample.json
scoring-platform debug database --query "SELECT COUNT(*) FROM customers"
```

### **SDK Python**

#### **Installation**
```bash
pip install scoring-platform-sdk
```

#### **Utilisation Avancée**
```python
from scoring_platform import ScoringPlatform

# Client complet
sp = ScoringPlatform(
    api_url="https://api.scoring-platform.com",
    api_key="your-key",
    enable_caching=True,
    enable_retry=True
)

# Pipeline complexe
with sp.pipeline() as pipeline:
    # Ingestion données
    data = pipeline.ingest_from_csv("customers.csv")

    # Feature engineering
    features = pipeline.engineer_features(data)

    # Scoring batch
    results = pipeline.score_batch(features)

    # Export résultats
    pipeline.export_to_s3(results, "s3://results-bucket/scoring-results/")

print(f"Pipeline completed: {len(results)} customers scored")
```

### **Webhooks et Intégrations**

#### **Configuration Webhooks**
```python
# Configuration webhooks pour événements
webhooks = {
    "model_deployed": {
        "url": "https://your-app.com/webhooks/model-deployed",
        "events": ["model.staging.deployed", "model.production.deployed"],
        "secret": "webhook-secret"
    },
    "scoring_completed": {
        "url": "https://your-app.com/webhooks/scoring-completed",
        "events": ["scoring.batch.completed", "scoring.async.completed"],
        "secret": "webhook-secret"
    }
}

sp.configure_webhooks(webhooks)
```

---

## 🧪 **TESTS ET VALIDATION**

### **Tests Locaux**

```bash
# Tests unitaires
make test-unit

# Tests intégration
make test-integration

# Tests end-to-end
make test-e2e

# Tests performance
make test-performance

# Tests sécurité
make test-security
```

### **Validation Production**

```bash
# Validation pré-déploiement
make validate-deployment

# Smoke tests
make smoke-test

# Canary validation
make canary-test

# Rollback automatique si échec
make rollback-on-failure
```

---

## 🚨 **GESTION INCIDENTS**

### **Processus Incident**

1. **Détection** : Alertes automatiques, monitoring temps réel
2. **Triage** : Classification sévérité, impact assessment
3. **Investigation** : Logs analysis, root cause analysis
4. **Résolution** : Fix deployment, rollback si nécessaire
5. **Post-mortem** : Incident review, lessons learned

### **Outils Debug**

```bash
# Debug API calls
scoring-platform debug api-trace --request-id req-123

# Debug modèle
scoring-platform debug model-prediction --model credit-scoring-v2 --input sample.json

# Debug base de données
scoring-platform debug db-query --query "SELECT * FROM customers WHERE id = 'CUST-123'"

# Debug infrastructure
scoring-platform debug pod-logs --namespace platform --pod scoring-api-123
```

---

## 📚 **RESSOURCES SUPPLÉMENTAIRES**

### **Documentation**
- [📖 Documentation API](api-reference.md) - Référence complète API
- [🏗️ Architecture](architecture.md) - Architecture détaillée
- [🔒 Sécurité](security.md) - Guide sécurité
- [📊 Métriques](metrics.md) - Métriques et KPIs

### **Exemples et Tutorials**
- [🎯 Tutorials](https://learn.scoring-platform.com) - Guides pas à pas
- [💻 Code Examples](https://github.com/your-org/examples) - Exemples pratiques
- [🎥 Videos](https://youtube.com/scoring-platform) - Vidéos explicatives

### **Support Communauté**
- [💬 Slack Community](https://slack.scoring-platform.com) - Discussions temps réel
- [📧 Mailing List](https://groups.scoring-platform.com) - Annonces et discussions
- [🐛 GitHub Issues](https://github.com/your-org/mlops-scoring-platform/issues) - Bug reports

---

**🎯 Guide utilisateur complet !**

*API Integration • Model Management • A/B Testing • Monitoring*
*Developer-Friendly • Production-Ready • Enterprise-Scale* 🚀