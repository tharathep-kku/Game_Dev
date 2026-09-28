extends SceneTree
# Dev tool: (re)generates Level_01.tscn, Level_02.tscn, level_03.tscn, level_04.tscn
# from plain data below, using the new zombie-themed TileSet + Kenney art.
# Run with: Godot_v4.7-stable_win64_console.exe --headless --path . --script tools/build_levels.gd
# Re-run any time to regenerate the levels after tweaking the layouts below.

const TILE := 64

# --- Atlas coords in Scenes/Prefabs/zombie_tile_set.tres ---
const T_STONE_TOP := Vector2i(15, 15)
const T_STONE_TOPLEFT := Vector2i(16, 15)
const T_STONE_TOPRIGHT := Vector2i(17, 15)
const T_STONE_CENTER := Vector2i(12, 15)
const T_STONE_LEFT := Vector2i(13, 15)
const T_STONE_RIGHT := Vector2i(14, 15)
const T_DIRT_TOP := Vector2i(1, 8)
const T_DIRT_FILL := Vector2i(12, 7)
const T_CLOUD_LEFT := Vector2i(2, 16)
const T_CLOUD_MID := Vector2i(3, 16)
const T_CLOUD_RIGHT := Vector2i(4, 16)
const T_TORCH_ON := Vector2i(1, 17)
const T_LADDER_MID := Vector2i(12, 5)

# --- UIDs of resources referenced while building levels ---
const TILESET_UID := "uid://dk4qcax1suy2c"
const FINISH_DOOR_UID := "uid://cyti38f0lagf2"
const GAME_UI_UID := "uid://cdwabmqtlxr1y"
const PLAYER2_UID := "uid://douri0f526muw"
const THEME_UID := "uid://d3eng5cvycmjf"
const GAME_WIN_UID := "uid://b46lxwc5r3dy4"

const COIN_UID := "uid://bfmh3fm2de78o"
const HEAL_POTION_UID := "uid://dabag2r57aued"
const BOMB_PICKUP_UID := "uid://bbombpickup01a"
const SHIELD_PICKUP_UID := "uid://bshieldpickup01"
const JETPACK_PICKUP_UID := "uid://bjetpackpickup1"

const TRAP1_UID := "uid://cb8e62red7kc0"
const TRAP2_UID := "uid://bp4l1nlnh8oq1"
const TRAP_BLADE_UID := "uid://c8k4n0q7blade1"
const TRAP_LAVA_UID := "uid://d3n9p2q7lava01"

const MOVING_PLATFORM_UID := "uid://bmp1a2b3c4d5e"
const ELEVATOR_UID := "uid://belev01a2b3c4"
const JUMP_BOARD_UID := "uid://bjb01a2b3c4d5"
const PORTAL_GATE_UID := "uid://bportal01a2b3c"
const KILL_ZONE_UID := "uid://dkillzone001a"

const ZOMBIE1_UID := "uid://bb11am1mk0iuh"
const ZOMBIE2_UID := "uid://b7c8maoe37ao7"
const ZOMBIE3_UID := "uid://d0kgmlffowerk"
const ZOMBIE4_UID := "uid://dzombiefour01a"

const MUSIC_WALEN_UID := "uid://dhmn57nc23ah1"
const MUSIC_ALT_UID := "uid://bg6nultq2n7y2"

# --- Postapocalypse parallax background layers (Assets/Backgrounds/) ---
const BG1_FAR := "uid://cptmpjo7ss0wj"   # Postapocalypse1/clouds1.png
const BG1_MID := "uid://bg65vo7swbktg"   # Postapocalypse1/ground_houses_bg.png
const BG1_NEAR := "uid://bc3i0l4a8d47x"  # Postapocalypse1/ground_houses.png
const BG2_FAR := "uid://bkh6fbwg1qxyb"   # Postapocalypse2/sky.png
const BG2_MID := "uid://ftg1ik64i0mu"    # Postapocalypse2/houses_trees_bg.png
const BG2_NEAR := "uid://bwjmpmxk3vuqe"  # Postapocalypse2/houses.png
const BG3_FAR := "uid://by2e8ivvsstk3"   # Postapocalypse3/sky.png
const BG3_MID := "uid://0xkot2lwm6ti"    # Postapocalypse3/sand_back.png
const BG3_NEAR := "uid://pfshim4fwt2q"   # Postapocalypse3/sand_objects1.png
const BG4_FAR := "uid://3nim61n2adlt"    # Postapocalypse4/bg.png
const BG4_MID := "uid://p4848y71wwoq"    # Postapocalypse4/rail_wall.png
const BG4_NEAR := "uid://c1mijb0ed1wqi"  # Postapocalypse4/columns_floor.png

var tileset : TileSet
var tileset_src_id : int

func _init():
	call_deferred("_run")

func _run():
	tileset = load(TILESET_UID)
	tileset_src_id = tileset.get_source_id(0)

	build_level_01()
	build_level_02()
	build_level_03()
	build_level_04()

	print("ALL_LEVELS_BUILT")
	quit()

# ---------------------------------------------------------------- helpers --

func new_root(name: String) -> Node2D:
	var n := Node2D.new()
	n.name = name
	return n

func add_plain(root: Node, parent: Node, cls: String, name: String) -> Node:
	var n : Node = ClassDB.instantiate(cls)
	n.name = name
	parent.add_child(n)
	n.owner = root
	return n

func add_inst(root: Node, parent: Node, scene_uid: String, pos: Vector2, name: String = "") -> Node:
	var ps : PackedScene = load(scene_uid)
	var n : Node = ps.instantiate()
	if n is Node2D:
		(n as Node2D).position = pos
	if name != "":
		n.name = name
	parent.add_child(n)
	n.owner = root
	return n

func paint_strip(tml: TileMapLayer, c0: int, c1: int, top_row: int, thickness: int, dirt := false) -> void:
	var top_tile = T_DIRT_TOP if dirt else T_STONE_TOP
	for col in range(c0, c1 + 1):
		var t = top_tile
		if not dirt:
			if col == c0 and c0 != c1:
				t = T_STONE_TOPLEFT
			elif col == c1 and c0 != c1:
				t = T_STONE_TOPRIGHT
		tml.set_cell(Vector2i(col, top_row), tileset_src_id, t)
		for r in range(top_row + 1, top_row + thickness):
			var fill = T_DIRT_FILL if dirt else T_STONE_CENTER
			if not dirt:
				if col == c0 and c0 != c1:
					fill = T_STONE_LEFT
				elif col == c1 and c0 != c1:
					fill = T_STONE_RIGHT
			tml.set_cell(Vector2i(col, r), tileset_src_id, fill)

func paint_platform(tml: TileMapLayer, c0: int, c1: int, row: int) -> void:
	for col in range(c0, c1 + 1):
		var t = T_CLOUD_MID
		if col == c0 and c0 != c1:
			t = T_CLOUD_LEFT
		elif col == c1 and c0 != c1:
			t = T_CLOUD_RIGHT
		tml.set_cell(Vector2i(col, row), tileset_src_id, t)

func add_torch(tml: TileMapLayer, col: int, row: int) -> void:
	tml.set_cell(Vector2i(col, row), tileset_src_id, T_TORCH_ON)

func add_parallax_layer(root: Node, parent: Node, name: String, bg_uid: String, scroll: float, z: int, tex_native_w: float, level_repeat_times: int) -> void:
	var layer := Parallax2D.new()
	layer.name = name
	layer.z_index = z
	layer.scroll_scale = Vector2(scroll, scroll)
	layer.repeat_size = Vector2(1152, 0)
	layer.repeat_times = level_repeat_times
	parent.add_child(layer)
	layer.owner = root

	var tex : Texture2D = load(bg_uid)
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = tex
	var s = 1152.0 / tex_native_w
	spr.scale = Vector2(s, s)
	spr.position = Vector2(576, 260)
	layer.add_child(spr)
	spr.owner = root

func add_hint(root: Node, text_parent: Node, pos: Vector2, txt: String, theme: Theme) -> void:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.theme = theme
	text_parent.add_child(l)
	l.owner = root

func build_base(level_name: String, label_text: String, music_uid: String) -> Dictionary:
	var root := new_root(level_name)
	root.set_script(load("res://Scenes/Levels/base_level.gd"))

	var door := add_inst(root, root, FINISH_DOOR_UID, Vector2.ZERO, "LevelFinishDoor")
	door.z_index = 1

	var level_node := add_plain(root, root, "Node2D", "Level")

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	level_node.add_child(ground)
	ground.owner = root

	var player := add_inst(root, root, PLAYER2_UID, Vector2(100, 257), "Player2")

	var coins := add_plain(root, root, "Node2D", "Coins")
	coins.z_index = 2
	var enemies := add_plain(root, root, "Node2D", "Enemies")

	var ui := add_inst(root, root, GAME_UI_UID, Vector2.ZERO, "UserInterface")
	var theme : Theme = load(THEME_UID)
	var intro_label := Label.new()
	intro_label.name = "Label"
	intro_label.theme = theme
	intro_label.anchor_left = 0.5
	intro_label.anchor_top = 0.5
	intro_label.anchor_right = 0.5
	intro_label.anchor_bottom = 0.5
	intro_label.offset_left = -99.0
	intro_label.offset_top = -39.5
	intro_label.offset_right = 99.0
	intro_label.offset_bottom = 39.5
	intro_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	intro_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	intro_label.add_theme_font_size_override("font_size", 60)
	intro_label.add_theme_color_override("font_color", Color(0.5529412, 0.38431373, 1, 1))
	intro_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	intro_label.add_theme_constant_override("outline_size", 10)
	intro_label.text = label_text
	intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(intro_label)
	intro_label.owner = root

	var text_node := add_plain(root, root, "Node2D", "Text")

	var music := AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	music.stream = load(music_uid)
	music.bus = &"music"
	root.add_child(music)
	music.owner = root

	player.connect("hit_enemy", Callable(root, "_on_player_hit_enemy"), CONNECT_PERSIST)
	player.connect("hit_trap", Callable(root, "_on_player_hit_trap"), CONNECT_PERSIST)
	music.connect("finished", Callable(root, "_on_music_player_finished"), CONNECT_PERSIST)

	return {
		"root": root,
		"door": door,
		"level_node": level_node,
		"ground": ground,
		"player": player,
		"coins": coins,
		"enemies": enemies,
		"text_node": text_node,
		"theme": theme,
	}

func strip_redundant_self_connections(node: Node) -> void:
	# Nodes that are roots of an instanced sub-scene (e.g. Coin, HealPotion,
	# LevelFinishDoor) already wire up their own self->self signal
	# connections inside their own .tscn file. PackedScene.pack() called
	# manually (unlike the editor's scene-diff save) re-captures those as
	# extra top-level connections, causing a harmless but noisy "already
	# connected" error the next time the saved scene is instantiated. Since
	# they'll be re-established correctly by the sub-scene's own instancing
	# anyway, strip them here before packing.
	if node.scene_file_path != "":
		for sig in node.get_signal_list():
			for conn in node.get_signal_connection_list(sig["name"]):
				var callable : Callable = conn["callable"]
				if callable.get_object() == node:
					node.disconnect(sig["name"], callable)
	for child in node.get_children():
		strip_redundant_self_connections(child)

func finish_level(ctx: Dictionary, output_path: String) -> void:
	var root : Node = ctx["root"]
	strip_redundant_self_connections(root)
	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		print("PACK FAILED for ", output_path, " code=", result)
	else:
		var save_result := ResourceSaver.save(packed, output_path)
		print("Saved ", output_path, " -> ", save_result)
	root.free()

func px(col: float, row: float) -> Vector2:
	return Vector2(col * TILE, row * TILE)

func place_trap(ctx: Dictionary, kind: String, pos: Vector2, rot := 0.0, name := "") -> Node:
	var uid := TRAP1_UID
	match kind:
		"trap1": uid = TRAP1_UID
		"trap2": uid = TRAP2_UID
		"blade": uid = TRAP_BLADE_UID
		"lava": uid = TRAP_LAVA_UID
	var n := add_inst(ctx["root"], ctx["level_node"], uid, pos, name) as Node2D
	n.rotation = rot
	return n

func place_item(ctx: Dictionary, kind: String, pos: Vector2, name := "") -> Node:
	var uid := COIN_UID
	match kind:
		"coin": uid = COIN_UID
		"heal": uid = HEAL_POTION_UID
		"bomb": uid = BOMB_PICKUP_UID
		"shield": uid = SHIELD_PICKUP_UID
		"jetpack": uid = JETPACK_PICKUP_UID
	return add_inst(ctx["root"], ctx["coins"], uid, pos, name)

func place_enemy(ctx: Dictionary, kind: String, pos: Vector2, name := "") -> Node:
	# All enemy call sites still use these legacy labels, but every one of
	# them now resolves to a zombie-skinned variant (Zombie_1..Zombie_4 from
	# Assets/Free-Urban-Zombie-Sprite-Sheet-Pixel-Art-Pack) so nothing in the
	# game reads as a fantasy mushroom/slime monster.
	var uid := ZOMBIE1_UID
	match kind:
		"mushroom1": uid = ZOMBIE1_UID
		"mushroom2": uid = ZOMBIE2_UID
		"mushroom": uid = ZOMBIE3_UID
		"slim": uid = ZOMBIE4_UID
	return add_inst(ctx["root"], ctx["enemies"], uid, pos, name)

func place_moving_platform(ctx: Dictionary, pos: Vector2, offset: Vector2, name := "MovingPlatform") -> Node:
	var n := add_inst(ctx["root"], ctx["level_node"], MOVING_PLATFORM_UID, pos, name)
	n.set("offset", offset)
	return n

func place_elevator(ctx: Dictionary, pos: Vector2, stops: Array[Vector2], name := "Elevator") -> Node:
	var n := add_inst(ctx["root"], ctx["level_node"], ELEVATOR_UID, pos, name)
	n.set("stop_offsets", stops)
	if n.get("stop_offsets")[0] != stops[0] or n.get("stop_offsets").size() != stops.size():
		push_error("stop_offsets failed to apply on " + name)
	return n

func place_jump_board(ctx: Dictionary, pos: Vector2, name := "JumpBoard") -> Node:
	return add_inst(ctx["root"], ctx["level_node"], JUMP_BOARD_UID, pos, name)

func place_portal_pair(ctx: Dictionary, pos_a: Vector2, pos_b: Vector2, name_a := "PortalA", name_b := "PortalB") -> Array:
	var a := add_inst(ctx["root"], ctx["level_node"], PORTAL_GATE_UID, pos_a, name_a)
	var b := add_inst(ctx["root"], ctx["level_node"], PORTAL_GATE_UID, pos_b, name_b)
	a.set("linked_portal_path", a.get_path_to(b))
	b.set("linked_portal_path", b.get_path_to(a))
	a.set("modulate", Color(0.35, 0.75, 1.0))
	b.set("modulate", Color(1.0, 0.55, 0.25))
	return [a, b]

# Wide safety-net Area2D placed well below any level's lowest painted tile so
# a player who somehow falls past a MovingPlatform/Elevator/gap can never be
# left falling through the void forever -- forces damage + a respawn.
func place_kill_zone(ctx: Dictionary, center_x_px: float) -> Node:
	return add_inst(ctx["root"], ctx["level_node"], KILL_ZONE_UID, Vector2(center_x_px, 1400.0), "KillZone")

func repeat_times_for(width_tiles: int) -> int:
	return int(ceil(width_tiles * TILE / 1152.0)) + 1

# ---------------------------------------------------------------- Level 1 --

func build_level_01() -> void:
	var ctx := build_base("Level_01", "Level 1", MUSIC_WALEN_UID)
	var root = ctx["root"]
	var tml : TileMapLayer = ctx["ground"]
	var lvl = ctx["level_node"]
	var rt := repeat_times_for(62)

	add_parallax_layer(root, lvl, "Sky", BG1_FAR, 0.05, -12, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background1", BG1_MID, 0.2, -10, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background2", BG1_NEAR, 0.45, -9, 1920.0, rt)

	paint_strip(tml, 0, 9, 9, 5)
	paint_strip(tml, 13, 22, 9, 5)
	paint_strip(tml, 30, 40, 9, 5)
	paint_platform(tml, 34, 36, 6)
	paint_strip(tml, 44, 58, 9, 5)
	paint_platform(tml, 44, 46, 3)
	paint_strip(tml, 60, 62, 5, 3)

	place_trap(ctx, "trap1", px(15.5, 8.5), 0.0, "Trap1")
	place_trap(ctx, "trap2", px(18.5, 8.0), 0.0, "Trap2")
	place_trap(ctx, "blade", px(33.5, 8.0), 0.0, "TrapBlade1")
	place_trap(ctx, "lava", px(37.0, 8.5), 0.0, "TrapLava1")

	place_moving_platform(ctx, px(23.5, 9.5), Vector2(6 * TILE, 0), "MovingPlatform1")
	place_jump_board(ctx, px(44.5, 8.5), "JumpBoard1")
	place_elevator(ctx, px(59.5, 9.5), [Vector2.ZERO, Vector2(0, -4 * TILE)], "Elevator1")

	place_item(ctx, "heal", px(16.5, 7.5), "HealPotion")
	place_item(ctx, "bomb", px(39.5, 8.0), "BombPickup")
	place_item(ctx, "shield", px(45.5, 2.5), "ShieldPickup")
	for c in [3, 6, 19, 20, 21, 35, 45, 46, 61]:
		place_item(ctx, "coin", px(c + 0.5, 8.0), "Coin%d" % c)

	place_enemy(ctx, "mushroom1", px(5.5, 8.0), "Enemy1")
	place_enemy(ctx, "mushroom1", px(16.5, 8.0), "Enemy2")
	place_enemy(ctx, "mushroom2", px(31.5, 8.0), "Enemy3")
	place_enemy(ctx, "mushroom1", px(38.5, 8.0), "Enemy4")
	place_enemy(ctx, "mushroom2", px(50.5, 8.0), "Enemy5")

	var door : Node2D = ctx["door"]
	door.position = px(61.5, 5.5)
	door.set("next_scene", load("res://Scenes/Levels/Level_02.tscn"))

	var theme = ctx["theme"]
	add_hint(root, ctx["text_node"], Vector2(-57, 105), "นี่เป็นด่านตัวอย่าง\nA D เพื่อเดิน  Space กระโดด\nX ยิงบอลไฟ  C ขว้างระเบิด", theme)
	add_hint(root, ctx["text_node"], Vector2(1400, 300), "ใช้แท่นเลื่อน (MovingPlatform)\nข้ามหุบเหว", theme)
	add_hint(root, ctx["text_node"], Vector2(3760, 250), "ขึ้นลิฟต์ (Elevator)\nเพื่อไปประตูทางออก", theme)

	place_kill_zone(ctx, 3000.0)

	finish_level(ctx, "res://Scenes/Levels/Level_01.tscn")

# ---------------------------------------------------------------- Level 2 --

func build_level_02() -> void:
	var ctx := build_base("Level_02", "Level 2", MUSIC_ALT_UID)
	var root = ctx["root"]
	var tml : TileMapLayer = ctx["ground"]
	var lvl = ctx["level_node"]
	var rt := repeat_times_for(58)

	add_parallax_layer(root, lvl, "Sky", BG2_FAR, 0.05, -12, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background1", BG2_MID, 0.2, -10, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background2", BG2_NEAR, 0.45, -9, 1920.0, rt)

	paint_strip(tml, 0, 8, 9, 5, true)
	paint_strip(tml, 12, 20, 9, 5)
	paint_strip(tml, 21, 21, 9, 5)
	paint_strip(tml, 21, 24, 4, 2)
	# c25..29 intentionally left empty: bottomless chasm, cross via portal only
	paint_strip(tml, 30, 42, 9, 5)
	paint_strip(tml, 46, 56, 9, 5)

	place_trap(ctx, "lava", px(15.0, 8.5), 0.0, "TrapLava1")
	place_trap(ctx, "trap2", px(18.5, 8.0), 0.0, "Trap2")
	place_trap(ctx, "blade", px(33.5, 8.0), 0.0, "TrapBlade1")

	place_elevator(ctx, px(21.5, 9.5), [Vector2.ZERO, Vector2(0, -5 * TILE)], "Elevator1")
	place_portal_pair(ctx, px(23.5, 3.5), px(30.5, 8.5), "PortalA", "PortalB")

	place_item(ctx, "jetpack", px(14.5, 7.5), "JetpackPickup")
	place_item(ctx, "heal", px(22.5, 3.5), "HealPotion")
	place_item(ctx, "bomb", px(36.5, 8.0), "BombPickup")
	for c in [4, 13, 19, 23, 32, 40, 48, 52]:
		place_item(ctx, "coin", px(c + 0.5, 8.0), "Coin%d" % c)

	place_enemy(ctx, "mushroom1", px(3.5, 8.0), "Enemy1")
	place_enemy(ctx, "mushroom2", px(23.5, 3.0), "Enemy2")
	place_enemy(ctx, "slim", px(32.5, 8.0), "Enemy3")
	place_enemy(ctx, "mushroom1", px(40.5, 8.0), "Enemy4")
	place_enemy(ctx, "mushroom2", px(50.5, 8.0), "Enemy5")

	var door : Node2D = ctx["door"]
	door.position = px(54.5, 8.5)
	door.set("next_scene", load("res://Scenes/Levels/level_03.tscn"))

	var theme = ctx["theme"]
	add_hint(root, ctx["text_node"], Vector2(200, 250), "เก็บ Jetpack แล้วกด Space ค้างกลางอากาศ\nเพื่อบินขึ้น", theme)
	add_hint(root, ctx["text_node"], Vector2(1350, 100), "ขึ้นลิฟต์แล้วเดินเข้าประตูวาร์ป\nเพื่อข้ามเหว", theme)

	place_kill_zone(ctx, 3000.0)

	finish_level(ctx, "res://Scenes/Levels/Level_02.tscn")

# ---------------------------------------------------------------- Level 3 --

func build_level_03() -> void:
	var ctx := build_base("Level_03", "Level 3", MUSIC_WALEN_UID)
	var root = ctx["root"]
	var tml : TileMapLayer = ctx["ground"]
	var lvl = ctx["level_node"]
	var rt := repeat_times_for(58)

	add_parallax_layer(root, lvl, "Sky", BG3_FAR, 0.05, -12, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background1", BG3_MID, 0.2, -10, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background2", BG3_NEAR, 0.45, -9, 1920.0, rt)

	paint_strip(tml, 0, 7, 9, 5, true)
	paint_strip(tml, 11, 19, 9, 5)
	# c20..27 intentionally left empty: wide chasm, cross via moving platform
	paint_strip(tml, 28, 39, 9, 5)
	paint_platform(tml, 38, 40, 4)
	# c40..44 intentionally left empty: gap, cross via portal
	paint_strip(tml, 45, 56, 9, 5)

	place_trap(ctx, "trap1", px(13.5, 8.5), 0.0, "Trap1")
	place_trap(ctx, "blade", px(17.5, 8.0), 0.0, "TrapBlade1")
	place_trap(ctx, "lava", px(31.0, 8.5), 0.0, "TrapLava1")
	place_trap(ctx, "trap2", px(35.5, 8.0), 0.0, "Trap2")

	place_moving_platform(ctx, px(19.5, 9.5), Vector2(8 * TILE, 0), "MovingPlatform1")
	place_jump_board(ctx, px(38.5, 8.5), "JumpBoard1")
	place_portal_pair(ctx, px(39.5, 8.5), px(45.5, 8.5), "PortalA", "PortalB")

	place_item(ctx, "shield", px(4.5, 7.5), "ShieldPickup1")
	place_item(ctx, "shield", px(39.0, 3.5), "ShieldPickup2")
	place_item(ctx, "heal", px(29.5, 8.0), "HealPotion")
	for c in [14, 15, 16, 22, 24, 26, 48, 52]:
		place_item(ctx, "coin", px(c + 0.5, 8.0), "Coin%d" % c)

	place_enemy(ctx, "mushroom1", px(12.5, 8.0), "Enemy1")
	place_enemy(ctx, "slim", px(18.5, 8.0), "Enemy2")
	place_enemy(ctx, "mushroom2", px(30.5, 8.0), "Enemy3")
	place_enemy(ctx, "mushroom1", px(37.5, 8.0), "Enemy4")
	place_enemy(ctx, "mushroom2", px(48.5, 8.0), "Enemy5")

	var door : Node2D = ctx["door"]
	door.position = px(54.5, 8.5)
	door.set("next_scene", load("res://Scenes/Levels/level_04.tscn"))

	var theme = ctx["theme"]
	add_hint(root, ctx["text_node"], Vector2(150, 250), "โล่ (Shield) กันดาเมจชั่วคราว", theme)
	add_hint(root, ctx["text_node"], Vector2(2450, 100), "แท่นกระโดด (JumpBoard) เด้งขึ้นที่สูง", theme)

	place_kill_zone(ctx, 3000.0)

	finish_level(ctx, "res://Scenes/Levels/level_03.tscn")

# ---------------------------------------------------------------- Level 4 --

func build_level_04() -> void:
	var ctx := build_base("Level_04", "Level 4", MUSIC_ALT_UID)
	var root = ctx["root"]
	var tml : TileMapLayer = ctx["ground"]
	var lvl = ctx["level_node"]
	var rt := repeat_times_for(70)

	add_parallax_layer(root, lvl, "Sky", BG4_FAR, 0.05, -12, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background1", BG4_MID, 0.2, -10, 1920.0, rt)
	add_parallax_layer(root, lvl, "Background2", BG4_NEAR, 0.45, -9, 1920.0, rt)

	paint_strip(tml, 0, 9, 9, 5)
	add_torch(tml, 2, 8)
	add_torch(tml, 7, 8)
	paint_strip(tml, 13, 24, 9, 5)
	# c25..32 intentionally left empty: wide chasm, cross via moving platform
	paint_strip(tml, 33, 44, 9, 5)
	paint_strip(tml, 45, 48, 4, 2)
	paint_platform(tml, 47, 49, 0)
	# c49..57 intentionally left empty: bottomless chasm, cross via portal
	paint_strip(tml, 58, 68, 9, 5)
	add_torch(tml, 60, 8)
	add_torch(tml, 65, 8)

	place_trap(ctx, "blade", px(15.5, 8.0), 0.0, "TrapBlade1")
	place_trap(ctx, "lava", px(18.5, 8.5), 0.0, "TrapLava1")
	place_trap(ctx, "trap2", px(22.5, 8.0), 0.0, "Trap2")
	place_trap(ctx, "trap1", px(38.5, 8.5), 0.0, "Trap1")
	place_trap(ctx, "blade", px(41.5, 8.0), 0.0, "TrapBlade2")

	place_moving_platform(ctx, px(24.5, 9.5), Vector2(8 * TILE, 0), "MovingPlatform1")
	place_elevator(ctx, px(45.5, 9.5), [Vector2.ZERO, Vector2(0, -5 * TILE)], "Elevator1")
	place_jump_board(ctx, px(48.5, 3.5), "JumpBoard1")
	place_portal_pair(ctx, px(45.5, 3.5), px(58.5, 8.5), "PortalA", "PortalB")

	place_item(ctx, "jetpack", px(5.5, 7.5), "JetpackPickup")
	place_item(ctx, "bomb", px(17.5, 7.5), "BombPickup")
	place_item(ctx, "shield", px(35.5, 7.5), "ShieldPickup")
	place_item(ctx, "heal", px(46.5, 3.5), "HealPotion")
	for c in [46, 47, 48, 61, 63, 66]:
		place_item(ctx, "coin", px(c + 0.5, 3.5 if c < 50 else 8.0), "Coin%d" % c)

	place_enemy(ctx, "mushroom1", px(14.5, 8.0), "Enemy1")
	place_enemy(ctx, "slim", px(20.5, 8.0), "Enemy2")
	place_enemy(ctx, "mushroom2", px(23.5, 8.0), "Enemy3")
	place_enemy(ctx, "mushroom1", px(34.5, 8.0), "Enemy4")
	place_enemy(ctx, "mushroom2", px(43.5, 8.0), "Enemy5")
	place_enemy(ctx, "mushroom2", px(62.5, 8.0), "Enemy6")
	place_enemy(ctx, "mushroom1", px(66.5, 8.0), "Enemy7")

	var door : Node2D = ctx["door"]
	door.position = px(67.5, 8.5)
	door.set("next_scene", load(GAME_WIN_UID))

	var theme = ctx["theme"]
	add_hint(root, ctx["text_node"], Vector2(150, 250), "ด่านสุดท้าย! ใช้ทุกความสามารถที่เก็บมา", theme)
	add_hint(root, ctx["text_node"], Vector2(2950, 100), "ขึ้นลิฟต์ -> กระโดดโบนัส -> วาร์ปข้ามเหว", theme)

	place_kill_zone(ctx, 3000.0)

	finish_level(ctx, "res://Scenes/Levels/level_04.tscn")
