extends RigidBody2D

# ARRAY UNTUK RANDOM SHATTER SOUNDS
@export var shatter_sounds: Array[AudioStream]

@onready var sprite = $Sprite2D
@onready var particles = $ShatterParticles
@onready var hit_box = $Area2D
@onready var collision_shape = $CollisionShape2D

@onready var sfx_spark_break = $SfxSparkBreak # AUDIO NODE

var is_destroyed = false 

func _ready():
	rotation = randf_range(0, TAU)
	angular_velocity = randf_range(-20, 20)
	body_entered.connect(_on_body_entered)
	hit_box.body_entered.connect(_on_hitbox_body_entered)

func _on_body_entered(body):
	if is_destroyed: return
	if body.name == "Ground":
		shatter_and_destroy()

func _on_hitbox_body_entered(body):
	if is_destroyed: return
	if body.has_method("take_damage"):
		print(">> Busi mengenai Zombie!")
		body.take_damage(1)
		shatter_and_destroy()

func shatter_and_destroy():
	is_destroyed = true
	
	set_deferred("freeze", true)
	hit_box.set_deferred("monitoring", false) 
	sprite.visible = false
	
	if particles:
		particles.global_rotation = 0 
		particles.emitting = true
		
	# TRIK ANTI POTONG + RANDOM SUARA PECAH
	if sfx_spark_break and shatter_sounds.size() > 0:
		sfx_spark_break.pitch_scale = randf_range(0.9, 1.1) # Acak nada biar variatif
		sfx_spark_break.stream = shatter_sounds.pick_random() # Pilih suara acak
		sfx_spark_break.play()
		await sfx_spark_break.finished
	else:
		await get_tree().create_timer(particles.lifetime if particles else 0.5).timeout
		
	queue_free()
