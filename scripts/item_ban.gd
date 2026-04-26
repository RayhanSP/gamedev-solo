extends RigidBody2D

@onready var hit_box = $Hitbox

var is_destroyed = false
var damage = 2
var no_bounce_timer: float = 0.0
var hit_zombies: Array = [] # Daftar zombie yang sudah kena hit oleh ban ini

func _ready():
	# Ban di depan zombie secara visual
	z_index = 1
	angular_velocity = randf_range(-15, 15)
	hit_box.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if is_destroyed: return
	
	# Hilangkan ban kalau sudah tidak mantul selama 1 detik
	if abs(linear_velocity.y) < 10.0:
		no_bounce_timer += delta
		if no_bounce_timer >= 1.0:
			queue_free()
	else:
		no_bounce_timer = 0.0

func _on_hitbox_body_entered(body):
	if is_destroyed: return
	
	# Cek apakah yang ditabrak adalah zombie dan BELUM pernah kena hit oleh ban ini
	if body.has_method("take_damage") and not body in hit_zombies:
		print(">> Ban menghantam Zombie!")
		
		# Masukkan zombie ini ke daftar 'sudah kena hit'
		hit_zombies.append(body)
		
		# Berikan Damage
		body.take_damage(damage)
		
		# Berikan Knockback (Kita naikkan angkanya jadi 500 biar kerasa mentalnya)
		if body.has_method("apply_knockback"):
			body.apply_knockback(150.0)
		
		# JANGAN matikan monitoring, biar bisa kena zombie berikutnya!

func destroy_item():
	if is_destroyed: return
	is_destroyed = true
	queue_free()
