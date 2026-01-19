# Collab Workflow Integration Tests

Manual test scripts for validating the collab workflow end-to-end.

## Overview

These tests validate the complete collab workflow pipeline:

```
/collab -> brainstorming -> rough-draft -> implementation -> cleanup
```

## Test Scenarios

| File | Description |
|------|-------------|
| [new-feature-flow.md](./new-feature-flow.md) | Complete workflow from new collab to cleanup |
| [resume-flow.md](./resume-flow.md) | Resume functionality at various phases |
| [verification-drift.md](./verification-drift.md) | Drift detection, accept/reject workflows |

## Prerequisites

Before running tests:

1. **Mermaid-collab server available**
   ```bash
   # Verify server can start
   ls ~/Code/claude-mermaid-collab/src/server.ts
   ```

2. **Dependencies installed**
   ```bash
   # Check for jq (required by hooks)
   which jq

   # Check for bun (required for mermaid-collab)
   which bun
   ```

3. **Word lists present**
   ```bash
   # Verify word lists for name generation
   ls lib/words/adjectives.txt lib/words/nouns.txt
   ```

4. **Clean state** (optional but recommended)
   ```bash
   # Remove any existing test collabs
   rm -rf .collab/
   ```

## Running Tests

These are manual tests. Follow the step-by-step instructions in each file:

1. Start with `new-feature-flow.md` to validate the happy path
2. Run `resume-flow.md` to validate state persistence
3. Run `verification-drift.md` to validate drift detection

## Success Criteria

Tests validate the following criteria from the design doc:

- [ ] Can create new collab with template selection
- [ ] Can resume existing collab with state restoration
- [ ] Multiple collabs can run simultaneously on different ports
- [ ] Design doc updates persist and survive context compaction
- [ ] Verification catches drift and shows pros/cons
- [ ] Accepted drift auto-updates design doc with decision log
- [ ] Task dependency graph executes with correct parallelization
- [ ] Artifacts copy to project on completion
- [ ] Cleanup properly stops server and releases port

## Troubleshooting

### Server won't start
- Check if port is already in use: `lsof -i :3737`
- Kill any stale processes: `kill <pid>`

### Name generation fails
- Verify word lists exist in `lib/words/`
- Check file permissions

### Verification hook errors
- Ensure `jq` is installed
- Check that design doc exists at expected path

### Port not released after cleanup
- Manually edit `.collab/ports.json` if needed
- Remove orphaned entries
