# https://developer.hashicorp.com/packer/integrations/hashicorp/qemu
# v.1.0.10

variable "communicator_type" {
  type        = string
  description = "Communicator type for connecting to the VM"
  default     = "ssh"
}

variable "cpu_model" {
  type        = string
  description = "The model of CPU to use when building VM that is supported by your hardware"
  default     = "host"
}

variable "rhsm_username" {
  type        = string
  description = "The username to Red Hat Subscription Manager."
  default     = ""
  sensitive   = true
}

variable "rhsm_password" {
  type        = string
  description = "The password to login to Red Hat Subscription Manager."
  default     = ""
  sensitive   = true
}

variable "vm_guest_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard input."
  default     = "us"
}

variable "vm_guest_os_language" {
  type        = string
  description = "The guest operating system language."
  default     = "en_US"
}

variable "vm_guest_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "UTC"
}

variable "disk_interface" {
  type        = string
  description = "Disk interface type (virtio, scsi, ide)"
  default     = "virtio"
}

variable "efi" {
  type        = bool
  description = "Enable EFI boot"
  default     = true
}

variable "lin_firmware_code" {
  type        = string
  description = "Path to EFI firmware code file"
}

variable "firmware_vars" {
  type        = string
  description = "Path to EFI firmware vars file"
}

variable "format" {
  type        = string
  description = "Output format (qcow2, raw, vmdk)"
  default     = "qcow2"
}

variable "hash_password" {
  type        = string
  description = "The hashed password for template SSH Login."
  sensitive   = true
}

variable "headless" {
  type        = bool
  description = "Run QEMU in headless mode (no GUI)"
  default     = true
}

variable "iso_checksum" {
  type        = string
  description = "The checksum of the ISO file."
}

variable "iso_url" {
  type        = string
  description = "The URL to download the ISO file."
}

variable "machine_type" {
  type        = string
  description = "QEMU machine type"
}

variable "net_bridge" {
  type        = string
  description = "Network bridge to use for VM networking"
}

variable "net_device" {
  type        = string
  description = "Network device type"
  default     = "virtio-net"
}

variable "output_directory" {
  type        = string
  description = "Directory where the VM image will be stored"
}

variable "prefix" {
  type        = string
  description = "Prefix for the VM name"
}

variable "qemu_binary" {
  type        = string
  description = "Path to QEMU binary"
  default     = "qemu-system-x86_64"
}

variable "skip_cache" {
  type        = bool
  description = "Skip ISO download cache"
  default     = false
}

variable "ssh_timeout" {
  type        = string
  description = "SSH Timeout duration"
  default     = "20m"
}

variable "template_password" {
  type        = string
  description = "The password for template SSH Login."
  sensitive   = true
}

variable "template_username" {
  type        = string
  description = "The username for template SSH Login."
}

variable "templates_directory" {
  type        = string
  description = "Directory to move template files"
}

variable "vCPU" {
  type        = number
  description = "Number of vCPUs"
}

variable "vDisk" {
  type        = number
  description = "Disk size in GB"
}

variable "vMEM" {
  type        = number
  description = "Memory in MB"
}

variable "vm_boot_command" {
  type        = list(string)
  description = "The virtual machine boot command."
  default = [
    "<up>",
    "e",
    "<down><down><end><wait>",
    " text inst.ks=cdrom:/ks.cfg",
    "<enter><wait><leftCtrlOn>x<leftCtrlOff>"
  ]
}

variable "vnc_port" {
  type        = number
  description = "VNC Port for QEMU"
}

locals {
  build_date = formatdate("YYYYMMDDHHmmss", timestamp())
  data_source_content = {
    "/ks.cfg" = templatefile(abspath("${path.root}/../common/http/ks.pkrtpl.hcl"), {
      template_username        = var.template_username
      template_password        = var.hash_password
      rhsm_username            = var.rhsm_username
      rhsm_password            = var.rhsm_password
      vm_guest_os_language     = var.vm_guest_os_language
      vm_guest_os_keyboard     = var.vm_guest_os_keyboard
      vm_guest_os_timezone     = var.vm_guest_os_timezone
      storage                  = templatefile(abspath("${path.root}/../common/http/storage.pkrtpl.hcl"), {})
    }),
    "/runonce.sh"= templatefile(abspath("${path.root}/../common/scripts/runonce.pkrtpl.hcl"), {
      template_username = var.template_username
    })
  }
  vm_name = "${var.prefix}-${local.build_date}"
  output_directory = "${var.output_directory}${local.vm_name}"
}

packer {
  required_version = ">= 1.11.0"
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "RHEL10" {
  # ISO Configuration
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  iso_skip_cache = var.skip_cache

  # Boot Configuration
  ssh_username     = var.template_username
  ssh_password     = var.template_password
  ssh_timeout      = var.ssh_timeout
  communicator     = var.communicator_type
  boot_command     = var.vm_boot_command
  shutdown_command = "echo '${var.template_password}' | sudo -S shutdown -P now"

  # VM Name and Output
  vm_name          = local.vm_name
  output_directory = local.output_directory

  # QEMU Configuration
  accelerator    = "kvm"
  qemu_binary    = var.qemu_binary
  headless       = var.headless
   cpu_model     = var.cpu_model

  # Hardware Configuration
  cpus              = var.vCPU
  memory            = var.vMEM
  disk_size         = "${var.vDisk}G"
  format            = var.format
  machine_type      = var.machine_type
  disk_interface    = var.disk_interface
  net_device        = var.net_device
  net_bridge        = var.net_bridge
  efi_boot          = var.efi
  efi_firmware_code = var.lin_firmware_code
  efi_firmware_vars = var.firmware_vars

  # Cloud-init / Autoinstall
  cd_content = local.data_source_content
  cd_label   = "cidata"
}

build {
  name    = "${var.prefix}-${local.build_date}"
  sources = ["source.qemu.${var.prefix}"]

  provisioner "shell" {
    scripts = [
      "${path.root}/../common/scripts/setup.sh",
      "${path.root}/scripts/kvm.sh"
    ]
    execute_command = "echo '${var.template_password}' | sudo -S bash '{{ .Path }}'"
  }

  provisioner "shell" {
    inline = [
      # Find and mount the CD
      "CDROM_DEV=$(blkid -L cidata || blkid -L CIDATA)",
      "sudo mkdir -p /mnt/cdrom",
      "sudo mount $CDROM_DEV /mnt/cdrom",

      # Execute the script from CD
      "sudo bash /mnt/cdrom/runonce.sh",

      # Unmount
      "sudo umount /mnt/cdrom"
    ]
    execute_command = "echo '${var.template_password}' | sudo -S bash -c '{{ .Path }}'"
  }

  provisioner "shell" {
    scripts = [
      "${path.root}/../common/scripts/cleanup.sh"
    ]
    execute_command = "echo '${var.template_password}' | sudo -S bash '{{ .Path }}'"
  }

  post-processor "shell-local" {
  inline = [
    "echo 'Build completed: ${local.build_date}'",
    "mkdir -p ${var.templates_directory}/${local.vm_name}",
    "cp ${local.output_directory}/${local.vm_name} ${var.templates_directory}/${local.vm_name}/${local.vm_name}.qcow2",
    "echo 'Template copied to: ${var.templates_directory}/${local.vm_name}/${local.vm_name}.qcow2'",
    "cat > ${var.templates_directory}/${local.vm_name}/metadata.json <<EOF\n{\"disks\":[{\"capacity\":${var.vDisk * 1024 * 1024 * 1024},\"guestDeviceName\":\"vda\",\"position\":0,\"name\":\"root\",\"file\":\"${local.vm_name}.qcow2\"}]}\nEOF",
    "echo 'Metadata file created: ${var.templates_directory}/${local.vm_name}/metadata.json'"
    ]
  }
}