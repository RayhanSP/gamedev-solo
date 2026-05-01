extends RigidBody2D

@onready var hit_box = $Hitbox
@onready var sfx_tire_bounce = $SfxTireBounce # AUDIO NODE

var is_destroyed = false
var damage = 2
var no_bounce_timer: float = 0.0
var hit_zombies: Array = [] 

func _ready():
	z_index = 1
	angular_velocity = randf_range(-15, 15)
	
	# Deteksi tabrakan tanah (Physics)
	body_entered.connect(_on_body_entered)
	# Deteksi nabrak zombi (Sensor)
	hit_box.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if is_destroyed: return
	if abs(linear_velocity.y) < 10.0:
		no_bounce_timer += delta
		if no_bounce_timer >= 1.0:
			destroy_item()
	else:
		no_bounce_timer = 0.0

# FUNGSI BARU: Bunyi saat ban nabrak aspal
func _on_body_entered(body):
	if sfx_tire_bounce:
		sfx_tire_bounce.pitch_scale = randf_range(0.9, 1.2)
		sfx_tire_bounce.play()

func _on_hitbox_body_entered(body):
	if is_destroyed: return
	
	if body.has_method("take_damage") and not body in hit_zombies:
		print(">> Ban menghantam Zombie!")
		hit_zombies.append(body)
		body.take_damage(damage)
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(150.0)
			
		# Bunyi juga saat menghantam zombi
		if sfx_tire_bounce:
			sfx_tire_bounce.pitch_scale = randf_range(0.9, 1.2)
			sfx_tire_bounce.play()

func destroy_item():
	if is_destroyed: return
	is_destroyed = true
	queue_free()
