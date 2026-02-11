---
name: skill-reviewer
slug: skill-reviewer
description: |
  Use this skill when the user wants to audit, review, or evaluate the quality of Claude Code skills.
  Triggers on: "audit my skill", "review this skill", "check skill quality", "score my skill",
  "evaluate skill", "what's wrong with my skill", "is my skill production-ready".
  Applies a deterministic 49-point scoring grid across 4 passes: Structure, Coherence,
  Technical Quality, and Design. Produces actionable reports with prioritized fixes.
category: development
complexity: intermediate
version: 1.0.0
author: Based on Mathieu Grenier's methodology
tags:
  - skill-audit
  - quality-assurance
  - claude-code
  - best-practices
triggers:
  - "audit my skill"
  - "review this skill"
  - "check skill quality"
  - "score my skill"
  - "evaluate my skill"
  - "is my skill production-ready"
  - "what's wrong with my skill"
---

# Skill Reviewer

Audits Claude Code skills using a deterministic 49-point scoring grid. Produces objective, reproducible quality scores and prioritized correction reports.

## When to use this skill

- User wants to audit an existing skill's quality
- User reports a skill that doesn't trigger correctly
- User wants to improve a skill before production deployment
- User needs to compare skill versions objectively
- User asks "is my skill production-ready?"

## Philosophy

**LLM-as-judge has ~53% adoption but poor reproducibility.** Two evaluations of the same skill can produce different results. This skill uses **binary checks** instead: a criterion is met or it isn't. No subjectivity, no variance.

**The goal:** Transform vague "this skill feels broken" into "this skill scores 62% with 5 critical fixes needed."

---

## The 49-Point Scoring Grid

### Pass 1 — Structure (18 points)

| Category | Criteria | Points |
|----------|----------|--------|
| Frontmatter | name, slug, description, category, version, triggers (2+) | 9 |
| Sections | Title, "When to use", constraints, examples, output format | 6 |
| Organization | <500 lines, scripts/ dir, no long inline code | 3 |

### Pass 2 — Coherence (7 points)

| Criteria | Points |
|----------|--------|
| Documented commands exist in scripts | 2 |
| All scripts are documented | 2 |
| Flags match implementation | 1 |
| Examples are executable | 1 |
| Cross-references valid | 1 |

### Pass 3 — Technical Quality (10 points)

| Criteria | Points |
|----------|--------|
| Shebang present | 1 |
| `set -euo pipefail` | 2 |
| Main guard | 1 |
| Trap cleanup | 2 |
| Variables quoted | 1 |
| Header comments | 1 |
| Temp files cleaned | 1 |
| Structured logging | 1 |

### Pass 4 — Design (14 points)

| Criteria | Points |
|----------|--------|
| Single responsibility | 2 |
| Low coupling | 2 |
| Precise triggering | 2 |
| Specificity | 2 |
| Actionability | 2 |
| Completeness | 2 |
| Separation of concerns | 2 |

---

## Verdict Scale

| Score | Verdict | Meaning |
|-------|---------|---------|
| 90%+ (44+) | 🟢 Excellent | Production-ready |
| 80-89% (39-43) | 🟡 Good | Minor improvements needed |
| 70-79% (34-38) | 🟠 Acceptable | Works but fragile |
| 60-69% (29-33) | 🔴 Insufficient | Production risks |
| <60% (<29) | ⛔ Poor | Needs rewrite |

---

## Output Format

The audit produces a Markdown report:

```markdown
# Skill Audit Report: {skill-name}

**Score:** {points}/49 ({percentage}%)  
**Verdict:** {Excellent|Good|Acceptable|Insufficient|Poor}

## Score Breakdown

| Pass | Score | Max | % |
|------|-------|-----|---|
| Structure | X | 18 | Y% |
| Coherence | X | 7 | Y% |
| Technical | X | 10 | Y% |
| Design | X | 14 | Y% |

## Critical Issues (Fix First)
1. {Issue with highest impact}
...
```

---

## Usage

### Audit a single skill
```bash
./scripts/audit-skill.sh /path/to/skill
```

### Audit all skills in a directory
```bash
./scripts/audit-all-skills.sh /path/to/skills
```

---

## Constraints

- Audits ONE skill at a time (use batch script for multiple)
- Scripts are analyzed statically (not executed)
- Maximum audit time: ~5 minutes per skill

---

## References

- [Anthropic Skill Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Mathieu Grenier - Quality Grid Methodology](https://mathieugrenier.fr/blog/coder-avec-claude-c-est-facile-et-rapide-1/)
- [Lee Han Chung - Claude Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
