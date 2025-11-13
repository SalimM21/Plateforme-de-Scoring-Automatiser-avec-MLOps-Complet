# 🤝 **GUIDE CONTRIBUTION**

*MLOps Scoring Platform - Guide pour contribuer au projet*

---

## 📋 **APERÇU**

Bienvenue dans le guide de contribution de la plateforme MLOps Scoring ! Ce document explique comment contribuer efficacement au projet, que vous soyez développeur, data scientist, ou DevOps engineer.

### **🎯 Types de Contributions**
- **Code** : Nouvelles fonctionnalités, corrections bugs, optimisations
- **Documentation** : Guides, tutorials, API documentation
- **Tests** : Tests unitaires, intégration, performance
- **Infrastructure** : Terraform, Helm charts, CI/CD
- **ML Models** : Nouveaux modèles, améliorations existants
- **Bug Reports** : Signalement problèmes, suggestions d'amélioration

---

## 🚀 **DÉMARRAGE RAPIDE**

### **Configuration Environnement**

```bash
# 1. Fork le repository
# Aller sur https://github.com/your-org/mlops-scoring-platform
# Cliquer "Fork"

# 2. Cloner votre fork
git clone https://github.com/YOUR_USERNAME/mlops-scoring-platform.git
cd mlops-scoring-platform

# 3. Configuration git
git remote add upstream https://github.com/your-org/mlops-scoring-platform.git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 4. Installation dépendances
make install-dev-dependencies

# 5. Configuration environnement local
cp .env.example .env
# Éditer .env avec vos paramètres locaux

# 6. Démarrage environnement développement
make start-dev-environment
```

### **Première Contribution**

```bash
# 1. Créer branche feature
git checkout -b feature/amazing-feature

# 2. Faire vos changements
# ... code ...

# 3. Tests locaux
make test-unit
make test-integration

# 4. Commit changes
git add .
git commit -m "feat: add amazing feature

- Add new scoring endpoint
- Improve error handling
- Add comprehensive tests

Closes #123"

# 5. Push vers votre fork
git push origin feature/amazing-feature

# 6. Créer Pull Request
# Aller sur GitHub et créer PR vers main branch
```

---

## 📝 **STANDARDS DE CODE**

### **Style Guide Python**

#### **PEP 8 Compliance**
```python
# ✅ Correct
def calculate_credit_score(customer_data: Dict[str, Any]) -> float:
    """Calculate credit score using ML model.

    Args:
        customer_data: Customer financial data

    Returns:
        Credit score between 300-850

    Raises:
        ValidationError: If customer data is invalid
    """
    if not self._validate_customer_data(customer_data):
        raise ValidationError("Invalid customer data")

    # Process features
    features = self._extract_features(customer_data)

    # Make prediction
    score = self.model.predict(features)[0]

    return round(score, 2)

# ❌ Incorrect
def calc_score(data):  # No type hints, poor naming
    # No docstring
    if not data:  # Poor validation
        raise Exception("bad data")  # Generic exception
    return model.predict(data)[0]  # No rounding
```

#### **Imports Organization**
```python
# Standard library imports
import os
import json
from typing import Dict, List, Optional

# Third-party imports
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
import mlflow

# Local imports
from .models import CreditScoringModel
from .utils import validate_customer_data
from ..config import settings
```

### **Style Guide JavaScript/React**

#### **ES6+ Features**
```javascript
// ✅ Correct - Modern JavaScript
import React, { useState, useEffect, useCallback } from 'react';
import { ScoringDashboard } from '../components';

const CreditScoringWidget = ({ customerId }) => {
  const [scoringData, setScoringData] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchScoringData = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(`/api/scoring/${customerId}`);
      const data = await response.json();
      setScoringData(data);
    } catch (error) {
      console.error('Failed to fetch scoring data:', error);
    } finally {
      setLoading(false);
    }
  }, [customerId]);

  useEffect(() => {
    fetchScoringData();
  }, [fetchScoringData]);

  if (loading) return <div>Loading...</div>;

  return (
    <div className="scoring-widget">
      <h3>Credit Score: {scoringData?.credit_score}</h3>
      <p>Risk Level: {scoringData?.risk_level}</p>
    </div>
  );
};

export default CreditScoringWidget;
```

### **Style Guide Infrastructure as Code**

#### **Terraform Standards**
```hcl
# ✅ Correct - Terraform best practices
resource "aws_db_instance" "scoring_database" {
  identifier              = "scoring-db-${var.environment}"
  engine                  = "postgres"
  engine_version          = "14.2"
  instance_class          = "db.r6g.large"
  allocated_storage       = 100
  max_allocated_storage   = 1000
  storage_encrypted       = true
  backup_retention_period = 30

  # Security
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name
  publicly_accessible    = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_enhanced_monitoring.arn

  # Maintenance
  maintenance_window = "sun:03:00-sun:04:00"
  backup_window      = "02:00-03:00"

  tags = merge(local.common_tags, {
    Name        = "scoring-database"
    Environment = var.environment
    Component   = "database"
  })
}
```

---

## 🧪 **TESTS ET QUALITÉ**

### **Stratégie Testing**

#### **Pyramid Testing**
```
End-to-End Tests (10%)
  ↳ Integration Tests (20%)
    ↳ Unit Tests (70%)
```

#### **Tests Unitaires**
```python
# ✅ Example - Comprehensive unit test
import pytest
from unittest.mock import Mock, patch
from scoring.api.scoring_service import ScoringService
from scoring.models.customer import CustomerData


class TestScoringService:
    @pytest.fixture
    def scoring_service(self):
        return ScoringService()

    @pytest.fixture
    def valid_customer_data(self):
        return CustomerData(
            customer_id="TEST-001",
            age=35,
            income=75000,
            credit_score=720,
            debt_ratio=0.3,
            employment_years=8
        )

    def test_calculate_credit_score_success(self, scoring_service, valid_customer_data):
        """Test successful credit score calculation"""
        # Arrange
        expected_score = 742.5

        # Act
        result = scoring_service.calculate_credit_score(valid_customer_data)

        # Assert
        assert result.credit_score == expected_score
        assert result.risk_level == "LOW"
        assert result.confidence > 0.8

    def test_calculate_credit_score_invalid_data(self, scoring_service):
        """Test credit score calculation with invalid data"""
        # Arrange
        invalid_data = CustomerData(
            customer_id="TEST-001",
            age=-5,  # Invalid age
            income=75000,
            credit_score=720,
            debt_ratio=0.3,
            employment_years=8
        )

        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            scoring_service.calculate_credit_score(invalid_data)

        assert "age" in str(exc_info.value).lower()

    @patch('scoring.api.scoring_service.MLflowClient')
    def test_calculate_credit_score_model_failure(self, mock_mlflow, scoring_service, valid_customer_data):
        """Test handling of model prediction failure"""
        # Arrange
        mock_mlflow.return_value.predict.side_effect = Exception("Model unavailable")

        # Act & Assert
        with pytest.raises(ModelPredictionError) as exc_info:
            scoring_service.calculate_credit_score(valid_customer_data)

        assert "model prediction failed" in str(exc_info.value).lower()

    @pytest.mark.parametrize("age,income,expected_risk", [
        (25, 30000, "HIGH"),
        (35, 75000, "LOW"),
        (50, 150000, "VERY_LOW"),
    ])
    def test_credit_score_risk_levels(self, scoring_service, age, income, expected_risk):
        """Test credit score risk level classification"""
        customer_data = CustomerData(
            customer_id="TEST-001",
            age=age,
            income=income,
            credit_score=720,
            debt_ratio=0.3,
            employment_years=8
        )

        result = scoring_service.calculate_credit_score(customer_data)
        assert result.risk_level == expected_risk
```

#### **Tests d'Intégration**
```python
# ✅ Example - API integration test
import pytest
from fastapi.testclient import TestClient
from scoring.api.main import app
from scoring.database.connection import get_db_session


class TestScoringAPI:
    @pytest.fixture
    def client(self):
        return TestClient(app)

    @pytest.fixture
    def db_session(self):
        # Setup test database
        session = get_db_session()
        # Create test data
        yield session
        # Cleanup
        session.close()

    def test_scoring_endpoint_success(self, client, db_session):
        """Test successful scoring API call"""
        # Arrange
        customer_data = {
            "customer_id": "TEST-001",
            "features": {
                "age": 35,
                "income": 75000,
                "credit_score": 720,
                "debt_ratio": 0.3,
                "employment_years": 8
            }
        }

        # Act
        response = client.post("/api/v1/scoring", json=customer_data)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "credit_score" in data
        assert "risk_level" in data
        assert "confidence" in data
        assert 300 <= data["credit_score"] <= 850

    def test_scoring_endpoint_validation_error(self, client):
        """Test scoring API with invalid data"""
        # Arrange
        invalid_data = {
            "customer_id": "TEST-001",
            "features": {
                "age": -5,  # Invalid age
                "income": 75000,
                "credit_score": 720,
                "debt_ratio": 0.3,
                "employment_years": 8
            }
        }

        # Act
        response = client.post("/api/v1/scoring", json=invalid_data)

        # Assert
        assert response.status_code == 422
        data = response.json()
        assert "detail" in data
        assert any("age" in str(error).lower() for error in data["detail"])

    def test_scoring_batch_endpoint(self, client):
        """Test batch scoring endpoint"""
        # Arrange
        batch_data = {
            "requests": [
                {
                    "customer_id": "TEST-001",
                    "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}
                },
                {
                    "customer_id": "TEST-002",
                    "features": {"age": 45, "income": 95000, "credit_score": 780, "debt_ratio": 0.2, "employment_years": 12}
                }
            ]
        }

        # Act
        response = client.post("/api/v1/scoring/batch", json=batch_data)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["results"]) == 2
        for result in data["results"]:
            assert "credit_score" in result
            assert "customer_id" in result
```

#### **Tests Performance**
```python
# ✅ Example - Performance test
import pytest
import time
import statistics
from locust import HttpUser, task, between


class ScoringAPIUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def score_customer(self):
        customer_data = {
            "customer_id": f"CUST-{self.user_id}",
            "features": {
                "age": 35,
                "income": 75000,
                "credit_score": 720,
                "debt_ratio": 0.3,
                "employment_years": 8
            }
        }

        with self.client.post("/api/v1/scoring", json=customer_data, catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Request failed with status {response.status_code}")


def test_api_performance_baseline():
    """Test performance baseline"""
    import requests

    # Test simple request time
    start_time = time.time()
    response = requests.post("http://localhost:8000/api/v1/scoring", json={
        "customer_id": "PERF-TEST",
        "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}
    })
    end_time = time.time()

    response_time = end_time - start_time

    # Assert performance requirements
    assert response.status_code == 200
    assert response_time < 0.5  # 500ms requirement
    assert response.elapsed.total_seconds() < 1.0  # 1s requirement


def test_api_load_performance():
    """Test performance under load"""
    import concurrent.futures
    import requests

    def make_request(customer_id):
        response = requests.post("http://localhost:8000/api/v1/scoring", json={
            "customer_id": customer_id,
            "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}
        })
        return response.elapsed.total_seconds()

    # Test with 50 concurrent requests
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        customer_ids = [f"LOAD-TEST-{i}" for i in range(50)]
        response_times = list(executor.map(make_request, customer_ids))

    # Calculate statistics
    avg_response_time = statistics.mean(response_times)
    p95_response_time = statistics.quantiles(response_times, n=20)[18]  # 95th percentile
    max_response_time = max(response_times)

    # Assert performance requirements
    assert avg_response_time < 0.3  # 300ms average
    assert p95_response_time < 0.8  # 800ms P95
    assert max_response_time < 2.0  # 2s maximum

    print(f"Average response time: {avg_response_time:.3f}s")
    print(f"P95 response time: {p95_response_time:.3f}s")
    print(f"Max response time: {max_response_time:.3f}s")
```

### **Tests Sécurité**
```python
# ✅ Example - Security test
import pytest
from scoring.api.main import app
from fastapi.testclient import TestClient


class TestSecurity:
    @pytest.fixture
    def client(self):
        return TestClient(app)

    def test_sql_injection_protection(self, client):
        """Test protection against SQL injection"""
        malicious_data = {
            "customer_id": "'; DROP TABLE customers; --",
            "features": {
                "age": 35,
                "income": 75000,
                "credit_score": 720,
                "debt_ratio": 0.3,
                "employment_years": 8
            }
        }

        response = client.post("/api/v1/scoring", json=malicious_data)

        # Should not crash or expose sensitive data
        assert response.status_code in [200, 422]  # Success or validation error
        if response.status_code == 200:
            data = response.json()
            assert "error" not in data  # No error in response

    def test_rate_limiting(self, client):
        """Test API rate limiting"""
        # Make many requests quickly
        responses = []
        for i in range(150):  # Exceed rate limit
            response = client.post("/api/v1/scoring", json={
                "customer_id": f"RATE-TEST-{i}",
                "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}
            })
            responses.append(response.status_code)

        # Should have some rate limited responses
        rate_limited_count = sum(1 for status in responses if status == 429)
        assert rate_limited_count > 0, "Rate limiting not working"

    def test_input_validation(self, client):
        """Test comprehensive input validation"""
        test_cases = [
            # Oversized input
            {"customer_id": "A" * 1000, "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}},
            # Negative values
            {"customer_id": "NEG-TEST", "features": {"age": -5, "income": -1000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}},
            # Extreme values
            {"customer_id": "EXT-TEST", "features": {"age": 150, "income": 10000000, "credit_score": 1000, "debt_ratio": 5.0, "employment_years": 100}},
            # Missing required fields
            {"customer_id": "MISS-TEST", "features": {"age": 35}},
            # Wrong data types
            {"customer_id": "TYPE-TEST", "features": {"age": "thirty-five", "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}},
        ]

        for i, test_data in enumerate(test_cases):
            response = client.post("/api/v1/scoring", json=test_data)

            # Should either succeed with validation or fail gracefully
            assert response.status_code in [200, 422], f"Test case {i} failed with status {response.status_code}"

            if response.status_code == 422:
                data = response.json()
                assert "detail" in data, f"Validation error details missing for test case {i}"

    def test_authentication_required(self, client):
        """Test that authentication is required"""
        # Try request without auth
        response = client.post("/api/v1/scoring", json={
            "customer_id": "AUTH-TEST",
            "features": {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8}
        })

        # Should require authentication
        assert response.status_code in [401, 403], "Authentication not enforced"

    def test_authorization_levels(self, client):
        """Test different authorization levels"""
        # Test with different user roles
        roles = ["viewer", "editor", "admin"]

        for role in roles:
            # Simulate different auth tokens
            headers = {"Authorization": f"Bearer {role}-token"}

            response = client.get("/api/v1/admin/stats", headers=headers)

            if role == "admin":
                assert response.status_code == 200, f"Admin should access admin endpoints"
            elif role == "viewer":
                assert response.status_code in [200, 403], f"Viewer access level incorrect"
            else:
                # Editor permissions
                assert response.status_code in [200, 403], f"Editor access level incorrect"
```

---

## 📝 **PROCESSUS PULL REQUEST**

### **Template PR**

#### **Titre PR**
```
type(scope): description

Types: feat, fix, docs, style, refactor, test, chore
Scopes: api, ml, infra, docs, tests, security
```

#### **Description PR**
```markdown
## Description
[Description détaillée des changements]

## Type de changement
- [ ] 🐛 Correction bug
- [ ] ✨ Nouvelle fonctionnalité
- [ ] 💥 Breaking change
- [ ] 📚 Documentation
- [ ] 🎨 Style
- [ ] ♻️ Refactoring
- [ ] 🧪 Tests
- [ ] 🔧 Maintenance

## Checklist
- [ ] Tests unitaires ajoutés/modifiés
- [ ] Tests intégration passent
- [ ] Documentation mise à jour
- [ ] Code respecte standards
- [ ] Sécurité vérifiée
- [ ] Performance testée

## Tests
- [ ] Tests locaux passent
- [ ] CI/CD passe
- [ ] Tests performance OK

## Breaking Changes
[Liste changements cassants si applicable]

## Migration Guide
[Guide migration si nécessaire]

Fixes #123
```

### **Review Process**

#### **Checklist Reviewer**
```markdown
## Code Review Checklist

### Fonctionnalité
- [ ] Code fait ce qui est demandé
- [ ] Logique métier correcte
- [ ] Edge cases gérés

### Qualité Code
- [ ] Respecte standards coding
- [ ] Noms variables/fonctions clairs
- [ ] Commentaires appropriés
- [ ] Pas de code dupliqué

### Tests
- [ ] Tests unitaires présents
- [ ] Tests d'intégration ajoutés
- [ ] Coverage adequate
- [ ] Tests passent

### Sécurité
- [ ] Pas de vulnérabilités évidentes
- [ ] Données sensibles protégées
- [ ] Authentification/autorisation correcte

### Performance
- [ ] Pas de bottlenecks évidents
- [ ] Requêtes DB optimisées
- [ ] Cache utilisé appropriément

### Documentation
- [ ] Code autodocumenté
- [ ] README mis à jour si nécessaire
- [ ] API documentation à jour

## Feedback
[Commentaires spécifiques, suggestions d'amélioration]
```

### **Étapes Validation PR**

1. **Validation Automatique**
   ```bash
   # Linting
   make lint

   # Tests
   make test-all

   # Sécurité
   make security-scan

   # Performance
   make performance-test
   ```

2. **Review Manuelle**
   - Code review par maintainer
   - Tests fonctionnels
   - Documentation review

3. **Merge**
   - Squash and merge
   - Delete branch
   - Update changelog

---

## 🏷️ **CONVENTIONS COMMIT**

### **Format Commit**

```
type(scope): description

[body optionnel]

[footer optionnel]
```

### **Types Commit**

| Type | Description |
|------|-------------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction bug |
| `docs` | Changements documentation |
| `style` | Changements style (formatting, etc.) |
| `refactor` | Refactoring code |
| `test` | Ajout/modification tests |
| `chore` | Maintenance, tooling |

### **Scopes**

| Scope | Description |
|-------|-------------|
| `api` | API endpoints, controllers |
| `ml` | Machine learning, modèles |
| `infra` | Infrastructure, déploiement |
| `docs` | Documentation |
| `tests` | Tests |
| `security` | Sécurité, authentification |
| `ui` | Interface utilisateur |
| `db` | Base de données, migrations |

### **Exemples Commits**

```bash
# Nouvelle fonctionnalité
feat(api): add batch scoring endpoint

- Add POST /api/v1/scoring/batch endpoint
- Support up to 100 customers per request
- Add request validation and error handling
- Update API documentation

# Correction bug
fix(ml): handle edge case in credit scoring model

Customer with no credit history was causing division by zero
in risk calculation. Added null check and default values.

Fixes #456

# Refactoring
refactor(db): optimize customer data queries

- Add database indexes for frequently queried fields
- Implement query result caching
- Reduce average query time from 150ms to 45ms

# Tests
test(api): add comprehensive scoring API tests

- Add unit tests for all API endpoints
- Add integration tests with real database
- Add performance tests for high load scenarios
- Coverage increased from 75% to 92%
```

---

## 🐛 **SIGNALEMENT BUGS**

### **Template Bug Report**

```markdown
## Bug Report

### Description
[Description claire et concise du bug]

### Steps to Reproduce
1. Aller sur '...'
2. Cliquer sur '....'
3. Voir erreur

### Expected Behavior
[Comportement attendu]

### Actual Behavior
[Comportement actuel]

### Screenshots
[Si applicable, ajouter screenshots]

### Environment
- OS: [e.g. Windows 10, macOS 12.1]
- Browser: [e.g. Chrome 100.0, Safari 15.1]
- Version: [e.g. v2.1.0]

### Additional Context
[Informations supplémentaires, logs, configuration, etc.]
```

### **Template Feature Request**

```markdown
## Feature Request

### Problem Statement
[Description du problème que cette feature résoudrait]

### Proposed Solution
[Description de la solution proposée]

### Alternative Solutions
[Solutions alternatives considérées]

### Additional Context
[Mockups, examples, références, etc.]

### Acceptance Criteria
- [ ] Critère 1
- [ ] Critère 2
- [ ] Critère 3
```

---

## 🎯 **BEST PRACTICES**

### **Code Reviews**

#### **Guidelines Reviewer**
- **Soyez constructif** : Focus sur le code, pas la personne
- **Expliquez votre raisonnement** : Pourquoi ce changement est nécessaire
- **Suggérez, n'imposez pas** : "Considérez..." plutôt que "Faites..."
- **Priorisez** : Bugs critiques > Améliorations > Nitpicks

#### **Guidelines Author**
- **Répondez à tous les commentaires** : Même si vous n'acceptez pas
- **Expliquez vos choix** : Pourquoi vous avez fait comme ça
- **Demandez clarification** : Si quelque chose n'est pas clair
- **Itérez rapidement** : Plus vite vous répondez, plus vite c'est mergé

### **Development Workflow**

#### **Branch Strategy**
```bash
# Main branches
main          # Production code
develop       # Integration branch

# Feature branches
feature/feat-name
bugfix/bug-name
hotfix/critical-fix

# Release branches
release/v1.2.0
```

#### **Workflow Git**
```bash
# Démarrer nouvelle feature
git checkout develop
git pull origin develop
git checkout -b feature/amazing-feature

# Commits réguliers
git add .
git commit -m "feat: implement core logic"

# Rebase avant PR
git fetch origin
git rebase origin/develop

# Push et PR
git push origin feature/amazing-feature
```

### **Communication**

#### **Channels**
- **GitHub Issues** : Bugs, features, discussions techniques
- **Pull Requests** : Code reviews, feedback
- **Slack/Discord** : Questions rapides, discussions générales
- **Documentation** : Guides, best practices, décisions d'architecture

#### **Code of Conduct**
- **Respect** : Tous les contributeurs méritent respect
- **Inclusivité** : Bienvenue à tous, indépendamment background
- **Collaboration** : Travailler ensemble pour le bien du projet
- **Responsabilité** : Prendre responsabilité de ses actions

---

## 🏆 **RECONNAISSANCE**

### **Contributors Hall of Fame**

Contributions appréciées et reconnues :
- ⭐ **Top Contributors** : Badges spéciaux
- 🏅 **First PR** : Badge première contribution
- 🎯 **Bug Hunter** : Badge pour corrections bugs critiques
- 🚀 **Feature Champion** : Badge pour features majeures
- 📚 **Documentation Hero** : Badge pour améliorations docs

### **Monthly Recognition**

Chaque mois, nous célébrons :
- **Contributor of the Month**
- **Most Valuable PR**
- **Security Champion**
- **Testing Excellence**

---

**🤝 Guide contribution complet !**

*Development Workflow • Code Standards • Testing Strategy*
*PR Process • Best Practices • Recognition Program* 🚀