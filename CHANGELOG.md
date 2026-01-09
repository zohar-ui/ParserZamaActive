# Changelog - ZAMM Workout Parser

## [1.2.0] - January 7, 2026

### 🎯 Major Feature: Production Validation System

#### ✅ Comprehensive Validation Functions (Migration: 20260107150000)
**Created 6 production-ready SQL functions** to enforce data quality in Stage 3 (Validation):

**Individual Validation Functions:**
1. **`validate_parsed_structure()`** - Basic JSON structure validation
   - Checks: workout_date, athlete_id, sessions existence and format
   - Date validation: YYYY-MM-DD format, not in future, not before 2015
   - Athlete_id: UUID format + exists in lib_athletes table
   - Returns: errors/warnings with field-level details

2. **`validate_block_codes()`** - Block and session structure validation
   - Validates 17 standard block codes (WU, STR, METCON, etc.)
   - Session_code validation (AM, PM, SINGLE)
   - Checks: block_label, prescription, performed fields existence
   - Returns: location-specific errors (Session X, Block Y)

3. **`validate_data_values()`** - Numeric value range validation
   - **Loads:** 0-500kg (error if > 500, warning if > 300)
   - **Reps:** 1-200 (error if > 200, warning if > 50)
   - **Sets:** 1-10 (warning if > 8)
   - **Times:** 1-7200 seconds (error if > 3 hours)
   - **RPE:** 1-10 (supports 0.5 increments)
   - **RIR:** 0-10
   - Validates both prescription and performed values

4. **`validate_catalog_references()`** - Exercise and equipment validation
   - Checks exercise_name exists in lib_exercise_catalog or lib_exercise_aliases
   - Checks equipment_key exists in lib_equipment_catalog or lib_equipment_aliases
   - Returns: catalog lookup failures with exercise/equipment name

5. **`validate_prescription_performance_separation()`** - Critical business rule
   - **Prevents mixing of prescription/performance data** (core architecture principle)
   - Detects forbidden keys in wrong context:
     - Prescription cannot have: actual_sets, reps_performed, did_complete
     - Performed cannot have: target_sets, target_reps, target_load
   - Returns: separation violations with specific key names

**Master Function:**
6. **`validate_parsed_workout(draft_id, parsed_json)`** - All-in-one validation
   - Runs all 5 validation checks sequentially
   - Returns comprehensive report:
     - `validation_status`: 'pass', 'warning', or 'fail'
     - `total_checks`, `errors`, `warnings`, `info` counts
     - `report`: Full JSONB with categorized issues
   - Designed for Stage 3 workflow integration

**Key Benefits:**
- ✅ **Automated quality control** before commit
- ✅ **Prevents invalid data** from entering production tables
- ✅ **Detailed error reports** with exact field locations
- ✅ **3-tier severity system**: error (blocks commit), warning (review), info (FYI)
- ✅ **Production-ready** with comprehensive error handling

#### ✅ Workflow Integration Documentation
**Created:** `docs/guides/VALIDATION_WORKFLOW_EXAMPLES.sql` (7 scenarios)

**Scenario 1:** Validate draft before commit (manual)
**Scenario 2:** Batch validation of all pending drafts
**Scenario 3:** Safe commit workflow (only commit if validated)
**Scenario 4:** Query validation reports (analytics)
**Scenario 5:** Individual validation checks (debugging)
**Scenario 6:** `v_draft_validation_status` view (dashboard-ready)
**Scenario 7:** `auto_validate_and_commit()` function (automation)

**Automated Workflow Function:**
```sql
auto_validate_and_commit(draft_id UUID)
-- Returns: success (boolean), workout_id (UUID), message (text)
-- Usage: SELECT * FROM zamm.auto_validate_and_commit('draft-uuid');
```

**Integration Points:**
- Plugs directly into existing Stage 3 (after parsing, before commit)
- Logs results to `log_validation_reports` table
- View for dashboard: `v_draft_validation_status`

### 📚 Documentation

#### ✅ PARSER_WORKFLOW.md (600+ lines)
**Created:** Complete parser workflow documentation
- 4-stage pipeline breakdown (Ingestion → Parsing → Validation → Commit)
- 18 tables involved in parser workflow
- 5 AI tools available (check_athlete_exists, normalize_block_type, etc.)
- End-to-end example (raw text → JSON → relational tables)
- Error handling guide
- Best practices for AI agents and developers
**Created:** Comprehensive validation checklist
- 4 audit phases: Structure → Data → Consistency → Business Logic
- Detailed checklists by block type (STR, METCON, INTV, SS)
- Data validation rules:
  - Loads: 0-500kg
  - Reps: 1-100
  - RPE: 1-10 (with 0.5 increments)
  - Times: 1-7200 seconds
- 3 severity levels: ERROR (blocks commit), WARNING (review), INFO (FYI)
- SQL validation script templates
- JSON validation report format
- Manual review workflow

#### ✅ VALIDATION_WORKFLOW_EXAMPLES.sql (300+ lines)
**Created:** Practical SQL examples for validation integration
- 7 complete workflow scenarios
- Copy-paste ready code
- Production deployment patterns
- n8n integration examples

---

## [1.1.0] - January 7, 2026

### Fixes

#### ✅ Table Reference Corrections (Migration: 20260107140000)
- **Fixed SQL functions** to use correct table names
- **Updated References:**
  - `dim_athletes` → `lib_athletes` in all functions
  - `workouts` → `workout_main` in get_athlete_context()
- **Functions Fixed:**
  - `calculate_load_from_bodyweight()` - Now queries lib_athletes
  - `check_athlete_exists()` - Updated to lib_athletes
  - `get_athlete_context()` - Fixed workout_main reference
- **Impact:** Functions now work correctly with current schema

### Documentation

#### ✅ agents.md - Source of Truth for AI Agents
- **Created comprehensive AI agent guide** (494 lines)
- **PROTOCOL ZERO:** Mandatory startup handshake for database connectivity
- **Identity & Authority:** AI agents as Operators with full execution authority
- **Critical Business Rules:**
  - Rule #1: Exercise name normalization via `check_exercise_exists()`
  - Rule #2: Atomic commits via `commit_full_workout_v3()` stored procedure
  - Rule #3: Prescription vs Performance separation
- **Complete architecture reference**, coding standards, and quick reference guide
- **Purpose:** Single source of truth for all AI agents working on project

#### ⚠️ Schema Synchronization
- **Discovered table naming mismatch** between function code and actual tables
- **Schema dumped successfully** using `supabase db dump` (bypassed Docker issue)
- **Migration 20260107120000 CANCELLED** (used incorrect table names)
- **agents.md UPDATED** with correct table names: `lib_athletes`, `workout_main`, `lib_parser_rulesets`, etc.
- **Migration history repaired:** 37 extra migrations marked as reverted
- **Status:** Schema synchronized, ready for clean data entry

---

## [1.0.0] - January 4-7, 2026

### Major Features Implemented

#### ✅ Database Schema Complete
- **Hierarchical Workout Structure**: workouts → sessions → blocks → items → set_results
- **Staging Pipeline**: imports → parse_drafts → validation_reports → draft_edits
- **Results Tracking**: item_set_results, workout_block_results, interval_segments
- **Infrastructure**: dim_athletes, parser_rulesets, equipment_catalog/aliases

#### ✅ Block Type System (Migration: 20260104140000)
- **17 Standardized Block Types** across 5 categories (Preparation, Strength, Power, Skill, Conditioning, Recovery)
- **60+ Aliases** supporting English, abbreviations, and Hebrew
- **UI Hints** for frontend rendering guidance
- **normalize_block_code()** function for automatic type normalization

#### ✅ Exercise Catalog System (Migration: 20260104130000)
- **exercise_catalog** table with 14 seed exercises
- **exercise_aliases** supporting multiple names per exercise
- Rich metadata: category, movement_pattern, muscles, difficulty, equipment
- Indexes for fast lookups and fuzzy matching

#### ✅ AI Tools (Migration: 20260104120000)
Five SQL functions for AI agents:
- `check_athlete_exists(name)` - Athlete lookup
- `check_equipment_exists(name)` - Equipment validation
- `get_active_ruleset()` - Parser rules retrieval
- `get_athlete_context(id)` - Full athlete context
- `normalize_block_type(type)` - Block type normalization

#### ✅ Validation Functions (Migration: 20260104120100)
Five data quality checks:
- `validate_prescription_structure()`
- `validate_performance_data()`
- `validate_exercise_names()`
- `validate_units_consistency()`
- `validate_date_ranges()`

#### ✅ Stored Procedures
- `commit_full_workout_v2()` - Normalized JSON to relational conversion
- `commit_full_workout_v3()` - Enhanced prescription/performance separation with detailed set results

### Documentation Created

#### Core Documentation (Root Level)
- `README.md` - Project overview and quick start
- `DB_READINESS_REPORT.md` - Database status report (85/100 score)
- `LICENSE` - Project license

#### Guides (docs/guides/)
- `AI_PROMPTS.md` - AI agent prompt templates (335 lines)

#### Reference (docs/reference/)
- `BLOCK_TYPES_REFERENCE.md` - Complete block type catalog (307 lines)
- `BLOCK_TYPE_SYSTEM_SUMMARY.md` - Block type system overview (239 lines)

#### API Documentation (docs/api/)
- `QUICK_TEST_QUERIES.sql` - Sample SQL queries for testing

#### Archive (docs/archive/)
Historical implementation records:
- `IMPLEMENTATION_COMPLETE.md` - Initial implementation summary
- `PRIORITY1_COMPLETE.md` - Exercise catalog completion report
- `DB_ARCHITECTURE_REVIEW.md` - Architecture review (88/100 score)
- `COMMIT_WORKOUT_V3_UPDATE.md` - v3 stored procedure update notes

### Key Design Decisions

#### Prescription vs Performance Separation
The core architecture separates planned workouts from actual execution:
- **Prescription**: What the program says to do ("3x5 @ 100kg")
- **Performance**: What actually happened ("got only 4 reps on last set")

This separation enables:
- Better progress tracking
- Program adherence analysis
- Realistic performance data for AI coaching

#### 4-Stage Workflow
1. **Context & Ingestion** - Text capture + athlete identification
2. **Parsing Agent** - Separation of prescription from performance
3. **Validation & Normalization** - Quality control + error correction
4. **Atomic Commit** - Single-transaction database save

### Database Statistics
- **Total Tables**: 20+ (infrastructure, staging, core workout, results)
- **Stored Procedures**: 3 versions of commit_full_workout
- **SQL Tools for AI**: 5 functions
- **Validation Functions**: 5 functions
- **Migrations**: 6 schema migrations
- **Sample Data**: 10 workout log files

### Project Status
**Overall Readiness**: 85/100
- Infrastructure: 100% ✅
- Staging Tables: 100% ✅
- Core Workout Schema: 100% ✅
- Results Tracking: 90% ✅
- AI Tools: 100% ✅
- Documentation: 95% ✅

### Next Steps (Future)
- Implement AI agent orchestration layer
- Add real-time validation during parsing
- Build analytics dashboard
- Enhance exercise catalog with videos
- Add multi-language support for more languages
