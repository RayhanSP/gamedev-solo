extends CharacterBody2D

@export var speed: float = 25.0
@export var max_health: int = 3
@export var can_be_knocked_back: bool = true

var current_health: int
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var knockback_velocity: Vector2 = Vector2.ZERO # Menampung tenaga dorongan
var is_dead: bool = false # Flag biar zombi gak bangkit dari kubur

@onready var original_speed: float = speed
@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health
	anim.play("walk")

func _physics_process(delta):
	# Logika gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- LOGIKA GERAK + KNOCKBACK ---
	if knockback_velocity.length() > 10:
		# Jika ada tenaga knockback, paksa zombie bergerak sesuai arah knockback
		velocity.x = knockback_velocity.x
		# Redam tenaga knockback pelan-pelan sampai berhenti (friction)
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	elif not is_dead:
		# Cuma boleh jalan normal kalau belum mati
		velocity.x = -speed
	else:
		# Kalau mati dan gak ada knockback, berhenti di tempat
		velocity.x = 0
	
	move_and_slide()

func take_damage(amount: int):
	# Kalau udah mati (sedang nunggu ilang), jangan terima damage lagi
	if is_dead: return 
	
	current_health -= amount
	anim.play("hurt")
	
	if current_health <= 0:
		is_dead = true
		
		# Tahan selama 0.3 detik biar animasi 'hurt' dan pentalan knockback-nya kelihatan!
		await get_tree().create_timer(0.3).timeout
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		# Pastikan dia gak keburu mati pas lagi nunggu timer
		if not is_dead: 
			anim.play("walk")

# Fungsi ini dipanggil oleh Ban
func apply_knockback(strength: float):
	if not can_be_knocked_back: return
	# Dorong ke kanan (X positif) dengan tenaga yang cukup kuat
	# Kita biarin zombi yang mati tetep bisa mental biar efek last-hit nya makin brutal!
	knockback_velocity.x = strength

func die():
	queue_free()
	
# FUNGSI BARU: Efek Kesetrum (Slow + Gosong)
func apply_shock_effect(slow_multiplier: float, duration: float):
	if is_dead: return
	
	# 1. Bikin sprite jadi warna abu-abu gelap (gosong)
	anim.modulate = Color(0.3, 0.3, 0.3) 
	
	# 2. Kurangi kecepatan jalan
	speed = original_speed * slow_multiplier
	
	# 3. Tunggu durasi setruman habis
	await get_tree().create_timer(duration).timeout
	
	# 4. Kalau belum mati, kembalikan ke kondisi normal
	if not is_dead:
		anim.modulate = Color(1.0, 1.0, 1.0) # Balik ke warna asli
		speed = original_speed
