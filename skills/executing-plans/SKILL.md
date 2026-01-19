---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 1.1: Parse Task Dependency Graph (Collab Workflow)

When called from `rough-draft` within a collab workflow, the plan includes a task dependency graph. Parse and prepare for intelligent execution.

**Graph Format (YAML in design doc):**
```yaml
tasks:
  - id: auth-types
    files: [src/auth/types.ts]
    description: Core auth type definitions
    parallel: true

  - id: auth-service
    files: [src/auth/service.ts]
    description: Authentication service implementation
    depends-on: [auth-types]

  - id: auth-middleware
    files: [src/middleware/auth.ts]
    description: Express middleware for auth
    depends-on: [auth-service]
```

**Parsing Steps:**
1. Extract YAML block from design doc (look for `## Task Dependency Graph`)
2. Parse task list with: `id`, `files`, `description`, `parallel`, `depends-on`
3. Build adjacency list for dependency relationships
4. Validate: check for cycles (topological sort must succeed)
5. If cycle detected: STOP and report error to user

**Build Execution Order:**
1. Topological sort on dependency graph
2. Group tasks by "wave" (tasks with all dependencies satisfied)
3. Within each wave, identify parallel-safe tasks (those with `parallel: true` or independent file sets)

**Execution State Tracking:**
```
completed: []
in_progress: []
pending: [all tasks initially]
```

### Anti-Drift Rules

**NO INTERPRETATION:**
- Implement EXACTLY what the plan says, even if you think there's a better way
- If the plan says "create function foo(x) that returns x+1" — do that, not "a more flexible version"
- If something seems wrong or suboptimal, STOP and ask — do not "fix" it silently
- Your job is execution, not design improvement

**NO SHORTCUTS:**
- Complete every step in order, even if you "know" the outcome
- Run every test command, even if you're "sure" it will pass
- Write every file listed, even if you think some are "unnecessary"
- If a step feels redundant, do it anyway — the plan author had a reason

**DESIGN VERIFICATION:**
- Before each task: re-read the relevant design doc section
- If mermaid-collab diagrams are referenced, open and verify against them
- After each task: diff your implementation against the spec — EXACT match required
- Any deviation = undo and redo, or STOP and ask

**When in doubt:** Ask, don't improvise.

### Design Freeze

Once execution begins, the design is FROZEN.

**No changes during implementation:**
- No "small tweaks" to requirements
- No "I realized we need X" additions
- No "let's just add this while we're here"
- No scope creep, no matter how reasonable it sounds

**If something needs to change:**
1. STOP execution immediately
2. Document what needs to change and why
3. Go back to design doc — update it formally
4. Update the plan to reflect changes
5. THEN resume execution

**Why this matters:**
- Mid-implementation changes cause drift
- "Quick additions" compound into chaos
- The plan is a contract — honor it

### Step 1.5: Pre-Flight Check

Before executing ANY tasks, verify:
- [ ] Design doc exists and is complete
- [ ] All referenced mermaid-collab diagrams exist and are accessible
- [ ] No ambiguous requirements in the plan
- [ ] Every task has explicit file paths and pseudo code

**If anything is missing:** STOP. Go back to brainstorming/writing-plans. Do not proceed with incomplete specs.

### Step 2: Execute Batch
**Default: First 3 tasks** (or use dependency graph for collab workflow)

#### Standard Execution (No Dependency Graph)

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

#### Dependency-Aware Execution (Collab Workflow)

When a task dependency graph is present, use intelligent parallel dispatch:

**Find Ready Tasks:**
```
ready_tasks = tasks where:
  - status is "pending"
  - all depends-on tasks are in "completed"
```

**Parallel Dispatch Logic:**
1. From ready tasks, identify parallel-safe group:
   - Tasks explicitly marked `parallel: true`
   - OR tasks with no file overlap and no shared dependencies
2. If multiple parallel-safe tasks exist:
   - **REQUIRED:** Use `superpowers:subagent-driven-development` to dispatch them simultaneously
   - Each subagent handles one task independently
   - Track completion status for each
3. If only sequential tasks remain:
   - Execute one at a time in topological order

**Task Completion Handling:**
When a task completes:
1. Move task from `in_progress` to `completed`
2. Check what tasks are now unblocked (their `depends-on` all satisfied)
3. Add newly unblocked tasks to the ready queue
4. Repeat until all tasks done

**Example Execution Flow:**
```
Wave 1: [auth-types, utils] (parallel: true) → dispatch together
  ↓ both complete
Wave 2: [auth-service] (depends-on: auth-types) → dispatch
  ↓ complete
Wave 3: [auth-middleware] (depends-on: auth-service) → dispatch
```

### Step 2.5: Per-Task Verification (Collab Workflow)

When within a collab workflow, run verification after each task completes:

**Verification Steps:**
1. After task completion, trigger `verify-phase` hook (if available)
2. Compare task output against design doc specification
3. Check for drift:
   - Are implemented interfaces matching design?
   - Any undocumented additions?
   - Missing components?

**On Verification Success:**
- Mark task as verified
- Unlock dependent tasks
- Proceed to next ready tasks

**On Verification Failure:**
- Keep task as `in_progress` (not completed)
- Show drift report with pros/cons
- Ask user: accept drift, reject and fix, or review each
- If drift accepted: update design doc, then unlock dependents
- If drift rejected: fix implementation before proceeding

**Unlocking Dependents:**
```
for each task T where T.depends-on includes completed_task:
  if all(T.depends-on) are completed:
    move T from pending to ready
```

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output (including any drift decisions)
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess

## Integration with Collab Workflow

This skill can be invoked in two contexts:

### Standalone (Traditional)
- Called directly by user with a plan file
- No dependency graph
- Standard batch execution (3 tasks at a time)
- Uses `writing-plans` output format

### Within Collab Workflow
- Called by `rough-draft` skill after skeleton phase completes
- Receives task dependency graph from design doc
- Uses dependency-aware parallel execution
- Per-task verification via `verify-phase` hook
- On completion, triggers `collab-cleanup` hook

**Collab Workflow Chain:**
```
collab → brainstorming → rough-draft → executing-plans → finishing-a-development-branch
                                            ↑
                                     (you are here)
```

**When called from rough-draft:**
1. Design doc is already complete with task dependency graph
2. Skeleton files already exist with TODOs
3. Your job: implement TODOs respecting dependency order
4. Parallel dispatch independent tasks via `subagent-driven-development`
5. Verify each task against design before unlocking dependents
