# Git Hooks

This directory contains git hooks that are committed to the repository.

## 📋 Available Hooks

### `pre-commit`

**Purpose:** Verify schema version compatibility before every commit

**What it checks:**
1. ✅ Schema document version matches database version
2. ✅ CANONICAL_JSON_SCHEMA.md has YAML frontmatter if modified
3. ✅ Reminds to update CHANGELOG.md on version changes
4. ✅ Reminds to apply migrations if detected in commit

**Behavior:**
- ✅ **Pass** → Commit proceeds
- ❌ **Fail** → Commit blocked with fix instructions
- ⚠️ **DB Offline** → Commit allowed with warning

### `post-merge`

**Purpose:** Automatically update schema documentation after pulling migrations

**What it does:**
1. 🔍 Detects if migration files changed in the merge
2. 📝 Runs `npm run update-docs` to refresh VERIFIED_TABLE_NAMES.md
3. 📊 Reports any schema changes detected
4. 💡 Suggests committing the updated documentation

**Behavior:**
- ✅ **Migrations detected** → Updates docs automatically
- ℹ️ **No migrations** → Skips update
- ⚠️ **DB Offline** → Skips with warning

---

## 🚀 Installation

### Automatic (Recommended)
```bash
npm install
```

The `postinstall` script automatically installs hooks.

### Manual
```bash
npm run install:hooks
# OR
./scripts/install_hooks.sh
```

This copies hooks from `.git-hooks/` to `.git/hooks/` and makes them executable.

---

## 🧪 Testing

### Test hook directly:
```bash
.git/hooks/pre-commit
```

### Test with actual commit:
```bash
git add .
git commit -m "test commit"
```

---

## 🔧 Hook Files

### Source (committed to repo)
- `.git-hooks/pre-commit` - Pre-commit hook source
- `.git-hooks/post-merge` - Post-merge hook source
- `.git-hooks/README.md` - This file

### Active (not committed)
- `.git/hooks/pre-commit` - Copied from source by install script
- `.git/hooks/post-merge` - Copied from source by install script
- `.git/hooks/` - Git's hooks directory (in .gitignore)

---

## 🛑 Bypassing Hooks (Emergency Only)

```bash
# Skip all hooks (NOT RECOMMENDED)
git commit --no-verify -m "emergency fix"

# Better: Fix the issue first
npm run verify:schema
git commit -m "fix"
```

**⚠️ Warning:** Bypassing hooks can cause documentation drift!

---

## 🗑️ Uninstalling

```bash
# Remove specific hook
rm .git/hooks/pre-commit

# Remove all hooks
rm -rf .git/hooks/*
```

---

## 📝 Adding New Hooks

1. Create hook file in `.git-hooks/`:
   ```bash
   touch .git-hooks/post-commit
   chmod +x .git-hooks/post-commit
   ```

2. Update `scripts/install_hooks.sh` to copy new hook:
   ```bash
   if [ -f ".git-hooks/post-commit" ]; then
       cp .git-hooks/post-commit .git/hooks/post-commit
       chmod +x .git/hooks/post-commit
       echo "✓ Installed: post-commit hook"
   fi
   ```

3. Commit both files:
   ```bash
   git add .git-hooks/post-commit scripts/install_hooks.sh
   git commit -m "Add post-commit hook"
   ```

4. Team members get hook on next `npm install`

---

## 📚 Related Documentation

- [VERSIONING_STRATEGY.md](../docs/guides/VERSIONING_STRATEGY.md) - Full versioning documentation
- [verify_schema_version.sh](../scripts/verify_schema_version.sh) - Version checker script
- [install_hooks.sh](../scripts/install_hooks.sh) - Hook installer

---

## 🤝 For Contributors

**Important:** After cloning or pulling, run:
```bash
npm install
```

This ensures you have the latest hooks installed.

**Why this matters:**
- Prevents committing with schema version mismatches
- Catches common mistakes early
- Maintains consistency across team

---

**Last Updated:** 2026-01-11
