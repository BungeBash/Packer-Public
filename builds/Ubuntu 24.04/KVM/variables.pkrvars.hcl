communicator_type = "ssh"
disk_interface = "virtio"
efi = true
format = "qcow2"
headless = true
iso_checksum = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
iso_url = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
machine_type = "q35"
net_bridge = "virbr0"
net_device = "virtio-net"
prefix = "Ubuntu2404"
skip_cache = false
ssh_timeout = "20m"
vCPU = 2
vDisk = "10"
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
vMEM = 4096
vnc_port = 5907