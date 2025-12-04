convert_template = true
disk_controller_type = "pvscsi"
disk_thin = true
firmware = "efi"
iso_checksum = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
iso_url = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
os = "ubuntu64Guest"
prefix = "Ubuntu2404"
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
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot",
    "<enter>"
  ]
vTPM = false