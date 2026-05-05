@tool
class_name ModuleDefinition
extends Resource

@export var module_id: StringName = &"Module"
@export var display_name: String = "Module"
@export var category: StringName = &"blockout"
@export var footprint_cells: Vector3i = Vector3i.ONE
@export var cell_size: Vector3 = Vector3(2.0, 4.0, 2.0)
@export var scene: PackedScene
@export var sockets: Array[ModuleSocket] = []
@export var tags: PackedStringArray = []


func footprint_size() -> Vector3:
	return Vector3(footprint_cells) * cell_size


func find_socket(socket_name: StringName) -> ModuleSocket:
	for socket in sockets:
		if socket != null and socket.socket_name == socket_name:
			return socket
	return null
