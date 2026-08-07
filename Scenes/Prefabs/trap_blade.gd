extends StaticBody2D

@onready var saw_sprite : Sprite2D = $Saw
var warning_tween : Tween

func _ready() -> void:
	$WarningZone.body_entered.connect(_on_warning_entered)
	$WarningZone.body_exited.connect(_on_warning_exited)

func _on_warning_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if warning_tween:
		warning_tween.kill()
	warning_tween = create_tween().set_loops()
	warning_tween.tween_property(saw_sprite, "modulate", Color(1.6, 0.55, 0.55), 0.15)
	warning_tween.tween_property(saw_sprite, "modulate", Color(1, 1, 1), 0.15)

func _on_warning_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if warning_tween:
		warning_tween.kill()
	saw_sprite.modulate = Color(1, 1, 1)
