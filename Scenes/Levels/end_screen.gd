extends Node2D

@export var show_full_stats := false # false = GameOver-style (score/stage/high score), true = WinGame-style (+kills/time)

@onready var stinger : AudioStreamPlayer = $Stinger
@onready var title : Label = $Title
@onready var stats_label : Label = get_node_or_null("StatsLabel")
@onready var music_player : AudioStreamPlayer = get_node_or_null("MusicPlayer")

func _ready() -> void:
	stinger.play()
	title.scale = Vector2.ZERO
	title.pivot_offset = title.size / 2.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(title, "scale", Vector2.ONE, 0.5)

	if stats_label:
		_populate_stats()

	if music_player:
		music_player.volume_db = -40.0
		music_player.play()
		var music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -6.0, 2.5)

func _populate_stats() -> void:
	if show_full_stats:
		stats_label.text = "คะแนน: %d\nซอมบี้ที่ฆ่า: %d\nเวลาที่ใช้: %s\nด่านที่จบ: %d" % [
			GameManager.score,
			GameManager.kills,
			_format_time(GameManager.run_time_elapsed()),
			GameManager.stage,
		]
	else:
		var hs_note = "  (สถิติใหม่!)" if GameManager.score >= GameManager.high_score and GameManager.score > 0 else ""
		stats_label.text = "คะแนน: %d\nไปถึงด่าน: %d\nคะแนนสูงสุด: %d%s" % [
			GameManager.score,
			GameManager.stage,
			GameManager.high_score,
			hs_note,
		]

func _format_time(seconds: float) -> String:
	var s = int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
