# 🚀 Supabase CLI Cheatsheet

> **Quick Reference Card** - Print & Keep Handy!  
> ParserZamaActive Project | January 9, 2026

---

## 🔐 SETUP (One-time)

```bash
npx supabase login                          # Login to Supabase
npx supabase init                           # Initialize project
npx supabase link --project-ref PROJECT_ID  # Link to cloud
```

---

## 🏠 LOCAL DEVELOPMENT

```bash
npx supabase start        # Start local stack (Docker)
npx supabase status       # Check what's running
npx supabase stop         # Stop local stack
npx supabase db reset     # Reset DB to migrations
```

**After `start`, get URLs:**
- API: http://localhost:54321
- DB: postgresql://postgres:postgres@localhost:54322/postgres
- Studio: http://localhost:54323

---

## 📊 MIGRATIONS (Schema Changes)

### Create & Apply
```bash
npx supabase migration new my_change     # Create empty migration
npx supabase db diff -f my_change        # Generate from diff
npx supabase db reset                    # Apply locally
```

### Deploy & Sync
```bash
npx supabase db push                     # Deploy to cloud
npx supabase db pull                     # Sync from cloud
npx supabase db diff                     # Check differences
npx supabase migration list              # Show status
```

### Rollback (Local Only)
```bash
npx supabase migration down              # Undo last migration
```

---

## ⚡ EDGE FUNCTIONS

```bash
npx supabase functions new NAME          # Create function
npx supabase functions serve NAME        # Test locally (hot reload)
npx supabase functions deploy NAME       # Deploy to cloud
npx supabase functions deploy            # Deploy all
npx supabase functions list              # Show all functions
```

**Local test URL:**
http://localhost:54321/functions/v1/FUNCTION_NAME

---

## 🔐 SECRETS

```bash
npx supabase secrets set KEY=value       # Set single secret
npx supabase secrets set K1=v1 K2=v2     # Set multiple
npx supabase secrets set --env-file .env # Load from file
npx supabase secrets list                # List (values hidden)
npx supabase secrets unset KEY           # Delete secret
```

---

## 💾 BACKUP & RESTORE

```bash
# Backup
npx supabase db dump -f backup.sql       # Full backup
npx supabase db dump --schema zamm -f z.sql  # Schema only
npx supabase db dump --data-only -f d.sql    # Data only

# Restore (use psql)
psql "postgresql://..." -f backup.sql
```

---

## 📦 STORAGE

```bash
npx supabase storage ls                  # List buckets
npx supabase storage create-bucket NAME  # Create bucket
npx supabase storage cp local.txt bucket/remote.txt  # Upload
npx supabase storage cp bucket/file.txt ./local.txt  # Download
npx supabase storage rm bucket/file.txt  # Delete file
```

---

## 🔍 CODE GENERATION

```bash
# TypeScript types from database
npx supabase gen types typescript --linked > types/db.ts
npx supabase gen types typescript --local > types/db.ts
```

---

## 📊 MONITORING

```bash
npx supabase logs tail --service api       # API logs
npx supabase logs tail --service db        # Database logs
npx supabase logs tail --service auth      # Auth logs
npx supabase logs tail --service functions # Function logs
```

---

## 🌿 DATABASE BRANCHING (Pro Plan)

```bash
npx supabase branches create BRANCH_NAME   # Create branch
npx supabase branches list                 # List branches
npx supabase branches switch BRANCH_NAME   # Switch to branch
npx supabase branches delete BRANCH_NAME   # Delete branch
```

---

## 🛠️ UTILITIES

```bash
npx supabase db lint                     # Check DB issues
npx supabase inspect db                  # Security check
npx supabase test policies               # Test RLS policies
npx supabase projects list               # List projects
```

---

## ❌ NOT SUPPORTED

**Supabase CLI cannot:**
- ❌ Execute SQL files (`execute` command doesn't exist)
- ❌ Run SELECT/INSERT/UPDATE queries directly
- ❌ Provide interactive SQL shell

**For SQL execution, use:**
- ✅ `psql` command-line tool
- ✅ Supabase Dashboard (SQL Editor)

---

## 🎯 COMMON WORKFLOWS

### 1. New Feature with DB Changes
```bash
npx supabase migration new add_feature
# Edit migration file
npx supabase db reset              # Test locally
npx supabase db push               # Deploy
```

### 2. Sync from Production
```bash
npx supabase db pull               # Pull changes
git add supabase/migrations/
git commit -m "Sync schema"
```

### 3. Deploy Edge Function
```bash
npx supabase functions new parser
# Edit function code
npx supabase secrets set API_KEY=...
npx supabase functions serve parser  # Test
npx supabase functions deploy parser # Deploy
```

### 4. Backup Before Changes
```bash
npx supabase db dump -f backup_$(date +%Y%m%d).sql
# Make changes...
# Restore if needed: psql ... -f backup.sql
```

---

## 🔑 PROJECT SPECIFIC

**ParserZamaActive:**
- Project ID: `dtzcamerxuonoeujrgsu`
- Schema: `zamm` (32 tables)
- Linked: Yes (no local stack)

**Link command used:**
```bash
npx supabase link --project-ref dtzcamerxuonoeujrgsu
```

---

## 💡 PRO TIPS

1. **Always test migrations locally first**
   ```bash
   npx supabase db reset  # Before push
   ```

2. **Use profiles for multiple environments**
   ```bash
   npx supabase link --profile staging
   npx supabase link --profile production
   npx supabase db push --profile production
   ```

3. **Auto-generate types after schema changes**
   ```bash
   npx supabase gen types typescript --linked > types/database.ts
   ```

4. **Monitor logs after deployment**
   ```bash
   npx supabase logs tail --service functions
   ```

5. **Create migration from Dashboard changes**
   ```bash
   npx supabase db pull  # Auto-generates migration
   ```

---

## 📚 MORE INFO

- Full Guide: `supabase.md`
- Project Docs: `ARCHITECTURE.md`
- AI Agents: `agents.md`, `CLAUDE.md`
- Online Docs: https://supabase.com/docs/cli

---

**Print this page and keep it visible while coding!** 🖨️

---

*Last Updated: January 9, 2026*
