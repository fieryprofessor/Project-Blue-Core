extends Area2D

const SPEED: float = 300.0
var direction: int = 1
var shooter: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += SPEED * direction * delta
	if position.x >5000 or position.x<-5000:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body==shooter:
		return
	# Later, we can damage enemies here.
	print("Buster shot hit: ", body.name)
	queue_free()
