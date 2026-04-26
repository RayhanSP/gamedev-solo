extends RigidBody2D

@onready var shock_zone = $ShockZone
@onready var shock_timer = $ShockTimer
@onready var particles = $ShockParticles 

var is_active = false
var has_hit_zombie = false
var damage_on_hit = 2 
var dot_damage = 1
var aoe_duration = 4.0
var dot_tick_rate = 0.8
var slow_factor = 0.3

func _ready():
	z_index = 1
	# Pastikan monitoring ON dari awal biar bisa deteksi zombie pas melayang
	shock_zone.monitoring = true
	
	if particles:
		particles.emitting = false
	
	body_entered.connect(_on_body_entered)
	shock_zone.body_entered.connect(_on_direct_hit)
	shock_timer.timeout.connect(_on_shock_tick)

func _on_direct_hit(body):
	# Deteksi hantaman pertama (sebelum aki mendarat/aktif area DoT)
	if not is_active and not has_hit_zombie:
		if body.has_method("take_damage"):
			print(">> Aki menghantam Zombie! (Direct Hit)")
			has_hit_zombie = true
			body.take_damage(damage_on_hit)
			if body.has_method("apply_knockback"):
				body.apply_knockback(200.0)

func _on_body_entered(body):
	if is_active: return
	if body.name == "Ground":
		activate_battery()

func activate_battery():
	is_active = true
	set_deferred("freeze", true)
	
	if particles:
		particles.emitting = true
	
	shock_timer.start(dot_tick_rate)
	await get_tree().create_timer(aoe_duration).timeout
	queue_free()

func _on_shock_tick():
	var victims = shock_zone.get_overlapping_bodies()
	for body in victims:
		if body.has_method("take_damage") and body.has_method("apply_shock_effect"):
			body.take_damage(dot_damage)
			body.apply_shock_effect(slow_factor, dot_tick_rate + 0.2)
