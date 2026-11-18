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
const ATTACK_DELAY: float = 0.5
var attack_start_position: Vector2
var attack_target_position: Vector2
var attack_state: String = "PATROL"
var original_y: float = 0.0
var attack_direction: Vector2 = Vector2.ZERO
var recover_target_position: Vector2 = Vector2.ZERO


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

	match attack_state:

		"PATROL":
			if attack_delay_timer > 0.0:
				attack_delay_timer -= delta
			# Keep moving in the current facing_direction until cooldown finishes
				animated_sprite.flip_h = facing_direction > 0
				velocity.x = facing_direction * PATROL_SPEED
				velocity.y = 0.0
				move_and_slide()
				return
				
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
				attack_direction = (attack_target_position - attack_start_position).normalized()
				# Mirror the horizontal distance across the player for final_pos
				var offset_x: float = attack_target_position.x - attack_start_position.x
				recover_target_position = Vector2(
					attack_target_position.x + offset_x,
					attack_start_position.y
				)
				attack_state = "ATTACK"

		"ATTACK":
			# Move diagonally toward the player's position captured when the attack began.
			velocity = attack_direction * ATTACK_SPEED
			move_and_slide()

			# 1. Check if enemy reached or passed the target vertical height (assuming +Y is down)
			var reached_target_y: bool = global_position.y >= attack_target_position.y

			# 2. Check if enemy passed the target horizontally based on movement direction
			var passed_target_x: bool = (
				(attack_direction.x > 0 and global_position.x >= attack_target_position.x) or
				(attack_direction.x < 0 and global_position.x <= attack_target_position.x)
			)

			# Exit dive if target height reached, passed target
			if reached_target_y or passed_target_x:
				velocity = Vector2.ZERO
				attack_state = "RECOVER"


		"RECOVER":
			# Fly diagonally up to final_pos (same distance_x on the opposite side).
			var to_final_pos: Vector2 = recover_target_position - global_position

			if to_final_pos.length() <= max(POSITION_TOLERANCE, ATTACK_SPEED  * delta):
				global_position = recover_target_position
				velocity = Vector2.ZERO
				facing_direction *= -1
				animated_sprite.flip_h = facing_direction > 0
				attack_delay_timer = ATTACK_DELAY
				attack_state = "PATROL"
			else:
				velocity = to_final_pos.normalized() * ATTACK_SPEED

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
