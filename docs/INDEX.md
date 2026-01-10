# Documentation Index

Welcome to the ZAMM Workout Parser documentation. Start here to navigate all available resources.

## 🎯 Start Here

**New to the project?**
1. Read [README.md](../README.md) - Project overview and quick start
2. Review [ARCHITECTURE.md](../ARCHITECTURE.md) - Understand system design
3. Check [CANONICAL_JSON_SCHEMA.md](./reference/CANONICAL_JSON_SCHEMA.md) - **The Constitution** ⚖️
4. See [CHANGELOG.md](../CHANGELOG.md) - Version history

**Want to improve the parser?**
1. Read [ACTIVE_LEARNING_QUICKSTART.md](../ACTIVE_LEARNING_QUICKSTART.md) - How parser learns
2. Run `npm run learn` - Train parser from corrections

## 📚 By Category

### Getting Started
- **[README.md](../README.md)** - Project overview, quick commands, key concepts
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - System design, data flow, patterns
- **[DB_READINESS_REPORT.md](../DB_READINESS_REPORT.md)** - Current status assessment (85/100)
- **[ACTIVE_LEARNING_QUICKSTART.md](../ACTIVE_LEARNING_QUICKSTART.md)** 🆕 - Active learning system quick start
- **[ENVIRONMENT_SETUP.md](../ENVIRONMENT_SETUP.md)** 🆕 - Environment configuration guide

### Core Reference (MUST READ)
- **[CANONICAL_JSON_SCHEMA.md](./reference/CANONICAL_JSON_SCHEMA.md)** ⚖️ 🆕 **THE CONSTITUTION**
  - The ONLY allowed JSON schema for parser output
  - 5 core principles (prescription/performed, atomic types, ranges, normalization, null safety)
  - Complete schema definitions with TypeScript types
  - 6 validation rule categories
  - 5 test cases parser must pass
  - 5 common parser errors to avoid
  - **Status:** 🔒 LOCKED - This is the law

### Quality Assurance & Testing 🧪 🆕
- **[QA_STRESS_TEST_REPORT.md](../QA_STRESS_TEST_REPORT.md)** 🆕 (350+ lines)
  - Full system stress test results
  - Golden set validation (19 files, 94.7% pass rate)
  - "Nasty 10" edge case scenarios
  - Production readiness assessment
  - **Status:** ⚠️ 95% Production Ready
  
- **[STRESS_TEST_GUIDE.md](./reference/STRESS_TEST_GUIDE.md)** 🆕 (400+ lines)
  - Step-by-step execution guide for stress tests
  - Expected outputs for all 10 edge cases
  - Validation commands and success criteria
  - Common pitfalls to avoid
  
- **[validate_golden_sets.py](../scripts/validate_golden_sets.py)** 🆕
  - Automated validation script (Python)
  - Checks: JSON structure, type safety, block codes, equipment keys
  - Run with: `python3 scripts/validate_golden_sets.py`

### Active Learning System 🔄 🆕
- **[ACTIVE_LEARNING_README.md](../scripts/ACTIVE_LEARNING_README.md)** (500+ lines)
  - Complete active learning system documentation
  - How corrections become training data
  - Database schema and workflow
  - Usage examples and best practices
  
- **[update_parser_brain.js](../scripts/update_parser_brain.js)** (280+ lines)
  - Node.js script for active learning loop
  - Fetches corrections from DB
  - Injects examples into AI prompts
  - Run with: `npm run learn`
  
- **[MISSION_COMPLETE.md](../MISSION_COMPLETE.md)** 🆕
  - Implementation summary
  - Success criteria checklist
  - Usage guide

### Implementation Guides
- **[Schema Change Workflow](./guides/SCHEMA_CHANGE_WORKFLOW.md)** 🆕
  - How to update docs when schema changes
  - Semi-automated checklist system
  - Git hooks and validation
  
- **[Parser Workflow](./guides/PARSER_WORKFLOW.md)** (600+ lines)
  - Complete 4-stage workflow
  - Stage-by-stage implementation details
  
- **[Stage 2 Parsing Strategy](./guides/STAGE2_PARSING_STRATEGY.md)** (900+ lines)
  - AI parsing patterns and examples
  - Exercise options, circuits, blocks
  
- **[Parser Audit Checklist](./guides/PARSER_AUDIT_CHECKLIST.md)** (900+ lines)
  - Comprehensive validation checklist
  - JSON structure validation
  
- **[Schema Updates (Jan 10, 2026)](./guides/SCHEMA_UPDATES_2026-01-10.md)** 🆕
  - New scalable patterns for exercise_options
  - New circuit_config structure
  - Migration from v1 to v2 schema

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

### Schema & Data Structure (NEW! v2.0) 🆕
- [SCHEMA_UPDATES_2026-01-10.md](./guides/SCHEMA_UPDATES_2026-01-10.md) - v2 schema changes
- [STAGE2_PARSING_STRATEGY.md](./guides/STAGE2_PARSING_STRATEGY.md) - Updated patterns
- [PARSER_AUDIT_CHECKLIST.md](./guides/PARSER_AUDIT_CHECKLIST.md) - Updated validation rules

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

**Last Updated:** January 10, 2026  
**Version:** 2.0.0 (Schema v2 - Scalable Patterns)
