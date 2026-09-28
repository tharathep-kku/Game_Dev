extends AnimatableBody2D

@export var stop_offsets : Array[Vector2] = [Vector2.ZERO, Vector2(0, -448)]
@export var speed : float = 80.0
@export var wait_time : float = 1.0

var origin : Vector2
var current_index := 0
var waiting := false

func _ready() -> void:
	origin = position
	if stop_offsets.is_empty():
		stop_offsets = [Vector2.ZERO]

func _physics_process(delta: float) -> void:
	if waiting or stop_offsets.size() < 2:
		return
	var target = origin + stop_offsets[(current_index + 1) % stop_offsets.size()]
	var to_target = target - position
	var dist = to_target.length()
	if dist <= speed * delta:
		position = target
		current_index = (current_index + 1) % stop_offsets.size()
		waiting = true
		AudioManager.platform_sfx.play()
		await get_tree().create_timer(wait_time).timeout
		waiting = false
	else:
		position += to_target.normalized() * speed * delta
