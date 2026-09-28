extends Node2D

@export var tick_damage := 8
@export var tick_interval := 0.4

var player_in_zone : Node2D = null
var tick_timer := 0.0

@onready var anim_player : AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	$DangerZone.body_entered.connect(_on_danger_entered)
	$DangerZone.body_exited.connect(_on_danger_exited)
	$WarningZone.body_entered.connect(_on_warning_entered)
	$WarningZone.body_exited.connect(_on_warning_exited)

func _on_warning_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		anim_player.speed_scale = 2.5

func _on_warning_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		anim_player.speed_scale = 1.0

func _on_danger_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_zone = body
		tick_timer = 0.0 # deal the first tick immediately on entry

func _on_danger_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and player_in_zone == body:
		player_in_zone = null

func _process(delta: float) -> void:
	if player_in_zone == null:
		return
	tick_timer -= delta
	if tick_timer > 0:
		return
	tick_timer = tick_interval
	if player_in_zone.has_method("is_shielded") and player_in_zone.is_shielded():
		return
	var can_dmg = player_in_zone.get("can_damage")
	if can_dmg != null and not can_dmg:
		return
	GameManager.damage(tick_damage)
