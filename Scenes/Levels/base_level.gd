extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.player = $Player2
	$MusicPlayer.play(0)
	var tween = create_tween()
	$UserInterface/Label.scale = Vector2.ZERO
	tween.stop(); tween.play()
	tween.tween_property($UserInterface/Label, "scale", Vector2.ONE, 1)
	await get_tree().create_timer(3).timeout
	$UserInterface/Label.queue_free()


func _on_player_hit_enemy() -> void:
	GameManager.damage(5)	

func _on_player_hit_trap() -> void:
	GameManager.damage(20)


func _on_music_player_finished() -> void:
	$MusicPlayer.play(0)
