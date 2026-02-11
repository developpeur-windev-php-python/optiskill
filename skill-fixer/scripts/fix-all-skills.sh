#!/usr/bin/env bash
#
# fix-all-skills.sh - Fix all skills in a directory
#
# Usage: ./fix-all-skills.sh /path/to/skills
#

set -euo pipefail

SKILLS_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXER_SCRIPT="$SCRIPT_DIR/fix-skill.sh"
LOG_FILE="/tmp/fix-all-skills.log"
RESULTS_FILE="/tmp/fix-results.csv"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}BATCH SKILL FIXER${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo "Directory: $SKILLS_DIR"
echo ""

# Check if fixer script exists
if [ ! -f "$FIXER_SCRIPT" ]; then
    echo -e "${RED}[ERROR]${NC} Fixer script not found: $FIXER_SCRIPT"
    exit 1
fi

# Find all SKILL.md files
SKILL_FILES=$(find "$SKILLS_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)
TOTAL=$(echo "$SKILL_FILES" | grep -c "SKILL.md" || echo "0")

echo -e "${GREEN}[INFO]${NC} Found $TOTAL skills to fix"
echo ""

# Initialize
echo "skill,status,fixes_applied" > "$RESULTS_FILE"
echo "Fix started at $(date)" > "$LOG_FILE"

fixed_count=0
skipped_count=0
error_count=0

# Process each skill
while IFS= read -r skill_md; do
    if [ -z "$skill_md" ]; then
        continue
    fi
    
    skill_path=$(dirname "$skill_md")
    skill_name=$(basename "$skill_path")
    
    # Skip tool skills
    if [ "$skill_name" = "skill-fixer" ] || [ "$skill_name" = "skill-reviewer" ]; then
        echo -e "${YELLOW}[SKIP]${NC} $skill_name (tool skill)"
        echo "$skill_name,skipped,0" >> "$RESULTS_FILE"
        skipped_count=$((skipped_count + 1))
        continue
    fi
    
    echo -n -e "${BLUE}[FIX]${NC} $skill_name... "
    
    if bash "$FIXER_SCRIPT" "$skill_path" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}OK${NC}"
        echo "$skill_name,fixed,7" >> "$RESULTS_FILE"
        fixed_count=$((fixed_count + 1))
    else
        echo -e "${RED}ERROR${NC}"
        echo "$skill_name,error,0" >> "$RESULTS_FILE"
        error_count=$((error_count + 1))
    fi
    
done <<< "$SKILL_FILES"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Total skills:  $TOTAL"
echo -e "Fixed:         ${GREEN}$fixed_count${NC}"
echo -e "Skipped:       ${YELLOW}$skipped_count${NC}"
echo -e "Errors:        ${RED}$error_count${NC}"
echo ""
echo "Log file:      $LOG_FILE"
echo "Results CSV:   $RESULTS_FILE"
echo ""

# Generate report
REPORT_FILE="$SKILLS_DIR/fix-report.md"

{
    echo "# Batch Fix Report"
    echo ""
    echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Skills processed:** $TOTAL"
    echo ""
    echo "## Summary"
    echo ""
    echo "| Status | Count |"
    echo "|--------|-------|"
    echo "| ✅ Fixed | $fixed_count |"
    echo "| ⏭️ Skipped | $skipped_count |"
    echo "| ❌ Errors | $error_count |"
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Run audit to verify:"
    echo "   \`\`\`bash"
    echo "   ./skill-reviewer/scripts/audit-all-skills.sh ."
    echo "   \`\`\`"
    echo ""
    echo "2. Review changes:"
    echo "   \`\`\`bash"
    echo "   git diff"
    echo "   \`\`\`"
    echo ""
} > "$REPORT_FILE"

echo -e "${GREEN}[INFO]${NC} Report saved to: $REPORT_FILE"
echo ""
echo -e "${GREEN}[DONE]${NC} Run audit to verify improvements!"
