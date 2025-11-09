Write-Host ">>> Synchronisation avancée des sous-modules..." -ForegroundColor Cyan

# Synchroniser la configuration des submodules
git submodule sync --recursive

# Boucle sur chaque sous-module
$submodules = git config --file .gitmodules --get-regexp path | ForEach-Object { $_ -split ' ' } | ForEach-Object { $_[1] }

foreach ($sub in $submodules) {
    Write-Host "---------------------------------------------" -ForegroundColor Gray
    Write-Host "Sous-module : $sub" -ForegroundColor Yellow
    Write-Host "---------------------------------------------" -ForegroundColor Gray

    Push-Location $sub

    # Branche active
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Host "Branche active : $branch" -ForegroundColor Cyan

    git add .

    # Vérifier les changements
    $changes = git status --porcelain
    if ($changes) {
        Write-Host "Commit des modifications..." -ForegroundColor Yellow
        git commit -m "Mise à jour automatique du sous-module ($sub)"
        Write-Host "Push vers origin/$branch ..." -ForegroundColor Green
        git push origin $branch
    }
    else {
        Write-Host "Aucun changement local." -ForegroundColor DarkGreen
    }

    Pop-Location
    Write-Host ""
}

# Mise à jour des pointeurs dans le projet racine
Write-Host "---------------------------------------------" -ForegroundColor Gray
Write-Host "Mise à jour des pointeurs dans le projet racine..." -ForegroundColor Cyan
Write-Host "---------------------------------------------" -ForegroundColor Gray

git add .
$rootChanges = git status --porcelain
if ($rootChanges) {
    git commit -m "Synchronisation automatique des sous-modules"
    git push
    Write-Host "Pointeurs mis à jour et poussés." -ForegroundColor Green
}
else {
    Write-Host "Aucun changement dans le projet principal." -ForegroundColor DarkGreen
}

Write-Host "Synchronisation complète terminée !" -ForegroundColor Green
