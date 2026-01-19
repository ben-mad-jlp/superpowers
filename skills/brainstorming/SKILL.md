---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

**When invoked from collab skill:** The design doc location is `.collab/<name>/documents/design.md`. Create it immediately and update continuously.

## Live Design Doc

When brainstorming within a collab session, maintain a persistent design document that survives context compaction.

**Create immediately when brainstorming starts:**

```bash
# Create design doc with initial structure
cat > .collab/<name>/documents/design.md << 'EOF'
# <Topic> Design

## Problem / Goal

*To be filled during brainstorming*

## Key Decisions

*Decisions will be documented as they are made*

## Success Criteria

*To be defined*

## Out of Scope

*To be defined*

---

## Design Details

*Sections added as exploration progresses*
EOF
```

**Update continuously as topics emerge:**
- After each significant decision, update the design doc immediately
- Add new sections as topics are explored
- Capture rationale for decisions, not just the decision itself
- All diagrams are embedded inline automatically (sync-diagram-to-doc hook handles this)

**Document structure evolves through brainstorming:**
1. Initial skeleton created at start
2. Problem/Goal filled in during understanding phase
3. Key decisions added as approaches are explored
4. Design details expanded during presentation phase
5. Success criteria and out of scope refined at end

## Template-Specific Focus

Different templates require different emphasis during brainstorming:

| Template | Primary Focus | Key Questions | Artifacts |
|----------|---------------|---------------|-----------|
| **feature** | Full design, complete solution | What problem does it solve? Who uses it? How does it integrate? | Wireframes, architecture diagram, data flow |
| **bugfix** | Minimal intervention | How to reproduce? What's the root cause? Smallest fix? | Reproduction steps, root cause analysis, fix verification |
| **refactor** | Safe transformation | Current state? Desired state? Migration path? | Before/after diagrams, migration plan, rollback strategy |
| **spike** | Time-boxed exploration | What are we trying to learn? When do we stop? | Clear success criteria, time limit, decision points |

**Feature template:** Explore fully - wireframes for every screen, architecture for every component, data flow for every interaction. No ambiguity allowed.

**Bugfix template:** Focus on understanding before fixing. Reproduction steps first, root cause analysis second, minimal fix third. Resist scope creep.

**Refactor template:** Document current state thoroughly before proposing changes. Define clear before/after. Plan migration path with rollback.

**Spike template:** Set strict boundaries. Define what success looks like. Set time limit. Document decision points for go/no-go.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Visualizing with Mermaid Collab:**

When brainstorming involves visual artifacts, use the mermaid-collab server.

*GUI/UI Design (ALWAYS use wireframes):*
- When discussing screens, layouts, or user interfaces → create wireframe diagrams
- Use `create_diagram(name, content)` with wireframe syntax
- Iterate on wireframes as the design evolves
- Preview with `preview_diagram(id)` so user can see in browser

*Architecture & Flow Design:*
- System architecture → flowchart diagrams
- Data flow → sequence or flowchart diagrams
- State machines → SMACH YAML or state diagrams
- Component relationships → class or flowchart diagrams

*Design Documents:*
- Use `create_document(name, content)` for design specs
- Iterate on documents with `update_document(id, content)`
- Link related diagrams in the document

*Workflow:*
1. During "Exploring approaches" phase, create diagram(s) to visualize options
2. During "Presenting the design" phase, update diagrams to match validated sections
3. When writing final design doc, embed diagram references

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design completeness checklist (before moving to implementation):**
- [ ] Every screen/UI has a wireframe in mermaid-collab
- [ ] Every data flow/architecture decision has a diagram
- [ ] No ambiguous language ("should handle errors appropriately" → specify HOW)
- [ ] No TBD or "figure out later" items
- [ ] Success criteria are measurable, not subjective

## Completeness Gate (Before Rough-Draft)

Before transitioning to rough-draft phase, verify the design doc contains all required sections:

**Required sections:**
- [ ] **Problem/Goal** - Clear statement of what we're solving and why
- [ ] **Key Decisions** - At least one documented decision with rationale
- [ ] **At least one diagram** - Visual representation of architecture, flow, or UI
- [ ] **Success Criteria** - Measurable, testable criteria (not "works well")
- [ ] **Out of Scope** - Explicit boundaries on what this work does NOT include

**Gate check process:**

```bash
# Read design doc
cat .collab/<name>/documents/design.md

# Verify each required section exists and has content
# If any section is missing or empty, do NOT proceed
```

**If gate fails:**
- Identify which sections are incomplete
- Return to relevant brainstorming phase to fill gaps
- Do NOT proceed to rough-draft until all sections pass

**If gate passes:**
- Update collab state using MCP tool:
  ```
  Tool: mcp__mermaid__update_collab_session_state
  Args: { "sessionName": "<name>", "phase": "rough-draft/interface" }
  ```
- Invoke rough-draft skill

## Context Preservation

Design docs survive context compaction. When resuming or after long conversations:

**Re-read design doc to restore context:**

```bash
# Always re-read before continuing work
cat .collab/<name>/documents/design.md

# Also read any diagrams
ls .collab/<name>/diagrams/
```

**After re-reading:**
- Summarize current state briefly
- Identify where brainstorming left off
- Continue from that point

**Update design doc with any new context** discovered during the conversation.

## After the Design

**Within collab workflow (called from collab skill):**
- Design doc already exists at `.collab/<name>/documents/design.md`
- Run completeness gate (see above)
- If gate passes, transition to **rough-draft** skill
- Update collab-state.json phase to `rough-draft/interface`

**Standalone (not in collab workflow):**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing without collab):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Live documentation** - Update design doc as you go, not at the end

## Integration

**Called by:**
- **collab** skill - When starting new collab or resuming at brainstorming phase
- User directly via `/brainstorming` command for standalone design work

**Transitions to:**
- **rough-draft** skill - After completeness gate passes (within collab workflow)
- **writing-plans** skill - For standalone design work leading to implementation

**Collab workflow context:**
When invoked from collab skill, the following are already set up:
- `.collab/<name>/` folder exists
- `collab-state.json` tracks phase as `brainstorming`
- Mermaid-collab server running on assigned port
- Design doc location: `.collab/<name>/documents/design.md`

**State updates:**
- On completion: Use `mcp__mermaid__update_collab_session_state({ sessionName, phase: "rough-draft/interface" })`
- The MCP tool automatically updates `lastActivity` timestamp
