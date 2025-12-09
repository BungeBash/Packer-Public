# RHEL 10 Packer Build

This directory contains Packer configurations for building Red Hat Enterprise Linux 10 server images for both KVM and VMware hypervisors.

## Overview

- **OS Version**: RHEL 10.1
- **Installation Method**: Kickstart (ks.cfg)
- **Communicator**: SSH
- **Supported Hypervisors**: KVM/QEMU, VMware vSphere
- **Subscription**: Supports Red Hat Subscription Manager (RHSM) registration

## Directory Structure

```
RHEL 10/
├── KVM/
│   ├── image.pkr.hcl
│   ├── variables.pkrvars.hcl
│   └── scripts/
│       └── kvm.sh
├── VMware/
│   ├── image.pkr.hcl
│   ├── variables.pkrvars.hcl
│   └── scripts/
│       └── vmware.sh
├── common/
│   ├── http/
│   │   ├── ks.pkrtpl.hcl
│   │   └── storage.pkrtpl.hcl
│   └── scripts/
│       ├── setup.sh
│       ├── cleanup.sh
│       └── runonce.pkrtpl.hcl
└── README.md
```

## Common Configuration

Both builds share:
- **vCPU**: 2 cores
- **Memory**: 4096 MB (4 GB)
- **Disk**: 10 GB
- **Firmware**: EFI/UEFI
- **ISO Source**: RHEL 10.1 DVD (full DVD required)
- **ISO Checksum**: `5925e05c32d8324a72e146a29293d60707571817769de73df63eab8dbd6d3196`
- **Locale**: en_US language, US keyboard, UTC timezone

## KVM-Specific Configuration

### Storage & Networking
- **Disk Format**: QCOW2
- **Disk Interface**: VirtIO (high-performance paravirtualized)
- **Network Device**: virtio-net (paravirtualized networking)
- **Network Bridge**: virbr0
- **Machine Type**: Q35

### Display
- **VNC Port**: 5907 (for installation monitoring)

### Build Settings
- **Headless Mode**: Enabled
- **SSH Timeout**: 20 minutes
- **CPU Model**: host

### Key Features
- Headless build mode
- VirtIO drivers for optimal performance on KVM
- Q35 machine type for modern hardware emulation
- Metadata file generation for template management

## VMware-Specific Configuration

### Storage & Networking
- **Disk Controller**: PVSCSI (Paravirtual SCSI)
- **Disk Size**: 10240 MB (10 GB)
- **Thin Provisioning**: Enabled
- **Video RAM**: 16384 MB

### CPU/Memory Features
- **vCores**: 1 socket
- **Hot-Add CPU**: Enabled
- **Hot-Add Memory**: Enabled

### Template Options
- **Convert to Template**: Enabled
- **Remove CD-ROM**: Enabled (after build)
- **Guest OS Type**: rhel9_64Guest
- **vTPM**: Disabled

### Timeouts
- **SSH Timeout**: 10 minutes

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
# RHEL 10.1 DVD ISO (full DVD, not boot ISO)
```

**For VMware:**
```bash
# VMware vSphere/ESXi environment
# Network access to vCenter/ESXi host
# Credentials configured in common variables
# RHEL 10.1 DVD ISO (full DVD, not boot ISO)
```

**Red Hat Subscription (Optional):**
- Set `rhsm_username` and `rhsm_password` variables to register with RHSM
- Leave empty to skip subscription registration

### Building

**KVM Build:**
```bash
cd "RHEL 10/KVM"
packer init .
packer build -var-file="../../common/variables/KVM.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

**VMware Build:**
```bash
cd "RHEL 10/VMware"
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
| **Template Conversion** | Manual (with metadata) | Automatic |
| **SSH Timeout** | 20m | 10m |
| **Storage Driver** | Native virtio | Paravirtual SCSI |
| **CPU Model** | host | N/A (ESXi handles) |

## Boot Command

Both configurations use the same Kickstart boot sequence:
1. Press Up arrow key
2. Press 'e' to edit GRUB entry
3. Navigate to kernel line end
4. Append: ` text inst.ks=cdrom:/ks.cfg`
5. Press Enter and Ctrl+X to boot

The Kickstart configuration is provided via CD-ROM labeled "cidata".

## Provisioning Scripts

Both builds execute the following provisioning scripts in order:
1. **setup.sh** - Initial system setup and configuration
2. **kvm.sh** or **vmware.sh** - Hypervisor-specific optimizations
3. **runonce.sh** - Final configuration steps executed from CD-ROM
4. **cleanup.sh** - Clean up temporary files and prepare for templating (runs last)

## Red Hat Subscription Manager

To register the system with RHSM during build, configure:
```hcl
rhsm_username = "your-rhsm-username"
rhsm_password = "your-rhsm-password"
```

Leave empty to skip RHSM registration (useful for evaluation or development).

## Notes

- **Full DVD Required**: The ISO must be the full DVD image, not the boot ISO
- **Kickstart Installation**: Uses text mode installation via Kickstart
- **SSH Access**: Requires network connectivity during build
- **VirtIO drivers (KVM)**: Provide near-native performance
- **PVSCSI (VMware)**: Optimized for high I/O workloads
- **EFI boot mode**: Required for both platforms
- **Metadata Generation (KVM)**: Creates metadata.json for template management
