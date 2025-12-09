#!/bin/bash
set -e

# Detect OS and ensure growpart is available
if [ -f /etc/redhat-release ]; then
    # RHEL/CentOS
    if ! command -v growpart &> /dev/null; then
        sudo yum install -y cloud-utils-growpart
    fi
elif [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    if ! command -v growpart &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y cloud-guest-utils
    fi
fi

# Create the cleanup script
cat <<'EOF' | sudo tee /usr/local/bin/packer-cleanup.sh
#!/bin/bash
set -e

# Resize LVM
PART=$(pvs --noheadings -o pv_name,vg_name | grep vg0 | awk '{print $1}' | tr -d ' ')
DISK=$(lsblk -ndo PKNAME $PART)
PARTNUM=$(echo $PART | grep -o '[0-9]*$')
growpart /dev/$DISK $PARTNUM || true
pvresize $PART
lvextend -l +100%FREE /dev/vg0/root
resize2fs /dev/vg0/root

# Cleanup User
userdel -rf ${template_username} || true
rm -f /etc/sudoers.d/${template_username}

# Remove this script and service
systemctl disable packer-cleanup.service
rm -f /etc/systemd/system/packer-cleanup.service
rm -f /usr/local/bin/packer-cleanup.sh
EOF

sudo chmod +x /usr/local/bin/packer-cleanup.sh

# Create the systemd service
cat <<'EOF' | sudo tee /etc/systemd/system/packer-cleanup.service
[Unit]
Description=Packer Template First Boot Cleanup
After=multi-user.target
ConditionPathExists=/usr/local/bin/packer-cleanup.sh

[Service]
Type=oneshot
ExecStart=/usr/local/bin/packer-cleanup.sh
RemainAfterExit=no
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable packer-cleanup.service
