extends Node3D

# ---------- VARIABLES ---------- #

var score = 0
var total_coins = 0

# ---------- FUNCTIONS ---------- #

func _ready():
	total_coins = get_tree().get_nodes_in_group("Coin").size()

func _process(_delta):
	show_mouse_cursor()

# Making Cursor visible using "mouse_visible" key which is assigned in Project Settings > Input Map
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_score():
	score += 1

func all_coins_collected() -> bool:
	return total_coins > 0 and score >= total_coins
