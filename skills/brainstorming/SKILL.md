---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

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

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing):**
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
