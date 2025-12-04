# install-qemu-guest-agent.ps1
# Installs VirtIO Guest Tools (includes QEMU Guest Agent and drivers)

$ErrorActionPreference = "Stop"

# Define the installer executable
$tools = 'virtio-win-guest-tools.exe'

Write-Host "Installing VirtIO Guest Tools..."

# Find the VirtIO CD drive
$virtioDrive = $null
$cdDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 5 }

foreach ($drive in $cdDrives) {
    $driveLetter = $drive.DeviceID
    $installerPath = Join-Path $driveLetter $tools
    
    if (Test-Path $installerPath) {
        $virtioDrive = $driveLetter
        Write-Host "Found VirtIO drive at $virtioDrive"
        Write-Host "Installer found at: $installerPath"
        break
    }
}

if ($virtioDrive) {
    $installerPath = Join-Path $virtioDrive $tools
    
    Write-Host "Installing VirtIO Guest Tools from: $installerPath"
    
    # Install silently with /passive (shows progress) or /quiet (completely silent)
    # /norestart prevents automatic restart
    $arguments = "/install /passive /norestart"
    
    $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "VirtIO Guest Tools installed successfully"
        
        # Verify and start QEMU Guest Agent service
        $service = Get-Service -Name "QEMU-GA" -ErrorAction SilentlyContinue
        
        if ($service) {
            if ($service.Status -ne 'Running') {
                Start-Service -Name "QEMU-GA"
                Write-Host "QEMU Guest Agent service started"
            }
            
            Set-Service -Name "QEMU-GA" -StartupType Automatic
            Write-Host "QEMU Guest Agent service set to automatic startup"
        } else {
            Write-Host "Warning: QEMU-GA service not found. It may require a restart to be available."
        }
        
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "VirtIO Guest Tools installed successfully (restart required)"
        Write-Host "Exit code: 3010 - Restart pending"
    } else {
        Write-Host "Installation failed with exit code: $($process.ExitCode)"
        exit $process.ExitCode
    }
    
} else {
    Write-Host "ERROR: VirtIO ISO not found or $tools not present on any CD drive."
    Write-Host "Please ensure the virtio-win ISO is attached as a CD drive."
    
    # List available CD drives for debugging
    Write-Host "`nAvailable CD drives:"
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 5 } | ForEach-Object {
        Write-Host "  $($_.DeviceID) - $($_.VolumeName)"
    }
    
    exit 1
}

Write-Host "`nVirtIO Guest Tools installation complete"