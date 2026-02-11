# Skill Fixer

Automatically fix common issues in Claude Code skills.

Companion to [skill-reviewer](../skill-reviewer/).

## Installation

```bash
cp -r skill-fixer ~/.claude/skills/
chmod +x ~/.claude/skills/skill-fixer/scripts/*.sh
```

## Usage

### Fix a single skill

```bash
./scripts/fix-skill.sh /path/to/skill
```

### Fix all skills

```bash
./scripts/fix-all-skills.sh /path/to/skills
```

### Preview changes (dry run)

```bash
./scripts/fix-skill.sh /path/to/skill --dry-run
```

## Fixes Applied

| Fix | Points |
|-----|--------|
| Description rewrite | +3 |
| Trigger examples | +2 |
| "When to use" section | +2 |
| Output format section | +1 |
| Edge cases section | +1 |
| Script error handling | +4 |
| Frontmatter completion | +3 |
| **Total** | **+16** |

## Workflow

```
1. Audit:  ./skill-reviewer/scripts/audit-all-skills.sh .
2. Fix:    ./skill-fixer/scripts/fix-all-skills.sh .
3. Verify: ./skill-reviewer/scripts/audit-all-skills.sh .
```

## Backups

All changes create backups in `.backups/` directory.

To restore:
```bash
cp .backups/SKILL.md.{timestamp} SKILL.md
```

## License

MIT
