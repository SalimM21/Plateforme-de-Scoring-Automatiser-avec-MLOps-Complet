# ===========================================
# Script : update_all_submodules.ps1
# Description : Synchronisation automatique des sous-modules Git et mise à jour des pointeurs
# ===========================================

Write-Host "Synchronisation avancée des sous-modules..." -ForegroundColor Cyan

# Synchroniser la config des submodules
git submodule sync --recursive

# Initialisation des tableaux pour le rapport
$updatedSubs = @()
$upToDateSubs = @()
$notFoundSubs = @()

# Récupérer la liste des sous-modules
$submodules = git config --file .gitmodules --get-regexp path | ForEach-Object { $_.Split(" ")[1] }

# Boucle sur chaque sous-module
foreach ($sub in $submodules) {
    try {
        Push-Location $sub

        Write-Host "Sous-module : $sub" -ForegroundColor Yellow

        # Détecter la branche active
        $branch = git rev-parse --abbrev-ref HEAD
        Write-Host "Branche active : $branch" -ForegroundColor Cyan

        git add .
        $changes = git status --porcelain

        if ($changes) {
            Write-Host "Commit des modifications..." -ForegroundColor Yellow
            git commit -m "Mise à jour automatique du sous-module ($sub)"
            Write-Host "Push vers origin/$branch ..." -ForegroundColor Green
            git push origin $branch
            Write-Host "Sous-module $sub mis à jour." -ForegroundColor Green
            $updatedSubs += $sub
        } else {
            Write-Host "Aucun changement local." -ForegroundColor DarkGreen
            $upToDateSubs += $sub
        }

        Pop-Location
    } catch {
        Write-Host "Sous-module $sub introuvable ou erreur." -ForegroundColor Red
        $notFoundSubs += $sub
    }
}

# Mise à jour des pointeurs dans le projet racine
Write-Host "Mise à jour des pointeurs dans le projet racine..." -ForegroundColor Cyan

git add .
$rootChanges = git status --porcelain
if ($rootChanges) {
    git commit -m "Synchronisation automatique des sous-modules"
    git push
    Write-Host "Pointeurs mis à jour et poussés." -ForegroundColor Green
} else {
    Write-Host "Aucun changement dans le projet principal." -ForegroundColor DarkGreen
}

# Rapport final
Write-Host "`nRapport final de synchronisation des sous-modules" -ForegroundColor Cyan
Write-Host "Sous-modules mis à jour : $($updatedSubs -join ', ')" -ForegroundColor Green
Write-Host "Sous-modules déjà à jour : $($upToDateSubs -join ', ')" -ForegroundColor Yellow
Write-Host "Sous-modules non trouvés : $($notFoundSubs -join ', ')" -ForegroundColor Red
Write-Host "Synchronisation complète terminée !" -ForegroundColor Green
