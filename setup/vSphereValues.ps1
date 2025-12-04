$creds = Get-Credential -Message "Enter vSphere credentials"
$vCenterServer = "vcenter.example.com"
Connect-VIServer -Server $vCenterServer -Credential $creds

$anyEsxiHost = @(Get-VMHost) | Select-Object -First 1
$envBrowser = Get-View -Id (Get-View -Id $anyEsxiHost.ExtensionData.Parent).EnvironmentBrowser
$vmxVersion = ($envBrowser.QueryConfigOptionDescriptor() | Where-Object {$_.DefaultConfigOption}).Key
$envBrowser.QueryConfigOption($vmxVersion, $null).GuestOSDescriptor | Select-Object -Property Id, FullName | Sort-Object -Property FullName