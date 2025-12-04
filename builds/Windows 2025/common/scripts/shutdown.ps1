$ErrorActionPreference = 'Stop'

# Write-Output 'Removing packer user account...'
try {
    # Check if the user exists before attempting to remove
    $packerUser = Get-LocalUser -Name $env:USERNAME -ErrorAction SilentlyContinue
    if ($packerUser) {
        # Schedule the user removal after sysprep (will happen after current session ends)
        Write-Output "Scheduling removal of user: $packerUser"
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "DeletePacker" -Value "cmd.exe /c net user $packerUser /delete"
    }
} catch {
    Write-Output "Note: User removal will occur during sysprep process"
}

Write-Output "Running sysprep to generalize the image and initiate shutdown..."
& $env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /quit

while($true) {
    $imageState = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State | Select ImageState
    
    Write-Output "Checking Image State..."
    if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {
        Write-Output $imageState.ImageState
        Start-Sleep -s 10
    } else {
        Write-Output $imageState.ImageState
        shutdown /s /t 60 /f /d p:4:1 /c "Packer Shutdown"
        break
    }
}