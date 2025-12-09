# Storage configuration
# Clear all existing partitions
clearpart --all --initlabel

# Use disk autoselection or specify with --drives=sda
# ignoredisk --only-use=sda

# Create partitions
# --ondisk=sda
part /boot/efi --fstype=efi --size=600
part /boot --fstype=xfs --size=1024
part pv.01 --size=1 --grow

# Create volume group
volgroup vg0 pv.01

# Create logical volumes following best practices
logvol swap --fstype=swap --name=swap --vgname=vg0 --recommended
# logvol /home --fstype=xfs --name=home --vgname=vg0 --size=5120 --fsoptions="nodev"
# logvol /tmp --fstype=xfs --name=tmp --vgname=vg0 --size=5120 --fsoptions="nodev,nosuid,noexec"
# logvol /var --fstype=xfs --name=var --vgname=vg0 --size=10240
# logvol /var/log --fstype=xfs --name=var_log --vgname=vg0 --size=5120
# logvol /var/log/audit --fstype=xfs --name=var_log_audit --vgname=vg0 --size=2048
# logvol /var/tmp --fstype=xfs --name=var_tmp --vgname=vg0 --size=5120 --fsoptions="nodev,nosuid,noexec"
logvol / --fstype=xfs --name=root --vgname=vg0 --percent=100