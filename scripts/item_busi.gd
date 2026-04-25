extends RigidBody2D

@onready var sprite = $Sprite2D
@onready var particles = $ShatterParticles
@onready var hit_box = $Area2D
@onready var collision_shape = $CollisionShape2D

# Flag biar gak hancur dua kali
var is_destroyed = false 

func _ready():
	# Hubungkan sinyal saat RigidBody nabrak sesuatu (Fisika)
	body_entered.connect(_on_body_entered)
	
	# Hubungkan sinyal saat Area2D nyentuh Zombie (Sensor)
	hit_box.body_entered.connect(_on_hitbox_body_entered)

# FUNGSI 1: KETIKA NABRAK TANAH / TEMBOK (Fisika)
func _on_body_entered(body):
	if is_destroyed: return
	
	# Cek apakah yang ditabrak itu aspal/ground
	# Asumsi node lantai lu namanya "Ground"
	if body.name == "Ground":
		shatter_and_destroy()

# FUNGSI 2: KETIKA KENA ZOMBIE (Sensor)
func _on_hitbox_body_entered(body):
	if is_destroyed: return
	
	# Nanti kita ganti "Zombie" sesuai nama grup atau class musuh lu
	if body.name.begins_with("Zombie"):
		print(">> Busi mengenai Zombie!")
		# TODO: Panggil fungsi kurangin darah zombie di sini
		shatter_and_destroy()

# FUNGSI 3: ANIMASI HANCUR
func shatter_and_destroy():
	is_destroyed = true
	
	# 1. Matikan fungsi fisika biar gak mantul lagi
	freeze = true
	hit_box.monitoring = false
	
	# 2. Sembunyikan gambar utuh businya
	sprite.visible = false
	
	# 3. Nyalakan efek partikel pecah
	particles.emitting = true
	
	# 4. Tunggu sampai partikel selesai (sesuai lifetime 0.5 detik)
	await get_tree().create_timer(particles.lifetime).timeout
	
	# 5. Hapus item dari game biar gak menuhin RAM
	queue_free()
