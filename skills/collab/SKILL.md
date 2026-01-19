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
# Read random words from word lists
adj1=$(shuf -n 1 lib/words/adjectives.txt)
adj2=$(shuf -n 1 lib/words/adjectives.txt)
noun=$(shuf -n 1 lib/words/nouns.txt)

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
PORT=<port> STORAGE_DIR=.collab/<name> bun run src/server.ts &

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

### 1. List Existing Collabs

```bash
# List all directories in .collab/ (excluding ports.json)
ls -d .collab/*/
```

### 2. Show Status for Each

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

### 3. User Selects One

Get user selection.

### 4. Load State

```bash
# Read collab-state.json
cat .collab/<name>/collab-state.json
```

### 5. Check for Pending Verification Issues

If `pendingVerificationIssues` is not empty, display them:

```
This session has pending verification issues:

1. Interface drift: UserService.authenticate() signature changed
2. Missing test coverage for error handling

Address these before continuing? (y/n)
```

### 6. Restart Server if Needed

Check if server is running:

```bash
# Check if PID from collab-state.json is still running
if ! kill -0 <pid> 2>/dev/null; then
    # Server not running, restart it
    PORT=<port> STORAGE_DIR=.collab/<name> bun run src/server.ts &
    # Update PID in collab-state.json
fi
```

### 7. Read Design Doc into Context

```bash
# Read the design doc to restore context
cat .collab/<name>/documents/design.md
```

### 8. Continue at Current Phase

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
PORT=<port> STORAGE_DIR=.collab/<name> bun run src/server.ts &
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
| Spawn server | `PORT=<n> STORAGE_DIR=.collab/<name> bun run src/server.ts` |
| Stop server | `kill <pid>` (SIGTERM) |
