@tool
class_name ScaleProfile
extends Resource

@export var profile_name: StringName = &"ArenaShooterHuman"
@export var base_grid: float = 0.5
@export var major_grid: float = 2.0
@export var allowed_yaw_degrees: PackedFloat32Array = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]

@export_group("Player")
@export var player_height: float = 1.8
@export var player_radius: float = 0.4
@export var camera_height: float = 1.65
@export var jump_height: float = 1.2
@export var step_height: float = 0.35

@export_group("Architecture")
@export var door_width: float = 2.0
@export var door_height: float = 2.5
@export var hallway_width: float = 3.0
@export var ceiling_standard: float = 4.0


func snap_position(value: Vector3) -> Vector3:
	return Vector3(
		snappedf(value.x, base_grid),
		snappedf(value.y, base_grid),
		snappedf(value.z, base_grid)
	)


func is_position_on_grid(value: Vector3, tolerance: float = 0.001) -> bool:
	return value.distance_to(snap_position(value)) <= tolerance


func nearest_allowed_yaw(yaw_degrees: float) -> float:
	if allowed_yaw_degrees.is_empty():
		return snappedf(yaw_degrees, 90.0)

	var normalized := fposmod(yaw_degrees, 360.0)
	var best := allowed_yaw_degrees[0]
	var best_delta := 360.0

	for candidate in allowed_yaw_degrees:
		var delta := abs(angle_difference(deg_to_rad(normalized), deg_to_rad(candidate)))
		if delta < best_delta:
			best_delta = delta
			best = candidate

	return best


func is_yaw_allowed(yaw_degrees: float, tolerance_degrees: float = 0.01) -> bool:
	var delta := abs(angle_difference(deg_to_rad(yaw_degrees), deg_to_rad(nearest_allowed_yaw(yaw_degrees))))
	return rad_to_deg(delta) <= tolerance_degrees
