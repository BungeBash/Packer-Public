# Ubuntu 24.04 LTS Packer Build

This directory contains Packer configurations for building Ubuntu 24.04 LTS (Noble Numbat) server images for both KVM and VMware hypervisors.

## Overview

- **OS Version**: Ubuntu 24.04.3 LTS Server
- **Installation Method**: Autoinstall (cloud-init based)
- **Communicator**: SSH
- **Supported Hypervisors**: KVM/QEMU, VMware vSphere

## Directory Structure

```
Ubuntu 24.04/
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
- **vCPU**: 2 cores
- **Memory**: 4096 MB (4 GB)
- **Disk**: 10 GB
- **Firmware**: EFI/UEFI
- **ISO Source**: Ubuntu 24.04.3 official release
- **ISO Checksum**: `c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b`

## KVM-Specific Configuration

### Storage & Networking
- **Disk Format**: QCOW2
- **Disk Interface**: VirtIO (high-performance paravirtualized)
- **Network Device**: virtio-net (paravirtualized networking)
- **Network Bridge**: virbr0
- **Machine Type**: Q35

### Display
- **VNC Port**: 5907 (for installation monitoring)

### Key Features
- Headless build mode
- VirtIO drivers for optimal performance on KVM
- Q35 machine type for modern hardware emulation

## VMware-Specific Configuration

### Storage & Networking
- **Disk Controller**: PVSCSI (Paravirtual SCSI)
- **Thin Provisioning**: Enabled
- **Video RAM**: 16384 MB

### CPU/Memory Features
- **vCores**: 1 socket
- **Hot-Add CPU**: Enabled
- **Hot-Add Memory**: Enabled

### Template Options
- **Convert to Template**: Enabled
- **Remove CD-ROM**: Enabled (after build)
- **Guest OS Type**: ubuntu64Guest
- **vTPM**: Disabled

### Key Features
- PVSCSI controller for better disk I/O performance
- Hot-add capabilities for dynamic resource scaling
- Automatic conversion to vSphere template
- Thin provisioned disks to save storage space

## Build Instructions

### Prerequisites

**For KVM:**
```bash
# OVMF UEFI firmware
# QEMU/KVM installed
# VirtIO drivers available
```

**For VMware:**
```bash
# VMware vSphere/ESXi environment
# Network access to vCenter/ESXi host
# Credentials configured in common variables
```

### Building

**KVM Build:**
```bash
cd "Ubuntu 24.04/KVM"
packer init .
packer build -var-file="../../common/variables/KVM.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

**VMware Build:**
```bash
cd "Ubuntu 24.04/VMware"
packer init .
packer build -var-file="../../common/variables/VMware.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

## Key Differences: KVM vs VMware

| Feature | KVM | VMware |
|---------|-----|--------|
| **Disk Format** | QCOW2 | VMDK (thin) |
| **Disk Interface** | VirtIO | PVSCSI |
| **Network** | virtio-net on virbr0 | vmxnet3 (default) |
| **Machine Type** | Q35 | N/A (ESXi handles) |
| **Hot-Add** | Not configured | CPU & Memory enabled |
| **Template Conversion** | Manual | Automatic |
| **SSH Timeout** | 20m | 10m |
| **Storage Driver** | Native virtio | Paravirtual SCSI |

## Boot Command

Both configurations use the same autoinstall boot sequence:
1. Escape to GRUB menu
2. Enter command mode
3. Load kernel with autoinstall parameter
4. Load initrd
5. Boot the system

The autoinstall configuration should be provided via cloud-init or similar mechanism.

## Notes

- Both builds use evaluation/trial licenses by default
- SSH communicator requires network connectivity during build
- VirtIO drivers (KVM) provide near-native performance
- PVSCSI (VMware) optimized for high I/O workloads
- EFI boot mode required for both platforms
