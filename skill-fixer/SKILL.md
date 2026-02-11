---
name: skill-fixer
slug: skill-fixer
description: |
  Use this skill when the user wants to automatically fix issues found in a skill audit.
  Triggers on: "fix my skill", "apply corrections", "improve skill score", 
  "fix the issues in my skill", "auto-fix skill", "correct skill problems".
  Takes audit findings and applies corrections automatically.
  Prioritizes fixes by point recovery and creates backups before changes.
category: development
complexity: intermediate
version: 1.0.0
author: Based on Mathieu Grenier's methodology
tags:
  - skill-improvement
  - auto-fix
  - claude-code
  - quality-assurance
triggers:
  - "fix my skill"
  - "apply corrections"
  - "improve skill score"
  - "fix the issues"
  - "auto-fix skill"
  - "correct skill problems"
  - "improve my skill"
---

# Skill Fixer

Automatically applies corrections to Claude Code skills based on common issues. Transforms low-scoring skills into production-ready ones.

## When to use this skill

- After running skill-reviewer and receiving an audit report
- User wants to quickly improve a skill's quality score
- User says "fix the issues found in my skill"
- User wants to reach production-ready status (80%+)

## Philosophy

**Fix in priority order.** Not all fixes are equal. Fixing the description (+3 points) has more impact than adding a version field (+1 point).

**Verify after fixing.** Every fix should be validated by re-running the audit.

**Preserve intent.** Fixes enhance without changing core functionality.

---

## Automatic Fixes Applied

| Priority | Fix | Points |
|----------|-----|--------|
| 1 | Rewrite description with "Use this skill when..." | +3 |
| 2 | Add trigger examples (4 examples) | +2 |
| 3 | Add "When to use" section | +2 |
| 4 | Add "Output Format" section | +1 |
| 5 | Add "Constraints/Edge Cases" section | +1 |
| 6 | Add `set -euo pipefail` to scripts | +4 |
| 7 | Complete frontmatter (slug, category, version) | +3 |

**Total potential recovery: +16 points**

---

## Output Format

The fixer produces:

1. **Backup** — Original SKILL.md saved to `.backups/`
2. **Updated SKILL.md** — With all fixes applied
3. **Updated scripts/** — With error handling added
4. **Fix Report** — Summary of changes made

```
## Summary

- Fixes applied: 7
- Points recovered: ~16
- Backup location: .backups/

## Fixes Applied

1. ✅ Description rewrite
2. ✅ Trigger examples
3. ✅ When to use section
...
```

---

## Usage

### Fix a single skill

```bash
./scripts/fix-skill.sh /path/to/skill
```

### Fix all skills in a directory

```bash
./scripts/fix-all-skills.sh /path/to/skills
```

### Dry run (preview changes)

```bash
./scripts/fix-skill.sh /path/to/skill --dry-run
```

---

## Constraints

- Creates backups before any changes
- Will not delete existing content, only add/enhance
- Maximum 3 fix iterations before requiring human input
- Some fixes may need manual refinement for domain-specific content

---

## Integration with skill-reviewer

```
┌─────────────────┐
│  skill-reviewer │ ──► Score: 42%
│  (audit)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  skill-fixer    │ ──► Fixes applied
│  (corrections)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  skill-reviewer │ ──► Score: 85% ✅
│  (verify)       │
└─────────────────┘
```

---

## References

- skill-reviewer (companion skill)
- [Anthropic Skill Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Mathieu Grenier - Quality Grid](https://mathieugrenier.fr/blog/coder-avec-claude-c-est-facile-et-rapide-1/)
