#!/bin/bash
set -e

echo "=== ACTIVE LEARNING SYSTEM DEMONSTRATION ==="
echo ""

# Load password
export SUPABASE_DB_PASSWORD=$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2)
DB_HOST="db.dtzcamerxuonoeujrgsu.supabase.co"

echo "📥 Step 1: Inserting a learning example..."
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h "$DB_HOST" -U postgres -d postgres -q << 'EOF'
INSERT INTO zamm.log_learning_examples (
  original_text,
  original_json,
  corrected_json,
  error_type,
  error_location,
  error_description,
  correction_notes,
  learning_priority,
  tags
) VALUES (
  E'Block C - Landmine Press: 3×8/side @ RPE 5.5-6\nRight shoulder hurt 5/10. Bar only (20kg).',
  '{"block_code":"STR","items":[{"exercise_name":"Landmine Press","prescription":{"target_sets":3,"target_reps":8,"target_weight_kg":20,"notes":"Pain in shoulder"}}]}'::jsonb,
  '{"block_code":"STR","prescription":{"description":"3×8/side @ RPE 5.5-6"},"performed":{"actual_weight_kg":20,"notes":"Right shoulder hurt 5/10. Bar only (20kg)."},"items":[{"exercise_name":"Landmine Press","prescription":{"target_sets":3,"target_reps":8,"target_sets_per_side":1},"performed":{"actual_weight_kg":20}}]}'::jsonb,
  'prescription_performance_mix',
  'block.items[0].prescription',
  'Parser placed performed data (actual weight, pain notes) inside prescription object',
  'CRITICAL: Prescription = PLANNED. Performed = ACTUAL. Never mix them! Actual weight and pain notes belong in performed.',
  9,
  ARRAY['prescription_performance_separation', 'the_great_divide']
)
ON CONFLICT DO NOTHING;
EOF

echo "✅ Example inserted!"
echo ""

echo "📊 Step 2: Checking database..."
EXAMPLE_COUNT=$(PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h "$DB_HOST" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM zamm.log_learning_examples WHERE is_included_in_training = false AND learning_priority >= 7;")
echo "   Found $EXAMPLE_COUNT untrained examples (priority >= 7)"
echo ""

echo "🤖 Step 3: Running Active Learning Loop..."
npm run learn
echo ""

echo "📄 Step 4: Checking if AI_PROMPTS.md was updated..."
if grep -q "PRESCRIPTION_PERFORMANCE_MIX" docs/guides/AI_PROMPTS.md; then
  echo "✅ SUCCESS! Example was injected into prompts!"
  echo ""
  echo "📚 View the learning section:"
  sed -n '/## 🧠 Dynamic Learning Examples/,/## Prompt - Validation Agent/p' docs/guides/AI_PROMPTS.md | head -40
else
  echo "⚠️  Example not found in prompts file yet"
fi
