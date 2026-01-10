# 🔧 Active Learning System - Environment Setup

**For:** First-time setup of the active learning loop

---

## ⚠️ Prerequisites

Before running `npm run learn`, you need:

1. ✅ Supabase database access
2. ✅ Environment variables configured
3. ✅ NPM dependencies installed

---

## 📝 Step-by-Step Setup

### Step 1: Check Environment Variables

The script needs access to your Supabase database. It looks for these variables:

```bash
SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
# OR
SUPABASE_SERVICE_KEY=your-service-key-here
# OR
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

---

### Step 2: Create/Update `.env.local`

**Option A: File already exists**

Check if `.env.local` exists:
```bash
ls -la .env.local
```

If it exists, verify it has the required keys:
```bash
cat .env.local | grep SUPABASE
```

**Option B: Create new file**

```bash
# Create .env.local in project root
cat > .env.local << 'EOF'
SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co
SUPABASE_ANON_KEY=your-actual-key-here
EOF
```

---

### Step 3: Get Your Supabase Keys

**Method 1: Supabase Dashboard**

1. Go to: https://app.supabase.com/project/dtzcamerxuonoeujrgsu/settings/api
2. Copy "Project URL" → `SUPABASE_URL`
3. Copy "anon public" key → `SUPABASE_ANON_KEY`
4. (Optional) Copy "service_role" key → `SUPABASE_SERVICE_KEY` (if you need write access)

**Method 2: Supabase CLI**

```bash
# Get project URL
npx supabase status | grep "API URL"

# Get keys (requires auth)
npx supabase projects api-keys --project-ref dtzcamerxuonoeujrgsu
```

**Method 3: Check existing config**

```bash
# Check if Supabase CLI has credentials
cat ~/.supabase/config.toml
```

---

### Step 4: Install Dependencies

```bash
cd /workspaces/ParserZamaActive
npm install
```

**Expected output:**
```
added 13 packages, and audited 14 packages in 2s
found 0 vulnerabilities
```

---

### Step 5: Test Database Connection

**Quick test:**
```bash
# Test if environment variables are loaded
node -e "require('dotenv').config({path:'.env.local'}); console.log('URL:', process.env.SUPABASE_URL); console.log('Key:', process.env.SUPABASE_ANON_KEY ? 'Found' : 'Missing');"
```

**Full test (using psql):**
```bash
# Extract DB password from .env.local
DB_PASSWORD=$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2)

# Test connection
PGPASSWORD="$DB_PASSWORD" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres -c "SELECT COUNT(*) FROM zamm.log_learning_examples;"
```

---

### Step 6: Run the Learning Loop

```bash
npm run learn
```

**Expected output (if no examples yet):**
```
🤖 ACTIVE LEARNING LOOP - Starting...
✅ Supabase client initialized
📥 Fetching untrained learning examples...
   Found 0 examples (priority >= 7)
✨ No new examples to train! Parser is up to date.
   Run validation and make corrections to generate new examples.
```

---

## 🐛 Troubleshooting

### Issue 1: "SUPABASE_SERVICE_KEY not found"

**Symptom:**
```
❌ ERROR: SUPABASE_SERVICE_KEY or SUPABASE_ANON_KEY not found in environment
   Please set it in .env.local file
```

**Solution:**
```bash
# Check if .env.local exists
ls -la .env.local

# If missing, create it
cat > .env.local << 'EOF'
SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
EOF

# Verify
cat .env.local
```

---

### Issue 2: "Cannot find module '@supabase/supabase-js'"

**Symptom:**
```
Error: Cannot find module '@supabase/supabase-js'
```

**Solution:**
```bash
npm install @supabase/supabase-js
```

---

### Issue 3: "Connection refused" or "Invalid API key"

**Symptoms:**
- Script hangs
- "FetchError: request to https://... failed"
- "Invalid API key"

**Solution:**
```bash
# 1. Test direct connection
curl https://dtzcamerxuonoeujrgsu.supabase.co/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# 2. Check Supabase CLI status
npx supabase status

# 3. Verify project link
npx supabase projects list
```

---

### Issue 4: "table zamm.log_learning_examples does not exist"

**Symptom:**
```
Database query failed: relation "zamm.log_learning_examples" does not exist
```

**Solution:**
```bash
# Check if migration was applied
PGPASSWORD="$DB_PASSWORD" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
  -c "SELECT table_name FROM information_schema.tables WHERE table_schema='zamm' AND table_name='log_learning_examples';"

# If empty, run migration
npx supabase db push

# Or apply specific migration
PGPASSWORD="$DB_PASSWORD" psql -h db.dtzcamerxuonoeujrgsu.supabase.co -U postgres -d postgres \
  -f supabase/migrations/20260109160000_active_learning_system.sql
```

---

### Issue 5: Script runs but "Found 0 examples"

**This is EXPECTED if you haven't created any learning examples yet!**

**To create a test example:**

```sql
-- Run this in Supabase SQL Editor or psql
SELECT zamm.capture_learning_example(
    p_draft_id := NULL,
    p_validation_report_id := NULL,
    p_original_text := 'Test workout: 5x5 squat',
    p_original_json := '{"prescription": {"target_reps": 5}, "performed": null}'::jsonb,
    p_corrected_json := '{"prescription": {"target_reps": 5}, "performed": {"actual_reps": 5}}'::jsonb,
    p_error_type := 'missing_field',
    p_error_location := 'blocks[0].performed',
    p_error_description := 'Test example for learning loop',
    p_corrected_by := 'human',
    p_correction_notes := 'This is a test example',
    p_learning_priority := 8,
    p_tags := ARRAY['test']
);

-- Then run the learning loop again
```

---

## 🔐 Security Best Practices

### ✅ DO:
- Keep `.env.local` in `.gitignore` (already configured)
- Use `SUPABASE_ANON_KEY` for read-only operations
- Use `SUPABASE_SERVICE_KEY` only when needed
- Never commit keys to git

### ❌ DON'T:
- Share keys in chat/email
- Use production keys in development
- Commit `.env.local` to version control

---

## 📋 Verification Checklist

Before reporting issues, verify:

- [ ] `.env.local` file exists
- [ ] SUPABASE_URL is set
- [ ] SUPABASE_ANON_KEY or SUPABASE_SERVICE_KEY is set
- [ ] npm install completed successfully
- [ ] Database connection works (test with psql)
- [ ] Migration `20260109160000_active_learning_system.sql` is applied
- [ ] Table `zamm.log_learning_examples` exists

**Check all:**
```bash
# 1. File exists
[ -f .env.local ] && echo "✅ .env.local exists" || echo "❌ .env.local missing"

# 2. Variables set
grep -q SUPABASE_URL .env.local && echo "✅ SUPABASE_URL set" || echo "❌ SUPABASE_URL missing"
grep -q SUPABASE_ANON_KEY .env.local && echo "✅ SUPABASE_ANON_KEY set" || echo "❌ SUPABASE_ANON_KEY missing"

# 3. Dependencies installed
[ -d node_modules ] && echo "✅ node_modules exists" || echo "❌ Run npm install"

# 4. Script executable
[ -x scripts/update_parser_brain.js ] && echo "✅ Script executable" || echo "❌ Run chmod +x"
```

---

## 🚀 Quick Setup Script

**Run this all-in-one setup:**

```bash
#!/bin/bash
# Active Learning Setup Script

echo "🔧 Setting up Active Learning System..."

# 1. Check .env.local
if [ ! -f .env.local ]; then
    echo "❌ .env.local not found!"
    echo "   Create it manually or run:"
    echo "   cat > .env.local << 'EOF'"
    echo "   SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co"
    echo "   SUPABASE_ANON_KEY=your-key-here"
    echo "   EOF"
    exit 1
fi

# 2. Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# 3. Test connection (requires node)
echo "🔌 Testing database connection..."
node -e "
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({path:'.env.local'});
const client = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_KEY
);
client.from('log_learning_examples').select('count').then(
    r => console.log('✅ Connection successful'),
    e => console.log('❌ Connection failed:', e.message)
);
"

# 4. Run learning loop
echo "🤖 Running learning loop..."
npm run learn

echo "✅ Setup complete!"
```

**Save as `scripts/setup_learning.sh` and run:**
```bash
chmod +x scripts/setup_learning.sh
./scripts/setup_learning.sh
```

---

## 📞 Need Help?

### Documentation:
- [ACTIVE_LEARNING_README.md](./ACTIVE_LEARNING_README.md) - Full system docs
- [ACTIVE_LEARNING_QUICKSTART.md](../ACTIVE_LEARNING_QUICKSTART.md) - Quick start

### Commands:
```bash
# Test environment
node -p "process.env.SUPABASE_URL"

# Test npm
npm --version

# Test database
npx supabase status
```

---

**Last Updated:** January 10, 2026  
**Status:** Setup Guide  
**Questions?** Check troubleshooting section above
