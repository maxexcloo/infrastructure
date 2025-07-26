# Infrastructure

OpenTofu configuration for managing personal infrastructure including virtual machines, networking, DNS, and physical device management.

## Overview

This project manages core infrastructure for personal computing environment with features including:

- **Cloud Tunnels**: Cloudflare tunnels for secure external access
- **Device Management**: Physical servers, routers, and IoT devices
- **DNS Management**: Cloudflare DNS with automated record creation for all services
- **Monitoring**: Integrated with external monitoring and alerting systems
- **Network Infrastructure**: Tailscale mesh networking with device management
- **Security**: 1Password integration for secret management and credential storage
- **Storage**: Backblaze B2 buckets for backup and data storage
- **Virtual Machine Management**: Oracle Cloud Infrastructure (OCI) and Proxmox VE instances

## Architecture

### File Structure

```
├── *.tf                     # Resource files (alphabetically sorted)
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
│   ├── locals_dns.tf        # DNS record processing
│   ├── locals_output.tf     # Output formatting
│   ├── locals_servers.tf    # Server/device merging
│   ├── locals_tailscale.tf  # Tailscale configuration
│   └── locals_vms.tf        # VM configurations
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration and provider versions
├── terraform.tfvars         # Instance values (see terraform.tfvars.sample)
└── terraform.tfvars.sample  # Example configuration template
├── variables.tf             # Variable definitions
```

### Infrastructure Components

Infrastructure is defined in `terraform.tfvars` with the following structure:

```hcl
# Physical servers and routers
routers = [
  {
    flags    = ["homepage", "unifi"]
    location = "au"
    networks = [{ public_address = "example.com" }]
  }
]

servers = [
  {
    flags  = ["docker", "homepage"] 
    name   = "server-name"
    parent = "router-location"
    title  = "Display Name"
  }
]

# Virtual machines  
vms = [
  {
    location = "cloud"
    name     = "vm-name"
    # Generic VM configuration
  }
]

vms_oci = [
  {
    location = "au"
    name     = "vm-name"  
    config = {
      cpus   = 4
      memory = 8
      # OCI-specific configuration
    }
  }
]

vms_proxmox = [
  {
    name   = "vm-name"
    parent = "physical-server-name"
    config = {
      cpus   = 2
      memory = 4
      # Proxmox-specific configuration  
    }
  }
]
```

### Platforms

- **Cloud Services**: DNS, storage, tunnels, and monitoring integrations
- **OCI**: Oracle Cloud Infrastructure virtual machines with networking
- **Physical**: Physical servers, routers, and network devices
- **Proxmox**: Self-hosted virtualization platform for local VMs

## Usage

### Prerequisites

1. OpenTofu >= 1.8
2. Terraform Cloud workspace configured
3. Provider credentials configured in `terraform.tfvars` (see `terraform.tfvars.sample` for example configuration)

### Commands

```bash
# Initialize the workspace
tofu init

# Format, validate, and plan changes (always review before applying)
tofu fmt && tofu validate

# Apply changes
tofu apply

# View outputs
tofu output
```

### Getting Started

1. Copy the sample configuration file:
   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

2. Update `terraform.tfvars` with your actual configuration values:
   - Replace all example values with your real credentials and settings
   - Configure your domains, servers, and infrastructure components
   - See the sample file for complete examples of all supported configurations

3. Initialize and apply:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

### Adding New Infrastructure

1. Add infrastructure configuration to `terraform.tfvars` (reference `terraform.tfvars.sample` for examples)

2. Plan and apply changes

### Virtual Machine Management

VM configurations support multiple platforms:

- **Default Configuration**: VM defaults are centralized in `var.default.vm_config` structure
- **Networking**: Automatic Tailscale integration and DNS record creation
- **OCI VMs**: Defined in `vms_oci` with Oracle Cloud-specific settings
- **Proxmox VMs**: Defined in `vms_proxmox` with local virtualization settings
- **Storage**: B2 bucket provisioning for backup and data storage

#### VM Configuration Defaults

All VM defaults are stored in `var.default.vm_config`:

- `base`: Common VM settings (flags, services, tag)
- `network`: Network defaults (public_ipv4, public_ipv6)
- `oci`: OCI-specific defaults (boot_disk_size, cpus, memory, shape, etc.)
- `proxmox`: Proxmox VM defaults (boot_disk_size, cpus, memory, operating_system, etc.)
- `proxmox_hostpci`: PCI device passthrough defaults
- `proxmox_network`: Network configuration for Proxmox VMs
- `proxmox_usb`: USB device passthrough defaults

## Monitoring

- **DNS Health**: Automated monitoring of DNS record propagation
- **Network Connectivity**: Tailscale connectivity monitoring
- **Resource Usage**: Cloud resource utilization tracking
- **VM Status**: Health checks for all virtual machine instances

## Security

- **Access control**: Infrastructure access limited to authorized devices only
- **Network security**: Tailscale provides zero-trust network access
- **Secret management**: Passwords and API keys generated and stored in 1Password
- **Sensitive variables**: All provider credentials are marked as sensitive
- **State encryption**: Terraform state stored securely in Terraform Cloud

## Troubleshooting

### Common Issues

1. **Provider authentication errors**: Verify credentials in `terraform.tfvars` (use `terraform.tfvars.sample` as reference)
2. **VM provisioning failures**: Check cloud provider quotas and limits
3. **DNS propagation delays**: Cloudflare changes may take time to propagate
4. **Tailscale connectivity**: Verify device authentication and network policies
5. **Resource conflicts**: Check for naming collisions across infrastructure

### Validation

Run `tofu fmt && tofu validate && tofu plan` to format, validate configuration syntax, and preview changes before applying.

## Contributing

When modifying this configuration:

1. Always run `tofu fmt && tofu validate && tofu plan` before applying changes
2. Follow the CLAUDE.md code quality rules:
   - Recursive alphabetical sorting of all keys
   - count/for_each at top with blank line after
   - Simple values (single-line strings, numbers, bools, null) before complex values (arrays, multiline strings, objects, maps)
   - No comments - code should be self-explanatory
   - Trailing newlines in all files
3. Test changes in a separate workspace when possible
4. Update documentation for new features or significant changes
5. Follow the existing naming conventions and file organization
