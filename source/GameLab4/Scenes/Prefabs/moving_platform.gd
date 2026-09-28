extends AnimatableBody2D

@export var offset : Vector2 = Vector2(300, 0)
@export var speed : float = 100.0
@export var wait_time : float = 0.4

var point_a : Vector2
var point_b : Vector2
var going_to_b := true
var waiting := false

func _ready() -> void:
	point_a = position
	point_b = point_a + offset

func _physics_process(delta: float) -> void:
	if waiting:
		return
	var target = point_b if going_to_b else point_a
	var to_target = target - position
	var dist = to_target.length()
	if dist <= speed * delta:
		position = target
		going_to_b = !going_to_b
		waiting = true
		AudioManager.platform_sfx.play()
		await get_tree().create_timer(wait_time).timeout
		waiting = false
	else:
		position += to_target.normalized() * speed * delta
