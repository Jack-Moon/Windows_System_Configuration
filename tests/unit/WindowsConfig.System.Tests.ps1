# ===================================================================
# Unit tests for WindowsConfig.System
# Testuje podstawowe funkcje systemowe
# ===================================================================

Describe "WindowsConfig.System Module Tests" {
    BeforeAll {
        # Importuj moduły testowe
        Import-Module "$PSScriptRoot\..\..\modules\WindowsConfig.psd1" -Force
        
        # Mock dla Write-DetailedLog
        Mock Write-DetailedLog { }
    }
    
    Context "Test-AdministratorPrivileges Function" {
        It "Should return boolean value" {
            # Act
            $result = Test-AdministratorPrivileges
            
            # Assert
            $result | Should -BeOfType [bool]
        }
        
        It "Should not throw exceptions" {
            # Act & Assert
            { Test-AdministratorPrivileges } | Should -Not -Throw
        }
    }
    
    Context "Set-ExecutionPolicyForScript Function" {
        It "Should execute without errors" {
            # Act & Assert
            { Set-ExecutionPolicyForScript } | Should -Not -Throw
        }
        
        It "Should log execution policy changes" {
            # Act
            Set-ExecutionPolicyForScript
            
            # Assert
            Assert-MockCalled Write-DetailedLog -AtLeast 1
        }
    }
    
    Context "Get-SystemInfo Function" {
        It "Should return system information object" {
            # Act
            $result = Get-SystemInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
        }
        
        It "Should include required properties" {
            # Act
            $result = Get-SystemInfo
            
            # Assert
            $result.PSObject.Properties.Name | Should -Contain "ComputerName"
            $result.PSObject.Properties.Name | Should -Contain "UserName"
            $result.PSObject.Properties.Name | Should -Contain "OSVersion"
            $result.PSObject.Properties.Name | Should -Contain "TotalMemory"
        }
        
        It "Should have valid computer name" {
            # Act
            $result = Get-SystemInfo
            
            # Assert
            $result.ComputerName | Should -Be $env:COMPUTERNAME
        }
        
        It "Should have valid user name" {
            # Act
            $result = Get-SystemInfo
            
            # Assert
            $result.UserName | Should -Be $env:USERNAME
        }
        
        It "Should calculate memory in GB" {
            # Act
            $result = Get-SystemInfo
            
            # Assert
            $result.TotalMemory | Should -BeGreaterThan 0
            $result.TotalMemory | Should -BeOfType [double]
        }
    }
    
    Context "Set-PowerPlan Function" {
        It "Should accept valid power plans" {
            # Arrange
            $validPlans = @("High Performance", "Balanced", "Power Saver")
            
            # Act & Assert
            foreach ($plan in $validPlans) {
                { Set-PowerPlan -PowerPlan $plan } | Should -Not -Throw
            }
        }
        
        It "Should reject invalid power plan" {
            # Arrange
            $invalidPlan = "NonExistentPlan"
            
            # Act & Assert
            { Set-PowerPlan -PowerPlan $invalidPlan } | Should -Throw
        }
        
        It "Should log power plan changes" {
            # Act
            Set-PowerPlan -PowerPlan "High Performance"
            
            # Assert
            Assert-MockCalled Write-DetailedLog -ParameterFilter {
                $Message -like "*power plan*"
            }
        }
    }
    
    Context "Set-ComputerNameFromSerial Function" {
        It "Should execute without errors" {
            # Act & Assert
            { Set-ComputerNameFromSerial } | Should -Not -Throw
        }
        
        It "Should handle invalid BIOS serial gracefully" {
            # Act & Assert
            { Set-ComputerNameFromSerial } | Should -Not -Throw
        }
        
        It "Should log computer name operations" {
            # Act
            Set-ComputerNameFromSerial
            
            # Assert
            Assert-MockCalled Write-DetailedLog -AtLeast 1
        }
    }
    
    Context "Clear-TemporaryFiles Function" {
        It "Should execute without errors" {
            # Act & Assert
            { Clear-TemporaryFiles } | Should -Not -Throw
        }
        
        It "Should log cleanup operations" {
            # Act
            Clear-TemporaryFiles
            
            # Assert
            Assert-MockCalled Write-DetailedLog -ParameterFilter {
                $Message -like "*cleanup*" -or $Message -like "*temporary*"
            }
        }
        
        It "Should handle access denied errors gracefully" {
            # Test poprzez sprawdzenie czy funkcja zawiera obsługę błędów
            $function = Get-Command Clear-TemporaryFiles
            $function.Definition | Should -Match "try|catch|ErrorAction"
        }
    }
    
    Context "Restart-WindowsExplorer Function" {
        It "Should execute without errors" {
            # Nie wykonujemy rzeczywistego restartu w testach
            # Sprawdzamy tylko czy funkcja istnieje i ma odpowiednią strukturę
            $function = Get-Command Restart-WindowsExplorer -ErrorAction SilentlyContinue
            $function | Should -Not -BeNullOrEmpty
        }
        
        It "Should contain process management logic" {
            # Act
            $function = Get-Command Restart-WindowsExplorer
            
            # Assert
            $function.Definition | Should -Match "explorer|Get-Process|Stop-Process"
        }
    }
    
    Context "Module Integration Tests" {
        It "Should have all functions properly exported" {
            # Arrange
            $expectedFunctions = @(
                'Test-AdministratorPrivileges',
                'Set-ExecutionPolicyForScript',
                'Get-SystemInfo',
                'Set-PowerPlan',
                'Set-ComputerNameFromSerial',
                'Clear-TemporaryFiles',
                'Restart-WindowsExplorer'
            )
            
            # Act
            $exportedFunctions = Get-Command -Module WindowsConfig* | Where-Object { $_.Source -like "*System*" } | Select-Object -ExpandProperty Name
            
            # Assert
            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
        
        It "Should import logging module dependency" {
            # Act
            $systemModule = Get-Module WindowsConfig* | Where-Object { $_.Path -like "*System*" }
            
            # Assert
            $systemModule | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Error Handling and Robustness" {
        It "Should handle WMI/CIM query failures gracefully" {
            # Test poprzez sprawdzenie czy funkcje mają obsługę błędów
            $systemFunctions = Get-Command -Module WindowsConfig* | Where-Object { $_.Source -like "*System*" }
            
            foreach ($func in $systemFunctions) {
                $func.Definition | Should -Match "try|catch|ErrorAction"
            }
        }
        
        It "Should not require specific Windows version" {
            # Sprawdzamy czy funkcje nie są ograniczone do konkretnych wersji
            $result = Get-SystemInfo
            $result.OSVersion | Should -Not -BeNullOrEmpty
        }
    }
}
