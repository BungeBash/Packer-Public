# Makefile for KVM Server Setup
# Simplifies common Ansible operations for local execution

.PHONY: help install check validate clean

# Variables
VARS ?= vars.yml
PLAYBOOK = kvm-server-setup.yml

# Default target
help:
	@echo "KVM Server Setup - Available Commands:"
	@echo ""
	@echo "  make install              - Install KVM server on localhost"
	@echo "  make check                - Run playbook in check mode (dry run)"
	@echo "  make validate             - Validate installation"
	@echo "  make show-config          - Display current configuration"
	@echo "  make clean                - Remove temporary files"
	@echo ""
	@echo "Variables you can override:"
	@echo "  VARS=vars.yml             - Path to variables file (default: vars.yml)"
	@echo ""
	@echo "Examples:"
	@echo "  make install"
	@echo "  make install VARS=custom-vars.yml"

# Check if ansible-playbook is available
check-ansible:
	@which ansible-playbook > /dev/null || (echo "Error: ansible-playbook not found. Please install Ansible." && exit 1)

# Check if community.libvirt collection is installed
check-collection:
	@ansible-galaxy collection list | grep -q community.libvirt || \
		(echo "Installing community.libvirt collection..." && \
		ansible-galaxy collection install community.libvirt)

# Install prerequisites
prereqs: check-ansible check-collection
	@echo "✓ Prerequisites checked"

# Run playbook
install: prereqs
	@echo "Installing KVM server on localhost..."
	@if [ -f $(VARS) ]; then \
		ansible-playbook $(PLAYBOOK) -e @$(VARS); \
	else \
		echo "Error: $(VARS) not found. Create a vars file or specify VARS=path/to/vars.yml"; \
		exit 1; \
	fi

# Run in check mode (dry run)
check: prereqs
	@echo "Running playbook in check mode (no changes will be made)..."
	@if [ -f $(VARS) ]; then \
		ansible-playbook $(PLAYBOOK) -e @$(VARS) --check; \
	else \
		echo "Error: $(VARS) not found."; \
		exit 1; \
	fi

# Validate installation
validate:
	@echo "Validating installation..."
	@if [ -f validate-setup.sh ]; then \
		bash validate-setup.sh; \
	else \
		echo "Error: validate-setup.sh not found in current directory"; \
		exit 1; \
	fi

# Show current configuration
show-config:
	@echo "Current Configuration:"
	@echo "  Variables: $(VARS)"
	@echo ""
	@if [ -f $(VARS) ]; then \
		echo "Variables Contents:"; \
		cat $(VARS); \
	else \
		echo "Variables file not found: $(VARS)"; \
	fi

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.retry" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleaned"

# Run full installation with validation
full-install: install validate
	@echo ""
	@echo "================================================"
	@echo "✓ Installation complete and validated!"
	@echo "================================================"
	@echo ""
	@echo "Next steps:"
	@echo "1. Log out and back in for group changes"
	@echo "2. Test: virsh list --all"
	@echo "3. Start creating VMs!"

# Show server status
status:
	@echo "Checking server status..."
	@systemctl is-active libvirtd && echo "✓ libvirtd is running" || echo "✗ libvirtd is not running"
	@echo ""
	@echo "Virtual Machines:"
	@virsh list --all
	@echo ""
	@echo "NFS Mounts:"
	@df -h | grep -E '(nfs|Filesystem)'
