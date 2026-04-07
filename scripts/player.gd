extends Node2D

@export var projectile_scene: PackedScene
@export var max_power: float = 1200.0
@export var min_power: float = 300.0 # Batas bawah agar lemparan tetap logis (nggak jatoh di kaki sendiri)
@export var power_charge_rate: float = 900.0
@export var throw_angle: float = -35.0

@onready var throw_point = $ThrowPoint
@onready var line_2d = $Line2D
@onready var anim = $AnimatedSprite2D

var current_power: float = 0.0
var charge_time: float = 0.0 # Kita butuh timer buat ngitung waktu tekan
var is_charging: bool = false

func _process(delta):
	# SAAT SPACE DITAHAN
	if Input.is_action_pressed("ui_accept"):
		is_charging = true
		charge_time += delta
		
		# SAKTI: Fungsi pingpong bikin nilai current_power bolak-balik 0 -> Max -> 0
		var raw_power = pingpong(charge_time * power_charge_rate, max_power)
		
		# Memastikan power nggak terlalu letoy (min_power)
		current_power = max(raw_power, min_power)
		
		update_trajectory()
		line_2d.show()

	# SAAT SPACE DILEPAS
	if Input.is_action_just_released("ui_accept") and is_charging:
		anim.play("throw")
		throw_item()
		
		# RESET SEMUA
		current_power = 0.0
		charge_time = 0.0 
		is_charging = false
		line_2d.hide()
		
		await get_tree().create_timer(0.5).timeout
		anim.play("idle")

func update_trajectory():
	line_2d.clear_points()
	var pos = throw_point.position
	var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
	var vel = direction * current_power
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Gambar titik prediksi
	for i in range(35): 
		line_2d.add_point(pos)
		vel.y += gravity * 0.05
		pos += vel * 0.05

func throw_item():
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = throw_point.global_position
		var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
		projectile.apply_central_impulse(direction * current_power)
