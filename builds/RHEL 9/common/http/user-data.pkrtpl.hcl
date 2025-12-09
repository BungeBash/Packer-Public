#cloud-config
autoinstall:
  version: 1
  locale: en_US
  keyboard:
    layout: us
  packages:
    - wget
    - vim
    - net-tools
    - jq
    - openssh-server
    - unattended-upgrades
    - apt-transport-https
    - cloud-initramfs-growroot
    - cloud-guest-utils
  identity:
    hostname: ubuntu-2404
    username: "${template_username}"
    password: "${template_password}"
  ssh:
    install-server: true
    allow-pw: true
    disable_root: true
  network:
    network:
      version: 2
      ethernets:
        any:
          match:
            name: en*
          dhcp4: true
  storage:
    config:
      # --- Disk definition ---
      - id: disk0
        type: disk
        match:
          size: largest
        ptable: gpt
        wipe: superblock-recursive
        preserve: false
        grub_device: false

      # --- EFI Partition ---
      - id: part-efi
        type: partition
        device: disk0
        size: 512M
        flag: esp
        grub_device: true

      # --- /boot Partition ---
      - id: part-boot
        type: partition
        device: disk0
        size: 1G

      # --- LVM PV Partition ---
      - id: part-lvm
        type: partition
        device: disk0
        size: -1

      # --- Volume Group ---
      - id: vg0
        type: lvm_volgroup
        name: vg0
        devices:
          - part-lvm

      # --- Swap LV ---
      - id: lv-swap
        type: lvm_partition
        volgroup: vg0
        name: swap
        size: 2G

      # --- Root LV ---
      - id: lv-root
        type: lvm_partition
        volgroup: vg0
        name: root
        size: -1

      # --- EFI Filesystem ---
      - id: fs-efi
        type: format
        volume: part-efi
        fstype: fat32

      # --- Boot Filesystem ---
      - id: fs-boot
        type: format
        volume: part-boot
        fstype: ext4

      # --- Swap Format ---
      - id: fs-swap
        type: format
        volume: lv-swap
        fstype: swap

      # --- Root Filesystem ---
      - id: fs-root
        type: format
        volume: lv-root
        fstype: ext4

      # --- Mount points ---
      - id: mount-efi
        type: mount
        device: fs-efi
        path: /boot/efi

      - id: mount-boot
        type: mount
        device: fs-boot
        path: /boot

      - id: mount-root
        type: mount
        device: fs-root
        path: /