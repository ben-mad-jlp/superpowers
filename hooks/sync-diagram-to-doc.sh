#!/usr/bin/env bash
# PostToolUse hook: Sync diagram to design document
# Triggered after mcp__mermaid__create_diagram or mcp__mermaid__update_diagram
#
# This hook keeps embedded diagrams in the design document in sync with
# the source diagrams managed by mermaid-collab.

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read JSON input from stdin
json_input=$(cat)

# Extract tool name and response using jq (available in Git Bash on Windows)
tool_name=$(echo "$json_input" | jq -r '.tool_name // empty')
tool_response=$(echo "$json_input" | jq -r '.tool_response // empty')
cwd=$(echo "$json_input" | jq -r '.cwd // empty')

# Only process mermaid diagram tools
case "$tool_name" in
    mcp__mermaid__create_diagram|mcp__mermaid__update_diagram)
        ;;
    *)
        # Not a diagram tool, exit silently
        exit 0
        ;;
esac

# Extract diagram ID and content from tool response
# create_diagram response: {"id": "...", "previewUrl": "..."}
# The actual content must be fetched from the diagram source
diagram_id=$(echo "$tool_response" | jq -r '.id // empty')

if [ -z "$diagram_id" ]; then
    # No diagram ID, nothing to sync
    exit 0
fi

# Find active collab folder in current working directory
# Look for .collab/<collab-name>/ structure
collab_root="${cwd}/.collab"

if [ ! -d "$collab_root" ]; then
    # No collab folder, nothing to sync
    exit 0
fi

# Find the active collab by looking for the diagram in any collab's diagrams folder
active_collab=""
design_doc=""

for collab_dir in "$collab_root"/*/; do
    if [ -d "$collab_dir" ]; then
        # Check if this collab has diagrams directory with our diagram
        diagram_file="${collab_dir}diagrams/${diagram_id}.mmd"
        if [ -f "$diagram_file" ]; then
            active_collab="$collab_dir"
            # Find the design document (typically design.md or the main .md in documents/)
            if [ -f "${collab_dir}documents/design.md" ]; then
                design_doc="${collab_dir}documents/design.md"
            else
                # Find any .md file in documents
                for doc in "${collab_dir}documents/"*.md; do
                    if [ -f "$doc" ]; then
                        design_doc="$doc"
                        break
                    fi
                done
            fi
            break
        fi
    fi
done

if [ -z "$active_collab" ] || [ -z "$design_doc" ]; then
    # Could not find active collab or design doc
    exit 0
fi

# Read the diagram content
diagram_file="${active_collab}diagrams/${diagram_id}.mmd"
if [ ! -f "$diagram_file" ]; then
    exit 0
fi

diagram_content=$(cat "$diagram_file")

# Read current design doc
if [ ! -f "$design_doc" ]; then
    exit 0
fi

design_content=$(cat "$design_doc")

# Check if diagram already exists in the doc (look for <!-- diagram:ID --> markers)
marker_start="<!-- diagram:${diagram_id} -->"
marker_end="<!-- /diagram:${diagram_id} -->"

if echo "$design_content" | grep -q "$marker_start"; then
    # Diagram exists, replace it
    # Use awk to replace content between markers
    new_content=$(echo "$design_content" | awk -v start="$marker_start" -v end="$marker_end" -v content="$diagram_content" '
        BEGIN { in_block = 0 }
        $0 == start {
            print
            print "```mermaid"
            print content
            print "```"
            in_block = 1
            next
        }
        $0 == end {
            print
            in_block = 0
            next
        }
        !in_block { print }
    ')
else
    # New diagram, append a section
    # Create a human-readable title from the diagram ID
    diagram_title=$(echo "$diagram_id" | sed 's/-/ /g' | sed 's/\b\w/\u&/g')

    new_section="

## Diagram: ${diagram_title}

${marker_start}
\`\`\`mermaid
${diagram_content}
\`\`\`
${marker_end}"

    new_content="${design_content}${new_section}"
fi

# Write updated design doc
echo "$new_content" > "$design_doc"

# Output success context for Claude
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Diagram '${diagram_id}' has been synced to the design document at ${design_doc}"
  }
}
EOF

exit 0
