# ===================================================================
# Windows Configuration - Logging Module
# Purpose: Centralized logging system for all Windows configuration operations
# ===================================================================

# Export module functions
Export-ModuleMember -Function @(
    'Write-DetailedLog',
    'Start-OperationLog', 
    'Stop-OperationLog',
    'Initialize-LoggingSystem'
)

# Module variables
$script:LogPath = $null
$script:BackupBasePath = $null

function Initialize-LoggingSystem {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BackupBasePath,
        
        [Parameter(Mandatory=$false)]
        [string]$ScriptName = "WindowsConfigScript"
    )
    
    $script:BackupBasePath = $BackupBasePath
    
    # Initialize logging
    $LogTimestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $LogFileName = "$ScriptName" + "_log_" + "$LogTimestamp.log"
    $script:LogPath = "$BackupBasePath\$LogFileName"

    # Ensure log directory exists
    if (!(Test-Path $BackupBasePath)) {
        New-Item -Path $BackupBasePath -ItemType Directory -Force | Out-Null
    }
    
    Write-DetailedLog -Message "Logging system initialized" -Level "INFO" -Component "LOGGING"
    Write-DetailedLog -Message "Log file: $script:LogPath" -Level "INFO" -Component "LOGGING"
    
    return $script:LogPath
}

function Write-DetailedLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "OPERATION", "BACKUP", "RESTORE")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory=$false)]
        [string]$Component = "MAIN",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoDisplay
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] [$Component] $Message"
    
    # Write to log file
    try {
        if ($script:LogPath -and (Test-Path (Split-Path $script:LogPath -Parent))) {
            Add-Content -Path $script:LogPath -Value $LogEntry -ErrorAction SilentlyContinue
        }
    } catch {
        # Fallback if log file is locked
        Write-Host "Warning: Could not write to log file" -ForegroundColor Yellow
    }
    
    # Display on screen with colors if not suppressed
    if (-not $NoDisplay) {
        switch ($Level) {
            "INFO" { 
                Write-Host $LogEntry -ForegroundColor Cyan 
            }
            "WARNING" { 
                Write-Host $LogEntry -ForegroundColor Yellow 
            }
            "ERROR" { 
                Write-Host $LogEntry -ForegroundColor Red 
            }
            "SUCCESS" { 
                Write-Host $LogEntry -ForegroundColor Green 
            }
            "OPERATION" { 
                Write-Host $LogEntry -ForegroundColor Magenta 
            }
            "BACKUP" { 
                Write-Host $LogEntry -ForegroundColor DarkYellow 
            }
            "RESTORE" { 
                Write-Host $LogEntry -ForegroundColor DarkGreen 
            }
            default { 
                Write-Host $LogEntry -ForegroundColor White 
            }
        }
    }
}

function Start-OperationLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OperationName,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-DetailedLog -Message "=== STARTING OPERATION: $OperationName ===" -Level "OPERATION"
    Write-DetailedLog -Message "Operation Parameters: $($Parameters | ConvertTo-Json -Compress)" -Level "INFO"
    Write-DetailedLog -Message "User: $env:USERNAME" -Level "INFO"
    Write-DetailedLog -Message "Computer: $env:COMPUTERNAME" -Level "INFO"
    Write-DetailedLog -Message "PowerShell Version: $($PSVersionTable.PSVersion)" -Level "INFO"
    Write-DetailedLog -Message "Execution Policy: $(Get-ExecutionPolicy)" -Level "INFO"
    Write-DetailedLog -Message "Running as Administrator: $([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" -Level "INFO"
}

function Stop-OperationLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OperationName,
        
        [Parameter(Mandatory=$false)]
        [bool]$Success = $true
    )
    
    $status = if ($Success) { "COMPLETED SUCCESSFULLY" } else { "FAILED" }
    $level = if ($Success) { "SUCCESS" } else { "ERROR" }
    Write-DetailedLog -Message "=== OPERATION $OperationName $status ===" -Level $level
}
