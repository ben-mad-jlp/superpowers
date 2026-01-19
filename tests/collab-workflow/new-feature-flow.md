# Test: New Feature Flow

Complete end-to-end test of the collab workflow for a new feature.

## Test Objective

Validate that a user can:
1. Create a new collab with the feature template
2. Complete brainstorming with a live design doc
3. Progress through all rough-draft phases with verification
4. Complete implementation
5. Copy artifacts to `docs/designs/`
6. Clean up the collab folder

## Prerequisites

- Clean state (no `.collab/` folder) or known state
- Mermaid-collab server code available at `~/Code/claude-mermaid-collab`
- `jq` and `bun` installed

---

## Step 1: Start New Collab

**Action:**
```
/collab
```

**Expected behavior:**
1. Claude announces: "I'm using the collab skill to set up a collaborative design session."
2. If `.collab/` doesn't exist, Claude creates it and adds `.collab/` to `.gitignore`
3. Claude asks: "What type of work is this?" with options:
   - feature
   - bugfix
   - refactor
   - spike

**Your action:**
- Select "feature"

**Expected outcome:**
- [ ] `.collab/` folder created at project root
- [ ] `.collab/` is in `.gitignore`
- [ ] Claude generates a name (adjective-adjective-noun pattern, e.g., "bright-calm-river")

---

## Step 2: Verify Folder Structure

**Action:**
```bash
ls -la .collab/
ls -la .collab/<generated-name>/
```

**Expected outcome:**
- [ ] `.collab/ports.json` exists with port assignment
- [ ] `.collab/<name>/diagrams/` directory exists
- [ ] `.collab/<name>/documents/` directory exists
- [ ] `.collab/<name>/metadata.json` exists with template and createdAt
- [ ] `.collab/<name>/collab-state.json` exists with:
  - `"phase": "brainstorming"`
  - `"template": "feature"`
  - `serverPid` and `serverPort` populated

---

## Step 3: Verify Server Running

**Action:**
```bash
# Check ports.json
cat .collab/ports.json

# Verify server is running
curl http://localhost:3737/health 2>/dev/null || echo "Try the port from ports.json"
```

**Expected outcome:**
- [ ] `ports.json` shows `{"3737": "<collab-name>"}` (or next available port)
- [ ] Server responds to health check
- [ ] Server PID matches what's in `collab-state.json`

---

## Step 4: Brainstorming Phase

**Action:**
Claude should automatically transition to brainstorming. Engage in design discussion.

**Sample interaction:**
```
User: I want to add a user authentication feature with email/password login.
```

**Expected behavior:**
1. Claude asks clarifying questions one at a time
2. Claude creates design doc at `.collab/<name>/documents/design.md`
3. Claude creates diagrams using mermaid-collab MCP tools
4. Design doc is updated continuously as decisions are made

**Verify:**
```bash
# Check design doc exists and has content
cat .collab/<name>/documents/design.md
```

**Expected outcome:**
- [ ] Design doc created with initial skeleton
- [ ] Problem/Goal section filled in
- [ ] Key Decisions populated as topics are explored
- [ ] At least one diagram created (check `diagrams/` folder)

---

## Step 5: Completeness Gate

**Action:**
Continue brainstorming until Claude indicates readiness to move to rough-draft.

**Expected behavior:**
Claude should verify the design doc has:
1. Problem/Goal section
2. Key Decisions (at least one)
3. At least one diagram
4. Success Criteria
5. Out of Scope

**If gate fails:**
- Claude identifies missing sections
- Returns to brainstorming to fill gaps

**Expected outcome:**
- [ ] Claude explicitly runs completeness check
- [ ] All required sections present before proceeding
- [ ] `collab-state.json` phase updated to `rough-draft/interface`

---

## Step 6: Rough-Draft Interface Phase

**Action:**
Claude should announce transition to rough-draft and begin interface phase.

**Expected behavior:**
1. Claude adds "Interface Definition" section to design doc
2. Lists all file paths to create/modify
3. Defines function signatures with types
4. Documents component interactions

**Verify:**
```bash
cat .collab/<name>/documents/design.md | grep -A 50 "Interface Definition"
```

**Expected outcome:**
- [ ] Interface Definition section added to design doc
- [ ] File paths listed
- [ ] Function signatures with parameter and return types
- [ ] No `any` types used

---

## Step 7: Interface Verification Gate

**Action:**
Claude runs `verify-phase.sh interface <collab-name>` before proceeding.

**Expected behavior:**
1. Verification report generated with Aligned/Drift sections
2. If drift detected, shows pros/cons
3. User prompted: `[accept all / reject all / review each]`

**Your action:**
- Accept all (assuming no drift in this initial phase)

**Expected outcome:**
- [ ] Verification report presented
- [ ] Phase transitions to `rough-draft/pseudocode`
- [ ] `collab-state.json` updated

---

## Step 8: Rough-Draft Pseudocode Phase

**Expected behavior:**
1. Claude adds "Pseudocode" section to design doc
2. Logic flow for each function
3. Error handling documented
4. Edge cases identified

**Verify:**
```bash
cat .collab/<name>/documents/design.md | grep -A 100 "Pseudocode"
```

**Expected outcome:**
- [ ] Pseudocode section added
- [ ] Every function from Interface has pseudocode
- [ ] Error handling explicit
- [ ] Edge cases documented

---

## Step 9: Pseudocode Verification Gate

**Action:**
Claude runs verification before skeleton phase.

**Expected outcome:**
- [ ] Verification passes or drift handled
- [ ] Phase transitions to `rough-draft/skeleton`

---

## Step 10: Rough-Draft Skeleton Phase

**Expected behavior:**
1. Claude creates actual stub files with types and TODOs
2. Generates task dependency graph in YAML format
3. Creates Mermaid visualization of dependencies
4. Adds "Skeleton" section to design doc

**Verify:**
```bash
# Check stub files created
ls -la src/auth/  # or wherever files should be

# Check dependency graph in design doc
cat .collab/<name>/documents/design.md | grep -A 30 "Task Dependency Graph"
```

**Expected outcome:**
- [ ] Stub files created with function signatures
- [ ] TODO comments match pseudocode
- [ ] Task dependency graph in design doc
- [ ] Mermaid diagram of dependencies

---

## Step 11: Skeleton Verification Gate

**Expected outcome:**
- [ ] All files from Interface are created
- [ ] Dependency graph has no cycles
- [ ] Phase transitions to `implementation`

---

## Step 12: Implementation Phase

**Expected behavior:**
1. Claude hands off to executing-plans skill
2. Tasks executed in dependency order
3. Parallel-safe tasks dispatched in parallel
4. Verification after each task

**Verify:**
```bash
# Check implementation progress
cat .collab/<name>/collab-state.json
```

**Expected outcome:**
- [ ] All TODOs resolved
- [ ] Tests pass (if applicable)
- [ ] Final verification passes

---

## Step 13: Cleanup - Copy Artifacts

**Action:**
After implementation complete, Claude should trigger cleanup hook.

**Expected behavior:**
Claude asks: "Would you like to copy the design artifacts to `docs/designs/<collab-name>/`?"

**Your action:**
- Say "yes"

**Verify:**
```bash
ls -la docs/designs/<collab-name>/
```

**Expected outcome:**
- [ ] `docs/designs/<collab-name>/design.md` exists
- [ ] `docs/designs/<collab-name>/diagrams/` copied with `.mmd` files
- [ ] Git commit created with message: "docs: add design artifacts for <collab-name>"

---

## Step 14: Cleanup - Delete Collab Folder

**Action:**
Claude asks: "Would you like to delete the collab folder `.collab/<collab-name>/`?"

**Your action:**
- Say "yes"

**Verify:**
```bash
# Check collab folder deleted
ls .collab/

# Check ports.json updated
cat .collab/ports.json

# Check server stopped
ps aux | grep mermaid
```

**Expected outcome:**
- [ ] Collab folder deleted
- [ ] Port released from `ports.json`
- [ ] Server process stopped

---

## Final Validation

After completing all steps:

- [ ] No orphaned processes
- [ ] `.collab/` folder either empty or contains only `ports.json`
- [ ] Design artifacts preserved in `docs/designs/`
- [ ] Git history shows design doc commit

## Notes

Record any issues encountered:

```
Issue:
Resolution:
```
