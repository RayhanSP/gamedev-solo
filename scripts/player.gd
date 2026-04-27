extends Node2D

@export var ammo_list: Array[PackedScene] 
var current_ammo_index: int = 0

@export var projectile_scene: PackedScene
@export var max_power: float = 1200.0
@export var min_power: float = 300.0 
@export var power_charge_rate: float = 900.0
@export var throw_angle: float = -35.0

@onready var throw_point = $ThrowPoint
@onready var line_2d = $Line2D
@onready var anim = $AnimatedSprite2D

var current_power: float = 0.0
var charge_time: float = 0.0 
var is_charging: bool = false

func _ready():
	if ammo_list.size() > 0:
		projectile_scene = ammo_list[0]
		
func _process(delta):
	# UBAHAN KEYBINDING: Pakai "throw_item" (Space)
	if Input.is_action_pressed("throw_item"):
		is_charging = true
		
		var ammo_name = ""
		if projectile_scene:
			ammo_name = projectile_scene.resource_path.get_file().get_basename()
		
		if ammo_name == "item_metal_gear":
			current_power = 600.0 
			line_2d.hide()
		else:
			charge_time += delta
			var raw_power = pingpong(charge_time * power_charge_rate, max_power)
			current_power = max(raw_power, min_power)
			update_trajectory()
			line_2d.show()

	# UBAHAN KEYBINDING: Pakai "throw_item" (Space)
	if Input.is_action_just_released("throw_item") and is_charging:
		anim.play("throw")
		throw_item()
		current_power = 0.0
		charge_time = 0.0 
		is_charging = false
		line_2d.hide()
		await get_tree().create_timer(0.5).timeout
		anim.play("idle")

	if Input.is_action_just_pressed("ui_left"):
		cycle_ammo()

func update_trajectory():
	line_2d.clear_points()
	var pos = throw_point.position
	var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
	var vel = direction * current_power
	var current_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	for i in range(35): 
		line_2d.add_point(pos)
		vel.y += current_gravity * 0.05
		pos += vel * 0.05

func throw_item():
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		var ammo_name = projectile_scene.resource_path.get_file().get_basename()
		
		# --- TRACKING ITEM DIGUNAKAN KE MAIN SCENE ---
		var main_scene = get_tree().current_scene
		if main_scene.has_method("record_item_use"):
			main_scene.record_item_use(ammo_name)
		# ---------------------------------------------
		
		if ammo_name == "item_metal_gear":
			projectile.global_position = throw_point.global_position
			projectile.gravity_scale = 1.0 
			var fall_direction = Vector2(-100, 220.0).normalized()
			projectile.apply_central_impulse(fall_direction * current_power)
		else:
			projectile.global_position = throw_point.global_position
			var direction = Vector2.RIGHT.rotated(deg_to_rad(throw_angle))
			projectile.apply_central_impulse(direction * current_power)

func cycle_ammo():
	if ammo_list.is_empty(): return
	current_ammo_index = (current_ammo_index + 1) % ammo_list.size()
	projectile_scene = ammo_list[current_ammo_index]
	var ammo_name = projectile_scene.resource_path.get_file().get_basename()
	print(">> Equip Amunisi: ", ammo_name.to_upper())
