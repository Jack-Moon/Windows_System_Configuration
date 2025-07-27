Write-Host "Test rozpoczety" -ForegroundColor Green

if (Test-Path ".\modules") {
    Write-Host "Folder modules istnieje" -ForegroundColor Green
} else {
    Write-Host "Folder modules nie istnieje" -ForegroundColor Red
}

Write-Host "Test zakonczony" -ForegroundColor White
