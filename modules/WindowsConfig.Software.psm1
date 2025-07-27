# ===================================================================
# Windows Configuration - Software Management Module
# Purpose: Automated software installation and management
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
    'Install-Software',
    'Request-InstallSoftware',
    'Install-EssentialSoftware',
    'Install-HomeModeApps',
    'Install-WorkModeApps',
    'Remove-WindowsBloatware',
    'Install-PowerShellModules'
)

function Install-Software {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory=$false)]
        [string]$WingetID = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ChocoPackage = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ChocoParams = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Silent = $false
    )
    
    $installed = $false
    
    Write-DetailedLog -Message "Installing software: $SoftwareName" -Level "OPERATION" -Component "SOFTWARE"
    
    # Try Winget first if ID is provided
    if ($WingetID -ne "" -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        try {
            Write-Host "Installing $SoftwareName via Winget..." -ForegroundColor Yellow
            $wingetArgs = @("install", $WingetID, "--accept-package-agreements", "--accept-source-agreements")
            if ($Silent) {
                $wingetArgs += "--silent"
            }
            
            $result = & winget @wingetArgs 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-DetailedLog -Message "Successfully installed $SoftwareName via Winget" -Level "SUCCESS" -Component "SOFTWARE"
                Write-Host "✓ $SoftwareName installed successfully via Winget" -ForegroundColor Green
                $installed = $true
            } else {
                Write-DetailedLog -Message "Winget installation failed for $SoftwareName" -Level "WARNING" -Component "SOFTWARE"
                Write-Host "⚠ Winget installation failed for $SoftwareName" -ForegroundColor Yellow
            }
        } catch {
            Write-DetailedLog -Message "Error installing $SoftwareName via Winget: $($_.Exception.Message)" -Level "WARNING" -Component "SOFTWARE"
        }
    }
    
    # Fallback to Chocolatey if Winget failed or not available
    if (-not $installed -and $ChocoPackage -ne "") {
        try {
            Write-Host "Installing $SoftwareName via Chocolatey..." -ForegroundColor Yellow
            $chocoArgs = @("install", $ChocoPackage, "-y", "--force")
            if ($ChocoParams -ne "") {
                $chocoArgs += $ChocoParams
            }
            
            $result = & choco @chocoArgs 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-DetailedLog -Message "Successfully installed $SoftwareName via Chocolatey" -Level "SUCCESS" -Component "SOFTWARE"
                Write-Host "✓ $SoftwareName installed successfully via Chocolatey" -ForegroundColor Green
                $installed = $true
            } else {
                Write-DetailedLog -Message "Chocolatey installation failed for $SoftwareName" -Level "ERROR" -Component "SOFTWARE"
                Write-Host "✗ Chocolatey installation failed for $SoftwareName" -ForegroundColor Red
            }
        } catch {
            Write-DetailedLog -Message "Error installing $SoftwareName via Chocolatey: $($_.Exception.Message)" -Level "ERROR" -Component "SOFTWARE"
        }
    }
    
    if (-not $installed) {
        Write-Host "Failed to install $SoftwareName via both Winget and Chocolatey" -ForegroundColor Red
    }
    
    return $installed
}

function Request-InstallSoftware {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory=$false)]
        [string]$WingetID = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ChocoPackage = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [string]$ChocoParams = ""
    )
    
    $choice = Read-Host "Do you want to install $SoftwareName ($Description)? (y/n)"
    if ($choice -eq 'y' -or $choice -eq 'Y' -or $choice -eq 'yes') {
        Install-Software -SoftwareName $SoftwareName -WingetID $WingetID -ChocoPackage $ChocoPackage -ChocoParams $ChocoParams
    } else {
        Write-Host "Skipping $SoftwareName installation" -ForegroundColor Yellow
    }
}

function Install-EssentialSoftware {
    Write-DetailedLog -Message "Installing essential software..." -Level "OPERATION" -Component "SOFTWARE"
    
    $essentialApps = @(
        @{ Name = "7-Zip"; WingetID = "7zip.7zip"; ChocoPackage = "7zip"; Description = "File archiver" },
        @{ Name = "Notepad++"; WingetID = "Notepad++.Notepad++"; ChocoPackage = "notepadplusplus"; Description = "Advanced text editor" },
        @{ Name = "PowerToys"; WingetID = "Microsoft.PowerToys"; ChocoPackage = "powertoys"; Description = "Windows system utilities" },
        @{ Name = "Windows Terminal"; WingetID = "Microsoft.WindowsTerminal"; ChocoPackage = "microsoft-windows-terminal"; Description = "Modern terminal application" }
    )
    
    foreach ($app in $essentialApps) {
        Install-Software -SoftwareName $app.Name -WingetID $app.WingetID -ChocoPackage $app.ChocoPackage -Silent $true
    }
}

function Install-HomeModeApps {
    Write-Host "`n--- HOME MODE SOFTWARE SELECTION ---" -ForegroundColor Cyan
    Write-Host "Select software to install. Each category will be presented separately." -ForegroundColor Yellow
    
    # Basic Applications
    Write-Host "`n=== BASIC APPLICATIONS ===" -ForegroundColor Magenta
    Request-InstallSoftware -SoftwareName "Bitwarden" -WingetID "Bitwarden.Bitwarden" -ChocoPackage "bitwarden" -Description "Password manager"
    Request-InstallSoftware -SoftwareName "Office 365 Enterprise" -WingetID "Microsoft.Office" -ChocoPackage "office365business" -Description "Microsoft Office suite"
    Request-InstallSoftware -SoftwareName "Visual Studio Code" -WingetID "Microsoft.VisualStudioCode" -ChocoPackage "vscode" -Description "Code editor and IDE" -ChocoParams "--params '/NoDesktopIcon /NoQuicklaunchIcon'"
    
    # Development Tools
    Write-Host "`n=== DEVELOPMENT TOOLS ===" -ForegroundColor Magenta
    Request-InstallSoftware -SoftwareName "Git for Windows" -WingetID "Git.Git" -ChocoPackage "git" -Description "Distributed version control system"
    Request-InstallSoftware -SoftwareName "GitHub Desktop" -WingetID "GitHub.GitHubDesktop" -ChocoPackage "github-desktop" -Description "GUI for GitHub"
    Request-InstallSoftware -SoftwareName "Python" -WingetID "Python.Python.3.12" -ChocoPackage "python" -Description "Python programming language"
    Request-InstallSoftware -SoftwareName "Docker Desktop" -WingetID "Docker.DockerDesktop" -ChocoPackage "docker-desktop" -Description "Containerization platform"
    
    # Network & Security Tools
    Write-Host "`n=== NETWORK & SECURITY TOOLS ===" -ForegroundColor Magenta
    Request-InstallSoftware -SoftwareName "Wireshark" -WingetID "WiresharkFoundation.Wireshark" -ChocoPackage "wireshark" -Description "Network protocol analyzer"
    Request-InstallSoftware -SoftwareName "PuTTY" -WingetID "PuTTY.PuTTY" -ChocoPackage "putty" -Description "SSH and telnet client"
    Request-InstallSoftware -SoftwareName "WinSCP" -WingetID "WinSCP.WinSCP" -ChocoPackage "winscp" -Description "SFTP and SCP client"
    
    # Browsers & Communication
    Write-Host "`n=== BROWSERS & COMMUNICATION ===" -ForegroundColor Magenta
    Request-InstallSoftware -SoftwareName "Google Chrome" -WingetID "Google.Chrome" -ChocoPackage "googlechrome" -Description "Web browser"
    Request-InstallSoftware -SoftwareName "Mozilla Firefox" -WingetID "Mozilla.Firefox" -ChocoPackage "firefox" -Description "Web browser"
    Request-InstallSoftware -SoftwareName "WhatsApp Desktop" -WingetID "WhatsApp.WhatsApp" -ChocoPackage "whatsapp" -Description "WhatsApp messaging app"
    
    # Media & Utilities
    Write-Host "`n=== MEDIA & UTILITIES ===" -ForegroundColor Magenta
    Request-InstallSoftware -SoftwareName "VLC Media Player" -WingetID "VideoLAN.VLC" -ChocoPackage "vlc" -Description "Multimedia player"
    Request-InstallSoftware -SoftwareName "Everything" -WingetID "voidtools.Everything" -ChocoPackage "everything" -Description "Fast file search tool"
    Request-InstallSoftware -SoftwareName "TreeSize Free" -WingetID "JAMSoftware.TreeSize.Free" -ChocoPackage "treesizefree" -Description "Disk space analyzer"
}

function Install-WorkModeApps {
    Write-Host "`n--- WORK MODE SOFTWARE INSTALLATION ---" -ForegroundColor Cyan
    
    # Essential work tools - automatic installation
    $workApps = @(
        @{ Name = "Office 365 Enterprise"; WingetID = "Microsoft.Office"; ChocoPackage = "office365business" },
        @{ Name = "Dell Command Update"; WingetID = "Dell.CommandUpdate"; ChocoPackage = "DellCommandUpdate" },
        @{ Name = "Sysinternals Suite"; WingetID = "Microsoft.Sysinternals"; ChocoPackage = "sysinternals" }
    )
    
    foreach ($app in $workApps) {
        Write-Host "Installing $($app.Name)..." -ForegroundColor Yellow
        Install-Software -SoftwareName $app.Name -WingetID $app.WingetID -ChocoPackage $app.ChocoPackage -Silent $true
    }
}

function Remove-WindowsBloatware {
    Write-DetailedLog -Message "Removing Windows bloatware applications..." -Level "OPERATION" -Component "SOFTWARE"
    
    # List of built-in apps to remove
    $appsToRemove = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingFinance",
        "Microsoft.BingNews", 
        "Microsoft.BingSports",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.NetworkSpeedTest",
        "Microsoft.News",
        "Microsoft.Office.Lens",
        "Microsoft.Office.OneNote",
        "Microsoft.Office.Sway",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.RemoteDesktop",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.Whiteboard",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )

    foreach ($app in $appsToRemove) {
        try {
            $package = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
            if ($package) {
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                Write-DetailedLog -Message "Removed app: $app" -Level "SUCCESS" -Component "SOFTWARE"
                Write-Host "Removed app: $app" -ForegroundColor Yellow
            }
        } catch {
            Write-DetailedLog -Message "Failed to remove app $app`: $($_.Exception.Message)" -Level "WARNING" -Component "SOFTWARE"
        }
    }
    
    # Remove Microsoft Teams if installed
    Write-DetailedLog -Message "Removing Microsoft Teams..." -Level "OPERATION" -Component "SOFTWARE"
    Get-AppxPackage *Teams* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -online | Where-Object {$_.PackageName -like "*Teams*"} | Remove-AppxProvisionedPackage -online -ErrorAction SilentlyContinue
    
    # Uninstall Windows Web Experience Pack (Windows 11)
    try {
        winget uninstall "windows web experience pack" --force --accept-source-agreements 2>$null
        Write-DetailedLog -Message "Windows Web Experience Pack removed" -Level "SUCCESS" -Component "SOFTWARE"
    } catch {
        Write-DetailedLog -Message "Windows Web Experience Pack not found or already removed" -Level "INFO" -Component "SOFTWARE"
    }
}

function Install-PowerShellModules {
    Write-DetailedLog -Message "Installing essential PowerShell modules..." -Level "OPERATION" -Component "SOFTWARE"
    
    $modules = @("PSReadLine", "PSWindowsUpdate", "ImportExcel")
    
    try {
        Install-Module -Name $modules -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        Write-DetailedLog -Message "PowerShell modules installed successfully" -Level "SUCCESS" -Component "SOFTWARE"
        Write-Host "PowerShell modules installed successfully" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Error installing PowerShell modules: $($_.Exception.Message)" -Level "ERROR" -Component "SOFTWARE"
        Write-Host "Error installing PowerShell modules: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Install-ChocolateyIfNeeded {
    # Check if Chocolatey is installed, if not install it
    if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $env:PATH = [Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH","User")
            Write-Host "Chocolatey installed successfully" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Failed to install Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Chocolatey is already installed" -ForegroundColor Green
        return $true
    }
}
