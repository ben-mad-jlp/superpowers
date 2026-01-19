---
name: collab
description: Use when starting collaborative design work - creates isolated collab sessions with mermaid-collab server
---

# Collab Sessions

## Overview

Entry point for all collaborative design work. Creates and manages `.collab/` folder at project root, handles new vs resume sessions, spawns mermaid-collab servers (one per collab), and manages ports and state.

**Announce at start:** "I'm using the collab skill to set up a collaborative design session."

## New Collab Flow

### 1. Check/Create `.collab/` Folder

```bash
# Check if .collab exists at project root
if [ ! -d ".collab" ]; then
    # Verify .collab is in .gitignore before creating
    git check-ignore -q .collab 2>/dev/null || echo ".collab/" >> .gitignore

    mkdir -p .collab
    echo '{}' > .collab/ports.json
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
  "pendingVerificationIssues": [],
  "serverPid": null,
  "serverPort": null
}
```

### 5. Assign Port

Read `ports.json` and find next available port starting from 3737:

```bash
# Read current port assignments
# Find first available port starting from 3737
# Update ports.json with new assignment
```

`ports.json` format:

```json
{
  "3737": "happy-blue-mountain",
  "3738": "swift-green-river"
}
```

### 6. Spawn Mermaid-Collab Server

```bash
# Start server with STORAGE_DIR pointing to collab folder
# STORAGE_DIR must be absolute path since we cd to server directory
COLLAB_DIR="$(pwd)/.collab/<name>"
cd ~/Code/claude-mermaid-collab && PORT=<port> STORAGE_DIR="$COLLAB_DIR" bun run src/server.ts &

# Store PID in collab-state.json
```

Update `collab-state.json` with `serverPid` and `serverPort`.

### 7. Transition to Brainstorming

Invoke the brainstorming skill with the collab context:

```
Collab session "<name>" created.
Server running on port <port>.
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
# List all directories in .collab/ (excluding ports.json)
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

### 7. Restart Server if Needed

Check if server is running:

```bash
# Check if PID from collab-state.json is still running
if ! kill -0 <pid> 2>/dev/null; then
    # Server not running, restart it
    # STORAGE_DIR must be absolute path since we cd to server directory
    COLLAB_DIR="$(pwd)/.collab/<name>"
    cd ~/Code/claude-mermaid-collab && PORT=<port> STORAGE_DIR="$COLLAB_DIR" bun run src/server.ts &
    # Update PID in collab-state.json
fi
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

## Port Management

### Port Assignment

```bash
# Read ports.json
ports=$(cat .collab/ports.json)

# Find next available port starting from 3737
port=3737
while [ -n "$(echo "$ports" | jq -r ".\"$port\" // empty")" ]; do
    port=$((port + 1))
done

# Assign port to collab
ports=$(echo "$ports" | jq ". + {\"$port\": \"$name\"}")
echo "$ports" > .collab/ports.json
```

### Port Release

On cleanup or collab deletion:

```bash
# Remove port assignment
ports=$(cat .collab/ports.json | jq "del(.\"$port\")")
echo "$ports" > .collab/ports.json
```

## Folder Structure

```
.collab/
├── ports.json
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
  "pendingVerificationIssues": [],
  "serverPid": null,
  "serverPort": 3737
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

## Server Lifecycle Management

### Spawn Server

```bash
# Start server in background
# STORAGE_DIR must be absolute path since we cd to server directory
COLLAB_DIR="$(pwd)/.collab/<name>"
cd ~/Code/claude-mermaid-collab && PORT=<port> STORAGE_DIR="$COLLAB_DIR" bun run src/server.ts &
pid=$!

# Update state
jq ".serverPid = $pid | .serverPort = $port" .collab/<name>/collab-state.json > tmp.json
mv tmp.json .collab/<name>/collab-state.json
```

### Check Server Running

```bash
# Check if process exists
if kill -0 <pid> 2>/dev/null; then
    echo "Server running"
else
    echo "Server not running"
fi
```

### Stop Server

```bash
# Send SIGTERM for graceful shutdown
kill <pid>

# Update state
jq ".serverPid = null" .collab/<name>/collab-state.json > tmp.json
mv tmp.json .collab/<name>/collab-state.json
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
| New collab | Select template, generate name, create folder, spawn server |
| Resume collab | List existing, select, load state, restart server if needed |
| Assign port | Find first available from 3737, update ports.json |
| Release port | Remove from ports.json on cleanup |
| Spawn server | `cd ~/Code/claude-mermaid-collab && PORT=<n> STORAGE_DIR=<abs-path> bun run src/server.ts` |
| Stop server | `kill <pid>` (SIGTERM) |

## Common Mistakes

### Skipping .gitignore verification

- **Problem:** .collab/ contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating .collab/

### Using relative paths for STORAGE_DIR

- **Problem:** Server spawns from different directory, relative path breaks
- **Fix:** Always compute absolute path before cd'ing to server directory

### Forgetting to check for empty collabs on resume

- **Problem:** Resume flow shows empty list, confusing user
- **Fix:** Check for existing collabs first, offer to create new if none

### Not releasing ports on cleanup

- **Problem:** Port assignments accumulate in ports.json, waste port space
- **Fix:** Always remove port from ports.json when deleting collab

### Using `shuf` for random word selection

- **Problem:** `shuf` is GNU coreutils, not available on macOS by default
- **Fix:** Use `sort -R | head -1` which works on both Linux and macOS

## Red Flags

**Never:**
- Create .collab/ without verifying it's ignored
- Use relative paths for STORAGE_DIR when cd'ing to server directory
- Spawn server without recording PID in collab-state.json
- Delete collab without releasing its port assignment
- Assume `shuf` is available (use `sort -R | head -1`)

**Always:**
- Verify .collab/ is in .gitignore before creating
- Use absolute paths for STORAGE_DIR
- Track server PID and port in collab-state.json
- Release port when cleaning up collab
- Check for pending verification issues on resume
