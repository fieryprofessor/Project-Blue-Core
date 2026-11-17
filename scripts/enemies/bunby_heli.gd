extends CharacterBody2D

@export var health: int = 1
@export var damage: int = 3
@export var player_invincible: bool = false

@export var move_speed: float = 50.0
@export_enum("Left:-1", "Right:1") var facing_direction: int = -1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var is_dead: bool = false
var player_detected: bool = false
var attack_delay_timer: float = 0.0
const PATROL_SPEED: float = 80.0
const ATTACK_SPEED: float = 200.0
const ATTACK_DISTANCE: float = 56.0
const POSITION_TOLERANCE: float = 2.0
const ATTACK_DELAY: float = 1.0
var attack_start_position: Vector2
var attack_target_position: Vector2
var attack_state: String = "PATROL"
var original_y: float = 0.0

func _ready() -> void:
	animated_sprite.play("flying")
	original_y = global_position.y

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var player = get_tree().get_first_node_in_group("player")

	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not player_detected:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match attack_state:

		"PATROL":
			# Face the player.
			if player.global_position.x < global_position.x:
				facing_direction = -1
				animated_sprite.flip_h = false
			else:
				facing_direction = 1
				animated_sprite.flip_h = true

			# Move horizontally toward the player.
			velocity.x = facing_direction * PATROL_SPEED
			velocity.y = 0.0

			move_and_slide()

			# Check whether the player is close enough to attack.
			var distance_x: float = abs(
				player.global_position.x - global_position.x
			)

			if distance_x <= ATTACK_DISTANCE:
				attack_start_position = global_position
				attack_target_position = player.global_position
				attack_state = "ATTACK"

		"ATTACK":
			# Move diagonally toward the player's position
			# captured when the attack began.
			var direction: Vector2 = (
				attack_target_position - global_position
			).normalized()

			velocity = direction * ATTACK_SPEED
			move_and_slide()
			# Exit dive if target reached OR if blocked by a wall/floor/ceiling
			if global_position.distance_to(attack_target_position) <= ATTACK_SPEED * delta or is_on_floor() or is_on_wall() or is_on_ceiling():
				velocity = Vector2.ZERO
				attack_state = "RECOVER"


		"RECOVER":
			# Return to the original flying height.
			var vertical_distance: float = (
				attack_start_position.y - global_position.y
			)

			if abs(vertical_distance) <= POSITION_TOLERANCE:
				global_position.y = attack_start_position.y
				velocity = Vector2.ZERO
				attack_state = "PATROL"
			else:
				velocity.x = 0.0
				velocity.y = sign(vertical_distance) * PATROL_SPEED

			move_and_slide()



func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()


func give_damage(body: Node2D) -> void:
	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = true
		print("Player detected!")


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = false
		print("Player left detection area!")


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	detection_area.set_deferred("monitoring", false)

	animated_sprite.play("death")
	await animated_sprite.animation_finished

	queue_free()


func _on_damage_area_body_entered(body: Node2D) -> void:
	print("damage given: ",damage)
	give_damage(body)
