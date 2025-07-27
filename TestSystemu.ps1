# Test modułu Windows Configuration
# Sprawdzenie czy moduły działają

Write-Host "🔍 Testowanie modularnego systemu Windows Configuration..." -ForegroundColor Cyan

# Sprawdź czy folder modules istnieje
if (Test-Path ".\modules") {
    Write-Host "✓ Folder modules istnieje" -ForegroundColor Green
} else {
    Write-Host "❌ Folder modules nie istnieje" -ForegroundColor Red
    exit 1
}

# Sprawdź pliki modułów
$requiredFiles = @(
    "WindowsConfig.psd1",
    "WindowsConfig.psm1", 
    "WindowsConfig.Logging.psm1",
    "WindowsConfig.System.psm1",
    "WindowsConfig.Registry.psm1",
    "WindowsConfig.Services.psm1",
    "WindowsConfig.Software.psm1",
    "WindowsConfig.Network.psm1",
    "WindowsConfig.Backup.psm1"
)

foreach ($file in $requiredFiles) {
    $filePath = ".\modules\$file"
    if (Test-Path $filePath) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file - BRAK" -ForegroundColor Red
    }
}

Write-Host "`n🧪 Próba ładowania głównego modułu..." -ForegroundColor Yellow

try {
    Import-Module ".\modules\WindowsConfig.psd1" -Force
    Write-Host "✅ SUKCES! Moduły zostały załadowane pomyślnie!" -ForegroundColor Green
    
    # Sprawdź dostępne funkcje
    $commands = Get-Command -Module WindowsConfig* | Measure-Object
    Write-Host "📊 Dostępne komendy: $($commands.Count)" -ForegroundColor Cyan
    
    # Test prostych funkcji
    if (Get-Command Test-AdministratorPrivileges -ErrorAction SilentlyContinue) {
        Write-Host "✓ Funkcje systemu dostępne" -ForegroundColor Green
    }
    
    if (Get-Command Initialize-LoggingSystem -ErrorAction SilentlyContinue) {
        Write-Host "✓ Funkcje logowania dostępne" -ForegroundColor Green
    }
    
} catch {
    Write-Host "❌ BŁĄD podczas ładowania modułów:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`n🔧 Problem zostanie naprawiony..." -ForegroundColor Yellow
}

Write-Host "`n" + "="*50
Write-Host "Test zakończony" -ForegroundColor White
Write-Host "="*50
