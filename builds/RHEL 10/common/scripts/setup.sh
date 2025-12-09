#!/usr/bin/env bash
set -euxo pipefail

# --- Wait for yum/dnf locks to clear ---
echo "[+] Waiting for package manager locks to clear..."
while systemctl is-active dnf-makecache.service >/dev/null 2>&1 || \
      systemctl is-active packagekit.service >/dev/null 2>&1; do
  echo "[-] Package manager service active, waiting 5 seconds..."
  sleep 5
done
echo "[+] Package manager is ready."

# Update system
echo "[+] Updating system packages"
dnf update -y
dnf install -y vim cloud-init

# Configure SELinux (ensure it's enforcing)
echo "[+] Ensuring SELinux is in enforcing mode"
setenforce 1 || true
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# SSH hardening
echo "[+] Hardening SSH configuration"
SSHD="/etc/ssh/sshd_config"
cp -a "${SSHD}" "${SSHD}.orig"

# Apply CIS-style SSH hardening
cat >> "${SSHD}" <<'EOF'

# Packer hardening
PermitRootLogin no
PermitEmptyPasswords no
PasswordAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
EOF

# Validate and restart SSH
sshd -t && systemctl restart sshd || echo "[!] SSH config validation failed"

# Firewalld configuration (minimal - SSH only)
echo "[+] Configuring firewalld"
systemctl enable --now firewalld
firewall-cmd --set-default-zone=public
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --reload

# Sysctl hardening
echo "[+] Applying sysctl hardening"
cat > /etc/sysctl.d/99-packer-hardening.conf <<'EOF'
# Disable IPv6 (if not needed)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# IP forwarding (disabled for non-router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# ICMP hardening
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

sysctl --system

# Configure auditd
echo "[+] Enabling and configuring auditd"
systemctl enable auditd
systemctl start auditd

# Add basic audit rules (using new style format)
cat > /etc/audit/rules.d/packer-audit.rules <<'EOF'
# Monitor authentication events
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock -p wa -k logins

# Monitor user/group modifications
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity

# Monitor sudo usage
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d -p wa -k sudoers

# Monitor SSH configuration
-w /etc/ssh/sshd_config -p wa -k sshd
EOF

# Reload audit rules
augenrules --load 2>/dev/null || service auditd restart

# Lock root account
echo "[+] Locking root account"
passwd -l root

# Remove unnecessary services
echo "[+] Disabling unnecessary services"
for service in postfix avahi-daemon cups; do
  systemctl disable $service 2>/dev/null || true
  systemctl stop $service 2>/dev/null || true
done

# Create first-boot service for SSH key regeneration
echo "[+] Creating first-boot cleanup service"
cat > /usr/local/sbin/packer-firstboot-cleanup <<'EOF'
#!/bin/bash
set -euo pipefail

# Regenerate SSH host keys
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A

# Rebuild RPM database (ensures clean state)
rpm --rebuilddb

# Cloud-init cleanup
if command -v cloud-init >/dev/null 2>&1; then
  cloud-init clean --logs --machine-id --seed
fi

# Disable and remove this service
systemctl disable packer-firstboot.service
rm -f /etc/systemd/system/packer-firstboot.service
rm -f /usr/local/sbin/packer-firstboot-cleanup
EOF

chmod +x /usr/local/sbin/packer-firstboot-cleanup

cat > /etc/systemd/system/packer-firstboot.service <<'EOF'
[Unit]
Description=Packer first boot cleanup
After=network-online.target
Before=sshd.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/packer-firstboot-cleanup
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable packer-firstboot.service

# Set secure permissions
echo "[+] Setting secure file permissions"
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/passwd /etc/group
chmod 600 /etc/shadow /etc/gshadow

echo "[+] RHEL provisioning complete"
sync