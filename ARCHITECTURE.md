# Architecture Overview

## System Purpose
ZAMM Workout Parser is an AI-powered system that transforms free-form workout text into structured relational data, with a critical focus on separating workout **prescription** (what was planned) from **performance** (what actually happened).

## Core Concepts

### Prescription vs Performance
The fundamental architectural principle:
- **Prescription**: The planned workout ("Back Squat 3x5 @ 100kg")
- **Performance**: The actual execution ("Last set only got 4 reps, RPE 9.5")

This separation enables accurate progress tracking, program adherence analysis, and intelligent coaching recommendations.

## Data Flow

```
┌─────────────┐
│ Raw Text    │ WhatsApp logs, coach notes, athlete diaries
└──────┬──────┘
       ↓
┌──────────────────────┐
│ Stage 1: Ingestion   │ Save to imports table, identify athlete
└──────┬───────────────┘
       ↓
┌──────────────────────┐
│ Stage 2: AI Parsing  │ Extract prescription + performance JSONs
└──────┬───────────────┘
       ↓
┌──────────────────────┐
│ Stage 3: Validation  │ Quality checks, normalization, error reports
└──────┬───────────────┘
       ↓
┌──────────────────────┐
│ Stage 4: Commit      │ Atomic save to relational tables
└──────────────────────┘
```

## Database Architecture

### Layered Structure

#### 1. Infrastructure Layer
- `dim_athletes` - Athlete profiles (height, weight, age)
- `parser_rulesets` - Parsing rules and unit conversions
- `equipment_catalog` + `equipment_aliases` - Equipment definitions
- `exercise_catalog` + `exercise_aliases` - Exercise definitions
- `block_type_catalog` + `block_code_aliases` - Block type standards

#### 2. Staging Layer
- `imports` - Original raw text
- `parse_drafts` - AI-generated JSON (parsed + normalized)
- `validation_reports` - Error and warning logs
- `draft_edits` - Manual correction tracking

#### 3. Core Workout Layer (Hierarchical)
```
workouts (workout_id)
  └─ workout_sessions (session_id)
      └─ workout_blocks (block_id)
          ├─ prescription (JSONB) ──┐
          ├─ performed (JSONB)      │ Flexible structures
          └─ workout_items (item_id)│
              ├─ prescription_data ──┘
              └─ performed_data
```

#### 4. Results Layer (Denormalized for Analytics)
- `item_set_results` - Individual set details (reps, load, RPE, RIR)
- `workout_block_results` - Block-level summaries (time, completion, score)
- `interval_segments` - Interval-specific data (work/rest splits)

### Why This Design?

**Flexibility + Structure**:
- JSONB fields (`prescription`, `performed`) handle diverse workout formats
- Relational tables enable complex queries and analytics
- Denormalized results speed up common queries

**Audit Trail**:
- Every stage preserved (raw text → draft → validated → committed)
- Manual edits tracked separately
- Full history for debugging and improvement

## Key Components

### 1. AI Tools (SQL Functions)
Five functions AI agents can call:
```sql
check_athlete_exists(name TEXT)           -- Find athlete by name
check_equipment_exists(name TEXT)         -- Validate equipment
get_active_ruleset()                      -- Get parser rules
get_athlete_context(athlete_id UUID)     -- Full athlete profile
normalize_block_type(type TEXT)           -- Standardize block types
```

### 2. Stored Procedures
```sql
commit_full_workout_v3(
  p_import_id UUID,
  p_draft_id UUID,
  p_ruleset_id UUID,
  p_athlete_id UUID,
  p_normalized_json JSONB
) RETURNS UUID
```
Atomically converts normalized JSON into relational records.

### 3. Block Type System
17 standardized block types across 5 categories:
- **PREPARATION**: WU (Warm-Up), ACT (Activation), MOB (Mobility)
- **STRENGTH**: STR (Strength), ACC (Accessory), HYP (Hypertrophy)
- **POWER**: PWR (Power), WL (Weightlifting)
- **SKILL**: SKILL, GYM (Gymnastics)
- **CONDITIONING**: METCON, INTV (Intervals), SS (Steady State), HYROX
- **RECOVERY**: CD (Cool-Down), STRETCH, BREATH (Breathwork)

Each block type includes:
- `result_model` - How to track results (tracked_sets, scored_effort, completion)
- `ui_hint` - Frontend rendering guidance (table, card, list)

## Technology Stack

- **Database**: Supabase (PostgreSQL)
- **Schema**: `zamm`
- **AI Integration**: n8n workflows with OpenAI/Claude/Gemini
- **Project ID**: `dtzcamerxuonoeujrgsu`

## Design Patterns

### 1. Catalog + Aliases Pattern
Used for equipment, exercises, and block types:
```sql
-- Master catalog
exercise_catalog (exercise_key, display_name, metadata...)

-- Multiple names map to one canonical key
exercise_aliases (alias → exercise_key)
```

### 2. Prescription + Performance Pattern
All workout entities store both:
```json
{
  "prescription": { /* what was planned */ },
  "performed": { /* what actually happened */ }
}
```

### 3. Staged Transformation Pattern
```
Raw Text → Draft JSON → Normalized JSON → Relational Tables
   ↓          ↓             ↓                 ↓
imports  parse_drafts  validation       workout_*
```

## Scalability Considerations

- **Indexes**: Key lookups on athlete names, exercise names, equipment
- **JSONB**: GIN indexes for fast JSON queries
- **Partitioning**: Future partition workouts by date
- **Caching**: Rulesets and catalogs are stable, cache-friendly

## Future Enhancements

1. **Real-time Validation**: Validate during parsing, not after
2. **Multi-language Support**: Extend Hebrew/English to more languages
3. **Video Integration**: Link exercises to demonstration videos
4. **Analytics Views**: Pre-computed materialized views for dashboards
5. **Event Sourcing**: Consider event log for full replay capability
