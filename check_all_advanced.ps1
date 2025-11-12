<#
.SYNOPSIS
Vérification avancée de la plateforme de Scoring Automatisée MLOps sur Minikube

.DESCRIPTION
- Vérifie le bon fonctionnement des composants dans leurs namespaces (Kafka, Strimzi, MinIO, PostgreSQL, Spark, Airflow, API Gateway, Dashboard React, Rasa Chatbot, Grafana, Prometheus, Loki, MLflow, Keycloak)
- Capturer les 20 derniers logs des pods
- Relancer automatiquement les pods en échec si possible
- Tester l'endpoint API de scoring avec un payload réaliste
- Générer un rapport `verification_report.txt` et calculer un score global de santé
#>

# -----------------------------
# Configuration générale
# -----------------------------
$Report = "verification_report.txt"
$Total = 0
$Success = 0
$FailedComponents = @()

# Couleurs console
$Green = "`e[0;32m"
$Red = "`e[0;31m"
$Yellow = "`e[1;33m"
$NC = "`e[0m"

# Initialisation du rapport
"Rapport avancé de vérification - $(Get-Date)" | Out-File $Report
"====================================" | Out-File $Report -Append

# -----------------------------
# Fonction de logging et status
# -----------------------------
function Log-Status {
    param(
        [string]$Name,
        [bool]$IsSuccess,
        [string]$Logs
    )

    "$Name" | Out-File $Report -Append
    if ($IsSuccess) {
        Write-Host "$Green`u2714 $Name OK$NC"
        "Status: ✅ OK" | Out-File $Report -Append
        $Global:Success++
    } else {
        Write-Host "$Red`u274C $Name Problème détecté$NC"
        "Status: ❌ Problème détecté" | Out-File $Report -Append
        $Global:FailedComponents += $Name
    }

    if ($Logs) {
        "Derniers logs:" | Out-File $Report -Append
        $Logs | Out-File $Report -Append
        "------------------------------------" | Out-File $Report -Append
    }

    $Global:Total++
}

# -----------------------------
# Fonction de vérification d'un composant
# -----------------------------
function Check-Component {
    param(
        [string]$Name,
        [string]$Namespace,
        [string]$LabelSelector,
        [string]$TestUrl,
        [string]$RestartCmd
    )

    $IsSuccess = $false
    $Logs = ""

    # Vérifier existence du namespace
    $nsExists = kubectl get namespace $Namespace --no-headers -o custom-columns=":metadata.name" 2>$null
    if (-not $nsExists) {
        Write-Host "$Yellow⚠ Namespace $Namespace introuvable$NC"
        Log-Status $Name $false ""
        return
    }

    # Vérifier existence des pods
    $podsJson = kubectl get pods -n $Namespace -l $LabelSelector -o json 2>$null | ConvertFrom-Json
    if (-not $podsJson.items -or $podsJson.items.Count -eq 0) {
        Write-Host "$Yellow⚠ Aucun pod trouvé pour $Name dans le namespace $Namespace$NC"
        Log-Status $Name $false ""
        return
    }

    $pod = $podsJson.items[0]
    $podName = $pod.metadata.name
    $podStatus = $pod.status.phase

    if ($podStatus -eq "Running") {
        $IsSuccess = $true
    } else {
        Write-Host "$Yellow⚡ Pod $podName en état $podStatus$NC"
        if ($RestartCmd) {
            Invoke-Expression $RestartCmd
            Write-Host "$Yellow⚡ Relance automatique du pod $podName pour $Name$NC"
        }
    }

    # Récupérer les logs
    try { $Logs = kubectl logs -n $Namespace $podName | Select-Object -Last 20 } catch { $Logs = "Impossible de récupérer les logs." }

    # Tester endpoint HTTP si fourni
    if ($TestUrl) {
        try {
            $resp = Invoke-WebRequest -Uri $TestUrl -Method Head -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -eq 200) { $IsSuccess = $true } else { $IsSuccess = $false }
        } catch { $IsSuccess = $false }
    }

    Log-Status $Name $IsSuccess ($Logs -join "`n")
}

# -----------------------------
# Liste des composants
# -----------------------------
$Components = @(
    @{Name="Minikube"; Namespace="default"; Label=""; TestUrl=""; RestartCmd=""}, 
    @{Name="Strimzi Operator"; Namespace="kafka"; Label="name=strimzi-cluster-operator"; TestUrl=""; RestartCmd="kubectl rollout restart deploy/strimzi-cluster-operator -n kafka"}, 
    @{Name="Kafka Cluster"; Namespace="kafka"; Label="strimzi.io/name=my-cluster"; TestUrl=""; RestartCmd="kubectl rollout restart statefulset/my-cluster-kafka -n kafka"}, 
    @{Name="MinIO"; Namespace="storage"; Label="app=minio"; TestUrl="http://localhost:9000"; RestartCmd="kubectl rollout restart statefulset/minio -n storage"}, 
    @{Name="PostgreSQL"; Namespace="storage"; Label="app=postgresql"; TestUrl=""; RestartCmd=""}, 
    @{Name="Kafka Connect"; Namespace="kafka"; Label="app.kubernetes.io/name=strimzi-kafka-connect"; TestUrl="http://localhost:8083/connectors"; RestartCmd="kubectl rollout restart deploy/my-connect-cluster-connect -n kafka"}, 
    @{Name="Spark Master"; Namespace="default"; Label="app=spark-master"; TestUrl=""; RestartCmd="kubectl rollout restart statefulset/spark-master -n default"}, 
    @{Name="Airflow"; Namespace="airflow"; Label="app=airflow-webserver"; TestUrl="http://localhost:8080"; RestartCmd="kubectl rollout restart deploy/airflow-webserver -n airflow"}, 
    @{Name="API Gateway"; Namespace="api"; Label="app=api-gateway"; TestUrl="http://localhost:8000/docs"; RestartCmd="kubectl rollout restart deploy/api-gateway -n api"}, 
    @{Name="Dashboard React"; Namespace="dashboard"; Label="app=dashboard"; TestUrl="http://localhost:3000"; RestartCmd="kubectl rollout restart deploy/dashboard -n dashboard"}, 
    @{Name="Rasa Chatbot"; Namespace="chatbot"; Label="app=rasa"; TestUrl="http://localhost:5005/status"; RestartCmd="kubectl rollout restart deploy/rasa -n chatbot"}, 
    @{Name="Grafana"; Namespace="monitoring"; Label="app=grafana"; TestUrl="http://localhost:3001"; RestartCmd="kubectl rollout restart deploy/grafana -n monitoring"}, 
    @{Name="Prometheus"; Namespace="monitoring"; Label="app=prometheus"; TestUrl="http://localhost:9090"; RestartCmd="kubectl rollout restart deploy/prometheus -n monitoring"}, 
    @{Name="Loki"; Namespace="monitoring"; Label="app=loki"; TestUrl="http://localhost:3100"; RestartCmd="kubectl rollout restart deploy/loki -n monitoring"}, 
    @{Name="MLflow"; Namespace="mlops"; Label="app=mlflow"; TestUrl="http://localhost:5000"; RestartCmd="kubectl rollout restart deploy/mlflow -n mlops"}, 
    @{Name="Keycloak"; Namespace="auth"; Label="app=keycloak"; TestUrl="http://localhost:8081"; RestartCmd="kubectl rollout restart deploy/keycloak -n auth"}
)

# -----------------------------
# Vérification des composants
# -----------------------------
foreach ($comp in $Components) {
    Check-Component -Name $comp.Name -Namespace $comp.Namespace -LabelSelector $comp.Label -TestUrl $comp.TestUrl -RestartCmd $comp.RestartCmd
}

# -----------------------------
# Test API Scoring
# -----------------------------
Write-Host "`n===== Tests API réalistes ====="
$apiUrl = "http://localhost:8000/score/predict"
$payload = '{"age":35,"income":50000,"loan_amount":100000,"gender":"M","occupation":"Engineer","marital_status":"Married"}'
try {
    $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 5
    Write-Host "$Green`u2714 Endpoint API scoring OK$NC"
    "API Scoring Endpoint: ✅ OK" | Out-File $Report -Append
    $Success++
} catch {
    Write-Host "$Red`u274C Endpoint API scoring échoué$NC"
    "API Scoring Endpoint: ❌ Échec" | Out-File $Report -Append
    $FailedComponents += "API Scoring Endpoint"
}
$Total++

# -----------------------------
# Score global
# -----------------------------
Write-Host "`n$Yellow===== Résultat global =====$NC"
Write-Host "Services OK : $Success / $Total"
$score = [math]::Round(($Success/$Total*100),2)
Write-Host "Score global de santé : $score%"
Add-Content $Report "`nScore global de santé : $score%"

# -----------------------------
# Alerte email optionnelle
# -----------------------------
if ($FailedComponents.Count -ne 0) {
    Write-Host "⚠️ Certains composants sont en échec : $($FailedComponents -join ', ')"
    # Exemple : Send-MailMessage -To "you@example.com" -From "mlops@localhost" -Subject "Échec plateforme MLOps" -Body (Get-Content $Report | Out-String) -SmtpServer "smtp.local"
}

Write-Host "`nRapport complet sauvegardé dans $Report"
