communicator_port = 5985
communicator_type = "winrm"
common_ip_wait_timeout = "20m"
common_shutdown_timeout = "10m"
convert_template = true
disk_controller_type = "pvscsi"
disk_thin = true
firmware = "efi"
iso_checksum = "D0EF4502E350E3C6C53C15B1B3020D38A5DED011BF04998E950720AC8579B23D"
iso_url = "https://example.com/path/to/windows-server-2025.iso"
os = "windows2022srvNext_64Guest"
prefix = "Windows2025"
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
vm_inst_os_image_datacenter_desktop = "Windows Server 2025 SERVERDATACENTER"
vm_inst_os_key_datacenter = ""
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