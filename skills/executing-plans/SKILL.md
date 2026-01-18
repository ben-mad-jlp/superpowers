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
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
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
