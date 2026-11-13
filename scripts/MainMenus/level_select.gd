extends Control

@onready var slots: Array[Node] = $Slots.get_children()
var current_index: int = 0

func _ready() -> void:
	print("Total slots: ", slots.size())
	
	if slots.is_empty():
		push_error("No level slots found under Slots!")
		return
	
	_update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_right"):
		print("Right pressed")
		current_index = wrapi(current_index + 1, 0, slots.size())
		_update_selection()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("move_left"):
		print("Left pressed")
		current_index = wrapi(current_index - 1, 0, slots.size())
		_update_selection()
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("start"):
		print("Start pressed")
		
		if slots.is_empty():
			return
		
		var chosen_scene: String = slots[current_index].stage_scene_path
		
		if chosen_scene != "":
			var error := get_tree().change_scene_to_file(chosen_scene)
			
			if error != OK:
				push_error("Failed to load stage: " + chosen_scene)

func _update_selection() -> void:
	print("Current index: ", current_index)
	
	for i in range(slots.size()):
		slots[i].set_selected(i == current_index)
