extends Area3D

# ---------- VARIABLES ---------- #

@onready var spawn_position = %SpawnPosition

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# Sends the player back to the spawn point if they touch the trap
	if body.is_in_group("Player"):
		body.global_position = spawn_position.global_position
