# Test: Resume Flow

Test state persistence and resume functionality at various phases.

## Test Objective

Validate that:
1. Collab state persists correctly in `collab-state.json`
2. Resume lists all existing collabs with status
3. State is correctly restored on resume
4. Pending verification issues are shown on resume
5. Server restarts automatically if not running

## Prerequisites

- At least one existing collab (run part of new-feature-flow.md first)
- Or create a fresh collab and stop mid-process

---

## Scenario A: Resume Mid-Brainstorming

### Setup

**Step 1: Create a new collab**
```
/collab
```
- Select "feature" template
- Start brainstorming but DO NOT complete it
- Verify design doc has partial content

**Step 2: Simulate context loss**
- Start a new conversation (or imagine context was compacted)
- The collab state should persist in `.collab/<name>/`

### Test

**Step 3: Resume the collab**
```
/collab
```

**Expected behavior:**
1. Claude detects existing collab(s)
2. Shows list with format:
   ```
   Existing collab sessions:

   1. <collab-name> (feature)
      Phase: brainstorming
      Last activity: <timestamp>

   Which session to resume? (or 'new' for a new session)
   ```

**Your action:**
- Select the existing collab

**Expected outcome:**
- [ ] Collab list displayed with correct phase
- [ ] Last activity timestamp shown
- [ ] Server restarted if not running

**Step 4: Verify state restored**

**Expected behavior:**
1. Claude reads `collab-state.json` to get current phase
2. Claude reads design doc to restore context
3. Claude summarizes current state
4. Brainstorming continues from where it left off

**Verify:**
```bash
# Check state file
cat .collab/<name>/collab-state.json

# Verify phase is still brainstorming
```

**Expected outcome:**
- [ ] Phase is `brainstorming`
- [ ] Design doc content preserved
- [ ] Claude references previous work from design doc
- [ ] Can continue brainstorming naturally

---

## Scenario B: Resume Mid-Rough-Draft with Pending Issues

### Setup

**Step 1: Get to rough-draft phase**
- Complete brainstorming (pass completeness gate)
- Start interface phase
- Introduce intentional drift (e.g., add an extra parameter not in design)

**Step 2: Run verification and reject**
- When verification detects drift, select "reject all"
- This adds issues to `pendingVerificationIssues`

**Step 3: Simulate context loss**
- Start a new conversation

### Test

**Step 4: Resume the collab**
```
/collab
```

**Expected behavior:**
1. Claude lists existing collabs
2. Shows "Pending issues: N" for collabs with issues:
   ```
   Existing collab sessions:

   1. <collab-name> (feature)
      Phase: rough-draft/interface
      Last activity: <timestamp>
      Pending issues: 2

   Which session to resume?
   ```

**Your action:**
- Select the collab with pending issues

**Expected outcome:**
- [ ] Pending issue count shown in list
- [ ] After selection, issues are displayed prominently

**Step 5: Verify pending issues shown**

**Expected behavior:**
Claude displays:
```
This session has pending verification issues:

1. <issue description>
2. <issue description>

Address these before continuing? (y/n)
```

**Verify:**
```bash
cat .collab/<name>/collab-state.json | jq '.pendingVerificationIssues'
```

**Expected outcome:**
- [ ] All pending issues displayed
- [ ] User asked whether to address them
- [ ] Cannot proceed to next phase until issues resolved

---

## Scenario C: Resume at Skeleton Phase

### Setup

**Step 1: Get to skeleton phase**
- Complete brainstorming
- Complete interface phase
- Complete pseudocode phase
- Start skeleton phase (files created)

**Step 2: Simulate context loss**

### Test

**Step 3: Resume the collab**
```
/collab
```

**Expected behavior:**
1. Phase shown as `rough-draft/skeleton`
2. After resume, Claude reads:
   - `collab-state.json` for phase
   - Design doc for context
   - Checks for created skeleton files

**Expected outcome:**
- [ ] Phase correctly identified as `rough-draft/skeleton`
- [ ] Claude aware of already-created files
- [ ] Continues skeleton work without recreating existing files

---

## Scenario D: Multiple Collabs

### Setup

**Step 1: Create first collab**
```
/collab
```
- Select "feature" template
- Start brainstorming, leave in progress

**Step 2: Create second collab**
```
/collab
```
- When prompted, select "new"
- Select "bugfix" template
- Start brainstorming, leave in progress

### Test

**Step 3: Check ports.json**
```bash
cat .collab/ports.json
```

**Expected outcome:**
- [ ] Two port assignments (e.g., 3737 and 3738)
- [ ] Each mapped to correct collab name

**Step 4: Resume and select**
```
/collab
```

**Expected behavior:**
```
Existing collab sessions:

1. <first-name> (feature)
   Phase: brainstorming
   Last activity: <timestamp>

2. <second-name> (bugfix)
   Phase: brainstorming
   Last activity: <timestamp>

Which session to resume? (or 'new' for a new session)
```

**Expected outcome:**
- [ ] Both collabs listed
- [ ] Correct templates shown
- [ ] Can select either one
- [ ] Correct server port used for selected collab

---

## Scenario E: Server Not Running on Resume

### Setup

**Step 1: Create a collab and note the PID**
```bash
cat .collab/<name>/collab-state.json | jq '.serverPid'
```

**Step 2: Kill the server**
```bash
kill <pid>
```

**Step 3: Verify server stopped**
```bash
kill -0 <pid> 2>/dev/null && echo "Running" || echo "Stopped"
```

### Test

**Step 4: Resume the collab**
```
/collab
```

**Expected behavior:**
1. Claude detects server not running
2. Automatically restarts server on the same port
3. Updates `serverPid` in `collab-state.json`

**Verify:**
```bash
# Check new PID
cat .collab/<name>/collab-state.json | jq '.serverPid'

# Verify server running
curl http://localhost:<port>/health
```

**Expected outcome:**
- [ ] Server automatically restarted
- [ ] Same port used
- [ ] New PID stored in state file
- [ ] Collab continues normally

---

## Scenario F: Corrupted State Recovery

### Setup

**Step 1: Create a collab and corrupt the state file**
```bash
# Backup original
cp .collab/<name>/collab-state.json .collab/<name>/collab-state.json.bak

# Corrupt it
echo '{"invalid": json}' > .collab/<name>/collab-state.json
```

### Test

**Step 2: Try to resume**
```
/collab
```

**Expected behavior:**
According to design doc error handling:
- If `collab-state.json` corrupted: Infer phase from doc, ask user to confirm

**Expected outcome:**
- [ ] Claude detects corruption
- [ ] Attempts to infer phase from design doc content
- [ ] Asks user to confirm inferred phase
- [ ] Recovers gracefully

**Cleanup:**
```bash
# Restore backup
mv .collab/<name>/collab-state.json.bak .collab/<name>/collab-state.json
```

---

## Final Validation

After completing all scenarios:

- [ ] Resume correctly restores state at any phase
- [ ] Pending issues properly persisted and displayed
- [ ] Multiple collabs can coexist
- [ ] Server auto-restarts when needed
- [ ] Recovery from corrupted state works

## Notes

Record any issues encountered:

```
Issue:
Resolution:
```
