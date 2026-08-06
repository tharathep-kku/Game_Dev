extends RigidBody2D

var move_direction : Vector2 = Vector2.ZERO
var move_speed : float = 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func shoot(direction: Vector2, speed: float, lifetime: float):
	gravity_scale = 0.0
	move_direction = direction
	move_speed = speed
	rotation = direction.angle()
	
	# กำหนดความเร็วพุ่งไปข้างหน้า
	linear_velocity = direction * speed
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	# ถ้าเผลอไปชนตัวผู้เล่นเอง ให้ข้ามไปไม่ต้องลบกระสุนทิ้ง
	if body is Player:
		
		return
	
	queue_free()
