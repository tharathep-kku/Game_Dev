extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("move")
	$AnimationPlayer.seek(randf_range(0.0, $AnimationPlayer.get_animation("move").length), true)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.add_hp(20)
		AudioManager.coin_pickup_sfx.play()
		queue_free()
