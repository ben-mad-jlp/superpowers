# Collab Workflow Enforcement Bugfix

## Problem / Goal

The collab workflow is not enforcing its intended process. Skills are being skipped, users aren't being asked for approval at transitions. The goal is to make the collab workflow reliable and user-controlled.

## Key Decisions

1. Collab cleanup is a standalone skill
2. Summary + confirmation for skill transitions
3. Granular approval for design doc sections
4. Elements-of-style for design writing
5. Track task completion in collab-state.json

## Success Criteria

- [ ] State machine prevents skipping phases
- [ ] User prompted before each phase transition
- [ ] User prompted to accept/reject/edit design doc changes
- [ ] Cleanup skill available for session management
- [ ] Elements-of-style integrated in brainstorming and rough-draft phases
- [ ] Task completion tracked in collab-state.json

## Out of Scope

- MCP base directory bug (being fixed separately)
- Proposed section highlighting in mermaid-collab server UI

---

## Interface Definition

| File | Type | Action |
|------|------|--------|
| `skills/collab-cleanup/SKILL.md` | New skill | Create |
| `commands/collab-cleanup.md` | New command | Create |
| `skills/brainstorming/SKILL.md` | Existing skill | Modify |
| `skills/rough-draft/SKILL.md` | Existing skill | Modify |
| `skills/executing-plans/SKILL.md` | Existing skill | Modify |
| `skills/finishing-a-development-branch/SKILL.md` | Existing skill | Modify |

---

## Pseudocode

### 1. collab-cleanup/SKILL.md
- Step 1: Identify current session via `get_storage_config()`
- Step 2: Show session summary
- Step 3: Ask user choice (archive/delete/keep)
- Step 4: Execute choice
- Step 5: Confirm

### 2. commands/collab-cleanup.md
- Single line invoking the skill

### 3. brainstorming/SKILL.md
- Add "Writing Quality" section
- Add section approval after each design section
- Add transition confirmation before rough-draft

### 4. rough-draft/SKILL.md
- Add "Writing Quality" section
- Add transition confirmation before executing-plans

### 5. executing-plans/SKILL.md
- Initialize task tracking in collab-state.json
- Update completedTasks/pendingTasks after each task
- Add transition confirmation before finishing-a-development-branch

### 6. finishing-a-development-branch/SKILL.md
- Add collab-cleanup prompt at end

---

## Skeleton

### Generated Files

- [x] `skills/collab-cleanup/SKILL.md` - Created with stub content
- [x] `commands/collab-cleanup.md` - Created with full content

### Task Dependency Graph

```yaml
tasks:
  - id: create-collab-cleanup-skill
    files: [skills/collab-cleanup/SKILL.md]
    description: Create new collab-cleanup skill
    parallel: true

  - id: create-collab-cleanup-command
    files: [commands/collab-cleanup.md]
    description: Create command to invoke skill
    parallel: true

  - id: modify-brainstorming
    files: [skills/brainstorming/SKILL.md]
    description: Add section approval, transition prompt, elements-of-style
    parallel: true

  - id: modify-rough-draft
    files: [skills/rough-draft/SKILL.md]
    description: Add section approval, transition prompt, elements-of-style
    parallel: true

  - id: modify-executing-plans
    files: [skills/executing-plans/SKILL.md]
    description: Add task tracking and transition prompt
    parallel: true

  - id: modify-finishing-branch
    files: [skills/finishing-a-development-branch/SKILL.md]
    description: Add collab-cleanup prompt at end
    parallel: true
```

All 6 tasks are parallel-safe (no dependencies between them).

### Dependency Visualization

See diagram: http://localhost:3737/diagram.html?id=task-dependency

---

## collab-state.json Schema

```json
{
  "phase": "implementation",
  "template": "bugfix",
  "lastActivity": "2026-01-19T17:00:00Z",
  "completedTasks": [],
  "pendingTasks": [],
  "pendingVerificationIssues": []
}
```
