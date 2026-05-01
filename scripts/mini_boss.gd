extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

# === AUDIO NODES ===
@onready var sfx_growl = $SfxGrowl
@onready var sfx_wind_up = $SfxWindUp
@onready var sfx_charge = $SfxCharge
@onready var sfx_stunned = $SfxStunned
# ===================

var is_boss = true 
var hp = 100
var base_speed = 25.0 
var current_speed = base_speed
var state = "WALK" 
var has_charged = false

var walk_timer = 0.0
var is_slowed = false

func _ready():
	anim.play("walk")
	# Teriak menggelegar pas baru spawn!
	if sfx_growl: sfx_growl.play()

func _physics_process(delta):
	if state == "DEAD": return

	if not has_charged and state == "WALK":
		walk_timer += delta
		if walk_timer > 3.0:
			start_wind_up()

	if state in ["WALK", "CHARGE"]:
		velocity.x = -current_speed 
		if not is_on_floor():
			velocity.y += 980 * delta 
		move_and_slide()
		
	elif state in ["WIND_UP", "STUNNED"]:
		velocity.x = 0
		if not is_on_floor(): velocity.y += 980 * delta
		move_and_slide()

func start_wind_up():
	state = "WIND_UP"
	anim.play("wind_up")
	
	# MAININ SUARA NGIK-NGIK TARIK NAFAS / WIND UP!
	if sfx_wind_up: sfx_wind_up.play()
	
	await get_tree().create_timer(2.5).timeout
	
	if state == "WIND_UP": 
		state = "CHARGE"
		anim.play("charge")
		
		# MAININ SUARA DASH / NYERUDUK!
		if sfx_charge: sfx_charge.play()
		
		current_speed = base_speed * 5.0 
		has_charged = true
		
		await get_tree().create_timer(3.0).timeout
		
		if state == "CHARGE":
			state = "WALK"
			anim.play("walk")
			current_speed = base_speed if not is_slowed else base_speed * 0.1

func take_damage(amount: int):
	if state == "DEAD": return
	hp -= amount
	flash_white()
	if hp <= 0: die()

func apply_knockback(strength: float):
	if state == "DEAD": return
	
	# FIX BUG: Cek kekuatan hantaman! 
	# Metal gear (25) & Aki (50) akan diabaikan. Hanya Ban (150) yang lolos!
	if strength < 100.0:
		return
	
	if state == "WIND_UP" or state == "CHARGE":
		apply_stun(5.0) 
	else:
		apply_stun(2.5) 
		
	hp -= 5 
	flash_white()
	if hp <= 0: die()

func apply_shock_effect(slow_multiplier: float, duration: float):
	if state == "DEAD": return
	apply_battery_effect()

func apply_stun(duration):
	state = "STUNNED"
	anim.play("stunned")
	
	# MAININ SUARA LINGLUNG / STUNNED!
	if sfx_stunned: sfx_stunned.play()
	
	await get_tree().create_timer(duration).timeout
	if state != "DEAD":
		state = "WALK"
		anim.play("walk")
		current_speed = base_speed if not is_slowed else base_speed * 0.1

func apply_battery_effect():
	if is_slowed: return 
	is_slowed = true
	current_speed = base_speed * 0.1 
	anim.modulate = Color(0.2, 0.2, 0.2, 1) 
	
	for i in range(10): 
		await get_tree().create_timer(1.0).timeout
		if state == "DEAD" or not is_instance_valid(self): return
		hp -= 10
		if hp <= 0: die()

func flash_white():
	var tw = create_tween()
	anim.modulate = Color(10, 10, 10, 1) 
	tw.tween_property(anim, "modulate", Color.WHITE, 0.15) 

func die():
	state = "DEAD"
	anim.play("stunned") 
	collision.set_deferred("disabled", true)
	
	# Putar suara kalah pas mati
	if sfx_stunned:
		sfx_stunned.pitch_scale = 0.8 
		sfx_stunned.play()
	
	var main = get_tree().current_scene
	if main.has_method("on_boss_died"):
		main.on_boss_died()
		
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 25
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, 1) 
	particles.spread = 45.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 120
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color("589174")
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	
	anim.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var clipper = ColorRect.new()
	clipper.color = Color.WHITE
	clipper.position = Vector2(-50, -50) 
	clipper.size = Vector2(100, 100)
	anim.add_child(clipper)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(clipper, "position:y", 50.0, 0.8)
	
	await get_tree().create_timer(0.9).timeout
	particles.queue_free()
	queue_free()
