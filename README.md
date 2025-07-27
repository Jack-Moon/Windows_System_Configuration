# Windows System Configuration - Modular Version 2.0

Kompletny, modularny system automatycznej konfiguracji Windows z funkcjami kopii zapasowej i przywracania.

## 🚀 Nowe w Wersji 2.0

### ✨ Modularyzacja
- **7 wyspecjalizowanych modułów** zamiast jednego monolitycznego skryptu
- **Łatwość utrzymania** - każda funkcjonalność w osobnym module
- **Rozszerzalność** - łatwe dodawanie nowych funkcji
- **Testowalność** - każdy moduł można testować niezależnie

### 🛡️ Zaawansowane Bezpieczeństwo
- **Automatyczne kopie zapasowe** przed każdą operacją
- **Pełny rollback** wszystkich zmian
- **Szczegółowe logowanie** wszystkich operacji
- **Walidacja uprawnień** i parametrów

### 📦 Struktura Modułów

```
modules/
├── WindowsConfig.psd1         # Manifest głównego modułu
├── WindowsConfig.psm1         # Główny moduł
├── WindowsConfig.Logging.psm1  # System logowania
├── WindowsConfig.Backup.psm1   # Kopie zapasowe i rollback
├── WindowsConfig.Services.psm1 # Zarządzanie usługami
├── WindowsConfig.Registry.psm1 # Modyfikacje rejestru
├── WindowsConfig.Software.psm1 # Instalacja oprogramowania  
├── WindowsConfig.Network.psm1  # Konfiguracja sieci
└── WindowsConfig.System.psm1   # Podstawowa konfiguracja systemu
```

## 🎯 Funkcjonalności

### 🔧 Konfiguracja Systemu
- **Zarządzanie usługami** z kopią zapasową
- **Optymalizacja wydajności** systemu
- **Konfiguracja zasilania** (High Performance)
- **Automatyczne nazywanie** komputera z numeru seryjnego BIOS

### 🔒 Prywatność i Bezpieczeństwo
- **Wyłączenie telemetrii** Windows
- **Konfiguracja UAC** z inteligentnym balansem
- **Wyłączenie niepotrzebnych funkcji** Windows
- **Wzmocnienie bezpieczeństwa** systemu

### 🎨 Personalizacja UI
- **Klasyczne menu kontekstowe** Windows 11
- **Ukrycie niepotrzebnych ikon** paska zadań
- **Optymalizacja Eksploratora** plików
- **Wyłączenie Focus Assist** i powiadomień

### 🌐 Konfiguracja Sieci
- **Pulpit zdalny** z konfiguracją zapory
- **DNS Cloudflare** (1.1.1.1) dla lepszej wydajności
- **Optymalizacja ustawień** sieciowych
- **Reguły zapory** dla ICMP ping

### 💻 Instalacja Oprogramowania
- **Tryb domowy** - interaktywny wybór aplikacji
- **Tryb pracy** - automatyczna instalacja niezbędnych narzędzi
- **Wsparcie Winget i Chocolatey** jako fallback
- **Usuwanie bloatware** Windows

## 🚀 Szybki Start

### Wymagania
- Windows 10/11
- PowerShell 5.1+
- Uprawnienia administratora
- Połączenie z internetem

### Instalacja i Uruchomienie

1. **Pobranie** (clone lub download ZIP)
```powershell
git clone https://github.com/your-repo/Windows_System_Configuration.git
cd Windows_System_Configuration
```

2. **Uruchomienie w trybie domowym**
```powershell
.\WindowsConfigurationMain.ps1 -Mode home
```

3. **Uruchomienie w trybie pracy**
```powershell
.\WindowsConfigurationMain.ps1 -Mode work
```

### 🧪 Testowanie Modułów

Przed pierwszym użyciem możesz przetestować moduły:

```powershell
# Test wszystkich modułów
.\TestModules.ps1 -TestModule all

# Test konkretnego modułu
.\TestModules.ps1 -TestModule logging
.\TestModules.ps1 -TestModule system
.\TestModules.ps1 -TestModule registry
```

## 📋 Tryby Działania

### 🏠 Tryb Domowy (`-Mode home`)
- **Interaktywny wybór** oprogramowania
- **Pełna personalizacja** systemu
- **Pytania o ryzykowne** operacje (wyłączenie usług)
- **Szeroki wybór** aplikacji development/media/gaming

### 🏢 Tryb Pracy (`-Mode work`)  
- **Automatyczna instalacja** podstawowych narzędzi
- **Konserwatywne ustawienia** usług
- **Instalacja Office 365** i narzędzi IT
- **Konfiguracja dla środowiska** korporacyjnego

## 🛠️ Zaawansowane Opcje

### Parametry
```powershell
.\WindowsConfigurationMain.ps1 -Mode home -BackupBasePath "D:\Backups"
```

### Rollback
```powershell
# Przywrócenie systemu do stanu sprzed konfiguracji
.\WindowsConfigurationMain.ps1 -Rollback
```

### Kopia zapasowa oprogramowania
```powershell
.\WindowsConfigurationMain.ps1 -Mode home -BackupSoftware
```

## 📊 Co robi skrypt?

### ✅ Bezpieczeństwo
- ✓ Sprawdzenie uprawnień administratora
- ✓ Utworzenie kopii zapasowej systemu
- ✓ Wyłączenie telemetrii Windows
- ✓ Konfiguracja UAC
- ✓ Wyłączenie AutoRun
- ✓ Wzmocnienie Windows Defender

### ⚡ Wydajność
- ✓ Plan zasilania High Performance
- ✓ Wyłączenie niepotrzebnych usług
- ✓ Optymalizacja efektów wizualnych
- ✓ Konfiguracja pamięci wirtualnej
- ✓ Wyłączenie indexowania (opcjonalne)

### 🎨 UI/UX
- ✓ Klasyczne menu kontekstowe
- ✓ Ukrycie przycisku Teams/Cortana/Search
- ✓ Konfiguracja Eksploratora plików
- ✓ Wyłączenie powiadomień
- ✓ Konfiguracja paska zadań

### 🌐 Sieć
- ✓ Włączenie Pulpitu Zdalnego
- ✓ DNS Cloudflare
- ✓ Reguły zapory
- ✓ Wyłączenie IPv6 (opcjonalne)

### 💻 Oprogramowanie
- ✓ Instalacja podstawowych narzędzi
- ✓ Wybór aplikacji (tryb home)
- ✓ Usunięcie bloatware
- ✓ Konfiguracja package managerów

## 🔄 System Rollback

Każde uruchomienie skryptu tworzy pełną kopię zapasową:

### Lokalizacja kopii zapasowych
```
%USERPROFILE%\Documents\WindowsConfigBackups\
├── SystemBackup_2025-01-27_14-30-45\
│   ├── BACKUP_MANIFEST.json          # Informacje o kopii
│   ├── ROLLBACK_SYSTEM.ps1           # Skrypt rollback
│   ├── ServicesBackup.csv            # Kopia usług
│   ├── WindowsFeaturesBackup.csv     # Kopia funkcji Windows
│   └── Registry_*.reg                # Kopie kluczy rejestru
└── WindowsConfigScript_v2_log_2025-01-27_14-30-45.log
```

### Przywracanie
```powershell
# Automatyczny rollback
.\WindowsConfigurationMain.ps1 -Rollback

# Lub ręczne uruchomienie
.\path\to\backup\ROLLBACK_SYSTEM.ps1
```

## 🔍 Logowanie

Szczegółowe logi wszystkich operacji:
- **Poziomy logowania**: INFO, WARNING, ERROR, SUCCESS, OPERATION, BACKUP, RESTORE
- **Komponenty**: MAIN, SERVICES, REGISTRY, SOFTWARE, NETWORK, SYSTEM
- **Format**: `[DateTime] [Level] [Component] Message`

Przykład:
```
[2025-01-27 14:30:45] [OPERATION] [SERVICES] Processing service: Fax
[2025-01-27 14:30:45] [SUCCESS] [SERVICES] Service disabled successfully: Fax
[2025-01-27 14:30:46] [INFO] [REGISTRY] Setting registry value: HKEY_CURRENT_USER\Software\...
```

## 🎯 Instalowane Oprogramowanie

### Podstawowe (automatycznie)
- 7-Zip, Notepad++, PowerToys, Windows Terminal

### Tryb Domowy (do wyboru)
- **Development**: VS Code, Git, GitHub Desktop, Python, Docker
- **Network**: Wireshark, PuTTY, WinSCP, OpenVPN
- **Browsers**: Chrome, Firefox
- **Media**: VLC, PotPlayer
- **Utilities**: Everything, TreeSize
- **Communication**: WhatsApp, Messenger

### Tryb Pracy (automatycznie)
- Office 365 Enterprise
- Dell Command Update
- Sysinternals Suite
- Podstawowe narzędzia IT

## 🚨 Bezpieczeństwo

### Mechanizmy Ochrony
1. **Sprawdzenie uprawnień** - wymaga uprawnień administratora
2. **Automatyczny backup** - przed każdą operacją
3. **Walidacja parametrów** - sprawdzanie poprawności danych wejściowych
4. **Szczegółowe logowanie** - śledzenie wszystkich zmian
5. **Możliwość rollback** - pełne przywracanie systemu

### Przed uruchomieniem
- ✅ Utwórz punkt przywracania systemu
- ✅ Sprawdź czy masz kopie zapasowe ważnych danych
- ✅ Przeczytaj dokumentację modułów
- ✅ Przetestuj na maszynie wirtualnej

## 🤝 Współpraca

### Rozwój modułów
Każdy moduł jest niezależny i może być rozwijany oddzielnie:

```powershell
# Dodawanie nowej funkcji do modułu
# 1. Edytuj odpowiedni moduł w modules/
# 2. Dodaj funkcję do Export-ModuleMember
# 3. Zaktualizuj manifest WindowsConfig.psd1
# 4. Dodaj testy w TestModules.ps1
```

### Struktura commitów
- `feat(module): opis nowej funkcjonalności`
- `fix(module): opis poprawki`
- `docs: aktualizacja dokumentacji`
- `test: dodanie/modyfikacja testów`

## 📚 Dokumentacja

- [**README-Modules.md**](README-Modules.md) - Szczegółowa dokumentacja modułów
- **Komentarze w kodzie** - Każda funkcja ma pełną dokumentację
- **Przykłady użycia** - W każdym module i TestModules.ps1

## ⚠️ Ostrzeżenia

- **Administrator required** - Skrypt wymaga uprawnień administratora
- **System restart** - Niektóre zmiany wymagają restartu
- **Testowanie** - Zawsze testuj na maszynie wirtualnej przed produkcją
- **Backup** - Mimo automatycznych kopii zapasowych, utwórz własne

## 📝 Licencja

Ten projekt jest dostępny na licencji MIT. Zobacz plik LICENSE dla szczegółów.

## 🎉 Podziękowania

Dziękujemy wszystkim kontrybutorów i społeczności PowerShell za inspirację i wsparcie.
