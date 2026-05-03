# Protocol And Artifacts

## Table Of Contents

1. Operating model
2. Artifact bundle
3. Iteration protocol
4. Failure format
5. Invariant format
6. Decision rule
7. Convergence rule
8. Minimal example

## Operating Model

Use this when architecture is still being discovered.

The loop is not “design once, then implement.” The loop is:

1. Define the workload the design must survive.
2. Build a probe that makes the real difficulty concrete.
3. Record structural failures.
4. Promote durable lessons into invariants.
5. Decide whether to refactor locally or restart from constraints.
6. Re-run the workload.

This is not a license for endless rewriting. The purpose of each iteration is to reduce ambiguity about what structure is actually required.

## Artifact Bundle

Create one bundle per app or large feature:

```text
.architecture/<feature-slug>/
  intent.md
  scenarios.md
  active-invariants.md
  behavior/
    README.md
    ...tests, traces, fixtures, contracts, or checklists...
  iterations/
    01/
      proposal.md
      failures.md
      decision.md
    02/
      proposal.md
      failures.md
      decision.md
```

### intent.md

Capture only the things that must stay true:

- feature goal
- hard constraints
- explicit non-goals
- done criteria

Keep it short. If it starts reading like a design doc, it is too early.

Suggested template:

```markdown
# Intent

## Goal

## Must Hold

## Non-Goals

## Done Signals
```

### scenarios.md

This is the workload the architecture must survive.

Keep 3-7 scenarios, such as:

- primary end-to-end flow
- one awkward edge case
- one likely extension or change request
- one operational or failure-handling case

Each scenario should be concrete enough that two different agents would test roughly the same thing.

Suggested template:

```markdown
# Scenarios

## S1 Primary flow

## S2 Edge case

## S3 Likely next requirement

## S4 Failure or recovery path
```

### active-invariants.md

This is the durable constraint ledger for the feature.

Rules:

- keep only active or provisional invariants
- revise or supersede wrong ones explicitly
- do not store style opinions
- every invariant must point back to an observed failure or leverage point

Recommended line format:

```text
INV-001 | status=active | trigger=when preview and apply use different row models | because=schema drift causes three-way edits and inconsistent validation | if-ignored=rule changes spread across multiple modules and regressions hide in translation code | source=iterations/01/failures.md#F2
```

Use `status=provisional` until a constraint has survived at least two scenarios or iterations.

### behavior/

This is what survives every rewrite.

Keep whichever of these are available:

- executable tests
- golden traces
- fixtures
- schemas or contracts
- manual verification checklist when code is too early for full tests

The point is simple: never preserve only prose lessons. Preserve the behavioral evidence that made the lesson credible.

### iterations/<n>/proposal.md

Capture the shape being tried in this iteration:

```markdown
# Proposal

## Architectural move

## Assumptions

## Why this seems cheaper than the alternatives
```

### iterations/<n>/failures.md

Record only structural failures, not every bug.

Template:

```markdown
# Failures

## F1
- Signal:
- Evidence:
- Why this is structural:
- Scenario(s) exposed:

## F2
- Signal:
- Evidence:
- Why this is structural:
- Scenario(s) exposed:
```

### iterations/<n>/decision.md

Use this to prevent vague “we should probably rewrite” calls.

```markdown
# Decision

- Decision: refactor | restart | continue probe
- Current shape still viable because:
- Clean-slate alternative would be:
- Remaining cost via refactor:
- Remaining cost via restart:
- Risk if we preserve current structure:
- Next checkpoint:
```

## Iteration Protocol

Run this in order.

### 1. Define the workload

Before writing structure, create `intent.md` and `scenarios.md`.

If you cannot name the scenarios yet, the problem is still under-specified. Clarify the task before designing architecture.

### 2. Build a probe

Implement the thinnest slice that touches the hard part.

Rules:

- no speculative extension points
- no extra layers without active pressure
- no abstractions that are not exercised by a scenario

### 3. Capture structural failures

Stop when one of these appears:

- a small change forces edits across multiple concerns
- the same rule exists in multiple representations
- a boundary cannot be explained without exceptions
- tests or manual checks require heroic setup because responsibilities are tangled
- a likely next scenario obviously does not fit the current seams

Do not wait until the whole feature is complete. This skill works by making structural friction visible early.

### 4. Promote or revise invariants

For each failure, ask:

- does this reveal a reusable constraint?
- is the lesson causal, not stylistic?
- would ignoring it predictably recreate the same failure?

If yes, add or revise an invariant.

If no, leave it as a local failure and keep moving.

### 5. Decide refactor versus restart

Derive the simplest clean-slate design from the current intent and active invariants.

Then compare current versus clean-slate on:

- explainability
- local change safety
- duplication or translation burden
- scenario coverage
- remaining implementation cost

Restart when most of these are true:

- the clean-slate design is materially simpler
- remaining refactor cost is close to or higher than rebuild cost
- the current design survives only through exceptions or adapters
- likely next scenarios do not fit existing seams
- you cannot explain why the current structure is correct in a few sentences

Otherwise refactor locally and set a checkpoint. If the checkpoint is missed, restart instead of rescuing indefinitely.

### 6. Re-run the workload

After refactor or restart:

- execute or simulate the scenarios again
- update the `behavior/` evidence
- confirm active invariants are satisfied naturally rather than by workaround

## Failure Format

Use failures that are observable and structural.

Good:

- “Preview and apply require separate translation layers for the same row rules.”
- “A retry rule change touched controller, queue handler, and read model mapper.”

Weak:

- “Architecture felt messy.”
- “CQRS was overkill.”

## Invariant Format

An invariant should answer four things:

- when it matters
- what reality caused the failure
- what breaks if ignored
- where the evidence came from

Minimal shape:

```text
INV-00N | status=provisional|active | trigger=... | because=... | if-ignored=... | source=...
```

Promotion rule:

- `provisional` after one strong iteration failure
- `active` after repeated confirmation or broad scenario coverage
- supersede explicitly when later evidence changes the lesson

## Decision Rule

Do not let sunk cost decide.

The only relevant question is: what is the cheapest trustworthy path from here to a design that satisfies the active invariants and surviving scenarios?

If local refactoring is still cheaper and the structure is mostly right, keep it.
If preserving the structure has become the main work, restart.

## Convergence Rule

You are done with the discovery loop when all of these hold:

- new scenarios fit into existing seams
- changes are local more often than cross-cutting
- no new structural invariant emerges from recent iterations
- active invariants are being satisfied directly, not through translation glue or ceremonial layers
- the next 2-3 likely requirements have an obvious home in the design

The stop condition is not “nothing feels wrong.”
The stop condition is “new pressure no longer changes the shape of the architecture.”

## Minimal Example

Feature: bulk user import

Scenario set:

- upload and preview rows
- reject invalid rows with field errors
- retry partial failures safely
- add a future “dry run” mode

Iteration 01 failure:

- preview rows use one row shape, apply uses another
- validation rules are duplicated
- retry needs the preview normalization logic anyway

Invariant promoted:

```text
INV-001 | status=active | trigger=when preview, validation, and apply use different row models | because=canonical row normalization is shared domain logic, not a presentation detail | if-ignored=rule changes produce schema drift, repeated translation code, and inconsistent retries | source=iterations/01/failures.md#F1
```

Decision:

- restart
- keep tests, sample CSV fixtures, preview traces, and error expectations
- rebuild around one canonical row normalization pipeline