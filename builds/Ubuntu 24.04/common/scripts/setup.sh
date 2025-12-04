#!/usr/bin/env bash
set -euxo pipefail

# Ensure sudo non-interactive
export DEBIAN_FRONTEND=noninteractive

# --- NEW: Wait for apt locks to clear before provisioning ---
echo "[+] Waiting for apt/dpkg locks to clear..."
for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/debconf/config.dat; do
  while fuser "$lock" >/dev/null 2>&1; do
    echo "[-] Lock held by process, waiting 5 seconds..."
    sleep 5
  done
done
echo "[+] Apt/dpkg locks are clear, continuing with provisioning."
# --- END NEW ---

echo "[+] Updating apt and upgrading packages"
sudo apt-get update -y; sudo apt upgrade -y; sudo apt dist-upgrade -y

echo "[+] Installing recommended security packages"
apt-get -y install --no-install-recommends \
  ca-certificates gnupg lsb-release auditd

# NOTE: The configuration for unattended-upgrades is commented out to prevent
# race conditions when the new VM boots. Updates should be handled by cloud-init/user-data.
# dpkg-reconfigure -f noninteractive unattended-upgrades || true

# SSH hardening
echo "[+] Harden SSH configuration"
SSHD="/etc/ssh/sshd_config"

# Backup original
cp -a "${SSHD}" "${SSHD}.orig"

# Minimal secure settings
sed -i -E 's/^#?PermitRootLogin.*/PermitRootLogin no/' "${SSHD}"
echo "PermitEmptyPasswords no" >> "${SSHD}"

# Restart sshd
systemctl restart sshd || true

# UFW firewall (commented out as before)

# Sysctl hardening (safe defaults)
echo "[+] Tuning sysctl"
cat > /etc/sysctl.d/99-packer-hardening.conf <<'EOF'
# Network: protect against spoofing, syn flood
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
# IPv4 forwarding disabled (set to 1 if building router)
net.ipv4.ip_forward = 0

# ICMP
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Reduce netfilter connection tracking memory usage
net.netfilter.nf_conntrack_max = 262144
EOF

sysctl --system || true

# Audit basic permissions
echo "[+] Set secure permissions for /etc/ssh"
chmod 644 /etc/ssh/sshd_config || true

# Lock root account and remove password
echo "[+] Locking root account"
passwd -l root || true

# Create a first-boot service to regenerate SSH host keys
# NOTE: Removed machine-id logic from here, moved entirely to cleanup.sh
echo "[+] Creating first-boot unit to regenerate host keys"
/usr/bin/tee /usr/local/sbin/packer-firstboot-cleanup <<'EOF' > /dev/null
#!/bin/bash
set -euo pipefail

# remove existing SSH host keys
rm -f /etc/ssh/ssh_host_*

# regenerate
dpkg-reconfigure openssh-server || true

# cloud-init cleanup (so instance will run cloud-init on real first boot)
# This internal cloud-init clean command handles its own machine-id cleanup internally as well
cloud-init clean --logs --reboot || true

# disable this service
systemctl disable packer-firstboot.service || true
rm -f /etc/systemd/system/packer-firstboot.service

# exit 0
# EOF

# chmod +x /usr/local/sbin/packer-firstboot-cleanup

# cat > /etc/systemd/system/packer-firstboot.service <<'EOF'
# [Unit]
# Description=Packer firstboot cleanup
# After=network.target

# [Service]
# Type=oneshot
# ExecStart=/usr/local/sbin/packer-firstboot-cleanup

# [Install]
# WantedBy=multi-user.target
# EOF

# systemctl enable packer-firstboot.service || true

# Ensure auditd is running
systemctl enable auditd || true

echo "[+] Syncing and finishing provisioning"
sync