common_shutdown_timeout = "10m"
communicator_port = 5985
communicator_timeout = "20m"
communicator_type = "winrm"
disk_interface = "virtio"
drivers_url = "/drivers/viostor/2k25/amd64"
efi = true
format = "qcow2"
headless = true
iso_checksum = "D0EF4502E350E3C6C53C15B1B3020D38A5DED011BF04998E950720AC8579B23D"
iso_url = "https://example.com/path/to/windows-server-2025.iso"
machine_type = "q35"
net_device = "virtio-net"
prefix = "Windows2025"
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
vm_inst_os_image_datacenter_desktop = "Windows Server 2025 SERVERDATACENTER"
vm_inst_os_key_datacenter = ""
vm_inst_os_keyboard = "en-US"
vm_inst_os_language = "en-US"
vm_shutdown_command = "powershell.exe -ExecutionPolicy Bypass -File \"F:\\shutdown.ps1\""
vMEM = 8192
vTPM = true
windows_update_filters = [
    "exclude:$_.Title -like '*Preview*'",
    "include:$true"
  ]
windows_update_limit = 25
windows_update_search_criteria = "IsInstalled=0"