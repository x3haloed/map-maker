# Map Maker Godot Architecture

The first MVP slice is intentionally small: prove that semantic modules can snap together in Godot and be validated without turning the project into a pile of premature systems.

## Core

Core scripts live under `res://addons/map_maker/core`.

- `ScaleProfile` stores grid, yaw, and player-scale measurements.
- `ModuleSocket` stores an oriented local connection point.
- `ModuleDefinition` stores module size, socket list, and compatibility-facing metadata.
- `SocketCompatibility` answers whether two socket types may connect.
- `ValidationIssue` is the plain data result emitted by validation.

Core code should be deterministic and mostly side-effect free.

## Nodes

`res://addons/map_maker/nodes/module_instance_3d.gd` is the authoring node placed in maps. It owns scene-facing behavior such as computing world socket transforms and applying snap transforms.

## Surfaces

`res://addons/map_maker/surfaces` contains rule-shaped extension points:

- `socket_rules.gd` for default compatibility tables.
- `validation_rules.gd` for lightweight MVP validation.

Future agents should usually extend these files before creating new concepts.

## Edges

`res://addons/map_maker/editor` and `map_maker_plugin.gd` are Godot editor edges. They may touch the editor UI, selection, resources, and scene tree.

The future map compiler is also an edge. Do not add compiler classes until the MVP has real authoring scenes that need compiled runtime output.
