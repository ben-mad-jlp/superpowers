---
name: collab
description: Use when starting collaborative design work - creates isolated collab sessions with mermaid-collab server
---

# Collab Sessions

## Overview

Entry point for all collaborative design work. Creates and manages `.collab/` folder at project root, handles new vs resume sessions, and configures the mermaid-collab server to use the collab folder for storage.

---

## MANDATORY FIRST STEP - DO THIS IMMEDIATELY

**DO NOT** check mermaid storage config first. **DO NOT** look at existing diagrams elsewhere.

**ONLY** `.collab/<session-name>/` folders are valid collab sessions. Diagrams/documents anywhere else are NOT collab sessions.

```bash
# STEP 1: Check if .collab exists and has sessions
if [ -d ".collab" ] && [ -n "$(ls -d .collab/*/ 2>/dev/null)" ]; then
    # Has existing sessions -> Go to RESUME FLOW
    echo "Found existing collab sessions"
else
    # No .collab or empty -> Go to NEW COLLAB FLOW
    echo "No existing sessions"
fi
```

**Based on result:**
- **Existing sessions found** → Jump to "Resume Collab Flow" section
- **No sessions** → Jump to "New Collab Flow" section

---

## New Collab Flow

### 1. Check/Create `.collab/` Folder

```bash
# Check if .collab exists at project root
if [ ! -d ".collab" ]; then
    # Verify .collab is in .gitignore before creating
    git check-ignore -q .collab 2>/dev/null || echo ".collab/" >> .gitignore

    mkdir -p .collab
fi
```

### 2. Template Selection

Ask the user which template to use:

```
What type of work is this?

1. feature - New functionality
2. bugfix - Fix an issue
3. refactor - Restructure existing code
4. spike - Exploratory/research work

Which template?
```

### 3. Generate Name

Generate a memorable name using adjective-adjective-noun pattern:

```bash
# Read random words from word lists (using sort -R for macOS compatibility)
adj1=$(sort -R lib/words/adjectives.txt | head -1)
adj2=$(sort -R lib/words/adjectives.txt | head -1)
noun=$(sort -R lib/words/nouns.txt | head -1)

# Combine into name
name="${adj1}-${adj2}-${noun}"
# Example: "bright-calm-river"
```

### 4. Create Folder Structure

```bash
mkdir -p ".collab/${name}/diagrams"
mkdir -p ".collab/${name}/documents"
```

Create `metadata.json`:

```json
{
  "name": "<name>",
  "template": "<template>",
  "createdAt": "<ISO-8601-timestamp>",
  "description": ""
}
```

Create `collab-state.json`:

```json
{
  "phase": "brainstorming",
  "template": "<template>",
  "lastActivity": "<ISO-8601-timestamp>",
  "pendingVerificationIssues": []
}
```

### 5. Configure Mermaid Server Storage

Use the `mcp__mermaid__configure_storage` tool to point the server at the collab folder:

```
Use: mcp__mermaid__configure_storage
Args: { "storageDir": "/absolute/path/to/.collab/<name>" }
```

This tells the existing MCP mermaid server to use the collab folder for all diagrams and documents.

### 6. Transition to Brainstorming

Invoke the brainstorming skill with the collab context:

```
Collab session "<name>" created.
Storage configured at: .collab/<name>/
Design doc: .collab/<name>/documents/design.md

Starting brainstorming phase...
```

## Resume Collab Flow

### 1. Check for Existing Collabs

```bash
# Check if .collab exists and has any collab directories
if [ ! -d ".collab" ] || [ -z "$(ls -d .collab/*/ 2>/dev/null)" ]; then
    echo "No existing collab sessions found."
    echo "Would you like to create a new one? (y/n)"
    # If yes, transition to New Collab Flow
    # If no, exit
fi
```

### 2. List Existing Collabs

```bash
# List all directories in .collab/
ls -d .collab/*/
```

### 3. Show Status for Each

Display for each collab:
- Name
- Template type
- Current phase (from collab-state.json)
- Last activity timestamp

```
Existing collab sessions:

1. bright-calm-river (feature)
   Phase: brainstorming
   Last activity: 2025-01-18 10:30 AM

2. swift-green-meadow (bugfix)
   Phase: rough-draft/interface
   Last activity: 2025-01-17 3:45 PM
   Pending issues: 2

Which session to resume? (or 'new' for a new session)
```

### 4. User Selects One

Get user selection.

### 5. Load State

```bash
# Read collab-state.json
cat .collab/<name>/collab-state.json
```

### 6. Check for Pending Verification Issues

If `pendingVerificationIssues` is not empty, display them:

```
This session has pending verification issues:

1. Interface drift: UserService.authenticate() signature changed
2. Missing test coverage for error handling

Address these before continuing? (y/n)
```

### 7. Configure Mermaid Server Storage

Use the `mcp__mermaid__configure_storage` tool to point the server at the collab folder:

```
Use: mcp__mermaid__configure_storage
Args: { "storageDir": "/absolute/path/to/.collab/<name>" }
```

### 8. Read Design Doc into Context

```bash
# Read the design doc to restore context
cat .collab/<name>/documents/design.md
```

### 9. Continue at Current Phase

Based on `phase` in collab-state.json:
- `brainstorming` -> invoke brainstorming skill
- `rough-draft/*` -> invoke rough-draft skill at appropriate phase
- `implementation` -> invoke executing-plans skill

## Folder Structure

```
.collab/
└── <collab-name>/
    ├── diagrams/
    ├── documents/
    ├── metadata.json
    └── collab-state.json
```

## State Tracking (collab-state.json)

```json
{
  "phase": "brainstorming",
  "template": "feature",
  "lastActivity": "2025-01-18T10:30:00Z",
  "pendingVerificationIssues": []
}
```

**Phase values:**
- `brainstorming` - Initial design exploration
- `rough-draft/interface` - Defining interfaces
- `rough-draft/pseudocode` - Logic flow
- `rough-draft/skeleton` - Stub files
- `implementation` - Executing the plan

**Pending issues format:**

```json
{
  "pendingVerificationIssues": [
    {
      "type": "drift",
      "description": "UserService.authenticate() signature changed",
      "file": "src/services/user.ts",
      "detectedAt": "2025-01-18T11:00:00Z"
    }
  ]
}
```

## Integration

**Transitions to:**
- **brainstorming** - After creating new collab or resuming at brainstorming phase
- **rough-draft** - When resuming at rough-draft phase
- **executing-plans** - When resuming at implementation phase

**Called by:**
- User directly via `/collab` command
- Any workflow starting collaborative design work

## Quick Reference

| Action | Command |
|--------|---------|
| New collab | Select template, generate name, create folder, configure storage |
| Resume collab | List existing, select, load state, configure storage |
| Configure storage | `mcp__mermaid__configure_storage({ storageDir: "<abs-path>" })` |
| Get current storage | `mcp__mermaid__get_storage_config()` |

## Common Mistakes

### Checking mermaid storage config first

- **Problem:** Mermaid server may have diagrams from previous work that are NOT collab sessions. Checking storage first leads to confusion and treating random diagrams as "sessions"
- **Fix:** ALWAYS check `.collab/` folder first. Only `.collab/<name>/` folders are valid collab sessions. Ignore whatever mermaid server currently has loaded.

### Skipping .gitignore verification

- **Problem:** .collab/ contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating .collab/

### Using relative paths for storage

- **Problem:** MCP server may not resolve relative paths correctly
- **Fix:** Always use absolute paths when calling configure_storage

### Forgetting to check for empty collabs on resume

- **Problem:** Resume flow shows empty list, confusing user
- **Fix:** Check for existing collabs first, offer to create new if none

### Using `shuf` for random word selection

- **Problem:** `shuf` is GNU coreutils, not available on macOS by default
- **Fix:** Use `sort -R | head -1` which works on both Linux and macOS

## Red Flags

**Never:**
- Check mermaid storage config BEFORE checking `.collab/` folder
- Treat diagrams outside `.collab/` as collab sessions
- Create .collab/ without verifying it's ignored
- Use relative paths when configuring storage
- Assume `shuf` is available (use `sort -R | head -1`)

**Always:**
- FIRST check if `.collab/` exists with sessions (MANDATORY FIRST STEP)
- Only treat `.collab/<name>/` folders as valid sessions
- Verify .collab/ is in .gitignore before creating
- Use absolute paths for configure_storage
- Check for pending verification issues on resume
- Call configure_storage when starting or resuming a collab
