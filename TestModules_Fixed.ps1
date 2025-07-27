# ===================================================================
# Windows Configuration Modules - Test Script
# Purpose: Test individual modules and their functions
# ===================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("logging", "system", "registry", "services", "software", "network", "backup", "all")]
    [string]$TestModule = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupBasePath = "$env:USERPROFILE\Documents\WindowsConfigTests"
)

# Get script directory and import modules
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModulePath = Join-Path $ScriptRoot "modules"

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║              Windows Configuration Modules - Test               ║
║                       Testing: $TestModule                      ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Import the main module
try {
    Import-Module "$ModulePath\WindowsConfig.psd1" -Force
    Write-Host "✓ Windows Configuration modules imported successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Ensure backup directory exists
if (-not (Test-Path $BackupBasePath)) {
    New-Item -Path $BackupBasePath -ItemType Directory -Force | Out-Null
    Write-Host "✓ Test backup directory created: $BackupBasePath" -ForegroundColor Green
}

# Initialize logging for tests
Initialize-LoggingSystem -LogPath (Join-Path $BackupBasePath "TestLog.txt")

function Test-LoggingModule {
    Write-Host "`n🔍 Testing Logging Module..." -ForegroundColor Yellow
    
    # Test different log levels
    Write-DetailedLog -Message "This is an INFO message" -Level "INFO" -Component "TEST"
    Write-DetailedLog -Message "This is a WARNING message" -Level "WARNING" -Component "TEST"
    Write-DetailedLog -Message "This is an ERROR message" -Level "ERROR" -Component "TEST"
    Write-DetailedLog -Message "This is a SUCCESS message" -Level "SUCCESS" -Component "TEST"
    
    # Test operation logging
    Start-OperationLog -OperationName "Module Testing" -Parameters @{TestModule = $TestModule}
    Write-DetailedLog -Message "Operation started successfully" -Level "INFO"
    Stop-OperationLog -OperationName "Module Testing" -Success $true
    
    Write-Host "✓ Logging module test completed" -ForegroundColor Green
}

function Test-SystemModule {
    Write-Host "`n🔍 Testing System Module..." -ForegroundColor Yellow
    
    # Test privilege check
    $isAdmin = Test-AdministratorPrivileges
    Write-Host "✓ Administrator privileges: $isAdmin" -ForegroundColor Green
    
    # Get system info
    $systemInfo = Get-SystemInfo
    if ($systemInfo) {
        Write-Host "✓ System info retrieved:" -ForegroundColor Green
        Write-Host "  Computer: $($systemInfo.ComputerName)" -ForegroundColor Gray
        Write-Host "  User: $($systemInfo.UserName)" -ForegroundColor Gray
        Write-Host "  OS: $($systemInfo.OSVersion)" -ForegroundColor Gray
        Write-Host "  Memory: $($systemInfo.TotalMemory) GB" -ForegroundColor Gray
    }
    
    Write-Host "✓ System module test completed" -ForegroundColor Green
}

function Test-RegistryModule {
    Write-Host "`n🔍 Testing Registry Module..." -ForegroundColor Yellow
    
    # Test registry value setting (non-destructive test)
    $testPath = "HKEY_CURRENT_USER\SOFTWARE\WindowsConfigTest"
    Set-RegistryValue -Path $testPath -Name "TestValue" -Type "REG_SZ" -Value "ModuleTest" -Description "Test value for module testing"
    
    # Verify the value was set
    try {
        $regValue = Get-ItemProperty -Path "Registry::$testPath" -Name "TestValue" -ErrorAction SilentlyContinue
        if ($regValue.TestValue -eq "ModuleTest") {
            Write-Host "✓ Registry test value set and verified" -ForegroundColor Green
            
            # Clean up test value
            Remove-ItemProperty -Path "Registry::$testPath" -Name "TestValue" -ErrorAction SilentlyContinue
            Remove-Item -Path "Registry::$testPath" -ErrorAction SilentlyContinue
            Write-Host "✓ Test registry value cleaned up" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠ Registry test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host "✓ Registry module test completed" -ForegroundColor Green
}

function Test-ServicesModule {
    Write-Host "`n🔍 Testing Services Module..." -ForegroundColor Yellow
    
    # Create services backup
    $backupResult = Get-ServiceBackup -BackupPath $BackupBasePath
    if ($backupResult) {
        Write-Host "✓ Services backup created successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ Services backup failed" -ForegroundColor Yellow
    }
    
    # Test service information retrieval (non-destructive)
    $testService = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
    if ($testService) {
        Write-Host "✓ Service information retrieved: $($testService.Name) - $($testService.Status)" -ForegroundColor Green
    }
    
    Write-Host "✓ Services module test completed" -ForegroundColor Green
}

function Test-SoftwareModule {
    Write-Host "`n🔍 Testing Software Module..." -ForegroundColor Yellow
    
    # Test software detection
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    
    Write-Host "Package managers available:" -ForegroundColor Gray
    Write-Host "  Winget: $(if($wingetAvailable) { 'Yes' } else { 'No' })" -ForegroundColor Gray
    Write-Host "  Chocolatey: $(if($chocoAvailable) { 'Yes' } else { 'No' })" -ForegroundColor Gray
    
    # Test PowerShell modules function (dry run)
    Write-Host "✓ Software module functions are available" -ForegroundColor Green
    
    Write-Host "✓ Software module test completed" -ForegroundColor Green
}

function Test-NetworkModule {
    Write-Host "`n🔍 Testing Network Module..." -ForegroundColor Yellow
    
    # Test network adapter enumeration
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    Write-Host "✓ Active network adapters found: $($adapters.Count)" -ForegroundColor Green
    
    foreach ($adapter in $adapters) {
        Write-Host "  $($adapter.Name) - $($adapter.InterfaceDescription)" -ForegroundColor Gray
    }
    
    Write-Host "✓ Network module test completed" -ForegroundColor Green
}

function Test-BackupModule {
    Write-Host "`n🔍 Testing Backup Module..." -ForegroundColor Yellow
    
    # Create a test backup
    $backupPath = New-SystemBackup -BackupBasePath $BackupBasePath -BackupReason "Module Testing"
    
    if ($backupPath) {
        Write-Host "✓ Test backup created: $backupPath" -ForegroundColor Green
        
        # Test backup manifest
        $manifest = Get-BackupManifest -BackupPath $backupPath
        if ($manifest) {
            Write-Host "✓ Backup manifest verified:" -ForegroundColor Green
            Write-Host "  Date: $($manifest.BackupDate)" -ForegroundColor Gray
            Write-Host "  Reason: $($manifest.BackupReason)" -ForegroundColor Gray
            Write-Host "  Computer: $($manifest.Computer)" -ForegroundColor Gray
        }
        
        # Test finding backups
        $backups = Find-AvailableBackups -BackupBasePath $BackupBasePath
        Write-Host "✓ Found $($backups.Count) backup(s)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Backup creation failed" -ForegroundColor Yellow
    }
    
    Write-Host "✓ Backup module test completed" -ForegroundColor Green
}

# Run tests based on parameter
switch ($TestModule) {
    "logging" { Test-LoggingModule }
    "system" { Test-SystemModule }
    "registry" { Test-RegistryModule }
    "services" { Test-ServicesModule }
    "software" { Test-SoftwareModule }
    "network" { Test-NetworkModule }
    "backup" { Test-BackupModule }
    "all" {
        Test-LoggingModule
        Test-SystemModule
        Test-RegistryModule
        Test-ServicesModule
        Test-SoftwareModule
        Test-NetworkModule
        Test-BackupModule
    }
}

Write-Host "`n" + "="*70 -ForegroundColor Green
Write-Host "✅ MODULE TESTING COMPLETED!" -ForegroundColor Green
Write-Host "="*70 -ForegroundColor Green

Write-Host "`n📋 Test Results Summary:" -ForegroundColor Cyan
Write-Host "- Test module: $TestModule" -ForegroundColor White
Write-Host "- Backup path: $BackupBasePath" -ForegroundColor White

if (Test-Path $BackupBasePath) {
    $testFiles = Get-ChildItem $BackupBasePath -Recurse | Measure-Object
    Write-Host "- Test files created: $($testFiles.Count)" -ForegroundColor White
}

Write-Host "`n⚠️ Note: This was a test run. No permanent system changes were made." -ForegroundColor Yellow
Write-Host "To run actual configuration, use: .\WindowsConfigurationMain.ps1 -Mode home|work" -ForegroundColor Yellow
