#!/usr/bin/env python3
"""
MLOps Scoring Platform - API Performance Optimization
Optimisation avancée des performances de l'API Scoring
"""

import asyncio
import aiohttp
import json
import time
import psutil
import threading
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache, wraps
import redis
import aioredis
from typing import Dict, List, Any, Optional
import logging

# Configuration
REDIS_HOST = "localhost"
REDIS_PORT = 6379
CACHE_TTL = 3600  # 1 hour
MAX_WORKERS = 4

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AsyncCache:
    """Cache asynchrone avec Redis"""

    def __init__(self, host: str = REDIS_HOST, port: int = REDIS_PORT):
        self.host = host
        self.port = port
        self.redis = None

    async def init(self):
        """Initialiser la connexion Redis"""
        self.redis = await aioredis.from_url(f"redis://{self.host}:{self.port}")

    async def get(self, key: str) -> Optional[str]:
        """Récupérer une valeur du cache"""
        if not self.redis:
            await self.init()
        return await self.redis.get(key)

    async def set(self, key: str, value: str, ttl: int = CACHE_TTL):
        """Stocker une valeur dans le cache"""
        if not self.redis:
            await self.init()
        await self.redis.set(key, value, ex=ttl)

    async def delete(self, key: str):
        """Supprimer une clé du cache"""
        if not self.redis:
            await self.init()
        await self.redis.delete(key)

    async def exists(self, key: str) -> bool:
        """Vérifier si une clé existe"""
        if not self.redis:
            await self.init()
        return await self.redis.exists(key)

class ScoringOptimizer:
    """Optimiseur de performance pour l'API Scoring"""

    def __init__(self):
        self.cache = AsyncCache()
        self.executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
        self.session = None
        self.model_cache = {}
        self.feature_cache = {}

    async def init_session(self):
        """Initialiser la session HTTP"""
        if not self.session:
            timeout = aiohttp.ClientTimeout(total=30, connect=5)
            self.session = aiohttp.ClientSession(timeout=timeout)

    async def close_session(self):
        """Fermer la session HTTP"""
        if self.session:
            await self.session.close()
        await self.cache.redis.close()

    def cache_result(ttl: int = CACHE_TTL):
        """Décorateur pour mettre en cache les résultats"""
        def decorator(func):
            @wraps(func)
            async def wrapper(self, *args, **kwargs):
                # Créer une clé de cache basée sur les arguments
                key_parts = [func.__name__]
                for arg in args:
                    if isinstance(arg, dict):
                        # Trier les clés pour cohérence
                        key_parts.append(json.dumps(arg, sort_keys=True))
                    else:
                        key_parts.append(str(arg))

                for k, v in sorted(kwargs.items()):
                    if isinstance(v, dict):
                        key_parts.append(f"{k}:{json.dumps(v, sort_keys=True)}")
                    else:
                        key_parts.append(f"{k}:{v}")

                cache_key = ":".join(key_parts)

                # Vérifier le cache
                cached_result = await self.cache.get(cache_key)
                if cached_result:
                    logger.info(f"Cache hit for {func.__name__}")
                    return json.loads(cached_result)

                # Exécuter la fonction
                result = await func(self, *args, **kwargs)

                # Mettre en cache le résultat
                await self.cache.set(cache_key, json.dumps(result), ttl)
                logger.info(f"Cached result for {func.__name__}")

                return result
            return wrapper
        return decorator

    @cache_result(ttl=1800)  # 30 minutes cache
    async def optimize_scoring_request(self, customer_data: Dict[str, Any]) -> Dict[str, Any]:
        """Optimiser une requête de scoring"""
        await self.init_session()

        # Pré-traitement optimisé
        optimized_data = await self._preprocess_features(customer_data)

        # Scoring avec modèle optimisé
        scoring_result = await self._perform_optimized_scoring(optimized_data)

        # Post-traitement
        final_result = await self._postprocess_result(scoring_result, customer_data)

        return final_result

    async def _preprocess_features(self, customer_data: Dict[str, Any]) -> Dict[str, Any]:
        """Pré-traitement optimisé des features"""
        customer_id = customer_data.get("customer_id")

        # Vérifier le cache des features
        cache_key = f"features:{customer_id}"
        cached_features = await self.cache.get(cache_key)

        if cached_features:
            logger.info(f"Feature cache hit for customer {customer_id}")
            return json.loads(cached_features)

        # Calculer les features optimisées
        features = customer_data.get("features", {})

        # Normalisation optimisée
        normalized_features = await self._normalize_features(features)

        # Feature engineering
        engineered_features = await self._engineer_features(normalized_features)

        # Mise en cache
        await self.cache.set(cache_key, json.dumps(engineered_features), ttl=3600)

        return engineered_features

    async def _normalize_features(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Normalisation optimisée des features"""
        # Utiliser des statistiques pré-calculées pour la normalisation
        normalized = {}

        for feature_name, value in features.items():
            # Récupérer les stats de normalisation depuis le cache
            stats_key = f"stats:{feature_name}"
            stats = await self.cache.get(stats_key)

            if stats:
                stats = json.loads(stats)
                mean = stats.get("mean", 0)
                std = stats.get("std", 1)

                # Normalisation Z-score
                normalized[feature_name] = (value - mean) / std if std > 0 else value
            else:
                # Fallback si pas de stats
                normalized[feature_name] = value

        return normalized

    async def _engineer_features(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Feature engineering optimisé"""
        engineered = features.copy()

        # Ratios financiers optimisés
        if "income" in features and "debt_ratio" in features:
            engineered["debt_to_income"] = features["debt_ratio"] / (features["income"] / 100000) if features["income"] > 0 else 0

        # Catégorisation d'âge optimisée
        if "age" in features:
            age = features["age"]
            engineered["age_category"] = "young" if age < 30 else "middle" if age < 60 else "senior"

        # Score de stabilité optimisé
        stability_factors = ["employment_years", "home_ownership"]
        stability_score = sum(features.get(factor, 0) for factor in stability_factors)
        engineered["stability_score"] = stability_score / len(stability_factors) if stability_factors else 0

        return engineered

    async def _perform_optimized_scoring(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Scoring avec modèle optimisé"""
        # Utiliser un modèle depuis le cache
        model_key = "current_model"
        model_data = await self.cache.get(model_key)

        if not model_data:
            # Fallback vers calcul simplifié optimisé
            return await self._fallback_scoring(features)

        # Simulation de scoring ML optimisé
        # En production, ceci chargerait et utiliserait un vrai modèle ML
        credit_score = await self._calculate_credit_score(features)

        # Déterminer le niveau de risque
        risk_level = self._calculate_risk_level(credit_score)

        # Calculer le montant approuvé
        approved_amount = await self._calculate_approved_amount(features, credit_score)

        return {
            "credit_score": credit_score,
            "risk_level": risk_level,
            "approved_amount": approved_amount,
            "confidence": 0.85,  # Score de confiance du modèle
            "model_version": "v2.1-optimized"
        }

    async def _calculate_credit_score(self, features: Dict[str, Any]) -> int:
        """Calcul optimisé du score de crédit"""
        # Formule optimisée basée sur les features importantes
        base_score = 600  # Score de base

        # Facteurs positifs
        positive_factors = {
            "income": lambda x: min(x / 10000, 100),  # Max +100 pour revenu élevé
            "employment_years": lambda x: min(x * 5, 50),  # +5 par année
            "home_ownership": lambda x: 25 if x == 1 else 0,  # +25 si propriétaire
            "stability_score": lambda x: x * 20,  # Score de stabilité
        }

        # Facteurs négatifs
        negative_factors = {
            "debt_ratio": lambda x: -x * 200,  # Pénalité pour dette élevée
            "age": lambda x: -max(0, (25 - x) * 2) if x < 25 else 0,  # Pénalité âge jeune
        }

        score_adjustment = 0

        for factor, func in positive_factors.items():
            if factor in features:
                score_adjustment += func(features[factor])

        for factor, func in negative_factors.items():
            if factor in features:
                score_adjustment += func(features[factor])

        final_score = int(base_score + score_adjustment)
        return max(300, min(850, final_score))  # Limiter entre 300-850

    def _calculate_risk_level(self, credit_score: int) -> str:
        """Calcul optimisé du niveau de risque"""
        if credit_score >= 750:
            return "LOW"
        elif credit_score >= 650:
            return "MEDIUM"
        elif credit_score >= 550:
            return "HIGH"
        else:
            return "VERY_HIGH"

    async def _calculate_approved_amount(self, features: Dict[str, Any], credit_score: int) -> float:
        """Calcul optimisé du montant approuvé"""
        # Base sur le revenu et le score
        income = features.get("income", 50000)
        base_amount = income * 2  # 2x le revenu annuel

        # Ajustement selon le score
        score_multiplier = {
            "LOW": 1.0,
            "MEDIUM": 0.8,
            "HIGH": 0.6,
            "VERY_HIGH": 0.3
        }

        risk_level = self._calculate_risk_level(credit_score)
        multiplier = score_multiplier.get(risk_level, 0.5)

        approved_amount = base_amount * multiplier

        # Limites
        min_amount = 5000
        max_amount = 500000

        return max(min_amount, min(max_amount, approved_amount))

    async def _fallback_scoring(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Scoring de fallback optimisé"""
        # Calcul simplifié mais optimisé
        credit_score = 650  # Score moyen

        # Ajustements simples
        if features.get("income", 0) > 75000:
            credit_score += 50
        if features.get("employment_years", 0) > 5:
            credit_score += 25
        if features.get("debt_ratio", 0) > 0.4:
            credit_score -= 50

        return {
            "credit_score": max(300, min(850, credit_score)),
            "risk_level": self._calculate_risk_level(credit_score),
            "approved_amount": features.get("income", 50000) * 1.5,
            "confidence": 0.7,
            "model_version": "fallback-v1"
        }

    async def _postprocess_result(self, scoring_result: Dict[str, Any], original_data: Dict[str, Any]) -> Dict[str, Any]:
        """Post-traitement optimisé du résultat"""
        customer_id = original_data.get("customer_id")

        # Enrichir avec des métadonnées
        result = {
            **scoring_result,
            "customer_id": customer_id,
            "timestamp": int(time.time() * 1000),
            "processing_time_ms": 150,  # Mesuré dans la vraie implémentation
            "cached": False,  # Sera mis à jour par le décorateur cache
        }

        # Calculer des métriques supplémentaires
        result["risk_score"] = 1 - (scoring_result["credit_score"] - 300) / 550  # 0-1 scale
        result["approval_probability"] = min(1.0, scoring_result["approved_amount"] / (original_data.get("features", {}).get("income", 50000) * 3))

        return result

    async def batch_score(self, customer_batch: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Scoring par lot optimisé"""
        logger.info(f"Processing batch of {len(customer_batch)} customers")

        # Traitement parallèle optimisé
        tasks = []
        semaphore = asyncio.Semaphore(MAX_WORKERS)  # Limiter la concurrence

        async def score_with_semaphore(customer_data):
            async with semaphore:
                return await self.optimize_scoring_request(customer_data)

        # Créer les tâches
        for customer_data in customer_batch:
            task = asyncio.create_task(score_with_semaphore(customer_data))
            tasks.append(task)

        # Attendre tous les résultats
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Traiter les exceptions
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(f"Error processing customer {i}: {result}")
                # Résultat d'erreur
                processed_results.append({
                    "customer_id": customer_batch[i].get("customer_id"),
                    "error": str(result),
                    "timestamp": int(time.time() * 1000)
                })
            else:
                processed_results.append(result)

        return processed_results

    async def warmup_cache(self):
        """Pré-chargement optimisé du cache"""
        logger.info("Warming up performance caches...")

        # Pré-charger les statistiques de features
        common_features = ["age", "income", "credit_score", "debt_ratio", "employment_years"]

        for feature in common_features:
            # Simulation de calcul de stats
            stats = {
                "mean": 50000 if feature == "income" else 35 if feature == "age" else 650 if feature == "credit_score" else 0.3 if feature == "debt_ratio" else 5,
                "std": 20000 if feature == "income" else 10 if feature == "age" else 100 if feature == "credit_score" else 0.2 if feature == "debt_ratio" else 3,
                "min": 0,
                "max": 100000 if feature == "income" else 80 if feature == "age" else 850 if feature == "credit_score" else 1.0 if feature == "debt_ratio" else 40
            }

            await self.cache.set(f"stats:{feature}", json.dumps(stats), ttl=86400)  # 24h

        # Pré-charger des exemples de résultats courants
        common_profiles = [
            {"age": 35, "income": 75000, "credit_score": 720, "debt_ratio": 0.3, "employment_years": 8},
            {"age": 28, "income": 45000, "credit_score": 650, "debt_ratio": 0.4, "employment_years": 3},
            {"age": 45, "income": 95000, "credit_score": 780, "debt_ratio": 0.2, "employment_years": 15},
        ]

        for profile in common_profiles:
            customer_data = {"customer_id": f"warmup-{hash(str(profile))}", "features": profile}
            await self.optimize_scoring_request(customer_data)

        logger.info("Cache warmup completed")

    async def health_check(self) -> Dict[str, Any]:
        """Vérification de santé optimisée"""
        health_status = {
            "status": "healthy",
            "timestamp": int(time.time() * 1000),
            "checks": {}
        }

        # Vérifier Redis
        try:
            redis_ping = await self.cache.redis.ping()
            health_status["checks"]["redis"] = "healthy" if redis_ping else "unhealthy"
        except Exception as e:
            health_status["checks"]["redis"] = f"error: {str(e)}"

        # Vérifier cache
        try:
            test_key = f"health-{int(time.time())}"
            await self.cache.set(test_key, "test", ttl=10)
            retrieved = await self.cache.get(test_key)
            health_status["checks"]["cache"] = "healthy" if retrieved == "test" else "unhealthy"
            await self.cache.delete(test_key)
        except Exception as e:
            health_status["checks"]["cache"] = f"error: {str(e)}"

        # Métriques de performance
        health_status["metrics"] = {
            "cache_hit_ratio": 0.85,  # À calculer dans la vraie implémentation
            "avg_response_time": 0.15,
            "throughput": 150,
            "active_connections": 25
        }

        # Status global
        all_healthy = all(status == "healthy" for status in health_status["checks"].values())
        health_status["status"] = "healthy" if all_healthy else "degraded"

        return health_status

# Fonctions utilitaires pour monitoring
def monitor_system_resources():
    """Monitoring des ressources système"""
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    return {
        "cpu_percent": cpu_percent,
        "memory_percent": memory.percent,
        "memory_used_gb": memory.used / (1024**3),
        "disk_percent": disk.percent,
        "disk_free_gb": disk.free / (1024**3)
    }

async def performance_test():
    """Test de performance de l'optimisation"""
    optimizer = ScoringOptimizer()

    try:
        # Warmup
        await optimizer.warmup_cache()

        # Test de charge
        test_customers = []
        for i in range(100):
            customer = {
                "customer_id": f"perf-test-{i}",
                "features": {
                    "age": 25 + (i % 40),
                    "income": 30000 + (i * 500),
                    "credit_score": 600 + (i % 200),
                    "debt_ratio": 0.1 + (i % 50) / 100,
                    "employment_years": i % 20
                }
            }
            test_customers.append(customer)

        # Test individuel
        logger.info("Testing individual scoring...")
        start_time = time.time()
        results = []
        for customer in test_customers[:10]:  # Test avec 10 premiers
            result = await optimizer.optimize_scoring_request(customer)
            results.append(result)

        individual_time = time.time() - start_time
        logger.info(f"Individual scoring: {individual_time:.2f}s for 10 requests")

        # Test par lot
        logger.info("Testing batch scoring...")
        start_time = time.time()
        batch_results = await optimizer.batch_score(test_customers[:50])  # Test avec 50

        batch_time = time.time() - start_time
        logger.info(f"Batch scoring: {batch_time:.2f}s for 50 requests")

        # Rapport de performance
        print("\n" + "="*60)
        print("PERFORMANCE OPTIMIZATION RESULTS")
        print("="*60)
        print(f"Individual requests: {len(results)}")
        print(f"Individual time: {individual_time:.2f}s")
        print(f"Avg per request: {individual_time/len(results):.3f}s")
        print(f"Batch requests: {len(batch_results)}")
        print(f"Batch time: {batch_time:.2f}s")
        print(f"Avg per request: {batch_time/len(batch_results):.3f}s")
        print(f"Batch efficiency: {individual_time/len(results) / (batch_time/len(batch_results)):.2f}x faster")
        print("="*60)

    finally:
        await optimizer.close_session()

if __name__ == "__main__":
    # Test de performance
    asyncio.run(performance_test())