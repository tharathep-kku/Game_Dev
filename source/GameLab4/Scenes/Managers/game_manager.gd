# This script is an autoload, that can be accessed from any other script!

extends Node2D

var score : int = 0
var hp    : int = 100
var life  : int = 1
var max_life : int = 1
var max_hp  :int = 100

var sfx_on = true
var music_on = true

var player = null
var current_level : String = "res://Scenes/Levels/Level_01.tscn"
var save_path := "user://game.save"
var save_player_position = Vector2.ZERO
var is_dying = false
var stage : int = 1

var combo : int = 0
var combo_timer : float = 0.0
var combo_window : float = 1.5
var kills : int = 0
var run_start_time : float = 0.0
var high_score : int = 0
const HIGH_SCORE_PATH := "user://highscore.cfg"

func _ready() -> void:
	load_high_score()

func load_high_score() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(HIGH_SCORE_PATH) == OK:
		high_score = cfg.get_value("stats", "high_score", 0)

func save_high_score() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("stats", "high_score", high_score)
	cfg.save(HIGH_SCORE_PATH)

# Call at the end of a run (death or win) to update the persisted high score.
func finalize_run() -> void:
	if score > high_score:
		high_score = score
		save_high_score()

func _process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo = 0

# Adds 1 to score variable
func add_score(v=1):
	score += v

# Called whenever an enemy dies (regardless of level type), from Enemy.death_tween().
# Centralizing here means no per-level signal wiring is needed for scoring/combo to work.
func register_kill(base_score: int) -> void:
	kills += 1
	combo += 1
	combo_timer = combo_window
	var multiplier = 1.0 + float(min(combo, 20)) / 5.0
	add_score(int(round(base_score * multiplier)))
	if combo > 1:
		AudioManager.combo_sfx.play()

func run_time_elapsed() -> float:
	return (Time.get_ticks_msec() - run_start_time) / 1000.0

# Loads next level
func load_next_level(next_scene : PackedScene):
	get_tree().change_scene_to_packed(next_scene)

# Called when the player reaches the exit door of an endless-mode run.
func advance_stage() -> void:
	stage += 1

func restart():
	score = 0
	hp = 100
	life = 1
	stage = 1
	combo = 0
	combo_timer = 0.0
	kills = 0
	run_start_time = Time.get_ticks_msec()
	is_dying = false
	save_player_position = Vector2.ZERO
	get_tree().change_scene_to_file("res://Scenes/Levels/Level_01.tscn")


func damage(val=1):
	if is_dying:
		return
	hp = hp - val
	if hp <=0 :
		death()
func add_hp(val=1):
	hp = hp + val
	if hp >max_hp:
		hp = max_hp

func update_option():
	var music_bus = AudioServer.get_bus_index("music")
	var sfx_bus = AudioServer.get_bus_index("sfx")
	AudioServer.set_bus_mute(sfx_bus,!sfx_on)
	AudioServer.set_bus_mute(music_bus,!music_on)
	
func add_life():
	if life < max_life:
		life += 1

func death():
	if is_dying:
		return
	is_dying = true
	if player != null:
		await player.death_tween()
	life -= 1
	hp = max_hp
	if life <= 0:
		finalize_run()
		await _death_shake_and_flash()
		get_tree().change_scene_to_file("res://Scenes/Levels/game_over.tscn")
	is_dying = false

func _death_shake_and_flash() -> void:
	if player != null and player.has_node("Camera2D"):
		player.get_node("Camera2D").shake(0.4, 12.0)
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0.8, 0.0, 0.0, 0.6)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	get_tree().root.add_child(layer)
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	await tween.finished
	layer.queue_free()

func save_option():
	var file = FileAccess.open("user://option.json", FileAccess.WRITE)
	if file:
		var payload: Dictionary = {
			"music" : music_on,
			"sound" : sfx_on,
		}
		var json_text = JSON.stringify(payload, "  ")
		file.store_pascal_string(json_text)
		file.close()

func load_option():
	if FileAccess.file_exists("user://option.json"):
		var file = FileAccess.open("user://option.json", FileAccess.READ)
		var text = file.get_pascal_string()
		var data = JSON.parse_string(text)        		
		file.close()
		music_on = data.get("music",true)
		sfx_on = data.get("sound",true)
		update_option()
				
func save_game():
	current_level = get_tree().current_scene.scene_file_path
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var pos = player.global_position
		var payload: Dictionary = {
			"current_level" : current_level,
			"player" : [pos.x, pos.y],
			"score": score,
			"life" : life,
			"stage" : stage
		}
		var json_text = JSON.stringify(payload, "  ")
		file.store_pascal_string(json_text)
		file.close()

func has_gamesaved():
	return FileAccess.file_exists(save_path)

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var text = file.get_pascal_string()
		var data = JSON.parse_string(text)        		
		file.close()
		current_level = data.get("current_level", current_level)
		score = data.get("score", score)
		life = data.get("life", 1)
		stage = data.get("stage", 1)
		var pos = data.get("player",[0,0])
		save_player_position = Vector2(pos[0],pos[1])
		get_tree().change_scene_to_file(current_level)
	else:
		restart()	
