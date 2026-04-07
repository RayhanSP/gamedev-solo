extends RigidBody2D

var damage = 1

func _on_area_2d_body_entered(body):
	# Cek apakah yang ditabrak itu Zombie
	if body.has_method("take_damage"):
		body.take_damage(damage)
		# Efek partikel/ledakan bisa ditaruh di sini nanti
		queue_free() # Busi hancur pas kena zombie
