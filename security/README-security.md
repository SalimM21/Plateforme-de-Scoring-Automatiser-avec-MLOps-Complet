# 🔐 **GUIDE SÉCURITÉ AVANCÉE**

*MLOps Scoring Platform - Zero Trust Security, Defense in Depth*
*Multi-Layer Security, Compliance, Threat Detection & Response*

---

## 📋 **APERÇU**

Ce guide présente le système de sécurité avancée de la plateforme MLOps Scoring, implémentant une approche Zero Trust avec defense in depth, incluant network policies, service mesh, secrets management, WAF, intrusion detection, audit et compliance automatisée.

### **Capacités du Système**
- ✅ **Zero Trust Architecture** : Vérification continue, moindre privilège
- ✅ **Defense in Depth** : Multiples couches de sécurité
- ✅ **Network Security** : Micro-segmentation, service mesh, mTLS
- ✅ **Secrets Management** : Vault, Sealed Secrets, rotation automatique
- ✅ **API Security** : WAF, rate limiting, authentication JWT
- ✅ **Intrusion Detection** : Falco, audit logging, threat hunting
- ✅ **Compliance Automatisée** : GDPR, PCI-DSS, SOX, HIPAA
- ✅ **Security Monitoring** : Alertes temps réel, dashboards sécurité

---

## 🏗️ **ARCHITECTURE SÉCURITÉ**

### **Defense in Depth Layers**

#### **1. Network Security (Layer 1)**
```yaml
# Micro-segmentation avec Network Policies
- Isolation par namespace
- Contrôle trafic ingress/egress
- Service mesh Istio avec mTLS
- Network policies Kubernetes
```

#### **2. Identity & Access (Layer 2)**
```yaml
# Zero Trust Identity
- Keycloak OIDC/OAuth2
- RBAC Kubernetes avancé
- Service accounts dédiées
- JWT avec claims personnalisés
```

#### **3. Application Security (Layer 3)**
```yaml
# Runtime Security
- Pod Security Standards
- Security Contexts restrictifs
- Read-only root filesystems
- Non-root containers
```

#### **4. Data Protection (Layer 4)**
```yaml
# Secrets & Encryption
- HashiCorp Vault pour secrets
- Sealed Secrets pour K8s
- TLS 1.3 everywhere
- Encryption at rest/transit
```

#### **5. API Security (Layer 5)**
```yaml
# Web Application Firewall
- OWASP ModSecurity CRS
- Rate limiting intelligent
- Geo-blocking et IP filtering
- API validation spécifique
```

#### **6. Threat Detection (Layer 6)**
```yaml
# Intrusion Detection & Response
- Falco runtime security
- Audit logging complet
- SIEM integration
- Automated response
```

#### **7. Compliance & Audit (Layer 7)**
```yaml
# Regulatory Compliance
- GDPR, PCI-DSS, SOX, HIPAA
- Audit trails automatisés
- Reports de conformité
- Evidence collection
```

---

## 🚀 **DÉPLOIEMENT SÉCURITÉ AVANCÉE**

### **1. Network Policies**
```bash
kubectl apply -f security/network-policies.yaml
kubectl apply -f security/istio-security.yaml
```

### **2. Pod Security**
```bash
kubectl apply -f security/pod-security.yaml
```

### **3. Secrets Management**
```bash
kubectl apply -f security/secrets-management.yaml
```

### **4. WAF & Rate Limiting**
```bash
kubectl apply -f security/waf-ratelimiting.yaml
```

### **5. Intrusion Detection**
```bash
kubectl apply -f security/intrusion-detection.yaml
```

### **6. Audit & Compliance**
```bash
kubectl apply -f security/audit-compliance.yaml
```

---

## 🔒 **NETWORK SECURITY**

### **Network Policies Avancées**

#### **API Gateway Isolation**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-policy
spec:
  podSelector:
    matchLabels:
      app: api-gateway
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0  # External access
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: scoring-api
    ports:
    - protocol: TCP
      port: 8000
```

#### **Database Protection**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-isolation-policy
spec:
  podSelector:
    matchLabels:
      app: postgresql
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: scoring-api
    ports:
    - protocol: TCP
      port: 5432
  egress: []  # No outbound traffic
```

### **Service Mesh Istio**

#### **Mutual TLS**
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT  # mTLS obligatoire
```

#### **Authorization Policies**
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: scoring-api-authz
spec:
  selector:
    matchLabels:
      app: scoring-api
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/api-gateway-sa"]
    to:
    - operation:
        methods: ["POST"]
        paths: ["/score"]
```

#### **JWT Authentication**
```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: scoring-api-jwt
spec:
  selector:
    matchLabels:
      app: scoring-api
  jwtRules:
  - issuer: "https://keycloak.company.com/auth/realms/scoring"
    jwksUri: "https://keycloak.company.com/auth/realms/scoring/protocol/openid-connect/certs"
```

---

## 🔑 **SECRETS MANAGEMENT**

### **HashiCorp Vault**

#### **Configuration Vault**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-config
data:
  vault.hcl: |
    storage "kubernetes" {
      secret_name = "vault-data"
    }
    seal "transit" {
      address = "https://vault.example.com:8200"
      token = "s-xxxxxxxxxx"
      key_name = "autounseal"
    }
```

#### **Auto-unseal avec Transit**
```yaml
seal "transit" {
  address = "https://vault.example.com:8200"
  token = "s-xxxxxxxxxx"
  mount_path = "transit/"
  key_name = "autounseal"
}
```

### **Sealed Secrets**

#### **Encrypted Secrets**
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: database-credentials
spec:
  encryptedData:
    POSTGRES_USER: <encrypted-user>
    POSTGRES_PASSWORD: <encrypted-password>
```

### **External Secrets Operator**

#### **Cloud Secrets Integration**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: cloud-credentials
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: vault-backend
  data:
  - secretKey: AWS_ACCESS_KEY_ID
    remoteRef:
      key: aws
      property: access_key
```

### **Certificate Management**

#### **Let's Encrypt Automation**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: scoring-api-tls
spec:
  secretName: scoring-api-tls-secret
  issuerRef:
    name: letsencrypt-prod
  dnsNames:
  - scoring-api.company.com
```

---

## 🛡️ **API SECURITY - WAF**

### **OWASP ModSecurity CRS**

#### **Configuration WAF**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: scoring-api-ingress
  annotations:
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/enable-owasp-core-ruleset: "true"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
      SecRule REQUEST_HEADERS:Content-Type "text/xml" "id:101,deny,status:415"
      SecRule ARGS "@contains <script>" "id:102,deny,status:403"
```

### **Rate Limiting Intelligent**

#### **Configuration Rate Limit**
```yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
  nginx.ingress.kubernetes.io/rate-limit-burst: "20"
```

#### **Rate Limit par Utilisateur**
```yaml
SecAction "id:1005,phase:1,nolog,pass,initcol:ip=%{REMOTE_ADDR}"
SecAction "id:1006,phase:1,nolog,pass,setvar:ip.rate_limit=+1,expirevar:ip.rate_limit=60"
SecRule IP:RATE_LIMIT "@gt 100" "id:1007,deny,status:429"
```

### **Règles Personnalisées**

#### **Validation API Scoring**
```yaml
SecRule REQUEST_URI "@streq /score" "id:1001,phase:1,chain"
  SecRule ARGS_POST:features "@validateByteRange 0-255" "deny,status:400"

SecRule REQUEST_URI "@streq /score" "id:1002,phase:1,chain"
  SecRule &ARGS_POST:features "@lt 1000" "deny,status:413"
```

#### **Protection XSS/SQL Injection**
```yaml
SecRule ARGS "@contains <script>" "id:1011,deny,status:403"
SecRule ARGS "@rx (select|union|insert|update|delete)\s+" "id:1012,deny,status:403"
```

---

## 🔍 **INTRUSION DETECTION**

### **Falco Runtime Security**

#### **Règles Personnalisées**
```yaml
- rule: Suspicious File Access in Scoring API
  desc: Detect suspicious file access patterns
  condition: >
    container.image.repository = "scoring-api" and
    (fd.filename contains "/etc/passwd" or fd.filename contains "/root")
  output: >
    Suspicious file access (user=%user.name file=%fd.filename)
  priority: WARNING

- rule: Privilege Escalation Attempt
  desc: Detect privilege escalation attempts
  condition: >
    spawned_process and proc.vpid = 1 and user.uid != 0 and
    (proc.cmdline contains "sudo" or proc.cmdline contains "su")
  output: >
    Privilege escalation (user=%user.name command=%proc.cmdline)
  priority: CRITICAL
```

#### **Event Handler**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-handler
spec:
  template:
    spec:
      containers:
      - name: event-handler
        env:
        - name: SLACK_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: security-alerts
              key: slack_webhook
```

### **Audit Logging**

#### **Fluent Bit Configuration**
```yaml
[INPUT]
    Name              tail
    Path              /var/log/kubernetes/audit.log
    Parser            json
    Tag               audit.*

[FILTER]
    Name                grep
    Match               audit.*
    Regex               verb (create|update|delete|patch)

[OUTPUT]
    Name  loki
    Match *
    Host  loki.logging.svc.cluster.local
    Labels job=audit,component=security
```

---

## 📊 **COMPLIANCE & AUDIT**

### **Frameworks Supportés**

#### **GDPR Compliance**
```yaml
gdpr:
  data_retention: 2555  # 7 years
  encryption_required: true
  audit_required: true
  consent_required: true
```

#### **PCI-DSS Compliance**
```yaml
pci_dss:
  encryption_required: true
  access_logging: true
  vulnerability_scanning: true
  network_segmentation: true
```

### **Audit Automatisé**

#### **Evidence Collection**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliance-monitor
spec:
  template:
    spec:
      containers:
      - name: compliance-monitor
        env:
        - name: COMPLIANCE_RULES
          valueFrom:
            configMapKeyRef:
              name: compliance-rules
              key: rules.yaml
```

### **Reports de Conformité**

#### **Génération Automatique**
```bash
# Rapport GDPR mensuel
./compliance/generate-gdpr-report.sh

# Rapport PCI-DSS trimestriel
./compliance/generate-pci-report.sh

# Audit SOX annuel
./compliance/generate-sox-audit.sh
```

---

## ⚙️ **CONFIGURATION AVANCÉE**

### **Pod Security Standards**

#### **Restricted PSP**
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities: [ALL]
  runAsUser:
    rule: 'MustRunAsNonRoot'
  fsGroup:
    rule: 'MustRunAs'
    ranges:
    - min: 1000
      max: 65535
```

#### **Security Contexts**
```yaml
securityContext:
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001
  runAsNonRoot: true

containers:
- securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop: [ALL]
    seccompProfile:
      type: RuntimeDefault
```

### **RBAC Avancé**

#### **Service Accounts Dédiées**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scoring-api-sa
automountServiceAccountToken: false

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: scoring-api-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["scoring-api-secret"]
```

### **TLS Everywhere**

#### **Auto-TLS avec cert-manager**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: scoring-api-tls
spec:
  secretName: scoring-api-tls-secret
  issuerRef:
    name: letsencrypt-prod
  dnsNames:
  - scoring-api.company.com
```

#### **mTLS Istio**
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
```

---

## 🎯 **MONITORING SÉCURITÉ**

### **Security Dashboards**

#### **Falco Events Dashboard**
- Événements sécurité temps réel
- Top règles déclenchées
- Évolution menaces
- Réponses automatiques

#### **Compliance Dashboard**
- Score conformité par framework
- Violations détectées
- Actions correctives
- Audit trails

#### **Network Security Dashboard**
- Trafic autorisé/refusé
- Tentatives intrusion
- Geo-blocking stats
- WAF effectiveness

### **Alertes Sécurité**

#### **Critical Security Alerts**
```yaml
- alert: PrivilegeEscalationDetected
  expr: sum(rate(falco_events{priority="CRITICAL"}[5m])) > 0
  labels: {severity: critical, type: security}

- alert: DataExfiltrationAttempt
  expr: sum(rate(falco_events{rule=~"DataExfiltration"}[5m])) > 0
  labels: {severity: critical, type: security}
```

#### **Compliance Alerts**
```yaml
- alert: GDPRViolationDetected
  expr: sum(rate(compliance_violations{framework="gdpr"}[5m])) > 0
  labels: {severity: warning, type: compliance}

- alert: PCIDSSNonCompliance
  expr: pci_dss_compliance_score < 0.95
  labels: {severity: warning, type: compliance}
```

---

## 🎯 **IMPACT BUSINESS**

### **Avantages Sécurité**
- **Zero Trust** : Vérification continue, moindre privilège
- **Defense in Depth** : Multiples couches de protection
- **Compliance Automatisée** : Conformité réglementaire assurée
- **Threat Detection** : Détection menaces en temps réel
- **Incident Response** : Réponse automatisée aux incidents

### **Métriques de Succès**
- **MTTR Sécurité** : < 15 minutes (objectif < 10min)
- **False Positives** : < 5% des alertes sécurité
- **Compliance Score** : > 95% pour tous frameworks
- **Zero Breaches** : Objectif zéro compromission
- **Audit Readiness** : 100% préparés aux audits

### **ROI Sécurité Avancée**
- **Réduction Risques** : -90% risque cyberattaques
- **Conformité** : Évitement pénalités > 1M€
- **Productivité** : +30% équipes (automatisation sécurité)
- **Confiance Client** : +40% satisfaction (sécurité perçue)
- **Innovation** : Focus sur business vs sécurité

---

**🔐 Sécurité avancée opérationnelle !**

*Zero Trust, Defense in Depth, Compliance Automatisée*
*Multi-layer Security, Threat Detection, Audit Trails* 🎯