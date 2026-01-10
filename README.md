# ParserZamaActive

🏋️‍♂️ **ZAMM Workout Parser** - AI-SQL Agent Architecture with Active Learning

## Project Overview

מערכת פרסור חכמה הממירה טקסט חופשי (תוכנית אימון + תוצאות ביצוע) למבנה נתונים רלציוני מורכב, באמצעות AI Agents עם SQL Tools.

**🆕 New in v1.2.0:** Active Learning Loop - Parser learns from validation corrections automatically!

## Quick Start

### Setup
```bash
# Install dependencies (auto-installs git hooks)
npm install

# Or manually install git hooks
npm run install:hooks

# Check database connection
npx supabase status
```

**Git Hooks Installed:**
- ✅ `pre-commit` - Verifies schema version compatibility before every commit

### Run Active Learning Loop
```bash
# Train parser from validation corrections
npm run learn
```

### Test Scripts
```bash
# Verify schema version compatibility (Doc ↔ DB)
npm run verify:schema

# Test block type system
npm run test:blocks

# Test parser accuracy
npm run test:parser

# Validate golden set
npm run validate:golden
```

## Database Connection

**Supabase Project:** `dtzcamerxuonoeujrgsu`  
**Schema:** `zamm`  
**Status:** ✅ Connected & Ready

### Quick Commands
```bash
# Check connection
supabase status

# Pull latest schema
supabase db pull

# Generate TypeScript types
supabase gen types typescript --linked > types/database.ts

# Reset local database (if running locally)
supabase db reset
```

## Documentation

### Core Documents
- 🏗️ [Architecture Overview](./docs/architecture/ARCHITECTURE.md) - System design and patterns
- 🤖 [AI Agent Instructions](./docs/context/agents.md) - Complete agent guide (600+ lines)
- 📋 [Changelog](./CHANGELOG.md) - Version history and updates

### Guides
- 🤖 [AI Prompts](./docs/guides/AI_PROMPTS.md) - Agent prompt templates
- 🔄 [Active Learning System](./scripts/active_learning/README.md) - Parser training from corrections
- ✅ [Validation System](./docs/VALIDATION_SYSTEM_SUMMARY.md) - Stage 3 validation functions and workflow
- 🔒 [Idempotency Guide](./docs/guides/IDEMPOTENCY_GUIDE.md) - Duplicate prevention system
- 📋 [Versioning Strategy](./docs/guides/VERSIONING_STRATEGY.md) - Schema version compatibility checks
- 🚀 [Workflow Guide](./docs/guides/WORKFLOW_GUIDE.md) - Development workflow
- ⚙️ [Environment Setup](./docs/guides/ENVIRONMENT_SETUP.md) - Setup instructions

### Reference
- 📜 [Canonical JSON Schema](./docs/reference/CANONICAL_JSON_SCHEMA.md) - **THE CONSTITUTION** - Parser output rules
- 📚 [Block Types Reference](./docs/reference/BLOCK_TYPES_REFERENCE.md) - 17 block types catalog
- 🗄️ [Schema Reference](./docs/architecture/SCHEMA_REFERENCE.md) - Database schema documentation

### API & Testing
- 🧪 [Test Queries](./docs/api/QUICK_TEST_QUERIES.sql) - Sample SQL queries
- 📁 [Schema Migrations](./supabase/migrations/) - Database version history

### Reports
- 📊 [v3.2 Upgrade Report](./docs/reports/SCHEMA_V3.2_UPGRADE_REPORT.md) - Schema v3.2 migration
- 📊 [Parser Test Report](./docs/reports/PARSER_V3.2_TEST_REPORT.md) - Parser validation results
- 📦 [All Reports](./docs/reports/) - Historical reports and summaries

## Architecture Highlights

### 4-Stage Workflow
1. **Context & Ingestion** - קליטת טקסט + זיהוי אתלט
2. **Parsing Agent** - הפרדת תכנון (prescription) מביצוע (performance)
3. **Validation & Normalization** - 6 בדיקות SQL אוטומטיות:
   - מבנה JSON תקין
   - קודי block מהקטלוג (17 סוגים)
   - טווחי ערכים הגיוניים (משקלים, זמנים, חזרות)
   - תרגילים וציוד מהקטלוגים
   - הפרדת prescription מ-performance
   - דוח מפורט עם `is_valid: true/false`
4. **Atomic Commit** - שמירה למסד נתונים בטרנזקציה אחת (רק אחרי validation מוצלח)

### Key Separation: Prescription vs Performance
המערכת מפרידה בין:
- **Prescription (תכנון):** מה אמור להתבצע ("3x5 @ 100kg")
- **Performance (ביצוע):** מה קרה בפועל ("הצלחתי רק 4 חזרות בסט אחרון")

## Project Structure

```
ParserZamaActive/
├── 📄 Core Documentation
│   ├── README.md                    # This file - project overview
│   ├── ARCHITECTURE.md              # System design and patterns
│   ├── CHANGELOG.md                 # Version history (v1.0.0)
│   ├── DB_READINESS_REPORT.md       # Status assessment (85/100)
│   └── LICENSE                      # MIT license
│
├── 📚 docs/                         # All documentation
│   ├── INDEX.md                     # Documentation navigation guide
│   │
│   ├── guides/                      # Implementation guides
│   │   └── AI_PROMPTS.md            # AI agent templates (335 lines)
│   │
│   ├── reference/                   # Technical reference
│   │   ├── BLOCK_TYPES_REFERENCE.md # 17 block types catalog
│   │   └── BLOCK_TYPE_SYSTEM_SUMMARY.md # System overview
│   │
│   ├── api/                         # SQL & API documentation
│   │   └── QUICK_TEST_QUERIES.sql   # Test queries
│   │
│   └── archive/                     # Historical records
│       ├── IMPLEMENTATION_COMPLETE.md
│       ├── PRIORITY1_COMPLETE.md
│       ├── DB_ARCHITECTURE_REVIEW.md
│       └── COMMIT_WORKOUT_V3_UPDATE.md
│
├── 💾 data/                         # Sample workout logs
│   ├── README.md                    # Data overview
│   └── *.txt                        # 10 workout log files (~640KB)
│
├── 🔧 scripts/                      # Utility scripts
│   ├── README.md                    # Scripts documentation
│   └── test_block_types.sh          # Block type system tests
│
└── 🗄️ supabase/                     # Database configuration
    ├── config.toml                  # Supabase config
    └── migrations/                  # 6 schema migrations
        ├── 20260104112029_remote_schema.sql
        ├── 20260104120000_create_ai_tools.sql
        ├── 20260104120100_create_validation_functions.sql
        ├── 20260104120200_commit_full_workout_v3.sql
        ├── 20260104130000_priority1_exercise_catalog_indexes.sql
        └── 20260104140000_block_type_system.sql
```

**Total:** 35 files across 10 directories

## Database Overview

### Hierarchical Structure
```
workouts → workout_sessions → workout_blocks → workout_items → item_set_results
```

### Key Tables
- **Infrastructure**: `dim_athletes`, `parser_rulesets`, `equipment_catalog`, `exercise_catalog`, `block_type_catalog`
- **Staging**: `imports`, `parse_drafts`, `validation_reports`, `draft_edits`
- **Core**: `workouts`, `workout_sessions`, `workout_blocks`, `workout_items`
- **Results**: `item_set_results`, `workout_block_results`, `interval_segments`

**For detailed schema:** See [ARCHITECTURE.md](./ARCHITECTURE.md) and [DB_READINESS_REPORT.md](./DB_READINESS_REPORT.md)

### Stored Procedures
- `commit_full_workout_v3()` - Convert normalized JSON to relational data (current)
- 5 AI Tools: `check_athlete_exists()`, `check_equipment_exists()`, `get_active_ruleset()`, etc.
- 5 Validation Functions: `validate_workout_draft()`, `check_prescription_performance_consistency()`, etc.

## Example Parsing Flow

```
Input Text:
"Squat: 3x5 @ 100kg. Last set was hard, only got 4 reps."

↓ Stage 1: Context & Ingestion
- Save to imports table
- Identify athlete (SQL Tool: CheckAthleteExists)
- Get active ruleset

↓ Stage 2: Parsing Agent
- Exercise: "Squat"
- Prescription: {sets: 3, reps: 5, load_kg: 100}
- Performance: [
    {set: 1, reps: 5, load: 100},
    {set: 2, reps: 5, load: 100},
    {set: 3, reps: 4, load: 100, notes: "hard"}
  ]

↓ Stage 3: Validation
✅ set_index exists
✅ load_kg is reasonable (< 500kg)
⚠️  Warning: actual_reps (4) < target_reps (5) in set 3

↓ Stage 4: Atomic Commit
workout_items:
  - prescription_data: {sets: 3, reps: 5, load: 100}

item_set_results (3 rows):
  - set 1: reps=5, load_kg=100
  - set 2: reps=5, load_kg=100
  - set 3: reps=4, load_kg=100, notes="hard"
```

## Project Status

**Version:** 1.0.0  
**Overall Readiness:** 85/100 ✅

### Implementation Complete ✅
- ✅ Database schema with 20+ tables
- ✅ 6 migrations deployed to Supabase
- ✅ 5 AI SQL tools for agent integration
- ✅ 5 validation functions
- ✅ 3 stored procedure versions (v3 current)
- ✅ 17 standardized block types with 60+ aliases
- ✅ Exercise catalog with 14 seed exercises
- ✅ Comprehensive documentation

### Ready for Integration
- 🤖 AI prompts templates ready
- 🧪 Test queries available
- 📊 Sample workout logs (10 files)

### Next Steps
1. Configure AI agents with [prompt templates](./docs/guides/AI_PROMPTS.md)
2. Test parsing with sample data from `data/` folder
3. Monitor validation reports and iterate

## Quick Start

### 1. Check Database Connection
```bash
supabase status
```

### 2. Review Key Documents
- Start with [Architecture Overview](./ARCHITECTURE.md) to understand the system
- Check [DB Readiness](./DB_READINESS_REPORT.md) for current status (85/100)
- Use [AI Prompts](./docs/guides/AI_PROMPTS.md) for agent configuration

### 3. Test SQL Functions
```bash
# Run test queries
psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres -f docs/api/QUICK_TEST_QUERIES.sql
```

### 4. Review Sample Data
Check `data/` folder for 10 real workout log examples.

---

**Technology Stack:** Supabase (PostgreSQL), AI Agents (OpenAI/Claude/Gemini)  
**License:** MIT  
**Project ID:** dtzcamerxuonoeujrgsu
