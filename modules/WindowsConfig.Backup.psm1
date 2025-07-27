# ===================================================================
# Windows Configuration - System Backup Module
# Purpose: System backup and restore functionality
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
    'New-SystemBackup',
    'Start-SystemRollback',
    'Find-AvailableBackups',
    'Get-BackupManifest'
)

function New-SystemBackup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupBasePath,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupReason = "Pre-Script-Execution"
    )
    
    Write-DetailedLog -Message "Creating system backup before making changes..." -Level "BACKUP"
    
    $LogTimestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $systemBackupPath = "$BackupBasePath\SystemBackup_$LogTimestamp"
    New-Item -Path $systemBackupPath -ItemType Directory -Force | Out-Null
    
    try {
        # Backup critical registry keys
        Write-DetailedLog -Message "Backing up critical registry keys..." -Level "BACKUP"
        
        $criticalKeys = @{
            "Services" = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services"
            "WindowsUpdate" = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            "Explorer" = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
            "Taskbar" = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            "Privacy" = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            "Cortana" = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            "TelemetryAndDiagnostics" = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        }
        
        foreach ($key in $criticalKeys.GetEnumerator()) {
            try {
                $exportPath = "$systemBackupPath\Registry_$($key.Key).reg"
                $result = reg export $key.Value $exportPath /y 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-DetailedLog -Message "Registry key exported: $($key.Key)" -Level "BACKUP"
                } else {
                    Write-DetailedLog -Message "Failed to export registry key: $($key.Key)" -Level "WARNING"
                }
            } catch {
                Write-DetailedLog -Message "Error exporting registry key $($key.Key): $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Backup current services configuration
        Write-DetailedLog -Message "Backing up services configuration..." -Level "BACKUP"
        try {
            $services = Get-Service | Select-Object Name, Status, StartType, ServiceType
            $services | Export-Csv "$systemBackupPath\ServicesBackup.csv" -NoTypeInformation
            Write-DetailedLog -Message "Services configuration backed up successfully" -Level "BACKUP"
        } catch {
            Write-DetailedLog -Message "Failed to backup services configuration: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Backup current Windows features
        Write-DetailedLog -Message "Backing up Windows features..." -Level "BACKUP"
        try {
            $features = Get-WindowsOptionalFeature -Online | Select-Object FeatureName, State
            $features | Export-Csv "$systemBackupPath\WindowsFeaturesBackup.csv" -NoTypeInformation
            Write-DetailedLog -Message "Windows features backed up successfully" -Level "BACKUP"
        } catch {
            Write-DetailedLog -Message "Failed to backup Windows features: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Create rollback script
        $rollbackScript = @"
# System Rollback Script
# Generated: $(Get-Date)
# Backup Location: $systemBackupPath

Write-Host "System Rollback Script" -ForegroundColor Red
Write-Host "======================" -ForegroundColor Red
Write-Host "This will restore system settings to state before script execution"
Write-Host "Backup created: $(Get-Date)"

# Restore registry keys
Write-Host "`nRestoring registry keys..." -ForegroundColor Yellow
Get-ChildItem "$systemBackupPath\*.reg" | ForEach-Object {
    try {
        Write-Host "Importing: `$(`$_.Name)" -ForegroundColor Cyan
        reg import "`$(`$_.FullName)" /reg:64
        if (`$LASTEXITCODE -eq 0) {
            Write-Host "✓ Successfully imported: `$(`$_.Name)" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to import: `$(`$_.Name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Error importing `$(`$_.Name): `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

# Restore services
Write-Host "`nRestoring services configuration..." -ForegroundColor Yellow
try {
    `$servicesBackup = Import-Csv "$systemBackupPath\ServicesBackup.csv"
    foreach (`$service in `$servicesBackup) {
        try {
            `$currentService = Get-Service -Name `$service.Name -ErrorAction SilentlyContinue
            if (`$currentService -and `$currentService.StartType -ne `$service.StartType) {
                Set-Service -Name `$service.Name -StartupType `$service.StartType
                Write-Host "✓ Restored service: `$(`$service.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "✗ Failed to restore service: `$(`$service.Name)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "✗ Failed to restore services configuration" -ForegroundColor Red
}

Write-Host "`n✅ System rollback completed" -ForegroundColor Green
Write-Host "Please restart the computer to ensure all changes take effect" -ForegroundColor Yellow
"@
        
        $rollbackScript | Out-File "$systemBackupPath\ROLLBACK_SYSTEM.ps1" -Encoding UTF8
        
        # Create backup manifest
        $backupManifest = @{
            BackupDate = Get-Date
            BackupReason = $BackupReason
            BackupPath = $systemBackupPath
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
            ScriptVersion = "2.0"
            BackupType = "SystemConfiguration"
        }
        
        $backupManifest | ConvertTo-Json -Depth 3 | Out-File "$systemBackupPath\BACKUP_MANIFEST.json" -Encoding UTF8
        
        Write-DetailedLog -Message "System backup completed successfully at: $systemBackupPath" -Level "SUCCESS"
        return $systemBackupPath
        
    } catch {
        Write-DetailedLog -Message "System backup failed: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Start-SystemRollback {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupBasePath
    )
    
    Write-DetailedLog -Message "Starting system rollback process..." -Level "RESTORE"
    
    if (!(Test-Path $BackupBasePath)) {
        Write-DetailedLog -Message "No backup directory found: $BackupBasePath" -Level "ERROR"
        return $false
    }
    
    # Find available system backups
    $systemBackups = Get-ChildItem $BackupBasePath -Directory | 
        Where-Object { $_.Name -like "SystemBackup_*" } |
        Sort-Object CreationTime -Descending
    
    if ($systemBackups.Count -eq 0) {
        Write-DetailedLog -Message "No system backups found for rollback" -Level "ERROR"
        return $false
    }
    
    Write-Host "`n🔄 SYSTEM ROLLBACK" -ForegroundColor Red
    Write-Host "Available system backups:" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $systemBackups.Count; $i++) {
        $backup = $systemBackups[$i]
        $manifestPath = Join-Path $backup.FullName "BACKUP_MANIFEST.json"
        
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            Write-Host "$($i + 1). $($backup.Name)" -ForegroundColor Cyan
            Write-Host "   Date: $($manifest.BackupDate)" -ForegroundColor Gray
            Write-Host "   Reason: $($manifest.BackupReason)" -ForegroundColor Gray
        } else {
            Write-Host "$($i + 1). $($backup.Name)" -ForegroundColor Cyan
            Write-Host "   Date: $($backup.CreationTime)" -ForegroundColor Gray
            Write-Host "   Reason: Unknown (manifest missing)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nSelect backup to rollback to (1-$($systemBackups.Count)) or 'q' to quit: " -NoNewline
    $selection = Read-Host
    
    if ($selection -eq 'q' -or $selection -eq 'Q') {
        Write-DetailedLog -Message "Rollback cancelled by user" -Level "INFO"
        return $false
    }
    
    if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $systemBackups.Count) {
        $selectedBackup = $systemBackups[[int]$selection - 1]
        Write-DetailedLog -Message "Selected backup: $($selectedBackup.FullName)" -Level "RESTORE"
        
        # Execute rollback script
        $rollbackScript = Join-Path $selectedBackup.FullName "ROLLBACK_SYSTEM.ps1"
        if (Test-Path $rollbackScript) {
            Write-Host "`nExecuting rollback script..." -ForegroundColor Yellow
            & $rollbackScript
            return $true
        } else {
            Write-DetailedLog -Message "Rollback script not found in backup" -Level "ERROR"
            return $false
        }
    } else {
        Write-DetailedLog -Message "Invalid selection: $selection" -Level "ERROR"
        return $false
    }
}

function Find-AvailableBackups {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupBasePath
    )
    
    if (!(Test-Path $BackupBasePath)) {
        return @()
    }
    
    $backups = Get-ChildItem $BackupBasePath -Directory | 
        Where-Object { $_.Name -like "SystemBackup_*" } |
        Sort-Object CreationTime -Descending
    
    return $backups
}

function Get-BackupManifest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    
    $manifestPath = Join-Path $BackupPath "BACKUP_MANIFEST.json"
    if (Test-Path $manifestPath) {
        return Get-Content $manifestPath | ConvertFrom-Json
    } else {
        return $null
    }
}
