---
name: collab
description: Use when starting collaborative design work - creates isolated collab sessions with mermaid-collab server
---

# Collab Sessions

## Overview

Entry point for all collaborative design work. Creates and manages `.collab/` folder at project root, handles new vs resume sessions, and configures the mermaid-collab server to use the collab folder for storage.

---

## MANDATORY FIRST STEP - DO THIS IMMEDIATELY

Use the `mcp__mermaid__list_collab_sessions` tool to check for existing sessions:

```
Tool: mcp__mermaid__list_collab_sessions
Args: {}
```

This returns:
- `sessions`: Array of existing sessions with name, template, phase, lastActivity, pendingIssueCount, path
- `baseDir`: The directory being searched (current working directory)

**Based on result:**
- **`sessions` array is NOT empty** → Jump to "Resume Collab Flow" section
- **`sessions` array is empty** → Jump to "New Collab Flow" section

---

## New Collab Flow

### 1. Ensure .gitignore

Before creating a session, verify `.collab/` is in .gitignore:

```bash
git check-ignore -q .collab 2>/dev/null || echo ".collab/" >> .gitignore
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

### 3. Create Session

Use the `mcp__mermaid__create_collab_session` tool:

```
Tool: mcp__mermaid__create_collab_session
Args: { "template": "<selected-template>" }
```

This automatically:
- Creates `.collab/` folder if it doesn't exist
- Generates a memorable name (adjective-adjective-noun)
- Creates the folder structure: `diagrams/`, `documents/`, `metadata.json`, `collab-state.json`
- Returns `{ name, path, template, phase }`

### 4. Configure Mermaid Server Storage

Use the `mcp__mermaid__configure_storage` tool to point the server at the collab folder:

```
Tool: mcp__mermaid__configure_storage
Args: { "storageDir": "<path-from-create-response>" }
```

### 5. Display Server URL and Transition

After configuring storage, create the design doc and display the server URL:

**Create initial design doc:**
```
Tool: mcp__mermaid__create_document
Args: { "name": "design", "content": "# Design\n\n## Problem / Goal\n\n*To be filled during brainstorming*\n\n## Key Decisions\n\n*Decisions will be documented as they are made*\n" }
```

**Get preview URL:**
```
Tool: mcp__mermaid__preview_document
Args: { "id": "design" }
```

**Display to user:**
```
Session created: <name>
Server: http://localhost:<port>
Design doc: http://localhost:<port>/document.html?id=design

Starting brainstorming phase...
```

Invoke the brainstorming skill.

---

## Resume Collab Flow

### 1. Display Available Sessions

The `list_collab_sessions` response already contains all session info. Display it:

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

### 2. User Selects One

Get user selection. If 'new', go to New Collab Flow.

### 3. Get Session State

Use the `mcp__mermaid__get_collab_session_state` tool for full state details:

```
Tool: mcp__mermaid__get_collab_session_state
Args: { "sessionName": "<selected-session-name>" }
```

Returns: `{ name, path, phase, template, lastActivity, pendingVerificationIssues }`

### 4. Check for Pending Verification Issues

If `pendingVerificationIssues` is not empty, display them:

```
This session has pending verification issues:

1. Interface drift: UserService.authenticate() signature changed
2. Missing test coverage for error handling

Address these before continuing? (y/n)
```

### 5. Configure Mermaid Server Storage

```
Tool: mcp__mermaid__configure_storage
Args: { "storageDir": "<path-from-state-response>" }
```

### 6. Read Design Doc into Context

```bash
cat .collab/<name>/documents/design.md
```

Or use the Read tool to read the design document.

### 6.5. Display Server URL

Get the server URL and display it:

```
Tool: mcp__mermaid__preview_document
Args: { "id": "design" }
```

**Display to user:**
```
Resuming session: <name>
Server: http://localhost:<port>
Design doc: http://localhost:<port>/document.html?id=design
Phase: <current-phase>
```

### 7. Continue at Current Phase

Based on `phase` in the state:
- `brainstorming` → invoke brainstorming skill
- `rough-draft/*` → invoke rough-draft skill at appropriate phase
- `implementation` → invoke executing-plans skill

---

## Updating Session State

When transitioning phases or recording issues, use:

```
Tool: mcp__mermaid__update_collab_session_state
Args: {
  "sessionName": "<name>",
  "phase": "rough-draft/interface",  // optional
  "pendingVerificationIssues": [...]  // optional
}
```

This automatically updates `lastActivity`.

---

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

| Action | MCP Tool |
|--------|----------|
| List sessions | `mcp__mermaid__list_collab_sessions()` |
| Create session | `mcp__mermaid__create_collab_session({ template })` |
| Get session state | `mcp__mermaid__get_collab_session_state({ sessionName })` |
| Update session state | `mcp__mermaid__update_collab_session_state({ sessionName, phase?, pendingVerificationIssues? })` |
| Configure storage | `mcp__mermaid__configure_storage({ storageDir })` |

## Common Mistakes

### Checking mermaid storage config first

- **Problem:** Mermaid server may have diagrams from previous work that are NOT collab sessions
- **Fix:** ALWAYS use `list_collab_sessions` first. Only `.collab/<name>/` folders are valid sessions.

### Skipping .gitignore verification

- **Problem:** .collab/ contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before the first session creation

### Using relative paths for storage

- **Problem:** MCP server may not resolve relative paths correctly
- **Fix:** Use the `path` returned from `create_collab_session` or `get_collab_session_state`

## Red Flags

**Never:**
- Check mermaid storage config BEFORE using `list_collab_sessions`
- Treat diagrams outside `.collab/` as collab sessions
- Create .collab/ without verifying it's ignored
- Manually create session folders (use `create_collab_session`)

**Always:**
- FIRST call `list_collab_sessions` (MANDATORY FIRST STEP)
- Only treat `.collab/<name>/` folders as valid sessions
- Use MCP tools for session management
- Use absolute paths from tool responses for configure_storage
- Check for pending verification issues on resume
