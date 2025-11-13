#!/usr/bin/env python3
"""
Locust Load Testing for MLOps Scoring Platform
Advanced performance testing with realistic scenarios
"""

import json
import random
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from locust import HttpUser, TaskSet, between, constant, tag, task
from locust.exception import StopUser


class BaseTestUser(HttpUser):
    """Base user class with common functionality"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.auth_token = None
        self.customer_id = None
        self.session_start = time.time()

    def on_start(self):
        """Initialize user session"""
        self.customer_id = f"CUST{random.randint(1000, 9999)}"
        self.session_start = time.time()

        # Authenticate if required
        if hasattr(self, 'requires_auth') and self.requires_auth:
            self.authenticate()

    def on_stop(self):
        """Cleanup user session"""
        session_duration = time.time() - self.session_start
        self.environment.events.request.fire(
            request_type="SESSION",
            name="session_duration",
            response_time=int(session_duration * 1000),
            response_length=0,
            exception=None,
            context=self.context()
        )

    def authenticate(self):
        """Authenticate user with Keycloak"""
        auth_data = {
            "username": f"user{random.randint(1, 100)}",
            "password": "password123",
            "grant_type": "password",
            "client_id": "scoring-api"
        }

        with self.client.post("/auth/realms/mlops-scoring-platform/protocol/openid-connect/token",
                            json=auth_data,
                            catch_response=True) as response:
            if response.status_code == 200:
                self.auth_token = response.json().get("access_token")
                response.success()
            else:
                response.failure(f"Authentication failed: {response.status_code}")

    def get_auth_headers(self) -> Dict[str, str]:
        """Get authorization headers"""
        if self.auth_token:
            return {"Authorization": f"Bearer {self.auth_token}"}
        return {}


class ScoringAPITasks(TaskSet):
    """Task set for Scoring API testing"""

    @tag('scoring', 'api')
    @task(5)
    def score_credit_basic(self):
        """Basic credit scoring request"""
        payload = {
            "customer_id": self.user.customer_id,
            "features": {
                "age": random.randint(18, 80),
                "income": random.normalvariate(50000, 15000),
                "employment_years": random.randint(0, 40),
                "debt_ratio": random.uniform(0, 1),
                "revolving_utilization": random.uniform(0, 1)
            }
        }

        headers = {"Content-Type": "application/json"}
        headers.update(self.user.get_auth_headers())

        with self.client.post("/score",
                            json=payload,
                            headers=headers,
                            catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "credit_score" in data and "risk_level" in data:
                    response.success()
                else:
                    response.failure("Invalid response format")
            elif response.status_code == 401:
                response.failure("Authentication required")
            elif response.status_code == 429:
                response.success()  # Rate limiting is expected
            else:
                response.failure(f"Unexpected status: {response.status_code}")

    @tag('scoring', 'batch')
    @task(2)
    def score_credit_batch(self):
        """Batch credit scoring request"""
        batch_size = random.randint(5, 20)
        customers = []

        for i in range(batch_size):
            customers.append({
                "customer_id": f"CUST{random.randint(1000, 9999)}",
                "features": {
                    "age": random.randint(18, 80),
                    "income": random.normalvariate(50000, 15000),
                    "employment_years": random.randint(0, 40),
                    "debt_ratio": random.uniform(0, 1),
                    "revolving_utilization": random.uniform(0, 1)
                }
            })

        payload = {"customers": customers}
        headers = {"Content-Type": "application/json"}
        headers.update(self.user.get_auth_headers())

        with self.client.post("/score/batch",
                            json=payload,
                            headers=headers,
                            catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "results" in data and len(data["results"]) == batch_size:
                    response.success()
                else:
                    response.failure("Invalid batch response")
            elif response.status_code == 429:
                response.success()  # Rate limiting expected for large batches
            else:
                response.failure(f"Batch scoring failed: {response.status_code}")

    @tag('health', 'monitoring')
    @task(3)
    def health_check(self):
        """API health check"""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Health check failed: {response.status_code}")

    @tag('features', 'feast')
    @task(2)
    def get_customer_features(self):
        """Retrieve customer features from Feast"""
        headers = self.user.get_auth_headers()

        with self.client.get(f"/features/{self.user.customer_id}",
                           headers=headers,
                           catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "features" in data:
                    response.success()
                else:
                    response.failure("Invalid features response")
            elif response.status_code == 404:
                response.success()  # Customer not found is acceptable
            else:
                response.failure(f"Features retrieval failed: {response.status_code}")

    @tag('features', 'push')
    @task(1)
    def push_real_time_features(self):
        """Push real-time features"""
        payload = {
            "customer_id": self.user.customer_id,
            "features": {
                "current_balance": random.uniform(0, 100000),
                "last_transaction_amount": random.uniform(10, 5000),
                "login_attempts_24h": random.randint(0, 10),
                "device_fingerprint_score": random.uniform(0, 1),
                "ip_risk_score": random.uniform(0, 1)
            }
        }

        headers = {"Content-Type": "application/json"}
        headers.update(self.user.get_auth_headers())

        with self.client.post("/features/update",
                            json=payload,
                            headers=headers,
                            catch_response=True) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Feature push failed: {response.status_code}")


class MLflowTasks(TaskSet):
    """Task set for MLflow testing"""

    @tag('mlflow', 'models')
    @task(3)
    def list_experiments(self):
        """List MLflow experiments"""
        with self.client.get("/api/2.0/mlflow/experiments/list",
                           catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "experiments" in data:
                    response.success()
                else:
                    response.failure("Invalid experiments response")
            else:
                response.failure(f"Experiments list failed: {response.status_code}")

    @tag('mlflow', 'models')
    @task(2)
    def get_model_versions(self):
        """Get model versions"""
        with self.client.get("/api/2.0/mlflow/registered-models/list",
                           catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Model versions failed: {response.status_code}")

    @tag('mlflow', 'tracking')
    @task(1)
    def log_metrics(self):
        """Log metrics to MLflow (simulated)"""
        # This would normally log real metrics
        time.sleep(random.uniform(0.1, 0.5))  # Simulate processing
        self.environment.events.request.fire(
            request_type="MLFLOW",
            name="log_metrics",
            response_time=random.randint(100, 500),
            response_length=0,
            exception=None,
            context=self.context()
        )


class FeastTasks(TaskSet):
    """Task set for Feast Feature Store testing"""

    @tag('feast', 'online')
    @task(4)
    def get_online_features(self):
        """Get online features from Feast"""
        payload = {
            "features": [
                "customer_features:age",
                "customer_features:income",
                "transaction_features:total_transaction_amount_30d"
            ],
            "entities": [{"customer_id": f"CUST{random.randint(1000, 9999)}"}]
        }

        headers = {"Content-Type": "application/json"}

        with self.client.post("/api/v1/online-features",
                            json=payload,
                            headers=headers,
                            catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "results" in data:
                    response.success()
                else:
                    response.failure("Invalid Feast response")
            else:
                response.failure(f"Feast online features failed: {response.status_code}")

    @tag('feast', 'health')
    @task(2)
    def feast_health_check(self):
        """Feast health check"""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Feast health check failed: {response.status_code}")


class KafkaTasks(TaskSet):
    """Task set for Kafka testing"""

    @tag('kafka', 'producer')
    @task(2)
    def send_kafka_message(self):
        """Send message to Kafka topic"""
        payload = {
            "customer_id": f"CUST{random.randint(1000, 9999)}",
            "event_type": "transaction",
            "amount": random.uniform(10, 5000),
            "timestamp": datetime.now().isoformat()
        }

        headers = {"Content-Type": "application/json"}

        with self.client.post("/kafka/topics/transactions/messages",
                            json=payload,
                            headers=headers,
                            catch_response=True) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Kafka message send failed: {response.status_code}")

    @tag('kafka', 'consumer')
    @task(1)
    def consume_kafka_messages(self):
        """Consume messages from Kafka topic"""
        with self.client.get("/kafka/topics/transactions/messages?limit=10",
                           catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if "messages" in data:
                    response.success()
                else:
                    response.failure("Invalid Kafka response")
            else:
                response.failure(f"Kafka consume failed: {response.status_code}")


# User Classes
class ScoringAPIUser(BaseTestUser):
    """User for Scoring API testing"""
    tasks = [ScoringAPITasks]
    wait_time = between(1, 3)
    requires_auth = True

    # Weight: 60% of users
    weight = 6


class MLflowUser(BaseTestUser):
    """User for MLflow testing"""
    tasks = [MLflowTasks]
    wait_time = constant(2)
    requires_auth = False

    # Weight: 20% of users
    weight = 2


class FeastUser(BaseTestUser):
    """User for Feast testing"""
    tasks = [FeastTasks]
    wait_time = between(2, 5)
    requires_auth = False

    # Weight: 15% of users
    weight = 1.5


class KafkaUser(BaseTestUser):
    """User for Kafka testing"""
    tasks = [KafkaTasks]
    wait_time = between(1, 4)
    requires_auth = False

    # Weight: 5% of users
    weight = 0.5


class MixedWorkloadUser(BaseTestUser):
    """User performing mixed operations across all services"""
    tasks = [ScoringAPITasks, MLflowTasks, FeastTasks, KafkaTasks]
    wait_time = between(1, 5)
    requires_auth = True

    # Weight: 10% of users (complex scenarios)
    weight = 1


# Test Scenarios
class LoadTestScenario:
    """Load testing scenario with realistic user distribution"""

    @staticmethod
    def get_user_classes():
        return [
            ScoringAPIUser,
            MLflowUser,
            FeastUser,
            KafkaUser,
            MixedWorkloadUser
        ]

    @staticmethod
    def get_test_configuration(test_type: str) -> Dict:
        """Get test configuration based on type"""

        configs = {
            "smoke": {
                "users": 5,
                "spawn_rate": 1,
                "run_time": "1m",
                "description": "Smoke test - basic functionality"
            },
            "load": {
                "users": 50,
                "spawn_rate": 5,
                "run_time": "5m",
                "description": "Load test - normal production load"
            },
            "stress": {
                "users": 200,
                "spawn_rate": 10,
                "run_time": "10m",
                "description": "Stress test - high load"
            },
            "spike": {
                "users": 500,
                "spawn_rate": 50,
                "run_time": "2m",
                "description": "Spike test - sudden traffic increase"
            },
            "endurance": {
                "users": 30,
                "spawn_rate": 2,
                "run_time": "30m",
                "description": "Endurance test - sustained load"
            },
            "volume": {
                "users": 20,
                "spawn_rate": 1,
                "run_time": "10m",
                "description": "Volume test - large data processing"
            }
        }

        return configs.get(test_type, configs["load"])


# Export for external usage
__all__ = [
    'BaseTestUser',
    'ScoringAPIUser',
    'MLflowUser',
    'FeastUser',
    'KafkaUser',
    'MixedWorkloadUser',
    'LoadTestScenario'
]