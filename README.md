# Infrastructure

OpenTofu configuration for managing personal infrastructure including virtual machines, networking, DNS, and physical device management.

## Overview

This project manages core infrastructure for personal computing environment with features including:

- **Virtual Machine Management**: Oracle Cloud Infrastructure (OCI) and Proxmox VE instances
- **DNS Management**: Cloudflare DNS with automated record creation for all services
- **Network Infrastructure**: Tailscale mesh networking with device management
- **Storage**: Backblaze B2 buckets for backup and data storage
- **Device Management**: Physical servers, routers, and IoT devices
- **Security**: 1Password integration for secret management and credential storage
- **Monitoring**: Integrated with external monitoring and alerting systems
- **Cloud Tunnels**: Cloudflare tunnels for secure external access

## Architecture

### File Structure

```
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
│   ├── locals_dns.tf        # DNS record processing
│   ├── locals_output.tf     # Output formatting
│   ├── locals_servers.tf    # Server/device merging
│   ├── locals_tailscale.tf  # Tailscale configuration
│   └── locals_vms.tf        # VM configurations
├── variables.tf             # Variable definitions
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration and provider versions
├── *.tf                     # Resource files (alphabetically sorted)
├── terraform.tfvars         # Instance values (see terraform.tfvars.sample)
└── terraform.tfvars.sample  # Example configuration template
```

### Infrastructure Components

Infrastructure is defined in `terraform.tfvars` with the following structure:

```hcl
servers = {
  "server-name" = {
    dns_name        = "hostname"
    dns_zone        = "example.com"
    enable_dns      = true
    enable_tailscale = true
    # ... other configuration
  }
}

vms_oci = {
  "vm-name" = {
    # OCI-specific configuration
  }
}

vms_proxmox = {
  "vm-name" = {
    # Proxmox-specific configuration
  }
}
```

### Platforms

- **OCI**: Oracle Cloud Infrastructure virtual machines with networking
- **Proxmox**: Self-hosted virtualization platform for local VMs
- **Physical**: Physical servers, routers, and network devices
- **Cloud Services**: DNS, storage, tunnels, and monitoring integrations

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

2. Create server-specific resource file (e.g., `server.tf`) if needed

3. Plan and apply changes

### Virtual Machine Management

VM configurations support multiple platforms:

- **OCI VMs**: Defined in `vms_oci` with Oracle Cloud-specific settings
- **Proxmox VMs**: Defined in `vms_proxmox` with local virtualization settings
- **Networking**: Automatic Tailscale integration and DNS record creation
- **Storage**: B2 bucket provisioning for backup and data storage

## Security

- **Sensitive variables**: All provider credentials are marked as sensitive
- **Secret management**: Passwords and API keys generated and stored in 1Password
- **Network security**: Tailscale provides zero-trust network access
- **State encryption**: Terraform state stored securely in Terraform Cloud
- **Access control**: Infrastructure access limited to authorized devices only

## Monitoring

- **DNS Health**: Automated monitoring of DNS record propagation
- **VM Status**: Health checks for all virtual machine instances
- **Network Connectivity**: Tailscale connectivity monitoring
- **Resource Usage**: Cloud resource utilization tracking

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
