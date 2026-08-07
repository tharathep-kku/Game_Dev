extends Area2D

@export var fall_accel : float = 1400.0
@export var lifetime : float = 3.0
@export var damage : int = 8

var velocity : Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(v: Vector2) -> void:
	velocity = v

func _physics_process(delta: float) -> void:
	velocity.y += fall_accel * delta
	position += velocity * delta
	rotate(6.0 * delta)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if not body.can_damage or body.is_shielded():
		queue_free()
		return
	body.damage_tween()
	GameManager.damage(damage)
	queue_free()
