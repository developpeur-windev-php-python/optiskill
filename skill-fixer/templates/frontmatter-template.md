# Template: Complete Frontmatter

## Full Structure

```yaml
---
name: {skill-name}
slug: {skill-name}
description: |
  Use this skill when the user asks to {ACTION}.
  Triggers on: "{trigger_1}", "{trigger_2}".
  {SUMMARY}.
category: {category}
version: 1.0.0
tags:
  - {tag_1}
  - {tag_2}
triggers:
  - "{trigger_phrase_1}"
  - "{trigger_phrase_2}"
  - "{trigger_phrase_3}"
---
```

## Required Fields

| Field | Description |
|-------|-------------|
| name | Human-readable skill name |
| description | Trigger-optimized description |

## Recommended Fields

| Field | Description |
|-------|-------------|
| slug | URL-safe identifier |
| category | Classification |
| version | Semantic version |
| triggers | User prompts that activate |

## Categories

- `data-processing`
- `file-management`
- `code-analysis`
- `documentation`
- `api-integration`
- `devops`
- `utility`

## Checklist

- [ ] name is kebab-case
- [ ] description starts with "Use this skill when"
- [ ] At least 2 triggers
- [ ] version follows semver
