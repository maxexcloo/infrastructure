# Infrastructure

OpenTofu configuration for personal infrastructure management.

## Overview

Manages cloud and physical infrastructure with:

- **DNS**: Cloudflare zones and automated record creation
- **Networking**: Tailscale mesh with device management  
- **Security**: 1Password integration for secret management
- **Storage**: Backblaze B2 buckets for backup
- **VMs**: Oracle Cloud Infrastructure and Proxmox instances

## Structure

```
├── data.tf                  # All data sources
├── locals_*.tf              # Configuration processing
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration
├── variables.tf             # Variable definitions
├── *.tf                     # Resource files
└── terraform.tfvars         # Instance values
```

## Usage

### Setup

1. Copy configuration template:
   ```bash
   cp terraform.tfvars.sample terraform.tfvars
   ```

2. Update `terraform.tfvars` with your values

3. Initialize and apply:
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

### Configuration

Infrastructure defined in `terraform.tfvars`:

```hcl
routers = [
  {
    flags    = ["homepage", "unifi"]
    location = "au"
  }
]

servers = [
  {
    flags  = ["docker", "homepage"] 
    name   = "server-name"
    parent = "router-location"
  }
]

vms_oci = [
  {
    location = "au"
    name     = "vm-name"  
    config = {
      cpus   = 4
      memory = 8
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
    }
  }
]
```

### Workflow

```bash
tofu fmt && tofu validate && tofu plan
tofu apply
```

## Security

- Network access via Tailscale zero-trust
- Secrets managed in 1Password
- State stored in Terraform Cloud
- All credentials marked sensitive

## Troubleshooting

Common issues:

1. **Authentication errors**: Check `terraform.tfvars` credentials
2. **DNS delays**: Cloudflare changes take time to propagate
3. **Resource conflicts**: Check for naming collisions
4. **VM failures**: Verify cloud provider quotas

Run `tofu validate` to check configuration syntax.
