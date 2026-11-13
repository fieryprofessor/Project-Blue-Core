extends Node2D

@onready var start_label: Label = $CanvasLayer/StartText # Update to match your node path
var is_starting: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("start") and not is_starting:
		start_game()

func start_game() -> void:
	is_starting = true
	
	# Blink the label for 1.0 second (5 loops x 0.2s per cycle = 1.0s)
	var blink_tween = create_tween()
	blink_tween.set_loops(5)
	blink_tween.tween_property(
		start_label,
		"modulate:a",
		0.0,
		0.1
	)
	blink_tween.tween_property(
		start_label,
		"modulate:a",
		1.0,
		0.1
	)
	
	# Wait for the tween to finish its 1-second loop
	await blink_tween.finished
	
	get_tree().change_scene_to_file(
		"res://scenes/MainMenus/level_selection.tscn"
	)
