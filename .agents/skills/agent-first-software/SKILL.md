---
name: agent-first-software
description: Use when designing, reviewing, refactoring, or extending a codebase that will receive repeated bounded edits from LLM agents or other fast contributors
---

# Agent-First Software

## Overview

Organize software so repeated small edits remain coherent. The correct change should be the obvious local change, and accumulated exploratory structure should be compacted before it becomes permanent architecture.

For the full rationale, read `references/manifesto.md`. This skill operationalizes that manifesto.

## When to Use

Use when:
- Adding features to a codebase that agents will continue editing
- Reviewing architecture for agent-readiness
- Refactoring sediment from many small changes
- Creating `AGENTS.md`, `ARCHITECTURE.md`, `COMPACTION.md`, or similar repo guidance
- Deciding whether a new abstraction, service, handler, interface, helper, or file deserves to exist

Do not use as a reason to avoid necessary architecture. Use it to make architecture earn its cost.

## Core Rule

```
MAKE THE CORRECT LOCAL CHANGE OBVIOUS, AND MAKE ACCIDENTAL STRUCTURE EXPENSIVE.
```

Agents follow local coherence. Shape the repository so local coherence points toward the intended architecture.

## Operating Instructions

### 1. Find the Stable Kernel and Open Surfaces

Before changing structure, identify:
- **Core:** stable concepts, invariants, domain meaning
- **Surfaces:** tables, schemas, registries, reducers, policies, workflows, route maps, migrations
- **Edges:** UI, HTTP, files, databases, queues, clocks, auth, external APIs

Prefer placing routine changes in surfaces or edges. Treat core changes as conceptually expensive.

Why: agents are safest when frequent edits land in places designed to absorb variation.

### 2. Prefer Data-Shaped Additions

For additive work, first look for an existing:
- rule table
- schema field
- route registration
- reducer case
- policy entry
- adapter method
- migration
- test case
- declarative map or registry

Only create a new file, class, interface, or layer when the existing surfaces cannot honestly contain the change.

Why: agents are good at adding one more case. One more durable concept is much more expensive.

### 3. Make New Concepts Pay Rent

Before introducing a permanent abstraction, require evidence:
- two or three concrete uses, or a clear external boundary
- a name that improves understanding
- behavior pinned by tests
- deletion, simplification, or consolidation elsewhere
- no simpler procedural/local shape would explain the work

One-implementation interfaces, new service-like classes, generic helpers, and manager/handler/provider/factory layers need explicit justification.

Why: concept inflation is the default failure mode of cautious small edits.

### 4. Keep Behavior Load-Bearing, Not Ceremony

Write or preserve tests that assert durable behavior:
- input produces output
- invalid state is rejected
- operation creates the intended effect
- parser returns the intended structure
- transition changes state as expected

Avoid tests that fossilize internal choreography:
- handler calls repository once
- service invokes mapper
- validator receives command
- private helper is called

Why: behavior tests let modules be replaced. Implementation tests make temporary structure immortal.

### 5. Keep Side Effects at the Edges

Make impurity easy to find. Keep the center focused on:
- pure transformations
- explicit state transitions
- deterministic rules
- small data structures

Put these at edges:
- network calls
- file I/O
- database writes
- queues
- clocks
- randomness
- user interfaces
- external APIs

Why: agents can modify code more safely when they can distinguish "computes meaning" from "touches the world."

### 6. Organize by Concept, Not Ritual

Prefer folders that keep a coherent idea together:

```text
Billing/
Customers/
Scheduling/
Search/
Rendering/
Persistence/
Auth/
```

Be suspicious of folder structures that imply every feature needs every layer:

```text
Commands/
Handlers/
Validators/
Services/
Repositories/
Dtos/
Mappers/
```

Why: folder names teach agents where to add code. Ritual folders create ritual code.

### 7. Create Sediment Basins for Provisional Work

Exploratory or uncertain work may live in explicitly provisional places:
- `Workflows`
- `Experiments`
- `Recipes`
- `Examples`
- `Playground`
- `FeatureDrafts`

Do not let provisional code become load-bearing by accident. Promote it only after repeated use, behavioral tests, stable naming, and removal of duplicate paths.

Why: exploration is useful, but unmarked exploration in core code becomes accidental architecture.

### 8. Compact Regularly

After several small edits, perform a compaction pass whose goal is to preserve behavior while reducing accidental structure.

A compaction pass may:
- inline one-off helpers
- merge files that express one concept
- delete duplicate branches
- rename concepts to match observed use
- replace speculative abstractions with direct code
- move edge-specific logic back to the edge
- reduce public API surface

A compaction pass should usually reduce at least one of:
- file count
- public type count
- one-off abstractions
- duplicated control flow
- special cases
- unnecessary indirection
- naming mismatch

Why: tiny agent edits create sediment. Compaction turns useful sediment into architecture and removes the rest.

## Architecture Budgets

When creating or updating repo guidance, include explicit budgets such as:

```text
Core may contain no more than N public concepts without an architecture note.
Interfaces are allowed at external boundaries, not around every internal class.
One-implementation interfaces are disallowed unless they isolate an external dependency.
New Service, Manager, Handler, Provider, Factory, or Helper files require justification.
New abstractions should delete or simplify more code than they add.
Side effects belong in adapters/edges, not the core.
If changing core concepts, update ARCHITECTURE.md.
```

Why: agents follow explicit constraints better than tacit taste.

## Review Checklist

Before finishing an agent-first change, ask:
- Did the change land on the smallest honest surface?
- Did it avoid adding a durable concept without evidence?
- Are side effects still visible at the edges?
- Are tests behavioral rather than choreography-based?
- Is there a future obvious place for the next similar change?
- Did the change increase file count, public types, or indirection without paying for it?
- Should this task include a small compaction pass?
- Would a fresh agent understand where to make the next edit?

## Common Mistakes

**Adding a professional-looking noun too early:** Use a local function or table entry until repetition proves the concept.

**Creating an interface for one implementation:** Keep concrete code unless isolating an external dependency or a proven boundary.

**Distributing one feature across ritual layers:** Keep the whole relevant idea visible in one conceptual area when possible.

**Mocking internal choreography:** Test meaning at module boundaries so internals can be replaced.

**Hiding the substrate completely:** Expose enough about SQL, files, queues, eventual consistency, or external APIs for agents to preserve real constraints.

**Skipping compaction:** Treat cleanup after repeated bounded edits as part of development, not optional polish.
