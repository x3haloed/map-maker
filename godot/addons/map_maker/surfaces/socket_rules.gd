@tool
class_name SocketRules
extends RefCounted


static func default_compatibility() -> SocketCompatibility:
	var compatibility := SocketCompatibility.new()
	compatibility.compatible_types = {
		&"doorway.medium": PackedStringArray(["hallway.medium", "room.edge.medium"]),
		&"hallway.medium": PackedStringArray(["doorway.medium", "room.edge.medium"]),
		&"room.edge.medium": PackedStringArray(["doorway.medium", "hallway.medium"]),
	}
	return compatibility
