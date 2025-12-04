<#
    .DESCRIPTION
    Prepares Windows 11 for VDI template creation with optimizations for virtual desktop performance.
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

# Configure Windows Event Logs (increase size)
Write-Output 'Configuring Event Log sizes...'
$logs = @('Application', 'System', 'Security')
foreach ($log in $logs) {
    wevtutil sl $log /ms:524288000  # 500MB
}

# ============================================
# VDI-SPECIFIC OPTIMIZATIONS
# ============================================

# Disable Windows Defender real-time protection for VDI performance
# Re-enable if using persistent VDI or if security policy requires it
Write-Output 'Disabling Windows Defender real-time protection for VDI...'
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue

# Disable unnecessary visual effects for better VDI performance
Write-Output 'Optimizing visual effects for VDI...'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 0 -Type DWord -Force

# Disable Windows Search indexing (or limit to specific locations)
Write-Output 'Disabling Windows Search indexing...'
Stop-Service "WSearch" -Force -ErrorAction SilentlyContinue
Set-Service "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Superfetch/SysMain (not needed in VDI)
Write-Output 'Disabling Superfetch/SysMain...'
Stop-Service "SysMain" -Force -ErrorAction SilentlyContinue
Set-Service "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Windows Tips and Suggestions
Write-Output 'Disabling Windows tips and suggestions...'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force

# Disable Background Apps
Write-Output 'Disabling background apps...'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force

# Disable Widgets (Windows 11)
Write-Output 'Disabling Windows 11 Widgets...'
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force
# Hide Widgets icon from taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force

# Disable Chat icon on taskbar
Write-Output 'Disabling Chat icon...'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord -Force

# Disable Transparency Effects
Write-Output 'Disabling transparency effects...'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force

# Disable Timeline
Write-Output 'Disabling Timeline...'
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force

# Disable Storage Sense (let admins manage disk space)
Write-Output 'Disabling Storage Sense...'
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense" -Recurse -Force -ErrorAction SilentlyContinue

# Optimize RDP for VDI
Write-Output 'Optimizing RDP settings for VDI...'
# Enable Hardware Graphics Adapter for all RDP Sessions
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "fEnableWddmDriver" -Value 1 -Type DWord -Force
# Set RDP port (default 3389)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value 3389 -Type DWord -Force
# Optimize for bandwidth
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "fQueryUserConfigFromDC" -Value 0 -Type DWord -Force

# Disable unnecessary scheduled tasks for VDI
Write-Output 'Disabling unnecessary scheduled tasks...'
$tasksToDisable = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Autochk\Proxy',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Maintenance\WinSAT',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start'
)

foreach ($task in $tasksToDisable) {
    Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
}

# Disable unnecessary services for VDI
Write-Output 'Disabling unnecessary services for VDI...'
$servicesToDisable = @(
    'DiagTrack',            # Connected User Experiences and Telemetry
    'dmwappushservice',     # WAP Push Message Routing Service
    'MapsBroker',           # Downloaded Maps Manager
    'lfsvc',                # Geolocation Service
    'WSearch',              # Windows Search (already handled above)
    'XblAuthManager',       # Xbox Live Auth Manager
    'XblGameSave',          # Xbox Live Game Save
    'XboxNetApiSvc',        # Xbox Live Networking Service
    'XboxGipSvc',           # Xbox Accessory Management Service
    'SysMain',              # Superfetch (already handled above)
    'TabletInputService',   # Touch Keyboard and Handwriting Panel Service (if not using touch)
    'OneSyncSvc',           # Sync Host Service (if not using Microsoft accounts)
    'WerSvc',               # Windows Error Reporting
    'Spooler'               # Print Spooler (if not printing from VDI)
)

foreach ($service in $servicesToDisable) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Output "  Disabling service: $service"
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# Configure pagefile for VDI (system-managed on C: drive)
Write-Output 'Configuring pagefile for VDI...'
$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
$computersys.AutomaticManagedPagefile = $true
$computersys.Put()

# Disable Action Center notifications
Write-Output 'Disabling Action Center notifications...'
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord -Force

# Set execution policy for scripts
Write-Output 'Setting PowerShell execution policy...'
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Install VMware Tools optimization (if using VMware)
Write-Output 'Configuring VMware optimizations...'
if (Test-Path "$env:ProgramFiles\VMware\VMware Tools\VMwareToolboxCmd.exe") {
    # Disable memory page trimming
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
    
    # Enable time synchronization with host
    & "$env:ProgramFiles\VMware\VMware Tools\VMwareToolboxCmd.exe" timesync enable
    
    # Optimize VMware SVGA driver for VDI
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\vm3dmp" -Name "Start" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

# Do NOT use Compact OS for VDI - it can hurt performance
# Write-Output 'Compacting OS (this may take several minutes)...'
# Compact.exe /CompactOS:always

# Reset autologon count
Write-Output 'Resetting autologon count...'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

Write-Output 'VDI template preparation complete!'
Write-Output 'Ready for Windows Updates.'

# # Final restart
# Write-Output 'Restarting computer...'
# Restart-Computer -Force