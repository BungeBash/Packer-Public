# https://developer.hashicorp.com/packer/integrations/hashicorp/vsphere/latest/components/builder/vsphere-iso
# https://github.com/vmware/packer-examples-for-vsphere/tree/develop?tab=readme-ov-file
# v1.0.9

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
  description = "The hashed password for template SSH login."
  sensitive   = true
}

variable "insecure_connection" {
  type        = bool
  description = "Whether to skip SSL certificate verification for vCenter connection."
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
  description = "VMware OS guest type."
}

variable "prefix" {
  type        = string
  description = "The prefix to use for the VM name."
}

variable "remove_cdrom" {
  type        = bool
  description = "Whether to remove the CD-ROM drive after provisioning."
}

variable "ssh_timeout" {
  type        = string
  description = "SSH timeout duration."
}

variable "template_password" {
  type        = string
  description = "The password for template SSH login."
  sensitive   = true
}

variable "template_username" {
  type        = string
  description = "The username for template SSH login."
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
  default = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot",
    "<enter>"
  ]
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

variable "vmware_username" {
  type        = string
  description = "The username to login to the vCenter Server instance."
}

variable "vmware_tools_path" {
  type        = string
  description = "The path to the VMware Tools ISO image."
  default     = "[] /vmimages/tools-isoimages/windows.iso"
}

variable "vTPM" {
  type        = bool
  description = "Whether to enable virtual TPM."
}

locals {
  build_date = formatdate("YYYYMMDDHHmmss", timestamp())
  data_source_content = {
    "/meta-data" = templatefile(abspath("${path.root}/../common/http/meta-data.pkrtpl.hcl"), {})
    "/user-data" = templatefile(abspath("${path.root}/../common/http/user-data.pkrtpl.hcl"), {
      template_username = var.template_username
      template_password = var.hash_password
    }),
    "/runonce.sh"= templatefile(abspath("${path.root}/../common/scripts/runonce.pkrtpl.hcl"), {
      template_username = var.template_username
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
  }
}

source "vmware-iso" "Ubuntu2404" {
  # ISO Configuration
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum

  # Boot Configuration
  ssh_username       = var.template_username
  ssh_password       = var.template_password
  ssh_timeout        = var.ssh_timeout
  boot_command       = var.vm_boot_command

  # VM Configuration
  vm_name            = local.vm_name
  
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

  cd_content = local.data_source_content
  cd_label = "cidata"
  remove_cdrom = var.remove_cdrom
}

build {
  name    = local.vm_name
  sources = ["source.vmware-iso.${var.prefix}"]

  provisioner "shell" {
    scripts = [
      "${path.root}/../common/scripts/setup.sh",
      "${path.root}/scripts/vmware.sh",
      "${path.root}/../common/scripts/cleanup.sh"
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
}