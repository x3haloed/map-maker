@tool
class_name ValidationRules
extends RefCounted


static func validate_instances(instances: Array[ModuleInstance3D], scale_profile: ScaleProfile, compatibility: SocketCompatibility) -> Array[ValidationIssue]:
	var issues: Array[ValidationIssue] = []

	for instance in instances:
		issues.append_array(validate_instance(instance, scale_profile))

	for index in range(instances.size()):
		for other_index in range(index + 1, instances.size()):
			issues.append_array(validate_pair(instances[index], instances[other_index], compatibility))
			issues.append_array(validate_footprints(instances[index], instances[other_index]))

	return issues


static func validate_instance(instance: ModuleInstance3D, scale_profile: ScaleProfile) -> Array[ValidationIssue]:
	var issues: Array[ValidationIssue] = []
	if instance == null:
		return issues

	if instance.module_definition == null:
		issues.append(ValidationIssue.error(&"module.missing_definition", "Module instance has no module definition.", _node_path(instance)))
		return issues

	if scale_profile != null:
		var position := instance.global_position if instance.is_inside_tree() else instance.position
		var rotation := instance.global_rotation if instance.is_inside_tree() else instance.rotation

		if not scale_profile.is_position_on_grid(position):
			issues.append(ValidationIssue.error(&"module.off_grid", "%s is off the scale grid." % instance.name, _node_path(instance)))

		var yaw := rad_to_deg(rotation.y)
		if not scale_profile.is_yaw_allowed(yaw):
			issues.append(ValidationIssue.error(&"module.invalid_yaw", "%s uses a yaw outside the scale profile." % instance.name, _node_path(instance)))

		for socket in instance.module_definition.sockets:
			var socket_position := instance.get_socket_world_transform(socket.socket_name).origin
			if not scale_profile.is_position_on_grid(socket_position):
				issues.append(ValidationIssue.error(&"socket.off_grid", "%s socket %s is off the scale grid." % [instance.name, socket.socket_name], _node_path(instance)))

	return issues


static func validate_pair(a: ModuleInstance3D, b: ModuleInstance3D, compatibility: SocketCompatibility) -> Array[ValidationIssue]:
	var issues: Array[ValidationIssue] = []
	if a == null or b == null or compatibility == null:
		return issues

	if a.module_definition == null or b.module_definition == null:
		return issues

	var pairs := a.connected_socket_names(compatibility, b)
	for pair in pairs:
		var socket_a := a.get_socket(pair[0])
		var socket_b := b.get_socket(pair[1])
		if socket_a != null and socket_b != null and not compatibility.allows(socket_a.socket_type, socket_b.socket_type):
			issues.append(ValidationIssue.error(&"socket.incompatible", "%s:%s is incompatible with %s:%s." % [a.name, socket_a.socket_name, b.name, socket_b.socket_name], _node_path(a)))

	return issues


static func validate_footprints(a: ModuleInstance3D, b: ModuleInstance3D) -> Array[ValidationIssue]:
	var issues: Array[ValidationIssue] = []
	if a == null or b == null:
		return issues

	if a.module_definition == null or b.module_definition == null:
		return issues

	var a_size := a.module_definition.footprint_size()
	var b_size := b.module_definition.footprint_size()
	var a_position := a.global_position if a.is_inside_tree() else a.position
	var b_position := b.global_position if b.is_inside_tree() else b.position
	var a_min := a_position - a_size * 0.5
	var a_max := a_position + a_size * 0.5
	var b_min := b_position - b_size * 0.5
	var b_max := b_position + b_size * 0.5

	var overlaps_x := a_min.x < b_max.x and a_max.x > b_min.x
	var overlaps_y := a_min.y < b_max.y and a_max.y > b_min.y
	var overlaps_z := a_min.z < b_max.z and a_max.z > b_min.z

	if overlaps_x and overlaps_y and overlaps_z:
		issues.append(ValidationIssue.error(&"module.overlapping_footprint", "%s overlaps %s." % [a.name, b.name], _node_path(a)))

	return issues


static func _node_path(node: Node) -> NodePath:
	return node.get_path() if node != null and node.is_inside_tree() else NodePath()
