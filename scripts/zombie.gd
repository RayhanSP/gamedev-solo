extends CharacterBody2D

@export var speed: float = 25.0
@export var max_health: int = 3

var current_health: int
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D

func _ready():
	current_health = max_health
	anim.play("walk")

func _physics_process(delta):
	# Logika gravitasi biar zombie tetep napak di tanah
	if not is_on_floor():
		velocity.y += gravity * delta

	# Zombie jalan ke arah kiri (X negatif)
	velocity.x = -speed
	
	# Mengeksekusi pergerakan fisika
	move_and_slide()

# Fungsi ini nanti bakal dipanggil pas barang lu nabrak zombie ini
func take_damage(amount: int):
	current_health -= amount
	
	# Ganti animasi jadi sakit sebentar
	anim.play("hurt")
	
	# Timer singkat buat balik ke animasi jalan
	await get_tree().create_timer(0.3).timeout
	
	if current_health <= 0:
		die()
	else:
		anim.play("walk")

func die():
	# Hilangkan zombie dari scene kalau mati
	queue_free()
