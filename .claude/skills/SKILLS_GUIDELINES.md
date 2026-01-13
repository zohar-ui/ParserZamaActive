# Skills Guidelines

**Purpose:** Maintain high standards for all Claude Code skills in ParserZamaActive
**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Reference:** [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)

---

## Quick Reference

**Before creating a new skill:**
1. Review [SKILL_TEMPLATE.md](SKILL_TEMPLATE.md)
2. Follow the checklist below
3. Use existing skills as examples
4. Test with Claude Code before committing

---

## Mandatory Standards

### 1. YAML Frontmatter

```yaml
---
name: skill-name
description: [COMPREHENSIVE DESCRIPTION]
---
```

**Requirements:**
- ✅ `name` matches directory name
- ✅ `description` is 2-4 sentences (150-300 characters)
- ✅ Description includes **when to use** (numbered list)
- ✅ Description includes triggering keywords
- ✅ NO extra YAML fields beyond name/description

### 2. Description Quality

**Formula:**
```
[WHAT] + [WHEN/CRITICAL] + Use when: (1) ... (2) ... (3) ... (4) ... (5) ...
```

**Example:**
```yaml
description: Shows COMPLETE table structure including columns, types, nullability, defaults, and ALL constraints (CHECK, FK, UNIQUE, ENUM values). CRITICAL - Use this skill BEFORE writing ANY SQL INSERT/UPDATE statements or creating database functions. Use when you need to: (1) Verify actual table/column names because documentation may be outdated, (2) Check valid enum/constraint values to prevent constraint violations, (3) See foreign key requirements to prevent FK errors, (4) Identify NOT NULL columns to prevent null violations, or (5) Understand complete table schema before any database operation
```

### 3. Body Length

- ✅ **Under 500 lines total**
- ✅ Use progressive disclosure for longer content
- ✅ Move details to `references/` directory
- ✅ Link to references in body

### 4. Writing Style

- ✅ Use imperative form ("Run", "Check", "Verify")
- ✅ Be concise - assume Claude is smart
- ✅ Provide exact commands and examples
- ✅ Link to references for deep dives

### 5. Progressive Disclosure

**When body exceeds 300 lines:**

```
.claude/skills/skill-name/
├── SKILL.md (< 500 lines)
├── references/
│   ├── DETAILED_STEPS.md
│   ├── EXAMPLES.md
│   └── ERROR_HANDLING.md
└── scripts/ (optional)
```

---

## New Skill Checklist

Use this before committing any new skill:

### Frontmatter ✅
- [ ] Has `name` field (matches directory)
- [ ] Has comprehensive `description` (150-300 chars)
- [ ] Description lists 5+ specific use cases
- [ ] Description includes triggering keywords
- [ ] Description states **when** to use (not just what)
- [ ] NO extra YAML fields

### Description Quality ✅
- [ ] Starts with what the skill does
- [ ] Includes "CRITICAL" or "Use BEFORE" if applicable
- [ ] Lists explicit numbered use cases: (1)... (2)... (3)...
- [ ] Contains keywords users would search for
- [ ] Clear about problem it solves

### Body Structure ✅
- [ ] Under 500 lines total
- [ ] Uses imperative form consistently
- [ ] Has "Core Workflow" section
- [ ] Links to references for details
- [ ] Includes "Success Criteria" section
- [ ] Lists "Related Skills"

### Progressive Disclosure ✅
- [ ] Long content moved to `references/`
- [ ] Executable code in `scripts/` if needed
- [ ] Examples in `EXAMPLES.md` (if >50 lines)
- [ ] Error handling in `ERROR_HANDLING.md` (if >100 lines)
- [ ] Links properly reference external files

### Documentation ✅
- [ ] Has version number at bottom
- [ ] Has "Last Updated" date
- [ ] Links to related skills
- [ ] Includes practical examples in body or references

### Testing ✅
- [ ] Skill loads in Claude Code
- [ ] Triggers on expected keywords in description
- [ ] Instructions are clear and actionable
- [ ] References load when mentioned
- [ ] No broken links

---

## Common Patterns by Skill Type

### Database Skills

```yaml
description: [What it does] database operation. CRITICAL - Use BEFORE [when]. Use when you need to: (1) Verify database [aspect], (2) Check [constraint type], (3) Validate [data aspect], (4) Prevent [error type], or (5) Ensure [correctness aspect]
```

**Examples:**
- `inspect-table` - Schema inspection
- `verify-sql` - SQL validation
- `db-status` - Connection health

### Parser Skills

```yaml
description: [What it does] parser functionality to [purpose]. Use when you need to: (1) Debug [parser issue], (2) Test [pattern type], (3) Validate [output aspect], (4) Understand [parsing behavior], or (5) Fix [common error]
```

**Examples:**
- `debug-parse` - Pattern testing
- `fix-parser` - Auto-repair

### Validation Skills

```yaml
description: [What it does] validation checks to [ensure what]. Use BEFORE [critical action], or when you need to: (1) Verify [aspect 1], (2) Check [aspect 2], (3) Ensure [requirement], (4) Prevent [error], or (5) Validate [correctness]
```

**Examples:**
- `verify` - Full test suite
- `verify-sql` - SQL validation

### Workflow Skills

```yaml
description: [What it does] end-to-end workflow for [purpose] through [stages]. Use when: (1) [Primary use case with full workflow], (2) [Testing specific stage], (3) [Automating process], (4) [Validating before commit], or (5) [Processing multiple items]
```

**Examples:**
- `process-workout` - Full pipeline orchestration

---

## Anti-Patterns to Avoid

### ❌ Don't: Vague Descriptions

```yaml
# BAD
description: Helpful tool for database work

# GOOD
description: Shows COMPLETE table structure... Use BEFORE writing ANY SQL... Use when you need to: (1)...
```

### ❌ Don't: "When to Use" in Body

```markdown
# BAD - This belongs in description!
## When to Use This Skill

- Use when debugging parser
- Use when testing patterns
```

### ❌ Don't: Inline Everything

```markdown
# BAD - SKILL.md is 1200 lines

# GOOD - SKILL.md is 250 lines + references/
```

### ❌ Don't: Assume Context

```yaml
# BAD
description: Use this when needed

# GOOD
description: ... Use when you need to: (1) Verify actual table names...
```

---

## Version Control

### Skill Versioning

```markdown
---
**Version:** 1.2.0
**Last Updated:** 2026-01-13
```

**Increment:**
- **MAJOR (1.x.x):** Breaking changes to skill interface
- **MINOR (x.1.x):** New features, backward compatible
- **PATCH (x.x.1):** Bug fixes, clarifications

### Update Checklist

When updating an existing skill:
- [ ] Increment version number
- [ ] Update "Last Updated" date
- [ ] Add changelog entry (if major/minor)
- [ ] Test with Claude Code
- [ ] Commit with descriptive message

---

## Current Skills Inventory

### Production Skills (11 total)

**Database Operations:**
1. `inspect-table` - Table structure inspection
2. `verify-sql` - SQL validation before execution
3. `db-status` - Quick database health check
4. `sync-docs` - Schema documentation sync
5. `add-entity` - Exercise/equipment catalog management

**Parser Operations:**
6. `debug-parse` - Parser pattern testing
7. `fix-parser` - Auto-repair common errors

**Validation:**
8. `verify` - Full validation suite

**Workflow:**
9. `process-workout` - End-to-end pipeline orchestration

**Utility:**
10. `release` - (Review status and document purpose)

All skills follow the standards defined in this document.

---

## Maintenance

### Regular Reviews

**Monthly:**
- Check all skills still follow standards
- Update descriptions if new use cases discovered
- Verify links in references still work

**After Major Changes:**
- Update skill if database schema changes
- Add new use cases to description
- Update version number

**When Issues Reported:**
- Fix and increment patch version
- Add clarifications
- Update examples if confusing

---

## Getting Help

**Resources:**
- **Template:** [SKILL_TEMPLATE.md](SKILL_TEMPLATE.md)
- **Official Docs:** https://code.claude.com/docs/en/skills
- **GitHub Examples:** https://github.com/anthropics/skills
- **Best Practices:** https://mikhail.io/2025/10/claude-code-skills/

**Team Standards:**
- All skills must pass the checklist above
- When in doubt, follow existing skill patterns
- Progressive disclosure > inline everything
- Description quality is critical for triggering

---

**Maintained By:** ParserZamaActive Team
**Review Cycle:** Monthly
**Next Review:** 2026-02-13
