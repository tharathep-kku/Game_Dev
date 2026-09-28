extends Enemy

@export var throw_range := 500.0
@export var throw_cooldown := 2.0
@export var debris_scene : PackedScene

var throw_timer := 0.0

func _ready() -> void:
	super._ready()
	var types = Array($Sprite/AnimateSprite.sprite_frames.get_animation_names())
	$Sprite/AnimateSprite.animation = types.pick_random()
	$Sprite/AnimateSprite.play()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not alive:
		return
	if throw_timer > 0:
		throw_timer -= delta
	if player_ray.is_colliding() and throw_timer <= 0:
		var point : Vector2 = player_ray.get_collision_point()
		if global_position.distance_to(point) <= throw_range:
			_throw_debris(point)
			throw_timer = throw_cooldown

func _throw_debris(target: Vector2) -> void:
	if debris_scene == null:
		return
	var d = debris_scene.instantiate()
	d.global_position = global_position + Vector2(0, -30)
	get_parent().add_child(d)
	var dir = (target - d.global_position).normalized()
	d.launch(Vector2(dir.x * 260.0, -220.0))
	AudioManager.throw_sfx.play()
