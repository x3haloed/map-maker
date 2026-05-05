@tool
class_name ModuleInstance3D
extends Node3D

@export var module_definition: ModuleDefinition:
	set(value):
		module_definition = value
		_refresh_visual()
		_refresh_socket_markers()

var _visual_instance: Node
var _socket_marker_root: Node3D
var _selected_socket_name: StringName = &""
var _compatible_socket_names: Array[StringName] = []
var _ghost_markers := false


func _ready() -> void:
	_refresh_visual()
	_refresh_socket_markers()


func get_socket_world_transform(socket_name: StringName) -> Transform3D:
	var socket := get_socket(socket_name)
	if socket == null:
		return _authoring_transform()

	return _authoring_transform() * socket.local_transform()


func get_socket(socket_name: StringName) -> ModuleSocket:
	if module_definition == null:
		return null

	return module_definition.find_socket(socket_name)


func snap_socket_to(socket_name: StringName, target: ModuleInstance3D, target_socket_name: StringName) -> void:
	var socket := get_socket(socket_name)
	var target_socket := target.get_socket(target_socket_name) if target != null else null
	if socket == null or target_socket == null:
		return

	var desired_socket_basis := target.get_socket_world_transform(target_socket_name).basis * Basis(Vector3.UP, PI)
	var desired_socket_transform := Transform3D(desired_socket_basis, target.get_socket_world_transform(target_socket_name).origin)
	_set_authoring_transform(desired_socket_transform * socket.local_transform().affine_inverse())


func connected_socket_names(compatibility: SocketCompatibility, other: ModuleInstance3D, tolerance: float = 0.01) -> Array[PackedStringArray]:
	var pairs: Array[PackedStringArray] = []
	if module_definition == null or other == null or other.module_definition == null:
		return pairs

	for socket in module_definition.sockets:
		for other_socket in other.module_definition.sockets:
			if sockets_touch(socket, other, other_socket, tolerance):
				pairs.append(PackedStringArray([socket.socket_name, other_socket.socket_name]))

	return pairs


func sockets_touch(socket: ModuleSocket, other: ModuleInstance3D, other_socket: ModuleSocket, tolerance: float = 0.01) -> bool:
	if socket == null or other == null or other_socket == null:
		return false

	var a := get_socket_world_transform(socket.socket_name)
	var b := other.get_socket_world_transform(other_socket.socket_name)
	var same_position := a.origin.distance_to(b.origin) <= tolerance
	var facing := a.basis.z.normalized().dot(b.basis.z.normalized()) <= -0.99
	return same_position and facing


func nearest_socket_to_ray(ray_origin: Vector3, ray_direction: Vector3, max_distance: float = 0.35) -> StringName:
	if module_definition == null:
		return &""

	var best_name: StringName = &""
	var best_distance := max_distance
	for socket in module_definition.sockets:
		var socket_origin := get_socket_world_transform(socket.socket_name).origin
		var distance := _point_to_ray_distance(socket_origin, ray_origin, ray_direction)
		if distance <= best_distance:
			best_distance = distance
			best_name = socket.socket_name

	return best_name


func set_socket_marker_state(selected_socket_name: StringName, compatible_socket_names: Array[StringName] = [], ghost_markers: bool = false) -> void:
	_selected_socket_name = selected_socket_name
	_compatible_socket_names = compatible_socket_names.duplicate()
	_ghost_markers = ghost_markers
	_refresh_socket_markers()


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	if _visual_instance != null:
		_visual_instance.queue_free()
		_visual_instance = null

	if module_definition == null or module_definition.scene == null:
		return

	_visual_instance = module_definition.scene.instantiate()
	add_child(_visual_instance)
	_visual_instance.owner = owner


func _refresh_socket_markers() -> void:
	if not is_inside_tree():
		return

	if _socket_marker_root != null:
		_socket_marker_root.queue_free()
		_socket_marker_root = null

	_socket_marker_root = Node3D.new()
	_socket_marker_root.name = "SocketMarkers"
	add_child(_socket_marker_root)

	if module_definition == null:
		return

	for socket in module_definition.sockets:
		var marker := _create_socket_marker(socket)
		_socket_marker_root.add_child(marker)


func _create_socket_marker(socket: ModuleSocket) -> Node3D:
	var root := Node3D.new()
	root.name = "Socket_%s" % socket.socket_name
	root.transform = socket.local_transform()
	root.scale = Vector3.ONE * _socket_marker_scale(socket.socket_name)

	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.16
	sphere_mesh.height = 0.32
	sphere.mesh = sphere_mesh
	sphere.material_override = _socket_marker_material(socket)
	root.add_child(sphere)

	var normal := MeshInstance3D.new()
	var normal_mesh := BoxMesh.new()
	normal_mesh.size = Vector3(0.08, 0.08, 0.7)
	normal.mesh = normal_mesh
	normal.position = Vector3(0, 0, -0.35)
	normal.material_override = sphere.material_override
	root.add_child(normal)

	return root


func _socket_marker_material(socket: ModuleSocket) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = _socket_color(socket)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if material.albedo_color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _socket_color(socket: ModuleSocket) -> Color:
	if socket.socket_name == _selected_socket_name:
		return Color(1.0, 0.25, 0.55, 1.0)
	if socket.socket_name in _compatible_socket_names:
		return Color(0.25, 1.0, 0.3, 0.95)
	if _compatible_socket_names.size() > 0:
		return Color(0.45, 0.45, 0.45, 0.35)
	if _ghost_markers:
		return Color(0.7, 0.9, 1.0, 0.45)

	var socket_type := socket.socket_type
	if String(socket_type).begins_with("room."):
		return Color(0.2, 0.7, 1.0, 0.85)
	if String(socket_type).begins_with("hallway."):
		return Color(0.2, 1.0, 0.55, 0.85)
	if String(socket_type).begins_with("doorway."):
		return Color(1.0, 0.75, 0.2, 0.85)
	return Color(1.0, 1.0, 1.0, 0.85)


func _socket_marker_scale(socket_name: StringName) -> float:
	if _ghost_markers:
		return 0.75
	if socket_name == _selected_socket_name:
		return 1.35
	if _compatible_socket_names.size() > 0 and not socket_name in _compatible_socket_names:
		return 0.75
	return 1.0


func _point_to_ray_distance(point: Vector3, ray_origin: Vector3, ray_direction: Vector3) -> float:
	var normalized_direction := ray_direction.normalized()
	var projected_length := maxf(0.0, (point - ray_origin).dot(normalized_direction))
	var closest_point := ray_origin + normalized_direction * projected_length
	return point.distance_to(closest_point)


func _authoring_transform() -> Transform3D:
	return global_transform if is_inside_tree() else transform


func _set_authoring_transform(value: Transform3D) -> void:
	if is_inside_tree():
		global_transform = value
	else:
		transform = value
