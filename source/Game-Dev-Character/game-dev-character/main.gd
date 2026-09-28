extends Node

# Thana stalks in a circle around the cubicles, stops to peek over the partition, repeats.
const CENTER := Vector3(0, 0, -2.2)
const RADIUS := 2.3
const SPEED := 1.1          # m/s along the circle
const PEEK_ANGLE := PI / 2  # stop beside the right-hand cubicle wall
const PEEK_TIME := 72.0 / 30.0

@onready var thana: Node3D = %Thana
@onready var flicker: OmniLight3D = %FlickerLight

var angle := 0.0
var peek_left := 0.0
var peeked := false


func _ready() -> void:
	for n in get_tree().get_nodes_in_group("psx"):
		_psx_materials(n)
	_play(%Pim, "Type")
	_play(%Ton, "Bow")
	_play(thana, "Stalk")
	_place_thana(Vector3(cos(angle), 0, -sin(angle)))

	var args := OS.get_cmdline_user_args()
	var i := args.find("--shot")
	if i != -1:  # godot --path . -- --shot out.png [seconds]
		await get_tree().create_timer(float(args[i + 2]) if args.size() > i + 2 else 3.0).timeout
		get_viewport().get_texture().get_image().save_png(args[i + 1])
		get_tree().quit()


func _process(delta: float) -> void:
	flicker.light_energy = 0.0 if randf() < 0.04 else 1.3

	if peek_left > 0.0:
		peek_left -= delta
		if peek_left <= 0.0:
			_play(thana, "Stalk")
		return

	angle = fmod(angle + SPEED / RADIUS * delta, TAU)
	if not peeked and absf(angle - PEEK_ANGLE) < 0.05:
		peeked = true
		peek_left = PEEK_TIME
		_play(thana, "Peek")
		_place_thana(CENTER - _circle_pos())  # face the partition
		return
	if absf(angle - PEEK_ANGLE) > 0.5:
		peeked = false
	_place_thana(Vector3(cos(angle), 0, -sin(angle)))  # face along the circle


func _circle_pos() -> Vector3:
	return CENTER + Vector3(sin(angle), 0, cos(angle)) * RADIUS


func _place_thana(facing: Vector3) -> void:
	thana.position = _circle_pos()
	thana.rotation.y = atan2(facing.x, facing.z)  # models face +Z


func _play(character: Node, anim: String) -> void:
	var ap: AnimationPlayer = character.find_child("AnimationPlayer", true, false)
	ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	ap.play(anim)


# Nearest filtering, no mipmaps: crisp PSX texels and no palette bleed at distance.
func _psx_materials(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if m:
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
