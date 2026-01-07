# Documentation Index

Welcome to the ZAMM Workout Parser documentation. Start here to navigate all available resources.

## 🎯 Start Here

**New to the project?**
1. Read [README.md](../README.md) - Project overview and quick start
2. Review [ARCHITECTURE.md](../ARCHITECTURE.md) - Understand system design
3. Check [CHANGELOG.md](../CHANGELOG.md) - See what's been built

## 📚 By Category

### Getting Started
- **[README.md](../README.md)** - Project overview, quick commands, key concepts
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - System design, data flow, patterns
- **[DB_READINESS_REPORT.md](../DB_READINESS_REPORT.md)** - Current status assessment (85/100)

### Implementation Guides
- **[n8n Integration Guide](./guides/N8N_INTEGRATION_GUIDE.md)** (572 lines)
  - Complete n8n workflow setup
  - Step-by-step AI agent configuration
  - Structured output schemas
  
- **[AI Prompts](./guides/AI_PROMPTS.md)** (335 lines)
  - Main parser agent prompt
  - Validation agent prompt
  - Block type classifier prompt
  - Example inputs and outputs

### Reference Documentation
- **[Block Types Reference](./reference/BLOCK_TYPES_REFERENCE.md)** (307 lines)
  - 17 standardized block types
  - Result models and UI hints
  - Aliases in English, abbreviations, and Hebrew
  
- **[Block Type System Summary](./reference/BLOCK_TYPE_SYSTEM_SUMMARY.md)** (239 lines)
  - System overview
  - Implementation details
  - Testing information

### API & Database
- **[Quick Test Queries](./api/QUICK_TEST_QUERIES.sql)**
  - Sample SQL queries to test functions
  - Example data inserts
  - Validation checks

- **[Schema Migrations](../supabase/migrations/)**
  - `20260104112029_remote_schema.sql` - Initial schema
  - `20260104120000_create_ai_tools.sql` - AI SQL tools (5 functions)
  - `20260104120100_create_validation_functions.sql` - Validation (5 functions)
  - `20260104120200_commit_full_workout_v3.sql` - Stored procedure v3
  - `20260104130000_priority1_exercise_catalog_indexes.sql` - Exercise catalog
  - `20260104140000_block_type_system.sql` - Block types (17 types, 60+ aliases)

### Historical Records (Archive)
- **[Implementation Complete](./archive/IMPLEMENTATION_COMPLETE.md)** (229 lines)
  - Initial implementation summary
  - SQL tools overview
  - Validation functions
  
- **[Priority 1 Complete](./archive/PRIORITY1_COMPLETE.md)** (419 lines)
  - Exercise catalog implementation
  - Exercise normalization system
  - 14 seed exercises
  
- **[DB Architecture Review](./archive/DB_ARCHITECTURE_REVIEW.md)** (514 lines)
  - Professional database assessment
  - Score: 88/100
  - Recommendations and improvements
  
- **[Commit Workout v3 Update](./archive/COMMIT_WORKOUT_V3_UPDATE.md)** (267 lines)
  - Stored procedure v3 changes
  - Prescription/performance separation enhancements
  - Detailed set results tracking

## 🗂️ Directory Structure

```
/workspaces/ParserZamaActive/
├── README.md                    # Start here
├── ARCHITECTURE.md              # System design
├── CHANGELOG.md                 # Version history
├── DB_READINESS_REPORT.md       # Status assessment
├── LICENSE                      # MIT license
│
├── data/                        # Sample workout logs (10 files)
│   ├── bader_workout_log.txt
│   ├── Workout Log: Arnon Shafir.txt
│   └── ... (8 more)
│
├── docs/                        # All documentation
│   ├── INDEX.md                 # This file
│   │
│   ├── guides/                  # Implementation guides
│   │   ├── N8N_INTEGRATION_GUIDE.md
│   │   └── AI_PROMPTS.md
│   │
│   ├── reference/               # Technical reference
│   │   ├── BLOCK_TYPES_REFERENCE.md
│   │   └── BLOCK_TYPE_SYSTEM_SUMMARY.md
│   │
│   ├── api/                     # SQL queries & API docs
│   │   └── QUICK_TEST_QUERIES.sql
│   │
│   └── archive/                 # Historical implementation docs
│       ├── IMPLEMENTATION_COMPLETE.md
│       ├── PRIORITY1_COMPLETE.md
│       ├── DB_ARCHITECTURE_REVIEW.md
│       └── COMMIT_WORKOUT_V3_UPDATE.md
│
├── scripts/                     # Utility scripts
│   └── test_block_types.sh
│
└── supabase/                    # Database configuration
    ├── config.toml
    └── migrations/              # 6 schema migrations
        ├── 20260104112029_remote_schema.sql
        ├── 20260104120000_create_ai_tools.sql
        ├── 20260104120100_create_validation_functions.sql
        ├── 20260104120200_commit_full_workout_v3.sql
        ├── 20260104130000_priority1_exercise_catalog_indexes.sql
        └── 20260104140000_block_type_system.sql
```

## 🔍 Find Information By Topic

### Prescription vs Performance
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Core concept explanation
- [AI_PROMPTS.md](./guides/AI_PROMPTS.md) - Prompt templates for separation
- [COMMIT_WORKOUT_V3_UPDATE.md](./archive/COMMIT_WORKOUT_V3_UPDATE.md) - v3 implementation

### Block Types
- [BLOCK_TYPES_REFERENCE.md](./reference/BLOCK_TYPES_REFERENCE.md) - Complete catalog
- [BLOCK_TYPE_SYSTEM_SUMMARY.md](./reference/BLOCK_TYPE_SYSTEM_SUMMARY.md) - System details
- Migration: `20260104140000_block_type_system.sql`

### Exercise Catalog
- [PRIORITY1_COMPLETE.md](./archive/PRIORITY1_COMPLETE.md) - Implementation details
- Migration: `20260104130000_priority1_exercise_catalog_indexes.sql`

### AI Integration
- [N8N_INTEGRATION_GUIDE.md](./guides/N8N_INTEGRATION_GUIDE.md) - Complete setup
- [AI_PROMPTS.md](./guides/AI_PROMPTS.md) - Prompt templates
- Migration: `20260104120000_create_ai_tools.sql` - 5 SQL functions

### Validation
- [AI_PROMPTS.md](./guides/AI_PROMPTS.md) - Validation agent prompt
- Migration: `20260104120100_create_validation_functions.sql` - 5 functions

### Database Schema
- [DB_READINESS_REPORT.md](../DB_READINESS_REPORT.md) - Tables overview and status
- [DB_ARCHITECTURE_REVIEW.md](./archive/DB_ARCHITECTURE_REVIEW.md) - Detailed review
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Logical structure

## 📊 Documentation Statistics

- **Total Documentation**: ~3,500 lines
- **Guides**: 907 lines (2 files)
- **Reference**: 546 lines (2 files)
- **Archive**: 1,429 lines (4 files)
- **Core Docs**: ~600 lines (README, ARCHITECTURE, CHANGELOG, DB_READINESS)
- **SQL Migrations**: 6 files
- **Sample Data**: 10 workout log files

## 🎯 Common Tasks

### Setting Up n8n Workflow
→ [N8N_INTEGRATION_GUIDE.md](./guides/N8N_INTEGRATION_GUIDE.md)

### Understanding Block Types
→ [BLOCK_TYPES_REFERENCE.md](./reference/BLOCK_TYPES_REFERENCE.md)

### Writing AI Prompts
→ [AI_PROMPTS.md](./guides/AI_PROMPTS.md)

### Testing SQL Functions
→ [QUICK_TEST_QUERIES.sql](./api/QUICK_TEST_QUERIES.sql)

### Understanding Architecture
→ [ARCHITECTURE.md](../ARCHITECTURE.md)

### Checking Project Status
→ [CHANGELOG.md](../CHANGELOG.md) or [DB_READINESS_REPORT.md](../DB_READINESS_REPORT.md)

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0
