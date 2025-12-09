communicator_type = "ssh"
cpu_model = "host"
disk_interface = "virtio"
efi = true
format = "qcow2"
headless = true
iso_checksum = "5925e05c32d8324a72e146a29293d60707571817769de73df63eab8dbd6d3196"
iso_url = "file:///path/to/rhel-10.1-x86_64-dvd.iso" # Must be full DVD
machine_type = "q35"
net_bridge = "virbr0"
net_device = "virtio-net"
prefix = "RHEL10"
skip_cache = false
ssh_timeout = "20m"
vCPU = 2
vDisk = "10"
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
vMEM = 4096
vnc_port = 5907