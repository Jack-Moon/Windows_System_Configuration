# ===================================================================
# Windows Configuration - System Registry Module
# Purpose: Safe registry modifications for Windows configuration
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
    'Set-RegistryValue',
    'Set-PrivacySettings',
    'Set-PerformanceSettings',
    'Set-UICustomizations',
    'Set-SecuritySettings'
)

function Set-RegistryValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("REG_DWORD", "REG_SZ", "REG_BINARY", "REG_EXPAND_SZ", "REG_MULTI_SZ")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Value,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    Write-DetailedLog -Message "Setting registry value: $Path\$Name = $Value ($Type)" -Level "OPERATION" -Component "REGISTRY"
    
    try {
        # Ensure the registry path exists
        if (!(Test-Path "Registry::$Path")) {
            New-Item -Path "Registry::$Path" -Force | Out-Null
        }
        
        # Set the registry value using reg.exe for better compatibility
        $regType = switch ($Type) {
            "REG_DWORD" { "REG_DWORD" }
            "REG_SZ" { "REG_SZ" }
            "REG_BINARY" { "REG_BINARY" }
            "REG_EXPAND_SZ" { "REG_EXPAND_SZ" }
            "REG_MULTI_SZ" { "REG_MULTI_SZ" }
        }
        
        reg add $Path /v $Name /t $regType /d $Value /f | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-DetailedLog -Message "Successfully set registry value: $Path\$Name" -Level "SUCCESS" -Component "REGISTRY"
            if ($Description) {
                Write-DetailedLog -Message "Registry description: $Description" -Level "INFO" -Component "REGISTRY"
            }
        } else {
            Write-DetailedLog -Message "Failed to set registry value: $Path\$Name" -Level "ERROR" -Component "REGISTRY"
        }
    } catch {
        Write-DetailedLog -Message "Error setting registry value $Path\$Name`: $($_.Exception.Message)" -Level "ERROR" -Component "REGISTRY"
    }
}

function Set-PrivacySettings {
    Write-DetailedLog -Message "Configuring privacy settings and disabling telemetry..." -Level "OPERATION" -Component "PRIVACY"
    
    # Disable Windows telemetry and data collection
    Write-Host "`nDisabling telemetry and data collection..." -ForegroundColor Yellow
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type "REG_DWORD" -Value "0" -Description "Disable telemetry data collection"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type "REG_DWORD" -Value "0" -Description "Disable telemetry (alternative path)"

    # Disable diagnostic data
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Name "ShowedToastAtLevel" -Type "REG_DWORD" -Value "1" -Description "Disable diagnostic tracking toast"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDeviceNameInTelemetry" -Type "REG_DWORD" -Value "0" -Description "Disable device name in telemetry"

    # Disable Windows Error Reporting
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type "REG_DWORD" -Value "1" -Description "Disable Windows Error Reporting"

    # Disable Customer Experience Improvement Program
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type "REG_DWORD" -Value "0" -Description "Disable Customer Experience Improvement Program"

    # Disable Application Compatibility Telemetry
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Type "REG_DWORD" -Value "0" -Description "Disable Application Compatibility Telemetry"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Type "REG_DWORD" -Value "1" -Description "Disable application inventory"

    # Disable Windows Defender submission of samples
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Type "REG_DWORD" -Value "2" -Description "Disable sample submission"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Type "REG_DWORD" -Value "0" -Description "Disable SpyNet reporting"

    # Disable activity history
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type "REG_DWORD" -Value "0" -Description "Disable activity feed"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type "REG_DWORD" -Value "0" -Description "Disable publishing user activities"

    # Disable location tracking
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Type "REG_DWORD" -Value "1" -Description "Disable location services"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "REG_SZ" -Value "Deny" -Description "Deny location access"

    # Disable advertising ID
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type "REG_DWORD" -Value "1" -Description "Disable advertising ID"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type "REG_DWORD" -Value "0" -Description "Disable advertising ID for user"

    # Disable sync with Microsoft services
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" -Name "SyncPolicy" -Type "REG_DWORD" -Value "5" -Description "Disable settings sync"

    Write-DetailedLog -Message "Privacy settings configured successfully" -Level "SUCCESS" -Component "PRIVACY"
}

function Set-PerformanceSettings {
    Write-DetailedLog -Message "Applying performance optimizations..." -Level "OPERATION" -Component "PERFORMANCE"
    
    # Disable Windows Update automatic restart
    Write-Host "`nConfiguring Windows Update settings..." -ForegroundColor Yellow
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type "REG_DWORD" -Value "1" -Description "Prevent automatic restart with logged on users"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type "REG_DWORD" -Value "0" -Description "Disable automatic power management for updates"

    # Optimize visual effects for performance
    Write-Host "`nOptimizing visual effects..." -ForegroundColor Yellow
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type "REG_DWORD" -Value "2" -Description "Set visual effects for best performance"

    # Disable unnecessary animations
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Control Panel\Desktop" -Name "MenuShowDelay" -Type "REG_SZ" -Value "0" -Description "Remove menu show delay"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type "REG_SZ" -Value "0" -Description "Disable window animations"

    # Set processor scheduling for background services
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type "REG_DWORD" -Value "24" -Description "Optimize processor scheduling for background services"

    # Disable Windows Update P2P sharing
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type "REG_DWORD" -Value "0" -Description "Disable P2P Windows Update sharing"

    # Enable Storage Sense (automatic cleanup)
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Type "REG_DWORD" -Value "1" -Description "Enable automatic storage cleanup"

    Write-DetailedLog -Message "Performance settings configured successfully" -Level "SUCCESS" -Component "PERFORMANCE"
}

function Set-UICustomizations {
    Write-DetailedLog -Message "Applying UI customizations..." -Level "OPERATION" -Component "UI"
    
    # Enable classic context menu in Windows 11
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Type "REG_SZ" -Value "" -Description "Enable classic context menu"

    # Disable Windows Quiet Hours/Focus Assist
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\QuietHours" -Name "Enable" -Type "REG_DWORD" -Value "0" -Description "Disable Focus Assist"

    # Hide search box from taskbar
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type "REG_DWORD" -Value "0" -Description "Hide search box from taskbar"

    # Hide Task View button from taskbar
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "REG_DWORD" -Value "0" -Description "Hide Task View button"

    # Hide Cortana button from taskbar
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Type "REG_DWORD" -Value "0" -Description "Hide Cortana button"

    # Hide Teams Chat icon from taskbar (Windows 11)
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type "REG_DWORD" -Value "0" -Description "Hide Teams Chat icon"

    # Disable multitasking view
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView" -Name "Enabled" -Type "REG_DWORD" -Value "0" -Description "Disable multitasking view"

    # Disable auto-tray for system icons
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type "REG_DWORD" -Value "0" -Description "Disable auto-tray for system icons"

    # Set File Explorer to open to "This PC" instead of Quick Access
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type "REG_DWORD" -Value "1" -Description "Open File Explorer to This PC"

    # Disable Windows Tips and Tricks
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Type "REG_DWORD" -Value "0" -Description "Disable soft landing tips"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type "REG_DWORD" -Value "0" -Description "Disable system pane suggestions"

    # Disable consumer features (suggested apps)
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "REG_DWORD" -Value "1" -Description "Disable Windows consumer features and app suggestions"

    # Disable People icon in taskbar
    Set-RegistryValue -Path "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type "REG_DWORD" -Value "0" -Description "Hide People icon from taskbar"

    # Disable accessibility key prompts
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type "REG_SZ" -Value "506" -Description "Disable Sticky Keys prompt"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Type "REG_SZ" -Value "122" -Description "Disable Filter Keys prompt"
    Set-RegistryValue -Path "HKEY_CURRENT_USER\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type "REG_SZ" -Value "58" -Description "Disable Toggle Keys prompt"

    Write-DetailedLog -Message "UI customizations applied successfully" -Level "SUCCESS" -Component "UI"
}

function Set-SecuritySettings {
    Write-DetailedLog -Message "Applying security enhancements..." -Level "OPERATION" -Component "SECURITY"
    
    # Enable UAC but reduce prompts for admins
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type "REG_DWORD" -Value "2" -Description "Enable UAC with reduced prompts for admins"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type "REG_DWORD" -Value "0" -Description "Disable secure desktop for UAC prompts"

    # Disable AutoRun for removable media
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type "REG_DWORD" -Value "255" -Description "Disable AutoRun for all drive types"

    # Disable Windows Connect Now
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "EnableRegistrars" -Type "REG_DWORD" -Value "0" -Description "Disable Windows Connect Now registrars"
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "DisableUPnPRegistrar" -Type "REG_DWORD" -Value "0" -Description "Disable UPnP registrar"

    # Disable Fast Startup (improves boot reliability)
    Set-RegistryValue -Path "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type "REG_DWORD" -Value "0" -Description "Disable Fast Startup"

    Write-DetailedLog -Message "Security settings applied successfully" -Level "SUCCESS" -Component "SECURITY"
}
