# Brainstorming Skill Improvement Design

## Problem / Goal

The brainstorming skill was skipped/shortcut despite being loaded. The agent jumped from "understanding the idea" directly to implementation without:
- Asking clarifying questions one at a time
- Presenting design in sections for validation
- Passing the completeness gate
- Transitioning to rough-draft phase

**Observed failure modes:**
1. User saw an Edit tool call as the first sign something was wrong
2. Agent presented multiple items at once instead of discussing one at a time
3. Agent asked for batch selection ("which of these 5?") instead of clarifying each item
4. Agent never asked "what else?" - treated exploration as exhaustive
5. Agent skipped rough-draft phase entirely (brainstorming → implementation instead of brainstorming → rough-draft → implementation)

## Key Decisions

1. **Use explicit phase state machine (Approach B)** - Define phases with required transitions rather than relying on prose instructions. If this doesn't work, we'll escalate to MCP enforcement (Approach C).

2. **Apply state machine to both skills** - Both brainstorming and rough-draft will have explicit state machines.

3. **Brainstorming phases validated** ✓
   - EXPLORING → CLARIFYING → DESIGNING → VALIDATING → TRANSITION

4. **Phase transition rules validated** ✓
   - Each transition requires explicit announcement
   - CLARIFYING exit requires "what else?" confirmation
   - DESIGNING presents sections one at a time with validation

5. **Rough-draft drift detection validated** ✓
   - Compare artifact to design doc after each phase
   - Present drift with pros/cons
   - AI recommends, user decides: keep change or discard
   - If keep: AI recommends significance, user decides if back to brainstorming
   - If discard: AI recommends restart point, user decides

6. **[PROPOSED] tag for validation** ✓
   - Before asking user validation, write content to design doc with `[PROPOSED]` tag
   - User reviews in collab viewer
   - After acceptance, remove tag
   - **Applies to both brainstorming (DESIGNING) and rough-draft (INTERFACE, PSEUDOCODE, SKELETON)**

## Success Criteria

- [ ] Brainstorming skill has explicit state machine with 5 phases
- [ ] Each phase transition requires announcement
- [ ] CLARIFYING phase requires "what else?" before exit
- [ ] DESIGNING phase presents sections one at a time with validation
- [ ] Rough-draft skill has explicit drift detection flow
- [ ] Drift detection presents pros/cons and asks user to decide
- [ ] Both skills have visual flowchart diagrams embedded
- [ ] Design sections written with [PROPOSED] tag before validation (both skills)

**How we'll know it worked:**
- Next time we use these skills, phase transitions are visible
- Agent cannot jump from exploring to implementation
- Drift is caught and presented for decision

## Out of Scope

- MCP enforcement (Approach C) - only if B fails
- Changes to other skills (executing-plans, etc.)
- Automated testing of the skill changes
- Changes to collab skill itself

---

## Design Details

### Brainstorming State Machine ✓

See diagram: brainstorming-state-machine

| Phase | Purpose | Exit Criteria |
|-------|---------|---------------|
| **EXPLORING** | Gather context - read files, check git, understand scope | Context gathered, initial understanding formed |
| **CLARIFYING** | Discuss each item one at a time, ask "what else?" | Every item discussed individually, user confirmed nothing else |
| **DESIGNING** | Present approach in 200-300 word sections, get validation | Each section validated by user |
| **VALIDATING** | Run completeness gate checklist | All required sections present, no TBDs |

### Phase Transition Rules ✓

**EXPLORING → CLARIFYING**
- Must have read relevant files/context
- Must have formed initial list of items/topics
- Announce: "I've gathered context. Now let me discuss each item with you one at a time."

**CLARIFYING → DESIGNING**
- Each item discussed individually (not batched)
- Asked "Is there anything else?" and got confirmation
- Announce: "All items clarified. Now let me present the design approach."

**DESIGNING → VALIDATING**
- Each design section (200-300 words) presented separately
- User validated each section before moving to next
- Can backtrack to CLARIFYING if user raises new questions
- Announce: "Design sections complete. Let me run the completeness gate."

**VALIDATING → TRANSITION**
- Completeness checklist passed
- Announce: "Completeness gate passed. Transitioning to rough-draft skill."

### Proposed Tag Workflow ✓

**Applies to:** Brainstorming DESIGNING phase AND Rough-draft INTERFACE/PSEUDOCODE/SKELETON phases

For each section/artifact:
1. Write to design doc with `[PROPOSED]` marker
2. Tell user: "I've added a proposed section to the design doc. Please review."
3. Ask: "Does this look right?"
4. If accepted: remove `[PROPOSED]` marker
5. If rejected: discuss, revise, repeat

### Rough-Draft State Machine ✓

See diagram: rough-draft-state-machine

| Phase | Purpose | Exit Criteria |
|-------|---------|---------------|
| **INTERFACE** | Define file paths, signatures, types | All public interfaces have signatures, no `any` types |
| **PSEUDOCODE** | Define logic flow, error handling, edge cases | Every function has pseudocode, errors explicit |
| **SKELETON** | Generate stub files, build dependency graph | Files created, dependency graph complete |

### Rough-Draft Drift Detection ✓

See diagram: rough-draft-drift-detection

After each phase, compare artifact to design doc:
1. If drift detected → present with pros/cons
2. User decides: keep or discard
3. If keep → AI recommends significance → user decides if back to brainstorming
4. If discard → AI recommends restart point → user decides where to restart

---

## Rough-Draft Artifacts

### Interface Phase ✓

**Files to Modify:**

| File | Purpose |
|------|---------|
| `skills/brainstorming/SKILL.md` | Add state machine with 5 phases |
| `skills/rough-draft/SKILL.md` | Add drift detection flow |

### Pseudocode Phase ✓

**brainstorming/SKILL.md changes:**
- Add Phase State Machine section with DOT flowchart
- Add phase table with exit criteria
- Add transition rules with announcements
- Add proposed tag workflow
- Restructure "The Process" around explicit phases
- Add CLARIFYING rules (one item at a time, "what else?")
- Add Red Flags section for phase violations

**rough-draft/SKILL.md changes:**
- Add Proposed Tag Workflow section
- Add Drift Detection section with DOT flowchart
- Add drift presentation format
- Add keep/discard decision flows

### Skeleton Phase ✓

**brainstorming/SKILL.md - Phase State Machine section:**

```markdown
## Phase State Machine

Brainstorming follows a strict 5-phase state machine. You cannot skip phases.

[DOT flowchart]

| Phase | Purpose | Exit Criteria |
|-------|---------|---------------|
| **EXPLORING** | Gather context | Context gathered, initial understanding formed |
| **CLARIFYING** | Discuss each item one at a time | Every item discussed, "what else?" confirmed |
| **DESIGNING** | Present approach in sections | Each section validated by user |
| **VALIDATING** | Run completeness gate | All required sections present |

### Phase Transitions
[Transition rules with announcements]

### Proposed Tag Workflow
[Write with [PROPOSED], review, accept/reject]

### Red Flags - Phase Violations
[List of violations and corrections]
```

**rough-draft/SKILL.md - Proposed Tag & Drift Detection sections:**

```markdown
## Proposed Tag Workflow

For each phase (INTERFACE, PSEUDOCODE, SKELETON):
1. Write artifact to design doc with `[PROPOSED]` marker
2. Tell user to review
3. If accepted: remove marker, proceed to drift check
4. If rejected: discuss, revise, repeat

## Drift Detection

After each phase is accepted, check for drift.

[DOT flowchart]

### When to Check
After INTERFACE/PSEUDOCODE/SKELETON accepted

### How to Detect
Compare artifact against original design

### Presenting Drift
[Format with pros/cons/recommendation]

### If User Keeps Change
[Update design, assess significance, ask about brainstorming return]

### If User Discards Change
[Revert, recommend restart point, execute restart]
```