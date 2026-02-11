#!/usr/bin/env bash
#
# audit-all-skills.sh - Audit all skills in a directory
#
# Usage: ./audit-all-skills.sh /path/to/skills
#

set -euo pipefail

SKILLS_DIR="${1:-.}"
OUTPUT_FILE="/tmp/all-skills-audit.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}BATCH SKILL AUDIT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo "Directory: $SKILLS_DIR"
echo ""

# Find all SKILL.md files
SKILL_FILES=$(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)
TOTAL=$(echo "$SKILL_FILES" | grep -c "SKILL.md" || echo "0")

echo -e "${GREEN}[INFO]${NC} Found $TOTAL skills to audit"
echo ""

# Results file
RESULTS_FILE="/tmp/skill-audit-results.csv"
echo "name,score,percentage,verdict,issues" > "$RESULTS_FILE"

# Audit each skill
audit_skill() {
    local skill_path="$1"
    local skill_name
    skill_name=$(basename "$skill_path")
    local skill_md="$skill_path/SKILL.md"
    
    echo -n "Auditing $skill_name... "
    
    local score=0
    local issues=""
    
    # Read skill content
    local content
    content=$(cat "$skill_md" 2>/dev/null || echo "")
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_md" 2>/dev/null | head -50 || echo "")
    
    # === PASS 1: Structure (18 pts) ===
    
    if echo "$frontmatter" | grep -q "^name:"; then
        score=$((score + 1))
    fi
    
    if echo "$frontmatter" | grep -q "^slug:"; then
        score=$((score + 1))
    fi
    
    local desc_len
    desc_len=$(echo "$frontmatter" | grep -A20 "^description:" | wc -c)
    if [ "$desc_len" -gt 50 ]; then
        score=$((score + 1))
    else
        issues="$issues,short-desc"
    fi
    
    if echo "$frontmatter" | grep -qi "use this skill when"; then
        score=$((score + 2))
    else
        issues="$issues,no-trigger-phrase"
    fi
    
    if echo "$frontmatter" | grep -q "^category:"; then
        score=$((score + 1))
    fi
    
    if echo "$frontmatter" | grep -q "^version:"; then
        score=$((score + 1))
    fi
    
    local trigger_count
    trigger_count=$(echo "$frontmatter" | grep -c "^  - " || true)
    trigger_count=${trigger_count:-0}
    if [ "$trigger_count" -ge 2 ]; then
        score=$((score + 2))
    else
        issues="$issues,few-triggers"
    fi
    
    if echo "$content" | grep -qi "when to use"; then
        score=$((score + 2))
    else
        issues="$issues,no-when-section"
    fi
    
    if echo "$content" | grep -qiE "constraint|limitation|edge"; then
        score=$((score + 1))
    fi
    
    if echo "$content" | grep -qi "## example"; then
        score=$((score + 1))
    fi
    
    if echo "$content" | grep -qi "output format"; then
        score=$((score + 1))
    fi
    
    local lines
    lines=$(wc -l < "$skill_md" 2>/dev/null || echo "999")
    if [ "$lines" -lt 500 ]; then
        score=$((score + 1))
    fi
    
    if [ -d "$skill_path/scripts" ]; then
        score=$((score + 1))
    fi
    
    score=$((score + 1))
    
    # === PASS 2: Coherence (7 pts) ===
    score=$((score + 5))
    if echo "$content" | grep -qE '```'; then
        score=$((score + 1))
    fi
    score=$((score + 1))
    
    # === PASS 3: Technical (10 pts) ===
    if [ -d "$skill_path/scripts" ]; then
        local has_scripts=0
        local good_scripts=0
        shopt -s nullglob
        for script in "$skill_path/scripts"/*.sh; do
            if [ -f "$script" ]; then
                has_scripts=$((has_scripts + 1))
                if grep -q "set -e" "$script"; then
                    good_scripts=$((good_scripts + 1))
                fi
            fi
        done
        shopt -u nullglob
        
        if [ "$has_scripts" -gt 0 ]; then
            if [ "$good_scripts" -eq "$has_scripts" ]; then
                score=$((score + 6))
            else
                score=$((score + 3))
            fi
            score=$((score + 4))
        else
            score=$((score + 5))
        fi
    else
        score=$((score + 5))
    fi
    
    # === PASS 4: Design (14 pts) ===
    local h2_count
    h2_count=$(grep -c "^## " "$skill_md" 2>/dev/null || true)
    h2_count=${h2_count:-0}
    
    if [ "$h2_count" -lt 15 ]; then
        score=$((score + 2))
    else
        score=$((score + 1))
    fi
    
    score=$((score + 2))
    
    if echo "$content" | grep -qi "use this skill when"; then
        score=$((score + 2))
    else
        issues="$issues,vague-trigger"
    fi
    
    local generic
    generic=$(echo "$content" | grep -ciE "help you|assist you|can do many" || true)
    generic=${generic:-0}
    
    if [ "$generic" -lt 3 ]; then
        score=$((score + 2))
    else
        score=$((score + 1))
    fi
    
    if echo "$content" | grep -qiE "step|process|workflow"; then
        score=$((score + 2))
    else
        score=$((score + 1))
    fi
    
    if [ "$h2_count" -ge 3 ]; then
        score=$((score + 2))
    else
        score=$((score + 1))
    fi
    
    score=$((score + 2))
    
    # Calculate percentage and verdict
    local percentage=$((score * 100 / 49))
    local verdict
    if [ "$percentage" -ge 90 ]; then
        verdict="Excellent"
    elif [ "$percentage" -ge 80 ]; then
        verdict="Good"
    elif [ "$percentage" -ge 70 ]; then
        verdict="Acceptable"
    elif [ "$percentage" -ge 60 ]; then
        verdict="Insufficient"
    else
        verdict="Poor"
    fi
    
    local issue_count
    issue_count=$(echo "$issues" | tr ',' '\n' | grep -c "." || true)
    issue_count=${issue_count:-0}
    
    echo "$score/49 ($percentage%) - $verdict"
    
    echo "$skill_name,$score,$percentage,$verdict,$issue_count" >> "$RESULTS_FILE"
}

# Process all skills
while IFS= read -r skill_md; do
    if [ -n "$skill_md" ]; then
        skill_path=$(dirname "$skill_md")
        audit_skill "$skill_path"
    fi
done <<< "$SKILL_FILES"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}GENERATING REPORT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

# Generate report
{
    echo "# Skills Audit Report"
    echo ""
    echo "**Directory:** $SKILLS_DIR"
    echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Skills Audited:** $TOTAL"
    echo ""
    echo "---"
    echo ""
    
    # Count verdicts
    excellent=$(grep -c "Excellent" "$RESULTS_FILE" || true)
    excellent=${excellent:-0}
    good=$(grep -c ",Good," "$RESULTS_FILE" || true)
    good=${good:-0}
    acceptable=$(grep -c "Acceptable" "$RESULTS_FILE" || true)
    acceptable=${acceptable:-0}
    insufficient=$(grep -c "Insufficient" "$RESULTS_FILE" || true)
    insufficient=${insufficient:-0}
    poor=$(grep -c "Poor" "$RESULTS_FILE" || true)
    poor=${poor:-0}
    
    echo "## Summary"
    echo ""
    echo "| Verdict | Count | % |"
    echo "|---------|-------|---|"
    echo "| 🟢 Excellent (90%+) | $excellent | $((excellent * 100 / TOTAL))% |"
    echo "| 🟡 Good (80-89%) | $good | $((good * 100 / TOTAL))% |"
    echo "| 🟠 Acceptable (70-79%) | $acceptable | $((acceptable * 100 / TOTAL))% |"
    echo "| 🔴 Insufficient (60-69%) | $insufficient | $((insufficient * 100 / TOTAL))% |"
    echo "| ⛔ Poor (<60%) | $poor | $((poor * 100 / TOTAL))% |"
    echo ""
    echo "**Production-ready (80%+):** $((excellent + good))/$TOTAL"
    echo ""
    echo "---"
    echo ""
    echo "## All Skills (Ranked by Score)"
    echo ""
    echo "| Rank | Skill | Score | Verdict |"
    echo "|------|-------|-------|---------|"
    
    rank=1
    tail -n +2 "$RESULTS_FILE" | sort -t',' -k2 -rn | head -50 | while IFS=',' read -r name score pct verdict issues; do
        echo "| $rank | $name | $score/49 ($pct%) | $verdict |"
        rank=$((rank + 1))
    done
    
    echo ""
    echo "---"
    echo ""
    echo "## Skills Needing Attention (<80%)"
    echo ""
    
    tail -n +2 "$RESULTS_FILE" | sort -t',' -k2 -rn | while IFS=',' read -r name score pct verdict issues; do
        if [ "$pct" -lt 80 ]; then
            echo "- **$name** ($score/49, $pct%)"
        fi
    done | head -30
    
    echo ""
    echo "---"
    echo ""
    echo "*Generated by skill-reviewer*"
    
} | tee "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}[INFO]${NC} Report saved to: $OUTPUT_FILE"
echo -e "${GREEN}[INFO]${NC} CSV data saved to: $RESULTS_FILE"
