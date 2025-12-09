#!/usr/bin/env bash
set -euxo pipefail

echo "[+] Ensuring no package operations are in progress"

# Finish any interrupted or pending dpkg configuration
dpkg --configure -a || true
apt-get -f install -y || true

echo "[+] Cleaning APT caches and lists"
apt-get -y autoremove || true
apt-get -y clean || true
rm -rf /var/lib/apt/lists/* /var/cache/apt/* || true

echo "[+] Removing cloud-init instance data"
cloud-init clean --logs || true
rm -rf /var/lib/cloud/* || true

echo "[+] Removing SSH host keys - will be re-generated on first real boot"
rm -f /etc/ssh/ssh_host_* || true

# --- MACHINE-ID CLEANUP (Consolidated here) ---
echo "[+] Removing machine-id files"
# Truncate the standard machine-id file
truncate -s 0 /etc/machine-id || true
# Ensure the dbus symlink points correctly to the truncated file, creating it if necessary
rm -f /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id || true
# --- END MACHINE-ID CLEANUP ---

echo "[+] Cleaning logs"
find /var/log -type f -exec truncate -s 0 {} \; || true

echo "[+] Removing shell history"
unset HISTFILE
rm -f /root/.bash_history || true
if [ -n "${HOME:-}" ]; then
  rm -f /home/*/.bash_history || true
fi

echo "[+] Remove udev persistent net rules"
rm -f /etc/udev/rules.d/70-persistent-net.rules || true

echo "[+] Clearing dhcp leases"
rm -f /var/lib/dhcp/* || true

echo "[+] Zero out free space (optional - commented out; enable if you want smaller sparse image)"
dd if=/dev/zero of=/zerofile bs=1M || true
sync
rm -f /zerofile
sync

echo "[+] Waiting for apt/dpkg locks to clear..."
for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/debconf/config.dat; do
  while fuser "$lock" >/dev/null 2>&1; do
    echo "[-] Lock held by process, waiting 5 seconds..."
    sleep 5
  done
done
echo "[+] Apt/dpkg locks are clear, finalizing..."

echo "[+] Final sync"
sync