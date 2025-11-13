#!/usr/bin/env python3
"""
MLOps Scoring Platform - Cache & ML Model Performance Optimization
Optimisation avancée du cache Redis et des modèles ML
"""

import redis
import json
import time
import asyncio
import threading
from typing import Dict, List, Any, Optional, Tuple
import logging
import pickle
import numpy as np
from concurrent.futures import ThreadPoolExecutor
import psutil
import gc

# Configuration
REDIS_CONFIG = {
    "host": "localhost",
    "port": 6379,
    "password": None,
    "db": 0,
    "decode_responses": False  # Pour les données binaires
}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class RedisOptimizer:
    """Optimiseur de performance pour Redis"""

    def __init__(self, redis_config: Dict[str, Any]):
        self.redis_config = redis_config
        self.redis_client = None
        self.pipeline = None
        self.cache_stats = {
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "deletes": 0,
            "errors": 0
        }
        self.memory_stats = {}
        self.key_patterns = {}

    def connect(self):
        """Établir la connexion Redis"""
        try:
            self.redis_client = redis.Redis(**self.redis_config)
            self.redis_client.ping()
            logger.info("✅ Connected to Redis")
        except Exception as e:
            logger.error(f"❌ Failed to connect to Redis: {e}")
            raise

    def init_pipeline(self):
        """Initialiser un pipeline Redis pour les opérations groupées"""
        if not self.redis_client:
            self.connect()
        self.pipeline = self.redis_client.pipeline()

    def execute_pipeline(self):
        """Exécuter le pipeline et retourner les résultats"""
        if self.pipeline:
            try:
                results = self.pipeline.execute()
                self.pipeline.reset()
                return results
            except Exception as e:
                logger.error(f"Pipeline execution failed: {e}")
                self.pipeline.reset()
                raise
        return []

    def optimize_memory_usage(self):
        """Optimiser l'utilisation mémoire de Redis"""
        logger.info("Optimizing Redis memory usage...")

        if not self.redis_client:
            self.connect()

        # Analyser l'utilisation mémoire actuelle
        info = self.redis_client.info("memory")
        used_memory = info.get("used_memory", 0)
        max_memory = info.get("maxmemory", 0)
        memory_usage_percent = (used_memory / max_memory * 100) if max_memory > 0 else 0

        logger.info(f"Current memory usage: {memory_usage_percent:.1f}% ({used_memory/1024/1024:.1f}MB)")

        # Politiques d'éviction optimisées
        if memory_usage_percent > 80:
            # Mode agressif pour haute utilisation
            self.redis_client.config_set("maxmemory-policy", "allkeys-lru")
            logger.info("Set aggressive LRU eviction policy")
        elif memory_usage_percent > 60:
            # Mode modéré
            self.redis_client.config_set("maxmemory-policy", "volatile-lru")
            logger.info("Set moderate LRU eviction policy")
        else:
            # Mode conservateur
            self.redis_client.config_set("maxmemory-policy", "volatile-ttl")
            logger.info("Set conservative TTL eviction policy")

        # Optimiser la fragmentation mémoire
        self.redis_client.config_set("activedefrag", "yes")
        self.redis_client.config_set("active-defrag-threshold-lower", "10")
        self.redis_client.config_set("active-defrag-threshold-upper", "100")

        logger.info("Memory optimization completed")

    def implement_intelligent_caching(self):
        """Implémenter une stratégie de cache intelligente"""
        logger.info("Implementing intelligent caching strategy...")

        # Définir les patterns de clés pour différents types de données
        self.key_patterns = {
            "model": "model:{model_name}:{version}",
            "features": "features:{customer_id}",
            "stats": "stats:{feature_name}",
            "predictions": "pred:{customer_id}:{model_version}",
            "batch": "batch:{batch_id}",
            "session": "session:{session_id}"
        }

        # TTL optimisés par type de données
        self.ttl_config = {
            "model": 3600 * 24,      # 24h pour les modèles
            "features": 1800,        # 30min pour les features
            "stats": 3600 * 4,       # 4h pour les stats
            "predictions": 900,      # 15min pour les prédictions
            "batch": 3600,           # 1h pour les batches
            "session": 1800          # 30min pour les sessions
        }

        # Pré-charger les données fréquemment utilisées
        self._preload_frequent_data()

        logger.info("Intelligent caching strategy implemented")

    def _preload_frequent_data(self):
        """Pré-charger les données fréquemment utilisées"""
        # Simuler le pré-chargement de statistiques
        common_features = ["age", "income", "credit_score", "debt_ratio", "employment_years"]

        for feature in common_features:
            stats_key = f"stats:{feature}"
            # Simuler des stats pré-calculées
            stats = {
                "mean": 50000 if feature == "income" else 35 if feature == "age" else 650,
                "std": 20000 if feature == "income" else 10 if feature == "age" else 100,
                "count": 10000,
                "last_updated": time.time()
            }

            self.set_cached_value(stats_key, json.dumps(stats), self.ttl_config["stats"])

        logger.info("Preloaded frequent data into cache")

    def set_cached_value(self, key: str, value: Any, ttl: int = None, serialize: bool = True):
        """Stocker une valeur dans le cache avec optimisation"""
        try:
            if not self.redis_client:
                self.connect()

            # Sérialisation optimisée
            if serialize and isinstance(value, (dict, list)):
                cached_value = json.dumps(value).encode('utf-8')
            elif isinstance(value, str):
                cached_value = value.encode('utf-8')
            else:
                cached_value = pickle.dumps(value)

            # Utiliser le pipeline pour les opérations groupées
            if self.pipeline:
                self.pipeline.set(key, cached_value, ex=ttl)
            else:
                self.redis_client.set(key, cached_value, ex=ttl)

            self.cache_stats["sets"] += 1

        except Exception as e:
            logger.error(f"Cache set failed for key {key}: {e}")
            self.cache_stats["errors"] += 1

    def get_cached_value(self, key: str, deserialize: bool = True) -> Optional[Any]:
        """Récupérer une valeur du cache avec optimisation"""
        try:
            if not self.redis_client:
                self.connect()

            # Utiliser le pipeline si disponible
            if self.pipeline:
                self.pipeline.get(key)
                return None  # Résultat sera traité lors de execute_pipeline

            cached_value = self.redis_client.get(key)

            if cached_value is None:
                self.cache_stats["misses"] += 1
                return None

            self.cache_stats["hits"] += 1

            # Désérialisation optimisée
            if deserialize:
                try:
                    # Essayer JSON d'abord
                    return json.loads(cached_value.decode('utf-8'))
                except (json.JSONDecodeError, UnicodeDecodeError):
                    # Fallback vers pickle
                    return pickle.loads(cached_value)

            return cached_value

        except Exception as e:
            logger.error(f"Cache get failed for key {key}: {e}")
            self.cache_stats["errors"] += 1
            return None

    def implement_cache_compression(self):
        """Implémenter la compression des données cache"""
        logger.info("Implementing cache compression...")

        # Identifier les clés volumineuses
        large_keys = []
        all_keys = self.redis_client.keys("*")

        for key in all_keys[:100]:  # Analyser un échantillon
            try:
                size = self.redis_client.memory_usage(key.decode('utf-8') if isinstance(key, bytes) else key)
                if size and size > 1024:  # Plus de 1KB
                    large_keys.append((key, size))
            except:
                continue

        # Compresser les grandes valeurs
        import gzip
        for key, size in large_keys:
            try:
                key_str = key.decode('utf-8') if isinstance(key, bytes) else key
                value = self.redis_client.get(key_str)

                if value and len(value) > 1024:
                    # Compresser
                    compressed = gzip.compress(value)
                    if len(compressed) < len(value) * 0.8:  # Au moins 20% de gain
                        self.redis_client.set(key_str, compressed)
                        logger.info(f"Compressed key {key_str}: {len(value)} -> {len(compressed)} bytes")

            except Exception as e:
                logger.warning(f"Failed to compress key {key}: {e}")

        logger.info("Cache compression completed")

    def optimize_cache_distribution(self):
        """Optimiser la distribution des données cache"""
        logger.info("Optimizing cache key distribution...")

        # Analyser la distribution des clés
        key_distribution = {}
        all_keys = self.redis_client.keys("*")

        for key in all_keys[:1000]:  # Échantillon
            try:
                key_str = key.decode('utf-8') if isinstance(key, bytes) else key
                prefix = key_str.split(':')[0] if ':' in key_str else 'other'
                key_distribution[prefix] = key_distribution.get(prefix, 0) + 1
            except:
                continue

        # Log distribution
        logger.info("Cache key distribution:")
        for prefix, count in sorted(key_distribution.items(), key=lambda x: x[1], reverse=True):
            logger.info(f"  {prefix}: {count} keys")

        # Recommander des optimisations
        total_keys = sum(key_distribution.values())
        recommendations = []

        for prefix, count in key_distribution.items():
            percentage = (count / total_keys) * 100
            if percentage > 50:
                recommendations.append(f"High concentration of {prefix} keys ({percentage:.1f}%) - consider sharding")
            elif percentage < 1:
                recommendations.append(f"Low usage of {prefix} keys ({percentage:.1f}%) - consider consolidation")

        return recommendations

    def get_cache_performance_metrics(self) -> Dict[str, Any]:
        """Récupérer les métriques de performance du cache"""
        total_requests = self.cache_stats["hits"] + self.cache_stats["misses"]
        hit_rate = (self.cache_stats["hits"] / total_requests * 100) if total_requests > 0 else 0

        return {
            "cache_stats": self.cache_stats,
            "hit_rate": hit_rate,
            "total_requests": total_requests,
            "redis_info": self.redis_client.info() if self.redis_client else {},
            "memory_stats": self.memory_stats
        }

class MLModelOptimizer:
    """Optimiseur de performance pour les modèles ML"""

    def __init__(self):
        self.model_cache = {}
        self.prediction_stats = {
            "total_predictions": 0,
            "avg_latency": 0,
            "model_switches": 0,
            "cache_hits": 0,
            "errors": 0
        }
        self.executor = ThreadPoolExecutor(max_workers=4)

    def load_model_optimized(self, model_name: str, version: str = "latest") -> Any:
        """Charger un modèle avec optimisation"""
        cache_key = f"{model_name}:{version}"

        # Vérifier le cache des modèles
        if cache_key in self.model_cache:
            logger.info(f"Model cache hit: {cache_key}")
            return self.model_cache[cache_key]

        # Simuler le chargement d'un modèle
        # En production, ceci chargerait un vrai modèle ML
        logger.info(f"Loading model: {cache_key}")

        # Simulation d'un modèle simple
        model = {
            "name": model_name,
            "version": version,
            "type": "xgboost",
            "features": ["age", "income", "credit_score", "debt_ratio", "employment_years"],
            "parameters": {
                "max_depth": 6,
                "learning_rate": 0.1,
                "n_estimators": 100
            },
            "loaded_at": time.time(),
            "performance_metrics": {
                "accuracy": 0.85,
                "precision": 0.82,
                "recall": 0.78
            }
        }

        # Mettre en cache
        self.model_cache[cache_key] = model

        return model

    def predict_optimized(self, model: Dict[str, Any], features: Dict[str, Any]) -> Dict[str, Any]:
        """Effectuer une prédiction optimisée"""
        start_time = time.time()

        try:
            # Validation des features
            required_features = model.get("features", [])
            missing_features = [f for f in required_features if f not in features]

            if missing_features:
                raise ValueError(f"Missing required features: {missing_features}")

            # Prétraitement optimisé
            processed_features = self._preprocess_features_optimized(features)

            # Prédiction simulée optimisée
            prediction_result = self._predict_simulated_optimized(processed_features, model)

            # Calcul du temps de latence
            latency = time.time() - start_time

            # Mise à jour des statistiques
            self.prediction_stats["total_predictions"] += 1
            self.prediction_stats["avg_latency"] = (
                (self.prediction_stats["avg_latency"] * (self.prediction_stats["total_predictions"] - 1)) + latency
            ) / self.prediction_stats["total_predictions"]

            result = {
                **prediction_result,
                "latency_ms": latency * 1000,
                "model_version": model["version"],
                "timestamp": time.time()
            }

            return result

        except Exception as e:
            self.prediction_stats["errors"] += 1
            logger.error(f"Prediction failed: {e}")
            raise

    def _preprocess_features_optimized(self, features: Dict[str, Any]) -> np.ndarray:
        """Prétraitement optimisé des features"""
        # Conversion en array numpy optimisée
        feature_values = []
        for feature in ["age", "income", "credit_score", "debt_ratio", "employment_years"]:
            value = features.get(feature, 0)

            # Normalisation rapide
            if feature == "income":
                value = min(value / 10000, 10)  # Normalisation simple
            elif feature == "age":
                value = min(value / 10, 8)
            elif feature == "credit_score":
                value = (value - 300) / 550  # Scale 0-1
            elif feature == "debt_ratio":
                value = min(value, 1.0)
            elif feature == "employment_years":
                value = min(value / 2, 10)

            feature_values.append(value)

        return np.array(feature_values)

    def _predict_simulated_optimized(self, features: np.ndarray, model: Dict[str, Any]) -> Dict[str, Any]:
        """Prédiction simulée optimisée"""
        # Calcul de score simplifié mais optimisé
        weights = np.array([0.1, 0.3, 0.4, -0.2, 0.15])  # Poids des features
        bias = 0.5

        # Calcul vectorisé optimisé
        score = np.dot(features, weights) + bias

        # Application de sigmoid pour probabilité
        probability = 1 / (1 + np.exp(-score))

        # Calcul du score de crédit
        credit_score = int(300 + (550 * probability))

        # Détermination du niveau de risque
        if credit_score >= 750:
            risk_level = "LOW"
        elif credit_score >= 650:
            risk_level = "MEDIUM"
        elif credit_score >= 550:
            risk_level = "HIGH"
        else:
            risk_level = "VERY_HIGH"

        # Calcul du montant approuvé
        base_amount = features[1] * 10000 * 2  # 2x le revenu annuel
        risk_multiplier = {"LOW": 1.0, "MEDIUM": 0.8, "HIGH": 0.6, "VERY_HIGH": 0.3}
        approved_amount = base_amount * risk_multiplier.get(risk_level, 0.5)

        return {
            "credit_score": max(300, min(850, credit_score)),
            "risk_level": risk_level,
            "approved_amount": max(5000, min(500000, approved_amount)),
            "confidence": float(probability),
            "feature_contributions": {
                "age": float(weights[0] * features[0]),
                "income": float(weights[1] * features[1]),
                "credit_score": float(weights[2] * features[2]),
                "debt_ratio": float(weights[3] * features[3]),
                "employment_years": float(weights[4] * features[4])
            }
        }

    async def batch_predict_optimized(self, model: Dict[str, Any], batch_features: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Prédiction par lot optimisée"""
        logger.info(f"Processing batch prediction of {len(batch_features)} items")

        # Traitement parallèle optimisé
        loop = asyncio.get_event_loop()

        def predict_single(features):
            return self.predict_optimized(model, features)

        # Exécuter en parallèle
        with ThreadPoolExecutor(max_workers=min(len(batch_features), 8)) as executor:
            tasks = [loop.run_in_executor(executor, predict_single, features) for features in batch_features]
            results = await asyncio.gather(*tasks, return_exceptions=True)

        # Traiter les résultats
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(f"Batch prediction failed for item {i}: {result}")
                processed_results.append({
                    "error": str(result),
                    "customer_id": batch_features[i].get("customer_id", f"unknown-{i}")
                })
            else:
                processed_results.append(result)

        return processed_results

    def optimize_model_loading(self):
        """Optimiser le chargement des modèles"""
        logger.info("Optimizing model loading...")

        # Pré-charger les modèles fréquemment utilisés
        common_models = ["credit-scoring-v1", "credit-scoring-v2", "fraud-detection-v1"]

        for model_name in common_models:
            try:
                model = self.load_model_optimized(model_name)
                logger.info(f"Preloaded model: {model_name}")
            except Exception as e:
                logger.warning(f"Failed to preload model {model_name}: {e}")

        # Optimiser la mémoire des modèles
        gc.collect()  # Forcer le garbage collection

        logger.info("Model loading optimization completed")

    def implement_model_versioning_optimization(self):
        """Optimiser la gestion des versions de modèles"""
        logger.info("Optimizing model versioning...")

        # Implémenter un système de cache pour les versions
        self.model_versions = {
            "credit-scoring": {
                "latest": "v2.1",
                "stable": "v2.0",
                "experimental": "v3.0-beta"
            }
        }

        # Cache des métadonnées de version
        self.version_metadata = {
            "v2.1": {
                "accuracy": 0.87,
                "latency_ms": 45,
                "memory_mb": 150,
                "last_deployed": time.time()
            },
            "v2.0": {
                "accuracy": 0.85,
                "latency_ms": 52,
                "memory_mb": 140,
                "last_deployed": time.time() - 86400
            }
        }

        logger.info("Model versioning optimization implemented")

    def get_ml_performance_metrics(self) -> Dict[str, Any]:
        """Récupérer les métriques de performance ML"""
        return {
            "prediction_stats": self.prediction_stats,
            "model_cache_info": {
                "cached_models": len(self.model_cache),
                "cache_memory_mb": sum(
                    model.get("parameters", {}).get("estimated_memory_mb", 0)
                    for model in self.model_cache.values()
                )
            },
            "version_info": self.version_metadata,
            "system_resources": {
                "cpu_percent": psutil.cpu_percent(),
                "memory_percent": psutil.virtual_memory().percent,
                "active_threads": threading.active_count()
            }
        }

class PerformanceOptimizer:
    """Optimiseur global de performance"""

    def __init__(self):
        self.redis_optimizer = RedisOptimizer(REDIS_CONFIG)
        self.ml_optimizer = MLModelOptimizer()
        self.performance_metrics = {}

    def run_comprehensive_optimization(self):
        """Exécuter une optimisation complète"""
        logger.info("Starting comprehensive performance optimization...")

        try:
            # Optimisation Redis
            logger.info("Step 1: Optimizing Redis cache...")
            self.redis_optimizer.connect()
            self.redis_optimizer.optimize_memory_usage()
            self.redis_optimizer.implement_intelligent_caching()
            self.redis_optimizer.implement_cache_compression()

            # Optimisation ML
            logger.info("Step 2: Optimizing ML models...")
            self.ml_optimizer.optimize_model_loading()
            self.ml_optimizer.implement_model_versioning_optimization()

            # Tests de performance
            logger.info("Step 3: Running performance tests...")
            test_results = self.run_performance_tests()

            # Génération du rapport
            logger.info("Step 4: Generating optimization report...")
            report = self.generate_optimization_report(test_results)

            # Sauvegarder le rapport
            with open('performance-optimization-report.json', 'w') as f:
                json.dump(report, f, indent=2, default=str)

            logger.info("Performance optimization completed successfully!")
            logger.info("Report saved to: performance-optimization-report.json")

            return report

        except Exception as e:
            logger.error(f"Performance optimization failed: {e}")
            raise

    def run_performance_tests(self) -> Dict[str, Any]:
        """Exécuter des tests de performance"""
        logger.info("Running performance validation tests...")

        test_results = {
            "cache_performance": {},
            "ml_performance": {},
            "end_to_end": {}
        }

        # Test cache
        test_results["cache_performance"] = self.test_cache_performance()

        # Test ML
        test_results["ml_performance"] = self.test_ml_performance()

        # Test end-to-end
        test_results["end_to_end"] = self.test_end_to_end_performance()

        return test_results

    def test_cache_performance(self) -> Dict[str, Any]:
        """Tester les performances du cache"""
        logger.info("Testing cache performance...")

        # Test de charge du cache
        test_keys = [f"test:key:{i}" for i in range(1000)]
        test_data = {"data": "x" * 1000}  # 1KB de données

        # Test écriture
        start_time = time.time()
        for key in test_keys:
            self.redis_optimizer.set_cached_value(key, test_data, ttl=300)
        write_time = time.time() - start_time

        # Test lecture
        start_time = time.time()
        for key in test_keys:
            self.redis_optimizer.get_cached_value(key)
        read_time = time.time() - start_time

        # Nettoyage
        for key in test_keys:
            self.redis_optimizer.redis_client.delete(key)

        return {
            "write_throughput": len(test_keys) / write_time,
            "read_throughput": len(test_keys) / read_time,
            "avg_write_latency": write_time / len(test_keys) * 1000,
            "avg_read_latency": read_time / len(test_keys) * 1000,
            "cache_stats": self.redis_optimizer.get_cache_performance_metrics()
        }

    def test_ml_performance(self) -> Dict[str, Any]:
        """Tester les performances ML"""
        logger.info("Testing ML performance...")

        # Charger un modèle
        model = self.ml_optimizer.load_model_optimized("credit-scoring-v1")

        # Test de prédictions individuelles
        test_features = {
            "age": 35,
            "income": 75000,
            "credit_score": 720,
            "debt_ratio": 0.3,
            "employment_years": 8
        }

        # Test individuel
        individual_results = []
        for i in range(100):
            start_time = time.time()
            result = self.ml_optimizer.predict_optimized(model, test_features)
            latency = time.time() - start_time
            individual_results.append(latency)

        # Test par lot
        batch_features = [test_features] * 50
        start_time = time.time()

        async def run_batch():
            return await self.ml_optimizer.batch_predict_optimized(model, batch_features)

        batch_results = asyncio.run(run_batch())
        batch_time = time.time() - start_time

        return {
            "individual_predictions": len(individual_results),
            "avg_individual_latency": sum(individual_results) / len(individual_results) * 1000,
            "batch_predictions": len(batch_results),
            "batch_total_time": batch_time,
            "batch_throughput": len(batch_results) / batch_time,
            "ml_stats": self.ml_optimizer.get_ml_performance_metrics()
        }

    def test_end_to_end_performance(self) -> Dict[str, Any]:
        """Tester les performances end-to-end"""
        logger.info("Testing end-to-end performance...")

        # Simulation d'un workflow complet
        test_customer = {
            "customer_id": f"perf-test-{int(time.time())}",
            "features": {
                "age": 35,
                "income": 75000,
                "credit_score": 720,
                "debt_ratio": 0.3,
                "employment_years": 8
            }
        }

        # Mesurer le temps total
        start_time = time.time()

        # 1. Mise en cache des features
        features_key = f"features:{test_customer['customer_id']}"
        self.redis_optimizer.set_cached_value(features_key, test_customer["features"], ttl=1800)

        # 2. Chargement du modèle
        model = self.ml_optimizer.load_model_optimized("credit-scoring-v1")

        # 3. Prédiction
        prediction = self.ml_optimizer.predict_optimized(model, test_customer["features"])

        # 4. Mise en cache du résultat
        result_key = f"pred:{test_customer['customer_id']}:{model['version']}"
        self.redis_optimizer.set_cached_value(result_key, prediction, ttl=900)

        total_time = time.time() - start_time

        return {
            "total_time": total_time,
            "steps_breakdown": {
                "cache_features": 0.01,  # estimé
                "load_model": 0.05,      # estimé
                "prediction": prediction["latency_ms"] / 1000,
                "cache_result": 0.01     # estimé
            },
            "success": True
        }

    def generate_optimization_report(self, test_results: Dict[str, Any]) -> Dict[str, Any]:
        """Générer un rapport d'optimisation complet"""
        report = {
            "timestamp": time.time(),
            "optimization_summary": {
                "cache_optimized": True,
                "ml_models_optimized": True,
                "performance_tested": True
            },
            "test_results": test_results,
            "cache_metrics": self.redis_optimizer.get_cache_performance_metrics(),
            "ml_metrics": self.ml_optimizer.get_ml_performance_metrics(),
            "recommendations": []
        }

        # Générer des recommandations
        recommendations = []

        # Analyse cache
        cache_metrics = test_results["cache_performance"]
        if cache_metrics.get("avg_read_latency", 0) > 10:
            recommendations.append("Consider using Redis Cluster for better read performance")

        # Analyse ML
        ml_metrics = test_results["ml_performance"]
        if ml_metrics.get("avg_individual_latency", 0) > 100:
            recommendations.append("Consider model quantization or distillation for faster inference")

        # Analyse end-to-end
        e2e_metrics = test_results["end_to_end"]
        if e2e_metrics.get("total_time", 0) > 1.0:
            recommendations.append("Implement request batching and async processing for better throughput")

        report["recommendations"] = recommendations

        return report

def main():
    """Fonction principale"""
    print("⚡ MLOps Scoring Platform - Performance Optimization")
    print("="*60)

    optimizer = PerformanceOptimizer()

    try:
        # Exécuter l'optimisation complète
        report = optimizer.run_comprehensive_optimization()

        # Afficher un résumé
        print("\n" + "="*60)
        print("PERFORMANCE OPTIMIZATION SUMMARY")
        print("="*60)

        # Résultats des tests
        cache_perf = report["test_results"]["cache_performance"]
        ml_perf = report["test_results"]["ml_performance"]
        e2e_perf = report["test_results"]["end_to_end"]

        print("📊 Cache Performance:")
        print(f"  Read Throughput: {cache_perf.get('read_throughput', 0):.0f} ops/sec")
        print(f"  Write Throughput: {cache_perf.get('write_throughput', 0):.0f} ops/sec")
        print(f"  Read Latency: {cache_perf.get('avg_read_latency', 0)*1000:.1f}ms")

        print("\n🤖 ML Performance:")
        print(f"  Individual Predictions: {ml_perf.get('individual_predictions', 0)}")
        print(f"  Avg Latency: {ml_perf.get('avg_individual_latency', 0):.1f}ms")
        print(f"  Batch Throughput: {ml_perf.get('batch_throughput', 0):.1f} pred/sec")

        print("\n🔄 End-to-End Performance:")
        print(f"  Total Time: {e2e_perf.get('total_time', 0)*1000:.1f}ms")

        recommendations = report.get("recommendations", [])
        if recommendations:
            print(f"\n💡 Recommendations ({len(recommendations)}):")
            for i, rec in enumerate(recommendations, 1):
                print(f"  {i}. {rec}")

        print("\n✅ Performance optimization completed!")
        print("📊 Detailed report: performance-optimization-report.json")

    except Exception as e:
        print(f"❌ Performance optimization failed: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())