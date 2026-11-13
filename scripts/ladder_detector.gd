extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_ladder = true
		body.current_ladder = self # <--- Store the ladder reference here
		#print(body.near_ladder," ",body.current_ladder)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.near_ladder = false
		body.current_ladder = null
