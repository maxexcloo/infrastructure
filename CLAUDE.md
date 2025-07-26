# CLAUDE.md - OpenTofu Project Rules

## Rules
- ALL files end with trailing newline
- Consolidate defaults in `var.default` structure
- Locals in `locals_*.tf` files must start with filename prefix
- No comments - code is self-explanatory
- Run `tofu fmt` after every change
- Sort everything alphabetically and recursively
- Use `type = any` for complex nested structures

## Sorting
**Key order within blocks:**
1. `count` and `for_each` (with blank line after)
2. Simple values (strings, numbers, bools, null)  
3. Complex values (arrays, objects, maps)

## Structure
```
├── data.tf                  # All data sources
├── locals_*.tf              # All locals (prefixed by filename)
├── outputs.tf               # Output definitions
├── providers.tf             # Provider configurations
├── terraform.tf             # Terraform configuration
├── variables.tf             # Variable definitions
├── *.tf                     # Resource files
└── terraform.tfvars         # Instance values
```

## Workflow
```bash
tofu fmt && tofu validate && tofu plan
git add . && git commit -m "Update OpenTofu configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```
