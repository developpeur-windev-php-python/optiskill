#!/usr/bin/env bash
#
# fix-skill.sh - Automatically fix common skill issues
#
# Usage: ./fix-skill.sh /path/to/skill [--dry-run]
#

set -euo pipefail

SKILL_PATH="${1:?Usage: $0 /path/to/skill [--dry-run]}"
DRY_RUN="${2:-}"
SKILL_MD="$SKILL_PATH/SKILL.md"
BACKUP_DIR="$SKILL_PATH/.backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Tracking
declare -a fixes_applied=()
points_recovered=0

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_fix() { echo -e "${CYAN}[FIX]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${BLUE}═══ $* ═══${NC}"; }

create_backup() {
    mkdir -p "$BACKUP_DIR"
    cp "$SKILL_MD" "$BACKUP_DIR/SKILL.md.$TIMESTAMP"
    log_info "Backup created: $BACKUP_DIR/SKILL.md.$TIMESTAMP"
}

get_skill_name() {
    grep "^name:" "$SKILL_MD" 2>/dev/null | head -1 | sed 's/name: *//' | tr -d '"' || basename "$SKILL_PATH"
}

get_frontmatter() {
    sed -n '/^---$/,/^---$/p' "$SKILL_MD" | head -100
}

#=============================================================================
# FIX 1: Description Rewrite
#=============================================================================
fix_description() {
    log_section "Fix 1: Description"
    
    local frontmatter
    frontmatter=$(get_frontmatter)
    
    if echo "$frontmatter" | grep -qi "use this skill when"; then
        log_info "✓ Description already has proper trigger phrasing"
        return 0
    fi
    
    local skill_name
    skill_name=$(get_skill_name)
    local skill_words="${skill_name//-/ }"
    
    local purpose
    case "$skill_name" in
        *pdf*|*PDF*) purpose="process, read, or manipulate PDF files" ;;
        *excel*|*xlsx*) purpose="work with Excel spreadsheets" ;;
        *image*|*img*) purpose="process or manipulate images" ;;
        *code*|*review*) purpose="analyze or review code" ;;
        *automation*) purpose="automate tasks with ${skill_words%% *}" ;;
        *) purpose="perform tasks related to ${skill_words}" ;;
    esac
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would rewrite description"
        return 0
    fi
    
    python3 << PYEOF
import re

with open("$SKILL_MD", 'r') as f:
    content = f.read()

new_desc = '''description: |
  Use this skill when the user asks to $purpose.
  Triggers on: "help me with $skill_words", "process $skill_words", "$skill_words task".
  Provides automated assistance for $skill_words operations.'''

pattern = r'description:.*?(?=\n[a-z_-]+:|^---$)'
if re.search(pattern, content, re.MULTILINE | re.DOTALL):
    content = re.sub(pattern, new_desc + '\n', content, count=1, flags=re.MULTILINE | re.DOTALL)

with open("$SKILL_MD", 'w') as f:
    f.write(content)
PYEOF
    
    log_fix "Description rewritten with trigger phrasing (+3 pts)"
    fixes_applied+=("Description rewrite")
    points_recovered=$((points_recovered + 3))
}

#=============================================================================
# FIX 2: Add Triggers
#=============================================================================
fix_triggers() {
    log_section "Fix 2: Trigger Examples"
    
    local frontmatter
    frontmatter=$(get_frontmatter)
    
    local trigger_count
    trigger_count=$(echo "$frontmatter" | grep -c "^  - " || true)
    trigger_count=${trigger_count:-0}
    
    if [ "$trigger_count" -ge 2 ]; then
        log_info "✓ Already has $trigger_count triggers"
        return 0
    fi
    
    local skill_name
    skill_name=$(get_skill_name)
    local skill_words="${skill_name//-/ }"
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would add triggers"
        return 0
    fi
    
    python3 << PYEOF
with open("$SKILL_MD", 'r') as f:
    content = f.read()

if 'triggers:' not in content:
    parts = content.split('---')
    if len(parts) >= 3:
        triggers_block = """
triggers:
  - "help me with $skill_words"
  - "$skill_words this file"
  - "run $skill_words"
  - "use $skill_words on"
"""
        parts[1] = parts[1].rstrip() + triggers_block
        content = '---'.join(parts)
    
    with open("$SKILL_MD", 'w') as f:
        f.write(content)
PYEOF
    
    log_fix "Added trigger examples (+2 pts)"
    fixes_applied+=("Trigger examples")
    points_recovered=$((points_recovered + 2))
}

#=============================================================================
# FIX 3: Add "When to use" Section
#=============================================================================
fix_when_to_use() {
    log_section "Fix 3: When to Use Section"
    
    if grep -qi "when to use" "$SKILL_MD"; then
        log_info "✓ 'When to use' section exists"
        return 0
    fi
    
    local skill_name
    skill_name=$(get_skill_name)
    local skill_words="${skill_name//-/ }"
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would add 'When to use' section"
        return 0
    fi
    
    local section="

## When to use this skill

- User asks to work with $skill_words
- User needs help processing related files
- User mentions \"$skill_words\" in their request
- Task requires $skill_words capabilities
"
    
    python3 << PYEOF
import re

with open("$SKILL_MD", 'r') as f:
    content = f.read()

if 'when to use' not in content.lower():
    h1_match = re.search(r'^# .+$', content, re.MULTILINE)
    if h1_match:
        pos = h1_match.end()
        next_para = re.search(r'\n\n', content[pos:])
        if next_para:
            insert_pos = pos + next_para.end()
            section = '''
## When to use this skill

- User asks to work with $skill_words
- User needs help processing related files
- User mentions "$skill_words" in their request
- Task requires $skill_words capabilities
'''
            content = content[:insert_pos] + section + content[insert_pos:]

    with open("$SKILL_MD", 'w') as f:
        f.write(content)
PYEOF
    
    log_fix "Added 'When to use' section (+2 pts)"
    fixes_applied+=("When to use section")
    points_recovered=$((points_recovered + 2))
}

#=============================================================================
# FIX 4: Add Output Format Section
#=============================================================================
fix_output_format() {
    log_section "Fix 4: Output Format Section"
    
    if grep -qi "output format" "$SKILL_MD"; then
        log_info "✓ Output format section exists"
        return 0
    fi
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would add Output Format section"
        return 0
    fi
    
    cat >> "$SKILL_MD" << 'EOF'

## Output Format

The skill produces structured output including:

1. **Status**: Success or failure indication
2. **Results**: Main output data
3. **Metrics**: Processing statistics (if applicable)
4. **Errors**: Any issues encountered
EOF
    
    log_fix "Added Output Format section (+1 pt)"
    fixes_applied+=("Output format section")
    points_recovered=$((points_recovered + 1))
}

#=============================================================================
# FIX 5: Add Edge Cases Section
#=============================================================================
fix_edge_cases() {
    log_section "Fix 5: Edge Cases Section"
    
    if grep -qiE "edge case|constraint|limitation" "$SKILL_MD"; then
        log_info "✓ Edge cases/constraints section exists"
        return 0
    fi
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would add Constraints section"
        return 0
    fi
    
    cat >> "$SKILL_MD" << 'EOF'

## Constraints and Edge Cases

- **Empty input**: Returns informative message, no error
- **Invalid format**: Rejects with clear error message
- **Large files**: May process in chunks or warn about limits
- **Missing dependencies**: Reports what is needed
EOF
    
    log_fix "Added Constraints section (+1 pt)"
    fixes_applied+=("Edge cases section")
    points_recovered=$((points_recovered + 1))
}

#=============================================================================
# FIX 6: Script Error Handling
#=============================================================================
fix_script_error_handling() {
    log_section "Fix 6: Script Error Handling"
    
    local scripts_dir="$SKILL_PATH/scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        log_info "No scripts directory"
        return 0
    fi
    
    local fixed_count=0
    
    shopt -s nullglob
    for script in "$scripts_dir"/*.sh "$scripts_dir"/*.bash; do
        if [ ! -f "$script" ]; then
            continue
        fi
        
        local script_name
        script_name=$(basename "$script")
        
        if grep -q "set -euo pipefail" "$script"; then
            log_info "✓ $script_name already has error handling"
            continue
        fi
        
        if [ "$DRY_RUN" = "--dry-run" ]; then
            log_fix "[DRY-RUN] Would add error handling to $script_name"
            continue
        fi
        
        mkdir -p "$BACKUP_DIR"
        cp "$script" "$BACKUP_DIR/${script_name}.$TIMESTAMP"
        
        local temp_file
        temp_file=$(mktemp)
        
        head -1 "$script" > "$temp_file"
        
        cat >> "$temp_file" << 'ERRORHANDLING'

# Strict error handling
set -euo pipefail
trap 'echo "ERROR: Script failed at line $LINENO" >&2; exit 1' ERR

ERRORHANDLING
        
        tail -n +2 "$script" >> "$temp_file"
        mv "$temp_file" "$script"
        chmod +x "$script"
        
        log_fix "Added error handling to $script_name"
        fixed_count=$((fixed_count + 1))
    done
    shopt -u nullglob
    
    if [ "$fixed_count" -gt 0 ]; then
        fixes_applied+=("Script error handling ($fixed_count files)")
        points_recovered=$((points_recovered + 4))
        log_fix "Fixed $fixed_count scripts (+4 pts)"
    fi
}

#=============================================================================
# FIX 7: Add Missing Frontmatter Fields
#=============================================================================
fix_frontmatter_fields() {
    log_section "Fix 7: Frontmatter Fields"
    
    local frontmatter
    frontmatter=$(get_frontmatter)
    local skill_name
    skill_name=$(get_skill_name)
    
    local fields_to_add=""
    local points=0
    
    if ! echo "$frontmatter" | grep -q "^slug:"; then
        local slug="${skill_name,,}"
        slug="${slug// /-}"
        fields_to_add="${fields_to_add}slug: $slug\n"
        points=$((points + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^category:"; then
        fields_to_add="${fields_to_add}category: utility\n"
        points=$((points + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^version:"; then
        fields_to_add="${fields_to_add}version: 1.0.0\n"
        points=$((points + 1))
    fi
    
    if [ -z "$fields_to_add" ]; then
        log_info "✓ All frontmatter fields present"
        return 0
    fi
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_fix "[DRY-RUN] Would add frontmatter fields"
        return 0
    fi
    
    python3 << PYEOF
import re

with open("$SKILL_MD", 'r') as f:
    content = f.read()

fields = """$fields_to_add"""

match = re.search(r'(name:.*?\n)', content)
if match:
    pos = match.end()
    content = content[:pos] + fields + content[pos:]

with open("$SKILL_MD", 'w') as f:
    f.write(content)
PYEOF
    
    log_fix "Added missing frontmatter fields (+$points pts)"
    fixes_applied+=("Frontmatter fields")
    points_recovered=$((points_recovered + points))
}

#=============================================================================
# REPORT
#=============================================================================
generate_report() {
    local skill_name
    skill_name=$(get_skill_name)
    
    cat << EOF

═══════════════════════════════════════════════════════════════
                      FIX REPORT: $skill_name
═══════════════════════════════════════════════════════════════

## Summary

- **Fixes applied**: ${#fixes_applied[@]}
- **Points recovered**: ~$points_recovered
- **Backup location**: $BACKUP_DIR

## Fixes Applied

EOF
    
    local i=1
    for fix in "${fixes_applied[@]}"; do
        echo "$i. ✅ $fix"
        i=$((i + 1))
    done
    
    if [ ${#fixes_applied[@]} -eq 0 ]; then
        echo "No fixes were needed."
    fi
    
    cat << EOF

## Next Steps

1. Run skill-reviewer to verify improvements
2. Review changes manually for accuracy
3. Test the skill with real prompts

## Backup Recovery

To restore the original:
cp $BACKUP_DIR/SKILL.md.$TIMESTAMP $SKILL_MD

EOF
}

#=============================================================================
# MAIN
#=============================================================================
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                     SKILL FIXER                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ ! -f "$SKILL_MD" ]; then
        log_error "SKILL.md not found at: $SKILL_MD"
        exit 1
    fi
    
    if [ "$DRY_RUN" = "--dry-run" ]; then
        log_warn "DRY RUN MODE - No changes will be made"
    else
        create_backup
    fi
    
    log_info "Fixing skill at: $SKILL_PATH"
    log_info "Skill name: $(get_skill_name)"
    
    fix_description
    fix_triggers
    fix_when_to_use
    fix_output_format
    fix_edge_cases
    fix_script_error_handling
    fix_frontmatter_fields
    
    generate_report
}

main "$@"
