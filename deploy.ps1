Write-Host "🏗️ Compilando Salufit 2026..." -ForegroundColor Cyan
flutter build apk --debug

$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "🗑️ Eliminando versión antigua..." -ForegroundColor Yellow
& $adbPath uninstall com.salufit.app

Write-Host "📲 Instalando versión limpia con permisos totales..." -ForegroundColor Green
& $adbPath install -g "build\app\outputs\flutter-apk\app-debug.apk"

Write-Host "🚀 Lanzando aplicación..." -ForegroundColor Cyan
& $adbPath shell monkey -p com.salufit.app -c android.intent.category.LAUNCHER 1