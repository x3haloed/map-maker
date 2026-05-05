@tool
class_name ModuleSocket
extends Resource

@export var socket_name: StringName = &"socket"
@export var socket_type: StringName = &"doorway.medium"
@export var local_position: Vector3 = Vector3.ZERO
@export var local_rotation_degrees: Vector3 = Vector3.ZERO
@export var width: float = 2.0
@export var height: float = 2.5
@export var required: bool = false
@export var tags: PackedStringArray = []


func local_transform() -> Transform3D:
	var basis := Basis.from_euler(local_rotation_degrees * TAU / 360.0)
	return Transform3D(basis, local_position)


func forward() -> Vector3:
	return -local_transform().basis.z.normalized()
