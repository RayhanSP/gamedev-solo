extends RigidBody2D

@onready var hit_box = $Hitbox

var is_destroyed = false
var damage = 2 # Damage lebih sakit dari busi!

func _ready():
	# Biar bannya muter natural pas dilempar
	angular_velocity = randf_range(-15, 15)
	
	# Hubungkan sinyal hitbox ke fungsi deteksi zombi
	hit_box.body_entered.connect(_on_hitbox_body_entered)
	
	# Timer pembersih: Ban hilang otomatis 5 detik setelah dilempar biar game gak ngelag
	var cleanup_timer = get_tree().create_timer(5.0)
	cleanup_timer.timeout.connect(destroy_item)

func _on_hitbox_body_entered(body):
	if is_destroyed: return
	
	# Karena Hitbox Mask-nya cuma ngecek Layer 2 (Zombi), yg masuk sini pasti zombi
	if body.has_method("take_damage"):
		print(">> Ban menghantam Zombie!")
		body.take_damage(damage)
		
		# Ban GAK hancur pas kena zombi, biar dia tembus dan lanjut mantul ke belakang!
		# Tapi sensornya kita matiin biar gak ngasih damage berkali-kali ke zombi yg sama
		hit_box.set_deferred("monitoring", false)

func destroy_item():
	if is_destroyed: return
	is_destroyed = true
	queue_free()
