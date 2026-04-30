extends Node2D

var projectile_scene: PackedScene 

@export var dot_texture: Texture2D

@export var max_power: float = 800.0 
@export var min_power: float = 150.0 
@export var power_charge_rate: float = 750.0 
@export var throw_angle: float = -35.0

@onready var throw_point = $ThrowPoint
@onready var anim = $AnimatedSprite2D

var current_power: float = 0.0
var charge_time: float = 0.0 
var is_charging: bool = false

func set_equipped_item(scene: PackedScene):
	projectile_scene = scene

func _process(delta):
	if Input.is_action_pressed("throw_item") and projectile_scene:
		is_charging = true
		
		var ammo_name = projectile_scene.resource_path.get_file().get_basename()
		
		if ammo_name == "item_metal_gear":
			current_power = 600.0 
		else:
			charge_time += delta
			var raw_power = pingpong(charge_time * power_charge_rate, max_power)
			current_power = max(raw_power, min_power)
		
		queue_redraw()

	if Input.is_action_just_released("throw_item") and is_charging:
		anim.play("throw")
		throw_item()
		current_power = 0.0
		charge_time = 0.0 
		is_charging = false
		queue_redraw() 
		await get_tree().create_timer(0.5).timeout
		anim.play("idle")

# ==========================================
# REVISI: AIMING LINE RINGAN & ANTI NGELAG
# ==========================================
func _draw():
	if not is_charging or dot_texture == null: return
	
	var ammo_name = ""
	if projectile_scene:
		ammo_name = projectile_scene.resource_path.get_file().get_basename()
	if ammo_name == "item_metal_gear": return 

	var pos = throw_point.position 
	var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
	var vel = direction * current_power
	var current_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# KUANTITAS KONSTAN: Jauh lebih ringan untuk CPU!
	var max_points = 45 # Jumlah chevron diperbanyak biar jarak minimum gak terlalu renggang
	var time_step = 0.03 # Waktu antar chevron (makin kecil makin rapat)
	
	for i in range(max_points):
		var t = i * time_step
		var px = pos.x + vel.x * t
		var py = pos.y + vel.y * t + 0.5 * current_gravity * (t * t)
		var curr_pos = Vector2(px, py)
		
		# Hitung rotasi (Tangen) di titik ini untuk ngunci axis Chevron
		var current_vx = vel.x
		var current_vy = vel.y + current_gravity * t
		var angle = atan2(current_vy, current_vx)
		
		var progress = float(i) / float(max_points)
		
		# Scale dan Alpha (Makin jauh, makin kecil dan makin pudar)
		var scale_mult = lerp(1.0, 0.3, progress)
		var alpha = lerp(1.0, 0.0, progress)
		var color = Color(1.0, 1.0, 1.0, alpha)
		
		# Lock Axis: Posisikan, Putar, dan Skala
		draw_set_transform(curr_pos, angle, Vector2(scale_mult, scale_mult))
		
		# Stempel sprite-nya
		var offset = -dot_texture.get_size() / 2.0
		draw_texture(dot_texture, offset, color)
		
	# Reset transform agar tidak merusak koordinat node lain
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ==========================================
# --- FUNGSI LEMPAR BARANG ---
# ==========================================
func throw_item():
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		var ammo_name = projectile_scene.resource_path.get_file().get_basename()
		
		var main_scene = get_tree().current_scene
		if main_scene.has_method("consume_current_item"):
			main_scene.consume_current_item(ammo_name)
		
		if ammo_name == "item_metal_gear":
			projectile.global_position = throw_point.global_position
			projectile.gravity_scale = 1.0 
			var fall_direction = Vector2(-100, 220.0).normalized()
			projectile.apply_central_impulse(fall_direction * current_power)
		else:
			projectile.global_position = throw_point.global_position
			var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
			projectile.apply_central_impulse(direction * current_power)
