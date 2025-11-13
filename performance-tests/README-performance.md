# ⚡ **GUIDE TESTS DE PERFORMANCE**

*Tests de charge et performance pour MLOps Scoring Platform*
*Locust, JMeter, monitoring et alertes intégrés*

---

## 📋 **APERÇU**

Ce guide présente le système complet de tests de performance et de charge pour la plateforme MLOps Scoring. Il couvre les tests automatisés, les métriques de monitoring et les seuils de performance.

### **Outils Implémentés**
- ✅ **Locust** : Tests de charge Python avancés
- ✅ **JMeter** : Tests complexes et base de données
- ✅ **Grafana Dashboard** : Visualisation des métriques
- ✅ **Prometheus Alertes** : Notifications automatiques
- ✅ **Scripts d'automatisation** : Exécution et rapports

---

## 🏗️ **ARCHITECTURE DES TESTS**

### **Types de Tests Disponibles**

| Type | Description | Durée | Utilisateurs | Usage |
|------|-------------|-------|--------------|-------|
| **Smoke** | Validation basique | 1 min | 5 | Tests quotidiens |
| **Load** | Charge normale | 5 min | 50 | Performance standard |
| **Stress** | Charge élevée | 10 min | 200 | Limites système |
| **Spike** | Pic soudain | 2 min | 500 | Trafic burst |
| **Endurance** | Charge prolongée | 30 min | 30 | Stabilité |
| **Volume** | Gros volumes | 10 min | 20 | Traitement données |

### **Métriques Mesurées**
- **Response Time** : Temps de réponse (avg, 95th percentile)
- **Throughput** : Requêtes/seconde
- **Error Rate** : Taux d'échec (%)
- **Resource Usage** : CPU, mémoire, I/O
- **Business Metrics** : Scoring accuracy, latency SLA

---

## 🚀 **EXÉCUTION DES TESTS**

### **Via GitHub Actions**
```bash
# Interface web GitHub
1. Aller dans Actions > Performance Tests
2. Cliquer "Run workflow"
3. Sélectionner :
   - test_type: load|stress|spike|endurance|volume
   - duration: minutes
   - concurrency: utilisateurs
   - target_environment: staging|production
```

### **Via Script Local**
```bash
cd performance-tests

# Test de charge standard
./run-performance-tests.sh load staging 300 50

# Test de stress
./run-performance-tests.sh stress production 600 200

# Test local (avec port-forward)
./run-performance-tests.sh smoke local 60 5
```

### **Via Locust Direct**
```bash
# Interface web interactive
locust -f performance-tests/locustfile.py \
       --host http://localhost:8000 \
       --users 50 \
       --spawn-rate 5

# Accéder à http://localhost:8089 pour contrôler le test
```

---

## 📊 **ANALYSE DES RÉSULTATS**

### **Rapports Générés**

#### **Rapport HTML Locust**
```bash
# Structure du rapport
├── Charts: Response times, RPS over time
├── Statistics: Min/Max/Avg response times
├── Failures: Detailed error breakdown
├── Exceptions: Python stack traces
└── Download: CSV data export
```

#### **Rapport Métriques JSON**
```json
{
  "test_info": {
    "type": "load",
    "environment": "staging",
    "timestamp": "2025-11-13T13:00:00Z",
    "duration_seconds": 300,
    "users": 50
  },
  "metrics": {
    "avg_response_time_ms": 245.67,
    "median_response_time_ms": 198.45,
    "requests_per_second": 42.3,
    "failure_rate_percent": 0.8
  },
  "evaluation": {
    "performance_status": "✅ BON",
    "reliability_status": "✅ BONNE"
  }
}
```

### **Seuils de Performance**

| Métrique | Excellent | Bon | Acceptable | Critique |
|----------|-----------|-----|------------|----------|
| **Response Time (95th)** | < 500ms | < 1000ms | < 2000ms | > 2000ms |
| **Error Rate** | < 0.1% | < 1% | < 5% | > 5% |
| **Throughput** | > 100 req/s | > 50 req/s | > 20 req/s | < 20 req/s |
| **CPU Usage** | < 60% | < 80% | < 90% | > 90% |
| **Memory Usage** | < 70% | < 85% | < 95% | > 95% |

---

## 📈 **DASHBOARD GRAFANA**

### **Import du Dashboard**
```bash
# Via Grafana UI
1. Dashboard > Import
2. Upload JSON: performance-tests/performance-dashboard.json
3. Sélectionner datasource Prometheus
```

### **Panneaux Disponibles**

#### **1. API Response Time**
- 95th percentile response time
- Median response time
- Evolution temporelle

#### **2. Request Rate**
- Requêtes/seconde globales
- Par endpoint (/score, /health, etc.)

#### **3. Error Rate**
- Taux d'erreur global
- Par code HTTP (4xx, 5xx)

#### **4. Database Performance**
- Temps de requête PostgreSQL
- Nombre de connexions actives

#### **5. Kafka Throughput**
- Messages/seconde
- Consumer lag

#### **6. Feast Performance**
- Latence récupération features
- Taux de succès

#### **7. System Resources**
- CPU usage par pod
- Memory usage par pod

#### **8. ML Model Performance**
- Latence d'inférence
- Nombre de prédictions

---

## 🚨 **ALERTES PROMETHEUS**

### **Configuration**
```bash
# Ajouter au fichier prometheus/alerts.yml
cat performance-tests/performance-alerts.yml >> monitoring/prometheus/alerts.yml

# Recharger Prometheus
kubectl rollout restart deployment prometheus
```

### **Alertes Critiques**

#### **API Performance**
- `HighAPIResponseTime`: > 2s pendant 5min
- `CriticalAPIResponseTime`: > 5s pendant 2min
- `HighAPIErrorRate`: > 5% pendant 5min
- `CriticalAPIErrorRate`: > 10% pendant 2min

#### **SLA Violations**
- `APISLAViolation`: > 3s pendant 15min
- `FeastSLAViolation`: > 200ms pendant 15min
- `DatabaseSLAViolation`: > 500ms pendant 15min

#### **System Resources**
- `HighCPUUsage`: > 80% pendant 5min
- `HighMemoryUsage`: > 90% pendant 5min
- `PodRestartingFrequently`: > 3 restarts/10min

#### **Business Metrics**
- `LowScoringThroughput`: < 10 predictions/min
- `HighScoringQueueDepth`: > 100 requests queued

---

## 🔧 **CONFIGURATION AVANCÉE**

### **Personnalisation des Tests**

#### **Modifier les Scénarios Locust**
```python
# Dans locustfile.py
class CustomScoringUser(BaseTestUser):
    tasks = [CustomScoringTasks]

    @task(2)
    def custom_scoring_scenario(self):
        # Scénario personnalisé
        payload = {
            "customer_id": self.user.customer_id,
            "features": { /* features personnalisées */ }
        }

        with self.client.post("/score/custom",
                            json=payload,
                            headers=self.get_auth_headers()) as response:
            # Logique personnalisée
            pass
```

#### **Configuration JMeter**
```xml
<!-- Dans jmeter-test-plan.jmx -->
<ThreadGroup>
  <stringProp name="ThreadGroup.num_threads">100</stringProp>
  <stringProp name="ThreadGroup.ramp_time">60</stringProp>
  <stringProp name="ThreadGroup.duration">600</stringProp>
</ThreadGroup>
```

### **Variables d'Environnement**
```bash
# Pour les tests
export BASE_URL="http://scoring-api.example.com"
export FEAST_URL="http://feast.example.com"
export AUTH_TOKEN="your-jwt-token"

# Pour les seuils
export MAX_RESPONSE_TIME=2000
export MAX_ERROR_RATE=5
```

---

## 📊 **INTÉGRATION CI/CD**

### **Tests Automatisés**
```yaml
# Dans .github/workflows/ci-cd-pipeline.yml
- name: Performance Tests
  run: |
    cd performance-tests
    ./run-performance-tests.sh smoke staging 60 5

- name: Performance Regression Check
  run: |
    # Comparer avec les baselines
    python scripts/compare-performance.py \
      --baseline baseline.json \
      --current results/latest/metrics.json
```

### **Gates de Qualité**
```yaml
# Bloquer le déploiement si performance dégradée
- name: Performance Gate
  run: |
    if [ "$(cat results/latest/evaluation/performance_status)" = "❌ MAUVAIS" ]; then
      echo "Performance degraded - blocking deployment"
      exit 1
    fi
```

---

## 🔍 **DÉBOGAGE ET DIAGNOSTIC**

### **Analyse des Goulets d'Étranglement**

#### **1. Identifier les Slow Queries**
```bash
# Logs applicatifs
kubectl logs -f deployment/scoring-api | grep "duration"

# Métriques PostgreSQL
kubectl exec -it postgres-pod -- psql -c "SELECT * FROM pg_stat_activity;"

# Métriques Redis
kubectl exec -it redis-pod -- redis-cli info
```

#### **2. Analyse des Resources**
```bash
# Utilisation CPU/Memory
kubectl top pods

# Network I/O
kubectl exec -it pod -- netstat -i

# Disk I/O
kubectl exec -it pod -- iostat -x 1
```

#### **3. Profiling de l'Application**
```bash
# Python profiling
python -m cProfile -s time app/main.py

# Memory profiling
from memory_profiler import profile
@profile
def scoring_function():
    # Code à profiler
```

### **Outils de Diagnostic**
- **APM**: New Relic, DataDog pour tracing distribué
- **Profiling**: Py-Spy pour profiling CPU Python
- **Memory**: Memray pour analyse mémoire
- **Database**: pgBadger pour analyse PostgreSQL

---

## 📈 **OPTIMISATIONS PERFORMANCE**

### **Recommandations par Métrique**

#### **Response Time Élevé**
```python
# Optimisations API
- Utiliser async/await
- Implémenter caching (Redis)
- Optimiser les requêtes DB
- Utiliser connection pooling
```

#### **Throughput Faible**
```python
# Scaling horizontal
kubectl scale deployment scoring-api --replicas=5

# Optimisations système
- Ajuster les limits de ressources
- Utiliser des pods plus performants
- Optimiser la configuration JVM
```

#### **Error Rate Élevé**
```python
# Améliorer la résilience
- Implémenter retry logic
- Ajouter circuit breakers
- Améliorer la gestion d'erreurs
- Monitoring des dépendances
```

### **Benchmarks Cibles**

| Scénario | Users | Response Time | Throughput | Error Rate |
|----------|-------|---------------|------------|------------|
| **Baseline** | 10 | < 200ms | > 50 req/s | < 0.1% |
| **Normal Load** | 50 | < 500ms | > 100 req/s | < 1% |
| **Peak Load** | 200 | < 1000ms | > 150 req/s | < 2% |
| **Stress Test** | 500 | < 2000ms | > 200 req/s | < 5% |

---

## 📋 **BEST PRACTICES**

### **Planification des Tests**
1. **Smoke Tests** quotidiens (CI)
2. **Load Tests** avant chaque release
3. **Stress Tests** mensuels
4. **Endurance Tests** trimestriels

### **Environnements de Test**
- **CI/Local**: Tests unitaires rapides
- **Staging**: Tests d'intégration complets
- **Production**: Tests en lecture seule uniquement

### **Monitoring Continu**
- **Synthetic Monitoring**: Tests automatisés 24/7
- **Real User Monitoring**: Métriques utilisateurs réels
- **Alerting**: Notifications immédiates sur dégradation

### **Documentation**
- **Runbooks**: Procédures d'investigation
- **Baselines**: Métriques de référence
- **Historique**: Évolution des performances

---

## 🎯 **IMPACT BUSINESS**

### **Avantages Opérationnels**
- **Fiabilité**: Détection précoce des problèmes
- **Performance**: Optimisations continues
- **SLA**: Respect des engagements
- **Coûts**: Évitement des sur-provisionnements

### **Métriques Business**
- **User Experience**: Temps de réponse perçu
- **Conversion**: Impact des lenteurs sur le business
- **Retention**: Satisfaction utilisateur
- **Revenue**: Disponibilité des services critiques

---

**⚡ Tests de performance complets opérationnels !**

*Locust avancés, JMeter complexes, monitoring intégré*
*Alertes automatiques et optimisations continues* 🎯