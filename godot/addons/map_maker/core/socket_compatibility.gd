@tool
class_name SocketCompatibility
extends Resource

@export var compatible_types: Dictionary = {}


func allows(type_a: StringName, type_b: StringName) -> bool:
	if type_a == type_b:
		return true

	return _entry_allows(type_a, type_b) or _entry_allows(type_b, type_a)


func _entry_allows(source: StringName, target: StringName) -> bool:
	if not compatible_types.has(source):
		return false

	var targets = compatible_types[source]
	if targets is PackedStringArray:
		return String(target) in targets
	if targets is Array:
		return target in targets or String(target) in targets

	return false
