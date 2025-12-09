#!/usr/bin/env bash
set -euxo pipefail

echo "[+] Unregistering from Red Hat Subscription Manager"
# Unregister from RHSM if registered
if command -v subscription-manager >/dev/null 2>&1; then
  subscription-manager unregister 2>/dev/null || echo "[!] System was not registered with RHSM"
  subscription-manager clean || true
fi

echo "[+] Cleaning up Anaconda Logs"
rm -rf /root/anaconda-ks.cfg

echo "[+] Cleaning DNF/YUM caches"
dnf clean all
rm -rf /var/cache/dnf/* /var/cache/yum/*

echo "[+] Removing kickstart configuration from GRUB"
# Remove inst.ks boot parameter from grub config
if [ -f /etc/default/grub ]; then
  sed -i 's/ inst\.ks=[^ ]*//g' /etc/default/grub
  sed -i 's/ text//g' /etc/default/grub
  # Regenerate grub config
  if [ -f /boot/efi/EFI/redhat/grub.cfg ]; then
    grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg || true
  elif [ -f /boot/grub2/grub.cfg ]; then
    grub2-mkconfig -o /boot/grub2/grub.cfg || true
  fi
fi

echo "[+] Removing SSH host keys - will be regenerated on first boot"
rm -f /etc/ssh/ssh_host_* || true

echo "[+] Removing machine-id files"
truncate -s 0 /etc/machine-id || true
rm -f /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id || true

echo "[+] Cleaning logs"
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true

echo "[+] Removing shell history"
unset HISTFILE
rm -f /root/.bash_history || true
rm -f /home/*/.bash_history 2>/dev/null || true

echo "[+] Remove udev persistent net rules"
rm -f /etc/udev/rules.d/70-persistent-net.rules || true

echo "[+] Clearing DHCP leases"
rm -f /var/lib/dhclient/* || true
rm -f /var/lib/dhcp/* || true
rm -f /var/lib/NetworkManager/* || true

echo "[+] Remove subscription manager data (if not subscribed)"
if [ -d /etc/pki/entitlement ]; then
  rm -rf /etc/pki/entitlement/* || true
fi
rm -rf /var/lib/rhsm/* || true

echo "[+] Clean RPM database"
rpm --rebuilddb || true

echo "[+] Zero out free space to reduce template size"
dd if=/dev/zero of=/zerofile bs=1M 2>/dev/null || true
sync
rm -f /zerofile
sync

echo "[+] Final sync"
sync
