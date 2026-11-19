extends Area2D

const SPEED: float = 150.0
const DAMAGE: int = 2
var direction: Vector2 = Vector2.LEFT
var shooter: Node2D = null
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
const MAX_LIFETIME: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)
	# Fallback: despawn even if it never enters the camera's view
	get_tree().create_timer(MAX_LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += SPEED * direction * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	
	print("Blaster shot hit: ", body.name)
	queue_free()
