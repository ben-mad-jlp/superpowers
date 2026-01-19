# Allow using-git-worktrees Skill in Collab Workflow

## Problem / Goal

Enable users to optionally work in a git worktree during the implementation phase of the collab workflow, providing isolation for larger features while keeping the overhead optional for smaller changes.

## Key Decisions

### 1. Worktree Prompt Timing - After Rough-Draft
### 2. Prompt Location - rough-draft Skill  
### 3. Branch Naming - Session Name Default

## Success Criteria

- [ ] User prompted about worktree at rough-draft → executing-plans transition
- [ ] Option 1 (current directory) works as before
- [ ] Option 2 creates worktree, runs setup, then continues to executing-plans
- [ ] Branch name defaults to session name, allows override
- [ ] Worktree location tracked in collab-state.json for cleanup

## Out of Scope

- Changes to using-git-worktrees skill itself (use as-is)
- Changes to finishing-a-development-branch (already handles worktree cleanup)

---

## Skeleton

### Task Dependency Graph

```yaml
tasks:
  - id: rough-draft-worktree-option
    files: [skills/rough-draft/SKILL.md]
    description: Add worktree option to implementation handoff prompt
    parallel: true
```

### Skeleton Content: skills/rough-draft/SKILL.md

**Replace "Step 2: Confirm transition to executing-plans" (lines 524-542) with:**

```markdown
**Step 2: Confirm transition to executing-plans**

Show summary and ask for confirmation:

```
Rough-draft complete. Ready for implementation:
- [N] files created with stubs
- [N] tasks in dependency graph
- [N] parallel-safe tasks identified

Ready to move to executing-plans?
  1. Yes, in current directory
  2. Yes, in a new git worktree (recommended for larger features)
  3. No, I need to revise something
```

**Option 1 - Current directory:**

Update collab state and invoke executing-plans:
```
Tool: mcp__mermaid__update_collab_session_state
Args: { "sessionName": "<name>", "phase": "implementation" }
```

Then invoke executing-plans skill.

**Option 2 - Git worktree:**

1. Get session name from collab state
2. Prompt for branch name:
   ```
   Creating worktree with branch: feature/<session-name>
   (Press enter to accept, or type a different branch name)
   ```
3. Announce: "I'm using the using-git-worktrees skill to set up an isolated workspace."
4. Invoke using-git-worktrees skill with the branch name
5. On success:
   - Update collab-state.json to add `worktreePath` field:
     ```json
     {
       "worktreePath": "<absolute-path-to-worktree>"
     }
     ```
   - Update collab state: `phase: "implementation"`
   - Invoke executing-plans skill (now in worktree context)
6. On failure:
   - Report error
   - Ask: "Continue in current directory instead? (y/n)"
   - If yes: fall back to Option 1 flow
   - If no: stay at rough-draft phase

**Option 3 - Revise:**

Ask what needs revision and return to appropriate phase.
```

---

## Design Details

### Flow Diagram

See: http://localhost:3737/diagram.html?id=worktree-flow