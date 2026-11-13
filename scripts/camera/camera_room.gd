extends Area2D

@export_group("Camera Region")

@export var camera_region_size: Vector2 = Vector2(384, 216)

@export var camera_offset: Vector2 = Vector2.ZERO

@export_group("Camera Behavior")

@export var follow_player: bool = true

@export var camera_zoom: Vector2 = Vector2(3, 3)


func get_camera_bounds() -> Rect2:
	var region_center = global_position + camera_offset

	return Rect2(
		region_center - camera_region_size / 2.0,
		camera_region_size
	)
