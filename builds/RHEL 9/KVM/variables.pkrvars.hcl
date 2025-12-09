communicator_type = "ssh"
cpu_model = "host"
disk_interface = "virtio"
efi = true
format = "qcow2"
headless = true
iso_checksum = "aac774e5aba1c0275d50e0cc4e0e08eca660a116773280596e0bcb894d2da16d"
iso_url = "file:///path/to/rhel-9.7-x86_64-dvd.iso"
machine_type = "q35"
net_bridge = "virbr0"
net_device = "virtio-net"
prefix = "RHEL9"
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