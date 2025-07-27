# ===================================================================
# Windows Configuration - Network Module
# Purpose: Network configuration and optimization
# ===================================================================

# Import required modules
Import-Module "$PSScriptRoot\WindowsConfig.Logging.psm1" -Force

# Export module functions
Export-ModuleMember -Function @(
    'Set-NetworkOptimizations',
    'Enable-RemoteDesktop',
    'Set-DNSServers',
    'Disable-IPv6',
    'Set-FirewallRules'
)

function Set-NetworkOptimizations {
    Write-DetailedLog -Message "Optimizing network settings..." -Level "OPERATION" -Component "NETWORK"
    
    # Disable Teredo tunneling (can be security risk)
    try {
        netsh interface teredo set state disabled | Out-Null
        Write-DetailedLog -Message "Teredo tunneling disabled" -Level "SUCCESS" -Component "NETWORK"
    } catch {
        Write-DetailedLog -Message "Failed to disable Teredo: $($_.Exception.Message)" -Level "WARNING" -Component "NETWORK"
    }
    
    Write-DetailedLog -Message "Network optimizations completed" -Level "SUCCESS" -Component "NETWORK"
}

function Enable-RemoteDesktop {
    Write-DetailedLog -Message "Enabling Remote Desktop..." -Level "OPERATION" -Component "NETWORK"
    
    try {
        # Enable Remote Desktop connections (Registry method)
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f | Out-Null

        # Enable Remote Desktop connections (PowerShell method)
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

        # Enable Remote Desktop firewall rules
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        
        Write-DetailedLog -Message "Remote Desktop enabled successfully" -Level "SUCCESS" -Component "NETWORK"
        Write-Host "✓ Remote Desktop enabled" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to enable Remote Desktop: $($_.Exception.Message)" -Level "ERROR" -Component "NETWORK"
        Write-Host "✗ Failed to enable Remote Desktop" -ForegroundColor Red
    }
}

function Set-DNSServers {
    param(
        [Parameter(Mandatory=$false)]
        [string]$PrimaryDNS = "1.1.1.1",
        
        [Parameter(Mandatory=$false)]
        [string]$SecondaryDNS = "1.0.0.1"
    )
    
    Write-DetailedLog -Message "Setting DNS servers to $PrimaryDNS and $SecondaryDNS" -Level "OPERATION" -Component "NETWORK"
    
    try {
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $PrimaryDNS, $SecondaryDNS
                Write-DetailedLog -Message "DNS set for adapter: $($adapter.Name)" -Level "SUCCESS" -Component "NETWORK"
            } catch {
                Write-DetailedLog -Message "Failed to set DNS for adapter $($adapter.Name): $($_.Exception.Message)" -Level "WARNING" -Component "NETWORK"
            }
        }
        Write-Host "✓ DNS set to Cloudflare ($PrimaryDNS, $SecondaryDNS)" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Could not set DNS servers: $($_.Exception.Message)" -Level "ERROR" -Component "NETWORK"
        Write-Host "✗ Could not set DNS servers" -ForegroundColor Red
    }
}

function Disable-IPv6 {
    Write-DetailedLog -Message "Disabling IPv6 on all network adapters..." -Level "OPERATION" -Component "NETWORK"
    
    try {
        Disable-NetAdapterBinding -Name * -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-DetailedLog -Message "IPv6 disabled on all adapters" -Level "SUCCESS" -Component "NETWORK"
        Write-Host "✓ IPv6 disabled on all network adapters" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to disable IPv6: $($_.Exception.Message)" -Level "WARNING" -Component "NETWORK"
        Write-Host "⚠ Failed to disable IPv6" -ForegroundColor Yellow
    }
}

function Set-FirewallRules {
    Write-DetailedLog -Message "Configuring firewall rules..." -Level "OPERATION" -Component "NETWORK"
    
    try {
        # Enable ICMP ping responses for local subnet
        $existingRule = Get-NetFirewallRule -DisplayName "!!! ICMP PING" -ErrorAction SilentlyContinue
        if (-not $existingRule) {
            New-NetFirewallRule -DisplayName "!!! ICMP PING" -Direction Inbound -Protocol ICMPv4 -RemoteAddress LocalSubnet -Action Allow | Out-Null
            Write-DetailedLog -Message "ICMP ping rule created" -Level "SUCCESS" -Component "NETWORK"
        } else {
            Write-DetailedLog -Message "ICMP ping rule already exists" -Level "INFO" -Component "NETWORK"
        }
        
        Write-Host "✓ Firewall rules configured" -ForegroundColor Green
    } catch {
        Write-DetailedLog -Message "Failed to configure firewall rules: $($_.Exception.Message)" -Level "ERROR" -Component "NETWORK"
        Write-Host "✗ Failed to configure firewall rules" -ForegroundColor Red
    }
}
