#!/usr/bin/env python3
"""
MLOps Scoring Platform - Database Performance Optimization
Optimisation avancée des performances de base de données PostgreSQL
"""

import psycopg2
import psycopg2.extras
import time
import json
import logging
from typing import Dict, List, Any, Tuple
from datetime import datetime, timedelta
import concurrent.futures
import threading

# Configuration
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "mlops",
    "user": "mlops",
    "password": "password"
}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DatabaseOptimizer:
    """Optimiseur de performance pour PostgreSQL"""

    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.connection_pool = []
        self.max_pool_size = 10
        self.query_stats = {}
        self.index_stats = {}

    def get_connection(self):
        """Obtenir une connexion depuis le pool"""
        if self.connection_pool:
            return self.connection_pool.pop()

        try:
            conn = psycopg2.connect(**self.db_config)
            conn.autocommit = False
            return conn
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            raise

    def return_connection(self, conn):
        """Retourner une connexion au pool"""
        if len(self.connection_pool) < self.max_pool_size:
            try:
                # Test si la connexion est toujours valide
                conn.cursor().execute("SELECT 1")
                self.connection_pool.append(conn)
            except:
                # Connexion invalide, fermer
                conn.close()
        else:
            conn.close()

    def execute_query(self, query: str, params: Tuple = None, fetch: bool = True):
        """Exécuter une requête avec gestion du pool de connexions"""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
                start_time = time.time()

                cursor.execute(query, params or ())

                execution_time = time.time() - start_time

                # Collecter les statistiques de requête
                self._collect_query_stats(query, execution_time)

                if fetch and cursor.description:
                    result = cursor.fetchall()
                    return [dict(row) for row in result]
                else:
                    conn.commit()
                    return cursor.rowcount

        except Exception as e:
            conn.rollback()
            logger.error(f"Query execution failed: {e}")
            raise
        finally:
            self.return_connection(conn)

    def _collect_query_stats(self, query: str, execution_time: float):
        """Collecter les statistiques de requête"""
        query_type = query.strip().split()[0].upper()

        if query_type not in self.query_stats:
            self.query_stats[query_type] = {
                "count": 0,
                "total_time": 0,
                "avg_time": 0,
                "max_time": 0,
                "min_time": float('inf')
            }

        stats = self.query_stats[query_type]
        stats["count"] += 1
        stats["total_time"] += execution_time
        stats["avg_time"] = stats["total_time"] / stats["count"]
        stats["max_time"] = max(stats["max_time"], execution_time)
        stats["min_time"] = min(stats["min_time"], execution_time)

    def analyze_table_structure(self):
        """Analyser la structure des tables pour optimisation"""
        logger.info("Analyzing table structure...")

        # Récupérer toutes les tables
        tables_query = """
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename LIKE 'mlflow_%'
        """
        tables = self.execute_query(tables_query)

        table_analysis = {}

        for table in tables:
            table_name = table['tablename']
            schema_name = table['schemaname']

            # Analyser la structure de la table
            analysis = self._analyze_single_table(schema_name, table_name)
            table_analysis[table_name] = analysis

        return table_analysis

    def _analyze_single_table(self, schema: str, table: str) -> Dict[str, Any]:
        """Analyser une table spécifique"""
        analysis = {
            "row_count": 0,
            "size_mb": 0,
            "indexes": [],
            "missing_indexes": [],
            "column_stats": {}
        }

        # Nombre de lignes
        count_query = f"SELECT COUNT(*) as row_count FROM {schema}.{table}"
        result = self.execute_query(count_query)
        analysis["row_count"] = result[0]["row_count"] if result else 0

        # Taille de la table
        size_query = f"""
        SELECT pg_size_pretty(pg_total_relation_size('{schema}.{table}')) as size,
               pg_total_relation_size('{schema}.{table}') / 1024 / 1024 as size_mb
        """
        result = self.execute_query(size_query)
        if result:
            analysis["size_mb"] = result[0]["size_mb"]

        # Indexes existants
        indexes_query = """
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE schemaname = %s AND tablename = %s
        """
        indexes = self.execute_query(indexes_query, (schema, table))
        analysis["indexes"] = [idx["indexname"] for idx in indexes]

        # Statistiques des colonnes
        columns_query = """
        SELECT column_name, data_type, is_nullable,
               n_distinct, correlation
        FROM information_schema.columns c
        LEFT JOIN pg_stats s ON s.tablename = c.table_name
                           AND s.attname = c.column_name
        WHERE c.table_schema = %s AND c.table_name = %s
        """
        columns = self.execute_query(columns_query, (schema, table))

        for col in columns:
            analysis["column_stats"][col["column_name"]] = {
                "data_type": col["data_type"],
                "nullable": col["is_nullable"] == "YES",
                "distinct_values": col["n_distinct"],
                "correlation": col["correlation"]
            }

        # Suggestions d'indexes manquants
        analysis["missing_indexes"] = self._suggest_missing_indexes(schema, table, analysis)

        return analysis

    def _suggest_missing_indexes(self, schema: str, table: str, analysis: Dict[str, Any]) -> List[str]:
        """Suggérer des indexes manquants"""
        suggestions = []

        # Analyser les requêtes lentes récentes
        slow_queries_query = """
        SELECT query, mean_time, calls
        FROM pg_stat_statements
        WHERE query LIKE '%' || %s || '%'
        AND mean_time > 100  -- Plus de 100ms en moyenne
        ORDER BY mean_time DESC
        LIMIT 10
        """
        slow_queries = self.execute_query(slow_queries_query, (table,))

        for query_info in slow_queries:
            query = query_info["query"]
            # Analyse simple pour suggérer des indexes
            if "WHERE" in query.upper():
                where_clause = query.upper().split("WHERE")[1].split("ORDER BY")[0] if "ORDER BY" in query.upper() else query.upper().split("WHERE")[1]

                # Chercher les colonnes dans WHERE
                for col_name, col_info in analysis["column_stats"].items():
                    if col_name.upper() in where_clause and col_name not in [idx.split('_')[-1] for idx in analysis["indexes"]]:
                        suggestions.append(f"CREATE INDEX idx_{table}_{col_name} ON {schema}.{table}({col_name})")

        return list(set(suggestions))  # Éliminer les doublons

    def optimize_indexes(self):
        """Optimiser les indexes existants"""
        logger.info("Optimizing existing indexes...")

        # Réindexer les indexes fragmentés
        reindex_query = """
        SELECT schemaname, tablename, indexname
        FROM pg_stat_user_indexes
        WHERE idx_scan = 0  -- Index non utilisé
        AND schemaname = 'public'
        """
        unused_indexes = self.execute_query(reindex_query)

        for idx in unused_indexes:
            logger.warning(f"Unused index: {idx['indexname']} on {idx['schemaname']}.{idx['tablename']}")

        # Analyser et réindexer
        analyze_query = "ANALYZE"
        self.execute_query(analyze_query, fetch=False)

        logger.info("Index optimization completed")

    def optimize_queries(self):
        """Optimiser les requêtes lentes"""
        logger.info("Analyzing slow queries...")

        # Récupérer les requêtes lentes
        slow_queries_query = """
        SELECT query, mean_time, calls, total_time,
               rows, shared_blks_hit, shared_blks_read
        FROM pg_stat_statements
        WHERE mean_time > 50  -- Plus de 50ms
        ORDER BY mean_time DESC
        LIMIT 20
        """
        slow_queries = self.execute_query(slow_queries_query)

        optimizations = []

        for query_info in slow_queries:
            query = query_info["query"]
            mean_time = query_info["mean_time"]
            calls = query_info["calls"]

            # Analyser la requête pour optimisations
            analysis = self._analyze_query_for_optimization(query, mean_time, calls)
            if analysis:
                optimizations.append(analysis)

        return optimizations

    def _analyze_query_for_optimization(self, query: str, mean_time: float, calls: int) -> Dict[str, Any]:
        """Analyser une requête pour optimisations"""
        analysis = {
            "query": query[:100] + "..." if len(query) > 100 else query,
            "mean_time": mean_time,
            "calls": calls,
            "optimizations": []
        }

        query_upper = query.upper()

        # Vérifier l'utilisation d'indexes
        if "SELECT" in query_upper and "WHERE" in query_upper:
            # Vérifier si la requête utilise des indexes
            if "seq scan" in query_upper or "bitmap heap scan" not in query_upper:
                analysis["optimizations"].append("Consider adding appropriate indexes for WHERE conditions")

        # Vérifier les jointures
        if "JOIN" in query_upper:
            analysis["optimizations"].append("Review JOIN conditions and ensure proper indexing")

        # Vérifier l'utilisation de fonctions
        if "COUNT(*)" in query_upper or "SUM(" in query_upper:
            analysis["optimizations"].append("Consider using approximate functions for large datasets")

        # Vérifier la pagination
        if "LIMIT" in query_upper and "OFFSET" in query_upper:
            analysis["optimizations"].append("Consider cursor-based pagination for large result sets")

        return analysis if analysis["optimizations"] else None

    def optimize_connection_pooling(self):
        """Optimiser le pool de connexions"""
        logger.info("Optimizing connection pooling...")

        # Analyser l'utilisation actuelle
        pool_stats_query = """
        SELECT count(*) as active_connections
        FROM pg_stat_activity
        WHERE state = 'active'
        """
        active_conn = self.execute_query(pool_stats_query)

        # Ajuster la taille du pool basée sur l'utilisation
        current_active = active_conn[0]["active_connections"] if active_conn else 0

        # Logique d'ajustement du pool
        if current_active > self.max_pool_size * 0.8:
            new_pool_size = min(self.max_pool_size * 2, 50)
            logger.info(f"Increasing pool size from {self.max_pool_size} to {new_pool_size}")
            self.max_pool_size = new_pool_size
        elif current_active < self.max_pool_size * 0.3:
            new_pool_size = max(self.max_pool_size // 2, 5)
            logger.info(f"Decreasing pool size from {self.max_pool_size} to {new_pool_size}")
            self.max_pool_size = new_pool_size

    def implement_partitioning(self):
        """Implémenter le partitionnement pour les grandes tables"""
        logger.info("Analyzing tables for partitioning...")

        # Identifier les tables candidates pour le partitionnement
        large_tables_query = """
        SELECT schemaname, tablename,
               pg_total_relation_size(schemaname||'.'||tablename) / 1024 / 1024 as size_mb
        FROM pg_tables
        WHERE schemaname = 'public'
        AND pg_total_relation_size(schemaname||'.'||tablename) > 1024 * 1024 * 1024  -- > 1GB
        """
        large_tables = self.execute_query(large_tables_query)

        partitioning_suggestions = []

        for table in large_tables:
            table_name = table["tablename"]
            size_mb = table["size_mb"]

            # Vérifier si la table a une colonne de timestamp
            timestamp_columns_query = """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = %s AND table_name = %s
            AND data_type IN ('timestamp', 'timestamptz', 'date')
            """
            timestamp_cols = self.execute_query(timestamp_columns_query, ("public", table_name))

            if timestamp_cols:
                partitioning_suggestions.append({
                    "table": table_name,
                    "size_mb": size_mb,
                    "partition_column": timestamp_cols[0]["column_name"],
                    "strategy": "RANGE",
                    "interval": "monthly"
                })

        return partitioning_suggestions

    def create_optimized_indexes(self):
        """Créer des indexes optimisés"""
        logger.info("Creating optimized indexes...")

        # Index pour les requêtes MLflow courantes
        indexes_to_create = [
            "CREATE INDEX IF NOT EXISTS idx_mlflow_experiments_name ON mlflow_experiments(name)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_runs_experiment_id ON mlflow_runs(experiment_id)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_runs_status ON mlflow_runs(status)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_runs_start_time ON mlflow_runs(start_time)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_metrics_run_uuid ON mlflow_metrics(run_uuid)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_params_run_uuid ON mlflow_params(run_uuid)",
            "CREATE INDEX IF NOT EXISTS idx_mlflow_tags_run_uuid ON mlflow_tags(run_uuid)",
        ]

        for index_sql in indexes_to_create:
            try:
                self.execute_query(index_sql, fetch=False)
                logger.info(f"Created index: {index_sql.split('ON')[1].split('(')[0].strip()}")
            except Exception as e:
                logger.warning(f"Failed to create index: {e}")

    def optimize_autovacuum_settings(self):
        """Optimiser les paramètres autovacuum"""
        logger.info("Optimizing autovacuum settings...")

        # Tables nécessitant une attention particulière
        tables_needing_attention = [
            "mlflow_runs",
            "mlflow_metrics",
            "mlflow_params"
        ]

        for table in tables_needing_attention:
            # Ajuster autovacuum pour les tables à haute écriture
            vacuum_settings = f"""
            ALTER TABLE {table} SET (
                autovacuum_vacuum_scale_factor = 0.02,
                autovacuum_analyze_scale_factor = 0.01,
                autovacuum_vacuum_cost_limit = 1000
            )
            """
            try:
                self.execute_query(vacuum_settings, fetch=False)
                logger.info(f"Optimized autovacuum for table: {table}")
            except Exception as e:
                logger.warning(f"Failed to optimize autovacuum for {table}: {e}")

    def implement_query_caching(self):
        """Implémenter la mise en cache des requêtes"""
        logger.info("Implementing query result caching...")

        # Créer une table de cache pour les résultats fréquents
        create_cache_table = """
        CREATE TABLE IF NOT EXISTS query_cache (
            cache_key TEXT PRIMARY KEY,
            query_result JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP,
            access_count INTEGER DEFAULT 1
        );

        CREATE INDEX IF NOT EXISTS idx_query_cache_expires ON query_cache(expires_at);
        CREATE INDEX IF NOT EXISTS idx_query_cache_access ON query_cache(access_count DESC);
        """

        try:
            self.execute_query(create_cache_table, fetch=False)
            logger.info("Created query cache table")
        except Exception as e:
            logger.error(f"Failed to create cache table: {e}")

    def generate_performance_report(self) -> Dict[str, Any]:
        """Générer un rapport de performance complet"""
        logger.info("Generating performance report...")

        report = {
            "timestamp": datetime.now().isoformat(),
            "database_info": self._get_database_info(),
            "table_analysis": self.analyze_table_structure(),
            "query_performance": dict(self.query_stats),
            "index_analysis": self._analyze_index_usage(),
            "slow_queries": self.optimize_queries(),
            "partitioning_suggestions": self.implement_partitioning(),
            "recommendations": []
        }

        # Générer des recommandations
        recommendations = []

        # Analyser la fragmentation
        for table_name, analysis in report["table_analysis"].items():
            if analysis["size_mb"] > 1000:  # Plus de 1GB
                recommendations.append(f"Consider partitioning table {table_name} ({analysis['size_mb']}MB)")

            if len(analysis["missing_indexes"]) > 0:
                recommendations.append(f"Missing indexes for {table_name}: {len(analysis['missing_indexes'])} suggestions")

        # Analyser les requêtes lentes
        slow_query_count = len([q for q in report["slow_queries"] if q])
        if slow_query_count > 5:
            recommendations.append(f"High number of slow queries detected: {slow_query_count}")

        # Analyser l'utilisation des indexes
        unused_indexes = [idx for idx in report["index_analysis"] if idx["usage_count"] == 0]
        if len(unused_indexes) > 0:
            recommendations.append(f"Consider removing {len(unused_indexes)} unused indexes")

        report["recommendations"] = recommendations

        return report

    def _get_database_info(self) -> Dict[str, Any]:
        """Récupérer les informations de la base de données"""
        info_query = """
        SELECT version() as version,
               current_database() as database,
               (SELECT COUNT(*) FROM pg_stat_activity) as active_connections,
               pg_size_pretty(pg_database_size(current_database())) as size
        """
        result = self.execute_query(info_query)
        return dict(result[0]) if result else {}

    def _analyze_index_usage(self) -> List[Dict[str, Any]]:
        """Analyser l'utilisation des indexes"""
        index_usage_query = """
        SELECT schemaname, tablename, indexname,
               idx_scan as usage_count,
               pg_size_pretty(pg_relation_size(indexrelid)) as size
        FROM pg_stat_user_indexes
        WHERE schemaname = 'public'
        ORDER BY idx_scan DESC
        """
        return self.execute_query(index_usage_query)

    def run_comprehensive_optimization(self):
        """Exécuter une optimisation complète"""
        logger.info("Starting comprehensive database optimization...")

        try:
            # Étape 1: Analyser la structure
            logger.info("Step 1: Analyzing database structure...")
            table_analysis = self.analyze_table_structure()

            # Étape 2: Optimiser les indexes
            logger.info("Step 2: Optimizing indexes...")
            self.optimize_indexes()
            self.create_optimized_indexes()

            # Étape 3: Optimiser les requêtes
            logger.info("Step 3: Analyzing and optimizing queries...")
            query_optimizations = self.optimize_queries()

            # Étape 4: Optimiser le pool de connexions
            logger.info("Step 4: Optimizing connection pooling...")
            self.optimize_connection_pooling()

            # Étape 5: Optimiser autovacuum
            logger.info("Step 5: Optimizing autovacuum settings...")
            self.optimize_autovacuum_settings()

            # Étape 6: Implémenter le cache de requêtes
            logger.info("Step 6: Implementing query caching...")
            self.implement_query_caching()

            # Étape 7: Générer le rapport
            logger.info("Step 7: Generating optimization report...")
            report = self.generate_performance_report()

            # Sauvegarder le rapport
            with open('database-optimization-report.json', 'w') as f:
                json.dump(report, f, indent=2, default=str)

            logger.info("Database optimization completed successfully!")
            logger.info(f"Report saved to: database-optimization-report.json")

            return report

        except Exception as e:
            logger.error(f"Database optimization failed: {e}")
            raise

def main():
    """Fonction principale"""
    print("🗄️ MLOps Scoring Platform - Database Performance Optimization")
    print("="*70)

    optimizer = DatabaseOptimizer(DB_CONFIG)

    try:
        # Exécuter l'optimisation complète
        report = optimizer.run_comprehensive_optimization()

        # Afficher un résumé
        print("\n" + "="*70)
        print("DATABASE OPTIMIZATION SUMMARY")
        print("="*70)

        db_info = report.get("database_info", {})
        print(f"Database: {db_info.get('database', 'Unknown')}")
        print(f"Size: {db_info.get('size', 'Unknown')}")
        print(f"Active Connections: {db_info.get('active_connections', 0)}")

        table_count = len(report.get("table_analysis", {}))
        print(f"Tables Analyzed: {table_count}")

        recommendations = report.get("recommendations", [])
        print(f"Optimization Recommendations: {len(recommendations)}")

        if recommendations:
            print("\n💡 Key Recommendations:")
            for i, rec in enumerate(recommendations[:5], 1):  # Top 5
                print(f"  {i}. {rec}")

        print("\n✅ Database optimization completed!")
        print("📊 Detailed report: database-optimization-report.json")

    except Exception as e:
        print(f"❌ Database optimization failed: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())