# SKILL_TEMPLATE.md

**Purpose:** Template for creating high-standard Claude Code skills
**Version:** 1.0.0
**Last Updated:** 2026-01-13
**Reference:** [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)

---

## File Structure

Every skill consists of:

```
.claude/skills/skill-name/
├── SKILL.md (required) - Core skill definition
├── references/ (optional) - Detailed documentation for progressive loading
│   ├── REFERENCE.md - Complete API/method documentation
│   ├── EXAMPLES.md - Usage examples and patterns
│   └── ERROR_HANDLING.md - Error categories and fixes
├── scripts/ (optional) - Reusable executable code
│   └── skill_helper.sh
└── assets/ (optional) - Templates and files for output
    └── template.json
```

---

## SKILL.md Template

```markdown
---
name: skill-name
description: [COMPREHENSIVE DESCRIPTION - See guidelines below]
---

# Skill Name

[1-2 sentence introduction - what this skill does]

## Core Workflow

[Step-by-step procedural instructions using imperative form]

1. First step - what to do
2. Second step - how to proceed
3. Third step - completion

## Key Concepts

[Essential domain knowledge and terminology - keep brief]

## Advanced Features

[For complex topics, reference separate files]

- **Topic 1**: See [REFERENCE.md](references/REFERENCE.md) for detailed documentation
- **Topic 2**: See [EXAMPLES.md](references/EXAMPLES.md) for use cases
- **Error Handling**: See [ERROR_HANDLING.md](references/ERROR_HANDLING.md)

## Success Criteria

[What defines successful execution]

- ✅ Criterion 1
- ✅ Criterion 2
- ✅ Criterion 3

## Related Skills

- `/skill-name` - Related functionality
- `/other-skill` - Complementary feature
```

---

## Description Field Guidelines

### ⚠️ CRITICAL: Description is for Discovery

The `description` field determines when Claude uses the skill. It must be comprehensive because the body only loads **after** triggering.

### Required Elements

Every description must include:

1. **What it does** (1 sentence summary)
2. **When to use it** (explicit triggering contexts)
3. **Specific use cases** (numbered list of scenarios)
4. **Key capabilities** (what problems it solves)

### Template Format

```yaml
description: [WHAT] Brief summary of what the skill does and its primary purpose. [WHEN] Use this skill when [triggering condition], or when you need to: (1) [Use case 1], (2) [Use case 2], (3) [Use case 3], (4) [Use case 4], or (5) [Use case 5]
```

### Example - Good Description

```yaml
---
name: inspect-table
description: Shows COMPLETE table structure including columns, types, nullability, defaults, and ALL constraints (CHECK, FK, UNIQUE, ENUM values). CRITICAL - Use this skill BEFORE writing ANY SQL INSERT/UPDATE statements or creating database functions. Use when you need to: (1) Verify actual table/column names (documentation may be outdated), (2) Check valid enum/constraint values to prevent constraint violations, (3) See foreign key requirements to prevent FK errors, (4) Identify NOT NULL columns to prevent null violations, or (5) Understand complete table schema for any database operation
---
```

---

## Checklist for New Skills

Before committing a new skill, verify:

### YAML Frontmatter
- [ ] Has `name` field (matches directory name)
- [ ] Has comprehensive `description` field (includes when to use)
- [ ] No extra YAML fields beyond name/description

### Description Quality
- [ ] Includes what the skill does (1 sentence)
- [ ] Lists explicit triggering contexts
- [ ] Provides 5+ specific use cases
- [ ] Uses keywords that match common queries
- [ ] Includes critical warnings if applicable (e.g., "BEFORE INSERT")

### Body Structure
- [ ] Under 500 lines total
- [ ] Uses imperative form ("Run", "Check", "Verify")
- [ ] Has clear procedural steps
- [ ] Links to references for details
- [ ] Includes success criteria

### Progressive Disclosure
- [ ] Long content moved to `references/`
- [ ] Executable code in `scripts/`
- [ ] Examples in `EXAMPLES.md` (if >50 lines)
- [ ] Error handling in `ERROR_HANDLING.md` (if >100 lines)
