
---
name: release
description: Prepares a new version release (bumps version, updates changelog, tags git)
---

# Release Skill

## Purpose
Automate version release workflow by:
- Bumping version number in package.json
- Updating CHANGELOG.md with release notes
- Running full test suite for quality gate
- Creating git tag for the release
- Pushing tag to remote repository

## Usage
```
/release <version> "<summary>"
```

**Arguments:**
- `version`: Semantic version (e.g., "1.3.0", "2.0.0", "1.2.1")
- `summary`: Brief description of changes (in quotes)

**Examples:**
```
/release 1.3.0 "Add quality gates and V4 commit function"
/release 2.0.0 "Major schema refactor with breaking changes"
/release 1.2.1 "Fix parser bug with RPE extraction"
```

## Semantic Versioning (Semver)

**Format:** `MAJOR.MINOR.PATCH`

- **MAJOR (X.0.0):** Breaking changes (incompatible API changes)
  - Example: Schema restructure, removed fields, changed function signatures

- **MINOR (0.X.0):** New features (backwards-compatible)
  - Example: New parser patterns, additional database fields, new catalog entries

- **PATCH (0.0.X):** Bug fixes (backwards-compatible)
  - Example: Fixed regex, corrected constraint, performance improvement

---

## Instructions for Claude

### Step 1: Validate Version Format

```javascript
const versionRegex = /^(\d+)\.(\d+)\.(\d+)$/;
if (!versionRegex.test(version)) {
    throw new Error('Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 1.3.0)');
}
```

### Step 2: Check Current Version

```bash
# Read current version from package.json
cat package.json | grep '"version"'
```

**Example output:**
```
Current version: 1.2.0
Requested version: 1.3.0
```

**Validate:**
- New version must be > current version
- Major/minor/patch increment makes sense

```
✅ Valid: 1.2.0 → 1.3.0 (minor bump)
✅ Valid: 1.2.0 → 2.0.0 (major bump)
✅ Valid: 1.2.0 → 1.2.1 (patch)
❌ Invalid: 1.2.0 → 1.1.0 (downgrade)
❌ Invalid: 1.2.0 → 1.4.0 (skipped minor version)
```

### Step 3: Ask for Changelog Details

Use `AskUserQuestion` to gather release notes:

```
Preparing release v1.3.0

Summary: "Add quality gates and V4 commit function"

Please provide additional changelog details:

What changed?
- [ ] New features
- [ ] Bug fixes
- [ ] Breaking changes
- [ ] Documentation updates
- [ ] Performance improvements

Provide bulleted list of changes:
```

**Example user response:**
```
### Added
- Quality gate validation for parsed workouts
- commit_full_workout_v4 with quality scoring
- Automatic schema documentation sync

### Fixed
- Parser bug with percentage-based loads
- Constraint violation in stg_imports checksum

### Changed
- Migration protocol to prevent function signature conflicts
```

### Step 4: Run Full Test Suite

**Before releasing, ensure quality:**

```bash
# Run verification suite
npm run verify

# Or manually:
./scripts/verify_schema.sh
./scripts/validate_golden_set.sh
./scripts/test_parser_accuracy.sh
```

**If ANY test fails:**
```
❌ Release blocked - tests failed!

Failures:
- Parser accuracy: 2/10 tests failed
- Schema verification: workout_main missing column

Action: Fix issues before releasing.
Run /verify to see full details.
```

**Do NOT proceed with release if tests fail!**

### Step 5: Update package.json

```bash
# Use npm version command (handles package.json + git tag)
npm version $NEW_VERSION --no-git-tag-version
```

**This updates:**
```json
{
  "version": "1.3.0"
}
```

### Step 6: Update CHANGELOG.md

**Format:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-01-11

### Added
- Quality gate validation for parsed workouts
- `commit_full_workout_v4` stored procedure with quality scoring
- Automatic schema documentation sync via `npm run update-docs`
- `/inspect-table` skill for viewing database constraints

### Fixed
- Parser bug where percentage loads were treated as kg/lb units
- Constraint violation in `stg_imports` when checksum format invalid
- Migration protocol to prevent function signature conflicts

### Changed
- Moved to atomic task breakdown strategy (60-80% debugging reduction)
- Enhanced CLAUDE.md with migration and constraint inspection protocols

## [1.2.0] - 2026-01-10
...
```

**Implementation:**
```bash
# Read CHANGELOG.md
# Insert new section after "# Changelog" header
# Use provided summary and changelog details
# Add today's date

# Edit the file
node -e "
const fs = require('fs');
const changelog = fs.readFileSync('CHANGELOG.md', 'utf8');
const newEntry = \`
## [${version}] - ${new Date().toISOString().split('T')[0]}

${changelogContent}
\`;

const updated = changelog.replace(
    /^(# Changelog.*?\\n\\n)/m,
    \`\$1\${newEntry}\\n\`
);

fs.writeFileSync('CHANGELOG.md', updated);
"
```

### Step 7: Commit Changes

```bash
# Stage version bump and changelog
git add package.json CHANGELOG.md

# Commit with conventional commit format
git commit -m "chore(release): bump version to ${version}

${summary}

See CHANGELOG.md for full details."
```

### Step 8: Create Git Tag

```bash
# Create annotated tag
git tag -a "v${version}" -m "Release v${version}: ${summary}"

# Verify tag created
git tag -l "v${version}"
```

### Step 9: Push to Remote

```bash
# Push commits
git push origin main

# Push tag
git push origin "v${version}"
```

**Output:**
```
✅ Release v1.3.0 complete!

Changes:
- Version bumped: 1.2.0 → 1.3.0
- CHANGELOG.md updated
- Git commit created
- Tag created: v1.3.0
- Pushed to remote: origin/main

View release:
git log -1
git show v1.3.0
```

---

## Safety Checks

### Pre-Release Checklist

Before running `/release`, ensure:

1. ✅ All changes committed (clean working directory)
2. ✅ Tests passing (`/verify` shows all green)
3. ✅ Documentation up-to-date (`/sync-docs` run)
4. ✅ No pending migrations (all applied)
5. ✅ On main branch (not feature branch)

**Check working directory:**
```bash
git status
```

**Expected:**
```
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**If not clean:**
```
⚠️ Warning: You have uncommitted changes!

Modified files:
  scripts/parse_workout.js
  docs/reference/SCHEMA_REFERENCE.md

Action: Commit or stash these changes before releasing.
```

### Post-Release Verification

After release, verify:

```bash
# Check tag exists
git tag -l

# Check remote has tag
git ls-remote --tags origin

# Check package.json matches tag
cat package.json | grep version
```

**Expected:**
```
Tags:
v1.0.0
v1.1.0
v1.2.0
v1.3.0  ← New tag appears

Remote tags:
v1.3.0  refs/tags/v1.3.0  ← Pushed to remote

package.json:
"version": "1.3.0"  ← Matches tag
```

---

## Rollback Procedure

If release was created incorrectly:

### Rollback Step 1: Delete Local Tag
```bash
git tag -d v1.3.0
```

### Rollback Step 2: Delete Remote Tag
```bash
git push origin --delete v1.3.0
```

### Rollback Step 3: Revert Commits
```bash
# Soft reset (keeps changes)
git reset --soft HEAD~1

# Or hard reset (discards changes)
git reset --hard HEAD~1
```

### Rollback Step 4: Restore Files
```bash
# Revert package.json and CHANGELOG.md
git checkout HEAD~1 -- package.json CHANGELOG.md
```

**Then:**
- Fix the issue
- Re-run `/release` with correct information

---

## Integration with CI/CD

**GitHub Actions (if configured):**

When tag is pushed, trigger:
1. Build verification
2. Test suite
3. Deploy to staging
4. Create GitHub Release with CHANGELOG notes

**Example workflow (not created by this skill):**
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: npm ci
      - run: npm run verify
      - uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body_path: CHANGELOG.md
```

---

## Version History Best Practices

### Keep Changelog Format

**DO:**
- ✅ Use "Added", "Changed", "Deprecated", "Removed", "Fixed", "Security" sections
- ✅ Include date in ISO format (YYYY-MM-DD)
- ✅ Link to issues/PRs when relevant
- ✅ Be specific (not vague)

**Example GOOD entry:**
```markdown
## [1.3.0] - 2026-01-11

### Added
- Quality gate validation rejects workouts with <70% confidence (#123)
- `commit_full_workout_v4` with automatic quality scoring
```

**Example BAD entry:**
```markdown
## [1.3.0]

### Updates
- Various improvements
- Bug fixes
```

### Commit Message Format

**Use Conventional Commits:**

```
chore(release): bump version to 1.3.0

Add quality gates and V4 commit function

See CHANGELOG.md for full details.
```

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance (releases, deps)
- `refactor`: Code restructure
- `test`: Test changes
- `perf`: Performance improvement

---

## Example Session

```
User: /release 1.3.0 "Add quality gates and V4 commit function"

Claude: 📦 Preparing release v1.3.0

Current version: 1.2.0
Requested version: 1.3.0
✅ Valid minor version bump

Running pre-release checks...

✅ Working directory clean
✅ On main branch
✅ No pending migrations

Running test suite...
$ npm run verify

✅ Schema verification: PASS
✅ Parser golden set: PASS (10/10)
✅ Parser accuracy: PASS (95% confidence)

All tests passed! Proceeding with release...

Updating package.json...
✅ Version bumped: 1.2.0 → 1.3.0

Updating CHANGELOG.md...

Please provide changelog details (what changed in this release):

User:
### Added
- Quality gate validation
- commit_full_workout_v4
- Automatic docs sync

### Fixed
- Parser percentage bug
- Checksum constraint violation

Claude:
✅ CHANGELOG.md updated

Creating git commit...
✅ Commit created: "chore(release): bump version to 1.3.0"

Creating git tag...
✅ Tag created: v1.3.0

Pushing to remote...
✅ Pushed commits to origin/main
✅ Pushed tag v1.3.0 to origin

🎉 Release v1.3.0 complete!

View release:
$ git log -1
$ git show v1.3.0

Or view on GitHub (if connected):
https://github.com/your-org/ParserZamaActive/releases/tag/v1.3.0
```

---

## Files Modified

- `package.json` - Version number updated
- `CHANGELOG.md` - New release section added
- Git tags - New annotated tag created

## Files NOT Modified

- Source code (no automatic code changes)
- Migrations (releases don't create migrations)
- Documentation (update separately with `/sync-docs`)

---

## Notes

- This skill follows **Semantic Versioning 2.0.0** specification
- Uses **Keep a Changelog** format for CHANGELOG.md
- Requires **clean working directory** (no uncommitted changes)
- Requires **all tests passing** before release
- Creates **annotated git tags** (not lightweight tags)
- Does NOT automatically create GitHub Releases (manual or CI/CD)
