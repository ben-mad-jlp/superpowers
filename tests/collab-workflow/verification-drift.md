# Test: Verification and Drift Detection

Test the verification gates and drift handling workflows.

## Test Objective

Validate that:
1. Verification hook detects drift between design and implementation
2. Drift report shows pros/cons for each drift item
3. "Accept" updates design doc with decision log
4. "Reject" adds issues to pending and blocks progress
5. "Review each" allows individual accept/reject decisions

## Prerequisites

- Collab in rough-draft phase (at least interface complete)
- Design doc with clear interface specifications
- Understanding of what constitutes "drift"

---

## Scenario A: Introduce Intentional Drift

### Setup

**Step 1: Create collab and reach interface phase**
```
/collab
```
- Select "feature" template
- Complete brainstorming
- Complete interface phase with this signature in design doc:
  ```typescript
  // Design specifies:
  authenticate(email: string, password: string): Promise<AuthResult>
  ```

**Step 2: Introduce drift in the code**
- When creating skeleton files, add an extra parameter:
  ```typescript
  // Actual implementation:
  authenticate(email: string, password: string, rememberMe?: boolean): Promise<AuthResult>
  ```

### Test

**Step 3: Trigger verification**
The verification runs automatically before phase transition, or manually:
```bash
./hooks/verify-phase.sh skeleton <collab-name>
```

**Expected output:**
```markdown
## Verification: rough-draft:skeleton

**Collab:** <collab-name>
**Design Doc:** .collab/<name>/documents/design.md
**Timestamp:** <ISO-8601>

---

### Aligned [checkmark]

- AuthResult type matches design
- Other interfaces match...

### Drift Detected [warning]

**1. `authenticate()` has extra `rememberMe` parameter**
   - Design: `authenticate(email: string, password: string): Promise<AuthResult>`
   - Code: `authenticate(email: string, password: string, rememberMe?: boolean): Promise<AuthResult>`

   Pros:
   - Enables "remember me" functionality for better UX
   - Optional parameter, doesn't break existing calls
   - Common authentication feature

   Cons:
   - Not in original design scope
   - May require additional session storage logic
   - Could have security implications if not implemented carefully

### Recommendation

Issue 1: Consider accepting - low risk, adds user value, optional parameter

---

**Proceed?** `[accept all / reject all / review each]`
```

**Expected outcome:**
- [ ] Drift detected and reported
- [ ] Pros and cons provided for each drift item
- [ ] Recommendation given
- [ ] User prompted for decision

---

## Scenario B: Accept Drift

### Test

**Step 1: Choose "accept all"**

**Expected behavior:**
1. Design doc updated to include the drift
2. Decision log section created/updated
3. Pending issues cleared (if any)
4. Phase transition proceeds

**Step 2: Verify design doc updated**
```bash
cat .collab/<name>/documents/design.md | grep -A 10 "authenticate"
```

**Expected outcome:**
- [ ] Design doc now shows `authenticate(email: string, password: string, rememberMe?: boolean)`
- [ ] Original specification replaced with new one

**Step 3: Verify decision log added**
```bash
cat .collab/<name>/documents/design.md | grep -A 20 "Decision Log"
```

**Expected format:**
```markdown
## Decision Log

### 2025-01-18: Added rememberMe parameter to authenticate()
- **Phase:** rough-draft:skeleton
- **Original:** `authenticate(email: string, password: string): Promise<AuthResult>`
- **Changed to:** `authenticate(email: string, password: string, rememberMe?: boolean): Promise<AuthResult>`
- **Reason:** Enables "remember me" functionality, optional parameter with low risk
```

**Expected outcome:**
- [ ] Decision Log section exists
- [ ] Entry includes date, phase, original, changed to, and reason
- [ ] Reason captures the rationale

**Step 4: Verify phase transition**
```bash
cat .collab/<name>/collab-state.json | jq '.phase'
```

**Expected outcome:**
- [ ] Phase transitioned to next phase
- [ ] No pending verification issues

---

## Scenario C: Reject Drift

### Setup

**Step 1: Introduce another drift**
- Add a method not in the design:
  ```typescript
  // Not in design:
  resetPassword(email: string): Promise<void>
  ```

### Test

**Step 2: Run verification**
Verification should detect the undocumented method.

**Step 3: Choose "reject all"**

**Expected behavior:**
1. Design doc unchanged
2. Drift items added to `pendingVerificationIssues`
3. Phase transition blocked
4. User informed they need to fix code

**Step 4: Verify pending issues**
```bash
cat .collab/<name>/collab-state.json | jq '.pendingVerificationIssues'
```

**Expected format:**
```json
[
  {
    "type": "drift",
    "phase": "skeleton",
    "description": "Added resetPassword method not in design",
    "file": "src/auth/service.ts",
    "detectedAt": "2025-01-18T12:00:00Z"
  }
]
```

**Expected outcome:**
- [ ] Pending issues populated
- [ ] Design doc NOT modified
- [ ] Phase NOT transitioned
- [ ] Claude indicates code needs to be fixed

**Step 5: Fix the code and re-verify**
- Remove the `resetPassword` method from code
- Run verification again

**Expected outcome:**
- [ ] Verification passes
- [ ] Pending issues cleared
- [ ] Phase can now transition

---

## Scenario D: Review Each Drift Individually

### Setup

**Step 1: Introduce multiple drifts**
- Drift 1: Add optional parameter (low risk)
- Drift 2: Add undocumented method (higher risk)
- Drift 3: Change return type (breaking change)

### Test

**Step 2: Run verification**

**Expected output:**
Three drift items with pros/cons for each.

**Step 3: Choose "review each"**

**Expected behavior:**
Claude presents each drift one at a time:
```
Drift 1 of 3:
**Added `rememberMe` parameter to authenticate()**

Pros: [list]
Cons: [list]

Accept or reject this change? [accept / reject]
```

**Step 4: Make individual decisions**
- Accept Drift 1 (low risk)
- Reject Drift 2 (scope creep)
- Reject Drift 3 (breaking change)

**Step 5: Verify mixed results**

**Check design doc:**
```bash
cat .collab/<name>/documents/design.md
```
- [ ] Drift 1 reflected in design doc
- [ ] Drift 1 in decision log
- [ ] Drifts 2 and 3 NOT in design doc

**Check pending issues:**
```bash
cat .collab/<name>/collab-state.json | jq '.pendingVerificationIssues'
```
- [ ] Drifts 2 and 3 in pending issues
- [ ] Drift 1 NOT in pending issues

**Expected outcome:**
- [ ] Mixed accept/reject handled correctly
- [ ] Accepted drifts update design
- [ ] Rejected drifts become pending issues
- [ ] Phase blocked due to pending issues

---

## Scenario E: Verification at Different Phases

### Test: Interface Phase Verification

**Checklist items verified:**
- [ ] All interface/function signatures defined in design present in code
- [ ] Signatures match exactly (parameter types, return types)
- [ ] No undocumented public interfaces
- [ ] Interface names follow naming conventions

### Test: Pseudocode Phase Verification

**Checklist items verified:**
- [ ] Implemented logic matches pseudocode flow
- [ ] All error handling cases addressed
- [ ] Edge cases from design handled
- [ ] Control flow consistent with design

### Test: Skeleton Phase Verification

**Checklist items verified:**
- [ ] All files from design created
- [ ] File paths match specifications
- [ ] Stub implementations present for all components
- [ ] Dependency graph matches design

### Test: Implementation Phase Verification

**Checklist items verified:**
- [ ] Final implementation matches design intent
- [ ] All features from design implemented
- [ ] Tests cover scenarios from design
- [ ] No significant deviations from architecture

---

## Scenario F: Missing Component (vs. Modified Component)

### Setup

**Step 1: In interface phase, define a component**
```typescript
// Design specifies:
class RateLimiter {
  checkLimit(userId: string): boolean
  resetLimit(userId: string): void
}
```

**Step 2: In skeleton phase, omit this class entirely**

### Test

**Step 3: Run verification**

**Expected output:**
```markdown
### Drift Detected [warning]

**1. Missing: `RateLimiter` class**
   - Design: Class with `checkLimit()` and `resetLimit()` methods
   - Code: Class not created

   Pros of keeping it out:
   - Simpler initial implementation
   - Could add later as enhancement
   - Reduces scope

   Cons:
   - Design specified it for a reason (API protection)
   - Security implications of missing rate limiting
   - May be harder to add later
```

**Expected outcome:**
- [ ] Missing component detected
- [ ] Pros/cons framed appropriately for omission
- [ ] Security/risk implications highlighted

---

## Scenario G: Repeated Verification Failures

### Setup

Design doc says:
> After 3 failed verifications, offer skip with warning

**Step 1: Fail verification three times**
- Introduce drift
- Reject
- Don't fix, try to proceed
- Repeat 3 times

### Test

**Expected behavior after 3 failures:**
Claude offers option to skip:
```
Verification has failed 3 times. You can:
1. Fix the issues and try again
2. Skip verification (NOT RECOMMENDED - drift will accumulate)

Warning: Skipping verification may cause implementation to diverge
significantly from the design, making it harder to maintain.
```

**Expected outcome:**
- [ ] Skip option offered after 3 failures
- [ ] Warning clearly explains risks
- [ ] User can choose to skip if needed

---

## Final Validation

After completing all scenarios:

- [ ] Drift detection works for additions, modifications, and omissions
- [ ] Pros/cons generated for all drift items
- [ ] Accept updates design doc with decision log
- [ ] Reject blocks progress and creates pending issues
- [ ] Review each allows granular decisions
- [ ] Verification checklist differs by phase
- [ ] Recovery path after repeated failures

## Notes

Record any issues encountered:

```
Issue:
Resolution:
```
