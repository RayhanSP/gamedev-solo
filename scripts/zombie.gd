extends CharacterBody2D

@export var speed: float = 25.0
@export var max_health: int = 3
@export var can_be_knocked_back: bool = true

# INI ARRAY UNTUK RANDOM GROWL!
@export var growl_sounds: Array[AudioStream]

var current_health: int
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var knockback_velocity: Vector2 = Vector2.ZERO 
var is_dead: bool = false 

@onready var original_speed: float = speed
@onready var anim = $AnimatedSprite2D

# === AUDIO NODES ===
@onready var sfx_growl = $SfxGrowl
@onready var sfx_hurt = $SfxHurt
@onready var sfx_metal_hit = $SfxMetalHit

func _ready():
	current_health = max_health
	anim.play("walk")
	
	# LOGIKA RANDOM GROWL SAAT SPAWN
	if growl_sounds.size() > 0 and sfx_growl:
		sfx_growl.pitch_scale = randf_range(0.85, 1.15)
		sfx_growl.stream = growl_sounds.pick_random()
		sfx_growl.play()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if knockback_velocity.length() > 10:
		velocity.x = knockback_velocity.x
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	elif not is_dead:
		velocity.x = -speed
	else:
		velocity.x = 0
	
	move_and_slide()

func take_damage(amount: int):
	if is_dead: return 
	
	current_health -= amount
	anim.play("hurt")
	
	# MAININ SFX HURT
	if sfx_hurt:
		sfx_hurt.pitch_scale = randf_range(0.9, 1.1) 
		sfx_hurt.play()
		
	# MAININ SFX METAL GEAR KALAU DAMAGE BESAR
	if amount == 30 and sfx_metal_hit:
		sfx_metal_hit.play()
	
	if current_health <= 0:
		is_dead = true
		await get_tree().create_timer(0.3).timeout
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		if not is_dead: 
			anim.play("walk")

func apply_knockback(strength: float):
	if not can_be_knocked_back: return
	knockback_velocity.x = strength

func die():
	var main_scene = get_tree().current_scene
	if main_scene.has_method("add_score"):
		main_scene.add_score(1)
		
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, 1) 
	particles.spread = 45.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 40
	particles.initial_velocity_max = 90
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color("589174") 
	
	main_scene.add_child(particles)
	particles.global_position = global_position
	
	if anim:
		anim.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		var clipper = ColorRect.new()
		clipper.color = Color.WHITE
		clipper.position = Vector2(-32, -32) 
		clipper.size = Vector2(64, 64)
		anim.add_child(clipper)
		
		var tw = create_tween()
		tw.tween_property(clipper, "position:y", 32.0, 0.6)
		
	await get_tree().create_timer(0.7).timeout
	particles.queue_free()
	queue_free()
	
func apply_shock_effect(slow_multiplier: float, duration: float):
	if is_dead: return
	
	anim.modulate = Color(0.3, 0.3, 0.3) 
	speed = original_speed * slow_multiplier
	
	await get_tree().create_timer(duration).timeout
	
	if not is_dead:
		anim.modulate = Color(1.0, 1.0, 1.0) 
		speed = original_speed
