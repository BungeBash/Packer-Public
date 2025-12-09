convert_template = true
disk_controller_type = "pvscsi"
disk_thin = true
firmware = "efi"
iso_checksum = "aac774e5aba1c0275d50e0cc4e0e08eca660a116773280596e0bcb894d2da16d"
iso_url = "file:///path/to/rhel-9.7-x86_64-dvd.iso"
os = "rhel9_64Guest"
prefix = "RHEL9"
remove_cdrom = true
ssh_timeout = "10m"
vCores = 1
vCPU = 2
vCPU_hot_add = true
vDisk = 10240 # in MB
video_ram = 16384
vMEM = 4096
vMEM_hot_add = true
vm_boot_command = [
    "<up>",
    "e",
    "<down><down><end><wait>",
    " text inst.ks=cdrom:/ks.cfg",
    "<enter><wait><leftCtrlOn>x<leftCtrlOff>"
  ]
vm_guest_os_keyboard = "us"
vm_guest_os_language = "en_US"
vm_guest_os_timezone = "UTC"
vTPM = false