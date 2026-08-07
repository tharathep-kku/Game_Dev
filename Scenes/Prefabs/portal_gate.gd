extends Area2D

@export var linked_portal_path : NodePath
@export var cooldown : float = 0.5

var linked_portal : Node2D
var locked := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if linked_portal_path != NodePath():
		linked_portal = get_node(linked_portal_path)

func _on_body_entered(body: Node2D) -> void:
	if locked:
		return
	if not body.is_in_group("Player"):
		return
	if linked_portal == null:
		return
	locked = true
	AudioManager.portal_sfx.play()
	body.global_position = linked_portal.global_position
	linked_portal.lock_temporarily()
	await get_tree().create_timer(cooldown).timeout
	locked = false

func lock_temporarily() -> void:
	locked = true
	await get_tree().create_timer(cooldown).timeout
	locked = false
