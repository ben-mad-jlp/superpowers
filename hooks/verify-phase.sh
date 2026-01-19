#!/usr/bin/env bash
# verify-phase.sh - Verification hook with drift detection
#
# Triggered before phase transitions in rough-draft to ensure
# implementation matches the design document.
#
# Usage:
#   verify-phase.sh <phase> [collab-name]
#
# Arguments:
#   phase       - The phase being transitioned FROM (interface, pseudocode, skeleton, implementation)
#   collab-name - Optional. If not provided, uses the active collab.
#
# This hook can be invoked:
#   1. Manually by user or skill
#   2. Automatically by rough-draft skill before phase transitions
#
# The hook outputs a verification report that Claude uses to:
#   - Compare current artifacts to design
#   - Show drift with pros/cons
#   - Guide user through accept/reject/review workflow

set -euo pipefail

# Determine script and plugin root directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Escape outputs for JSON using pure bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            $'\\') output+='\\' ;;
            '"') output+='\"' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *) output+="$char" ;;
        esac
    done
    printf '%s' "$output"
}

# Get current date in YYYY-MM-DD format
get_date() {
    date "+%Y-%m-%d"
}

# Get current timestamp in ISO-8601 format
get_timestamp() {
    date -u "+%Y-%m-%dT%H:%M:%SZ"
}

# Phase argument
PHASE="${1:-}"
COLLAB_NAME="${2:-}"

if [ -z "$PHASE" ]; then
    echo "Error: Phase argument required" >&2
    echo "Usage: verify-phase.sh <phase> [collab-name]" >&2
    exit 1
fi

# Validate phase
case "$PHASE" in
    interface|pseudocode|skeleton|implementation)
        ;;
    *)
        echo "Error: Invalid phase '$PHASE'" >&2
        echo "Valid phases: interface, pseudocode, skeleton, implementation" >&2
        exit 1
        ;;
esac

# If running interactively, read cwd from environment or use pwd
# If running as hook, cwd comes from JSON input
if [ -t 0 ]; then
    # Interactive mode - use current directory
    CWD="${PWD}"
else
    # Hook mode - read JSON input from stdin
    json_input=$(cat)
    CWD=$(echo "$json_input" | jq -r '.cwd // empty')
    if [ -z "$CWD" ]; then
        CWD="${PWD}"
    fi
fi

# Find active collab
COLLAB_ROOT="${CWD}/.collab"

if [ ! -d "$COLLAB_ROOT" ]; then
    echo "Error: No .collab folder found in ${CWD}" >&2
    exit 1
fi

# Find collab directory
if [ -n "$COLLAB_NAME" ]; then
    # Specific collab requested
    COLLAB_DIR="${COLLAB_ROOT}/${COLLAB_NAME}"
    if [ ! -d "$COLLAB_DIR" ]; then
        echo "Error: Collab '$COLLAB_NAME' not found" >&2
        exit 1
    fi
else
    # Find the most recently modified collab
    COLLAB_DIR=""
    for dir in "$COLLAB_ROOT"/*/; do
        if [ -d "$dir" ] && [ -f "${dir}collab-state.json" ]; then
            if [ -z "$COLLAB_DIR" ]; then
                COLLAB_DIR="$dir"
            else
                # Compare modification times
                if [ "${dir}collab-state.json" -nt "${COLLAB_DIR}collab-state.json" ]; then
                    COLLAB_DIR="$dir"
                fi
            fi
        fi
    done

    if [ -z "$COLLAB_DIR" ]; then
        echo "Error: No active collab found" >&2
        exit 1
    fi
fi

# Remove trailing slash
COLLAB_DIR="${COLLAB_DIR%/}"
COLLAB_NAME=$(basename "$COLLAB_DIR")

# Read collab state
STATE_FILE="${COLLAB_DIR}/collab-state.json"
if [ ! -f "$STATE_FILE" ]; then
    echo "Error: collab-state.json not found in ${COLLAB_DIR}" >&2
    exit 1
fi

# Find design document
DESIGN_DOC=""
if [ -f "${COLLAB_DIR}/documents/design.md" ]; then
    DESIGN_DOC="${COLLAB_DIR}/documents/design.md"
else
    for doc in "${COLLAB_DIR}/documents/"*.md; do
        if [ -f "$doc" ]; then
            DESIGN_DOC="$doc"
            break
        fi
    done
fi

if [ -z "$DESIGN_DOC" ] || [ ! -f "$DESIGN_DOC" ]; then
    echo "Error: No design document found in ${COLLAB_DIR}/documents/" >&2
    exit 1
fi

# Read design document content
DESIGN_CONTENT=$(cat "$DESIGN_DOC")

# Generate the verification report template
# This template is designed to be filled in by Claude during the verification process

REPORT_TEMPLATE="## Verification: rough-draft:${PHASE}

**Collab:** ${COLLAB_NAME}
**Design Doc:** ${DESIGN_DOC}
**Timestamp:** $(get_timestamp)

---

### Aligned [checkmark]

<!-- Claude: List items that match the design. For each aligned item, include:
- Interface/component name
- Brief description of alignment
-->

### Drift Detected [warning]

<!-- Claude: For each drift item, use this format:

**1. [Description of drift]**
   - Design: [what was specified in the design doc]
   - Code: [what was actually implemented]

   Pros:
   - [benefit of the change]
   - [another benefit if applicable]

   Cons:
   - [drawback or risk]
   - [another drawback if applicable]
-->

### Recommendation

<!-- Claude: Provide a summary recommendation:
- Which drifts should be accepted (and why)
- Which drifts should be rejected (and why)
- Overall assessment of implementation quality
-->

---

**Proceed?** \`[accept all / reject all / review each]\`"

# Create the verification context for Claude
VERIFICATION_CONTEXT="<verification-phase phase=\"${PHASE}\" collab=\"${COLLAB_NAME}\">

You are performing a verification check before transitioning from the '${PHASE}' phase.

**Your task:**
1. Read the design document below
2. Compare current artifacts/code to the design specifications
3. Identify what aligns and what has drifted
4. Generate pros/cons for each drift
5. Present the verification report to the user
6. Handle their decision (accept/reject/review)

**Design Document Content:**
\`\`\`markdown
${DESIGN_CONTENT}
\`\`\`

**Verification Checklist for '${PHASE}' phase:**
$(case "$PHASE" in
    interface)
        echo "- Are all interface/function signatures defined in the design present in the code?"
        echo "- Do the signatures match exactly (parameter types, return types)?"
        echo "- Are there any undocumented public interfaces?"
        echo "- Do interface names follow the design's naming conventions?"
        ;;
    pseudocode)
        echo "- Does the implemented logic match the pseudocode flow?"
        echo "- Are all error handling cases from the design addressed?"
        echo "- Are edge cases from the design handled?"
        echo "- Is the control flow consistent with the design?"
        ;;
    skeleton)
        echo "- Are all files from the design created?"
        echo "- Do file paths match the design specifications?"
        echo "- Are stub implementations present for all components?"
        echo "- Does the dependency graph match the design?"
        ;;
    implementation)
        echo "- Does the final implementation match the design intent?"
        echo "- Are all features from the design implemented?"
        echo "- Do tests cover the scenarios from the design?"
        echo "- Are there significant deviations from the architecture?"
        ;;
esac)

**Output Format:**
Use the following template for your verification report:

${REPORT_TEMPLATE}

**After presenting the report, handle user decisions:**

1. If user chooses 'accept all':
   - Update the design doc to reflect accepted changes
   - Append to Decision Log section (create if doesn't exist)
   - Clear any pending verification issues

2. If user chooses 'reject all':
   - Keep design doc unchanged
   - Add all drifts to pendingVerificationIssues in collab-state.json
   - User needs to fix code before transitioning

3. If user chooses 'review each':
   - Go through each drift one by one
   - For each: ask accept/reject
   - Update design doc for accepted items
   - Add rejected items to pendingVerificationIssues

**Decision Log Format (append to design doc when drift accepted):**
\`\`\`markdown
## Decision Log

### $(get_date): [Description of change]
- **Phase:** rough-draft:${PHASE}
- **Original:** [what was specified]
- **Changed to:** [what was implemented]
- **Reason:** [why accepted - from user or inferred]
\`\`\`

</verification-phase>"

# Escape the context for JSON output
CONTEXT_ESCAPED=$(escape_for_json "$VERIFICATION_CONTEXT")

# Output the hook response
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "VerifyPhase",
    "phase": "${PHASE}",
    "collab": "${COLLAB_NAME}",
    "designDoc": "${DESIGN_DOC}",
    "stateFile": "${STATE_FILE}",
    "additionalContext": "${CONTEXT_ESCAPED}"
  }
}
EOF

exit 0
