<#
    .DESCRIPTION
    Prepares Windows Server 2025 for template creation with optimizations and best practices.
#>

$ErrorActionPreference = 'Continue'

# Set network connection profile to Private mode
Write-Output 'Setting the network connection profiles to Private...'
$connectionProfile = Get-NetConnectionProfile
While ($connectionProfile.Name -eq 'Identifying...') {
    Start-Sleep -Seconds 10
    $connectionProfile = Get-NetConnectionProfile
}
Set-NetConnectionProfile -Name $connectionProfile.Name -NetworkCategory Private

# Configure Windows Remote Management (consolidated all WinRM settings)
Write-Output 'Configuring Windows Remote Management...'
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true";MaxConcurrentOperationsPerUser="4294967295"}'
winrm set winrm/config/service/auth '@{Basic="true";CredSSP="true"}'
winrm set winrm/config/client/auth '@{Basic="true";CredSSP="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'

# Configure Windows Firewall for WinRM
Write-Output 'Configuring Windows Firewall for remote management...'
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow

# Disable IPv6 (optional - if not used in your environment)
Write-Output 'Disabling IPv6 components (optional)...'
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xff -PropertyType DWord -Force | Out-Null

# Set Power Plan to High Performance
Write-Output 'Setting power plan to High Performance...'
try {
    $highPerf = powercfg -l | Where-Object { $_ -match "High performance" }
    if ($highPerf -match "([a-f0-9-]{36})") {
        powercfg -setactive $matches[1]
    }
    # Disable monitor and disk sleep
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    powercfg -change -standby-timeout-ac 0
    powercfg -change -hibernate-timeout-ac 0
} catch {
    Write-Warning "Could not set power plan: $_"
}

# Disable hibernation to save disk space
Write-Output 'Disabling hibernation...'
powercfg -h off

# Set timezone to UTC (adjust as needed)
Write-Output 'Setting timezone to UTC...'
Set-TimeZone -Id "UTC"

# Enable Remote Desktop
Write-Output 'Enabling Remote Desktop...'
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable NLA requirement for RDP (optional - less secure but more compatible)
# Uncomment if needed:
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

# Configure Windows Update to not auto-reboot
Write-Output 'Configuring Windows Update settings...'
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 3 -Type DWord

# Disable Server Manager auto-start
Write-Output 'Disabling Server Manager auto-start...'
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -ErrorAction SilentlyContinue

# Disable Windows Defender real-time protection (optional - for performance)
# Only do this if you plan to install another AV solution
# Write-Output 'Disabling Windows Defender real-time protection...'
# Set-MpPreference -DisableRealtimeMonitoring $true

# Configure Windows Event Logs (increase size)
Write-Output 'Configuring Event Log sizes...'
$logs = @('Application', 'System', 'Security')
foreach ($log in $logs) {
    wevtutil sl $log /ms:524288000  # 500MB
}

# Disable unnecessary services
Write-Output 'Disabling unnecessary services...'
$servicesToDisable = @(
    'MapsBroker',           # Downloaded Maps Manager
    'lfsvc',                # Geolocation Service
    'WSearch',              # Windows Search (if not needed)
    'XblAuthManager',       # Xbox Live Auth Manager
    'XblGameSave',          # Xbox Live Game Save
    'XboxNetApiSvc',        # Xbox Live Networking Service
    'XboxGipSvc'            # Xbox Accessory Management Service
)

foreach ($service in $servicesToDisable) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Output "  Disabling service: $service"
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# Set execution policy for scripts
Write-Output 'Setting PowerShell execution policy...'
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Enable CredSSP (if needed for delegation scenarios)
# Enable-WSManCredSSP -Role Server -Force

# # Compact OS (optional - reduces disk footprint)
# Write-Output 'Compacting OS (this may take several minutes)...'
# Compact.exe /CompactOS:always

# Reset autologon count
Write-Output 'Resetting autologon count...'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

Write-Output 'Template preparation complete!'
Write-Output 'Ready for Windows Updates.'

# # Final restart
# Write-Output 'Restarting computer...'
# Restart-Computer -Force