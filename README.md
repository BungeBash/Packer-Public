# Packer Multi-Cloud Image Builder

> ⚠️ **Full Disclosure**: Parts of this documentation were lovingly crafted by our AI overlords. If you find instructions telling you to "simply quantum-entangle your VMs" or "reticulate the splines," that's on me. PRs welcome for corrections! 🤖
>
> 🌐 **Another Disclaimer**: This repo is a merger of examples found across the internet, Reddit, StackOverflow answers at 2 AM, and official docs that may or may not have made sense at the time. I've done my best to generalize everything for public consumption.

## What's This?

A streamlined Packer automation pipeline that builds VM templates across multiple hypervisors (currently KVM and VMware) with GitHub Actions doing the heavy lifting. Think of it as Infrastructure-as-Code meets "I'm tired of clicking through wizards."

## Project Structure

```
Packer/
├── .github/workflows/
│   └── packer.yml              # The orchestration magic
├── builds/
│   ├── common/
│   │   └── variables/
│   │       ├── KVM.pkrvars.hcl     # KVM-specific vars
│   │       └── VMware.pkrvars.hcl  # VMware-specific vars
│   ├── Ubuntu 24.04/
│   │   ├── common/              # Shared configs
│   │   ├── KVM/
│   │   │   ├── image.pkr.hcl
│   │   │   └── variables.pkrvars.hcl
│   │   └── VMware/
│   │       ├── image.pkr.hcl
│   │       └── variables.pkrvars.hcl
│   ├── Windows 11/
│   │   ├── common/
│   │   ├── KVM/
│   │   └── VMware/
│   │       ├── scripts/
│   │       ├── image.pkr.hcl
│   │       └── variables.pkrvars.hcl
│   └── Windows 2025/
└── setup/
    ├── kvm-server-setup.yml     # Ansible playbook for KVM
    ├── Makefile
    ├── OVERVIEW.md
    └── QUICKSTART.md
```

### How It Flows

1. **Common Variables** (`builds/common/variables/`) - Cloud-specific settings that apply across all OS builds
2. **OS-Specific Builds** (`builds/{OS}/{Cloud}/`) - Each OS gets its own directory with cloud-specific subdirectories
3. **Shared Configs** (`builds/{OS}/common/`) - OS-specific files shared between clouds
4. **Setup Directory** - Ansible playbooks and documentation for setting up your build infrastructure

📚 **For detailed documentation on specific builds**, check the README files under `builds/` - each OS has its own quirks and config notes.

## The GitHub Actions Pipeline

### Trigger Happy

The workflow (`packer.yml`) kicks off in two ways:

1. **Automatic**: Push changes to any `builds/**` directory (except folders named like`*-archived` or READMEs)
2. **Manual**: Use `workflow_dispatch` to build specific OS/Cloud combos on-demand

### Smart Build Detection

The pipeline is clever enough to:
- Detect which OS/Cloud combinations changed
- Build only what's needed (no wasted cycles)
- Skip archived builds automatically (append `-archived` to any folder name to retire it)

### The Build Matrix

```yaml
# Auto-detects: "Oh, you changed Ubuntu 24.04/KVM? Let me build just that."
# Manual mode: "You want Windows 11 on VMware? Say no more."
```

The setup job scans changed files and generates a dynamic build matrix, so you're never building more than necessary.

### Runner Strategy

Here's where it gets interesting (and slightly hacky):

- **VMware Builds**: Uses `arc-packer` - ARC (Actions Runner Controller) on Kubernetes for dynamic, scalable runners
- **KVM Builds**: Uses `BareMetal2` - A dedicated VM specific to KVM as Packer QEMU doesn't support remote execution (yet) 🤷

### Key Features

- **Caching Strategy**: 
  - On `arc-packer`: Uses shared `/mnt/packer-cache` for ISOs and plugins (saves bandwidth)
  - Elsewhere: GitHub Actions cache for plugins and ISOs
- **Parallel Builds**: Max 5 concurrent builds (`max-parallel: 5`)
- **Fail-Fast Disabled**: One build failing won't kill the others
- **Secrets Management**: Template and cloud credentials via GitHub Secrets
- **Linux Password Hashing**: Auto-generates secure hashed passwords for cloud-init

### Environment Variables

The pipeline sets these automagically:
- `PKR_VAR_template_password` / `PKR_VAR_template_username` - Template VM credentials
- `PKR_VAR_vmware_password` / `PKR_VAR_vmware_username` - VMware vCenter/ESXi creds
- `PKR_VAR_hash_password` - OpenSSL-hashed password for Linux cloud-init

## Supported Platforms

### Currently Supported
- ✅ **Ubuntu 24.04** (KVM & VMware)
- ✅ **Windows 11** (KVM & VMware)
- ✅ **Windows 2025** (KVM & VMware)

### Easily Expandable
The structure is deliberately simple:
1. Add a new OS folder under `builds/`
2. Create `KVM/` and/or `VMware/` subdirectories
3. Drop in your `image.pkr.hcl` and `variables.pkrvars.hcl`
4. Push. The pipeline handles the rest.

Want to add Proxmox? Azure? AWS? Just add the cloud-specific config to `builds/common/variables/` and create the corresponding subdirectories.

## Getting Started

### Prerequisites
- GitHub repository with Actions enabled
- GitHub Secrets configured:
  - `TEMPLATE_PASSWORD` - Password for template VMs
  - `TEMPLATE_USERNAME` - Username for template VMs
  - `VMWARE_PASSWORD` - vCenter/ESXi password (if using VMware)
  - `VMWARE_USERNAME` - vCenter/ESXi username (if using VMware)
- Build infrastructure:
  - **For VMware**: ARC on Kubernetes cluster
  - **For KVM**: Dedicated VM with nested virtualization enabled

### Setting Up KVM Infrastructure

See the `setup/` directory for Ansible playbooks and detailed documentation:
- `QUICKSTART.md` - Get up and running fast
- `OVERVIEW.md` - Deep dive into the setup
- `kvm-server-setup.yml` - Automated KVM host provisioning

### Manual Build

Want to build a specific combo without waiting for a git push?

1. Go to **Actions** → **Packer Changed Builds**
2. Click **Run workflow**
3. Select your OS and Cloud platform
4. Watch the magic happen ✨

### Automatic Builds

Just push changes to any build directory:
```bash
# This will trigger Ubuntu 24.04 KVM build
vim builds/Ubuntu\ 24.04/KVM/image.pkr.hcl
git commit -am "Updated Ubuntu KVM config"
git push
```

### Archiving Old Builds

Retiring an old OS version? Just rename it:
```bash
mv "builds/Ubuntu 22.04" "builds/Ubuntu 22.04-archived"
git commit -am "Archived Ubuntu 22.04"
git push
```

The pipeline will ignore it forever (or until you un-archive it).

## Repository Highlights

### The `common` Directories

- `builds/common/variables/` - Cloud provider settings (datastore paths, networks, etc.)
- `builds/{OS}/common/` - OS-specific files used by both clouds (scripts, configs, etc.)

### Makefile & Setup Scripts

The `setup/` directory contains everything you need to bootstrap a KVM build server:
- Ansible-based provisioning
- Dependency installation
- Libvirt/QEMU configuration
- Storage pool setup

## Troubleshooting

### "My build failed!"
- Check if virtualization is enabled in BIOS (especially for KVM)
- Verify GitHub Secrets are configured correctly
- Look at the Packer logs - they're verbose for a reason

### "KVM builds are slow!"
- Make sure your `BareMetal` runner has enough CPU/RAM
- Check if nested virtualization is properly enabled
- Consider dedicating more cores to the build VM

### "I want to add a new cloud provider!"
1. Add cloud-specific variables to `builds/common/variables/{Cloud}.pkrvars.hcl`
2. Update the GitHub Actions workflow to recognize the new cloud
3. Create OS builds under `builds/{OS}/{Cloud}/`
4. Optionally add a runner selection rule in the workflow

## Contributing

Found a bug? Want to add support for another OS or cloud? PRs welcome!

Just remember: if the AI wrote something dumb in the docs, you're now part of the solution 😄

## License

Use it, break it, fix it, fork it. No warranty expressed or implied. If your VMs achieve sentience, that's between you and them.

---

**Pro Tip**: Start with the QUICKSTART.md in the `setup/` directory if you're setting this up from scratch.