extends CharacterBody2D

enum State {
	DORMANT,
	OPENING,
	MOVING,
	CLOSING,
	DEAD
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea # Make sure this matches your Area2D node name

@export var tilemap_layer: TileMapLayer # Drag your TileMapLayer node here in the Inspector
# Format: Vector3i(atlas_id, atlas_coord_x, atlas_coord_y)
@export var target_tiles: Array[Vector3i] = [
	Vector3i(0, 7, 2),
	Vector3i(0, 7, 3),
	Vector3i(0, 8, 2),
	Vector3i(0, 8, 3),
	Vector3i(0, 3, 0),
	Vector3i(0, 4, 0),
	Vector3i(0, 5, 1)
]

@export var move_speed: float = 120.0
@export var dormant_time: float = 2.0
@export var start_direction: Vector2 = Vector2.LEFT # Use RIGHT, LEFT, UP, or DOWN
@export var start_dormant: bool = true
@export var health: int = 5
@export var damage: int = 4

var current_state: State = State.DORMANT
var state_timer: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	move_direction = start_direction.normalized()
	
	# Fallback: auto-find TileMapLayer in the scene if not manually assigned
	if tilemap_layer == null:
		tilemap_layer = get_tree().current_scene.find_child("*", true, false) as TileMapLayer
	
	if start_dormant:
		# Invert initial direction so it flips to start_direction on its first OPENING
		move_direction = -move_direction
		_enter_state(State.DORMANT)
	else:
		_enter_state(State.MOVING)

func _physics_process(delta: float) -> void:
	if current_state != State.DEAD:
		_process_contact_damage()

	match current_state:
		State.DORMANT:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_state(State.OPENING)
				
		State.OPENING:
			# Waits for _on_animation_finished to transition to MOVING
			pass
			
		State.MOVING:
			var step := move_direction * move_speed * delta
			
			if _will_hit_target_tile(step):
				_snap_to_tile_edge(step)
				velocity = Vector2.ZERO
				_enter_state(State.CLOSING)
			else:
				position += step
				
		State.CLOSING:
			# Waits for _on_animation_finished to transition to DORMANT
			pass
			
		State.DEAD:
			pass

func _process_contact_damage() -> void:
	if damage_area == null:
		return

	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			give_damage(body)
			break

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.DORMANT:
			velocity = Vector2.ZERO
			animated_sprite.play("dormant") # Eye closed
			state_timer = dormant_time
			
		State.OPENING:
			move_direction = -move_direction # Reverse direction before moving
			animated_sprite.play("opening") # Half-open eye
			
		State.MOVING:
			animated_sprite.play("moving") # Eye fully open
			
		State.CLOSING:
			animated_sprite.play("closing") # Half-open eye
			
		State.DEAD:
			velocity = Vector2.ZERO
			collision_shape.set_deferred("disabled", true)
			animated_sprite.play("death")

func _on_animation_finished() -> void:
	match current_state:
		State.OPENING:
			_enter_state(State.MOVING)
		State.CLOSING:
			_enter_state(State.DORMANT)
		State.DEAD:
			queue_free()

func _will_hit_target_tile(step: Vector2) -> bool:
	if tilemap_layer == null:
		return false
		
	var half_extents := _get_half_extents()
	var leading_edge_global := global_position + (move_direction * half_extents) + step
	
	var local_pos := tilemap_layer.to_local(leading_edge_global)
	var cell_coords := tilemap_layer.local_to_map(local_pos)
	
	var source_id := tilemap_layer.get_cell_source_id(cell_coords)
	var atlas_coords := tilemap_layer.get_cell_atlas_coords(cell_coords)
	
	var tile_key := Vector3i(source_id, atlas_coords.x, atlas_coords.y)
	return tile_key in target_tiles

func _snap_to_tile_edge(step: Vector2) -> void:
	var half_extents := _get_half_extents()
	var leading_edge_global := global_position + (move_direction * half_extents) + step
	var local_pos := tilemap_layer.to_local(leading_edge_global)
	var cell_coords := tilemap_layer.local_to_map(local_pos)
	var tile_size := Vector2(tilemap_layer.tile_set.tile_size)
	
	if move_direction.x > 0:
		var tile_left_edge := tilemap_layer.to_global(Vector2(cell_coords.x * tile_size.x, 0)).x
		global_position.x = tile_left_edge - half_extents.x
	elif move_direction.x < 0:
		var tile_right_edge := tilemap_layer.to_global(Vector2((cell_coords.x + 1) * tile_size.x, 0)).x
		global_position.x = tile_right_edge + half_extents.x
	elif move_direction.y > 0:
		var tile_top_edge := tilemap_layer.to_global(Vector2(0, cell_coords.y * tile_size.y)).y
		global_position.y = tile_top_edge - half_extents.y
	elif move_direction.y < 0:
		var tile_bottom_edge := tilemap_layer.to_global(Vector2(0, (cell_coords.y + 1) * tile_size.y)).y
		global_position.y = tile_bottom_edge + half_extents.y

func _get_half_extents() -> Vector2:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		return (collision_shape.shape as RectangleShape2D).size * 0.5
	return Vector2(8, 8)

func take_damage(amount: int) -> void:
	# Octopus Battery takes damage in all states (unless already dead)
	if current_state == State.DEAD:
		return

	health -= amount
	if health <= 0:
		_enter_state(State.DEAD)

func give_damage(body: Node2D) -> void:
	if current_state == State.DEAD:
		return

	if not body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
