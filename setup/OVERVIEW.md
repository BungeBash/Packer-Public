# KVM Server Setup - Ansible Playbook

## Files Included

1. **kvm-server-setup.yml** - Main Ansible playbook for local execution
2. **vars.yml** - Variables file template
3. **README.md** - Complete documentation
4. **QUICKSTART.md** - 5-minute setup guide
5. **Makefile** - Convenience commands

## Quick Start

1. Install Ansible collection:
   ```bash
   ansible-galaxy collection install community.libvirt
   ```

2. Edit vars.yml with your settings:
   ```bash
   vi vars.yml
   ```

3. Run the playbook:
   ```bash
   ansible-playbook kvm-server-setup.yml -e @vars.yml
   ```

## Key Features

- ✅ Runs locally on the target system (hosts: localhost)
- ✅ Secure permissions using group-based ACLs (no 777 permissions)
- ✅ Single NFS mount for VM templates storage
- ✅ Packer uses default cache (~/.cache/packer/)
- ✅ VirtIO drivers automatically downloaded
- ✅ Proper user group configuration
- ✅ Optional build directory
- ✅ Idempotent (safe to run multiple times)
- ✅ Comprehensive validation script

## GitHub Actions Runner Setup

> [!NOTE] - 
> Only Required if using Github Actions Runner AND ther runner service is a different user than Ansible playbook configured user

This playbook does NOT install GitHub Actions runners automatically. If you need a self-hosted runner:

1. Follow GitHub's official instructions: https://docs.github.com/en/actions/hosting-your-own-runners
2. After setup, add the runner user to required groups:
   ```bash
   sudo usermod -aG libvirt,kvm,libvirt-qemu <runner-user>
   ```
3. Grant ACL permissions:
   ```bash
   sudo setfacl -R -m u:<runner-user>:rwx /build /isos /drivers
   sudo setfacl -R -d -m u:<runner-user>:rwx /build /isos /drivers
   ```

## Directory Permissions

All directories use secure group-based permissions:
- Owner: root
- Group: libvirt
- Mode: 2775 (setgid bit for group inheritance)
- ACLs: Default ACLs for consistent permissions

**Build directory** is optional - only created if you define `build_directory` in vars.yml

## Packer Cache

Packer uses its default cache location: `~/.cache/packer/`
- No NFS configuration needed
- Automatic caching
- Per-user isolation

## Documentation

- **Quick Start**: See QUICKSTART.md for rapid deployment
- **Full Guide**: See README.md for complete documentation
- **Commands**: Run `make help` for available shortcuts

## Requirements

- Ubuntu/Debian-based system
- Ansible 2.9+
- Sudo privileges
- NFS server (for shared storage)

---

For detailed information, see **README.md**
