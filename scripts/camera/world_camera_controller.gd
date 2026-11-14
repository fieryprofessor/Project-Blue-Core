extends Node2D

@export var camera_smooth_speed: float = 4.0

@onready var camera: Camera2D = $Camera2D
@onready var rooms: Node2D = $"../LevelRooms"

var player: CharacterBody2D
var current_room: Area2D

var initial_camera_position_set: bool = false
var camera_transitioning: bool = false
var target_camera_position: Vector2 = Vector2.ZERO
var camera_following_enabled: bool = false
var intro_camera_transition: bool = false
var horizontal_only_rooms: Array[String] = []
var vertical_only_rooms: Array[String] = []

func set_room_movement_modes(
	horizontal_rooms: Array[String],
	vertical_rooms: Array[String]
) -> void:
	horizontal_only_rooms = horizontal_rooms.duplicate()
	vertical_only_rooms = vertical_rooms.duplicate()

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

	# Wait until the player's intro sequence finishes.
	if player.get("current_state") != "PLAY":
		return

	# Find the room containing the player.
	var detected_room = _find_room_at_position(
		player.global_position
	)

	if detected_room == null:
		return

	# Initialize the camera when gameplay begins.
	if not initial_camera_position_set:
		current_room = detected_room

		target_camera_position = _get_camera_target()

		initial_camera_position_set = true
		intro_camera_transition = true

		print("Starting smooth camera transition.")
		return

	# Detect a room change.
	if detected_room != current_room:
		current_room = detected_room

		print("Current room: ", current_room.name)

		target_camera_position = _get_camera_target()

		if not global_position.is_equal_approx(
			target_camera_position
		):
			camera_transitioning = true
			get_tree().paused = true

	# Calculate smooth movement.
	var weight = 1.0 - exp(-camera_smooth_speed * delta)

	# Smoothly transition from the initial camera position.
	if intro_camera_transition:
		# Update the target as the player moves.
		target_camera_position = _get_camera_target()

		global_position = global_position.lerp(
			target_camera_position,
			weight
		)

		if global_position.distance_to(
			target_camera_position
		) < 0.5:
			global_position = target_camera_position
			intro_camera_transition = false

			print("Initial camera transition complete.")

		return

	# Transition between rooms while the world is paused.
	if camera_transitioning:
		global_position = global_position.lerp(
			target_camera_position,
			weight
		)

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
	return get_tree().get_first_node_in_group("player") as CharacterBody2D



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

	var viewport_size = camera.get_viewport_rect().size

	var half_view_size = Vector2(
		viewport_size.x / (2.0 * camera.zoom.x),
		viewport_size.y / (2.0 * camera.zoom.y)
	)

	var room_name = current_room.name

	var target = player.global_position

	if horizontal_only_rooms.has(room_name):
		# Follow horizontally and keep the camera vertically centered.
		target.x = _clamp_camera_axis(
			target.x,
			bounds.position.x,
			bounds.end.x,
			half_view_size.x
		)

		target.y = _clamp_camera_axis(
			(bounds.position.y + bounds.end.y) / 2.0,
			bounds.position.y,
			bounds.end.y,
			half_view_size.y
		)

	elif vertical_only_rooms.has(room_name):
		# Follow vertically and keep the camera horizontally centered.
		target.x = _clamp_camera_axis(
			(bounds.position.x + bounds.end.x) / 2.0,
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

	else:
		# Normal room: follow both axes.
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
	var room_size = rectangle.size * collision_shape.global_scale.abs()
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

	var room_size = room_end - room_start

	# If the room is smaller than the camera view,
	# center the camera on the room.
	if room_size <= half_view * 2.0:
		return (room_start + room_end) / 2.0

	var minimum = room_start + half_view
	var maximum = room_end - half_view

	return clampf(target, minimum, maximum)
