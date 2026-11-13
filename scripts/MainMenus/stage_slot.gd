extends Node2D

@export_file("*.tscn") var stage_scene_path: String

@onready var border_frame: AnimatedSprite2D = $BorderFrame

func _ready() -> void:
	set_selected(false)

func set_selected(is_selected: bool) -> void:
	if is_selected:
		border_frame.play("selected")
	else:
		border_frame.play("not_selected")
