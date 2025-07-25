# CLAUDE.md - OpenTofu Project Rules

## Code Quality
- **ALL files must end with trailing newline**
- **Run `tofu fmt` after every change**
- **Use OpenTofu >= 1.8** for latest features and stability
- **No comments** - code should be self-explanatory
- Add validation rules to variables for better error handling
- Consolidate data sources to minimize API calls
- Extract complex conditional logic to computed locals
- Mark sensitive values appropriately
- Pre-compute expensive operations in locals
- Use `type = any` for complex nested structures
- Use modern syntax (avoid `element()`, prefer direct indexing)

## Directory Structure
```
├── data.tf                  # All data sources
├── locals_*.tf              # All locals
├── variables.tf             # Variable definitions
├── outputs.tf               # Output definitions
├── *.tf                     # Resource files
└── terraform.tfvars         # Instance values
```

## File Organization
- **Data sources**: All in `data.tf`
- **Locals**: Split into `locals_*.tf` files by function
- **Outputs**: All in `outputs.tf`
- **Providers**: In `providers.tf` and `terraform.tf`
- **Variables**: All in `variables.tf` with proper types/descriptions

## Locals Formatting
**In `locals_*.tf` files:**
- Add a blank line between each local definition
- Sort all locals alphabetically by name
- **All locals must start with the filename prefix** (e.g., `locals_dns.tf` → all locals start with `dns_`)

## Sorting Rules
**ALWAYS sort alphabetically and recursively by:**
1. Block type
2. Data/resource source type  
3. Data/resource name
4. **All keys within blocks recursively**

**Key Ordering Within Blocks:**
1. `count` and `for_each` at the top with blank line after
2. Keys with simple values (single-line strings, numbers, bools, null)
3. Keys with complex values (arrays, multiline strings, objects, maps)
4. Within nested objects, apply same recursive sorting rules

**Simple vs Complex Values:**
- **Simple**: Single-line strings, numbers, booleans, null values
- **Complex**: Arrays (even single-item), multiline strings, objects, maps

## Validate & Commit
**After every change:**
```bash
tofu fmt && tofu validate && tofu plan
```

**Then auto-commit:**
```bash
git add . && git commit -m "Update OpenTofu configuration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```
