extends Area2D

@export var amount : int = 1
@export var amplitude := 4
@export var frequency := 5

var time_passed = 0.0
var initial_position := Vector2.ZERO

func _ready() -> void:
	initial_position = position

func _process(delta: float) -> void:
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		AudioManager.coin_pickup_sfx.play()
		if body.has_method("add_bombs"):
			body.add_bombs(amount)
		queue_free()
