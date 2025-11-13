#!/bin/bash

# Script de configuration Keycloak pour la plateforme MLOps Scoring
# Utilisation: ./setup-keycloak.sh

set -e

echo "🔐 Configuration Keycloak pour MLOps Scoring Platform"
echo "==================================================="

# Attendre que Keycloak soit prêt
echo "1️⃣ Attente du démarrage de Keycloak..."
kubectl wait --for=condition=ready pod -l app=keycloak --timeout=300s

# Port-forward pour accéder à Keycloak
echo "2️⃣ Configuration du port-forward..."
kubectl port-forward svc/keycloak-service 8080:8080 &
PORT_FORWARD_PID=$!

sleep 10

# Obtenir le token d'admin
echo "3️⃣ Obtention du token d'administration..."
TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin123" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Échec de l'obtention du token"
  kill $PORT_FORWARD_PID
  exit 1
fi

echo "✅ Token obtenu"

# Créer le realm
echo "4️⃣ Création du realm MLOps Scoring Platform..."
curl -s -X POST http://localhost:8080/admin/realms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @keycloak-realm-config.json

echo "✅ Realm créé"

# Vérifier la création
echo "5️⃣ Vérification de la configuration..."
REALM_EXISTS=$(curl -s http://localhost:8080/admin/realms/mlops-scoring-platform \
  -H "Authorization: Bearer $TOKEN" | jq -r '.realm')

if [ "$REALM_EXISTS" == "mlops-scoring-platform" ]; then
  echo "✅ Realm configuré avec succès"
else
  echo "❌ Échec de la configuration du realm"
  kill $PORT_FORWARD_PID
  exit 1
fi

# Tester les clients
echo "6️⃣ Vérification des clients..."
CLIENTS=$(curl -s http://localhost:8080/admin/realms/mlops-scoring-platform/clients \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[].clientId')

echo "Clients configurés:"
echo "$CLIENTS"

# Tester les utilisateurs
echo "7️⃣ Vérification des utilisateurs..."
USERS=$(curl -s http://localhost:8080/admin/realms/mlops-scoring-platform/users \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[].username')

echo "Utilisateurs configurés:"
echo "$USERS"

# Tester les rôles
echo "8️⃣ Vérification des rôles..."
ROLES=$(curl -s http://localhost:8080/admin/realms/mlops-scoring-platform/roles \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[].name')

echo "Rôles configurés:"
echo "$ROLES"

# Nettoyer
kill $PORT_FORWARD_PID

echo ""
echo "🎉 Configuration Keycloak terminée avec succès!"
echo ""
echo "📋 Informations de connexion:"
echo "   URL: http://localhost:8080"
echo "   Realm: mlops-scoring-platform"
echo "   Admin: admin / admin123"
echo ""
echo "👥 Utilisateurs de test:"
echo "   admin: admin / admin123 (Administrator)"
echo "   data-scientist: scientist123 (Data Scientist)"
echo "   data-engineer: engineer123 (Data Engineer)"
echo "   business-analyst: analyst123 (Business Analyst)"
echo "   compliance-officer: compliance123 (Compliance Officer)"
echo "   api-user: apiuser123 (API User)"
echo ""
echo "🔧 Clients configurés:"
echo "   scoring-api: scoring-api-secret-123"
echo "   dashboard-ui: dashboard-ui-secret-456"
echo "   mlflow-ui: mlflow-ui-secret-789"
echo ""
echo "🚀 Port-forward pour accéder:"
echo "   kubectl port-forward svc/keycloak-service 8080:8080"
echo ""
echo "🔗 URLs d'accès:"
echo "   Admin Console: http://localhost:8080/admin/master/console"
echo "   Account Console: http://localhost:8080/realms/mlops-scoring-platform/account"