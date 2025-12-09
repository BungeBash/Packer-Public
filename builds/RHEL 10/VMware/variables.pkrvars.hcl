convert_template = true
disk_controller_type = "pvscsi"
disk_thin = true
firmware = "efi"
iso_checksum = "5925e05c32d8324a72e146a29293d60707571817769de73df63eab8dbd6d3196"
iso_url = "file:///path/to/rhel-10.1-x86_64-dvd.iso" # Must be full DVD
os = "rhel9_64Guest"
prefix = "RHEL10"
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