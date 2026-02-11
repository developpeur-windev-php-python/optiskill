# The 10 Most Common Errors and Their Fixes

Based on Mathieu Grenier's analysis, these 10 errors account for ~80% of points lost in skill audits.

---

## Error 1: Vague or Missing Description

**Point Impact:** -3 points  
**Activation Impact:** ~50% — Claude doesn't know when to trigger

```yaml
# ❌ Bad
description: "Helps with files"

# ✅ Good  
description: |
  Use this skill when the user asks to process Excel spreadsheets.
  Triggers on: "analyze this Excel file", "extract data from xlsx".
```

---

## Error 2: Fewer Than 2 Trigger Examples

**Point Impact:** -2 points

```yaml
# ❌ Bad
# No triggers section

# ✅ Good
triggers:
  - "analyze this Excel file"
  - "extract data from spreadsheet"
  - "summarize the xlsx"
```

---

## Error 3: First-Person Prompt

**Point Impact:** -2 points

```markdown
# ❌ Bad
I am a helpful assistant. I can help you...

# ✅ Good
Extracts, validates, and summarizes data from Excel spreadsheets.
```

---

## Error 4: No Output Format Section

**Point Impact:** -1 point

```markdown
# ✅ Add this section
## Output Format

Produces a Markdown report with:
1. **Summary**: Key metrics
2. **Findings**: Detailed results
3. **Recommendations**: Next steps
```

---

## Error 5: No Edge Cases Section

**Point Impact:** -1 point

```markdown
# ✅ Add this section
## Edge Cases

- **Empty file**: Return informative message
- **Invalid format**: Reject with clear error
- **Large files**: Process in chunks or warn
```

---

## Error 6: Overly Permissive Tools

**Point Impact:** -2 points

```yaml
# ❌ Bad - no restriction
# (agent has access to everything)

# ✅ Good
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
```

---

## Error 7: Missing context: fork

**Point Impact:** Token waste (3000+ tokens)

```yaml
# ✅ Add for skills with significant output
context: fork
```

---

## Error 8: Scripts Without Error Handling

**Point Impact:** -4 points

```bash
# ❌ Bad
#!/bin/bash
result=$(curl $API_URL)
echo $result

# ✅ Good
#!/usr/bin/env bash
set -euo pipefail
trap 'echo "ERROR at line $LINENO" >&2; exit 1' ERR

result=$(curl --fail --silent "$API_URL")
echo "$result"
```

---

## Error 9: Monolithic Design

**Point Impact:** -2 points

Split large skills into focused sub-skills with single responsibilities.

---

## Error 10: No Consumption Constraints

**Point Impact:** Runaway costs

```markdown
# ✅ Add this section
## Constraints

- **Max tool calls**: 20 per execution
- **Max output tokens**: ~4,000
- **Expected duration**: 2-5 minutes
```

---

## Fix Priority Order

1. Description + triggers (fixes activation)
2. Output Format (fixes consistency)
3. Error handling (fixes reliability)
4. Single responsibility (fixes maintainability)
5. Edge cases (fixes robustness)
