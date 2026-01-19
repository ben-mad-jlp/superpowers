# Parallel Execution Visualization & Workflow Improvements

## Problem / Goal

Improve the parallel agent execution workflow with:
1. Visual task execution diagram showing real-time status (waiting → executing → completed)
2. Proposed tag support for design doc updates during execution
3. Verify subagent-driven-development skill integration with executing-plans
4. Display mermaid-collab server address when spawning

## Key Decisions

### 1. Task Execution Diagram - Skill-Directed Updates

**Decision:** The orchestrating skill (executing-plans) explicitly updates the task diagram via mermaid-collab.

### 2. Proposed Tag - Use Existing Mermaid-Collab Markers

**Decision:** Claude uses existing propose markers when updating design docs during execution.

### 3. Parallel Execution - Layered Architecture

**Decision:** executing-plans spawns parallel Task agents, each using subagent-driven-development for its task.

### 4. Server Address Display on Session Creation

**Decision:** Show mermaid-collab server URL immediately when creating a collab session.

## Success Criteria

- [ ] Task execution diagram updates in real-time as agents are dispatched/complete
- [ ] Proposed changes to design doc show as cyan, user can accept/reject in UI
- [ ] Parallel task waves execute concurrently with full review loops per task
- [ ] Server URL displayed immediately on collab session creation

## Out of Scope

- Changes to mermaid-collab MCP server itself (using existing tools)
- New MCP tools (using existing propose markers, existing preview URLs)
- Changes to subagent-driven-development skill (works as-is for single task)

---

## Skeleton

### Task Dependency Graph

```yaml
tasks:
  - id: collab-server-url
    files: [skills/collab/SKILL.md]
    description: Add server URL display after session creation and on resume
    parallel: true

  - id: executing-plans-diagram
    files: [skills/executing-plans/SKILL.md]
    description: Add task execution diagram creation and update logic
    parallel: true

  - id: executing-plans-parallel
    files: [skills/executing-plans/SKILL.md]
    description: Clarify parallel dispatch with subagent-driven-development
    depends-on: [executing-plans-diagram]

  - id: executing-plans-proposed
    files: [skills/executing-plans/SKILL.md]
    description: Add proposed tag usage for drift during execution
    depends-on: [executing-plans-parallel]
```

### Skeleton Content: skills/collab/SKILL.md

**Replace section "5. Transition to Brainstorming" (lines 82-93) with:**

```markdown
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
```

**Add after step 6 in "Resume Collab Flow" section (after line 158):**

```markdown
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
```

---

### Skeleton Content: skills/executing-plans/SKILL.md

**Add new section after "Step 1.5: Pre-Flight Check" (after line 135):**

```markdown
### Step 1.6: Create Task Execution Diagram

When within a collab workflow, create a visual diagram showing all tasks and their dependencies:

**Build diagram content:**
```
graph TD
    %% Node Definitions
    <for each task: task-id(["task-id"])>

    %% Dependencies  
    <for each dependency: dep-id --> task-id>

    %% Styles (all waiting initially)
    <for each task: style task-id fill:#e0e0e0,stroke:#9e9e9e>
```

**Create the diagram:**
```
Tool: mcp__mermaid__create_diagram
Args: { "name": "task-execution", "content": <generated-content> }
```

**Display to user:**
```
Task execution diagram: <previewUrl>
```

**Style definitions for state changes:**
- `waiting`: `fill:#e0e0e0,stroke:#9e9e9e`
- `executing`: `fill:#bbdefb,stroke:#1976d2,stroke-width:3px`
- `completed`: `fill:#c8e6c9,stroke:#2e7d32`
- `failed`: `fill:#ffcdd2,stroke:#c62828`

**Update diagram on state change:**
1. Read current diagram: `mcp__mermaid__get_diagram({ "id": "task-execution" })`
2. Replace style line for the task with new style
3. Update diagram: `mcp__mermaid__update_diagram({ "id": "task-execution", "content": <updated> })`
```

---

**Modify "Parallel Dispatch Logic" section (lines 159-166) to:**

```markdown
**Parallel Dispatch Logic:**
1. From ready tasks, identify parallel-safe group:
   - Tasks explicitly marked `parallel: true`
   - OR tasks with no file overlap and no shared dependencies
2. If multiple parallel-safe tasks exist:
   - Update task diagram: set all parallel tasks to "executing"
   - **REQUIRED:** Spawn Task agents in parallel (single message, multiple tool calls)
   - Each Task agent uses `superpowers:subagent-driven-development` for its task
   - Task prompt includes: task ID, files, description, relevant pseudocode
   - Wait for all agents to complete
   - Update task diagram: completed → "completed", failed → "failed"
3. If only sequential tasks remain:
   - Execute one at a time in topological order
   - Update diagram before/after each task

**Task agent prompt template:**
```
Use superpowers:subagent-driven-development skill.

Task ID: <task-id>
Files: <task-files>
Description: <task-description>

Pseudocode from design doc:
<relevant-pseudocode>

Implement this task following the subagent-driven-development workflow:
implement → spec review → quality review
```
```

---

**Add to "Step 2.5: Per-Task Verification" section (after line 210):**

```markdown
### Proposing Design Doc Changes

When drift is detected and requires a design doc update, use the proposed tag:

**For section-level changes:**
```markdown
<!-- status: proposed: <drift-description> -->
<new-section-content>
```

**For inline changes:**
```markdown
<!-- propose-start: <drift-description> --><new-text><!-- propose-end -->
```

**Process:**
1. Read current design doc
2. Insert proposed content at appropriate location
3. Update doc: `mcp__mermaid__update_document({ "id": "design", "content": <updated> })`
4. Notify user: "Proposed change visible in design doc (cyan). Accept/reject in mermaid-collab UI."
5. Wait for user decision before proceeding

**After user decision:**
- If accepted: proposed marker removed, content remains → continue execution
- If rejected: content removed → address the drift differently or stop
```

---

## Pseudocode

(See previous section for full pseudocode details)

---

## Design Details

### Task Execution Diagram

**Node styles by state:**
- `waiting` - Gray: `fill:#e0e0e0,stroke:#9e9e9e`
- `executing` - Blue: `fill:#bbdefb,stroke:#1976d2,stroke-width:3px`
- `completed` - Green: `fill:#c8e6c9,stroke:#2e7d32`
- `failed` - Red: `fill:#ffcdd2,stroke:#c62828`