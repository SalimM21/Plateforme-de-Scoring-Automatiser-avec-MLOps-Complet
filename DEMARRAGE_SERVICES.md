# Guide de démarrage des services MLOps

## 1. Démarrage de MLflow
```bash
cd scoring-credit/credit_scoring_mlops
docker-compose up -d mlflow
```
- URL: http://localhost:5000
- Pas d'authentification requise

## 2. Démarrage de Kafka & Zookeeper
```bash
cd integration-CRM-KYC/ingestion/kafka
docker-compose up -d
```
- Kafka Broker: localhost:9092
- Zookeeper: localhost:2181
- Pour tester Kafka : 
```bash
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092
```

## 3. Démarrage d'Airflow
```bash
cd scoring-credit/credit_scoring_mlops/ci_cd/airflow
docker-compose up -d
```
- URL: http://localhost:8082
- Identifiants par défaut:
  - Utilisateur: airflow
  - Mot de passe: airflow

## 4. Démarrage de l'API et Keycloak
```bash
cd api-integration/api_integration
docker-compose up -d
```

### Services disponibles :
- API FastAPI: http://localhost:8000
- Keycloak: http://localhost:8080
  - Admin Console: http://localhost:8080/admin
  - Identifiants dans: ./config/auth/keycloak.env
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

## Vérification des services
```bash
# Vérifier l'état des conteneurs
docker ps

# Vérifier les logs de Keycloak
docker logs keycloak

# Vérifier les logs de l'API
docker logs api_scoring

# Vérifier les logs d'Airflow
docker logs airflow-webserver-1
```

## Arrêt des services
Pour arrêter proprement les services :
```bash
# Arrêter MLflow
cd scoring-credit/credit_scoring_mlops
docker-compose down

# Arrêter Kafka
cd integration-CRM-KYC/ingestion/kafka
docker-compose down

# Arrêter Airflow
cd scoring-credit/credit_scoring_mlops/ci_cd/airflow
docker-compose down

# Arrêter l'API et Keycloak
cd api-integration/api_integration
docker-compose down
```

## Notes importantes
- Assurez-vous que les ports suivants sont disponibles : 5000, 9092, 2181, 8082, 8000, 8080, 9200, 5601
- Les mots de passe par défaut doivent être changés en production
- Les fichiers de configuration sensibles sont dans ./config/auth/
- Consultez les logs en cas de problème de démarrage