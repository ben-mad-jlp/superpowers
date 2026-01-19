#!/usr/bin/env bash
# collab-cleanup.sh - Cleanup hook for completed collabs
#
# Triggered after final implementation verification to:
# 1. Copy artifacts to docs/designs/<collab-name>/
# 2. Optionally delete the collab folder and stop the server
#
# Usage:
#   collab-cleanup.sh [collab-name]
#
# Arguments:
#   collab-name - Optional. If not provided, uses the active collab.
#
# This hook is a manual hook invoked after implementation is complete.
# It prompts the user for decisions about artifact preservation and cleanup.

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

# Get current timestamp in ISO-8601 format
get_timestamp() {
    date -u "+%Y-%m-%dT%H:%M:%SZ"
}

# Collab name argument
COLLAB_NAME="${1:-}"

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

# Find collab root
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

# Get server PID from state file
SERVER_PID=$(jq -r '.serverPid // empty' "$STATE_FILE")

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

# Check for decision log
DECISION_LOG=""
if [ -f "${COLLAB_DIR}/documents/decision-log.md" ]; then
    DECISION_LOG="${COLLAB_DIR}/documents/decision-log.md"
fi

# Check for dependency graph
DEPENDENCY_GRAPH=""
if [ -f "${COLLAB_DIR}/documents/dependency-graph.md" ]; then
    DEPENDENCY_GRAPH="${COLLAB_DIR}/documents/dependency-graph.md"
fi

# Check for diagrams
DIAGRAMS_DIR="${COLLAB_DIR}/diagrams"
HAS_DIAGRAMS="false"
DIAGRAM_COUNT=0
if [ -d "$DIAGRAMS_DIR" ]; then
    DIAGRAM_COUNT=$(find "$DIAGRAMS_DIR" -name "*.mmd" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIAGRAM_COUNT" -gt 0 ]; then
        HAS_DIAGRAMS="true"
    fi
fi

# Build artifact list
ARTIFACTS=""
if [ -n "$DESIGN_DOC" ]; then
    ARTIFACTS="${ARTIFACTS}design.md, "
fi
if [ "$HAS_DIAGRAMS" = "true" ]; then
    ARTIFACTS="${ARTIFACTS}diagrams/ (${DIAGRAM_COUNT} files), "
fi
if [ -n "$DECISION_LOG" ]; then
    ARTIFACTS="${ARTIFACTS}decision-log.md, "
fi
if [ -n "$DEPENDENCY_GRAPH" ]; then
    ARTIFACTS="${ARTIFACTS}dependency-graph.md, "
fi
# Remove trailing comma and space
ARTIFACTS="${ARTIFACTS%, }"

# Target directory for artifacts
TARGET_DIR="${CWD}/docs/designs/${COLLAB_NAME}"

# Build the cleanup context for Claude
CLEANUP_CONTEXT="<collab-cleanup collab=\"${COLLAB_NAME}\">

You are performing the cleanup step after a completed implementation.

**Collab:** ${COLLAB_NAME}
**Collab Directory:** ${COLLAB_DIR}
**Timestamp:** $(get_timestamp)

---

## Available Artifacts

The following artifacts are available for copying:
- ${ARTIFACTS:-No artifacts found}

**Target Location:** \`${TARGET_DIR}/\`

---

## Step 1: Copy Artifacts

**Ask the user:** \"Would you like to copy the design artifacts to \`docs/designs/${COLLAB_NAME}/\`?\"

If user agrees to copy:

1. Create the target directory structure:
   \`\`\`bash
   mkdir -p \"${TARGET_DIR}\"
   mkdir -p \"${TARGET_DIR}/diagrams\"
   \`\`\`

2. Copy files:
$([ -n "$DESIGN_DOC" ] && echo "   - Copy \`${DESIGN_DOC}\` to \`${TARGET_DIR}/design.md\`")
$([ "$HAS_DIAGRAMS" = "true" ] && echo "   - Copy all \`.mmd\` files from \`${DIAGRAMS_DIR}/\` to \`${TARGET_DIR}/diagrams/\`")
$([ -n "$DECISION_LOG" ] && echo "   - Copy \`${DECISION_LOG}\` to \`${TARGET_DIR}/decision-log.md\`")
$([ -n "$DEPENDENCY_GRAPH" ] && echo "   - Copy \`${DEPENDENCY_GRAPH}\` to \`${TARGET_DIR}/dependency-graph.md\`")

3. Create a git commit with the message:
   \`\`\`
   docs: add design artifacts for ${COLLAB_NAME}

   - Design document with architecture decisions
   - Mermaid diagrams (flow, wireframes, etc.)
   - Task dependency graph

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   \`\`\`

---

## Step 2: Delete Collab Folder

**After copying (or if user declines to copy), ask the user:** \"Would you like to delete the collab folder \`.collab/${COLLAB_NAME}/\`?\"

If user agrees to delete:

1. Stop the mermaid-collab server (if running):
$([ -n "$SERVER_PID" ] && echo "   - Server PID: ${SERVER_PID}" || echo "   - No server PID found in state file")
   \`\`\`bash
   # Check if process is running and kill it
   if [ -n \"${SERVER_PID}\" ] && kill -0 ${SERVER_PID} 2>/dev/null; then
       kill ${SERVER_PID}
   fi
   \`\`\`

2. Remove port from ports.json:
   - Read \`${COLLAB_ROOT}/ports.json\`
   - Remove the entry for this collab
   - Write updated ports.json

3. Delete the collab folder:
   \`\`\`bash
   rm -rf \"${COLLAB_DIR}\"
   \`\`\`

---

## Paths Reference

| Artifact | Source | Destination |
|----------|--------|-------------|
| Design Doc | \`${DESIGN_DOC:-N/A}\` | \`${TARGET_DIR}/design.md\` |
| Diagrams | \`${DIAGRAMS_DIR}/\` | \`${TARGET_DIR}/diagrams/\` |
| Decision Log | \`${DECISION_LOG:-N/A}\` | \`${TARGET_DIR}/decision-log.md\` |
| Dependency Graph | \`${DEPENDENCY_GRAPH:-N/A}\` | \`${TARGET_DIR}/dependency-graph.md\` |
| State File | \`${STATE_FILE}\` | (not copied) |
| Ports File | \`${COLLAB_ROOT}/ports.json\` | (not copied) |

**Server PID:** ${SERVER_PID:-Not running}

</collab-cleanup>"

# Escape the context for JSON output
CONTEXT_ESCAPED=$(escape_for_json "$CLEANUP_CONTEXT")

# Output the hook response
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "CollabCleanup",
    "collab": "${COLLAB_NAME}",
    "collabDir": "${COLLAB_DIR}",
    "targetDir": "${TARGET_DIR}",
    "serverPid": "${SERVER_PID:-}",
    "hasDesignDoc": $([ -n "$DESIGN_DOC" ] && echo "true" || echo "false"),
    "hasDiagrams": ${HAS_DIAGRAMS},
    "diagramCount": ${DIAGRAM_COUNT},
    "hasDecisionLog": $([ -n "$DECISION_LOG" ] && echo "true" || echo "false"),
    "hasDependencyGraph": $([ -n "$DEPENDENCY_GRAPH" ] && echo "true" || echo "false"),
    "additionalContext": "${CONTEXT_ESCAPED}"
  }
}
EOF

exit 0
