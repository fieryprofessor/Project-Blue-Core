extends Area2D

const SPEED: float = 300.0
const DAMAGE: int = 1
var direction: int = 1
var shooter: Node2D = null
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position.x += SPEED * direction * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	
	print("Buster shot hit: ", body.name)
	queue_free()
