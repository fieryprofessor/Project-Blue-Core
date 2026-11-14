extends Node2D

const PLAYER = preload("res://scenes/player/player.tscn")

@export var player_spawn_position: Vector2 = Vector2(139, 20)
@export var intro_landing_position: Vector2 = Vector2(139, 144)
@onready var ready_text: Label = $CanvasLayer/ReadyText
@onready var cut_level_music: AudioStreamPlayer2D = $CutManStageMusic
@onready var world_camera_controller: Node2D = $WorldCameraController

@export var horizontal_only_rooms: Array[String] = []
@export var vertical_only_rooms: Array[String] = []

func _ready() -> void:
	cut_level_music.play()
	
	# Pass the camera movement configuration to the controller.
	world_camera_controller.set_room_movement_modes(
		horizontal_only_rooms,
		vertical_only_rooms
	)
	
	# Display READY! before the player spawns.
	ready_text.visible = true

	# Blink the text for 2 seconds.
	var blink_tween = create_tween()
	blink_tween.set_loops(4)
	blink_tween.tween_property(
		ready_text,
		"modulate:a",
		0.0,
		0.5
	)
	blink_tween.tween_property(
		ready_text,
		"modulate:a",
		1.0,
		0.5
	)
	# Wait for the initial 2 seconds.
	await get_tree().create_timer(2.0).timeout
	
	# Remove READY! when the timer finishes.
	ready_text.visible = false
	
	var player = PLAYER.instantiate()
	player.global_position = player_spawn_position
	player.intro_landing_position = intro_landing_position
	add_child(player)
