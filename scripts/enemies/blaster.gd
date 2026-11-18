extends CharacterBody2D

enum State {
	CLOSED,
	OPENING,
	FIRING,
	CLOSING,
	DEAD
}

@onready var blaster_spawn: Marker2D = $BlasterSpawn
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var bullet_scene: PackedScene
@export var fire_interval: float = 0.25
@export var cooldown_time: float = 3.0
@export var facing_left: bool = true
@export var health: int = 1
@export var damage: int = 1

const SHOT_ANGLES_DEG: Array[float] = [60.0, 30.0, 0.0, -30.0, -60.0]

var current_state: State = State.CLOSED
var state_timer: float = 0.0
var shot_index: int = 0

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_enter_state(State.CLOSED)

func _physics_process(delta: float) -> void:
	match current_state:
		State.CLOSED:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_state(State.OPENING)
				
		State.OPENING:
			# Waits for _on_animation_finished to transition to FIRING
			pass
			
		State.FIRING:
			state_timer -= delta
			if state_timer <= 0.0:
				if shot_index < SHOT_ANGLES_DEG.size():
					_spawn_bullet(SHOT_ANGLES_DEG[shot_index])
					shot_index += 1
					state_timer = fire_interval
				else:
					_enter_state(State.CLOSING)
					
		State.CLOSING:
			# Waits for _on_animation_finished to transition to CLOSED
			pass
			
		State.DEAD:
			pass

func _enter_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.CLOSED:
			animated_sprite.play("idle")
			state_timer = cooldown_time
			
		State.OPENING:
			animated_sprite.play("opening")
			
		State.FIRING:
			animated_sprite.play("firing")
			shot_index = 0
			state_timer = 0.0 # Fires the first pellet immediately on frame 1
			
		State.CLOSING:
			animated_sprite.play("closing")
			
		State.DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			animated_sprite.play("death")

func _on_animation_finished() -> void:
	match current_state:
		State.OPENING:
			_enter_state(State.FIRING)
		State.CLOSING:
			_enter_state(State.CLOSED)
		State.DEAD:
			queue_free()

func _spawn_bullet(angle_deg: float) -> void:
	if bullet_scene == null:
		push_warning("Bullet Scene is not assigned in the Inspector!")
		return

	var base_direction := Vector2.LEFT if facing_left else Vector2.RIGHT
	var angle_rad := deg_to_rad(angle_deg if facing_left else -angle_deg)
	
	var bullet := bullet_scene.instantiate()
	bullet.shooter = self
	bullet.direction = base_direction.rotated(angle_rad)
	bullet.global_position = blaster_spawn.global_position
	
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
	# Invulnerable when closed or already dead
	if current_state == State.CLOSED or current_state == State.DEAD:
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


func _on_damage_area_body_entered(body: Node2D) -> void:
	print("damage given: ",damage)
	give_damage(body)
