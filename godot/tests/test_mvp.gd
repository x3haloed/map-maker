extends SceneTree

const ModuleInstanceScript := preload("res://addons/map_maker/nodes/module_instance_3d.gd")
const ScaleProfileScript := preload("res://addons/map_maker/core/scale_profile.gd")
const SocketRulesScript := preload("res://addons/map_maker/surfaces/socket_rules.gd")
const ValidationRulesScript := preload("res://addons/map_maker/surfaces/validation_rules.gd")


func _initialize() -> void:
	var failures: Array[String] = []

	_test_socket_compatibility(failures)
	_test_socket_snap(failures)
	_test_validation(failures)
	_test_example_resources(failures)
	_test_example_scene(failures)

	if failures.is_empty():
		print("Map Maker MVP tests passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_socket_compatibility(failures: Array[String]) -> void:
	var compatibility := SocketRulesScript.default_compatibility()
	_expect(compatibility.allows(&"doorway.medium", &"hallway.medium"), "doorways should connect to hallways", failures)
	_expect(not compatibility.allows(&"doorway.medium", &"pipe.small"), "doorways should reject unrelated sockets", failures)


func _test_socket_snap(failures: Array[String]) -> void:
	var room_definition: ModuleDefinition = load("res://addons/map_maker/examples/modules/room_small.tres")
	var hallway_definition: ModuleDefinition = load("res://addons/map_maker/examples/modules/hallway_medium.tres")
	var room: ModuleInstance3D = ModuleInstanceScript.new()
	var hallway: ModuleInstance3D = ModuleInstanceScript.new()
	room.module_definition = room_definition
	hallway.module_definition = hallway_definition

	hallway.snap_socket_to(&"south", room, &"north")

	var room_socket := room.get_socket_world_transform(&"north")
	var hallway_socket := hallway.get_socket_world_transform(&"south")
	_expect(room_socket.origin.distance_to(hallway_socket.origin) < 0.001, "snapped sockets should share a position", failures)
	_expect(room_socket.basis.z.normalized().dot(hallway_socket.basis.z.normalized()) < -0.99, "snapped sockets should face each other", failures)

	room.free()
	hallway.free()


func _test_validation(failures: Array[String]) -> void:
	var room_definition: ModuleDefinition = load("res://addons/map_maker/examples/modules/room_small.tres")
	var room_a: ModuleInstance3D = ModuleInstanceScript.new()
	var room_b: ModuleInstance3D = ModuleInstanceScript.new()
	room_a.name = "RoomA"
	room_b.name = "RoomB"
	room_a.module_definition = room_definition
	room_b.module_definition = room_definition
	room_b.position = Vector3(1, 0, 0)

	var instances: Array[ModuleInstance3D] = [room_a, room_b]
	var issues := ValidationRulesScript.validate_instances(instances, ScaleProfileScript.new(), SocketRulesScript.default_compatibility())
	var has_overlap := false
	for issue in issues:
		if issue.code == &"module.overlapping_footprint":
			has_overlap = true
			break

	_expect(has_overlap, "overlapping footprints should be reported", failures)

	room_a.free()
	room_b.free()


func _test_example_resources(failures: Array[String]) -> void:
	var scale = load("res://addons/map_maker/examples/arena_shooter_human.tres")
	var room = load("res://addons/map_maker/examples/modules/room_small.tres")
	var hallway = load("res://addons/map_maker/examples/modules/hallway_medium.tres")
	_expect(scale is ScaleProfile, "example scale profile should load", failures)
	_expect(room is ModuleDefinition, "example room definition should load", failures)
	_expect(hallway is ModuleDefinition, "example hallway definition should load", failures)


func _test_example_scene(failures: Array[String]) -> void:
	var scene: PackedScene = load("res://addons/map_maker/examples/socket_authoring_example.tscn")
	_expect(scene is PackedScene, "example authoring scene should load", failures)
	if scene == null:
		return

	var root := scene.instantiate()
	var instances: Array[ModuleInstance3D] = []
	_collect_module_instances(root, instances)
	_expect(instances.size() == 2, "example authoring scene should contain two module instances", failures)
	root.free()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _collect_module_instances(node: Node, instances: Array[ModuleInstance3D]) -> void:
	if node is ModuleInstance3D:
		instances.append(node)

	for child in node.get_children():
		_collect_module_instances(child, instances)
