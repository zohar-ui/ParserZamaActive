# n8n Integration Guide
## ZAMM Workout Parser - Complete Setup

This guide shows you how to integrate all the SQL Tools, Prompts, and Validation functions into your n8n workflow.

---

## 📋 Prerequisites

1. ✅ Supabase CLI connected (already done!)
2. ✅ SQL Tools functions deployed (from migrations)
3. ✅ Prompt templates ready (in docs/AI_PROMPTS.md)
4. ✅ Validation functions deployed

---

## 🔧 Step 1: Deploy SQL Functions to Supabase

```bash
# Push the new migrations to Supabase
cd /workspaces/ParserZamaActive
supabase db push

# Or apply them manually via Supabase Dashboard SQL Editor
# Copy contents from:
# - supabase/migrations/20260104120000_create_ai_tools.sql
# - supabase/migrations/20260104120100_create_validation_functions.sql
```

---

## 🤖 Step 2: Configure n8n AI Agent Node

### Node: **AI Agent - Workout Parser**

#### Agent Configuration

**Type:** `AI Agent`
**Model:** OpenAI GPT-4 / Claude / Gemini (your choice)

#### System Prompt
Copy the entire "System Prompt - Main Parser Agent" from `docs/AI_PROMPTS.md`

Key sections to include:
```
You are an expert workout parser specialized in analyzing CrossFit/strength training logs.

PRIMARY MISSION:
Parse workout text and SEPARATE what was PLANNED (prescription) from what was ACTUALLY DONE (performance).

[... rest of prompt from AI_PROMPTS.md ...]
```

#### Structured Output Schema

Set the agent to return structured JSON with this schema:

```json
{
  "type": "object",
  "properties": {
    "sessions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "sessionInfo": {
            "type": "object",
            "properties": {
              "date": {"type": "string", "format": "date"},
              "title": {"type": "string"}
            },
            "required": ["date"]
          },
          "blocks": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "block_code": {"type": "string"},
                "block_type": {"type": "string"},
                "name": {"type": "string"},
                "prescription": {
                  "type": "object",
                  "properties": {
                    "structure": {"type": "string"},
                    "steps": {"type": "array"}
                  }
                },
                "performed": {
                  "type": "object",
                  "properties": {
                    "did_complete": {"type": "boolean"},
                    "total_time_sec": {"type": "number"},
                    "steps": {"type": "array"}
                  }
                }
              },
              "required": ["block_code", "block_type", "prescription"]
            }
          }
        },
        "required": ["sessionInfo", "blocks"]
      }
    }
  },
  "required": ["sessions"]
}
```

---

## 🔨 Step 3: Add SQL Tools to the Agent

### Tool 1: Check Athlete Exists

**Node Type:** `Postgres` (Tool)
**Tool Name:** `check_athlete_exists`
**Description:** "Search for an athlete by name to get their ID and info"

**SQL Query:**
```sql
SELECT * FROM zamm.check_athlete_exists({{ $json.search_name }});
```

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "search_name": {
      "type": "string",
      "description": "Athlete name to search for"
    }
  },
  "required": ["search_name"]
}
```

---

### Tool 2: Check Equipment Exists

**Node Type:** `Postgres` (Tool)
**Tool Name:** `check_equipment_exists`
**Description:** "Validate equipment name and get standardized key"

**SQL Query:**
```sql
SELECT * FROM zamm.check_equipment_exists({{ $json.search_name }});
```

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "search_name": {
      "type": "string",
      "description": "Equipment name to validate"
    }
  },
  "required": ["search_name"]
}
```

---

### Tool 3: Get Active Ruleset

**Node Type:** `Postgres` (Tool)
**Tool Name:** `get_active_ruleset`
**Description:** "Get the current parser ruleset with unit conversion rules"

**SQL Query:**
```sql
SELECT * FROM zamm.get_active_ruleset();
```

**Input Schema:**
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

---

### Tool 4: Normalize Block Type

**Node Type:** `Postgres` (Tool)
**Tool Name:** `normalize_block_type`
**Description:** "Validate and normalize a block type name"

**SQL Query:**
```sql
SELECT * FROM zamm.normalize_block_type({{ $json.block_type }});
```

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "block_type": {
      "type": "string",
      "description": "Block type to normalize (e.g., 'strength', 'metcon')"
    }
  },
  "required": ["block_type"]
}
```

---

### Tool 5: Get Athlete Context

**Node Type:** `Postgres` (Tool)
**Tool Name:** `get_athlete_context`
**Description:** "Get full context for an athlete including recent workout stats"

**SQL Query:**
```sql
SELECT * FROM zamm.get_athlete_context({{ $json.athlete_id }}::uuid);
```

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "athlete_id": {
      "type": "string",
      "description": "UUID of the athlete"
    }
  },
  "required": ["athlete_id"]
}
```

---

## 🔍 Step 4: Add Validation Node

### Node: **Validate Parsed Draft**

**Node Type:** `Postgres`
**Position:** After AI Agent, before Commit

**SQL Query:**
```sql
SELECT * FROM zamm.validate_and_save_report(
  {{ $json.draft_id }}::uuid,
  {{ $json.parsed_json }}::jsonb
);
```

**Inputs:**
- `draft_id` - from previous "Save Draft" node
- `parsed_json` - from AI Agent output

**Output:**
Returns `report_id` UUID

---

## 🔀 Step 5: Add Conditional Logic

### Node: **Check Validation Result**

**Node Type:** `IF`

**Condition:**
```javascript
// Get validation status
const validation = await this.getWorkflowStaticData('node', 'get_draft_validation_status');

// Check if valid
if (validation.is_valid && validation.error_count === 0) {
  return true; // Proceed to commit
} else {
  return false; // Send to manual review
}
```

**True Branch:** → Commit to Database (call `commit_full_workout_v2`)
**False Branch:** → Send to Notion / Slack for manual review

---

## 📊 Step 6: Complete Workflow Structure

```
┌─────────────────────────────────────────────────────────┐
│ 1. Trigger (Webhook / Manual)                           │
│    - Receives raw workout text                          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Insert into imports table                            │
│    INSERT INTO zamm.imports (raw_text, source, ...)     │
│    RETURNS: import_id                                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Get Active Ruleset                                   │
│    Tool: get_active_ruleset()                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 4. AI Agent - Workout Parser                            │
│    - System Prompt (from AI_PROMPTS.md)                 │
│    - Tools: check_athlete_exists, check_equipment, etc. │
│    - Structured Output: JSON with prescription/performed│
│    RETURNS: parsed_json                                 │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Save Draft                                            │
│    INSERT INTO zamm.parse_drafts                        │
│    RETURNS: draft_id                                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 6. Validate Draft                                        │
│    zamm.validate_and_save_report(draft_id, parsed_json) │
│    RETURNS: report_id                                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ 7. Get Validation Status                                │
│    zamm.get_draft_validation_status(draft_id)           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
           ┌─────┴─────┐
           │    IF     │
           │ is_valid? │
           └─────┬─────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
  ✅ Valid           ❌ Invalid
        │                 │
        ▼                 ▼
┌──────────────┐   ┌──────────────┐
│ 8a. Commit   │   │ 8b. Send to  │
│ Full Workout │   │ Manual Review│
│              │   │ (Notion/Slack│
│ commit_full_ │   └──────────────┘
│ workout_v2() │
└──────────────┘
```

---

## 🎯 Step 7: Commit Node Configuration

### Node: **Commit Full Workout**

**Node Type:** `Postgres`

**SQL Query:**
```sql
SELECT zamm.commit_full_workout_v2(
  p_import_id := {{ $json.import_id }}::uuid,
  p_draft_id := {{ $json.draft_id }}::uuid,
  p_ruleset_id := {{ $json.ruleset_id }}::uuid,
  p_athlete_id := {{ $json.athlete_id }}::uuid,
  p_normalized_json := {{ $json.parsed_json }}::jsonb
);
```

**Returns:** `workout_id` UUID

---

## 🔔 Step 8: Manual Review Integration (Optional)

### Node: **Send to Notion**

**Node Type:** `Notion`
**Action:** Create Database Item

**Fields:**
- Title: "Review Needed: {{ $json.athlete_name }} - {{ $json.date }}"
- Status: "Needs Review"
- Draft ID: {{ $json.draft_id }}
- Errors: {{ $json.validation_errors }}
- Raw Text: {{ $json.raw_text }}

---

## 🧪 Step 9: Testing Workflow

### Test Case 1: Simple Plan Only
```
Input Text:
"Back Squat: 5x5 @ 100kg"

Expected Output:
- prescription: {sets: 5, reps: 5, load: 100kg}
- performed: null
- is_valid: true
```

### Test Case 2: Plan + Performance
```
Input Text:
"Back Squat: 3x5 @ 100kg. Did it, but last set only 4 reps."

Expected Output:
- prescription: {sets: 3, reps: 5, load: 100kg}
- performed: [
    {set: 1, reps: 5, load: 100},
    {set: 2, reps: 5, load: 100},
    {set: 3, reps: 4, load: 100, notes: "..."}
  ]
- is_valid: true
- warnings: ["Actual reps differ from target"]
```

### Test Case 3: Invalid Data
```
Input Text:
"Squat: 1000kg"

Expected Output:
- validation.warnings: ["Load exceeds 500kg - verify"]
- needs_review: true
```

---

## 📝 Step 10: Environment Variables

Add these to your n8n environment:

```env
SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
OPENAI_API_KEY=your_openai_key  # Or other AI provider
```

---

## 🚀 Quick Start Commands

```bash
# 1. Push migrations
cd /workspaces/ParserZamaActive
supabase db push

# 2. Verify functions exist
supabase db remote exec "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'zamm' AND routine_type = 'FUNCTION';"

# 3. Test a function manually
supabase db remote exec "SELECT * FROM zamm.check_athlete_exists('John');"

# 4. Import n8n workflow (if you have a JSON export)
# n8n import:workflow --input=workflow.json
```

---

## 📊 Monitoring & Debugging

### Check Validation Reports
```sql
SELECT 
  vr.report_id,
  vr.is_valid,
  jsonb_array_length(vr.errors) as error_count,
  jsonb_array_length(vr.warnings) as warning_count,
  vr.created_at
FROM zamm.validation_reports vr
ORDER BY vr.created_at DESC
LIMIT 10;
```

### Check Pending Drafts
```sql
SELECT 
  pd.draft_id,
  pd.stage,
  pd.confidence_score,
  pd.created_at,
  (SELECT COUNT(*) FROM zamm.validation_reports WHERE draft_id = pd.draft_id) as has_validation
FROM zamm.parse_drafts pd
WHERE pd.approved_at IS NULL
  AND pd.rejected_at IS NULL
ORDER BY pd.created_at DESC;
```

### Batch Validate All Pending
```sql
SELECT * FROM zamm.validate_pending_drafts();
```

---

## 🎓 Training the AI

### Fine-tuning Tips

1. **Collect Real Examples:** Save 20-30 real workout texts with correct outputs
2. **Update Prompts:** Add examples to the system prompt
3. **Iterate:** Track validation error patterns and update prompts accordingly

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| AI confuses prescription with performance | Add more explicit examples in prompt |
| Block types always "unknown" | Use `normalize_block_type` tool more |
| Load values unrealistic | Strengthen validation warnings |
| Missing set_index | Add strict validation rule |

---

## ✅ Checklist

- [ ] SQL functions deployed to Supabase
- [ ] n8n AI Agent node configured with system prompt
- [ ] All 5 SQL Tools added to agent
- [ ] Structured output schema configured
- [ ] Validation node added to workflow
- [ ] Conditional branching for valid/invalid
- [ ] Commit node configured
- [ ] Manual review integration (Notion/Slack)
- [ ] Test cases passing
- [ ] Monitoring queries saved

---

## 🆘 Troubleshooting

### Problem: Tools not working
**Solution:** Check Supabase permissions:
```sql
GRANT EXECUTE ON FUNCTION zamm.check_athlete_exists TO service_role;
GRANT EXECUTE ON FUNCTION zamm.check_equipment_exists TO service_role;
-- etc...
```

### Problem: AI returns invalid JSON
**Solution:** Strengthen the structured output schema in n8n

### Problem: Validation always fails
**Solution:** Check validation thresholds in `validate_workout_draft` function

---

## 📚 Additional Resources

- [Supabase Functions Docs](https://supabase.com/docs/guides/database/functions)
- [n8n AI Agent Docs](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/)
- [OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs)

---

**Next Steps:** Start with a simple test workflow in n8n and gradually add complexity!
