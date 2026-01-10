#!/bin/bash
set -e

echo "=========================================="
echo "🎓 ACTIVE LEARNING SYSTEM DEMONSTRATION"
echo "=========================================="
echo ""

# Load credentials
export PGPASSWORD=$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2)
DB_HOST="db.dtzcamerxuonoeujrgsu.supabase.co"

echo "📊 BEFORE: Checking database..."
COUNT_BEFORE=$(psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT COUNT(*) FROM zamm.log_learning_examples WHERE is_included_in_training = false AND learning_priority >= 7;")
echo "   Untrained examples: $COUNT_BEFORE"
echo ""

echo "📥 STEP 1: Inserting learning example..."
psql -h "$DB_HOST" -U postgres -d postgres -f demo_learning_example.sql -q -o /tmp/insert_result.txt
echo "✅ Example inserted!"
echo ""

echo "📊 AFTER INSERT: Checking database..."
COUNT_AFTER=$(psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT COUNT(*) FROM zamm.log_learning_examples WHERE is_included_in_training = false AND learning_priority >= 7;")
echo "   Untrained examples: $COUNT_AFTER"
echo ""

if [ "$COUNT_AFTER" -gt "0" ]; then
  echo "🤖 STEP 2: Running Active Learning Loop..."
  echo ""
  node scripts/update_parser_brain.js
  echo ""
  
  echo "📄 STEP 3: Checking AI_PROMPTS.md..."
  if grep -q "PRESCRIPTION_PERFORMANCE_MIX\|prescription_performance_mix" docs/guides/AI_PROMPTS.md; then
    echo "✅ SUCCESS! Learning example was injected into prompts!"
    echo ""
    echo "📚 Here's a preview of the learning section:"
    echo "----------------------------------------"
    sed -n '/## 🧠 Dynamic Learning Examples/,/## Prompt - Validation Agent/p' docs/guides/AI_PROMPTS.md | head -60
    echo "----------------------------------------"
  else
    echo "⚠️  Example not found in prompts yet"
  fi
  
  echo ""
  echo "📊 FINAL: Checking if example was marked as trained..."
  TRAINED_COUNT=$(psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT COUNT(*) FROM zamm.log_learning_examples WHERE is_included_in_training = true;")
  echo "   Trained examples: $TRAINED_COUNT"
else
  echo "⚠️  No new examples to process"
fi

echo ""
echo "=========================================="
echo "🎉 DEMONSTRATION COMPLETE!"
echo "=========================================="
