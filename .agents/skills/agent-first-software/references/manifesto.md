# Organizing Software for LLM Agents First

## A Manifesto for Codebases That Survive a Thousand Tiny Changes

Modern software is beginning to be written by a new kind of contributor: tireless, fast, literal, cautious, and dangerously willing to add one more file.

LLM agents are good at bounded change. They can inspect a local surface, make a small modification, run tests, repair compile errors, and proceed. This is powerful. It is also dangerous.

A codebase optimized for human architects alone often assumes that someone will continuously preserve the invisible shape of the system: the negative space, the conceptual budget, the reasons not to add another abstraction. LLM agents do not reliably preserve that shape unless the codebase makes the correct shape obvious and the wrong shape awkward.

The problem is not that LLMs make small changes.

The problem is that, in ordinary software architecture, small safe changes often accumulate as permanent structure.

After enough “safe” edits, the codebase becomes sedimentary rock: layers of handlers, services, helpers, adapters, validators, mappers, flags, branches, and duplicated patterns, all locally reasonable, all globally exhausting.

LLM-first software organization begins from a different premise:

> Tiny changes are inevitable. Therefore the codebase must be designed so tiny changes land on surfaces that can absorb, reveal, and later compact them.

The goal is not to make agents act like senior architects. The goal is to organize software so that agentic coding naturally falls downhill toward maintainable structure.

---

## 1. The Prime Directive: Make the Correct Change the Obvious Local Change

LLM agents operate through local coherence. They look for the next reasonable edit.

If the codebase presents ten folders named `Commands`, `Handlers`, `Services`, `Validators`, `Factories`, `Mappers`, and `Providers`, the model will infer that every feature requires ten additions.

If the codebase presents a small number of stable concepts and obvious extension slots, the model will usually add to those slots.

Therefore:

> Architecture is not merely what the system allows. Architecture is what the system makes obvious.

An LLM-first codebase should have visible gravitational centers:

- one obvious place for each concept
- one obvious way to add a case
- one obvious surface for configuration
- one obvious layer for external adapters
- one obvious boundary where tests pin behavior

The codebase should not require the agent to infer taste. It should embody taste.

---

## 2. Stable Kernel, Open Surfaces

The core of a system should be small, stable, and conceptually expensive to change.

Around that core, the system should expose open surfaces where most day-to-day changes belong.

A useful division:

```text
/Core
  The small stable kernel.
  Few concepts. Strong invariants. Rarely changed casually.

/Surfaces
  Declarative or table-shaped extension points.
  Rules, schemas, mappings, workflows, reducers, policies, registrations.

/Edges
  Adapters to the outside world.
  UI, HTTP, files, databases, queues, APIs, auth, cloud services.
```

The kernel should contain the ideas the system cannot live without.

The surfaces should contain the details that change often.

The edges should contain the world’s mess.

Most agent edits should happen in the surfaces and edges, not the kernel.

A healthy codebase makes this distinction hard to miss.

---

## 3. Additive Work Should Land in Data-Shaped Places

LLMs are good at adding one more case to an existing pattern.

So give them patterns that do not create architectural debt when extended.

Prefer additions like:

- one rule in a rule table
- one schema field
- one route registration
- one reducer case
- one migration
- one test case
- one policy entry
- one adapter method at a boundary
- one row in a declarative map

Be suspicious of additions like:

- one new service
- one new manager
- one new handler hierarchy
- one new provider abstraction
- one new one-off helper
- one new interface with one implementation
- one new layer because the old layer felt crowded

This is not a ban on structure. It is a bias against unearned permanence.

A new class is often a claim that the system has discovered a new durable concept.

Most feature edits do not deserve that.

---

## 4. New Concepts Must Pay Rent

In LLM-coded systems, the easiest failure is concept inflation.

A model sees a problem and creates a noun to contain it.

That noun compiles. It isolates risk. It appears professional. It is also how codebases rot.

An LLM-first project should treat new durable concepts as expensive.

A new permanent abstraction should require evidence:

- at least two or three concrete uses
- clear reduction of duplication
- a stable name that improves understanding
- tests that pin its public behavior
- deletion or simplification elsewhere

If a new abstraction does not delete complexity, it probably adds complexity.

If a new abstraction has only one implementation, it is probably not an abstraction yet. It may be a file-shaped anxiety response.

---

## 5. Prefer Procedural Clarity Until the Shape Proves Itself

The opposite of over-architecture is not chaos.

It is honest locality.

A straightforward function, workflow, or module is often better than a prematurely distributed set of types.

Prefer:

```text
A clear workflow in one place.
A boring function with obvious inputs and outputs.
A small module whose whole behavior can be read at once.
```

Over:

```text
A command.
A handler.
A validator.
A mapper.
A service.
A factory.
A result type.
A provider.
A repository.
```

Some systems genuinely need those things. Many do not.

LLM agents are especially vulnerable to ceremony because ceremony looks safe. A ceremonial architecture gives the model many low-risk places to add code. It also multiplies the number of places that must be understood before anything can be changed.

For LLM-first organization, boring code is a virtue when it preserves locality.

---

## 6. Behavioral Tests Are the Load-Bearing Walls

If you want agents to rewrite code safely, tests must pin behavior rather than implementation rituals.

Bad tests fossilize the current shape:

```text
The handler calls the repository once.
The service invokes the mapper.
The validator receives the command.
```

Good tests preserve replaceability:

```text
Given this input, the system produces this durable effect.
Given this state, this operation is rejected.
Given this event, this projection changes in this way.
Given this file, this parser returns this structure.
```

LLM-first codebases need tests that allow internals to be replaced wholesale.

The test suite should say:

> You may change how this works. You may not change what it means.

Mock-heavy tests often make the current implementation immortal. Behavioral tests make modules replaceable.

Replaceability is survival.

---

## 7. Design for Replacement, Not Endless Editing

A line-editable system is not necessarily maintainable.

LLM agents are excellent at incremental patching. Without counterpressure, they will patch forever.

A healthy codebase should make it normal to replace a module once its current shape has served its exploratory purpose.

The architectural unit is not the line.

The architectural unit is the replaceable module.

A module is healthy when:

- its public surface is small
- its behavior is pinned by tests
- its dependencies are explicit
- its internals can be rewritten without system-wide impact
- its name describes a stable concept

Tiny edits are useful for discovery. Replacement is how discovery becomes architecture.

---

## 8. Compaction Is a First-Class Development Activity

LLM coding creates sediment.

Some sediment is useful. It records exploration. It gives the system shape. It helps features land.

But sediment must be compacted.

A codebase intended for agents should have an explicit compaction ritual.

Compaction is not vague refactoring. It is a deliberate pass with a measurable goal:

```text
Preserve behavior.
Reduce concepts.
Delete weak abstractions.
Merge duplicated patterns.
Inline one-off helpers.
Rename things to match their final meaning.
Move accidental structure out of the load-bearing path.
```

A successful compaction pass should usually reduce at least one of:

- file count
- public type count
- one-off abstractions
- duplicated control flow
- special cases
- unnecessary indirection
- naming mismatch

The workflow should not be:

```text
feature, feature, feature, feature, feature, collapse
```

It should be:

```text
feature, feature, feature, compact
feature, feature, compact
feature, compact
```

Compaction is how agentic software avoids becoming a fossil record of every cautious intermediate step.

---

## 9. Use Architecture Budgets

Agents respond well to explicit constraints.

A codebase should expose its architectural budget:

```text
Maximum core concepts.
Maximum public abstractions.
Allowed dependency directions.
Allowed places for side effects.
Allowed places for new files.
Rules for introducing interfaces.
Rules for adding service-like classes.
Rules for promoting workflow code into core code.
```

Examples:

```text
Core may contain no more than twelve public concepts without an architecture note.

Interfaces are allowed at external boundaries, not around every internal class.

One-implementation interfaces are disallowed unless they isolate an external dependency or enable a specific test seam.

New files ending in Service, Manager, Handler, Provider, Factory, or Helper require justification.

A new abstraction should delete or simplify more code than it adds.
```

These are not aesthetic preferences. They are anti-entropy mechanisms.

The budget teaches agents what kind of growth is acceptable.

---

## 10. Make the Codebase Legible to a Fresh Agent

Every new agent instance arrives without the tacit memory of prior decisions.

Therefore the codebase must carry its own orientation.

An LLM-first repository should include a small number of high-value orientation documents:

```text
ARCHITECTURE.md
  The stable concepts, boundaries, dependency rules, and non-goals.

AGENTS.md
  How agents should work in this repo: commands, tests, style, forbidden moves, preferred moves.

COMPACTION.md
  How to reduce accumulated structure without changing behavior.

CONCEPTS.md or GLOSSARY.md
  Names that have specific meaning in this system.
```

These documents should be short enough to read and strong enough to constrain.

They should not be corporate theater.

They should tell the next agent where the floor is.

---

## 11. Name the Few Things That Matter

LLMs are sensitive to names. Names create paths of least resistance.

A codebase with vague names invites vague additions.

A codebase with sharp names channels edits.

Bad names:

```text
Manager
Processor
Service
Helper
Util
Data
Common
Shared
Thing
Handler
```

Sometimes these names are unavoidable. Usually they are evidence that the concept has not been understood.

Good names say what role the thing plays in the system:

```text
Ledger
Projection
Policy
Adapter
Snapshot
Parser
Renderer
Resolver
Scheduler
Boundary
```

The fewer named concepts a system has, the more carefully those names must be chosen.

LLM-first software should use names as rails.

---

## 12. Keep Side Effects at the Edges

Side effects create hidden coupling.

Hidden coupling is hard for agents to reason about.

An LLM-first architecture should make side effects visible and peripheral.

The center should be made of:

- pure transformations
- explicit state transitions
- deterministic rules
- small data structures
- functions whose behavior can be tested without the world

The edges should own:

- network calls
- file I/O
- database writes
- queues
- clocks
- random numbers
- user interfaces
- external APIs

This does not mean everything must be pure-functional. It means the system should make impurity easy to find.

Agents are much safer when they can distinguish:

```text
This computes meaning.
This touches the world.
```

---

## 13. Prefer Explicit State Transitions

Complex software becomes easier to modify when change is represented explicitly.

A state transition might be:

- a command
- an event
- a patch
- a reducer case
- a workflow step
- a migration
- a transaction
- a policy decision

The exact form depends on the system.

The principle is broader:

> State should change through named, inspectable, testable paths.

Agents struggle when state changes are smeared across callbacks, ambient globals, hidden mutation, implicit framework magic, and incidental side effects.

They do better when a change has a visible shape:

```text
Before state.
Operation.
After state.
Validation.
Effect.
```

State transition surfaces become safe landing zones for tiny edits.

---

## 14. Do Not Hide the Substrate Too Well

Abstractions are useful when they remove irrelevant detail.

They are harmful when they conceal the thing the developer must still understand.

LLM-first software should avoid illusion chambers.

If the system uses SQL, the agent should be allowed to know that SQL exists.

If the system uses files, the agent should know where files are written.

If the system uses queues, the agent should know the delivery semantics.

If the system uses eventual consistency, the agent should know where stale reads are possible.

A good abstraction says:

> Here is the common path. Here is the escape hatch. Here is the underlying reality when it matters.

A bad abstraction says:

> Pretend the underlying reality does not exist.

Agents cannot safely preserve boundaries they cannot see.

---

## 15. Organize by Concept, Not Ritual

Folders teach behavior.

A ritual folder structure creates ritual code.

If the repository is organized like this:

```text
Commands/
Handlers/
Validators/
Services/
Repositories/
Dtos/
Mappers/
```

then every feature will tend to be distributed across all of them.

For LLM-first work, prefer organization that keeps a coherent idea together until it genuinely needs to split.

```text
Billing/
Customers/
Scheduling/
Search/
Rendering/
Persistence/
Auth/
```

Or for a small library:

```text
Core/
Adapters/
Tests/
Examples/
```

The question is not “horizontal layers or vertical slices?”

The question is:

> Where can an agent make the next change while seeing the whole relevant idea?

Locality beats taxonomy.

---

## 16. Build Sediment Basins

Exploratory work needs a place to be messy.

If every experiment lands directly in the core, the core rots.

If experiments have no path to maturity, the system becomes a junk drawer.

An LLM-first codebase needs sediment basins: places where provisional code can exist without pretending to be architecture.

Examples:

```text
/Workflows
/Experiments
/Recipes
/Examples
/Playground
/FeatureDrafts
```

The rule:

> Provisional code may exist, but it must not become load-bearing by accident.

Promotion from sediment basin to core should require:

- repeated use
- behavioral tests
- a stable name
- removal of older duplicate paths
- clear dependency direction

Mess is not the enemy. Uncompacted mess in the load-bearing path is the enemy.

---

## 17. Prefer Tables, Registries, and Reducers Over Class Explosions

Many changes are variations inside an existing concept.

LLMs often express each variation as a new class because classes are an easy containment mechanism.

A better shape is often a table, registry, or reducer:

```text
Supported file types.
Validation rules.
Route definitions.
Feature flags.
Rendering cases.
Policy decisions.
Projection mappings.
Workflow steps.
Tool definitions.
```

A table-shaped extension point lets the agent add behavior without inventing structure.

A reducer-shaped extension point lets the agent add a case while preserving one state-transition surface.

A registry-shaped extension point lets the agent add a capability without scattering discovery logic.

The goal is not to avoid classes. The goal is to avoid one class per tiny difference.

---

## 18. Make Illegal Moves Incoherent

Instruction alone is weak.

The codebase should be shaped so bad additions feel out of place.

If agents should not add random service classes, there should not be a forest of existing random service classes.

If all side effects belong in adapters, then side effects in core should be rare enough to look obviously wrong.

If extensions belong in declarative maps, those maps should be easy to find and easier to modify than inventing a new path.

This is architecture as terrain design.

The best constraints are not merely written. They are embodied.

---

## 19. Optimize for Re-Entry

LLM agents lose context. Humans lose context. Teams lose context.

A codebase should be designed for re-entry.

A fresh agent should be able to answer quickly:

```text
What is this system?
What are the stable concepts?
Where do changes usually go?
How do I run tests?
What should I avoid doing?
What is the smallest meaningful behavior boundary?
How do I know when a change is complete?
```

Re-entry is not documentation polish. It is operational survival.

The less context a contributor needs to become useful, the more robust the codebase is under agentic work.

---

## 20. The Agent-Friendly Unit of Work

A good task for an LLM agent has a bounded surface and a behavioral check.

Poor task shape:

```text
Improve the architecture.
Make this cleaner.
Add support for billing.
Refactor the persistence layer.
```

Better task shape:

```text
Add this field to this schema, expose it in this endpoint, and add a behavioral test proving it round-trips.

Add this reducer case and test the before/after state.

Move this duplicated parsing logic into one function without changing public behavior.

Compact these three helpers into one module; tests must remain behaviorally identical.
```

The codebase should make good task decomposition natural.

If every change requires understanding twenty concepts, the architecture is hostile to agents.

---

## 21. The Human Role Changes

In an LLM-first codebase, the human is less often the author of every line and more often the steward of terrain.

The human’s job is to maintain:

- conceptual budget
- naming quality
- module boundaries
- test meaning
- compaction rhythm
- dependency direction
- the distinction between provisional and permanent structure

The human should ask:

```text
Where will the next hundred tiny changes land?
What will they accumulate into?
Is this new concept real?
Can this module be replaced?
Are tests preserving behavior or fossilizing implementation?
Is the codebase teaching the agent the right moves?
```

The human becomes less like a typist and more like a landscape architect.

---

## 22. What to Put in AGENTS.md

An LLM-first repository should give agents direct operational rules.

Example:

```text
# Agent Rules

Prefer modifying existing cohesive files over creating new files.

Do not add a new Service, Manager, Handler, Provider, Factory, or Helper unless no existing concept can honestly contain the change.

Interfaces are allowed at external boundaries. Do not create one-implementation interfaces for internal code.

Add behavior through existing tables, registries, reducers, policies, schemas, or adapters when possible.

Tests should assert behavior at module boundaries, not internal call sequences.

When adding a feature, choose the smallest surface that preserves locality.

When a change creates duplication, leave it if the pattern has not proven itself. Compact only after the second or third concrete example.

When performing compaction, reduce concepts without changing behavior.

If changing core concepts, update ARCHITECTURE.md.

If adding a new durable concept, explain what existing concept failed to express.
```

These rules are not bureaucracy. They are the rails that prevent cautious local edits from becoming global ruin.

---

## 23. What to Put in COMPACTION.md

Compaction needs its own protocol.

Example:

```text
# Compaction Protocol

Goal: preserve behavior while reducing accidental structure.

A compaction pass may:
- inline one-off helpers
- merge files that express one concept
- delete duplicate branches
- rename concepts to match observed usage
- replace speculative abstractions with direct code
- move edge-specific logic back to the edge
- reduce public API surface

A compaction pass may not:
- change external behavior without an explicit feature task
- add a new abstraction unless it removes more structure than it adds
- preserve compatibility with dead internal shapes
- keep duplicated code merely because it already exists

Success indicators:
- tests pass
- public surface is smaller or equally small
- fewer concepts are needed to explain the module
- fewer files/classes exist, or remaining files have clearer reasons to exist
- the next agent has a more obvious place to make future changes
```

Compaction is the digestion process of agentic coding.

Without digestion, the system bloats.

---

## 24. The Manifesto in Short

LLM-first software is not software with prompts sprinkled on top.

It is software organized so that bounded agent edits remain healthy under repetition.

It follows these laws:

```text
Make the correct local change obvious.
Keep the kernel small.
Expose open surfaces for frequent change.
Let additive work land in data-shaped places.
Make new concepts pay rent.
Prefer procedural clarity until abstraction is earned.
Pin behavior, not implementation rituals.
Design modules to be replaced.
Compact regularly.
Budget architecture explicitly.
Keep side effects at the edges.
Make state transitions visible.
Do not hide the substrate too well.
Organize by concept, not ceremony.
Create sediment basins for provisional work.
Use names as rails.
Optimize for fresh-agent re-entry.
Treat the human as terrain steward.
```

The goal is not to stop tiny changes.

The goal is to make tiny changes survivable.

The deepest principle is this:

> A codebase for LLM agents should not rely on the agent remembering the architecture. It should cause the agent to rediscover the architecture through the shape of the work.

When software is organized this way, agents can do what they are good at: make bounded, reversible, compiling changes.

And the system can do what it must do: remain coherent after the thousandth one.

