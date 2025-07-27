# ===================================================================
# Windows Configuration - System Module
# Purpose: Core system configuration and utilities
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
    'Test-AdministratorPrivileges',
    'Set-ExecutionPolicyForScript',
    'Set-PowerPlan',
    'Set-ComputerNameFromSerial',
    'Restart-WindowsExplorer',
    'Set-UserAccountSettings',
    'Get-SystemInfo',
    'Clear-TemporaryFiles'
)

function Test-AdministratorPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-DetailedLog -Message "Administrator privileges are required for this script" -Level "ERROR" -Component "SYSTEM"
        Write-Warning "Administrator privileges are required for this script."
        Write-Warning "Please re-launch the script from an elevated PowerShell session."
        return $false
    }
    
    Write-DetailedLog -Message "Administrator privileges verified" -Level "SUCCESS" -Component "SYSTEM"
    return $true
}

function Set-ExecutionPolicyForScript {
    Write-DetailedLog -Message "Setting execution policy..." -Level "OPERATION" -Component "SYSTEM"
    
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-DetailedLog -Message "Execution policy set to 'RemoteSigned' for the current user" -Level "SUCCESS" -Component "SYSTEM"
        Write-Host "Execution policy set to 'RemoteSigned' for the current user." -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to set execution policy: $($_.Exception.Message)" -Level "WARNING" -Component "SYSTEM"
        Write-Warning "Failed to set execution policy. Script may not run without '-ExecutionPolicy Bypass'."
    }
}

function Set-PowerPlan {
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("High Performance", "Balanced", "Power Saver")]
        [string]$PowerPlan = "High Performance"
    )
    
    Write-DetailedLog -Message "Setting power plan to: $PowerPlan" -Level "OPERATION" -Component "SYSTEM"
    
    try {
        switch ($PowerPlan) {
            "High Performance" {
                powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            }
            "Balanced" {
                powercfg.exe -SETACTIVE 381b4222-f694-41f0-9685-ff5bb260df2e
            }
            "Power Saver" {
                powercfg.exe -SETACTIVE a1841308-3541-4fab-bc81-f71556f20b4a
            }
        }
        
        Write-DetailedLog -Message "Power plan set to: $PowerPlan" -Level "SUCCESS" -Component "SYSTEM"
        Write-Host "✓ Power plan set to: $PowerPlan" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to set power plan: $($_.Exception.Message)" -Level "ERROR" -Component "SYSTEM"
    }
}

function Set-ComputerNameFromSerial {
    Write-DetailedLog -Message "Configuring computer name based on BIOS serial..." -Level "OPERATION" -Component "SYSTEM"
    
    try {
        $compDetails = Get-ComputerInfo
        
        # Check if BIOS serial number is available and valid
        $biosSerial = $null
        if ($compDetails.BiosSeralNumber -and $compDetails.BiosSeralNumber.Trim() -ne "" -and $compDetails.BiosSeralNumber -ne "To be filled by O.E.M.") {
            $biosSerial = $compDetails.BiosSeralNumber.Trim()
        } elseif ($compDetails.BiosSerialNumber -and $compDetails.BiosSerialNumber.Trim() -ne "" -and $compDetails.BiosSerialNumber -ne "To be filled by O.E.M.") {
            $biosSerial = $compDetails.BiosSerialNumber.Trim()
        } else {
            # Try WMI as fallback
            $wmiSerial = (Get-WmiObject -Class Win32_BIOS).SerialNumber
            if ($wmiSerial -and $wmiSerial.Trim() -ne "" -and $wmiSerial -ne "To be filled by O.E.M.") {
                $biosSerial = $wmiSerial.Trim()
            }
        }
        
        if ($biosSerial) {
            $currentName = $env:COMPUTERNAME
            $newName = $biosSerial
            
            if ($currentName -ne $newName) {
                Write-DetailedLog -Message "Renaming computer from '$currentName' to '$newName'" -Level "OPERATION" -Component "SYSTEM"
                Rename-Computer -NewName $newName -Force
                Write-DetailedLog -Message "Computer renamed successfully. Restart required." -Level "SUCCESS" -Component "SYSTEM"
                Write-Host "✓ Computer will be renamed to: $newName (restart required)" -ForegroundColor Green
            } else {
                Write-DetailedLog -Message "Computer name already matches BIOS serial: $currentName" -Level "INFO" -Component "SYSTEM"
                Write-Host "✓ Computer name already correct: $currentName" -ForegroundColor Green
            }
        } else {
            Write-DetailedLog -Message "Valid BIOS serial number not found. Computer will not be renamed." -Level "WARNING" -Component "SYSTEM"
            Write-Host "⚠ BIOS serial number not available. Computer will not be renamed." -ForegroundColor Yellow
        }
    } catch {
        Write-DetailedLog -Message "Error configuring computer name: $($_.Exception.Message)" -Level "ERROR" -Component "SYSTEM"
        Write-Host "✗ Error configuring computer name" -ForegroundColor Red
    }
}

function Restart-WindowsExplorer {
    Write-DetailedLog -Message "Restarting Windows Explorer..." -Level "OPERATION" -Component "SYSTEM"
    
    try {
        Get-Process explorer | Stop-Process -Force
        Write-DetailedLog -Message "Windows Explorer restarted successfully" -Level "SUCCESS" -Component "SYSTEM"
        Write-Host "✓ Windows Explorer restarted" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to restart Windows Explorer: $($_.Exception.Message)" -Level "ERROR" -Component "SYSTEM"
    }
}

function Set-UserAccountSettings {
    Write-DetailedLog -Message "Configuring user accounts..." -Level "OPERATION" -Component "SYSTEM"
    
    # Hide specific user accounts from login screen
    $accountsToHide = @("it dept", "jack", "jacek_brychcy_p")
    
    foreach ($account in $accountsToHide) {
        try {
            reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" /v $account /t REG_DWORD /d 0 /f | Out-Null
            Write-DetailedLog -Message "Hidden user account: $account" -Level "SUCCESS" -Component "SYSTEM"
        } catch {
            Write-DetailedLog -Message "Failed to hide user account: $account" -Level "WARNING" -Component "SYSTEM"
        }
    }
    
    # Set IT DEPT user password to never expire
    try {
        Set-LocalUser -Name "IT DEPT" -PasswordNeverExpires $true -ErrorAction SilentlyContinue
        Write-DetailedLog -Message "IT DEPT password set to never expire" -Level "SUCCESS" -Component "SYSTEM"
        Write-Host "IT DEPT password set to never expire" -ForegroundColor Yellow
    } catch {
        Write-DetailedLog -Message "Could not configure IT DEPT user - user may not exist" -Level "WARNING" -Component "SYSTEM"
        Write-Host "Could not configure IT DEPT user - user may not exist" -ForegroundColor Red
    }
    
    # Disable Guest account
    try {
        Disable-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        Write-DetailedLog -Message "Guest account disabled" -Level "SUCCESS" -Component "SYSTEM"
        Write-Host "Guest account disabled" -ForegroundColor Yellow
    } catch {
        Write-DetailedLog -Message "Guest account not found or already disabled" -Level "INFO" -Component "SYSTEM"
        Write-Host "Guest account not found or already disabled" -ForegroundColor Yellow
    }
    
    # Set strong password policy
    try {
        net accounts /minpwlen:8 /maxpwage:90 /lockoutthreshold:5 /lockoutduration:30 | Out-Null
        Write-DetailedLog -Message "Password policy configured" -Level "SUCCESS" -Component "SYSTEM"
    } catch {
        Write-DetailedLog -Message "Failed to set password policy" -Level "WARNING" -Component "SYSTEM"
    }
}

function Get-SystemInfo {
    Write-DetailedLog -Message "Gathering system information..." -Level "INFO" -Component "SYSTEM"
    
    try {
        $computerInfo = Get-ComputerInfo
        $systemInfo = @{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OSVersion = $computerInfo.WindowsVersion
            OSBuild = $computerInfo.WindowsBuildLabEx
            TotalMemory = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            BiosSerial = $computerInfo.BiosSerialNumber
            Manufacturer = $computerInfo.CsManufacturer
            Model = $computerInfo.CsModel
            LastBoot = $computerInfo.CsBootupState
        }
        
        Write-DetailedLog -Message "System Info: $($systemInfo | ConvertTo-Json -Compress)" -Level "INFO" -Component "SYSTEM"
        return $systemInfo
    } catch {
        Write-DetailedLog -Message "Failed to gather system information: $($_.Exception.Message)" -Level "ERROR" -Component "SYSTEM"
        return $null
    }
}

function Clear-TemporaryFiles {
    Write-DetailedLog -Message "Performing disk cleanup..." -Level "OPERATION" -Component "SYSTEM"
    
    try {
        # Clean temporary files
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-DetailedLog -Message "Temporary files cleaned" -Level "SUCCESS" -Component "SYSTEM"

        # Clear Windows Update cache
        try {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service wuauserv -ErrorAction SilentlyContinue
            Write-DetailedLog -Message "Windows Update cache cleared" -Level "SUCCESS" -Component "SYSTEM"
            Write-Host "Windows Update cache cleared" -ForegroundColor Yellow
        } catch {
            Write-DetailedLog -Message "Could not clear Windows Update cache: $($_.Exception.Message)" -Level "WARNING" -Component "SYSTEM"
            Write-Host "Could not clear Windows Update cache" -ForegroundColor Red
        }
        
        Write-Host "✓ Disk cleanup completed" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Disk cleanup failed: $($_.Exception.Message)" -Level "ERROR" -Component "SYSTEM"
        Write-Host "✗ Disk cleanup failed" -ForegroundColor Red
    }
}
