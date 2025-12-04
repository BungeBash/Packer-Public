# scripts/cleanup.ps1
<#
    .DESCRIPTION
    Final cleanup before sysprep
#>

$ErrorActionPreference = 'Stop'

Write-Output 'Performing final cleanup...'

# Remove unattend.xml files from all Panther directories
Write-Output 'Removing unattend.xml files...'
$unattendPaths = @(
    "$env:SystemRoot\Panther\*.xml",
    "$env:SystemRoot\Panther\UnattendGC\*.xml",
    "$env:SystemRoot\System32\Sysprep\*.xml",
    "$env:SystemRoot\System32\Sysprep\Panther\*.xml"
)

foreach ($path in $unattendPaths) {
    if (Test-Path $path) {
        Write-Output "  Removing: $path"
        Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
    }
}

# Reset VMware Tools for guest customization
Write-Output 'Resetting VMware Tools for guest customization...'
if (Test-Path "$env:ProgramFiles\VMware\VMware Tools\") {
    # Remove VMware customization state files
    Remove-Item "$env:SystemRoot\System32\Sysprep\state.ini" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\TEMP\vmware-imc\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Clear VMware guest customization logs
    Remove-Item "$env:SystemRoot\TEMP\vmware-*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\System32\Sysprep\Panther\*vmware*" -Force -ErrorAction SilentlyContinue
    
    Write-Output '  VMware Tools reset for customization'
}

# Clear all event logs
Write-Output 'Clearing event logs...'
wevtutil el | ForEach-Object { wevtutil cl $_ }

# Remove Windows.old if it exists
if (Test-Path "$env:SystemDrive\Windows.old") {
    Write-Output 'Removing Windows.old...'
    Remove-Item -Path "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
}

# Clear temp files one more time
Write-Output 'Clearing temporary files...'
$tempFolders = @(
    "$env:TEMP\*",
    "$env:SystemRoot\Temp\*",
    "$env:SystemRoot\Logs\*",
    "C:\Windows\SoftwareDistribution\Download\*"
)

foreach ($folder in $tempFolders) {
    Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
}

# Clear PowerShell history
Write-Output 'Clearing PowerShell history...'
Remove-Item (Get-PSReadlineOption).HistorySavePath -Force -ErrorAction SilentlyContinue

# Remove any packer-related files
Write-Output 'Removing Packer files...'
Remove-Item "C:\Packer" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output 'Cleanup complete. Ready for sysprep.'