# ============================================================================
# Скрипт автоматической сборки актуальных ZIP-архивов в папку dist/
# 1. dist/devops-nightmare-desktop.zip — Полная десктопная версия с .exe (для отправки друзьям)
# 2. dist/devops-nightmare.zip         — Лёгкий архив проекта (для GitHub и быстрой передачи)
# ============================================================================

$projectDir = $PSScriptRoot
if (-not $projectDir) { $projectDir = Get-Location }

$distDir = Join-Path $projectDir "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

# 1. Собираем лёгкий архив исходников (Godot 4 + Web Prototype)
$sourceItems = @(
    (Join-Path $projectDir "project.godot"),
    (Join-Path $projectDir "icon.svg"),
    (Join-Path $projectDir "open_editor.bat"),
    (Join-Path $projectDir "README.md"),
    (Join-Path $projectDir "scenes"),
    (Join-Path $projectDir "scripts"),
    (Join-Path $projectDir "shaders"),
    (Join-Path $projectDir "web_prototype")
)

$lightZipPath = Join-Path $distDir "devops-nightmare.zip"
if (Test-Path $lightZipPath) { Remove-Item $lightZipPath -Force }
Compress-Archive -Path $sourceItems -DestinationPath $lightZipPath -CompressionLevel Optimal -Force
$lightSizeKB = [math]::Round((Get-Item $lightZipPath).Length / 1KB, 1)
Write-Host "[1/2] Архив проекта (для репо) обновлён: $lightZipPath ($lightSizeKB KB)" -ForegroundColor Cyan

# 2. Собираем полный автономный десктопный архив с DevOpsNightmare.exe (если .exe присутствует)
$exePath = Join-Path $projectDir "DevOpsNightmare.exe"
$desktopZipPath = Join-Path $distDir "devops-nightmare-desktop.zip"
if (Test-Path $exePath) {
    if (Test-Path $desktopZipPath) { Remove-Item $desktopZipPath -Force }
    $desktopItems = @(
        $exePath,
        (Join-Path $projectDir "project.godot"),
        (Join-Path $projectDir "icon.svg"),
        (Join-Path $projectDir "README.md"),
        (Join-Path $projectDir "scenes"),
        (Join-Path $projectDir "scripts"),
        (Join-Path $projectDir "shaders")
    )
    Compress-Archive -Path $desktopItems -DestinationPath $desktopZipPath -CompressionLevel Optimal -Force
    $desktopSizeMB = [math]::Round((Get-Item $desktopZipPath).Length / 1MB, 1)
    Write-Host "[2/2] Полный десктопный ZIP (с .exe) обновлён: $desktopZipPath ($desktopSizeMB MB)" -ForegroundColor Green
}
