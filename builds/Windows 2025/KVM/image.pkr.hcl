# https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu
# v.1.0.1

variable "common_shutdown_timeout" {
  type        = string
  description = "Time to wait for guest operating system shutdown."
  default     = "10m"
}

variable "communicator_port" {
  type        = number
  description = "The port for the communicator protocol."
  default     = 5985
}

variable "communicator_timeout" {
  type        = string
  description = "The timeout for the communicator protocol."
  default     = "20m"
}

variable "communicator_type" {
  type        = string
  description = "The communicator type."
  default     = "winrm"
}

variable "disk_interface" {
  type        = string
  description = "Disk interface type (virtio, scsi, ide)"
  default     = "virtio"
}

variable "drivers_url" {
  type        = string
  description = "The URL to download the Drivers files."
  default     = "/drivers/viostor/2k25/amd64"
}

variable "efi" {
  type        = bool
  description = "Enable EFI boot"
  default     = true
}

variable "win_firmware_code" {
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

variable "headless" {
  type        = bool
  description = "Run in headless mode"
  default     = true
}

variable "iso_checksum" {
  type        = string
  description = "The checksum of the ISO file."
  default     = "D0EF4502E350E3C6C53C15B1B3020D38A5DED011BF04998E950720AC8579B23D"
}

variable "iso_url" {
  type        = string
  description = "The URL to download the ISO file."
  default     = "https://example.com/path/to/windows-server-2025.iso"
}

variable "machine_type" {
  type        = string
  description = "QEMU machine type"
  default     = "q35"
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
  default     = "Windows2025"
}

variable "qemu_binary" {
  type        = string
  description = "Path to QEMU binary"
  default     = "qemu-system-x86_64"
}

variable "skip_cache" {
  type        = bool
  description = "Skip ISO caching"
  default     = false
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
  default     = 4
}

variable "vDisk" {
  type        = number
  description = "Disk size (e.g., 10G, 20000M)"
  default     = 30
}

variable "virtio_url" {
  type        = string
  description = "The URL to download the Virtio ISO file."
  default     = "/isos/virtio-win.iso"
}

variable "vm_boot_command" {
  type        = list(string)
  description = "The virtual machine boot command."
  default     = [
    "<spacebar>"
  ]
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait before boot."
  default     = "3s"
}

variable "vm_guest_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard input."
  default     = "en-US"
}

variable "vm_guest_os_language" {
  type        = string
  description = "The guest operating system language."
  default     = "en-US"
}

variable "vm_guest_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "UTC"
}

variable "vm_inst_os_eval" {
  type        = bool
  description = "Build using the operating system evaluation"
  default     = true
}

variable "vm_inst_os_image_datacenter_desktop" {
  type        = string
  description = "The installation operating system image input. Does support evaluation."
  default     = "Windows Server 2025 SERVERDATACENTER"
}

variable "vm_inst_os_key_datacenter" {
  type        = string
  description = "The installation operating system key input."
  default     = ""
}

variable "vm_inst_os_keyboard" {
  type        = string
  description = "The installation operating system keyboard input."
  default     = "en-US"
}

variable "vm_inst_os_language" {
  type        = string
  description = "The installation operating system language."
  default     = "en-US"
}

variable "vm_shutdown_command" {
  type        = string
  description = "Command(s) for guest operating system shutdown."
  default     = "powershell.exe -ExecutionPolicy Bypass -File \"A:\\shutdown.ps1\""
}

variable "vMEM" {
  type        = number
  description = "Memory in MB"
  default     = 8192
}

variable "vTPM" {
  type        = bool
  description = "Enable virtual TPM"
  default     = true
}

variable "windows_update_filters" {
  type        = list(string)
  description = "Filters for Windows Update."
  default     = [
    "exclude:$_.Title -like '*Preview*'",
    "include:$true"
  ]
}

variable "windows_update_limit" {
  type        = number
  description = "Maximum number of updates to install per cycle."
  default     = 25
}

variable "windows_update_search_criteria" {
  type        = string
  description = "Search criteria for Windows Update."
  default     = "IsInstalled=0"
}

locals {
  build_date = formatdate("YYYYMMDDHHmmss", timestamp())
  data_source_content = {
    "/autounattend.xml" = templatefile(abspath("${path.root}/../common/http/autounattend.pkrtpl.hcl"), {
      template_password    = var.template_password
      template_username    = var.template_username
      vm_guest_os_keyboard = var.vm_guest_os_keyboard
      vm_guest_os_language = var.vm_guest_os_language
      vm_guest_os_timezone = var.vm_guest_os_timezone
      vm_inst_os_eval      = var.vm_inst_os_eval
      vm_inst_os_image     = var.vm_inst_os_image_datacenter_desktop
      vm_inst_os_key       = var.vm_inst_os_key_datacenter
      vm_inst_os_keyboard  = var.vm_inst_os_keyboard
      vm_inst_os_language  = var.vm_inst_os_language
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
    windows-update = {
      version = "0.17.1"
      source  = "github.com/rgl/windows-update"
    }
  }
}

source "qemu" "Windows2025" {
  # ISO Configuration
  iso_url           = var.iso_url
  iso_checksum      = var.iso_checksum
  iso_skip_cache    = var.skip_cache

  # Boot Configuration
  boot_wait         = var.vm_boot_wait
  boot_command      = var.vm_boot_command
  shutdown_command  = var.vm_shutdown_command
  shutdown_timeout  = var.common_shutdown_timeout

  # Template Communicator Configuration
  winrm_username = var.template_username
  winrm_password = var.template_password
  winrm_timeout  = var.communicator_timeout
  winrm_port     = var.communicator_port
  communicator   = var.communicator_type

  qemuargs = [
    ["-cdrom", "${var.virtio_url}"]
  ]

  # VM Name and Output
  vm_name          = local.vm_name
  output_directory = local.output_directory

  # QEMU Configuration
  accelerator    = "kvm"
  qemu_binary    = var.qemu_binary
  headless       = var.headless
  cpu_model      = "host"
  disk_discard   = "unmap"

  # Hardware Configuration
  cpus              = var.vCPU
  memory            = var.vMEM
  disk_size         = "${var.vDisk}G"
  format            = var.format
  machine_type      = var.machine_type
  vtpm              = var.vTPM
  disk_interface    = var.disk_interface
  net_device        = var.net_device
  efi_boot          = var.efi
  efi_firmware_code = var.win_firmware_code
  efi_firmware_vars = var.firmware_vars

  # Cloud-Init / Autounattend / Scripts
  floppy_content = local.data_source_content
  floppy_files = [
    "${path.root}/scripts/agent.ps1",
    "${path.root}/../common/scripts/setup.ps1",
    "${path.root}/../common/scripts/cleanup.ps1",
    "${path.root}/../common/scripts/shutdown.ps1"
  ]
  floppy_dirs    = ["${var.drivers_url}"]
  floppy_label   = "cidata"
}

build {
  name    = "${var.prefix}-${local.build_date}"
  sources = ["source.qemu.${var.prefix}"]

  # Install Windows Updates (Recommended - excludes Previews)
  provisioner "windows-update" {
    search_criteria = var.windows_update_search_criteria
    filters         = var.windows_update_filters
    update_limit    = var.windows_update_limit
  }

  # Restart after updates
  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  # Optional: Run another Windows Update cycle to catch any updates that depend on previous updates
  provisioner "windows-update" {
    search_criteria = var.windows_update_search_criteria
    filters         = var.windows_update_filters
    update_limit    = var.windows_update_limit
  }

  # Final restart
  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  # Sysprep the machine
  provisioner "powershell" {
    inline = [
      "& \"A:\\cleanup.ps1\""
    ]
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