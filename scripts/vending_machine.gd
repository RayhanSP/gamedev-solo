extends Node2D

@onready var anim = $AnimatedSprite2D

# Pool diganti pakai nama file scene amunisinya langsung!
var gacha_pool = [
	"item_ban", "item_ban", "item_ban",
	"item_metal_gear", "item_metal_gear",
	"item_battery"
]

var is_gacha_running = false 
var available_charges = 0 

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	update_machine_state()

func _input(event):
	if event.is_action_pressed("gacha_pull") and not get_tree().paused:
		_trigger_gacha()

func add_charge(amount):
	available_charges += amount
	print(">> Gacha Charge bertambah! Sisa: ", available_charges)
	update_machine_state()

func update_machine_state():
	if is_gacha_running: return
	if available_charges > 0:
		anim.play("ready") 
	else:
		anim.play("idle") 

func _on_animation_finished():
	if is_gacha_running: return
	if anim.animation == "idle" and available_charges <= 0:
		anim.play("text_final")
		await get_tree().create_timer(3.0).timeout
		if not is_gacha_running and available_charges <= 0:
			anim.play("idle")

func _trigger_gacha():
	if is_gacha_running or available_charges <= 0: return
	
	var main_scene = get_tree().current_scene
	if main_scene.has_method("record_gacha"):
		main_scene.record_gacha()
		
	print(">> Memulai Proses Gacha...")
	is_gacha_running = true
	available_charges -= 1
	
	anim.play("pull_handle")
	await get_tree().create_timer(0.4).timeout 
	anim.play("dispense")
	await get_tree().create_timer(1.2).timeout 
	
	var hadiah = gacha_pool.pick_random()
	print("!!! DAPET ITEM: ", hadiah.to_upper(), " !!!")
	
	# --- KIRIM ITEM KE INVENTORY MAIN SCENE ---
	if main_scene.has_method("receive_gacha_item"):
		main_scene.receive_gacha_item(hadiah)
	
	is_gacha_running = false
	update_machine_state()
