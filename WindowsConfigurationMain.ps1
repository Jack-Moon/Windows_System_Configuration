# ===================================================================
# Windows System Configuration Script - Modular Version
# Purpose: Automated setup and customization for corporate environment
# Usage: .\WindowsConfigurationMain.ps1 -Mode home|work
# ===================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("home", "work")]
    [string]$Mode,
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupSoftware,
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupAllInstalledSoftware,
    
    [Parameter(Mandatory=$false)]
    [switch]$Restore,
    
    [Parameter(Mandatory=$false)]
    [switch]$Rollback,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupBasePath = "$env:USERPROFILE\Documents\WindowsConfigBackups"
)

# ===================================================================
# INITIALIZATION
# ===================================================================

# Get script directory and import the main Windows Configuration module
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModulePath = Join-Path $ScriptRoot "modules"

# Import the main Windows Configuration module
try {
    Import-Module "$ModulePath\WindowsConfig.psd1" -Force
    Write-Host "✓ Windows Configuration modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to import Windows Configuration modules: $($_.Exception.Message)"
    Write-Error "Please ensure the modules directory exists and contains all required module files."
    exit 1
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

function Main {
    # Display banner
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║              Windows System Configuration Script v2.0            ║
║                          Modular Version                         ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # Check for Administrator Privileges
    if (-not (Test-AdministratorPrivileges)) {
        exit 1
    }

    # Set Execution Policy
    Set-ExecutionPolicyForScript

    # Initialize Logging System
    $logPath = Initialize-LoggingSystem -BackupBasePath $BackupBasePath -ScriptName "WindowsConfigScript_v2"
    
    # Start operation logging
    $operationParams = @{
        Mode = $Mode
        BackupSoftware = $BackupSoftware.IsPresent
        BackupAllInstalledSoftware = $BackupAllInstalledSoftware.IsPresent
        Restore = $Restore.IsPresent
        Rollback = $Rollback.IsPresent
        BackupBasePath = $BackupBasePath
    }
    Start-OperationLog -OperationName "Windows System Configuration" -Parameters $operationParams

    try {
        # Handle rollback request
        if ($Rollback) {
            Write-Host "`n🔄 SYSTEM ROLLBACK MODE" -ForegroundColor Red
            $rollbackResult = Start-SystemRollback -BackupBasePath $BackupBasePath
            if ($rollbackResult) {
                Write-Host "`n✅ System rollback completed successfully" -ForegroundColor Green
                Write-Host "Please restart the computer to ensure all changes take effect" -ForegroundColor Yellow
            } else {
                Write-Host "`n❌ System rollback failed" -ForegroundColor Red
            }
            return
        }

        # Create system backup before making changes
        Write-Host "`n📦 Creating system backup..." -ForegroundColor Cyan
        $backupPath = New-SystemBackup -BackupBasePath $BackupBasePath -BackupReason "Pre-Configuration-$Mode"
        
        if ($backupPath) {
            Write-Host "✅ System backup created at: $backupPath" -ForegroundColor Green
        } else {
            Write-Host "⚠ System backup failed, but continuing with configuration..." -ForegroundColor Yellow
        }

        # Gather system information
        Write-Host "`n🔍 Gathering system information..." -ForegroundColor Cyan
        $systemInfo = Get-SystemInfo
        if ($systemInfo) {
            Write-Host "Computer: $($systemInfo.ComputerName)" -ForegroundColor Gray
            Write-Host "User: $($systemInfo.UserName)" -ForegroundColor Gray
            Write-Host "OS: $($systemInfo.OSVersion) (Build: $($systemInfo.OSBuild))" -ForegroundColor Gray
            Write-Host "Memory: $($systemInfo.TotalMemory) GB" -ForegroundColor Gray
        }

        # Configure power management
        Write-Host "`n⚡ Configuring power management..." -ForegroundColor Cyan
        Set-PowerPlan -PowerPlan "High Performance"

        # Configure network settings
        Write-Host "`n🌐 Configuring network settings..." -ForegroundColor Cyan
        Enable-RemoteDesktop
        Set-DNSServers -PrimaryDNS "1.1.1.1" -SecondaryDNS "1.0.0.1"
        Set-NetworkOptimizations
        Set-FirewallRules

        # Apply UI customizations
        Write-Host "`n🎨 Applying UI customizations..." -ForegroundColor Cyan
        Set-UICustomizations

        # Configure privacy and telemetry settings
        Write-Host "`n🔒 Configuring privacy settings..." -ForegroundColor Cyan
        Set-PrivacySettings

        # Apply performance optimizations
        Write-Host "`n🚀 Applying performance optimizations..." -ForegroundColor Cyan
        Set-PerformanceSettings

        # Configure security settings
        Write-Host "`n🛡️ Applying security enhancements..." -ForegroundColor Cyan
        Set-SecuritySettings

        # Configure services based on user input
        Write-Host "`n⚙️ Configuring Windows services..." -ForegroundColor Cyan
        
        $disableSearch = $false
        $disableSysMain = $false
        
        if ($Mode -eq "home") {
            $searchChoice = Read-Host "Do you want to disable Windows Search indexing? This will improve performance but slow down file searches. (y/n)"
            $disableSearch = ($searchChoice -eq 'y' -or $searchChoice -eq 'Y' -or $searchChoice -eq 'yes')
            
            $sysmainChoice = Read-Host "Do you want to disable SysMain (SuperFetch)? Recommended for SSDs. (y/n)"
            $disableSysMain = ($sysmainChoice -eq 'y' -or $sysmainChoice -eq 'Y' -or $sysmainChoice -eq 'yes')
        } else {
            # Work mode - more conservative approach
            $disableSearch = $false  # Keep search enabled for work
            $disableSysMain = $true  # Disable for better performance
        }
        
        Disable-UnnecessaryServices -DisableSearch:$disableSearch -DisableSysMain:$disableSysMain

        # Install PowerShell modules
        Write-Host "`n📦 Installing PowerShell modules..." -ForegroundColor Cyan
        Install-PowerShellModules

        # Software installation based on mode
        Write-Host "`n💻 Installing software..." -ForegroundColor Cyan
        
        # Install essential software first
        Install-EssentialSoftware
        
        # Mode-specific software installation
        switch ($Mode) {
            "home" {
                Install-HomeModeApps
            }
            "work" {
                Install-WorkModeApps
            }
        }

        # Remove Windows bloatware
        Write-Host "`n🗑️ Removing Windows bloatware..." -ForegroundColor Cyan
        Remove-WindowsBloatware

        # Configure user accounts
        Write-Host "`n👤 Configuring user accounts..." -ForegroundColor Cyan
        Set-UserAccountSettings

        # Set computer name based on BIOS serial
        Write-Host "`n🖥️ Configuring computer name..." -ForegroundColor Cyan
        Set-ComputerNameFromSerial

        # Perform disk cleanup
        Write-Host "`n🧹 Performing disk cleanup..." -ForegroundColor Cyan
        Clear-TemporaryFiles

        # Restart Windows Explorer to apply UI changes
        Write-Host "`n🔄 Restarting Windows Explorer..." -ForegroundColor Cyan
        Restart-WindowsExplorer

        # Final status
        Write-Host "`n" + "="*70 -ForegroundColor Green
        Write-Host "✅ WINDOWS CONFIGURATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "="*70 -ForegroundColor Green
        
        Write-Host "`n📋 SUMMARY:" -ForegroundColor Cyan
        Write-Host "- Mode: $Mode" -ForegroundColor White
        Write-Host "- Backup created: $(if($backupPath) { 'Yes' } else { 'No' })" -ForegroundColor White
        Write-Host "- Log file: $logPath" -ForegroundColor White
        
        if ($backupPath) {
            Write-Host "- Backup location: $backupPath" -ForegroundColor White
            Write-Host "- Rollback script: $backupPath\ROLLBACK_SYSTEM.ps1" -ForegroundColor White
        }
        
        Write-Host "`n⚠️ IMPORTANT NOTES:" -ForegroundColor Yellow
        Write-Host "1. Some changes require a system restart to take full effect" -ForegroundColor White
        Write-Host "2. If you experience issues, use the rollback script in the backup folder" -ForegroundColor White
        Write-Host "3. Review the log file for detailed information about all changes" -ForegroundColor White
        
        $restartChoice = Read-Host "`nWould you like to restart the computer now? (y/n)"
        if ($restartChoice -eq 'y' -or $restartChoice -eq 'Y' -or $restartChoice -eq 'yes') {
            Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
            Write-Host "Press Ctrl+C to cancel" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } else {
            Write-Host "Please restart manually when convenient." -ForegroundColor Yellow
        }

        # End operation logging
        Stop-OperationLog -OperationName "Windows System Configuration" -Success $true

    } catch {
        Write-Host "`n❌ CONFIGURATION FAILED!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-DetailedLog -Message "Script execution failed: $($_.Exception.Message)" -Level "ERROR" -Component "MAIN"
        
        # End operation logging with failure
        Stop-OperationLog -OperationName "Windows System Configuration" -Success $false
        
        if ($backupPath) {
            Write-Host "`n🔄 To rollback changes, run:" -ForegroundColor Yellow
            Write-Host ".\WindowsConfigurationMain.ps1 -Rollback" -ForegroundColor Cyan
        }
        
        exit 1
    }
}

# ===================================================================
# SCRIPT EXECUTION
# ===================================================================

# Call main function
Main
