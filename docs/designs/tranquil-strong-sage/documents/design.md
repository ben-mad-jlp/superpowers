# Mermaid-Collab Server Location Cache

## Problem / Goal

When starting a collab session on a new machine, the `.mcp.json` has hardcoded absolute paths that don't exist → MCP server fails to start → collab skill doesn't work.

**Goal:** Make collab portable across machines by:
1. Treating `.mcp.json` as machine-specific (gitignored)
2. Caching server location in `.collab/settings.json`
3. Auto-detecting and configuring on first run

## Key Decisions

### 1. Location of logic
**Decision:** In the collab skill as "Step 0: Ensure server running"
**Rationale:** Single entry point, natural fit before existing mandatory first step

### 2. Config file strategy
**Decision:** Treat `.mcp.json` as machine-specific
- Add `.mcp.json` to `.gitignore`
- Keep `.mcp.json.example` in repo as template
- Store actual path in `.collab/settings.json` (gitignored)
- Collab skill creates/updates `.mcp.json` from settings on first run

**Rationale:** Clean separation between repo (portable) and local config (machine-specific)

### 3. Search strategy
**Decision:** Combination approach
1. Check common locations first (fast)
2. Search with `find`/`fd` if not found (thorough)
3. Ask user if still not found (fallback)

**Rationale:** Optimizes for common cases while handling edge cases

## Success Criteria

- [ ] `.mcp.json` gitignored, `.mcp.json.example` tracked
- [ ] First run on new machine: searches, finds, caches, generates `.mcp.json`
- [ ] Subsequent runs: MCP server just works
- [ ] If server moves: re-search and update

## Out of Scope

- Auto-cloning mermaid-collab if not found (user responsibility)
- Supporting multiple mermaid-collab installations

---

## Design Details

### Architecture

See diagram: [server-detection-flow](http://localhost:3737/diagram.html?id=server-detection-flow)

### File Structure

```
superpowers-collab/
├── .gitignore              # includes .mcp.json
├── .mcp.json               # (gitignored) machine-specific, auto-generated
├── .mcp.json.example       # template in repo
└── .collab/
    └── settings.json       # (gitignored) { "serverPath": "..." }
```

### .mcp.json.example

```json
{
  "mcpServers": {
    "mermaid": {
      "command": "bun",
      "args": ["run", "src/mcp/server.ts"],
      "cwd": "/path/to/claude-mermaid-collab"
    }
  }
}
```

### .collab/settings.json

```json
{
  "serverPath": "/Users/someone/Code/claude-mermaid-collab"
}
```

---

## Proposed Implementation

<!-- status: proposed: Step 0 pseudocode for collab skill -->

### Step 0: Ensure MCP Server Running

Add this as the new first step in `skills/collab/SKILL.md`, before the current "MANDATORY FIRST STEP":

```
STEP 0: ENSURE MCP SERVER RUNNING

0.1 Test MCP Connection:
    result = call mcp__mermaid__get_storage_config()
    if result.success:
        return  # MCP works, continue to Step 1
    
0.2 Check Cached Path:
    settings_path = ".collab/settings.json"
    if file_exists(settings_path):
        settings = read_json(settings_path)
        if settings.serverPath and dir_exists(settings.serverPath):
            if file_exists(settings.serverPath + "/src/mcp/server.ts"):
                goto GENERATE_MCP_JSON
    
0.3 Search Common Locations:
    common_paths = [
        "../claude-mermaid-collab",
        "~/Code/claude-mermaid-collab",
        "~/code/claude-mermaid-collab", 
        "~/Projects/claude-mermaid-collab",
        "~/projects/claude-mermaid-collab",
        "~/dev/claude-mermaid-collab"
    ]
    for path in common_paths:
        expanded = expand_path(path)
        if file_exists(expanded + "/src/mcp/server.ts"):
            serverPath = expanded
            goto SAVE_AND_GENERATE

0.4 Search with Find:
    result = bash("find ~ -maxdepth 4 -type d -name 'claude-mermaid-collab' 2>/dev/null | head -1")
    if result and file_exists(result + "/src/mcp/server.ts"):
        serverPath = result
        goto SAVE_AND_GENERATE

0.5 Ask User:
    display("Could not find claude-mermaid-collab. Please provide the path:")
    userPath = get_user_input()
    if file_exists(userPath + "/src/mcp/server.ts"):
        serverPath = userPath
        goto SAVE_AND_GENERATE
    else:
        error("Invalid path - src/mcp/server.ts not found")
        stop

SAVE_AND_GENERATE:
    # Ensure .collab directory exists
    mkdir_p(".collab")
    
    # Save to settings
    write_json(".collab/settings.json", { "serverPath": serverPath })

GENERATE_MCP_JSON:
    # Generate .mcp.json
    mcp_config = {
        "mcpServers": {
            "mermaid": {
                "command": "bun",
                "args": ["run", "src/mcp/server.ts"],
                "cwd": serverPath
            }
        }
    }
    write_json(".mcp.json", mcp_config)
    
    display("Created .mcp.json with server at: " + serverPath)
    display("Please restart Claude Code to load the MCP server, then run /collab again")
    stop  # User must restart
```

<!-- propose-end -->

---

## Implementation Plan

### Task Breakdown

| # | Task | Dependencies | Files |
|---|------|--------------|-------|
| 1 | Add `.mcp.json` to `.gitignore` | - | `.gitignore` |
| 2 | Create `.mcp.json.example` | - | `.mcp.json.example` |
| 3 | Add Step 0 to collab skill | - | `skills/collab/SKILL.md` |

### Execution Order

```
Wave 1: [task-1, task-2]  (parallel)
Wave 2: [task-3]
```

---

## Flows

### Flow: New Machine (First Run)

```
1. User runs /collab
2. Skill tries MCP tool call → fails (no .mcp.json or wrong path)
3. Check .collab/settings.json for serverPath
4. Not found → search for mermaid-collab
5. Found → save to .collab/settings.json
6. Generate .mcp.json with correct cwd
7. Tell user: "Created .mcp.json - please restart Claude Code to load the MCP server"
```

### Flow: Subsequent Runs

```
1. User runs /collab
2. MCP server works (Claude Code loaded .mcp.json)
3. Proceed with normal collab flow
```

### Flow: Server Moved

```
1. User runs /collab
2. MCP tool fails (path no longer valid)
3. Read .collab/settings.json → path doesn't exist
4. Re-search for mermaid-collab
5. Update settings.json and .mcp.json
6. Tell user to restart Claude Code
```

### Search Strategy

**Step 1: Check common locations (fast)**
```bash
# In order of likelihood
../claude-mermaid-collab           # sibling directory
~/Code/claude-mermaid-collab
~/code/claude-mermaid-collab
~/Projects/claude-mermaid-collab
~/projects/claude-mermaid-collab
~/dev/claude-mermaid-collab
```

Validate by checking for `src/mcp/server.ts` exists.

**Step 2: Search with find (thorough)**
```bash
# Search home directory, limit depth to avoid deep traversal
find ~ -maxdepth 4 -type d -name "claude-mermaid-collab" 2>/dev/null | head -1
```

Validate found path has `src/mcp/server.ts`.

**Step 3: Ask user (fallback)**
```
Could not find claude-mermaid-collab on your machine.

Please provide the path to your claude-mermaid-collab directory:
```

Validate user-provided path has `src/mcp/server.ts`.