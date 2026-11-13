extends Control

@onready var slots: Array[Node] = $Slots.get_children()
var current_index: int = 0

const TRANSITION_SCENE = preload("res://scenes/MainMenus/boss_transition.tscn")
const TRANSITION_SCRIPT = preload("res://scripts/MainMenus/boss_transition.gd")
@export var boss_scenes: Array[PackedScene]
@onready var music: AudioStreamPlayer2D = $StageSelectMusic
@onready var select_sound: AudioStreamPlayer2D = $SelectSound

func _ready() -> void:
	print("Total slots: ", slots.size())
	
	if slots.is_empty():
		push_error("No level slots found under Slots!")
		return
	
	_update_selection()
	# Start level selection music.
	music.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_right"):
		print("Right pressed")
		current_index = wrapi(current_index + 1, 0, slots.size())
		_update_selection()
		select_sound.play()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_left"):
		print("Left pressed")
		current_index = wrapi(current_index - 1, 0, slots.size())
		_update_selection()
		select_sound.play()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("start"):
		print("Start pressed")

		if current_index >= boss_scenes.size():
			push_error("No Robot Master scene assigned to this slot!")
			return

		var chosen_scene: String = slots[current_index].stage_scene_path

		print("Selected slot: ", current_index)
		print("Boss scene: ", boss_scenes[current_index])
		print("Stage path: ", chosen_scene)

		if boss_scenes[current_index] == null:
			push_error("Boss scene is not assigned for this slot!")
			return

		if chosen_scene == "":
			push_error("Stage scene path is empty for this slot!")
			return

		TRANSITION_SCRIPT.selected_boss_scene = boss_scenes[current_index]
		TRANSITION_SCRIPT.selected_stage_path = chosen_scene
		TRANSITION_SCRIPT.selected_boss_index = current_index

		print("Changing to boss transition scene...")

		var error = get_tree().change_scene_to_packed(TRANSITION_SCENE)

		if error != OK:
			push_error("Failed to load boss transition scene. Error: " + str(error))

func _update_selection() -> void:
	print("Current index: ", current_index)

	for i in range(slots.size()):
		print("Slot ", i, ": ", slots[i].name)
		print("Script: ", slots[i].get_script())
		print("Has set_selected: ", slots[i].has_method("set_selected"))

		if slots[i].has_method("set_selected"):
			slots[i].set_selected(i == current_index)
		else:
			push_error("Missing set_selected() on node: " + str(slots[i].get_path()))
