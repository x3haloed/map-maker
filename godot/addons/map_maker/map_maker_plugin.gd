@tool
extends EditorPlugin

const ModulePaletteDockScene := preload("res://addons/map_maker/editor/module_palette_dock.gd")
const ModuleInstanceScript := preload("res://addons/map_maker/nodes/module_instance_3d.gd")
const ValidationRulesScript := preload("res://addons/map_maker/surfaces/validation_rules.gd")
const SocketRulesScript := preload("res://addons/map_maker/surfaces/socket_rules.gd")
const ScaleProfileScript := preload("res://addons/map_maker/core/scale_profile.gd")

var _dock: ModulePaletteDock
var _compatibility: SocketCompatibility
var _ghost_instance: ModuleInstance3D


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
	_compatibility = SocketRulesScript.default_compatibility()

	add_custom_type("ModuleInstance3D", "Node3D", ModuleInstanceScript, null)

	_dock = ModulePaletteDockScene.new()
	_dock.set_socket_compatibility(_compatibility)
	_dock.validate_requested.connect(_validate_edited_scene)
	_dock.create_requested.connect(_create_module_instance)
	_dock.attach_requested.connect(_attach_module_instance)
	_dock.authoring_state_changed.connect(_refresh_authoring_preview)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)

	get_editor_interface().get_selection().selection_changed.connect(_refresh_selected_instance)
	_refresh_selected_instance()


func _exit_tree() -> void:
	_clear_ghost_preview()

	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null

	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_refresh_selected_instance):
		selection.selection_changed.disconnect(_refresh_selected_instance)

	remove_custom_type("ModuleInstance3D")


func _validate_edited_scene() -> void:
	_clear_ghost_preview()

	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_warning("Map Maker: no edited scene to validate.")
		return

	var instances: Array[ModuleInstance3D] = []
	_collect_module_instances(root, instances)
	var issues := ValidationRulesScript.validate_instances(instances, ScaleProfileScript.new(), _compatibility)
	_dock.set_validation_results(issues, instances.size())

	if issues.is_empty():
		print("Map Maker: validation passed for %d module instance(s)." % instances.size())
		return

	for issue in issues:
		var severity := "warning" if issue.severity == ValidationIssue.Severity.WARNING else "error"
		print("Map Maker %s [%s]: %s" % [severity, issue.code, issue.message])


func _collect_module_instances(node: Node, instances: Array[ModuleInstance3D]) -> void:
	if node is ModuleInstance3D and not node.has_meta("map_maker_preview"):
		instances.append(node)

	for child in node.get_children():
		_collect_module_instances(child, instances)


func _refresh_selected_instance() -> void:
	if _dock == null:
		return

	_dock.set_selected_instance(_selected_module_instance())
	_refresh_authoring_preview()


func _selected_module_instance() -> ModuleInstance3D:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	for node in selected_nodes:
		if node is ModuleInstance3D:
			return node
	return null


func _create_module_instance(module_path: String) -> void:
	_clear_ghost_preview()

	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_warning("Map Maker: create a scene before adding modules.")
		return

	var module_definition: ModuleDefinition = load(module_path)
	if module_definition == null:
		push_warning("Map Maker: could not load module definition: %s" % module_path)
		return

	var instance: ModuleInstance3D = ModuleInstanceScript.new()
	instance.name = _unique_child_name(root, String(module_definition.module_id))
	instance.module_definition = module_definition

	var undo := get_undo_redo()
	undo.create_action("Create Map Maker Module")
	undo.add_do_method(root, "add_child", instance)
	undo.add_do_method(instance, "set_owner", root)
	undo.add_undo_method(root, "remove_child", instance)
	undo.commit_action()

	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(instance)
	_refresh_selected_instance()


func _attach_module_instance(module_path: String, new_socket_name: StringName, target_socket_name: StringName) -> void:
	_clear_ghost_preview()

	var target := _selected_module_instance()
	var root := get_editor_interface().get_edited_scene_root()
	if root == null or target == null:
		push_warning("Map Maker: select a ModuleInstance3D before attaching.")
		return

	var module_definition: ModuleDefinition = load(module_path)
	if module_definition == null:
		push_warning("Map Maker: could not load module definition: %s" % module_path)
		return

	var target_socket := target.get_socket(target_socket_name)
	var new_socket := module_definition.find_socket(new_socket_name)
	if target_socket == null or new_socket == null:
		push_warning("Map Maker: could not find one of the selected sockets.")
		return

	if not _compatibility.allows(new_socket.socket_type, target_socket.socket_type):
		push_warning("Map Maker: %s cannot connect to %s." % [new_socket.socket_type, target_socket.socket_type])
		return

	var new_instance: ModuleInstance3D = ModuleInstanceScript.new()
	new_instance.name = _unique_child_name(root, String(module_definition.module_id))
	new_instance.module_definition = module_definition
	new_instance.snap_socket_to(new_socket_name, target, target_socket_name)

	var undo := get_undo_redo()
	undo.create_action("Attach Map Maker Module")
	undo.add_do_method(root, "add_child", new_instance)
	undo.add_do_method(new_instance, "set_owner", root)
	undo.add_undo_method(root, "remove_child", new_instance)
	undo.commit_action()

	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(new_instance)
	_refresh_selected_instance()


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _pick_socket_from_viewport(viewport_camera, mouse_event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _pick_socket_from_viewport(viewport_camera: Camera3D, screen_position: Vector2) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return false

	var ray_origin := viewport_camera.project_ray_origin(screen_position)
	var ray_direction := viewport_camera.project_ray_normal(screen_position)
	var instances: Array[ModuleInstance3D] = []
	_collect_module_instances(root, instances)

	var best_instance: ModuleInstance3D
	var best_socket: StringName = &""
	var best_distance := 0.45

	for instance in instances:
		var socket_name := instance.nearest_socket_to_ray(ray_origin, ray_direction, best_distance)
		if socket_name == &"":
			continue

		var socket_origin := instance.get_socket_world_transform(socket_name).origin
		var distance := _point_to_ray_distance(socket_origin, ray_origin, ray_direction)
		if distance <= best_distance:
			best_distance = distance
			best_instance = instance
			best_socket = socket_name

	if best_instance == null or best_socket == &"":
		return false

	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(best_instance)
	_dock.set_selected_instance(best_instance)
	_dock.pick_target_socket(best_socket)
	_refresh_authoring_preview()
	return true


func _refresh_authoring_preview() -> void:
	if _dock == null:
		return

	_clear_ghost_preview()
	_update_socket_marker_states()

	var root := get_editor_interface().get_edited_scene_root()
	var target := _selected_module_instance()
	if root == null or target == null:
		return

	var module_path := _dock.selected_module_path()
	var target_socket_name := _dock.selected_target_socket_name()
	var new_socket_name := _dock.selected_new_socket_name()
	if module_path == "" or target_socket_name == &"" or new_socket_name == &"":
		return

	var target_socket := target.get_socket(target_socket_name)
	var module_definition: ModuleDefinition = load(module_path)
	var new_socket := module_definition.find_socket(new_socket_name) if module_definition != null else null
	if target_socket == null or module_definition == null or new_socket == null:
		return

	if not _compatibility.allows(new_socket.socket_type, target_socket.socket_type):
		return

	_ghost_instance = ModuleInstanceScript.new()
	_ghost_instance.name = "__MapMakerPreview"
	_ghost_instance.set_meta("map_maker_preview", true)
	_ghost_instance.module_definition = module_definition
	_ghost_instance.snap_socket_to(new_socket_name, target, target_socket_name)
	_ghost_instance.set_socket_marker_state(new_socket_name, [], true)
	root.add_child(_ghost_instance)
	_ghost_instance.owner = null
	_ghost_instance.set_socket_marker_state(new_socket_name, [], true)


func _clear_ghost_preview() -> void:
	if _ghost_instance == null:
		return

	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
	_ghost_instance = null


func _update_socket_marker_states() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return

	var instances: Array[ModuleInstance3D] = []
	_collect_module_instances(root, instances)
	var selected := _selected_module_instance()
	var selected_socket := _dock.selected_target_socket_name() if _dock != null else &""

	for instance in instances:
		if instance == selected:
			instance.set_socket_marker_state(selected_socket)
		else:
			instance.set_socket_marker_state(&"")


func _point_to_ray_distance(point: Vector3, ray_origin: Vector3, ray_direction: Vector3) -> float:
	var normalized_direction := ray_direction.normalized()
	var projected_length := maxf(0.0, (point - ray_origin).dot(normalized_direction))
	var closest_point := ray_origin + normalized_direction * projected_length
	return point.distance_to(closest_point)


func _unique_child_name(parent: Node, base_name: String) -> String:
	var clean_name := base_name if base_name != "" else "ModuleInstance3D"
	var candidate := clean_name
	var suffix := 2
	while parent.has_node(NodePath(candidate)):
		candidate = "%s_%d" % [clean_name, suffix]
		suffix += 1
	return candidate
