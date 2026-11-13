extends Node2D

@export var camera_smooth_speed: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var rooms: Node2D = $"../LevelRooms"

var player: CharacterBody2D
var current_room: Area2D

var initial_camera_position_set: bool = false
var camera_transitioning: bool = false
var target_camera_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.make_current()
	print("WorldCameraController initialized.")
	print("Number of rooms: ", rooms.get_child_count())


func _process(delta: float) -> void:
	# Find the dynamically spawned player.
	if not is_instance_valid(player):
		player = _find_player()

	if not is_instance_valid(player):
		return

	# Find the room containing the player.
	var detected_room = _find_room_at_position(
		player.global_position
	)

	# Detect a room change.
	if detected_room != null and detected_room != current_room:
		current_room = detected_room

		print("Current room: ", current_room.name)

		# Calculate the camera's destination.
		target_camera_position = _get_camera_target()

		# Pause the world only if a transition is necessary.
		if initial_camera_position_set:
			if not global_position.is_equal_approx(
				target_camera_position
			):
				camera_transitioning = true
				get_tree().paused = true

	# Ensure a room has been detected.
	if not is_instance_valid(current_room):
		return

	# Initialize the camera's position.
	if not initial_camera_position_set:
		global_position = _get_camera_target()
		initial_camera_position_set = true

		print("Initial camera position: ", global_position)
		return

	var weight = 1.0 - exp(-camera_smooth_speed * delta)
	
	# Transition between rooms while the world is paused.
	if camera_transitioning:
		global_position = global_position.lerp(
			target_camera_position,
			weight
		)

		# Finish the transition.
		if global_position.distance_to(
			target_camera_position
		) < 0.5:
			global_position = target_camera_position

			camera_transitioning = false

			# Resume the entire world.
			get_tree().paused = false

		return

	# Normal camera following.
	var target_position = _get_camera_target()

	global_position = global_position.lerp(
		target_position,
		weight
	)


func _find_player() -> CharacterBody2D:
	# The spawned player is expected to be a direct child
	# of the stage, regardless of its node name.
	var stage = get_parent()

	for child in stage.get_children():
		if child is CharacterBody2D:
			print("Player detected: ", child.name)
			return child as CharacterBody2D

	return null


func _find_room_at_position(
	world_position: Vector2
) -> Area2D:

	for room in rooms.get_children():
		if not room is Area2D:
			continue

		var bounds = _get_room_bounds(room)

		if bounds.size == Vector2.ZERO:
			continue

		if bounds.has_point(world_position):
			return room as Area2D

	return null


func _get_camera_target() -> Vector2:
	var bounds = _get_room_bounds(current_room)

	if bounds.size == Vector2.ZERO:
		return global_position

	var viewport_size = get_viewport_rect().size
	var half_view_size = viewport_size / (2.0 * camera.zoom)

	var target = player.global_position

	target.x = _clamp_camera_axis(
		target.x,
		bounds.position.x,
		bounds.end.x,
		half_view_size.x
	)

	target.y = _clamp_camera_axis(
		target.y,
		bounds.position.y,
		bounds.end.y,
		half_view_size.y
	)

	return target


func _get_room_bounds(room: Area2D) -> Rect2:
	var collision_shape = room.get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision_shape == null:
		return Rect2()

	if not collision_shape.shape is RectangleShape2D:
		return Rect2()

	var rectangle = collision_shape.shape as RectangleShape2D

	var room_size = (
		rectangle.size * collision_shape.global_scale.abs()
	)

	var room_center = collision_shape.global_position

	return Rect2(
		room_center - room_size / 2.0,
		room_size
	)


func _clamp_camera_axis(
	target: float,
	room_start: float,
	room_end: float,
	half_view: float
) -> float:

	var minimum = room_start + half_view
	var maximum = room_end - half_view

	# Center the camera if the room is smaller than the viewport.
	if minimum > maximum:
		return (room_start + room_end) / 2.0

	return clampf(target, minimum, maximum)
