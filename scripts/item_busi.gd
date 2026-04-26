extends RigidBody2D

@onready var sprite = $Sprite2D
@onready var particles = $ShatterParticles
@onready var hit_box = $Area2D
@onready var collision_shape = $CollisionShape2D

# Flag biar gak hancur dua kali
var is_destroyed = false 

func _ready():
	# 1. Bikin sudut awal acak (0 sampai 360 derajat) biar gak kaku
	rotation = randf_range(0, TAU)
	
	# 2. Bikin dia muter-muter pas melayang
	angular_velocity = randf_range(-20, 20)
	
	# Hubungkan sinyal saat RigidBody nabrak sesuatu (Fisika)
	body_entered.connect(_on_body_entered)
	
	# Hubungkan sinyal saat Area2D nyentuh Zombie (Sensor)
	hit_box.body_entered.connect(_on_hitbox_body_entered)

# FUNGSI 1: KETIKA NABRAK TANAH / TEMBOK (Fisika)
func _on_body_entered(body):
	if is_destroyed: return
	
	# Cek apakah yang ditabrak itu aspal/ground
	if body.name == "Ground":
		shatter_and_destroy()

# FUNGSI 2: KETIKA KENA ZOMBIE (Sensor)
func _on_hitbox_body_entered(body):
	if is_destroyed: return
	
	# Ngecek apakah object yg ditabrak punya fungsi take_damage
	if body.has_method("take_damage"):
		print(">> Busi mengenai Zombie!")
		# Eksekusi fungsi kurangin darah di zombie.gd sebesar 1
		body.take_damage(1)
		shatter_and_destroy()

# FUNGSI 3: ANIMASI HANCUR
func shatter_and_destroy():
	is_destroyed = true
	
	# BIKIN AMAN DARI ERROR: Pakai set_deferred untuk semua perubahan status fisika
	set_deferred("freeze", true)
	hit_box.set_deferred("monitoring", false) 
	
	sprite.visible = false
	
	if particles:
		particles.global_rotation = 0 
		particles.emitting = true
		await get_tree().create_timer(particles.lifetime).timeout
	
	queue_free()
