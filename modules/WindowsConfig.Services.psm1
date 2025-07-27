# ===================================================================
# Windows Configuration Module - Services Management
# Purpose: Safe management of Windows services with backup capabilities
# ===================================================================

# Import logging module for detailed logging
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force -DisableNameChecking

# Functions to export
$ModuleFunctions = @(
    'Disable-WindowsService',
    'Enable-WindowsService', 
    'Get-ServiceBackup',
    'Restore-ServicesFromBackup',
    'Disable-UnnecessaryServices'
)

function Disable-WindowsService {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    Write-DetailedLog -Message "Processing service: $ServiceName" -Level "OPERATION" -Component "SERVICES"
    
    try {
        $serviceObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($serviceObj) {
            # Stop the service if it's running
            if ($serviceObj.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped service: $ServiceName" -ForegroundColor Yellow
            }
            
            # Disable the service
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
            
            # Verify the change
            $serviceObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($serviceObj.StartType -eq "Disabled") {
                Write-DetailedLog -Message "Service disabled: $ServiceName" -Level "SUCCESS" -Component "SERVICES"
                Write-Host "✓ Service disabled: $ServiceName" -ForegroundColor Green
                if ($Description) {
                    Write-Host "  $Description" -ForegroundColor Gray
                }
            } else {
                Write-DetailedLog -Message "Service may not be properly disabled: $ServiceName - StartType: $($serviceObj.StartType)" -Level "WARNING" -Component "SERVICES"
                Write-Host "  ⚠ Service may not be properly disabled: $ServiceName" -ForegroundColor Yellow
            }
        } else {
            Write-DetailedLog -Message "Service not found: $ServiceName" -Level "WARNING" -Component "SERVICES"
            Write-Host "⚠ Service not found: $ServiceName" -ForegroundColor Yellow
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-DetailedLog -Message "Error processing service $ServiceName - $errorMsg" -Level "ERROR" -Component "SERVICES"
        Write-Host "✗ Error processing service $ServiceName - $errorMsg" -ForegroundColor Red
    }
}

function Enable-WindowsService {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Automatic", "Manual", "Disabled")]
        [string]$StartupType = "Automatic"
    )
    
    try {
        $serviceObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($serviceObj) {
            Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
            Write-DetailedLog -Message "Service enabled: $ServiceName" -Level "SUCCESS" -Component "SERVICES"
            Write-Host "✓ Service enabled: $ServiceName" -ForegroundColor Green
        } else {
            Write-DetailedLog -Message "Service not found: $ServiceName" -Level "WARNING" -Component "SERVICES"
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-DetailedLog -Message "Error enabling service $ServiceName - $errorMsg" -Level "ERROR" -Component "SERVICES"
    }
}

function Get-ServiceBackup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    
    Write-DetailedLog -Message "Creating services backup..." -Level "BACKUP" -Component "SERVICES"
    
    try {
        $services = Get-Service | Select-Object Name, Status, StartType, ServiceType
        $services | Export-Csv "$BackupPath\ServicesBackup.csv" -NoTypeInformation
        Write-DetailedLog -Message "Services backup created at: $BackupPath\ServicesBackup.csv" -Level "SUCCESS" -Component "SERVICES"
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Write-DetailedLog -Message "Failed to create services backup: $errorMsg" -Level "ERROR" -Component "SERVICES"
        return $false
    }
}

function Restore-ServicesFromBackup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupPath
    )
    
    $backupFile = "$BackupPath\ServicesBackup.csv"
    if (!(Test-Path $backupFile)) {
        Write-DetailedLog -Message "Services backup file not found: $backupFile" -Level "ERROR" -Component "SERVICES"
        return $false
    }
    
    Write-DetailedLog -Message "Restoring services from backup..." -Level "RESTORE" -Component "SERVICES"
    
    try {
        $servicesBackup = Import-Csv $backupFile
        foreach ($service in $servicesBackup) {
            try {
                $currentService = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if ($currentService -and $currentService.StartType -ne $service.StartType) {
                    Set-Service -Name $service.Name -StartupType $service.StartType -ErrorAction SilentlyContinue
                    Write-DetailedLog -Message "Restored service: $($service.Name) to StartType: $($service.StartType)" -Level "SUCCESS" -Component "SERVICES"
                }
            } catch {
                $errorMsg = $_.Exception.Message
                Write-DetailedLog -Message "Failed to restore service: $($service.Name) - $errorMsg" -Level "ERROR" -Component "SERVICES"
            }
        }
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Write-DetailedLog -Message "Failed to restore services: $errorMsg" -Level "ERROR" -Component "SERVICES"
        return $false
    }
}

function Disable-UnnecessaryServices {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$DisableSearch,
        
        [Parameter(Mandatory=$false)]
        [switch]$DisableSysMain
    )
    
    Write-DetailedLog -Message "Disabling unnecessary services..." -Level "OPERATION" -Component "SERVICES"
    
    # List of services to disable for better performance
    $servicesToDisable = @(
        @{ Name = "Fax"; Description = "Fax service - rarely used in modern environments" },
        @{ Name = "RemoteRegistry"; Description = "Remote Registry service - security risk" },
        @{ Name = "WerSvc"; Description = "Windows Error Reporting service" },
        @{ Name = "DiagTrack"; Description = "Diagnostics Tracking service - telemetry" },
        @{ Name = "dmwappushservice"; Description = "WAP Push Message Routing service" },
        @{ Name = "XblAuthManager"; Description = "Xbox Live Auth Manager - for non-gamers" },
        @{ Name = "XblGameSave"; Description = "Xbox Live Game Save service - for non-gamers" },
        @{ Name = "XboxNetApiSvc"; Description = "Xbox Live Networking service - for non-gamers" },
        @{ Name = "XboxGipSvc"; Description = "Xbox Accessory Management service - for non-gamers" }
    )
    
    # Optional services based on user preference
    if ($DisableSearch) {
        $servicesToDisable += @{ Name = "WSearch"; Description = "Windows Search service - improves performance but slows down file searches" }
    }
    
    if ($DisableSysMain) {
        $servicesToDisable += @{ Name = "SysMain"; Description = "System Maintenance service (SuperFetch) - can slow down SSDs" }
    }
    
    foreach ($service in $servicesToDisable) {
        Disable-WindowsService -ServiceName $service.Name -Description $service.Description
    }
    
    Write-DetailedLog -Message "Unnecessary services processing completed" -Level "SUCCESS" -Component "SERVICES"
}

# Export functions
Export-ModuleMember -Function $ModuleFunctions
