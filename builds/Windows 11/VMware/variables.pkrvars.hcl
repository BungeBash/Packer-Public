communicator_port = 5985
communicator_type = "winrm"
common_ip_wait_timeout = "30m"
common_shutdown_timeout = "10m"
convert_template = true
disk_controller_type = "pvscsi"
disk_thin = true
firmware = "efi"
iso_checksum = "D141F6030FED50F75E2B03E1EB2E53646C4B21E5386047CB860AF5223F102A32"
iso_url = "https://example.com/path/to/windows-11.iso"
os = "windows11_64Guest"
prefix = "Windows11"
remove_cdrom = true
ssh_timeout = "20m"
vCores = 1
vCPU = 4
vCPU_hot_add = true
vDisk = 30720 # in MB
video_ram = 16384
vm_boot_command = [
    "<spacebar>"
    ]
vm_guest_os_keyboard = "en-US"
vm_guest_os_language = "en-US"
vm_guest_os_timezone = "UTC"
vm_inst_os_eval = true
vm_inst_os_image_ent = "Windows 11 Enterprise"
vm_inst_os_image_pro = "Windows 11 Pro"
vm_inst_os_key_pro = ""
vm_inst_os_key_ent = ""
vm_inst_os_keyboard = "en-US"
vm_inst_os_language = "en-US"
vMEM = 8192
vMEM_hot_add = true
vm_shutdown_command = "powershell.exe -ExecutionPolicy Bypass -File \"A:\\shutdown.ps1\""
vTPM = true
windows_update_filters = [
    "exclude:$_.Title -like '*Preview*'",
    "include:$true"
  ]
windows_update_limit = 25
windows_update_search_criteria = "IsInstalled=0"