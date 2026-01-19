# Superpowers Collab

Superpowers Collab extends the Superpowers workflow with collaborative design features powered by a live mermaid diagram server. Create wireframes, architecture diagrams, and design documents with real-time preview while brainstorming with your coding agent.

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do.

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. **With the mermaid-collab server, you can see wireframes and diagrams in real-time as the design evolves.**

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY.

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.

## Prerequisites

### Mermaid-Collab Server

This plugin requires the [claude-mermaid-collab](https://github.com/ben-mad-jlp/claude-mermaid-collab) server for diagram and wireframe features.

**Install and start the server:**
```bash
git clone https://github.com/ben-mad-jlp/claude-mermaid-collab.git
cd claude-mermaid-collab
bun install

# Start the server (runs in background)
bun run bin/mermaid-collab.ts start
```

The server runs at `http://localhost:3737` and serves all your collab sessions. Start it once and it stays running - you don't need to restart it for each project.

**Tip:** Add an alias for convenience:
```bash
alias mermaid-collab="bun run /path/to/claude-mermaid-collab/bin/mermaid-collab.ts"
```

Then just use `mermaid-collab start`, `mermaid-collab stop`, `mermaid-collab status`.

## Installation

**Note:** Installation differs by platform. Claude Code has a built-in plugin system. Codex and OpenCode require manual setup.

### Claude Code (via Plugin Marketplace)

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add ben-mad-jlp/superpowers-collab-dev
```

Then install the plugin from this marketplace:

```bash
/plugin install superpowers-collab@superpowers-collab-dev
```

### Verify Installation

Check that skills appear:

```bash
/help
```

```
# Should see skills like:
# /superpowers-collab:brainstorming - Interactive design refinement
# /superpowers-collab:collab - Design-to-implementation pipeline
# /superpowers-collab:writing-plans - Create implementation plan
```

## The Basic Workflow

**Start with brainstorming** (automatic) or use `/collab` for full design-to-implementation tracking with state persistence.

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks. Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## Collab Workflow

For complex features that need structured design-to-implementation flow, use the **collab workflow**. Start with `/collab` to create an isolated design session.

```
/collab → brainstorming → rough-draft → implementation → cleanup
```

### How It Works

1. **Start a collab** - Run `/collab`, pick a template (feature, bugfix, refactor, spike), get an auto-generated session name
2. **Brainstorm** - Create a live design document with goals, decisions, diagrams, and success criteria
3. **Rough-draft** - Progress through 4 phases: interfaces → pseudocode → skeleton → implementation handoff
4. **Verification gates** - At each phase transition, compare artifacts against design and catch drift early
5. **Execute** - Tasks run respecting dependency graph (parallel when safe, sequential when required)
6. **Cleanup** - Artifacts archived to `docs/designs/<name>/`, collab folder removed

### Key Features

- **Live diagrams** - Create flowcharts, wireframes, and architecture diagrams with real-time browser preview
- **Context persistence** - State survives across conversations in `.collab/<name>/`
- **Design drift detection** - Automatic comparison catches deviations before they compound
- **Task execution visualization** - Watch tasks progress from waiting → executing → completed in a live diagram
- **MCP auto-detection** - Automatically finds and configures the mermaid-collab server on first run
- **Multi-collab support** - Run multiple design sessions simultaneously
- **Templates** - Pre-configured workflows for features, bugfixes, refactors, and spikes

### Quick Start

```
You: /collab
Agent: What type of work? [feature/bugfix/refactor/spike]
You: feature
Agent: Created collab "bright-calm-river". Starting brainstorming...
```

Resume anytime with `/collab` and select the existing session.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**
- **collab** - Structured design-to-implementation pipeline with state persistence and live diagrams
- **brainstorming** - Socratic design refinement with mermaid diagram creation
- **mermaid-collab** - Create and iterate on flowcharts, wireframes, and architecture diagrams
- **rough-draft** - 4-phase refinement: interfaces → pseudocode → skeleton → handoff
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Contributing

Skills live directly in this repository. To contribute:

1. Fork the repository
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. Submit a PR

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Skills update automatically when you update the plugin:

```bash
/plugin update superpowers-collab
```

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: https://github.com/ben-mad-jlp/superpowers/issues
- **Mermaid-Collab Server**: https://github.com/ben-mad-jlp/claude-mermaid-collab
