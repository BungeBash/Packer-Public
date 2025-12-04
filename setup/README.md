# KVM/QEMU Server Setup Ansible Playbook

This Ansible playbook automates the setup of a KVM/QEMU virtualization server with NFS-mounted VM templates storage. The playbook is designed to run locally on the target system.

## Prerequisites

- Ansible 2.9 or higher installed on the system
- Ubuntu/Debian-based system
- Sudo privileges
- NFS server accessible from this system (for VM templates storage)

## Installation

1. Install required Ansible collections:
```bash
ansible-galaxy collection install community.libvirt
```

## Configuration

### Customize Variables

Edit `vars.yml` to match your environment:

**Key Variables to Customize:**

- `nfs_server`: IP address or FQDN of your NFS server
- `nfs_templates_share`: NFS export path for VM templates
- `templates_mount`: Local mount point for templates NFS share
- `build_directory`: Directory for build artifacts
- `iso_directory`: Directory for ISO files
- `drivers_directory`: Directory for Virtio drivers
- `virtio_iso_url`: URL to download VirtIO drivers ISO
- `target_user`: User to add to virtualization groups (defaults to current user)

Example vars.yml:
```yaml
---
nfs_server: "192.168.1.100"  # or "nfs.example.com"
nfs_templates_share: "/mnt/storage/vme-nfs"
build_directory: "/build"
target_user: "myusername"
```

## Usage

### Run the playbook:
```bash
# With vars file
ansible-playbook kvm-server-setup.yml -e @vars.yml

# Or with inline variables
ansible-playbook kvm-server-setup.yml \
  -e "nfs_server=192.168.1.100" \
  -e "build_directory=/build"
```

### Check mode (dry run):
```bash
ansible-playbook kvm-server-setup.yml -e @vars.yml --check
```

## What This Playbook Does

1. **Package Installation**: Installs KVM, QEMU, libvirt, and related virtualization tools
2. **User Configuration**: Adds specified user to libvirt, kvm, and libvirt-qemu groups
3. **Service Setup**: Enables and starts libvirtd service
4. **NFS Mount**: Mounts NFS share for VM templates storage (persistent via /etc/fstab)
5. **Directory Structure**: Creates ISO and drivers directories with proper permissions and ACLs
6. **Build Directory** Creates build directory
7. **QEMU Bridge**: Configures QEMU bridge networking
8. **Libvirt Network**: Starts and enables the default libvirt network
9. **VirtIO Drivers**: Downloads and extracts VirtIO storage drivers

## Packer ISO Caching

**Note**: This playbook does NOT configure a separate Packer cache mount. Packer will use its default cache location: `~/.cache/packer/`

This is the recommended approach because:
- Packer handles caching automatically
- No NFS overhead for ISO downloads
- Simpler configuration
- Works perfectly for single-system builds

If you need shared ISO caching across multiple build servers, you can manually configure Packer to use a shared directory.

## GitHub Actions Self-Hosted Runner

If you need to set up a GitHub Actions self-hosted runner on this system, follow the official GitHub documentation:

**Setup Instructions**: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners

**Quick Steps**:
1. Go to your GitHub repository → Settings → Actions → Runners → New self-hosted runner
2. Follow the provided commands to download and configure the runner
3. **Important**: Ensure the runner user is added to these groups:
   ```bash
   sudo usermod -aG libvirt,kvm,libvirt-qemu actions-runner
   ```
4. Grant the runner user ACL permissions to required directories:
   ```bash
   sudo setfacl -R -m u:actions-runner:rwx /build /isos /drivers
   sudo setfacl -R -d -m u:actions-runner:rwx /build /isos /drivers
   ```

## Permission Model & Best Practices

This playbook implements a security-focused permission model using Linux ACLs and group-based access:

### Directory Permissions Structure

All shared directories (`/build`, `/isos`, `/drivers`) use:
- **Owner**: `root`
- **Group**: `libvirt`
- **Mode**: `2775` (setgid bit ensures files inherit the libvirt group)
- **Default ACLs**: Grant libvirt group rwx permissions on new files

### User Access Model

**Target User** (e.g., your admin user):
- Member of: `libvirt`, `kvm`, `libvirt-qemu` groups
- Can create VMs, manage libvirt, and access shared directories

**Additional Users/Automation** (e.g., GitHub Actions runners):
- Add to same groups: `libvirt`, `kvm`, `libvirt-qemu`
- Grant additional ACLs if needed for specific directories

### Why This Model?

- **Security**: Avoids 777 permissions that allow any user to write
- **Isolation**: Service accounts run as separate users, not root
- **Compatibility**: Both human users and automation can work together
- **Auditability**: Clear ownership and group membership
- **Flexibility**: ACLs allow fine-grained control without changing base permissions

### Verifying Permissions

```bash
# Check directory permissions
ls -ld /build /isos /drivers

# Check ACLs
getfacl /build

# Verify group membership
groups your_username

# Test libvirt access
virsh list --all
```

## Directory Structure Created

```
/
├── build/                    # Build directory if build_directory is defined
│                             # (2775, group: libvirt, with ACLs)
├── drivers/                  # VirtIO and other drivers (2775, group: libvirt, with ACLs)
│   └── viostor/             # VirtIO storage drivers
├── isos/                     # Local ISO storage (2775, group: libvirt, with ACLs)
│   └── virtio-win.iso       # VirtIO drivers ISO
└── vme-nfs/                 # NFS mount for VM templates storage
    └── templates/           # VM templates directory
```

**Permission Notes:**
- Directories use mode `2775` (setgid) to ensure new files inherit the `libvirt` group
- Default ACLs ensure consistent permissions for new files
- Users in the libvirt group have proper access via group membership and ACLs
- Build directory is only created if you uncomment `build_directory` in vars.yml

**Packer Cache:**
- Packer uses its default cache: `~/.cache/packer/`
- No NFS mount needed for Packer ISOs
- Automatic and maintenance-free

## Troubleshooting

### NFS Mount Issues
- Verify NFS server is accessible: `ping 192.168.1.100` (or use your FQDN)
- Check NFS exports on server: `showmount -e 192.168.1.100`
- Test manual mount: `sudo mount -t nfs 192.168.1.100:/mnt/storage/vme-nfs /tmp/test`

### Libvirt Network Issues
- Check network status: `sudo virsh net-list --all`
- Start network manually: `sudo virsh net-start default`
- View network configuration: `sudo virsh net-dumpxml default`

### Permission Issues
- Verify user is in correct groups: `groups $USER`
- Check if you've logged out/in after group changes
- Verify qemu-bridge-helper permissions: `ls -l /usr/lib/qemu/qemu-bridge-helper`
- Check directory ACLs: `getfacl /build /isos /drivers`
- Verify libvirt group can write: `touch /build/test && rm /build/test`

## Customization Examples

### Using FQDN for NFS Server
```yaml
# vars.yml
nfs_server: "nfs.example.com"  # Use FQDN instead of IP
nfs_templates_share: "/exports/vm-templates"
```

### Custom Directory Locations
```yaml
# vars.yml
build_directory: "/opt/builds"  # Uncomment to create
iso_directory: "/opt/isos"
drivers_directory: "/opt/drivers"
templates_mount: "/mnt/vm-templates"
```

### Different User
```bash
ansible-playbook kvm-server-setup.yml -e @vars.yml -e "target_user=otheruser"
```

## Security Considerations

### Directory Permissions
- Directories use `2775` with `libvirt` group for controlled access
- ACLs provide fine-grained access control
- Only members of `libvirt` group can write to shared directories
- Consider using `noexec` on NFS mounts if security is a concern

### NFS Security
- Consider restricting NFS mount options:
  ```yaml
  # In your vars file
  nfs_mount_opts: "defaults,nosuid,nodev"
  ```
- Use NFSv4 with Kerberos authentication for production environments
- Restrict NFS exports on the server side to specific IPs

### User Isolation
- Service accounts (like GitHub Actions runners) should run as dedicated users
- Add service users to appropriate groups for libvirt access
- Use ACLs to grant specific permissions without changing base directory permissions

## License

This playbook is provided as-is for system configuration purposes.
