# ===================================================================
# Windows Configuration - Services Management Module
# Purpose: Safe management of Windows services with backup and restore capabilities
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
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
            Write-DetailedLog -Message "Service found: $ServiceName - Status: $($serviceObj.Status), StartType: $($serviceObj.StartType)" -Level "INFO" -Component "SERVICES"
            Write-Host "Processing service: $ServiceName" -ForegroundColor Cyan
            
            # Display current status
            Write-Host "  Current status: $($serviceObj.Status)" -ForegroundColor Gray
            Write-Host "  Startup type: $($serviceObj.StartType)" -ForegroundColor Gray
            if ($Description) {
                Write-DetailedLog -Message "Service description: $Description" -Level "INFO" -Component "SERVICES"
                Write-Host "  Purpose: $Description" -ForegroundColor Gray
            }
            
            # Backup current service state
            Write-DetailedLog -Message "Backing up service state: $ServiceName - Status: $($serviceObj.Status), StartType: $($serviceObj.StartType)" -Level "BACKUP" -Component "SERVICES"
            
            # Stop the service if it's running
            if ($serviceObj.Status -eq 'Running') {
                Write-DetailedLog -Message "Stopping running service: $ServiceName" -Level "OPERATION" -Component "SERVICES"
                Write-Host "  Stopping service..." -ForegroundColor Yellow
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1  # Brief pause to allow service to stop
                
                # Verify service stopped
                $serviceObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
                if ($serviceObj.Status -eq 'Stopped') {
                    Write-DetailedLog -Message "Service stopped successfully: $ServiceName" -Level "SUCCESS" -Component "SERVICES"
                    Write-Host "  ✓ Service stopped successfully" -ForegroundColor Green
                } else {
                    Write-DetailedLog -Message "Service may still be running: $ServiceName - Status: $($serviceObj.Status)" -Level "WARNING" -Component "SERVICES"
                    Write-Host "  ⚠ Service may still be running" -ForegroundColor Yellow
                }
            }
            
            # Disable the service
            Write-DetailedLog -Message "Setting service startup type to Disabled: $ServiceName" -Level "OPERATION" -Component "SERVICES"
            Write-Host "  Setting startup type to Disabled..." -ForegroundColor Yellow
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            
            # Verify the change
            $serviceObj = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($serviceObj.StartType -eq 'Disabled') {
                Write-DetailedLog -Message "Service disabled successfully: $ServiceName" -Level "SUCCESS" -Component "SERVICES"
                Write-Host "  ✓ Service disabled successfully: $ServiceName" -ForegroundColor Green
            } else {
                Write-DetailedLog -Message "Service may not be properly disabled: $ServiceName - StartType: $($serviceObj.StartType)" -Level "WARNING" -Component "SERVICES"
                Write-Host "  ⚠ Service may not be properly disabled: $ServiceName" -ForegroundColor Yellow
            }
        } else {
            Write-DetailedLog -Message "Service not found: $ServiceName" -Level "WARNING" -Component "SERVICES"
            Write-Host "⚠ Service not found: $ServiceName" -ForegroundColor Yellow
        }
    } catch {
        Write-DetailedLog -Message "Error processing service $ServiceName`: $($_.Exception.Message)" -Level "ERROR" -Component "SERVICES"
        Write-Host "✗ Error processing service $ServiceName `: $($_.Exception.Message)" -ForegroundColor Red
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
    
    Write-DetailedLog -Message "Enabling service: $ServiceName with startup type: $StartupType" -Level "OPERATION" -Component "SERVICES"
    
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
        Write-DetailedLog -Message "Error enabling service $ServiceName`: $($_.Exception.Message)" -Level "ERROR" -Component "SERVICES"
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
        Write-DetailedLog -Message "Failed to create services backup: $($_.Exception.Message)" -Level "ERROR" -Component "SERVICES"
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
                Write-DetailedLog -Message "Failed to restore service: $($service.Name) - $($_.Exception.Message)" -Level "ERROR" -Component "SERVICES"
            }
        }
        return $true
    } catch {
        Write-DetailedLog -Message "Failed to restore services: $($_.Exception.Message)" -Level "ERROR" -Component "SERVICES"
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
        @{ Name = "WMPNetworkSvc"; Description = "Windows Media Player Network Sharing Service" },
        @{ Name = "TabletInputService"; Description = "Tablet PC Input Service - not needed on desktop PCs" },
        @{ Name = "TrkWks"; Description = "Distributed Link Tracking Client - tracks file shortcuts" },
        @{ Name = "WerSvc"; Description = "Windows Error Reporting Service" },
        @{ Name = "DiagTrack"; Description = "Connected User Experiences and Telemetry" },
        @{ Name = "dmwappushservice"; Description = "WAP Push Message Routing Service - mobile networks" },
        @{ Name = "MapsBroker"; Description = "Downloaded Maps Manager" },
        @{ Name = "lfsvc"; Description = "Geolocation Service" },
        @{ Name = "RetailDemo"; Description = "Retail Demo Service - used in store displays" },
        @{ Name = "RemoteRegistry"; Description = "Remote Registry - security risk if not needed" },
        @{ Name = "SharedAccess"; Description = "Internet Connection Sharing (ICS)" },
        @{ Name = "SSDPSRV"; Description = "SSDP Discovery - UPnP device discovery" },
        @{ Name = "upnphost"; Description = "UPnP Device Host" }
    )
    
    # Add optional services based on parameters
    if ($DisableSearch) {
        $servicesToDisable += @{ Name = "WSearch"; Description = "Windows Search indexing service" }
    }
    
    if ($DisableSysMain) {
        $servicesToDisable += @{ Name = "SysMain"; Description = "System Maintenance service (SuperFetch) - can slow down SSDs" }
    }
    
    foreach ($service in $servicesToDisable) {
        Disable-WindowsService -ServiceName $service.Name -Description $service.Description
    }
    
    Write-DetailedLog -Message "Unnecessary services processing completed" -Level "SUCCESS" -Component "SERVICES"
}
