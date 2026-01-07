# Scripts

Utility scripts for testing and development.

## Available Scripts

### test_block_types.sh
Tests the block type system functionality.

**Usage:**
```bash
cd /workspaces/ParserZamaActive
./scripts/test_block_types.sh
```

**What it tests:**
1. Count of block types (should be 17)
2. Count of aliases (should be 60+)
3. Block types grouped by category
4. `normalize_block_code()` function with various inputs:
   - English: "strength", "wod", "metcon"
   - Hebrew: "כוח"
   - Aliases: Various abbreviations
5. UI hints validation

**Requirements:**
- Supabase CLI installed and configured
- Connected to the project (`supabase status` should show linked project)
- Block type migration deployed (`20260104140000_block_type_system.sql`)

## Future Scripts

Planned utility scripts:
- `test_ai_tools.sh` - Test all 5 AI SQL tools
- `test_validation.sh` - Test validation functions
- `seed_sample_data.sh` - Load sample workouts into database
- `verify_migrations.sh` - Verify all migrations are applied
- `generate_types.sh` - Generate TypeScript types from schema

## Contributing

When adding new scripts:
1. Add shebang: `#!/bin/bash`
2. Make executable: `chmod +x scripts/yourscript.sh`
3. Add comments explaining purpose
4. Update this README
5. Add error handling
6. Test before committing
