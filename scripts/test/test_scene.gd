extends Node2D

const PLAYER = preload("res://scenes/player/player.tscn")
@export var player_spawn_position: Vector2 = Vector2(20, 20)
@export var intro_landing_position: Vector2 = Vector2(20, 172)

func _ready() -> void:

	var player = PLAYER.instantiate()
	player.global_position = player_spawn_position
	player.intro_landing_position = intro_landing_position
	add_child(player)
