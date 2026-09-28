extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if body.can_damage and not body.is_shielded():
		body.hit_trap.emit()
	# If that damage wasn't lethal (or was skipped above due to i-frames/
	# shield), GameManager.death() never ran and never respawned the player --
	# force them back to spawn so they can't be left falling through empty
	# space below the map.
	if not GameManager.is_dying:
		body.velocity = Vector2.ZERO
		body.global_position = body.spawn_point
