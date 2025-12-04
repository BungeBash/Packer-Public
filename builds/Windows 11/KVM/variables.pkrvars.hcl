common_shutdown_timeout = "10m"
communicator_port = 5985
communicator_timeout = "30m"
communicator_type = "winrm"
disk_interface = "virtio"
drivers_url = "/drivers/viostor/w11/amd64"
efi = true
format = "qcow2"
headless = true
iso_checksum = "D141F6030FED50F75E2B03E1EB2E53646C4B21E5386047CB860AF5223F102A32"
iso_url = "https://example.com/path/to/windows-11.iso"
machine_type = "q35"
net_device = "virtio-net"
prefix = "Windows11"
skip_cache = false
vCPU = 4
vDisk = 30
virtio_url = "/isos/virtio-win.iso"
vm_boot_command = [
  "<spacebar>",
  "<spacebar>",
  "<enter>"
]
vm_boot_wait = "5s"
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
vm_shutdown_command = "powershell.exe -ExecutionPolicy Bypass -File \"A:\\shutdown.ps1\""
vMEM = 8192
vTPM = true
windows_update_filters = [
    "exclude:$_.Title -like '*Preview*'",
    "include:$true"
  ]
windows_update_limit = 25
windows_update_search_criteria = "IsInstalled=0"