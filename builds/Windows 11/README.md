# Windows 11 Packer Build

This directory contains Packer configurations for building Windows 11 images for both KVM and VMware hypervisors.

## Overview

- **OS Version**: Windows 11 Enterprise / Pro
- **Installation Method**: Automated (Autounattend.xml)
- **Communicator**: WinRM (port 5985)
- **Supported Hypervisors**: KVM/QEMU, VMware vSphere
- **License**: Evaluation mode enabled by default

## Directory Structure

```
Windows 11/
├── KVM/
│   ├── image.pkr.hcl
│   └── variables.pkrvars.hcl
├── VMware/
│   ├── image.pkr.hcl
│   └── variables.pkrvars.hcl
└── README.md
```

## Common Configuration

Both builds share:
- **vCPU**: 4 cores
- **Memory**: 8192 MB (8 GB)
- **Disk**: 30 GB
- **Firmware**: EFI/UEFI (required for Windows 11)
- **vTPM**: Enabled (required for Windows 11)
- **ISO Checksum**: `D141F6030FED50F75E2B03E1EB2E53646C4B21E5386047CB860AF5223F102A32`
- **Locale**: en-US keyboard, language, UTC timezone
- **Shutdown**: PowerShell script via A: drive

### Windows Update Settings
- **Update Limit**: 25 updates per cycle
- **Search Criteria**: IsInstalled=0 (only missing updates)
- **Filters**: Excludes Preview updates, includes all others

## KVM-Specific Configuration

### Storage & Networking
- **Disk Format**: QCOW2
- **Disk Interface**: VirtIO (requires VirtIO drivers)
- **Network Device**: virtio-net (paravirtualized networking)
- **Machine Type**: Q35
- **VirtIO Drivers**: Required from `/isos/virtio-win.iso`
- **Driver Path**: `/drivers/viostor/w11/amd64`

### Build Settings
- **Headless Mode**: Enabled
- **Communicator Timeout**: 30 minutes
- **Shutdown Timeout**: 10 minutes

### Boot Command
```
<spacebar>
<spacebar>
<enter>
```
Boot wait: 5 seconds

### Key Features
- VirtIO drivers for optimal performance on KVM
- Requires separate VirtIO driver ISO during installation
- QCOW2 format for flexible storage management
- Q35 machine type with PCIe support

## VMware-Specific Configuration

### Storage & Networking
- **Disk Controller**: PVSCSI (Paravirtual SCSI)
- **Thin Provisioning**: Enabled
- **Disk Size**: 30720 MB (30 GB)
- **Video RAM**: 16384 MB

### CPU/Memory Features
- **vCores**: 1 socket
- **Hot-Add CPU**: Enabled
- **Hot-Add Memory**: Enabled

### Template Options
- **Convert to Template**: Enabled
- **Remove CD-ROM**: Enabled (after build)
- **Guest OS Type**: windows11_64Guest
- **vTPM**: Enabled (Windows 11 requirement)

### Timeouts
- **IP Wait Timeout**: 30 minutes
- **SSH Timeout**: 20 minutes
- **Shutdown Timeout**: 10 minutes

### Boot Command
```
<spacebar>
```

### Key Features
- PVSCSI controller for better disk I/O performance
- Hot-add capabilities for dynamic resource scaling
- Automatic conversion to vSphere template
- Native VMware tools integration
- Thin provisioned disks to save storage space

## Build Instructions

### Prerequisites

**For KVM:**
```bash
# OVMF UEFI firmware with Secure Boot support
# QEMU/KVM installed
# VirtIO drivers ISO available at /isos/virtio-win.iso
# Windows 11 ISO
# WinRM configured for communication
```

**For VMware:**
```bash
# VMware vSphere/ESXi 7.0+ (for Windows 11 support)
# vTPM 2.0 support enabled on cluster
# Network access to vCenter/ESXi host
# Credentials configured in common variables
```

### Building

**KVM Build:**
```bash
cd "Windows 11/KVM"
packer init .
packer build -var-file="../../common/variables/KVM.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

**VMware Build:**
```bash
cd "Windows 11/VMware"
packer init .
packer build -var-file="../../common/variables/VMware.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

## Key Differences: KVM vs VMware

| Feature | KVM | VMware |
|---------|-----|--------|
| **Disk Format** | QCOW2 | VMDK (thin) |
| **Disk Interface** | VirtIO (requires drivers) | PVSCSI |
| **Network** | virtio-net | vmxnet3 (default) |
| **Machine Type** | Q35 | N/A (ESXi handles) |
| **Driver ISO** | Required (virtio-win.iso) | VMware Tools (built-in) |
| **Hot-Add** | Not configured | CPU & Memory enabled |
| **Template Conversion** | Manual | Automatic |
| **Communicator Timeout** | 30m | Uses IP wait (30m) |
| **Boot Command** | 2x spacebar + enter | 1x spacebar |
| **Video RAM** | Not specified | 16384 MB |
| **Shutdown Drive** | A: drive | A: drive |

## Windows 11 Requirements

Both configurations meet Windows 11 system requirements:
- UEFI firmware (EFI boot)
- TPM 2.0 (vTPM enabled)
- 4 GB RAM minimum (8 GB configured)
- 64 GB storage minimum (30 GB configured)
- UEFI Secure Boot capable

## Available Editions

Both builds support:
- **Windows 11 Pro** - Professional edition
- **Windows 11 Enterprise** - Enterprise edition

Product keys can be configured via:
- `vm_inst_os_key_pro` - For Pro edition
- `vm_inst_os_key_ent` - For Enterprise edition

Leave empty for evaluation mode (default).

## Notes

- **VirtIO Drivers (KVM)**: Must be injected during Windows installation for storage and network
- **vTPM Required**: Windows 11 will not install without TPM 2.0
- **WinRM Communication**: Ensure firewall rules allow WinRM during build
- **Evaluation Period**: 90 days for evaluation licenses
- **Windows Updates**: Automatically applied during build (excludes Preview updates)
- **Shutdown Script**: Located on A: drive (floppy/virtual media)
- **PVSCSI (VMware)**: Requires PVSCSI driver during Windows installation
