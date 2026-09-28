extends Control

# ---------- VARIABLES ---------- #

@onready var coinsLabel = $CoinsLabel

# ---------- FUNCTIONS ---------- #

func _process(_delta):
	coinsLabel.text = "x %d/%d" % [GameManager.score, GameManager.total_coins] # Set the coin label text to the score variable
