# https://developer.hashicorp.com/packer/integrations/hashicorp/vsphere/latest/components/builder/vsphere-iso
# https://github.com/vmware/packer-examples-for-vsphere/tree/develop?tab=readme-ov-file
# v1.1.1

variable "common_ip_settle_timeout" {
  type        = string
  description = "Time to wait for guest operating system IP to settle down."
  default     = "5s"
}

variable "common_ip_wait_timeout" {
  type        = string
  description = "Time to wait for guest operating system IP address response."
  default     = "15m"
}

variable "common_shutdown_timeout" {
  type        = string
  description = "Time to wait for guest operating system shutdown."
  default     = "5m"
}

variable "communicator_port" {
  type        = number
  description = "The port for the communicator protocol."
  default     = 5985
}

variable "communicator_timeout" {
  type        = string
  description = "The timeout for the communicator protocol."
  default     = "10m"
}

variable "communicator_type" {
  type        = string
  description = "The communicator type (ssh or winrm)."
  default     = "winrm"
}

variable "convert_template" {
  type        = bool
  default     = false
  description = "Whether to convert the VM to a template after creation."
}

variable "disk_controller_type" {
  type        = string
  description = "The disk controller type for the virtual machine."
}

variable "disk_thin" {
  type        = bool
  description = "Whether to use thin provisioning for the disk."
}

variable "firmware" {
  type        = string
  description = "The firmware type for the virtual machine (e.g., bios, efi)."
}

variable "hash_password" {
  type        = string
  description = "The hashed password for template SSH Login."
  sensitive   = true
}

variable "insecure_connection" {
  type        = bool
  description = "Whether to skip SSL certificate verification for vCenter connection."
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

variable "os" {
  type        = string
  description = "VMware OS Guest Type"
}

variable "prefix" {
  type        = string
  description = "Prefix for the VM name"
}

variable "remove_cdrom" {
  type        = bool
  description = "Whether to remove the CD-ROM drive after provisioning."
  default     = true
}

variable "ssh_timeout" {
  type        = string
  description = "SSH Timeout duration"
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

variable "vCores" {
  type        = number
  description = "The number of CPU cores per socket."
}

variable "vCPU" {
  type        = number
  description = "The number of virtual CPUs."
}

variable "vCPU_hot_add" {
  type        = bool
  description = "Whether to enable CPU hot add."
}

variable "vDisk" {
  type        = number
  description = "The size of the virtual disk in MB."
}

variable "vMEM" {
  type        = number
  description = "The amount of memory in MB."
}

variable "vMEM_hot_add" {
  type        = bool
  description = "Whether to enable memory hot add."
}

variable "video_ram" {
  type        = number
  description = "The amount of video RAM in KB."
}

variable "vm_boot_command" {
  type        = list(string)
  description = "The virtual machine boot command."
  default     = ["<spacebar>"]
}

variable "vm_boot_order" {
  type        = string
  description = "The boot order for virtual machines devices."
  default     = "disk,cdrom"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait before boot."
  default     = "2s"
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
  default     = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
}

variable "vmware_cluster" {
  type        = string
  description = "The vSphere cluster name."
}

variable "vmware_datacenter" {
  type        = string
  description = "The vSphere datacenter name."
}

variable "vmware_datastore" {
  type        = string
  description = "The vSphere datastore name."
}

variable "vmware_folder" {
  type        = string
  description = "The vSphere folder path for the VM."
}

variable "vmware_network" {
  type        = string
  description = "The vSphere network name."
}

variable "vmware_password" {
  type        = string
  description = "The password for the login to the vCenter Server instance."
  sensitive   = true
}

variable "vmware_server" {
  type        = string
  description = "The vCenter Server hostname or IP address."
}

variable "vmware_tools_path" {
  type        = string
  description = "The path to the VMware Tools ISO image."
  default     = "[] /vmimages/tools-isoimages/windows.iso"
}

variable "vmware_username" {
  type        = string
  description = "The username to login to the vCenter Server instance."
}

variable "vTPM" {
  type        = bool
  description = "Whether to enable virtual TPM."
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
}

packer {
  required_version = ">= 1.11.0"
  required_plugins {
    vmware = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/vsphere"
    }
    windows-update = {
      version = "0.17.1"
      source  = "github.com/rgl/windows-update"
    }
  }
}

source "vmware-iso" "Windows2025" {
  # ISO Configuration
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum

  # Boot Configuration
  boot_order        = var.vm_boot_order
  boot_wait         = var.vm_boot_wait
  boot_command      = var.vm_boot_command
  ip_wait_timeout   = var.common_ip_wait_timeout
  ip_settle_timeout = var.common_ip_settle_timeout
  shutdown_command  = var.vm_shutdown_command
  shutdown_timeout  = var.common_shutdown_timeout


  # Communicator Configuration
  communicator   = var.communicator_type
  winrm_username = var.template_username
  winrm_password = var.template_password
  winrm_port     = var.communicator_port
  winrm_timeout  = var.communicator_timeout

  # VM Configuration
  vm_name        = local.vm_name
  
  # vSphere Configuration
  vcenter_server      = var.vmware_server
  username            = var.vmware_username
  password            = var.vmware_password
  guest_os_type       = var.os
  insecure_connection = var.insecure_connection
  datacenter          = var.vmware_datacenter
  folder              = var.vmware_folder
  cluster             = var.vmware_cluster
  datastore           = var.vmware_datastore
  convert_to_template = var.convert_template

  # Hardware Configuration
  firmware       = var.firmware
  CPUs           = var.vCPU
  cpu_cores      = var.vCores
  CPU_hot_plug   = var.vCPU_hot_add
  RAM            = var.vMEM
  RAM_hot_plug   = var.vMEM_hot_add
  video_ram      = var.video_ram
  network_adapters {
    network      = var.vmware_network
    network_card = "vmxnet3"
  }
  vTPM = var.vTPM
  disk_controller_type = ["${var.disk_controller_type}"]
    storage {
      disk_size = var.vDisk
      disk_thin_provisioned = var.disk_thin
      disk_controller_index = 0
    }

  iso_paths = ["${var.vmware_tools_path}"]
  floppy_content = local.data_source_content
  floppy_files = [
    "${path.root}/scripts/agent.ps1",
    "${path.root}/../common/scripts/setup.ps1",
    "${path.root}/../common/scripts/cleanup.ps1",
    "${path.root}/../common/scripts/shutdown.ps1"
  ]
  floppy_label = "cidata"
  remove_cdrom = var.remove_cdrom
}

build {
  name    = "${var.prefix}-${local.build_date}"
  sources = ["source.vmware-iso.${var.prefix}"]

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

  provisioner "powershell" {
    inline = [
      "& \"A:\\cleanup.ps1\""
    ]
  }
}