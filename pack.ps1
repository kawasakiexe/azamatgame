# ============================================================================
# Скрипт автоматической сборки ZIP-архива для офлайн-передачи
# Создаёт архив dist/devops-nightmare.zip со всеми нужными файлами игры
# ============================================================================

$projectDir = $PSScriptRoot
if (-not $projectDir) { $projectDir = Get-Location }

$distDir = Join-Path $projectDir "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$files = @(
    (Join-Path $projectDir "index.html"),
    (Join-Path $projectDir "style.css"),
    (Join-Path $projectDir "three.min.js"),
    (Join-Path $projectDir "audio.js"),
    (Join-Path $projectDir "engine.js"),
    (Join-Path $projectDir "view3d.js"),
    (Join-Path $projectDir "README.md")
)

$zipPath = Join-Path $distDir "devops-nightmare.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path $files -DestinationPath $zipPath -Force
$size = (Get-Item $zipPath).Length / 1KB

Write-Host "ZIP-архив успешно собран: $zipPath ($([math]::Round($size, 1)) KB)" -ForegroundColor Green
