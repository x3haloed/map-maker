I’d think of it as moving through five product shapes:

1. Skateboard  → prove socket-based modular mapping is useful
2. Bicycle     → make it comfortable enough for real maps
3. Motorcycle  → add compilation, validation, and runtime quality
4. Car         → make it production-grade for teams
5. Luxury car  → make it an ecosystem / creation platform

Phase 1 — Skateboard: “I can place modular pieces without hating my life”

This is the true MVP.

The goal is not optimal collision, procedural generation, marketplace, runtime loading, or fancy UI.

The goal is:

I can build a small playable Godot level from snapping semantic components together.

Features

Godot editor plugin
One ScaleProfile resource
One ModuleDefinition resource
One ModuleInstance3D node
Socket markers on modules
Socket-to-socket snapping
Grid/angle snapping
Basic validation
Simple example module set

Authoring experience

User can:

Create a scale profile
Create/import a few modules
Add sockets to modules
Place a hallway
Attach a door
Attach a room
Attach another hallway
Press Play in Godot
Walk around

Scope constraints

Collision is still mostly per-piece.

No fancy merging yet.

No navmesh generation.

No occlusion.

No asset marketplace.

No standalone editor.

No procedural generation.

The validation should catch only brutal obvious problems

socket off-grid
module off-grid
incompatible socket types
overlapping footprints
unconnected required sockets
invalid rotation

Success test

You should be able to make:

one room
two hallways
one door
one corner
one stair/ramp if ambitious
one playable loop

And the feeling should be:

Oh. This already feels less stupid than dragging meshes around manually.

That’s the skateboard.

Phase 2 — Bicycle: “I can make an actual small map”

This phase turns the toy into a working authoring tool.

The goal:

A solo developer can build a small complete map using a real reusable module kit.

Features

Module library browser
Preview thumbnails
Socket compatibility rules
Module categories
Footprint visualization
Clearance volumes
Better gizmos
Undo/redo integration
MapRoot3D
Authoring/compiled scene separation
Basic decoration mode

Module types

Start supporting families:

hallways
corners
T-junctions
rooms
doors
floors
stairs/ramps
platforms
wall panels
ceiling caps
cover blocks
trim/decor pieces

Scale profile becomes useful

The tool should expose canonical measurements:

base grid
major grid
hallway widths
door widths
ceiling heights
wall thickness
allowed yaw angles
step height
jump height
player capsule

Better validation

Now the tool should detect:

player cannot pass through this connection
door too narrow
ceiling too low
ramp too steep
stair invalid
socket has no reciprocal connection
decor blocks required clearance
tiny gap between connected pieces

Output

Still mostly Godot-native scenes:

authoring.tscn
compiled_runtime.tscn
module definitions as .tres
scale profile as .tres

Success test

You can build a small deathmatch/blockout-style level:

3–5 rooms
multiple hallway loops
vertical transition
several doors
some cover
spawn points
playable collision

And it feels good enough that you would choose it over raw Godot placement.

That’s the bicycle.

Phase 3 — Motorcycle: “The compiler makes this better than manual work”

This is where it starts becoming special.

The goal:

The tool does the painful build-system work that hand-authored modular maps usually avoid.

Features

Map compiler
Collision contribution system
Merged collision generation
Generated runtime scene
Navigation contribution system
Basic navmesh generation or nav hints
Gameplay zone graph
Connection graph output
Validation report panel
Compile profiles

Collision becomes semantic

Modules stop saying merely:

here is my mesh collider

They start saying:

I contribute a floor slab here
I contribute a left wall here
I contribute a ceiling here
I contribute a blocker volume here
This doorway subtracts an opening here

Then the compiler emits fewer, larger collision shapes.

Compiler pipeline

authoring scene
→ collect module instances
→ validate transforms/sockets/footprints
→ extract collision contributions
→ quantize surfaces
→ merge compatible surfaces
→ generate runtime collision
→ generate graph metadata
→ emit compiled scene

Runtime scene gets clean

The compiled scene contains:

visual instances
optimized collision
navigation regions
spawn points
gameplay markers
map graph resource

The authoring helpers are stripped.

Validation becomes valuable

The report panel should become something mapmakers rely on:

Errors:
- Hallway_08 socket east is connected to incompatible RoomSocket.large
- Door_03 clearance blocked by Crate_12
- SpawnPoint_A has no valid floor below it
Warnings:
- Corridor loop has 19m uninterrupted sightline
- Room_04 has only one exit
- Stair_02 exceeds configured comfort angle

Success test

You can create a map, compile it, and the compiled version is objectively better than the authoring version:

fewer collision bodies
cleaner scene tree
validated traversal
usable graph metadata
less runtime junk

That’s the motorcycle.

This is probably the first version that could plausibly be sold.

Phase 4 — Car: “A production tool for real Godot teams”

Now the product becomes professional.

The goal:

A team can build, review, version, validate, package, and ship maps with this tool.

Features

Polished editor UI
Module kit manager
Map kit packaging
Versioned module definitions
Migration tools
Diff-friendly data
Team-safe validation
Batch compile
Command-line compile
CI validation
Performance budget reports
Automated thumbnails
Documentation generator

Team workflows

This phase needs boring-but-critical stuff:

Stable file formats
Clear folder conventions
Reference integrity
Missing asset repair
Module version upgrades
Deprecated module warnings
Batch recompile all maps
Headless validation in CI

Command line matters

You want something like:

godot --headless --script addons/spatial_mapper/tools/compile_maps.gd -- maps/**/*.tscn

or eventually:

spatial-mapper compile res://maps --profile shipping
spatial-mapper validate res://maps --fail-on-warnings

MapKit packaging

A MapKit becomes a first-class object:

MapKit:
  scale profiles
  module definitions
  meshes/materials
  socket schemas
  compile profiles
  validators
  example maps
  docs

Runtime support matures

Games can query:

What room is the player in?
What modules are connected to this room?
What zone is visible from here?
What doors connect these spaces?
Where are valid spawn regions?
What traversal types connect A to B?

This makes the graph useful beyond authoring.

Success test

A team can have:

10+ maps
100+ modules
several module kits
multiple designers
CI validation
repeatable shipping export

And the tool does not collapse into asset chaos.

That’s the car.

Phase 5 — Luxury Car: “The tool becomes an ecosystem”

This is the fully-realized version.

The goal:

Users are not just building maps. They are building, sharing, remixing, validating, and generating architectural spaces.

Features

Standalone editor option
Consumer-friendly map maker
In-editor playtest mode
Asset/MapKit marketplace
Procedural layout assistant
AI-assisted blockout
Gameplay flow analysis
Multiplayer arena analysis
Lighting/occlusion assistance
Mod/map pack export
One-click .pck packaging
Versioned content distribution

The big leap: grammar-aware creation

At this stage, the map is deeply semantic.

The tool can understand:

this is a combat loop
this is a chokepoint
this is a dead end
this is a flank route
this is a hub
this is a reveal corridor
this is a safe room
this is a vertical arena

Then it can assist meaningfully.

Not “generate random rooms.”

More like:

Suggest a second exit from this room
Add a flank route around this chokepoint
Make this arena more vertical
Find unfair spawn sightlines
Show all dead-end branches
Generate three alternate layouts preserving this room
Replace this hallway family with sci-fi industrial modules

Flow analysis

This is where it becomes much more than snap-to-grid.

It can analyze:

travel distances
line of sight
spawn exposure
arena loops
cover density
route redundancy
verticality
encounter pacing
zone control
door/chokepoint pressure

For multiplayer maps, this is gold.

Content ecosystem

This is where .pck matters more.

Users can ship:

MapKit .zip
MapPack .pck
CompiledMap .pck
Mod bundle
Workshop-style upload

Standalone editor becomes plausible

At this stage, you may want a full app because the audience may include people who are not Godot developers:

Open editor
Pick game profile
Choose MapKit
Build map
Test map
Publish map pack

That is no longer just a plugin. That is a creation platform.

Success test

A non-programmer can build and publish a map pack using constrained professional-quality modules, while an advanced Godot developer can still drop into the native project and customize everything.

That’s the luxury car.

Product evolution in one table

Phase	Product Form	Main Promise
1. Skateboard	Minimal Godot plugin	Snap components together
2. Bicycle	Usable editor plugin	Build real small maps comfortably
3. Motorcycle	Compiler-backed tool	Generate optimized runtime scenes
4. Car	Production pipeline	Teams can ship maps reliably
5. Luxury car	Ecosystem/platform	Create, analyze, package, share, remix

The critical path

The core sequence should be:

Socket snapping
→ scale profile
→ module definitions
→ validation
→ authoring/runtime split
→ collision compiler
→ graph metadata
→ MapKits
→ team pipeline
→ procedural/AI assistance
→ ecosystem

Do not start with procedural generation.

Do not start with standalone editor.

Do not start with marketplace.

Do not start with perfect collision.

Start with:

Can I snap a hallway to a room and have it be aligned, valid, and playable?

That is the seed crystal.

The MVP should be tiny but philosophically complete

The skateboard should already contain the whole worldview:

maps are made of semantic components
components have sockets
sockets have compatibility
scale is explicit
placement is constrained
validation is immediate
runtime output is Godot-native

Even if collision is dumb and the UI is crude, that is enough.

Because once that works, every later phase is “make the compiler/editor smarter.”

The fully-realized version is not a different idea.

It is the same idea with more consequences extracted from it.