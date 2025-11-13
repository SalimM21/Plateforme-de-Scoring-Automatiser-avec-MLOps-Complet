#!/bin/bash

# Script pour générer des données de test réalistes
# Utilisation: ./generate-test-data.sh

set -e

echo "🎯 Génération de données de test pour pipeline end-to-end"
echo "======================================================="

# Créer le dossier de données de test
mkdir -p test-data

# Générer des données CRM réalistes
echo "📊 Génération de données CRM..."

cat > test-data/crm_customers.sql << 'EOF'
-- Données de test pour CRM Customers
INSERT INTO crm.customers (customer_id, first_name, last_name, email, phone, address, registration_date, status) VALUES
('CUST001', 'Ahmed', 'Benali', 'ahmed.benali@email.com', '+212600000001', '123 Rue Mohammed V, Casablanca', '2024-01-15', 'ACTIVE'),
('CUST002', 'Fatima', 'Tazi', 'fatima.tazi@email.com', '+212600000002', '456 Boulevard Hassan II, Rabat', '2024-02-20', 'ACTIVE'),
('CUST003', 'Mohammed', 'Alaoui', 'mohammed.alaoui@email.com', '+212600000003', '789 Avenue Allal Ben Abdallah, Marrakech', '2024-03-10', 'ACTIVE'),
('CUST004', 'Amina', 'Bennani', 'amina.bennani@email.com', '+212600000004', '321 Rue de la Kasbah, Fès', '2024-04-05', 'INACTIVE'),
('CUST005', 'Youssef', 'El Amrani', 'youssef.elamrani@email.com', '+212600000005', '654 Boulevard Mohammed VI, Tanger', '2024-05-12', 'ACTIVE'),
('CUST006', 'Leila', 'Zahraoui', 'leila.zahraoui@email.com', '+212600000006', '987 Rue Souika, Meknès', '2024-06-18', 'ACTIVE'),
('CUST007', 'Karim', 'Bouazza', 'karim.bouazza@email.com', '+212600000007', '147 Avenue de France, Agadir', '2024-07-22', 'SUSPENDED'),
('CUST008', 'Nadia', 'El Fassi', 'nadia.elfassi@email.com', '+212600000008', '258 Rue de la Médina, Ouarzazate', '2024-08-30', 'ACTIVE'),
('CUST009', 'Omar', 'Tanger', 'omar.tanger@email.com', '+212600000009', '369 Boulevard Pasteur, Tetouan', '2024-09-14', 'ACTIVE'),
('CUST010', 'Sara', 'Meknassi', 'sara.meknassi@email.com', '+212600000010', '741 Rue du Jardin, Chefchaouen', '2024-10-08', 'ACTIVE');
EOF

# Générer des données de transactions
echo "💳 Génération de données de transactions..."

cat > test-data/transactions.sql << 'EOF'
-- Données de test pour Transactions
INSERT INTO crm.transactions (transaction_id, customer_id, amount, currency, transaction_type, timestamp, merchant, category) VALUES
('TXN001', 'CUST001', 1500.00, 'MAD', 'DEBIT', '2024-11-01 10:30:00', 'Marjane Supermarket', 'GROCERIES'),
('TXN002', 'CUST002', 250.00, 'MAD', 'DEBIT', '2024-11-01 14:15:00', 'Pharmacie Centrale', 'HEALTHCARE'),
('TXN003', 'CUST003', 5000.00, 'MAD', 'CREDIT', '2024-11-01 16:45:00', 'Bank Transfer', 'TRANSFER'),
('TXN004', 'CUST001', 320.00, 'MAD', 'DEBIT', '2024-11-02 09:20:00', 'Café Clock', 'FOOD'),
('TXN005', 'CUST004', 1200.00, 'MAD', 'DEBIT', '2024-11-02 11:10:00', 'Total Station', 'FUEL'),
('TXN006', 'CUST005', 850.00, 'MAD', 'DEBIT', '2024-11-02 13:30:00', 'Zara Store', 'CLOTHING'),
('TXN007', 'CUST002', 75.00, 'MAD', 'DEBIT', '2024-11-03 08:45:00', 'Bakery Hassan', 'FOOD'),
('TXN008', 'CUST006', 2200.00, 'MAD', 'DEBIT', '2024-11-03 15:20:00', 'Electronics Store', 'ELECTRONICS'),
('TXN009', 'CUST007', 150.00, 'MAD', 'DEBIT', '2024-11-03 17:10:00', 'Internet Provider', 'UTILITIES'),
('TXN010', 'CUST008', 3000.00, 'MAD', 'CREDIT', '2024-11-04 12:00:00', 'Salary Deposit', 'INCOME'),
('TXN011', 'CUST003', 450.00, 'MAD', 'DEBIT', '2024-11-04 14:30:00', 'Restaurant Al Fassia', 'FOOD'),
('TXN012', 'CUST009', 180.00, 'MAD', 'DEBIT', '2024-11-05 10:15:00', 'Gym Fitness', 'HEALTHCARE'),
('TXN013', 'CUST001', 2800.00, 'MAD', 'DEBIT', '2024-11-05 16:00:00', 'Hotel Royal', 'TRAVEL'),
('TXN014', 'CUST010', 95.00, 'MAD', 'DEBIT', '2024-11-06 09:45:00', 'Coffee Shop', 'FOOD'),
('TXN015', 'CUST005', 650.00, 'MAD', 'DEBIT', '2024-11-06 13:20:00', 'Bookstore', 'EDUCATION');
EOF

# Générer des données KYC
echo "🔍 Génération de données KYC..."

cat > test-data/kyc_data.json << 'EOF'
[
  {
    "customer_id": "CUST001",
    "kyc_status": "VERIFIED",
    "risk_score": 0.15,
    "documents_verified": true,
    "verification_date": 1730419200000
  },
  {
    "customer_id": "CUST002",
    "kyc_status": "VERIFIED",
    "risk_score": 0.08,
    "documents_verified": true,
    "verification_date": 1730505600000
  },
  {
    "customer_id": "CUST003",
    "kyc_status": "VERIFIED",
    "risk_score": 0.22,
    "documents_verified": true,
    "verification_date": 1730592000000
  },
  {
    "customer_id": "CUST004",
    "kyc_status": "PENDING",
    "risk_score": 0.45,
    "documents_verified": false,
    "verification_date": 1730678400000
  },
  {
    "customer_id": "CUST005",
    "kyc_status": "VERIFIED",
    "risk_score": 0.12,
    "documents_verified": true,
    "verification_date": 1730764800000
  }
]
EOF

# Générer des données de scoring de test
echo "🎯 Génération de données de scoring..."

cat > test-data/scoring_requests.json << 'EOF'
[
  {
    "customer_id": "CUST001",
    "features": {
      "age": 35,
      "income": 45000,
      "debt_ratio": 0.25,
      "employment_years": 8,
      "credit_history_length": 12,
      "num_credit_lines": 3,
      "revolving_utilization": 0.15
    }
  },
  {
    "customer_id": "CUST002",
    "features": {
      "age": 42,
      "income": 65000,
      "debt_ratio": 0.18,
      "employment_years": 15,
      "credit_history_length": 18,
      "num_credit_lines": 5,
      "revolving_utilization": 0.08
    }
  },
  {
    "customer_id": "CUST003",
    "features": {
      "age": 28,
      "income": 32000,
      "debt_ratio": 0.35,
      "employment_years": 3,
      "credit_history_length": 5,
      "num_credit_lines": 2,
      "revolving_utilization": 0.22
    }
  }
]
EOF

# Script pour injecter les données dans PostgreSQL
echo "💾 Création du script d'injection PostgreSQL..."

cat > test-data/inject-test-data.sh << 'EOF'
#!/bin/bash

# Script pour injecter les données de test dans PostgreSQL
# Utilisation: ./inject-test-data.sh

echo "🔄 Injection des données de test dans PostgreSQL..."

# Attendre que PostgreSQL soit prêt
echo "Attente de PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgresql -n storage --timeout=300s

# Injecter les données CRM
echo "📊 Injection des données CRM..."
kubectl exec -n storage deployment/postgresql -- psql -U postgres -d scoring_db -f /tmp/crm_customers.sql

# Injecter les données de transactions
echo "💳 Injection des données de transactions..."
kubectl exec -n storage deployment/postgresql -- psql -U postgres -d scoring_db -f /tmp/transactions.sql

echo "✅ Données de test injectées avec succès!"
EOF

chmod +x test-data/inject-test-data.sh

# Script pour tester le pipeline end-to-end
echo "🔬 Création du script de test end-to-end..."

cat > test-data/test-end-to-end.sh << 'EOF'
#!/bin/bash

# Script de test end-to-end du pipeline de données
# Utilisation: ./test-end-to-end.sh

set -e

echo "🧪 TEST END-TO-END - Pipeline de données complet"
echo "==============================================="

# 1. Vérifier l'état des services
echo "1️⃣ Vérification des services..."
kubectl get pods --all-namespaces | grep -E "(kafka|storage|default)" | grep Running

# 2. Injecter les données de test
echo "2️⃣ Injection des données de test..."
./inject-test-data.sh

# 3. Vérifier l'ingestion Kafka (Debezium)
echo "3️⃣ Test Debezium - Ingestion CRM..."
sleep 10
kubectl exec -n kafka my-cluster-kafka-0 -- kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic crm-customers \
  --max-messages 5 \
  --from-beginning

# 4. Vérifier les connecteurs Kafka Connect
echo "4️⃣ Vérification des connecteurs Kafka Connect..."
kubectl get kafkaconnector -n kafka

# 5. Tester l'API Scoring
echo "5️⃣ Test API Scoring..."
curl -X POST http://localhost:8000/score \
  -H "Content-Type: application/json" \
  -d @scoring_requests.json

# 6. Vérifier les métriques Prometheus
echo "6️⃣ Vérification des métriques..."
curl http://localhost:9090/api/v1/query?query=scoring_requests_total

echo "✅ Tests end-to-end terminés!"
EOF

chmod +x test-data/test-end-to-end.sh

echo ""
echo "🎉 Données de test générées avec succès!"
echo ""
echo "📁 Fichiers créés:"
echo "   - test-data/crm_customers.sql"
echo "   - test-data/transactions.sql"
echo "   - test-data/kyc_data.json"
echo "   - test-data/scoring_requests.json"
echo "   - test-data/inject-test-data.sh"
echo "   - test-data/test-end-to-end.sh"
echo ""
echo "🚀 Utilisation:"
echo "   cd test-data"
echo "   ./inject-test-data.sh    # Injecter dans PostgreSQL"
echo "   ./test-end-to-end.sh     # Tester le pipeline complet"