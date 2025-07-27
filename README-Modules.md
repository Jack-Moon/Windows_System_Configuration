# Windows Configuration Modules

Nowoczesny modularny system konfiguracji Windows z funkcjami kopii zapasowej i przywracania.

## Struktura Modułów

### 📋 Główny Moduł
- **WindowsConfig.psd1** - Manifest modułu
- **WindowsConfig.psm1** - Główny plik modułu

### 🔧 Moduły Funkcjonalne

#### WindowsConfig.Logging.psm1
Centralny system logowania dla wszystkich operacji konfiguracji.

**Funkcje:**
- `Initialize-LoggingSystem` - Inicjalizuje system logowania
- `Write-DetailedLog` - Zapisuje szczegółowe logi z różnymi poziomami
- `Start-OperationLog` - Rozpoczyna logowanie operacji
- `Stop-OperationLog` - Kończy logowanie operacji

**Przykład użycia:**
```powershell
$logPath = Initialize-LoggingSystem -BackupBasePath "C:\Backup"
Write-DetailedLog -Message "Rozpoczynam konfigurację" -Level "INFO" -Component "MAIN"
```

#### WindowsConfig.Backup.psm1
System kopii zapasowej i przywracania konfiguracji systemu.

**Funkcje:**
- `New-SystemBackup` - Tworzy kopię zapasową systemu
- `Start-SystemRollback` - Rozpoczyna proces przywracania
- `Find-AvailableBackups` - Znajduje dostępne kopie zapasowe
- `Get-BackupManifest` - Pobiera informacje o kopii zapasowej

**Przykład użycia:**
```powershell
$backupPath = New-SystemBackup -BackupBasePath "C:\Backup" -BackupReason "Przed aktualizacją"
Start-SystemRollback -BackupBasePath "C:\Backup"
```

#### WindowsConfig.Services.psm1
Bezpieczne zarządzanie usługami Windows z funkcją kopii zapasowej.

**Funkcje:**
- `Disable-WindowsService` - Bezpiecznie wyłącza usługę
- `Enable-WindowsService` - Włącza usługę
- `Get-ServiceBackup` - Tworzy kopię zapasową usług
- `Restore-ServicesFromBackup` - Przywraca usługi z kopii zapasowej
- `Disable-UnnecessaryServices` - Wyłącza niepotrzebne usługi

**Przykład użycia:**
```powershell
Disable-WindowsService -ServiceName "Fax" -Description "Usługa faksów - rzadko używana"
Disable-UnnecessaryServices -DisableSearch -DisableSysMain
```

#### WindowsConfig.Registry.psm1
Bezpieczne modyfikacje rejestru Windows.

**Funkcje:**
- `Set-RegistryValue` - Bezpiecznie ustawia wartość rejestru
- `Set-PrivacySettings` - Konfiguruje ustawienia prywatności
- `Set-PerformanceSettings` - Optymalizuje wydajność
- `Set-UICustomizations` - Personalizuje interfejs użytkownika
- `Set-SecuritySettings` - Wzmacnia bezpieczeństwo

**Przykład użycia:**
```powershell
Set-RegistryValue -Path "HKEY_CURRENT_USER\Software\Test" -Name "Value1" -Type "REG_DWORD" -Value "1"
Set-PrivacySettings
Set-PerformanceSettings
```

#### WindowsConfig.Software.psm1
Automatyczna instalacja i zarządzanie oprogramowaniem.

**Funkcje:**
- `Install-Software` - Instaluje oprogramowanie przez Winget/Chocolatey
- `Request-InstallSoftware` - Pyta użytkownika o instalację
- `Install-EssentialSoftware` - Instaluje podstawowe aplikacje
- `Install-HomeModeApps` - Instaluje aplikacje dla trybu domowego
- `Install-WorkModeApps` - Instaluje aplikacje dla trybu pracy
- `Remove-WindowsBloatware` - Usuwa niepotrzebne aplikacje Windows
- `Install-PowerShellModules` - Instaluje moduły PowerShell

**Przykład użycia:**
```powershell
Install-Software -SoftwareName "7-Zip" -WingetID "7zip.7zip" -ChocoPackage "7zip"
Install-EssentialSoftware
Remove-WindowsBloatware
```

#### WindowsConfig.Network.psm1
Konfiguracja i optymalizacja sieci.

**Funkcje:**
- `Set-NetworkOptimizations` - Optymalizuje ustawienia sieciowe
- `Enable-RemoteDesktop` - Włącza Pulpit Zdalny
- `Set-DNSServers` - Ustawia serwery DNS
- `Disable-IPv6` - Wyłącza IPv6
- `Set-FirewallRules` - Konfiguruje reguły zapory

**Przykład użycia:**
```powershell
Enable-RemoteDesktop
Set-DNSServers -PrimaryDNS "1.1.1.1" -SecondaryDNS "1.0.0.1"
Set-NetworkOptimizations
```

#### WindowsConfig.System.psm1
Podstawowa konfiguracja systemu i narzędzia.

**Funkcje:**
- `Test-AdministratorPrivileges` - Sprawdza uprawnienia administratora
- `Set-ExecutionPolicyForScript` - Ustawia politykę wykonywania
- `Set-PowerPlan` - Ustawia plan zasilania
- `Set-ComputerNameFromSerial` - Ustawia nazwę komputera z numeru seryjnego
- `Restart-WindowsExplorer` - Restartuje Eksplorator Windows
- `Set-UserAccountSettings` - Konfiguruje konta użytkowników
- `Get-SystemInfo` - Zbiera informacje o systemie
- `Clear-TemporaryFiles` - Czyści pliki tymczasowe

**Przykład użycia:**
```powershell
if (Test-AdministratorPrivileges) {
    Set-PowerPlan -PowerPlan "High Performance"
    Set-ComputerNameFromSerial
    Clear-TemporaryFiles
}
```

## Używanie Modułów

### Importowanie Głównego Modułu
```powershell
Import-Module ".\modules\WindowsConfig.psd1" -Force
```

### Przykładowy Workflow
```powershell
# 1. Sprawdź uprawnienia
if (-not (Test-AdministratorPrivileges)) {
    exit 1
}

# 2. Inicjalizuj logowanie
$logPath = Initialize-LoggingSystem -BackupBasePath "C:\Backup"

# 3. Utwórz kopię zapasową
$backupPath = New-SystemBackup -BackupBasePath "C:\Backup"

# 4. Wykonaj konfigurację
Set-PrivacySettings
Set-PerformanceSettings
Disable-UnnecessaryServices
Install-EssentialSoftware

# 5. W razie potrzeby przywróć system
# Start-SystemRollback -BackupBasePath "C:\Backup"
```

## Zalety Modularnej Architektury

### ✅ Korzyści
- **Modularność** - Każda funkcjonalność w osobnym module
- **Łatwość utrzymania** - Zmiany w jednym module nie wpływają na inne
- **Testowalność** - Każdy moduł można testować niezależnie
- **Rozszerzalność** - Łatwe dodawanie nowych funkcji
- **Ponowne użycie** - Moduły można używać w innych projektach
- **Bezpieczeństwo** - Wbudowane kopie zapasowe i rollback
- **Logging** - Szczegółowe logowanie wszystkich operacji

### 📦 Struktura Plików
```
Windows_System_Configuration/
├── WindowsConfigurationMain.ps1       # Główny skrypt
├── modules/                           # Katalog modułów
│   ├── WindowsConfig.psd1            # Manifest modułu
│   ├── WindowsConfig.psm1            # Główny moduł
│   ├── WindowsConfig.Logging.psm1    # Moduł logowania
│   ├── WindowsConfig.Backup.psm1     # Moduł kopii zapasowych
│   ├── WindowsConfig.Services.psm1   # Moduł usług
│   ├── WindowsConfig.Registry.psm1   # Moduł rejestru
│   ├── WindowsConfig.Software.psm1   # Moduł oprogramowania
│   ├── WindowsConfig.Network.psm1    # Moduł sieci
│   └── WindowsConfig.System.psm1     # Moduł systemu
└── README-Modules.md                 # Ta dokumentacja
```

## Uruchamianie

### Tryb Domowy
```powershell
.\WindowsConfigurationMain.ps1 -Mode home
```

### Tryb Pracy
```powershell
.\WindowsConfigurationMain.ps1 -Mode work
```

### Rollback
```powershell
.\WindowsConfigurationMain.ps1 -Rollback
```

## Wymagania

- PowerShell 5.1 lub nowszy
- Uprawnienia administratora
- Windows 10/11
- Połączenie z internetem (dla instalacji oprogramowania)

## Bezpieczeństwo

- Automatyczne tworzenie kopii zapasowych przed każdą operacją
- Szczegółowe logowanie wszystkich zmian
- Możliwość pełnego rollback-u
- Walidacja uprawnień i parametrów
- Bezpieczne manipulacje rejestrem
