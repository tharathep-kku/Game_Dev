extends Node2D

const TILE := 64
const GROUND_ROW := 9
const GROUND_TOP_Y := GROUND_ROW * TILE # 576, matches the platformer levels' ground convention
const GROUND_THICKNESS := 5

const BASE_LENGTH_TILES := 40
const LENGTH_PER_STAGE := 6
const MAX_LENGTH_TILES := 140

const TILESET_UID := "uid://dk4qcax1suy2c"
const T_STONE_TOP := Vector2i(15, 15)
const T_STONE_TOPLEFT := Vector2i(16, 15)
const T_STONE_TOPRIGHT := Vector2i(17, 15)
const T_STONE_CENTER := Vector2i(12, 15)
const T_STONE_LEFT := Vector2i(13, 15)
const T_STONE_RIGHT := Vector2i(14, 15)

const REGULAR_UIDS := [
	"uid://bb11am1mk0iuh", # monster_mushroom1 (Zombie_1 skin)
	"uid://b7c8maoe37ao7", # monster_mushroom2 (Zombie_2 skin)
	"uid://d0kgmlffowerk", # monster_zombie3
	"uid://dzombiefour01a", # monster_zombie4
]
const RUNNER_UID := "uid://drunner001a2b3"
const TANK_UID := "uid://dtank001a2b3c4"
const THROWER_UID := "uid://dthrower001a2b"
const BOSS_UID := "uid://dboss001a2b3c4"
const FINAL_STAGE := 10
const BOSS_STAGE_INTERVAL := 4

# far, mid, near layers per background set (Assets/Backgrounds/Postapocalypse*)
const BG_SETS := [
	["uid://cptmpjo7ss0wj", "uid://bg65vo7swbktg", "uid://bc3i0l4a8d47x"],
	["uid://bkh6fbwg1qxyb", "uid://ftg1ik64i0mu", "uid://bwjmpmxk3vuqe"],
	["uid://by2e8ivvsstk3", "uid://0xkot2lwm6ti", "uid://pfshim4fwt2q"],
	["uid://3nim61n2adlt", "uid://p4848y71wwoq", "uid://c1mijb0ed1wqi"],
]

@onready var ground : TileMapLayer = $Level/Ground
@onready var sky : Parallax2D = $Level/Sky
@onready var bg_mid : Parallax2D = $Level/Background1
@onready var bg_near : Parallax2D = $Level/Background2
@onready var player : CharacterBody2D = $Player2
@onready var finish_door : Area2D = $LevelFinishDoor
@onready var enemies_node : Node2D = $Enemies
@onready var coins_node : Node2D = $Coins
@onready var music_player : AudioStreamPlayer = $MusicPlayer
@onready var intro_label : Label = $UserInterface/Label

var level_length_px : float
var stage : int
var finished := false
var spawn_timer := 0.0
var spawn_interval := 2.2
var enemies_spawned := 0
var max_enemies_this_level := 10
var coin_timer := 0.0
var speed_mult := 1.0
var hp_mult := 1.0
var boss_due := false
var boss_spawned := false

func _ready() -> void:
	GameManager.player = player
	stage = GameManager.stage

	var length_tiles = min(BASE_LENGTH_TILES + (stage - 1) * LENGTH_PER_STAGE, MAX_LENGTH_TILES)
	level_length_px = length_tiles * TILE

	_build_ground(length_tiles)
	_setup_background(length_tiles)

	player.position = Vector2(TILE * 2, GROUND_TOP_Y - 100)
	player.get_node("Camera2D").enable_horizontal_lock()

	finish_door.position = Vector2(level_length_px - TILE * 1.5, GROUND_TOP_Y - TILE * 1.5)
	finish_door.body_entered.connect(_on_finish_entered)

	# Non-linear difficulty curve: accelerates instead of a flat linear step,
	# so later stages ramp up faster than early ones ("ค่อยๆ ชันขึ้นทุกด่าน").
	var s = float(stage - 1)
	spawn_interval = max(0.45, 2.2 - 0.06 * s - 0.006 * s * s)
	speed_mult = 1.0 + 0.035 * s + 0.002 * s * s
	hp_mult = 1.0 + 0.08 * s + 0.006 * s * s
	max_enemies_this_level = min(10 + stage * 3, 70)
	boss_due = stage % BOSS_STAGE_INTERVAL == 0
	boss_spawned = not boss_due

	intro_label.text = "ด่านที่ %d — เดินหน้าและยิงซอมบี้!\nA D เดิน  Space กระโดด  X ยิง  C ระเบิด" % stage
	intro_label.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(intro_label, "scale", Vector2.ONE, 1)
	await get_tree().create_timer(3).timeout
	intro_label.queue_free()

func _process(delta: float) -> void:
	if finished:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0 and enemies_spawned < max_enemies_this_level:
		_try_spawn_zombie()
		spawn_timer = spawn_interval
	coin_timer -= delta
	if coin_timer <= 0.0:
		_try_spawn_coin()
		coin_timer = randf_range(2.5, 4.0)
	if not boss_spawned and player.global_position.x > level_length_px * 0.5:
		_spawn_boss()
		boss_spawned = true

func _build_ground(length_tiles: int) -> void:
	var tileset : TileSet = load(TILESET_UID)
	ground.tile_set = tileset
	var src_id = tileset.get_source_id(0)
	for col in range(0, length_tiles):
		var top_tile = T_STONE_TOP
		if col == 0:
			top_tile = T_STONE_TOPLEFT
		elif col == length_tiles - 1:
			top_tile = T_STONE_TOPRIGHT
		ground.set_cell(Vector2i(col, GROUND_ROW), src_id, top_tile)
		for r in range(GROUND_ROW + 1, GROUND_ROW + GROUND_THICKNESS):
			var fill_tile = T_STONE_CENTER
			if col == 0:
				fill_tile = T_STONE_LEFT
			elif col == length_tiles - 1:
				fill_tile = T_STONE_RIGHT
			ground.set_cell(Vector2i(col, r), src_id, fill_tile)

func _setup_background(length_tiles: int) -> void:
	var bg_set = BG_SETS[(stage - 1) % BG_SETS.size()]
	var repeat_times = int(ceil(length_tiles * TILE / 1152.0)) + 1
	_layer_texture(sky, bg_set[0], repeat_times)
	_layer_texture(bg_mid, bg_set[1], repeat_times)
	_layer_texture(bg_near, bg_set[2], repeat_times)

func _layer_texture(layer: Parallax2D, tex_uid: String, repeat_times: int) -> void:
	layer.repeat_size = Vector2(1152, 0)
	layer.repeat_times = repeat_times
	var spr : Sprite2D = layer.get_node("Sprite")
	var tex : Texture2D = load(tex_uid)
	spr.texture = tex
	var s = 1152.0 / 1920.0
	spr.scale = Vector2(s, s)

func _pick_enemy_uid() -> String:
	var pool : Array = REGULAR_UIDS.duplicate()
	if stage >= 2:
		pool.append(RUNNER_UID)
		pool.append(RUNNER_UID)
	if stage >= 3:
		pool.append(TANK_UID)
	if stage >= 4:
		pool.append(THROWER_UID)
		pool.append(THROWER_UID)
	return pool[randi() % pool.size()]

func _try_spawn_zombie() -> void:
	var ahead_x = player.global_position.x + 750.0
	if ahead_x > level_length_px - TILE * 2:
		return
	var uid = _pick_enemy_uid()
	var scene : PackedScene = load(uid)
	var z = scene.instantiate()
	z.position = Vector2(ahead_x, GROUND_TOP_Y - 40)
	z.speed *= speed_mult
	z.max_hp = max(1, int(round(z.max_hp * hp_mult)))
	z.direction = -1
	enemies_node.add_child(z)
	enemies_spawned += 1

func _spawn_boss() -> void:
	var ahead_x = min(player.global_position.x + 900.0, level_length_px - TILE * 3)
	var scene : PackedScene = load(BOSS_UID)
	var z = scene.instantiate()
	z.position = Vector2(ahead_x, GROUND_TOP_Y - 40)
	z.direction = -1
	enemies_node.add_child(z)
	AudioManager.boss_sfx.play()

func _try_spawn_coin() -> void:
	var ahead_x = player.global_position.x + randf_range(300.0, 700.0)
	if ahead_x > level_length_px - TILE * 2:
		return
	var coin_scene : PackedScene = load("uid://bfmh3fm2de78o")
	var c = coin_scene.instantiate()
	c.position = Vector2(ahead_x, GROUND_TOP_Y - 60)
	coins_node.add_child(c)

func _on_finish_entered(body: Node2D) -> void:
	if finished:
		return
	if not body.is_in_group("Player"):
		return
	finished = true
	AudioManager.level_complete_sfx.play()
	if stage >= FINAL_STAGE:
		GameManager.finalize_run()
		SceneTransition.load_scene(load("res://Scenes/Levels/game_win.tscn"))
	else:
		GameManager.advance_stage()
		SceneTransition.load_scene(load("res://Scenes/Levels/endless_level.tscn"))

func _on_player_hit_enemy(damage: int) -> void:
	GameManager.damage(damage)

func _on_player_hit_trap() -> void:
	GameManager.damage(20)

func _on_music_player_finished() -> void:
	music_player.play(0)
