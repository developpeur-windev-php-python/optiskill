# Skill Reviewer

Audit Claude Code skills using a deterministic 49-point scoring grid.

Based on [Mathieu Grenier's methodology](https://mathieugrenier.fr/blog/coder-avec-claude-c-est-facile-et-rapide-1/).

## Installation

```bash
# Copy to your Claude skills directory
cp -r skill-reviewer ~/.claude/skills/
chmod +x ~/.claude/skills/skill-reviewer/scripts/*.sh
```

## Usage

### Audit a single skill

```bash
./scripts/audit-skill.sh /path/to/my-skill
```

### Audit all skills in a directory

```bash
./scripts/audit-all-skills.sh /path/to/skills
```

## Output

Reports are saved to `/tmp/`:
- `skill-audit-report.md` — Single skill audit
- `all-skills-audit.md` — Batch audit report
- `skill-audit-results.csv` — Raw data

## Verdict Scale

| Score | Verdict | Action |
|-------|---------|--------|
| 90%+ | 🟢 Excellent | Production-ready |
| 80-89% | 🟡 Good | Minor fixes |
| 70-79% | 🟠 Acceptable | Works but fragile |
| 60-69% | 🔴 Insufficient | Fix before use |
| <60% | ⛔ Poor | Rewrite needed |

## The 49-Point Grid

- **Structure** (18 pts): Frontmatter, sections, organization
- **Coherence** (7 pts): Documentation matches implementation
- **Technical** (10 pts): Script quality and error handling
- **Design** (14 pts): Single responsibility, triggering, completeness

## See Also

- `skill-fixer` — Automatically fix common issues
- `references/common-errors.md` — The 10 most common errors

## License

MIT
