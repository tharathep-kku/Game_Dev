extends Area3D

# ---------- VARIABLES ---------- #

@export_file("*.tscn") var next_level_path : String
@export var force_open_hits : int = 3 # Number of times the player can hit the door to force it open, ignoring coins

var hit_count := 0

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return

	if GameManager.all_coins_collected():
		get_tree().change_scene_to_file(next_level_path)
		return

	# Let the player force the door open by hitting it enough times, even without all the coins
	hit_count += 1
	if hit_count >= force_open_hits:
		get_tree().change_scene_to_file(next_level_path)
