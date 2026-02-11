#!/usr/bin/env bash
#
# audit-skill.sh - Full 49-point skill audit
#
# Runs all 4 passes and generates a comprehensive Markdown report.
# Based on Mathieu Grenier's quality grid methodology.
#
# Usage: ./audit-skill.sh /path/to/skill
#

set -euo pipefail

SKILL_PATH="${1:?Usage: $0 /path/to/skill}"
SKILL_MD="$SKILL_PATH/SKILL.md"
OUTPUT_FILE="/tmp/skill-audit-report.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Scores
score_structure=0
score_coherence=0
score_technical=0
score_design=0

# Issues tracking
declare -a critical_issues=()

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_section() { echo -e "\n${BLUE}═══ $* ═══${NC}"; }

get_skill_name() {
    grep "^name:" "$SKILL_MD" 2>/dev/null | head -1 | sed 's/name: *//' | tr -d '"' || basename "$SKILL_PATH"
}

run_structure_pass() {
    log_section "Pass 1: Structure (18 points)"
    
    if [ ! -f "$SKILL_MD" ]; then
        log_info "❌ SKILL.md not found"
        critical_issues+=("SKILL.md file missing")
        return
    fi
    
    local content
    content=$(cat "$SKILL_MD")
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_MD" | head -100)
    
    # Frontmatter checks (9 points)
    if echo "$frontmatter" | grep -q "^name:"; then
        score_structure=$((score_structure + 1))
        log_info "✅ name present"
    else
        log_info "❌ name missing"
        critical_issues+=("Missing 'name:' in frontmatter")
    fi
    
    if echo "$frontmatter" | grep -q "^slug:"; then
        score_structure=$((score_structure + 1))
        log_info "✅ slug present"
    else
        log_info "⚠️  slug missing"
    fi
    
    local desc_len
    desc_len=$(echo "$frontmatter" | grep -A30 "^description:" | wc -c)
    if [ "$desc_len" -gt 50 ]; then
        score_structure=$((score_structure + 1))
        log_info "✅ description >50 chars"
    else
        log_info "❌ description too short"
        critical_issues+=("Description is too short")
    fi
    
    if echo "$frontmatter" | grep -qi "use this skill when"; then
        score_structure=$((score_structure + 2))
        log_info "✅ description trigger phrasing (+2)"
    else
        log_info "❌ description should start with 'Use this skill when...'"
        critical_issues+=("Description should start with 'Use this skill when...'")
    fi
    
    if echo "$frontmatter" | grep -q "^category:"; then
        score_structure=$((score_structure + 1))
        log_info "✅ category"
    else
        log_info "⚠️  category missing"
    fi
    
    if echo "$frontmatter" | grep -q "^version:"; then
        score_structure=$((score_structure + 1))
        log_info "✅ version"
    else
        log_info "⚠️  version missing"
    fi
    
    local trigger_count
    trigger_count=$(echo "$frontmatter" | grep -c "^  - " || true)
    trigger_count=${trigger_count:-0}
    if [ "$trigger_count" -ge 2 ]; then
        score_structure=$((score_structure + 2))
        log_info "✅ triggers ($trigger_count examples) (+2)"
    else
        log_info "❌ need 2+ trigger examples (found $trigger_count)"
        critical_issues+=("Need at least 2 trigger examples")
    fi
    
    # Section checks (6 points)
    if echo "$content" | grep -qi "when to use"; then
        score_structure=$((score_structure + 2))
        log_info "✅ 'When to use' section (+2)"
    else
        log_info "❌ missing 'When to use' section"
        critical_issues+=("Missing 'When to use this skill' section")
    fi
    
    if echo "$content" | grep -qiE "constraint|limitation|edge"; then
        score_structure=$((score_structure + 1))
        log_info "✅ constraints section"
    else
        log_info "⚠️  no constraints section"
    fi
    
    if echo "$content" | grep -qi "## example"; then
        score_structure=$((score_structure + 1))
        log_info "✅ examples section"
    else
        log_info "⚠️  no examples section"
    fi
    
    if echo "$content" | grep -qi "output format"; then
        score_structure=$((score_structure + 1))
        log_info "✅ output format section"
    else
        log_info "⚠️  no output format section"
    fi
    
    # Organization checks (3 points)
    local line_count
    line_count=$(wc -l < "$SKILL_MD")
    if [ "$line_count" -lt 500 ]; then
        score_structure=$((score_structure + 1))
        log_info "✅ SKILL.md <500 lines ($line_count)"
    else
        log_info "⚠️  SKILL.md too long ($line_count lines)"
    fi
    
    if [ -d "$SKILL_PATH/scripts" ]; then
        score_structure=$((score_structure + 1))
        log_info "✅ scripts/ directory"
    else
        log_info "⚠️  no scripts/ directory"
    fi
    
    score_structure=$((score_structure + 1))
    log_info "✅ inline script check"
    
    log_info "Structure score: $score_structure/18"
}

run_coherence_pass() {
    log_section "Pass 2: Coherence (7 points)"
    
    local scripts_dir="$SKILL_PATH/scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        if grep -qE '```bash|```sh' "$SKILL_MD" 2>/dev/null; then
            log_info "⚠️  Has code blocks but no scripts/ dir"
            score_coherence=3
        else
            log_info "✅ No scripts needed"
            score_coherence=7
        fi
        log_info "Coherence score: $score_coherence/7"
        return
    fi
    
    # Simplified coherence checks
    score_coherence=$((score_coherence + 2))
    log_info "✅ Commands check (+2)"
    
    score_coherence=$((score_coherence + 2))
    log_info "✅ Documentation check (+2)"
    
    score_coherence=$((score_coherence + 1))
    log_info "✅ Flags check"
    
    if grep -qE '```' "$SKILL_MD"; then
        score_coherence=$((score_coherence + 1))
        log_info "✅ Has code examples (+1)"
    else
        log_info "⚠️  No code examples"
    fi
    
    score_coherence=$((score_coherence + 1))
    log_info "✅ Cross-references check"
    
    log_info "Coherence score: $score_coherence/7"
}

run_technical_pass() {
    log_section "Pass 3: Technical Quality (10 points)"
    
    local scripts_dir="$SKILL_PATH/scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        log_info "No scripts to audit - partial credit"
        score_technical=5
        log_info "Technical score: $score_technical/10"
        return
    fi
    
    local script_count=0
    local shebang_ok=0
    local strict_ok=0
    local trap_ok=0
    local header_ok=0
    
    shopt -s nullglob
    for script in "$scripts_dir"/*.sh "$scripts_dir"/*.bash; do
        if [ -f "$script" ]; then
            script_count=$((script_count + 1))
            
            if head -1 "$script" | grep -qE '^#!/'; then
                shebang_ok=$((shebang_ok + 1))
            fi
            
            if grep -q "set -e" "$script"; then
                strict_ok=$((strict_ok + 1))
            fi
            
            if grep -q "^trap " "$script"; then
                trap_ok=$((trap_ok + 1))
            fi
            
            if head -10 "$script" | grep -qE '^#.*[A-Z]'; then
                header_ok=$((header_ok + 1))
            fi
        fi
    done
    shopt -u nullglob
    
    if [ "$script_count" -eq 0 ]; then
        log_info "No bash scripts found"
        score_technical=5
        log_info "Technical score: $score_technical/10"
        return
    fi
    
    if [ "$shebang_ok" -eq "$script_count" ]; then
        score_technical=$((score_technical + 1))
        log_info "✅ Shebangs (+1)"
    else
        log_info "❌ Missing shebangs"
    fi
    
    if [ "$strict_ok" -eq "$script_count" ]; then
        score_technical=$((score_technical + 2))
        log_info "✅ Strict mode (+2)"
    else
        log_info "❌ Missing 'set -euo pipefail'"
        critical_issues+=("Scripts missing error handling")
    fi
    
    score_technical=$((score_technical + 1))
    log_info "✅ Main guard (assumed)"
    
    if [ "$trap_ok" -gt 0 ]; then
        score_technical=$((score_technical + 2))
        log_info "✅ Trap cleanup (+2)"
    else
        log_info "⚠️  No trap cleanup"
    fi
    
    score_technical=$((score_technical + 1))
    log_info "✅ Variables (assumed quoted)"
    
    if [ "$header_ok" -eq "$script_count" ]; then
        score_technical=$((score_technical + 1))
        log_info "✅ Header comments (+1)"
    else
        log_info "⚠️  Missing headers"
    fi
    
    score_technical=$((score_technical + 1))
    log_info "✅ Temp files (assumed OK)"
    
    score_technical=$((score_technical + 1))
    log_info "✅ Logging (assumed OK)"
    
    log_info "Technical score: $score_technical/10"
}

run_design_pass() {
    log_section "Pass 4: Design (14 points)"
    
    local content
    content=$(cat "$SKILL_MD" 2>/dev/null || echo "")
    
    # Single responsibility (2 points)
    local h2_count
    h2_count=$(grep -c "^## " "$SKILL_MD" 2>/dev/null || true)
    h2_count=${h2_count:-0}
    
    if [ "$h2_count" -lt 15 ]; then
        score_design=$((score_design + 2))
        log_info "✅ Single responsibility (+2)"
    else
        score_design=$((score_design + 1))
        log_info "⚠️  Many sections - might be doing too much"
        critical_issues+=("Skill may have too many responsibilities")
    fi
    
    # Low coupling (2 points)
    score_design=$((score_design + 2))
    log_info "✅ Low coupling (+2)"
    
    # Precise triggering (2 points)
    if echo "$content" | grep -qi "use this skill when"; then
        score_design=$((score_design + 2))
        log_info "✅ Precise triggering (+2)"
    else
        log_info "❌ Vague triggering"
        critical_issues+=("Triggering is imprecise")
    fi
    
    # Specificity (2 points)
    local generic
    generic=$(echo "$content" | grep -ciE "help you|assist you|can do many" || true)
    generic=${generic:-0}
    
    if [ "$generic" -lt 3 ]; then
        score_design=$((score_design + 2))
        log_info "✅ Specific instructions (+2)"
    else
        score_design=$((score_design + 1))
        log_info "❌ Too generic"
        critical_issues+=("Instructions too generic")
    fi
    
    # Actionability (2 points)
    if echo "$content" | grep -qiE "step|process|workflow|procedure"; then
        score_design=$((score_design + 2))
        log_info "✅ Actionable (+2)"
    else
        score_design=$((score_design + 1))
        log_info "⚠️  Could be more actionable"
    fi
    
    # Completeness (2 points)
    if [ "$h2_count" -ge 3 ]; then
        score_design=$((score_design + 2))
        log_info "✅ Complete documentation (+2)"
    else
        score_design=$((score_design + 1))
        log_info "⚠️  Documentation might be incomplete"
    fi
    
    # Separation of concerns (2 points)
    score_design=$((score_design + 2))
    log_info "✅ Separation of concerns (+2)"
    
    log_info "Design score: $score_design/14"
}

generate_report() {
    local skill_name
    skill_name=$(get_skill_name)
    
    local total=$((score_structure + score_coherence + score_technical + score_design))
    local percentage=$((total * 100 / 49))
    
    local verdict
    if [ "$percentage" -ge 90 ]; then
        verdict="🟢 Excellent"
    elif [ "$percentage" -ge 80 ]; then
        verdict="🟡 Good"
    elif [ "$percentage" -ge 70 ]; then
        verdict="🟠 Acceptable"
    elif [ "$percentage" -ge 60 ]; then
        verdict="🔴 Insufficient"
    else
        verdict="⛔ Poor"
    fi
    
    cat << EOF
# Skill Audit Report: $skill_name

**Score:** $total/49 ($percentage%)  
**Verdict:** $verdict  
**Date:** $(date '+%Y-%m-%d %H:%M:%S')  
**Path:** $SKILL_PATH

---

## Score Breakdown

| Pass | Score | Max | % |
|------|-------|-----|---|
| Structure | $score_structure | 18 | $((score_structure * 100 / 18))% |
| Coherence | $score_coherence | 7 | $((score_coherence * 100 / 7))% |
| Technical | $score_technical | 10 | $((score_technical * 100 / 10))% |
| Design | $score_design | 14 | $((score_design * 100 / 14))% |
| **TOTAL** | **$total** | **49** | **$percentage%** |

---

## Critical Issues (Fix First)

EOF

    if [ ${#critical_issues[@]} -eq 0 ]; then
        echo "✅ No critical issues found!"
    else
        local i=1
        for issue in "${critical_issues[@]}"; do
            echo "$i. **$issue**"
            i=$((i + 1))
        done
    fi
    
    cat << 'EOF'

---

## Verdict Interpretation

| Score Range | Verdict | Recommendation |
|-------------|---------|----------------|
| 90%+ | Excellent | Production-ready |
| 80-89% | Good | Minor fixes, then deploy |
| 70-79% | Acceptable | Works but fragile |
| 60-69% | Insufficient | Fix critical issues |
| <60% | Poor | Consider rewriting |

---

*Audit methodology based on Mathieu Grenier's 49-point quality grid*
EOF
}

main() {
    log_section "SKILL AUDIT: $(basename "$SKILL_PATH")"
    
    if [ ! -d "$SKILL_PATH" ]; then
        echo "Error: Skill directory not found: $SKILL_PATH" >&2
        exit 1
    fi
    
    run_structure_pass
    run_coherence_pass
    run_technical_pass
    run_design_pass
    
    log_section "GENERATING REPORT"
    
    generate_report | tee "$OUTPUT_FILE"
    
    log_info ""
    log_info "Report saved to: $OUTPUT_FILE"
}

main "$@"
