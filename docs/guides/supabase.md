# Supabase Database Access Guide

> **Quick reference for connecting to and querying the ParserZamaActive database**  
> Last Updated: January 9, 2026

---

## 📊 Database Info

**Project ID:** `dtzcamerxuonoeujrgsu`  
**Region:** US East  
**Schema:** `zamm` (32 tables)  
**PostgreSQL Version:** 17

---

## 🔑 Connection Details

### Environment Variables (from `.env.local`)
```bash
SUPABASE_URL=https://dtzcamerxuonoeujrgsu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Direct Connection String
```
postgresql://postgres:[password]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres
```

**⚠️ Password:** Get from Supabase dashboard → Database Settings

---

## 🛠️ Methods to Execute SQL

### Method 1: Supabase Dashboard (Recommended ✅)

**Best for:** Quick queries, testing, manual operations

```bash
# Open dashboard
npx supabase dashboard
```

**Steps:**
1. Navigate to **SQL Editor**
2. Paste your SQL query
3. Click **Run** or press `Ctrl+Enter`
4. View results in table format

**Pros:**
- ✅ No local tools needed
- ✅ Visual query builder available
- ✅ Syntax highlighting
- ✅ Query history saved
- ✅ Export results as CSV/JSON

**Cons:**
- ❌ Manual copy-paste for scripts
- ❌ Not scriptable/automatable

---

### Method 2: psql (PostgreSQL Client)

**Best for:** Running SQL files, automation, complex queries

#### Install psql
```bash
# On Ubuntu/Debian (Codespaces)
sudo apt-get update
sudo apt-get install -y postgresql-client

# Verify installation
psql --version
```

#### Run SQL File
```bash
# With connection string
psql "postgresql://postgres:[password]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" \
  -f scripts/check_all_tables.sql

# Or set PGPASSWORD environment variable
export PGPASSWORD="your-db-password"
psql -h db.dtzcamerxuonoeujrgsu.supabase.co \
     -U postgres \
     -d postgres \
     -f scripts/check_all_tables.sql
```

#### Interactive Session
```bash
psql "postgresql://postgres:[password]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres"

# Once connected:
\dt zamm.*          -- List all tables in zamm schema
\d zamm.workout_main -- Describe table structure
SELECT COUNT(*) FROM zamm.lib_athletes;
\q                  -- Quit
```

**Pros:**
- ✅ Run SQL files directly
- ✅ Scriptable/automatable
- ✅ Full PostgreSQL features
- ✅ Batch operations

**Cons:**
- ❌ Requires installation
- ❌ Need password management
- ❌ Less visual than dashboard

---

### Method 3: Supabase CLI (Comprehensive)

**Best for:** Development workflow, migrations, local testing

#### 🔵 1. Local Development Stack

Run full Supabase locally (Postgres + Auth + Storage + Realtime):

```bash
# Start local Supabase (Docker required)
npx supabase start

# Stop local stack
npx supabase stop

# Check status
npx supabase status

# View local dashboard
# Open: http://localhost:54323
```

**Use cases:**
- ✅ Test migrations before production
- ✅ Develop without internet
- ✅ Seed data for testing
- ✅ Run integration tests

**⚠️ Note:** This project uses **linked remote** database, not local. We skip `supabase start`.

---

#### 🔵 2. Database Migrations

Create, manage, and deploy schema changes:

```bash
# Create new migration
npx supabase migration new add_user_preferences

# This creates: supabase/migrations/YYYYMMDDHHMMSS_add_user_preferences.sql

# Check diff between local and remote
npx supabase db diff

# Generate migration from diff
npx supabase db diff -f new_migration_name

# Push migrations to remote
npx supabase db push

# Pull schema from remote
npx supabase db pull

# Reset local database to current migrations
npx supabase db reset
```

**Migration workflow example:**
```sql
-- supabase/migrations/20260109120000_add_user_preferences.sql
CREATE TABLE IF NOT EXISTS zamm.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    theme VARCHAR(20) DEFAULT 'light',
    notifications BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rollback (optional, for local testing)
-- DROP TABLE IF EXISTS zamm.user_preferences;
```

---

#### 🔵 3. Edge Functions

Create and deploy serverless functions:

```bash
# Create new Edge Function
npx supabase functions new workout-parser

# This creates: supabase/functions/workout-parser/index.ts

# Serve locally with hot reload
npx supabase functions serve workout-parser

# Deploy to remote
npx supabase functions deploy workout-parser

# List all functions
npx supabase functions list

# Delete function
npx supabase functions delete workout-parser
```

**Example Edge Function:**
```typescript
// supabase/functions/workout-parser/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { workout_text } = await req.json()
  
  // Parse workout logic here...
  
  return new Response(
    JSON.stringify({ parsed: true }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

---

#### 🔵 4. Secrets Management

Manage environment variables securely:

```bash
# Set secret
npx supabase secrets set OPENAI_API_KEY=sk-...

# Set multiple from .env file
npx supabase secrets set --env-file .env.production

# List secrets (values hidden)
npx supabase secrets list

# Unset secret
npx supabase secrets unset OPENAI_API_KEY
```

**Use in Edge Functions:**
```typescript
const apiKey = Deno.env.get('OPENAI_API_KEY')
```

---

#### 🔵 5. Project Management

Link, deploy, and manage projects:

```bash
# Login to Supabase
npx supabase login

# Link to existing project
npx supabase link --project-ref dtzcamerxuonoeujrgsu

# Create new project
npx supabase projects create my-new-project

# List all projects
npx supabase projects list

# Deploy everything (migrations + functions)
npx supabase db push && npx supabase functions deploy
```

---

#### 🔵 6. Database Branching (Preview)

Create database branches for testing:

```bash
# Create branch from main
npx supabase branches create feature-validation

# List branches
npx supabase branches list

# Switch to branch
npx supabase branches switch feature-validation

# Merge branch to main
npx supabase branches merge feature-validation

# Delete branch
npx supabase branches delete feature-validation
```

**⚠️ Requires:** Pro plan or higher

---

#### 🔵 7. Storage Management

Manage buckets and files:

```bash
# List storage buckets
npx supabase storage ls

# Create bucket
npx supabase storage mb workout-videos

# Upload file
npx supabase storage cp local-file.mp4 workout-videos/demo.mp4

# Download file
npx supabase storage cp workout-videos/demo.mp4 ./downloaded.mp4

# Delete file
npx supabase storage rm workout-videos/demo.mp4
```

---

#### 🔵 8. Database Utilities

Additional database operations:

```bash
# Dump entire database
npx supabase db dump -f backup.sql

# Dump specific schema
npx supabase db dump --schema zamm -f zamm_backup.sql

# Dump only data (no schema)
npx supabase db dump --data-only -f data_only.sql

# Dump roles only
npx supabase db dump --role-only -f roles.sql

# Lint database for issues
npx supabase db lint

# Inspect schema differences
npx supabase db diff -f proposed_changes

# Test queries for performance
npx supabase test db
```

---

#### 🔵 9. Authentication & Security

Manage auth and RLS:

```bash
# Test Row Level Security policies
npx supabase test policies

# Generate TypeScript types from database
npx supabase gen types typescript --linked > types/database.ts

# Validate database setup
npx supabase db lint

# Check for common security issues
npx supabase inspect db
```

---

#### 🔵 10. Realtime & Subscriptions

Test Realtime features:

```bash
# Test Realtime subscriptions locally
npx supabase functions serve --with-realtime

# Configure Realtime for tables
# (Done via Dashboard or SQL)
ALTER TABLE zamm.workout_main REPLICA IDENTITY FULL;
```

---

### 📊 Supabase CLI Decision Tree - Complete Reference

**I want to... → Command**

#### 🔐 Authentication & Setup
| Task | Command |
|------|---------|
| **Login to Supabase** | `npx supabase login` |
| **Initialize local project** | `npx supabase init` |
| **Link directory to cloud project** | `npx supabase link --project-ref dtzcamerxuonoeujrgsu` |

#### 🏠 Local Development Environment
| Task | Command |
|------|---------|
| **Start local stack** (DB/Auth/Storage/Realtime) | `npx supabase start` |
| **Stop local stack** | `npx supabase stop` |
| **Restart local stack** | `npx supabase restart` |
| **Check local status** | `npx supabase status` |
| **Reset local DB** (migrations + seed) | `npx supabase db reset` |

#### 📊 Database Migrations
| Task | Command |
|------|---------|
| **Create empty migration** | `npx supabase migration new my_migration` |
| **Generate migration from diff** | `npx supabase db diff -f new_migration` |
| **Run migrations locally** | `npx supabase migration up` |
| **Rollback migrations** | `npx supabase migration down` |
| **List migration status** | `npx supabase migration list` |
| **Push schema to cloud** | `npx supabase db push` |
| **Pull schema from cloud** | `npx supabase db pull` |
| **Check differences** | `npx supabase db diff` |

#### 💾 Database Backup & Export
| Task | Command |
|------|---------|
| **Dump entire database** | `npx supabase db dump -f backup.sql` |
| **Dump specific schema** | `npx supabase db dump --schema zamm -f zamm.sql` |
| **Dump data only** | `npx supabase db dump --data-only -f data.sql` |
| **Dump roles only** | `npx supabase db dump --role-only -f roles.sql` |

#### 🌿 Database Branching (Pro Plan)
| Task | Command |
|------|---------|
| **Create DB branch** | `npx supabase branches create feature-name` |
| **List branches** | `npx supabase branches list` |
| **Switch branch** | `npx supabase branches switch feature-name` |
| **Delete branch** | `npx supabase branches delete feature-name` |

#### ⚡ Edge Functions
| Task | Command |
|------|---------|
| **Create new function** | `npx supabase functions new function-name` |
| **Serve locally** (hot reload) | `npx supabase functions serve function-name` |
| **Deploy to cloud** | `npx supabase functions deploy function-name` |
| **Deploy all functions** | `npx supabase functions deploy` |
| **List functions** | `npx supabase functions list` |
| **Delete function** | `npx supabase functions delete function-name` |

#### 🔐 Secrets Management
| Task | Command |
|------|---------|
| **Set secret** | `npx supabase secrets set KEY=value` |
| **Set multiple secrets** | `npx supabase secrets set KEY1=val1 KEY2=val2` |
| **Load from .env file** | `npx supabase secrets set --env-file .env.production` |
| **List secrets** (values hidden) | `npx supabase secrets list` |
| **Get secret value** | `npx supabase secrets get KEY` |
| **Unset secret** | `npx supabase secrets unset KEY` |

#### 📦 Storage Management
| Task | Command |
|------|---------|
| **List buckets** | `npx supabase storage ls` |
| **Create bucket** | `npx supabase storage create-bucket workout-videos` |
| **Delete bucket** | `npx supabase storage delete-bucket workout-videos` |
| **Empty bucket** | `npx supabase storage empty-bucket workout-videos` |
| **Upload file** | `npx supabase storage cp local.mp4 bucket/remote.mp4` |
| **Download file** | `npx supabase storage cp bucket/remote.mp4 ./local.mp4` |
| **Delete file** | `npx supabase storage rm bucket/file.mp4` |

#### 🔍 Code Generation & Types
| Task | Command |
|------|---------|
| **Generate TypeScript types** | `npx supabase gen types typescript --linked > types/database.ts` |
| **Generate for local DB** | `npx supabase gen types typescript --local` |

#### 📋 Project Management
| Task | Command |
|------|---------|
| **List projects** | `npx supabase projects list` |
| **Create project** | `npx supabase projects create my-project` |

#### 📊 Monitoring & Logs
| Task | Command |
|------|---------|
| **Tail API logs** | `npx supabase logs tail --service api` |
| **Tail DB logs** | `npx supabase logs tail --service db` |
| **Tail Auth logs** | `npx supabase logs tail --service auth` |
| **Tail Storage logs** | `npx supabase logs tail --service storage` |
| **Tail Edge Function logs** | `npx supabase logs tail --service functions` |

#### 🛠️ Database Utilities
| Task | Command |
|------|---------|
| **Lint database** | `npx supabase db lint` |
| **Inspect DB** | `npx supabase inspect db` |
| **Test RLS policies** | `npx supabase test policies` |

#### ❌ NOT Supported
| Task | Why Not | Use Instead |
|------|---------|-------------|
| **Run SQL file** | No `execute` command | psql or Dashboard SQL Editor |
| **Interactive SQL shell** | CLI is for workflow, not queries | `psql` or Dashboard |
| **Ad-hoc SELECT/INSERT** | Not designed for this | Dashboard or psql |

---

## 🎯 Complete Workflow Examples

### Workflow 1: Local Development → Production

**Scenario:** Develop new feature with database changes locally, test, then deploy

```bash
# 1. Start local Supabase stack
npx supabase start

# 2. Create migration for new feature
npx supabase migration new add_workout_tags

# Edit: supabase/migrations/YYYYMMDDHHMMSS_add_workout_tags.sql
# Add your SQL changes...

# 3. Apply migration locally
npx supabase db reset  # Resets and applies all migrations

# 4. Test your changes locally
# → Use local DB URL from `supabase status`

# 5. Generate TypeScript types
npx supabase gen types typescript --local > types/database.ts

# 6. When ready, push to production
npx supabase db push

# 7. Verify on remote
npx supabase db pull  # Should show no changes
```

---

### Workflow 2: Schema Changes from Production

**Scenario:** Someone made changes in production dashboard, sync locally

```bash
# 1. Pull latest schema from production
npx supabase db pull

# This creates a new migration file with the changes

# 2. Review the generated migration
cat supabase/migrations/YYYYMMDDHHMMSS_remote_schema.sql

# 3. Apply to local DB (if running locally)
npx supabase db reset

# 4. Commit the migration to git
git add supabase/migrations/
git commit -m "Sync schema from production"
```

---

### Workflow 3: Edge Function Development

**Scenario:** Create and deploy a workout parser function

```bash
# 1. Create new function
npx supabase functions new parse-workout

# 2. Edit function code
# File: supabase/functions/parse-workout/index.ts
# (Add your Deno/TypeScript code)

# 3. Set secrets for the function
npx supabase secrets set OPENAI_API_KEY=sk-...

# 4. Test locally with hot reload
npx supabase functions serve parse-workout

# → Test at: http://localhost:54321/functions/v1/parse-workout

# 5. Deploy to production
npx supabase functions deploy parse-workout

# 6. Monitor logs
npx supabase logs tail --service functions
```

---

### Workflow 4: Migration Rollback

**Scenario:** A migration caused issues, need to rollback

```bash
# 1. Check migration history
npx supabase migration list

# 2. Rollback last migration (local only)
npx supabase migration down

# 3. Fix the migration file
nano supabase/migrations/YYYYMMDDHHMMSS_problematic.sql

# 4. Re-apply
npx supabase db reset

# 5. For production rollback:
# Create a new "down" migration manually
npx supabase migration new revert_problematic_change

# Add DROP/ALTER statements to undo changes
# Then push:
npx supabase db push
```

---

### Workflow 5: Database Backup & Restore

**Scenario:** Backup production before major changes

```bash
# 1. Backup entire database
npx supabase db dump -f backups/$(date +%Y%m%d)_full_backup.sql

# 2. Backup specific schema only
npx supabase db dump --schema zamm -f backups/zamm_backup.sql

# 3. Backup data only (no schema)
npx supabase db dump --data-only -f backups/data_backup.sql

# 4. To restore (use psql):
psql "postgresql://..." -f backups/backup.sql
```

---

### Workflow 6: TypeScript Types Sync

**Scenario:** Keep TypeScript types in sync with database changes

```bash
# After any schema change, regenerate types:

# For linked remote project
npx supabase gen types typescript --linked > types/database.ts

# Or for local DB
npx supabase gen types typescript --local > types/database.ts

# Use in your code:
# import { Database } from './types/database'
# type Athlete = Database['zamm']['Tables']['lib_athletes']['Row']
```

---

### Workflow 7: Multi-Environment Setup

**Scenario:** Separate staging and production databases

```bash
# 1. Link to staging
npx supabase link --project-ref staging-ref

# 2. Deploy migrations to staging
npx supabase db push

# 3. Test on staging
# ...

# 4. Link to production
npx supabase link --project-ref prod-ref

# 5. Deploy to production
npx supabase db push

# Pro tip: Use different profiles
npx supabase link --project-ref staging-ref --profile staging
npx supabase link --project-ref prod-ref --profile production

# Then deploy with:
npx supabase db push --profile staging
npx supabase db push --profile production
```

---

## ⚠️ Important Limitations

**Supabase CLI does NOT:**
- ❌ Execute arbitrary SQL queries against remote database
- ❌ Provide interactive SQL shell (use psql)
- ❌ Run ad-hoc SELECT/INSERT/UPDATE (use Dashboard or psql)

**Supabase CLI IS for:**
- ✅ Development workflow (migrations, functions)
- ✅ Schema management
- ✅ Local testing environment
- ✅ Deployment automation

**For SQL execution, use Dashboard or psql instead.**

---

### Method 4: REST API (Advanced)

**Best for:** Application integration, RPC calls

#### Using curl
```bash
# Call a stored function
curl -X POST "https://dtzcamerxuonoeujrgsu.supabase.co/rest/v1/rpc/check_athlete_exists" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"p_athlete_name": "John Doe"}'

# Query table directly
curl "https://dtzcamerxuonoeujrgsu.supabase.co/rest/v1/lib_athletes?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

**Pros:**
- ✅ No database client needed
- ✅ Works in CI/CD pipelines
- ✅ Can be used from any language

**Cons:**
- ❌ Limited to RPC functions and table queries
- ❌ Can't run complex SQL directly
- ❌ More complex syntax

---

### Method 5: Python Script (with psycopg2)

**Best for:** Data processing, ETL, automation

```python
import psycopg2
import os

conn = psycopg2.connect(
    host="db.dtzcamerxuonoeujrgsu.supabase.co",
    database="postgres",
    user="postgres",
    password=os.getenv("SUPABASE_DB_PASSWORD"),
    port=5432
)

cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM zamm.lib_athletes;")
result = cur.fetchone()
print(f"Athletes: {result[0]}")

cur.close()
conn.close()
```

---

## 🎯 Common Operations

### Check Connection
```sql
SELECT 
    current_database() as database,
    current_schema() as schema,
    version() as postgres_version;
```

### List All Tables
```sql
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'zamm'
ORDER BY table_name;
```

### Count Rows in All Tables
```sql
-- Use the provided script:
-- scripts/check_all_tables.sql
```

### Check Active Connections
```sql
SELECT 
    datname as database,
    usename as user,
    application_name,
    client_addr,
    state,
    query_start
FROM pg_stat_activity
WHERE datname = 'postgres';
```

### Test AI Tools
```sql
-- Check if athlete exists
SELECT * FROM zamm.check_athlete_exists('John Doe');

-- Normalize exercise name
SELECT * FROM zamm.check_exercise_exists('bench press');

-- Get active ruleset
SELECT * FROM zamm.get_active_ruleset();
```

---

## 🔐 Security Best Practices

### 1. Never Commit Passwords
- ✅ Use `.env.local` (already in `.gitignore`)
- ✅ Use environment variables
- ❌ Never hardcode in scripts

### 2. Use Service Role Key Carefully
```bash
# Anon key: Limited permissions (safe for client)
SUPABASE_ANON_KEY

# Service role: Full access (use server-side only!)
SUPABASE_SERVICE_ROLE_KEY
```

### 3. Connection Pooling
For high-volume operations, use connection pooling:
```
postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

---

## 📝 Quick Reference: SQL File Execution

### Scenario 1: I have a SQL file and want results
```bash
# Option A: Dashboard (easiest)
npx supabase dashboard
# → SQL Editor → Paste → Run

# Option B: psql (if installed)
psql "postgresql://postgres:[password]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" \
  -f your_file.sql
```

### Scenario 2: I want to run a query programmatically
```bash
# Option A: psql with pipe
echo "SELECT COUNT(*) FROM zamm.lib_athletes;" | psql "postgresql://..."

# Option B: REST API for RPC
curl -X POST "https://dtzcamerxuonoeujrgsu.supabase.co/rest/v1/rpc/your_function" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"param": "value"}'
```

### Scenario 3: I want to migrate schema
```bash
# Create migration
npx supabase migration new your_migration_name

# Edit: supabase/migrations/YYYYMMDDHHMMSS_your_migration_name.sql

# Push to remote
npx supabase db push
```

---

## 🐛 Troubleshooting

### "Connection refused"
- ✅ Check project is not paused (free tier sleeps after inactivity)
- ✅ Verify connection string is correct
- ✅ Check firewall/network settings

### "Password authentication failed"
- ✅ Get password from: Dashboard → Settings → Database → Reset password
- ✅ Update `.env.local` with new password
- ✅ Escape special characters in connection string (URL encoding)

### "Relation does not exist"
- ✅ Check schema name: Use `zamm.table_name` not just `table_name`
- ✅ Verify table exists: `\dt zamm.*` in psql
- ✅ Check if migrations deployed: `npx supabase db pull`

### "Too many connections"
- ✅ Use connection pooler (port 6543 instead of 5432)
- ✅ Close connections properly in scripts
- ✅ Upgrade plan if needed (free tier: 60 connections)

---

## 📚 Related Documentation

- [Supabase Database Docs](https://supabase.com/docs/guides/database)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [agents.md](./agents.md) - AI agent guidelines
- [CLAUDE.md](./CLAUDE.md) - Claude CLI quick reference

---

## 🚀 Quick Start Workflow

**For first-time setup:**

1. **Install psql** (optional but recommended)
   ```bash
   sudo apt-get update && sudo apt-get install -y postgresql-client
   ```

2. **Get database password**
   ```bash
   npx supabase dashboard
   # → Settings → Database → Copy password
   ```

3. **Add to .env.local**
   ```bash
   echo 'SUPABASE_DB_PASSWORD="your-password-here"' >> .env.local
   ```

4. **Test connection**
   ```bash
   psql "postgresql://postgres:$(grep SUPABASE_DB_PASSWORD .env.local | cut -d'=' -f2 | tr -d '"')@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" -c "SELECT current_database();"
   ```

5. **Run your first query**
   ```bash
   psql "postgresql://postgres:your-password@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" \
     -f scripts/check_all_tables.sql
   ```

---

## 💡 Pro Tips

1. **Save connection string as alias**
   ```bash
   echo 'alias supapsql="psql postgresql://postgres:[password]@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres"' >> ~/.bashrc
   source ~/.bashrc
   
   # Now just use:
   supapsql -f scripts/your_script.sql
   ```

2. **Use `.pgpass` for passwordless access**
   ```bash
   echo "db.dtzcamerxuonoeujrgsu.supabase.co:5432:postgres:postgres:your-password" >> ~/.pgpass
   chmod 600 ~/.pgpass
   ```

3. **Create helper scripts**
   ```bash
   # Example: scripts/run_sql.sh
   #!/bin/bash
   source .env.local
   psql "postgresql://postgres:$SUPABASE_DB_PASSWORD@db.dtzcamerxuonoeujrgsu.supabase.co:5432/postgres" "$@"
   ```

---

**Last Updated:** January 9, 2026  
**Maintained By:** AI Development Team
