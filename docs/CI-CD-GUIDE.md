# 🚀 **GUIDE CI/CD COMPLET**

*GitHub Actions pour MLOps Scoring Platform*
*Automatisation complète du développement au déploiement*

---

## 📋 **APERÇU**

Ce guide présente le système CI/CD complet basé sur GitHub Actions pour la plateforme MLOps Scoring. Il couvre tous les aspects de l'automatisation depuis les tests jusqu'au déploiement en production.

### **Workflows Disponibles**
- ✅ **CI/CD Pipeline** : Pipeline complète automatique
- ✅ **Déploiement Manuel** : Déploiements contrôlés
- ✅ **Tests Performance** : Tests de charge et performance
- ✅ **Audit Sécurité** : Audits automatiques hebdomadaires

---

## 🏗️ **ARCHITECTURE CI/CD**

### **Flux de Développement**
```
Développeur → Commit → GitHub Actions → Tests → Build → Security → Deploy
                                      ↓
                               Staging ← Manual Approval → Production
```

### **Environnements**
| Environnement | Trigger | Approbation | Usage |
|---------------|---------|-------------|-------|
| **CI** | Push/PR | Automatique | Tests, build, sécurité |
| **Staging** | Push `develop` | Automatique | Tests d'intégration |
| **Production** | Push `main` | Automatique | Production |

---

## ⚙️ **CONFIGURATION REQUISE**

### **1. Secrets GitHub**
```bash
# Aller dans Settings > Secrets and variables > Actions
# Ajouter les secrets suivants :

# Kubernetes
KUBE_CONFIG_STAGING     # Config kubectl pour staging
KUBE_CONFIG_PRODUCTION  # Config kubectl pour production

# Docker Registry
GHCR_TOKEN             # Personal Access Token GitHub

# Services externes (si utilisés)
SLACK_WEBHOOK          # Pour notifications Slack
DATADOG_API_KEY        # Pour monitoring avancé
```

### **2. Variables d'Environnement**
```bash
# Dans Settings > Environments
# Créer les environnements staging et production

# Variables communes :
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
```

### **3. Branches Protégées**
```bash
# Settings > Branches > Branch protection rules

# Pour main :
- Require pull request reviews
- Require status checks (ci-cd-pipeline)
- Include administrators

# Pour develop :
- Require status checks (quality-checks, unit-tests)
```

---

## 🚀 **WORKFLOW CI/CD PRINCIPAL**

### **Déclencheurs**
```yaml
on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - 'docs/**'
      - 'README.md'
  pull_request:
    branches: [ main, develop ]
```

### **Jobs Exécutés**

#### **1. Quality Checks** 🔍
```yaml
- Code formatting (Black)
- Linting (Flake8)
- Type checking (MyPy)
- Security scanning (Bandit, Safety)
```

#### **2. Unit Tests** 🧪
```yaml
- Tests API (pytest)
- Tests ML (pytest)
- Tests Feast (pytest)
- Coverage reports
```

#### **3. Integration Tests** 🔗
```yaml
- Build containers
- Tests end-to-end
- API health checks
```

#### **4. Build Images** 🐳
```yaml
- Multi-stage builds
- Push to GHCR
- Image tagging automatique
```

#### **5. Security Scan** 🔒
```yaml
- Vulnerability scanning (Trivy)
- SBOM generation
- License compliance
```

#### **6. Deploy Staging** 🚀
```yaml
- Auto-deploy sur push develop
- Tests post-déploiement
- Rollback automatique si échec
```

#### **7. Deploy Production** 🎯
```yaml
- Auto-deploy sur push main
- Blue-green deployment
- Monitoring post-déploiement
```

---

## 🔧 **WORKFLOW DÉPLOIEMENT MANUEL**

### **Utilisation**
```bash
# Via GitHub UI :
1. Aller dans Actions > Manual Deployment
2. Cliquer "Run workflow"
3. Sélectionner :
   - Environment (staging/production)
   - Service (all, scoring-api, mlflow-server, etc.)
   - Version (latest, develop, ou tag spécifique)
```

### **Cas d'Usage**
- **Rollback** : Déployer version précédente
- **Hotfix** : Déployer correctif urgent
- **Test** : Déployer feature branch
- **Maintenance** : Redémarrer services spécifiques

---

## ⚡ **WORKFLOW TESTS PERFORMANCE**

### **Types de Tests Disponibles**
- **Load** : Test de charge normal (concurrency stable)
- **Stress** : Test de stress (concurrency élevée)
- **Spike** : Test de pic (trafic soudain)
- **Volume** : Test de volume (données massives)
- **Endurance** : Test d'endurance (longue durée)

### **Configuration**
```yaml
inputs:
  test_type: load | stress | spike | volume | endurance
  duration: "5"  # minutes
  concurrency: "10"  # utilisateurs simultanés
  target_environment: staging | production
```

### **Rapports Générés**
- **Métriques Locust** : Response time, RPS, failure rate
- **Graphiques** : Distribution des temps de réponse
- **Recommandations** : Optimisations suggérées
- **Seuils** : Validation automatique des performances

---

## 🔒 **WORKFLOW AUDIT SÉCURITÉ**

### **Audits Disponibles**
- **Full** : Audit complet (tous les aspects)
- **Dependencies** : Vulnérabilités des dépendances
- **Secrets** : Détection de secrets exposés
- **Infrastructure** : Sécurité Kubernetes
- **Compliance** : Conformité RGPD/SOC2

### **Fréquence**
- **Automatique** : Hebdomadaire (dimanche 2h)
- **Manuel** : À la demande via workflow dispatch
- **Push** : Sur modification des dépendances

### **Rapports Générés**
- **Vulnérabilités** : Liste détaillée avec CVSS scores
- **Secrets exposés** : Localisation et gravité
- **Issues infrastructure** : Recommandations de sécurité
- **Conformité** : État des exigences réglementaires

---

## 📊 **MONITORING ET OBSERVABILITÉ**

### **Métriques Collectées**
```yaml
# Temps de build
- job_duration_seconds

# Taux de succès
- pipeline_success_rate

# Performance tests
- response_time_p95
- error_rate_percentage

# Sécurité
- vulnerabilities_count
- secrets_exposed_count
```

### **Dashboards Grafana**
- **Pipeline Health** : Taux de succès par job
- **Performance Trends** : Évolution des métriques
- **Security Overview** : Vulnérabilités par composant
- **Deployment Frequency** : Fréquence des déploiements

### **Alertes Configurées**
```yaml
# Pipeline failures
- alert: PipelineFailure
  expr: pipeline_success_rate < 0.95
  for: 5m

# Performance degradation
- alert: PerformanceDegradation
  expr: response_time_p95 > 2000
  for: 10m

# Security vulnerabilities
- alert: SecurityVulnerabilities
  expr: vulnerabilities_count > 0
  for: 1h
```

---

## 🛠️ **COMMANDES ET SCRIPTS UTILES**

### **Déclenchement Manuel**
```bash
# Déploiement manuel
gh workflow run deploy-manual.yml \
  -f environment=staging \
  -f service=scoring-api \
  -f version=v1.2.3

# Test performance
gh workflow run performance-tests.yml \
  -f test_type=load \
  -f duration=10 \
  -f concurrency=50

# Audit sécurité
gh workflow run security-audit.yml \
  -f audit_type=full
```

### **Monitoring des Pipelines**
```bash
# Status des workflows
gh run list --workflow=ci-cd-pipeline.yml

# Logs d'un run spécifique
gh run view <run-id> --log

# Artifacts d'un run
gh run download <run-id>
```

### **Debug Local**
```bash
# Test des actions localement
act -j quality-checks --container-architecture linux/amd64

# Validation des workflows
actionlint .github/workflows/*.yml
```

---

## 🚨 **GESTION DES INCIDENTS**

### **Rollback Procedures**

#### **Rollback Automatique**
```yaml
# En cas d'échec post-déploiement
- name: Rollback on failure
  if: failure()
  run: |
    kubectl rollout undo deployment/scoring-api
    kubectl rollout undo deployment/mlflow-server
```

#### **Rollback Manuel**
```bash
# Via deployment manuel
gh workflow run deploy-manual.yml \
  -f environment=production \
  -f service=all \
  -f version=previous-tag
```

### **Incident Response**
1. **Détection** : Alertes Slack/GitHub notifications
2. **Investigation** : Logs et métriques
3. **Containment** : Rollback automatique
4. **Recovery** : Déploiement version stable
5. **Analysis** : Post-mortem et améliorations

---

## 📈 **OPTIMISATIONS ET BONNES PRATIQUES**

### **Performance**
- **Cache** : Dépendances et builds Docker
- **Parallelisation** : Jobs exécutés en parallèle
- **Lazy loading** : Tests seulement si nécessaire
- **Artifact reuse** : Réutilisation des artifacts

### **Sécurité**
- **Secrets** : Stockage dans GitHub Secrets
- **Vulnerability scanning** : Intégré dans le pipeline
- **SBOM** : Génération automatique
- **Access control** : Branch protection rules

### **Fiabilité**
- **Retry logic** : Réessais automatiques
- **Fallbacks** : Déploiements alternatifs
- **Monitoring** : Observabilité complète
- **Documentation** : Guides à jour

---

## 🎯 **MÉTRIQUES DE SUCCÈS**

### **KPIs Pipeline**
- **Deployment Frequency** : Déploiements/jour
- **Lead Time** : Commit → Production
- **Change Failure Rate** : % échecs déploiement
- **MTTR** : Mean Time To Recovery

### **Targets Recommandés**
- **Deployment Frequency** : Multiple/day
- **Lead Time** : < 1 heure
- **Change Failure Rate** : < 15%
- **MTTR** : < 1 heure

---

## 📞 **SUPPORT ET MAINTENANCE**

### **Maintenance Régulière**
- **Mise à jour dépendances** : Sécurité et performance
- **Review workflows** : Optimisations continues
- **Mise à jour secrets** : Rotation périodique
- **Tests de charge** : Validation performance

### **Debug et Troubleshooting**
```bash
# Logs détaillés
gh run view <run-id> --log --exit-status

# Variables d'environnement
gh run view <run-id> --job <job-id>

# Artifacts de debug
gh run download <run-id> --name debug-artifacts
```

### **Support et Contact**
- **Documentation** : Ce guide et READMEs
- **Issues** : GitHub Issues avec label `ci-cd`
- **Reviews** : Pull requests pour modifications
- **Monitoring** : Dashboards Grafana

---

**🚀 CI/CD complet opérationnel pour déploiement automatisé !**

*Tests automatisés, sécurité intégrée, déploiements progressifs*
*Observabilité complète et rollback automatique* 🎯