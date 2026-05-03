Yes. This is a modular level-authoring system, but the important insight is that the module is not merely a mesh.

The module is a spatial contract.

A useful component would carry:

visual mesh
collision intent
grid footprint
snap sockets
semantic type
navigation contribution
occlusion/portal contribution
scale constraints
connection rules

That is much closer to old BSP/brush mapping than modern “drag arbitrary meshes into a scene” workflows.

The thing you miss from BSP is not necessarily BSP. It is:

geometry that knows what it is allowed to become adjacent to.

Modern mesh workflows lost that. They gave you arbitrary triangles, but took away architectural grammar.

The core primitive should probably be a “cell” or “module,” not a mesh

Something like:

Module:
  id: Hallway_01
  footprint: 1 x 2 x 1 cells
  canonical_height: 3m
  sockets:
    - name: north
      position: [0, 0, -1]
      normal: [0, 0, -1]
      type: hallway_2m
      tags: [walkable, interior]
    - name: south
      position: [0, 0, 1]
      normal: [0, 0, 1]
      type: hallway_2m
      tags: [walkable, interior]
  collision:
    mode: contributes_to_region
    solids:
      - floor
      - left_wall
      - right_wall
      - ceiling
  nav:
    walkable_regions:
      - center_strip
  occlusion:
    portals:
      - north
      - south

Then the map-maker is not placing “a mesh.” They are placing a topological room fragment.

That gives you the UT2004 feeling back: the map is not an art collage; it is an authored navigable space.

The scale system matters more than the asset library

You are exactly right that it starts with proportions.

Before assets exist, the tool should define a canonical body:

player height
player radius / capsule width
jump height
step height
crouch height
camera height
door clearance
combat distance
turning comfort

Then derive architectural units:

base grid: 0.5m or 1m
wall thickness: 0.25m / 0.5m
single hallway: 2m
double hallway: 4m
door width: 1.5m or 2m
ceiling: 3m / 4m / 6m
stair rise/run
cover height
ledge height

This should become a project-level “scale profile.”

Example:

ScaleProfile: ArenaShooterHuman
unit: meters
base_grid: 0.5
major_grid: 2.0
player:
  height: 1.8
  radius: 0.4
  camera_height: 1.65
  jump_height: 1.2
  step_height: 0.35
architecture:
  door_width: 2.0
  door_height: 2.5
  hallway_width: 3.0
  double_hallway_width: 6.0
  ceiling_low: 3.0
  ceiling_standard: 4.0
  ceiling_large: 8.0
angles:
  allowed_yaw: [0, 45, 90, 135, 180, 225, 270, 315]

Once that exists, components can be validated against the scale profile.

That is huge. It means the tool can say:

This doorway is invalid:
- width is 1.37m
- expected one of: 1.5m, 2.0m, 3.0m
- socket is off-grid by 0.013m

That alone would remove so much pain.

Snap points should be semantic sockets

The mistake would be making them “points.”

They should be oriented interfaces.

A socket needs:

position
rotation / normal
width
height
type
allowed counterpart types
clearance volume
tags
priority

For example:

Socket:
  type: doorway.medium
  width: 2.0
  height: 2.5
  normal: +Z
  compatible_with:
    - doorway.medium
    - hallway.medium
    - room.edge.medium
  clearance:
    shape: box
    size: [2.0, 2.5, 1.0]

That gives you intelligent attachment.

A hallway can connect to a room edge.
A door can connect to a wall opening.
A vent can connect to a vent shaft.
A stair top can connect to an upper-floor landing.
A pipe socket cannot accidentally connect to a doorway.

This is the “brush” feeling: pieces become meaningful in relation to each other.

Collision should be generated from intent, not inherited from meshes

I think your instinct is right: the hard part is collision.

But I would not try to merge arbitrary mesh collision at first. That gets ugly fast.

Instead, each module should contribute simple collision claims into a shared collision-building pass.

For example:

Hallway module contributes:
- floor plane from x=-1.5..1.5, z=-2..2
- left wall slab
- right wall slab
- ceiling slab

Then the map compiler merges adjacent slabs.

So instead of 400 hallway pieces each having their own floor collider, you get one long floor collider.

The pipeline becomes:

Placed modules
→ extract collision primitives
→ quantize to canonical grid
→ merge coplanar/adjacent surfaces
→ subtract openings from doors/windows
→ emit optimized collision bodies

This is basically a baby BSP/compiler pass, but over semantic modules.

The important thing is that the placed assets are not the final physics representation. They are the source document. The tool compiles them into runtime geometry.

A “map compiler” is probably the missing piece

Old editors had a build step. That was annoying, but powerful.

Modern scene editors often blur authoring and runtime too much. For this kind of tool, you probably want a compilation step:

Authoring Scene
  modular pieces
  sockets
  debug volumes
  semantic markers
Compiled Scene
  instanced visuals
  merged collision
  generated navmesh hints
  occlusion portals
  lightmap groups
  gameplay zones

The authoring scene can be messy and componentized.

The runtime scene should be optimized and boring.

That gives you a place to do:

collision merging
socket validation
gap detection
overlap detection
nav continuity checks
portal generation
occlusion region generation
spawn validation
scale linting

Very BSP-like.

The authoring loop should feel like this

1. Choose scale profile.
2. Define module families: hallway, room, door, stair, lift, trim, cover, platform.
3. Author modules with sockets and footprints.
4. Place modules by socket connection, not freehand transform.
5. Allow free placement only as decoration/detail mode.
6. Compile map.
7. Validate:
    * impossible gaps
    * tiny misalignments
    * broken socket chains
    * unwalkable doorways
    * collision seams
    * disconnected nav regions
    * too-low ceilings
    * invalid player clearances

This would be wildly useful.

The best mental model

I would frame the whole thing like this:

A map is a graph of spatial contracts, compiled into a Godot scene.

Not:

A map is a collection of meshes.

The graph is the real level.

The meshes are just one projection of it.

Something like:

Room_A
  connects east to Hallway_12 through Door_03
  connects north to Stairwell_01
  contains SpawnPoint_TeamA_02
  has gameplay volume CombatZone_A
Hallway_12
  connects west to Room_A
  connects east to Room_B
  width class: medium
  traversal class: walkable

Once the level is a graph, all sorts of nice things become possible:

auto doors
auto nav hints
flow analysis
distance analysis
spawn fairness checks
arena loop detection
dead-end detection
lock/key progression checks
procedural blockout
AI-assisted layout

This is where it gets exciting. You are not just building a mapper. You are building an architectural grammar engine.

Minimal viable version

The smallest useful version would be:

Godot editor plugin
Features:
- project scale profile resource
- module resource format
- socket nodes
- grid/angle validator
- socket snapping
- collision primitive extraction
- compile button
- merged box collision output

Do not start with arbitrary mesh collision merging.

Start with boxes/slabs.

For example:

CollisionSurface3D:
  kind: floor | wall | ceiling | ramp | blocker
  grid_aligned: true
  merge_group: "interior_stone"
  bounds: AABB

Then compile all compatible adjacent CollisionSurface3D nodes into fewer StaticBody3D collision shapes.

That is enough to prove the thesis.

The deeper thing

You are trying to restore the lost middle layer between:

raw geometry

and

finished game level

That middle layer used to be brushes, BSP volumes, zone portals, grid discipline, subtractive/additive forms, and strongly constrained editors.

Today, a lot of tools dropped users directly into arbitrary mesh soup.

Your instinct is to rebuild the missing ontology:

hallway
room
door
wall
floor
socket
clearance
connection
zone
surface
portal

That is exactly the right center.

The tool should not mainly help you “place assets.”

It should help you author playable architectural space.

---

I’d ship it as three layers, not one thing:

1. Godot editor plugin        ← primary authoring experience
2. Runtime support library    ← lightweight loader/types used by games
3. Optional standalone editor  ← later, if the UX outgrows Godot’s editor

Best starting form: Godot editor plugin

Start as an editor plugin.

That gives you the biggest leverage because you get Godot’s viewport, scene tree, inspector, gizmos, resources, import pipeline, undo/redo, export pipeline, and .tscn / .scn scene system for free. Godot’s plugin API is specifically meant for extending the editor with custom node/resource tooling, importers, exporters, docks, etc.  ￼

A full custom “game that is really an editor” is tempting, but it means immediately rebuilding a ton of editor infrastructure. That is death-by-tooling unless the whole product thesis is “Godot’s editor is not enough.”

For this idea, Godot’s editor is enough. The missing thing is a disciplined architectural authoring layer.

So: plugin first.

Runtime should be boring

The runtime should not be the main product.

The runtime should be a tiny library that knows how to consume compiled output:

Runtime package:
- module metadata types
- map manifest type
- compiled collision scene
- optional graph/topology data
- optional gameplay zone/query API

At runtime, the game should mostly see normal Godot scenes/resources:

res://maps/dm_foundry/compiled/dm_foundry.tscn
res://maps/dm_foundry/compiled/dm_foundry_collision.tscn
res://maps/dm_foundry/compiled/dm_foundry_nav.tres
res://maps/dm_foundry/compiled/dm_foundry_graph.tres

The game should not need your whole authoring system loaded at runtime unless it wants dynamic/procedural editing.

Product shape

I’d make the product ship as a Godot add-on:

addons/spatial_contract_mapper/
  plugin.cfg
  editor/
  runtime/
  importers/
  compilers/
  resources/
  gizmos/
  validators/

Then users install it into a Godot project.

The tool creates/uses project assets like:

res://mapkit/
  scale_profiles/
    arena_shooter_human.tres
  module_sets/
    industrial_01/
      modules/
        hallway_2m_straight.tscn
        hallway_2m_corner.tscn
        door_medium.tscn
        room_4x4.tscn
      materials/
      meshes/
      previews/
  maps/
    dm_foundry/
      source/
        dm_foundry_authoring.tscn
      compiled/
        dm_foundry_runtime.tscn
        dm_foundry_collision.tscn
        dm_foundry_graph.tres
        dm_foundry_manifest.tres

The authoring scene is full of semantic pieces.

The compiled scene is clean Godot output.

What does it ship to the final game?

For a normal game: compiled .tscn/.scn scenes plus resources.

The exported game then includes those in the normal Godot export.

A .pck is useful, but I’d think of it as a distribution/package format, not your core authoring format.

Godot exports playable builds as executable + project data, and “Export PCK/ZIP” exports only project resources, not a playable executable.  ￼ Godot also supports generating PCK files from the export UI or command line with --export-pack, and those packs can be useful for DLC/mod/resource bundles.  ￼

So the hierarchy is:

During development:
  .tscn / .tres / meshes / materials / addon resources
During normal game export:
  included automatically in the exported game data
For map packs / mods / DLC:
  export compiled maps + assets as .pck or .zip

I would not make .pck the main product artifact

.pck is too opaque for authoring.

For authoring, you want editable, diffable, inspectable project files:

.tscn
.tres
.glb
.png
.material
.json maybe

For distribution, .pck is fine.

So:

Authoring format:
  Godot project files
Exchange format:
  folder bundle or zip
Runtime/DLC format:
  .pck

The important artifact: a MapKit

The shippable thing should probably be a MapKit, not just a scene.

A MapKit contains:

Scale profile
Module library
Socket definitions
Validation rules
Compiler settings
Preview thumbnails
Example maps
Runtime support scripts

Then users make maps with that kit.

Example product SKUs, basically:

Spatial Contract Mapper - Core Plugin
Industrial Arena MapKit
Sci-Fi Facility MapKit
Dungeon Crawl MapKit
Modern Office MapKit
Retro FPS MapKit

That’s a much cleaner product shape.

The plugin is the platform.
The MapKits are the content economy.

Best architecture

I’d define four Godot resource/node concepts.

ScaleProfile

Project-level proportions.

ScaleProfile.tres
- base_grid
- major_grid
- player_height
- player_radius
- jump_height
- step_height
- hallway_widths
- door_sizes
- ceiling_classes
- allowed_angles

ModuleDefinition

The reusable piece.

ModuleDefinition.tres
- id
- scene
- footprint
- category
- sockets
- collision_contributions
- nav_contributions
- occlusion_contributions
- tags

ModuleInstance

A placed thing in the map.

ModuleInstance3D
- module_definition
- socket_connections
- transform, quantized
- local overrides

MapCompileProfile

Controls the build.

MapCompileProfile.tres
- merge_collision: true
- generate_nav_regions: true
- generate_occlusion_portals: true
- emit_graph_resource: true
- strip_authoring_helpers: true

The scene pipeline

I’d make the user work in:

dm_foundry_authoring.tscn

That contains:

MapRoot3D
  ModuleInstance3D
  ModuleInstance3D
  ModuleInstance3D
  DecorationRoot3D
  GameplayMarkers3D

Then the compiler emits:

dm_foundry_runtime.tscn

Containing:

RuntimeMap3D
  Visuals
    MultiMeshInstance3D / MeshInstance3D / instantiated scenes
  Collision
    StaticBody3D
      CollisionShape3D
      CollisionShape3D
  Navigation
    NavigationRegion3D
  Gameplay
    SpawnPoint3D
    Zone3D
    Door3D
  Metadata
    MapGraphResource

The key is that the runtime map is allowed to be ugly and optimized. The authoring map remains semantic.

Editor plugin vs standalone editor

My opinion:

Phase 1: Editor plugin
Phase 2: Editor plugin with custom main-screen workspace
Phase 3: Optional standalone app only if non-Godot users become the market

Godot editor plugins can add docks and custom editor UI; if needed, you can make a fairly opinionated workspace inside Godot.  ￼

A standalone editor only becomes worth it if you want:

engine-agnostic export
non-Godot customer base
Steam-style consumer map maker
heavily customized UX
in-app asset marketplace
runtime playtesting without exposing Godot

But for your first version? No. Stay inside Godot.

The “game that is really an editor” option

This is only compelling for a consumer-facing map maker.

Something like:

Launch app
Choose kit
Paint rooms/hallways
Hit Play
Share map

That could be awesome later.

But it is a different product. It’s not a dev tool; it’s a creation game / UGC platform.

For now, the Godot plugin gets you to truth faster.

Final answer

I’d ship:

A Godot editor plugin that authors semantic modular maps.
It produces:
- authoring scenes for editing
- compiled runtime scenes for games
- optional .pck/.zip bundles for map packs, DLC, or mods
- MapKits containing assets, modules, sockets, scale profiles, and compiler rules

The heart of it is not .pck.

The heart of it is:

authoring .tscn
→ compiler
→ runtime .tscn + optimized collision/nav/graph resources
→ optional .pck for distribution

That shape feels right. It preserves Godot-native workflows, gives you a clean runtime, and leaves room for a content marketplace later.