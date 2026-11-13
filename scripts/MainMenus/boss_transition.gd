extends Control
class_name BossTransition

static var selected_boss_scene: PackedScene
static var selected_stage_path: String
static var selected_boss_index: int = 0

@export var boss_display_duration: float = 6.0
@export var fade_duration: float = 0.5

@onready var background: ColorRect = $Background
@onready var color_box: ColorRect = $ColorBox
@onready var boss_container: Node2D = $BossContainer
@onready var boss_name_label: Label = $BossName

@export var color_box_color_1: Color = Color(0.0, 0.15, 0.0)
@export var color_box_color_2: Color = Color(0.0, 0.25, 0.05)
@export var color_box_flash_duration: float = 0.3

@onready var stage_chosen: AudioStreamPlayer2D = $StageChosen

var background_flash_tween: Tween
var boss_name: String
@export var typing_speed: float = 0.2

func _type_boss_name() -> void:
	boss_name_label.text = ""
	
	for i in range(boss_name.length()):
		boss_name_label.text += boss_name[i]
		await get_tree().create_timer(typing_speed).timeout

func _flash_background() -> void:
	background_flash_tween = create_tween()
	background_flash_tween.set_loops()

	background_flash_tween.tween_property(
		color_box,
		"color",
		color_box_color_2,
		color_box_flash_duration
	)

	background_flash_tween.tween_property(
		color_box,
		"color",
		color_box_color_1,
		color_box_flash_duration
	)


func _ready() -> void:
	background.modulate.a = 0.0
	boss_container.modulate.a = 0.0
	color_box.color = color_box_color_1
	stage_chosen.play()
	_display_boss()


func _display_boss() -> void:
	if selected_boss_scene == null:
		push_error("No Robot Master scene selected!")
		return

	if selected_stage_path.is_empty():
		push_error("No stage scene selected!")
		return

	# Instantiate the selected boss.
	var boss = selected_boss_scene.instantiate()
	boss_container.add_child(boss)

	if boss is Node2D:
		boss.position = Vector2.ZERO

	# Configure the boss's idle animation and orientation.
	var boss_sprite = boss.get_node_or_null("AnimatedSprite2D")

	if boss_sprite is AnimatedSprite2D:
		boss_sprite.scale = Vector2(4.0, 4.0)

		match selected_boss_index:
			0:
				boss_sprite.flip_h = true
				boss_sprite.play("cut_idle_cutter")
				boss_name = "CUTMAN"

			1:
				boss_sprite.flip_h = true
				boss_sprite.play("idle")
				boss_name = "GUTSMAN"

			2:
				boss_sprite.flip_h = true
				boss_sprite.play("pose")
				boss_name = "ICEMAN"

			3:
				boss_sprite.flip_h = true
				boss_sprite.play("pose")
				boss_name = "BOMBMAN"

			4:
				boss_sprite.flip_h = true
				boss_sprite.play("pose")
				boss_name = "FIREMAN"

			5:
				boss_sprite.flip_h = true
				boss_sprite.play("pose")
				boss_name = "ELECMAN"

			_:
				push_error("Invalid boss index: " + str(selected_boss_index))
				return
	else:
		push_error("AnimatedSprite2D not found directly under the boss root!")
		return

	# Set the boss name and initial ColorBox color.
	boss_name_label.text = ""
	color_box.color = color_box_color_1

	# Flash the ColorBox and type the boss name.
	_flash_background()
	_type_boss_name()

	# Fade in the background, ColorBox, and boss together.
	var fade_in = create_tween()
	fade_in.set_parallel(true)

	fade_in.tween_property(
		background,
		"modulate:a",
		1.0,
		fade_duration
	)

	fade_in.tween_property(
		color_box,
		"modulate:a",
		1.0,
		fade_duration
	)

	fade_in.tween_property(
		boss_container,
		"modulate:a",
		1.0,
		fade_duration
	)

	await fade_in.finished

	# Keep the boss visible while its idle animation plays.
	await get_tree().create_timer(boss_display_duration).timeout

	# Stop the ColorBox flashing before fading out.
	if background_flash_tween and background_flash_tween.is_running():
		background_flash_tween.kill()

	# Fade out the entire transition screen.
	var fade_out = create_tween()
	fade_out.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_duration
	)

	await fade_out.finished

	# Load the selected stage.
	var error = get_tree().change_scene_to_file(selected_stage_path)

	if error != OK:
		push_error("Failed to load stage: " + selected_stage_path)
