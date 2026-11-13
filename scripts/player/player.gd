extends CharacterBody2D

const SPEED: float = 100.0
const JUMP_VELOCITY: float = -300.0
const CLIMB_SPEED: float = 80.0
const FIRE_COOLDOWN: float = 0.25

var is_shooting: bool = false
var near_ladder: bool = false
var is_climbing: bool = false
var is_climbing_and_shooting: bool = false
var facing_direction: int = 1
var original_collision_layer: int
var original_collision_mask: int
var fire_timer: float = 0.0

@export var intro_landing_position: Vector2 = Vector2(139, 144)

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_ladder: Area2D = null

const BUSTER_SHOT = preload("res://scenes/weapons/buster_shot.tscn")
# Three precise states: "INTRO_FALL", "INTRO_LAND", or "PLAY"
var current_state: String = "INTRO_FALL"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var buster_spawn1: Marker2D = $BusterSpawnGround
@onready var buster_spawn2: Marker2D = $BusterSpawnJump

func fire_buster() -> void:
	if fire_timer > 0.0:
		return

	var shot = BUSTER_SHOT.instantiate()
	shot.direction = facing_direction
	shot.shooter = self

	var spawn_marker: Marker2D
	if is_on_floor():
		spawn_marker = buster_spawn1
	else:
		spawn_marker = buster_spawn2

	var spawn_position: Vector2 = spawn_marker.position
	spawn_position.x *= facing_direction
	shot.global_position = to_global(spawn_position)
	get_tree().current_scene.add_child(shot)
	fire_timer = FIRE_COOLDOWN
	is_shooting = true


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	print("INTRO FALL STATE")
	sprite.play("teleport_line")


func _on_animation_finished() -> void:
	if current_state == "INTRO_LAND" and sprite.animation == "teleport":
		print("PLAY STATE")
		current_state = "PLAY"
		sprite.play("idle")
		
	elif is_climbing_and_shooting and sprite.animation == "stair_shoot":
		is_climbing_and_shooting = false
		sprite.play("stair_climb")
		sprite.pause()


func _physics_process(delta: float) -> void:

	# Update the shooting cooldown in every state.
	fire_timer = maxf(0.0, fire_timer - delta)

	if fire_timer == 0.0:
		is_shooting = false

	# Apply gravity only when not climbing.
	if not is_on_floor() and not is_climbing:
		velocity.y += gravity * delta

	# =========================================================
	# INTRO STATE MACHINE
	# =========================================================
	if current_state == "INTRO_FALL":
		velocity.x = 0.0

		# Fall freely without being stopped by collisions.
		velocity.y += gravity * delta
		global_position += velocity * delta

		# Check whether the player has reached the target position.
		if global_position.y >= intro_landing_position.y:
			global_position = intro_landing_position
			velocity = Vector2.ZERO

			current_state = "INTRO_LAND"
			print("INTRO LAND STATE")
			# Restore collisions after reaching the target.
			collision_layer = original_collision_layer
			collision_mask = original_collision_mask

			sprite.play("teleport")

		return

	elif current_state == "INTRO_LAND":
		velocity.x = 0.0
		move_and_slide()
		return

	# Start climbing when pressing up or down near a ladder.
	if near_ladder and current_ladder and not is_climbing:
		if Input.is_action_just_pressed("move_up") and is_on_floor():
			is_climbing = true
			global_position.x = current_ladder.global_position.x

		elif not is_on_floor():
			if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
				if not is_on_floor():
					is_climbing = true
					global_position.x = current_ladder.global_position.x

	# Handle climbing movement.
	if is_climbing:

		# When touching the floor, pressing DOWN exits the ladder.
		if is_on_floor() and Input.is_action_pressed("move_down"):
			is_climbing = false
			is_climbing_and_shooting = false
			velocity = Vector2.ZERO
			sprite.play("idle")

		# Allow the player to leave the ladder horizontally.
		elif not near_ladder:
			is_climbing = false
			is_climbing_and_shooting = false

		else:
			var climb_direction: float = Input.get_axis("move_up", "move_down")

			# Prevent climbing downward while standing on the floor.
			if is_on_floor() and climb_direction > 0.0:
				climb_direction = 0.0

			velocity.x = 0.0
			velocity.y = climb_direction * CLIMB_SPEED

			# Update facing direction while standing still on the ladder.
			if climb_direction == 0.0:
				if Input.is_action_pressed("move_left"):
					facing_direction = -1
					sprite.flip_h = true
				elif Input.is_action_pressed("move_right"):
					facing_direction = 1
					sprite.flip_h = false

				# Shoot while paused on the ladder.
				if ((Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")) 
				and Input.is_action_just_pressed("fire") and not is_climbing_and_shooting):
					if fire_timer <= 0.0:
						fire_buster()
						is_climbing_and_shooting = true
						sprite.play("stair_shoot")

				# Keep the shooting animation from being overridden.
				if not is_climbing_and_shooting:
					if sprite.animation != "stair_climb" or not sprite.is_playing():
						sprite.play("stair_climb")
						sprite.pause()

			else:
			# Moving up or down the ladder.
				is_climbing_and_shooting = false
				sprite.play("stair_climb")

			move_and_slide()
			return

	# =========================================================
	# NORMAL PLAYER MOVEMENT
	# =========================================================
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("fire"):
		fire_buster()

	if direction != 0:
		velocity.x = direction * SPEED
		facing_direction = 1 if direction > 0 else -1
		sprite.flip_h = facing_direction == -1
	else:
		velocity.x = 0.0

	move_and_slide()

	# =========================================================
	# ANIMATION CONTROLLER
	# =========================================================
	if is_shooting:
		if not is_on_floor():
			sprite.play("jump_and_shoot")
		elif direction != 0:
			sprite.play("run_and_shoot")
		else:
			sprite.play("shoot")
	else:
		if not is_on_floor():
			sprite.play("jump")
		elif direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")
