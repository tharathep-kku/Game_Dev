class_name Player
extends CharacterBody2D

signal hit_enemy(damage: int)
signal hit_trap


# --------- VARIABLES ---------- #

@export_category("Player Properties") # You can tweak these changes according to your likings
@export var move_speed : float = 300
@export var run_speed_multiplier : float = 1.5
var is_running : bool = false
@export var jump_force : float = 650
@export var gravity : float = 30
@export var max_jump_count : int = 2
@export var bullet_scene : PackedScene
@export var shoot_cooldown_time : float = 0.2
@export var bullet_lifetime = 2.0
@export var bomb_projectile_scene : PackedScene
@export var jetpack_thrust : float = 900.0
@export var jetpack_drain_rate : float = 1.0
@export var bomb_throw_cooldown : float = 0.5
@export var max_ammo : int = 12
@export var reload_time : float = 1.4

var jump_count : int = 2

@export_category("Toggle Functions") # Double jump feature is disable by default (Can be toggled from inspector)
@export var double_jump : = false

var is_grounded : bool = false
var movement_enabled : bool = true
var spawn_point = Vector2(0,0)
var is_attacking = false
var shoot_cooldown_timer = 0.0
var can_damage = true
var fell_in_pit = false

var jetpack_fuel : float = 0.0
var shield_time_left : float = 0.0
var bomb_count : int = 0
var bomb_throw_timer : float = 0.0

var ammo : int
var reloading : bool = false
var reload_timer : float = 0.0

@onready var player_sprite : AnimatedSprite2D = $soldier/AnimatedSprite2D
@onready var player_node = $soldier
@onready var bullet_marker = $BulletMarker
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles
@onready var shield_visual = $ShieldVisual



# --------- BUILT-IN FUNCTIONS ---------- #
func _ready() -> void:
	spawn_point = global_position
	if GameManager.save_player_position.x != 0:
		global_position =  GameManager.save_player_position
		GameManager.save_player_position = Vector2.ZERO
	player_sprite.animation_finished.connect(_on_animation_finished)
	ammo = max_ammo
	
func _physics_process(_delta):
	is_grounded = is_on_floor()
	movement()

func _process(_delta):
	player_animations()
	flip_player()
	handle_shooting()
	handle_bomb_throw()
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= _delta
	if bomb_throw_timer > 0:
		bomb_throw_timer -= _delta
	if shield_time_left > 0:
		shield_time_left -= _delta
		shield_visual.visible = true
	else:
		shield_visual.visible = false
	if reloading:
		reload_timer -= _delta
		if reload_timer <= 0:
			reloading = false
			ammo = max_ammo
	
# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement():
	# Gravity
	if !is_on_floor():
		velocity.y += gravity
	elif is_on_floor():
		jump_count = max_jump_count
		velocity.x = 0
		fell_in_pit = false

	# Jetpack thrust: hold Jump while airborne with fuel to counter gravity
	if !is_on_floor() and jetpack_fuel > 0 and Input.is_action_pressed("Jump") and movement_enabled:
		velocity.y = max(velocity.y - jetpack_thrust * get_physics_process_delta_time(), -jetpack_thrust)
		jetpack_fuel = max(jetpack_fuel - jetpack_drain_rate * get_physics_process_delta_time(), 0.0)
		particle_trails.emitting = true

	handle_jumping()

	is_running = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = move_speed * (run_speed_multiplier if is_running else 1.0)

	# Move Player
	if movement_enabled:
		if Input.is_action_pressed("Left"):
			velocity.x = -current_speed # แก้ไข: เปลี่ยนจาก -move_speed เป็น -current_speed
		if Input.is_action_pressed("Right"):
			velocity.x = current_speed  # แก้ไข: เปลี่ยนจาก move_speed เป็น current_speed
	if velocity.y > 5000 and !fell_in_pit:
		fell_in_pit = true
		if can_damage and !is_shielded():
			hit_trap.emit()
		# hit_trap only deals damage; if that damage wasn't lethal (GameManager
		# didn't start a death/respawn sequence) -- including when it was
		# skipped entirely above due to i-frames/shield -- the fall would
		# otherwise continue forever with nothing to bring the player back.
		# Force them back to their spawn point directly so a pit-fall can
		# never leave them stuck falling through the void alive.
		if not GameManager.is_dying:
			velocity = Vector2.ZERO
			global_position = spawn_point
	move_and_slide()

# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping():
	if Input.is_action_just_pressed("Jump") and movement_enabled:
		if is_on_floor() and !double_jump:
			jump()
		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1

# Player jump
func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

# Handle Player Animations
func player_animations():
	particle_trails.emitting = false
	if is_attacking:
		return
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			if is_running:
				player_sprite.play("run")
			else:
				player_sprite.play("walk")
		else:
			player_sprite.play("idle")
	else:
		player_sprite.play("idle")


# Flip player sprite based on X velocity
# Flip player sprite based on X velocity
func flip_player():
	if velocity.x < 0: 
		player_node.scale.x = -1
		# สั่งกลับด้านตำแหน่ง X ของ BulletMarker เมื่อหันซ้าย
		bullet_marker.position.x = -abs(bullet_marker.position.x)
	elif velocity.x > 0:
		player_node.scale.x = 1
		# สั่งคืนค่าตำแหน่ง X ของ BulletMarker เมื่อหันขวา
		bullet_marker.position.x = abs(bullet_marker.position.x)

# Tween Animations
func death_tween():
	AudioManager.death_sfx.play()
	death_particles.emitting = true
	movement_enabled = false
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x,position.y-100), 0.15)
	await tween.finished
	global_position = spawn_point
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) 
	tween.parallel().tween_property(self, "position", spawn_point, 0.15)

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0,1.0), 0.1)

func damage_tween():
	var tween = create_tween() 
	tween.stop(); tween.play()
	can_damage = false
	for i in range(1,10):
		tween.tween_property(player_node , "modulate", Color.RED, 0.1)
		tween.tween_property(player_node , "modulate", Color.WHITE, 0.1)
	await tween.finished
	can_damage = true
# --------- SIGNALS ---------- #

# Reset the player's position to the current level spawn point if collided with any trap
func _on_collision_body_entered(body):
	if !can_damage : return
	if is_shielded() : return
	if body.is_in_group("Traps"):
		damage_tween()
		hit_trap.emit()
		return
	if body.is_in_group("Enemy"):
		var dx = body.position.x - position.x
		velocity.y = -400
		if dx > 0:
			velocity.x = -300
		else:
			velocity.x = 300
		damage_tween()
		var dmg = body.get("contact_damage")
		hit_enemy.emit(dmg if dmg != null else 5)

func handle_shooting():
	if Input.is_action_just_pressed("Reload") and movement_enabled and !reloading and ammo < max_ammo:
		start_reload()
	if Input.is_action_just_pressed("Shoot") and movement_enabled and shoot_cooldown_timer <= 0 and !reloading:
		shoot()

func start_reload():
	if reloading:
		return
	reloading = true
	reload_timer = reload_time
	AudioManager.reload_sfx.play()

func shoot():
	if bullet_scene == null:
		return
	if ammo <= 0:
		start_reload()
		return
	ammo -= 1
	is_attacking = true
	player_sprite.play("attack") # แก้ไข: เปลี่ยนจาก "Attack" เป็น "attack"
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_marker.global_position
	#var angle = deg_to_rad(randf_range(0, 20))
	var sign_x = 1.0 if player_node.scale.x > 0 else -1.0
	#var dir = Vector2(cos(angle) * sign_x, -sin(angle))
	var dir = Vector2(sign_x, 0)
	get_parent().add_child(bullet)
	bullet.shoot(dir, 600, bullet_lifetime)
	AudioManager.Gun_Sound_sfx.play()
	shoot_cooldown_timer = shoot_cooldown_time
	if ammo <= 0:
		start_reload()
	await get_tree().create_timer(0.25).timeout
	is_attacking = false
	
func _on_animation_finished() -> void:
	# แก้ไข: AnimatedSprite2D ไม่มี parameter และเช็กชื่อแอนิเมชันด้วย .animation
	if player_sprite.animation == "attack":
		is_attacking = false

# --------- ITEM FUNCTIONS ---------- #

func add_jetpack_fuel(amount: float) -> void:
	jetpack_fuel += amount

func activate_shield(duration: float) -> void:
	shield_time_left = max(shield_time_left, duration)

func is_shielded() -> bool:
	return shield_time_left > 0

func add_bombs(amount: int) -> void:
	bomb_count += amount

func handle_bomb_throw() -> void:
	if bomb_projectile_scene == null:
		return
	if !movement_enabled or bomb_count <= 0 or bomb_throw_timer > 0:
		return
	if Input.is_action_just_pressed("Bomb"):
		var bomb = bomb_projectile_scene.instantiate()
		bomb.global_position = bullet_marker.global_position
		var sign_x = 1.0 if player_node.scale.x > 0 else -1.0
		get_parent().add_child(bomb)
		bomb.launch(Vector2(sign_x * 350.0, -300.0))
		AudioManager.throw_sfx.play()
		bomb_count -= 1
		bomb_throw_timer = bomb_throw_cooldown
