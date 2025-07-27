# ===================================================================
# Windows Configuration Module - Main Module File
# Purpose: Main module that re-exports all functions from sub-modules
# ===================================================================

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Import all sub-modules
$ModulePath = $PSScriptRoot

# Import modules in dependency order
Import-Module "$ModulePath\WindowsConfig.Logging.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.System.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.Registry.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.Services.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.Network.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.Software.psm1" -Force
Import-Module "$ModulePath\WindowsConfig.Backup.psm1" -Force

# Export all functions (this is handled by the manifest file)
# The manifest file controls which functions are exported
