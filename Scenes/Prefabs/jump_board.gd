extends Area2D

@export var bounce_force : float = 1100.0
@export var cooldown : float = 0.15

var ready_to_bounce := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not ready_to_bounce:
		return
	if not body.is_in_group("Player"):
		return
	ready_to_bounce = false
	body.velocity.y = -bounce_force
	AudioManager.boost_sfx.play()
	bounce_tween()
	await get_tree().create_timer(cooldown).timeout
	ready_to_bounce = true

func bounce_tween() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.3, 0.55), 0.08)
	tween.tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 0.15)
