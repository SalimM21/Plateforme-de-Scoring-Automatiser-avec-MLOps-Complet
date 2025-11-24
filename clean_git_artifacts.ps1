# ============================================================
# clean_git_artifacts.ps1
# Nettoyer les fichiers suivis par Git mais ignorés dans .gitignore
# ============================================================

Write-Host "🔍 Chargement des fichiers ignorés selon .gitignore..." -ForegroundColor Cyan

# Vérifie que Git est installé
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git n'est pas installé ou non accessible dans PowerShell." -ForegroundColor Red
    exit 1
}

# Vérifie que .gitignore existe
if (-not (Test-Path ".gitignore")) {
    Write-Host "❌ Fichier .gitignore introuvable dans ce répertoire." -ForegroundColor Red
    exit 1
}

# Liste les fichiers suivis mais ignorés
$ignoredFiles = git ls-files -i -c --exclude-from=.gitignore

if (-not $ignoredFiles) {
    Write-Host "✅ Aucun fichier ignoré encore suivi par Git. Rien à nettoyer." -ForegroundColor Green
    exit 0
}

Write-Host "📦 Fichiers à nettoyer :" -ForegroundColor Yellow
$ignoredFiles | ForEach-Object { Write-Host " - $_" }

Write-Host "`n⚠️ Ces fichiers seront supprimés du suivi Git (git rm --cached)." -ForegroundColor Magenta
$confirmation = Read-Host "Continuer ? (y/n)"

if ($confirmation -ne "y") {
    Write-Host "❌ Opération annulée." -ForegroundColor DarkGray
    exit 0
}

# Suppression du suivi Git
git rm -r --cached $ignoredFiles

Write-Host "`n🔧 Mise à jour de l'index Git..." -ForegroundColor Cyan
git add .

Write-Host "📝 Commit automatique : 'clean: remove ignored tracked files'" -ForegroundColor Cyan
git commit -m "clean: remove ignored tracked files"

Write-Host "`n🎉 Nettoyage terminé avec succès !" -ForegroundColor Green
Write-Host "👉 Tous les fichiers ignorés sont maintenant correctement exclus." -ForegroundColor Green
