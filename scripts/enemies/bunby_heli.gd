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


func _ready() -> void:
	animated_sprite.play("flying")
	
func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if player_detected:
		velocity.x = 0.0
	else:
		velocity.x = move_speed * facing_direction

	velocity.y = 0.0

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

	if body.is_invincible:
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
	give_damage(body)
