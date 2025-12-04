# Quick Start Guide

Get your KVM virtualization server up and running in 5 minutes.

## Prerequisites Check

```bash
# Verify you have Ansible
ansible --version  # Need 2.9+
```

## Step 1: Install Ansible Collection

```bash
ansible-galaxy collection install community.libvirt
```

## Step 2: Configure Your Environment

### Create your vars file
```bash
cat > vars.yml << 'EOF'
---
# Your NFS server (IP or FQDN)
nfs_server: "192.168.1.100"
nfs_templates_share: "/mnt/storage/vme-nfs"

# Uncomment if you need a build directory
# build_directory: "/build"

# User to configure (defaults to current user)
target_user: "{{ ansible_user }}"
EOF
```

## Step 3: Deploy

```bash
ansible-playbook kvm-server-setup.yml -e @vars.yml
```

## Common Commands After Installation

```bash
# List all VMs
virsh list --all

# Check libvirt status
sudo systemctl status libvirtd

# View NFS mounts
df -h | grep nfs

# Check runner status (if installed)
sudo systemctl status actions.runner.*

# View directory permissions
ls -ld /build /isos /drivers
getfacl /build
```

## Troubleshooting Quick Fixes

### Can't Write to /isos or /drivers Directory
```bash
# Verify group membership
groups

# If missing groups, re-run playbook
ansible-playbook kvm-server-setup.yml -e @vars.yml

# Log out and back in
```

### NFS Mount Failed
```bash
# Test connectivity to NFS server
ping 192.168.1.100

# Check NFS exports
showmount -e 192.168.1.100

# Manually test mount
sudo mount -t nfs 192.168.1.100:/mnt/storage/vme-nfs /tmp/test
ls /tmp/test
sudo umount /tmp/test
```

## Default Locations Reference

| Purpose | Location | Permissions |
|---------|----------|-------------|
| VM Builds | `/build` (optional) | 2775, group: libvirt |
| ISO Files | `/isos` | 2775, group: libvirt |
| Drivers | `/drivers` | 2775, group: libvirt |
| VM Templates | `/vme-nfs` | NFS mount |
| Packer Cache | `~/.cache/packer/` | Auto-managed by Packer |

## Next Steps

1. **Create your first VM**: Use Packer or virt-install
2. **Configure VM templates**: Store in `/vme-nfs/templates`
3. **Set up automation**: GitHub Actions workflows can now build VMs
4. **Monitor resources**: `virt-top` or `virsh nodeinfo`
5. **Backup strategy**: Configure VM snapshots and backups

## Getting Help

- Full documentation: `README.md`
- Detailed changes: `SUMMARY.md`
- Run validation: `./validate-setup.sh`
- Check logs: `journalctl -xe`

## One-Liner Commands

```bash
# Full installation
ansible-galaxy collection install community.libvirt && \
ansible-playbook kvm-server-setup.yml -e @vars.yml

# Quick status check
systemctl is-active libvirtd && virsh list --all

# Check Packer cache
du -sh ~/.cache/packer/
```

## Setting Up GitHub Actions Runner

If you need a self-hosted GitHub Actions runner:

1. **Go to GitHub**: `https://github.com/YOUR_ORG/YOUR_REPO/settings/actions/runners/new`
2. **Follow the setup instructions** provided by GitHub
3. **Add runner user to groups**:
   ```bash
   sudo usermod -aG libvirt,kvm,libvirt-qemu <runner-username>
   ```
4. **Grant ACL permissions**:
   ```bash
   sudo setfacl -R -m u:<runner-username>:rwx /build /isos /drivers
   sudo setfacl -R -d -m u:<runner-username>:rwx /build /isos /drivers
   ```

---

**That's it!** Your KVM server should now be ready for VM builds.
