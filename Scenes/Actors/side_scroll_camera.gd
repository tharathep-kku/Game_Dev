extends Camera2D

# Off by default so the existing jump/platform levels keep normal vertical
# follow. Endless-mode levels call enable_horizontal_lock() to freeze the
# camera's vertical position so shooting/aiming stays visually stable while
# the player jumps or gets knocked around.
var lock_y := false
var fixed_y : float = 0.0

func enable_horizontal_lock() -> void:
	fixed_y = global_position.y
	lock_y = true

func _process(_delta: float) -> void:
	if lock_y:
		global_position.y = fixed_y

func shake(duration: float, strength: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	offset = Vector2.ZERO
