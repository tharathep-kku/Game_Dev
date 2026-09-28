extends Node3D

# เล่นท่า Idle ที่โหลดมาจาก Mixamo วนไปเรื่อยๆ
func _ready():
	var anim = $AnimationPlayer
	var name = anim.get_animation_list()[0]
	anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	anim.play(name)
