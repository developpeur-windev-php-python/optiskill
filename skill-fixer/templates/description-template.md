# Template: Skill Description

Use this structure for high-quality descriptions that trigger correctly.

## Structure

```yaml
description: |
  Use this skill when the user asks to {PRIMARY_ACTION}.
  Triggers on: "{trigger_1}", "{trigger_2}", "{trigger_3}".
  {CAPABILITY_SUMMARY}.
```

## Examples

### PDF Processor
```yaml
description: |
  Use this skill when the user asks to process PDF files.
  Triggers on: "read this PDF", "extract text from PDF", "merge PDFs".
  Handles text extraction, merging, splitting, and form filling.
```

### Code Reviewer
```yaml
description: |
  Use this skill when the user asks to review code quality.
  Triggers on: "review my code", "check for bugs", "code quality".
  Detects bugs, security issues, and style violations.
```

## Anti-Patterns

❌ Too vague: `"Helps with files"`
❌ First person: `"I can help you process documents"`
❌ No triggers: `"Processes PDF files for various tasks"`

## Checklist

- [ ] Starts with "Use this skill when"
- [ ] Contains 3+ trigger phrases in quotes
- [ ] Uses action verbs
- [ ] Under 500 characters
- [ ] No first-person language
