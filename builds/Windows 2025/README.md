# Windows Server 2025 Packer Build

This directory contains Packer configurations for building Windows Server 2025 images for both KVM and VMware hypervisors.

## Overview

- **OS Version**: Windows Server 2025 Datacenter
- **Installation Method**: Automated (Autounattend.xml)
- **Communicator**: WinRM (port 5985)
- **Supported Hypervisors**: KVM/QEMU, VMware vSphere
- **License**: Evaluation mode enabled by default

## Directory Structure

```
Windows 2025/
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
- **Firmware**: EFI/UEFI
- **vTPM**: Enabled
- **ISO Checksum**: `D0EF4502E350E3C6C53C15B1B3020D38A5DED011BF04998E950720AC8579B23D`
- **Locale**: en-US keyboard, language, UTC timezone
- **Edition**: Windows Server 2025 SERVERDATACENTER

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
- **Driver Path**: `/drivers/viostor/2k25/amd64`

### Build Settings
- **Headless Mode**: Enabled
- **Communicator Timeout**: 20 minutes
- **Shutdown Timeout**: 10 minutes

### Boot Command
```
<spacebar>
```
Boot wait: 5 seconds

### Shutdown
- **Shutdown Drive**: F: drive
- **Command**: `powershell.exe -ExecutionPolicy Bypass -File "F:\shutdown.ps1"`

### Key Features
- VirtIO drivers optimized for Server 2025
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
- **Guest OS Type**: windows2022srvNext_64Guest
- **vTPM**: Enabled

### Timeouts
- **IP Wait Timeout**: 20 minutes
- **SSH Timeout**: 20 minutes
- **Shutdown Timeout**: 10 minutes

### Boot Command
```
<spacebar>
```

### Shutdown
- **Shutdown Drive**: A: drive
- **Command**: `powershell.exe -ExecutionPolicy Bypass -File "A:\shutdown.ps1"`

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
# OVMF UEFI firmware
# QEMU/KVM installed
# VirtIO drivers ISO available at /isos/virtio-win.iso
# Windows Server 2025 ISO
# WinRM configured for communication
```

**For VMware:**
```bash
# VMware vSphere/ESXi 8.0+ (recommended for Server 2025)
# vTPM 2.0 support enabled on cluster
# Network access to vCenter/ESXi host
# Credentials configured in common variables
```

### Building

**KVM Build:**
```bash
cd "Windows 2025/KVM"
packer init .
packer build -var-file="../../common/variables/KVM.pkrvars.hcl" \
             -var-file="variables.pkrvars.hcl" \
             image.pkr.hcl
```

**VMware Build:**
```bash
cd "Windows 2025/VMware"
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
| **Driver Path** | /drivers/viostor/2k25/amd64 | N/A |
| **Hot-Add** | Not configured | CPU & Memory enabled |
| **Template Conversion** | Manual | Automatic |
| **Communicator Timeout** | 20m | Uses IP wait (20m) |
| **Boot Command** | 1x spacebar | 1x spacebar |
| **Shutdown Drive** | F: drive | A: drive |
| **Video RAM** | Not specified | 16384 MB |
| **Guest OS Type** | N/A | windows2022srvNext_64Guest |

## Available Editions

This build is configured for:
- **Windows Server 2025 Datacenter** with Desktop Experience

Product key can be configured via:
- `vm_inst_os_key_datacenter` - For Datacenter edition

Leave empty for evaluation mode (default).

## Important Notes

### VirtIO Drivers (KVM)
- Must be injected during Windows installation for storage and network
- Server 2025 uses dedicated driver path: `/drivers/viostor/2k25/amd64`
- Ensure VirtIO driver ISO is up-to-date for Server 2025 compatibility

### Shutdown Script Location
- **KVM**: Uses F: drive (different from Windows 11)
- **VMware**: Uses A: drive (consistent with Windows 11)
- Ensure shutdown scripts are placed in the correct drive location

### VMware Compatibility
- Guest OS type uses `windows2022srvNext_64Guest` (Server 2025 designation)
- Requires ESXi 8.0 or later for full feature support
- vTPM 2.0 required for modern security features

### Communicator Timeouts
- KVM: 20 minutes (shorter than Windows 11's 30m)
- VMware: 20 minutes IP wait timeout
- Adjust if installation takes longer in your environment

### Windows Updates
- Automatically applied during build
- Preview updates excluded by default
- Limit of 25 updates per cycle to prevent excessive build times
- May require multiple update passes for fresh installations

## System Requirements

Both configurations meet Windows Server 2025 requirements:
- UEFI firmware (EFI boot)
- TPM 2.0 support (vTPM enabled)
- 4 GB RAM minimum (8 GB configured)
- 32 GB storage minimum (30 GB configured)

## Evaluation Period

Windows Server 2025 evaluation licenses typically provide:
- 180 days evaluation period
- Full feature access during evaluation
- Can be converted to licensed version with product key
