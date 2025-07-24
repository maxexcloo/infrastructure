# Infrastructure
OpenTofu configuration for personal infrastructure.

## Code Quality Assessment

This document outlines the current state of the OpenTofu configuration against the CLAUDE.md specifications and identifies areas requiring attention.

## Current Compliance Status

### ❌ Critical Issues

#### 1. Missing Trailing Newlines
- **Issue**: All 17 .tf files missing required trailing newlines
- **Impact**: Code quality standard violation
- **Files Affected**: All .tf and .tfvars files
- **Fix Required**: Add trailing newline to each file

#### 2. Data Source Consolidation
- **Issue**: 9 data sources scattered across 6 different files
- **Impact**: Increased API calls, poor organization
- **Current**: Data sources in cloudflare.tf, oci.tf, b2.tf, tailscale.tf, onepassword.tf, github.tf
- **Required**: All data sources consolidated in data.tf

#### 3. Locals Organization
- **Issue**: Single 357-line locals.tf file instead of functional split
- **Impact**: Poor maintainability
- **Required**: Split into locals_*.tf files by function
- **Suggested Split**:
  - locals_dns.tf (DNS record processing)
  - locals_servers.tf (Server/device merging)
  - locals_output.tf (Output formatting)
  - locals_tailscale.tf (Tailscale configuration)
  - locals_vms.tf (VM configurations)

### ⚠️ Minor Issues

#### 1. Sorting Violations
- **cloudflare.tf**: `lifecycle` block positioned incorrectly in cloudflare_account_token.server
- **proxmox.tf**: Missing `for_each` at top with blank line, improper key grouping
- **locals.tf**: Missing blank lines between local definitions
- **outputs.tf**: Contains misplaced resource block (should be in separate .tf file)

#### 2. Missing Variable Specifications
- **variables.tf**: All variables missing type and description attributes
- **Impact**: Reduced error handling and documentation

### ✅ Compliant Areas

- Variables properly consolidated in variables.tf
- Outputs properly consolidated in outputs.tf (except for one misplaced resource)
- Individual resource files organized by provider
- OpenTofu validation passes successfully
- Configuration is syntactically correct

## Testing Results

```bash
tofu fmt     # ✅ Completed successfully
tofu validate # ✅ Configuration is valid
tofu plan    # ✅ Plan generated (shows 1 minor change to tailscale_acl)
```

## Code Smells and Complexity Issues

### 1. File Size Concerns
- **locals.tf**: 357 lines - should be split into functional modules
- **cloudflare.tf**: 174 lines - could benefit from data source extraction
- **proxmox.tf**: 155 lines - complex nested structures

### 2. Unused/Inconsistent Code
- **outputs.tf**: Contains resource definition instead of just outputs
- **Mixed responsibilities**: Data sources mixed with resources in provider files

### 3. Complexity Indicators
- Deep nesting in VM configuration blocks
- Complex conditional logic in locals that could be simplified
- Multiple resource types mixed in single files

## Recommendations

### Immediate Actions (Critical)
1. Create  directory structure
2. Add trailing newlines to all files
3. Consolidate data sources into data.tf
4. Split locals.tf into functional locals_*.tf files

### Medium Priority
1. Fix sorting violations in cloudflare.tf and proxmox.tf
2. Move resource from outputs.tf to appropriate file
3. Add type and description to all variables
4. Add blank lines between locals definitions

### Future Improvements
1. Consider breaking down large resource files
2. Implement consistent naming conventions
3. Add validation rules to variables
4. Review and simplify complex locals logic

## File Organization Target State

```

├── data.tf                  # All 9 data sources consolidated
├── locals_dns.tf           # DNS record processing
├── locals_servers.tf       # Server/device merging
├── locals_output.tf        # Output formatting
├── locals_tailscale.tf     # Tailscale configuration
├── locals_vms.tf          # VM configurations
├── variables.tf            # All variables with types/descriptions
├── outputs.tf              # Outputs only (move resource elsewhere)
├── providers.tf            # Provider configurations
├── terraform.tf            # Terraform settings
├── b2.tf                   # Resources only
├── cloudflare.tf           # Resources only (data moved to data.tf)
├── github.tf               # Resources only (data moved to data.tf)
├── htpasswd.tf            # Resources only
├── oci.tf                  # Resources only (data moved to data.tf)
├── onepassword.tf          # Resources only (data moved to data.tf)
├── proxmox.tf              # Resources only
├── random.tf               # Resources only
├── resend.tf               # Resources only
├── sftpgo.tf               # Resources only
├── tailscale.tf            # Resources only (data moved to data.tf)
└── terraform.tfvars        # Instance values
```

**Note**: As per CLAUDE.md instructions, this analysis suggests organizational changes but does not make major apply changes without user approval.
