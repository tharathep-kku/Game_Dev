extends Area2D

var velocity : Vector2 = Vector2.ZERO
@export var fall_accel : float = 1400.0
@export var fuse_time : float = 1.4
@export var explosion_radius : float = 120.0

var exploded := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(fuse_time).timeout.connect(explode)

func launch(v: Vector2) -> void:
	velocity = v

func _physics_process(delta: float) -> void:
	velocity.y += fall_accel * delta
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Traps"):
		explode()

func explode() -> void:
	if exploded:
		return
	exploded = true
	AudioManager.explosion_sfx.play()
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) <= explosion_radius and "alive" in enemy and enemy.alive:
			enemy.death_tween()
	queue_free()
