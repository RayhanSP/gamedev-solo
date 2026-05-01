extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint
@onready var defense_area = $HouseDefenseArea
@onready var player = $Player

@export var zombie_scene: PackedScene
@export var all_ammo_scenes: Array[PackedScene] 
var ammo_dict = {}

@export var tex_ban: Texture2D
@export var tex_metal_gear: Texture2D
@export var tex_battery: Texture2D

@onready var count_label = $HUD/ZombieBar/CountLabel
@onready var time_label = $HUD/TimeLabel
@onready var score_label = $HUD/ScoreLabel
@onready var vending_machine = $VendingMachine
@onready var pull_ready_label = $HUD/InventoryUI/PullReadyLabel

@onready var inv_top_slot = $HUD/InventoryUI/TopSlot
@onready var inv_slot_1 = $HUD/InventoryUI/BottomSlots/Slot1
@onready var inv_slot_2 = $HUD/InventoryUI/BottomSlots/Slot2
@onready var inv_slot_3 = $HUD/InventoryUI/BottomSlots/Slot3

@onready var icon_top = $HUD/InventoryUI/TopSlot/Icon
@onready var icon_1 = $HUD/InventoryUI/BottomSlots/Slot1/Icon
@onready var icon_2 = $HUD/InventoryUI/BottomSlots/Slot2/Icon
@onready var icon_3 = $HUD/InventoryUI/BottomSlots/Slot3/Icon
@onready var inv_selector = $HUD/InventoryUI/Selector

@onready var bgm_player = $BGMPlayer
@onready var sfx_select = $SfxSelect

# === NODE TUTORIAL ===
@onready var tutorial_overlay = $TutorialOverlay
@onready var dimmer = $TutorialOverlay/Dimmer
@onready var dialog_box = $TutorialOverlay/DialogBox
@onready var tutorial_text = $TutorialOverlay/DialogBox/TutorialText
@onready var prompt_text = $TutorialOverlay/DialogBox/PromptText
@onready var sfx_next = $TutorialOverlay/SfxNext
# =====================

var inventory = ["", "", ""] 
var is_top_grid_selected = true 
var selected_bottom_index = 0 
var default_item = "item_busi"

var is_waiting_for_space = false
var is_game_over = false
var active_zombie = null 
var total_duration: float = 0.0 # FIX: Tambahin variabel timer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for child in get_children():
		if child.name not in ["TutorialOverlay", "HUD", "BGMPlayer", "SfxSelect", "SfxError"]:
			child.process_mode = Node.PROCESS_MODE_PAUSABLE

	randomize()
	defense_area.body_entered.connect(_on_zombie_passed)
	
	for scene in all_ammo_scenes:
		if scene:
			var scene_name = scene.resource_path.get_file().get_basename()
			ammo_dict[scene_name] = scene
			
	if bgm_player:
		bgm_player.volume_db = -10.0
	
	count_label.text = "TUTORIAL"
	time_label.text = "00:00"
	
	if prompt_text:
		prompt_text.text = "Press E to continue"
	
	tutorial_overlay.visible = false
	
	var tw = create_tween().set_loops()
	tw.tween_property(prompt_text, "modulate:a", 0.2, 0.5)
	tw.tween_property(prompt_text, "modulate:a", 1.0, 0.5)
	
	update_inventory_ui()
	
	run_tutorial_sequence()

# FIX: Fungsi _process dikembalikan buat Timer dan Label Gacha
func _process(delta):
	if is_game_over: return
	
	# Update logic tulisan PULL READY
	if pull_ready_label and vending_machine:
		pull_ready_label.visible = (vending_machine.available_charges > 0)

	# Update Timer (Hanya jalan kalau game lagi gak difreeze sama dialog tutorial)
	if not get_tree().paused:
		total_duration += delta
		var mins = int(total_duration) / 60
		var secs = int(total_duration) % 60
		time_label.text = "%02d.%02d" % [mins, secs]

func _input(event):
	if is_waiting_for_space and event.is_action_pressed("continue_tutorial"): 
		is_waiting_for_space = false
		get_viewport().set_input_as_handled()
		if sfx_next: sfx_next.play()
		return

	if get_tree().paused: return
	
	var moved = false
	if event.is_action_pressed("ui_up"):
		is_top_grid_selected = true
		moved = true
	elif event.is_action_pressed("ui_down"):
		for i in range(3):
			if inventory[i] != "":
				is_top_grid_selected = false
				selected_bottom_index = i
				moved = true
				break
	elif event.is_action_pressed("ui_left"):
		if not is_top_grid_selected:
			var current = selected_bottom_index
			while current > 0:
				current -= 1
				if inventory[current] != "":
					selected_bottom_index = current
					moved = true
					break
	elif event.is_action_pressed("ui_right"):
		if not is_top_grid_selected:
			var current = selected_bottom_index
			while current < 2:
				current += 1
				if inventory[current] != "":
					selected_bottom_index = current
					moved = true
					break
					
	if moved:
		if sfx_select: sfx_select.play()
		update_inventory_ui()

func show_tutorial_step(text: String, wait_for_input: bool = true):
	get_tree().paused = true 
	
	tutorial_text.text = text
	prompt_text.visible = wait_for_input
	tutorial_overlay.visible = true
	
	if wait_for_input:
		is_waiting_for_space = true
		while is_waiting_for_space:
			await get_tree().process_frame
			
	tutorial_overlay.visible = false
	get_tree().paused = false 

func run_tutorial_sequence():
	await get_tree().create_timer(1.0).timeout
	
	await show_tutorial_step("Welcome to the Garage! Your job is to defend it from zombies.")
	await get_tree().create_timer(0.5).timeout
	
	await show_tutorial_step("See the item on the top center? That's your Spark Plug. You can throw it!")
	
	var zombie = zombie_scene.instantiate()
	zombie.process_mode = Node.PROCESS_MODE_PAUSABLE 
	add_child(zombie)
	zombie.global_position = spawn_point.global_position
	active_zombie = zombie
	
	await get_tree().create_timer(1.0).timeout
	
	await show_tutorial_step("Oh no! A zombie is approaching!\nHold space to aim, and release to throw your Spark Plug!")
	
	while is_instance_valid(active_zombie) and not active_zombie.is_dead:
		await get_tree().process_frame
		
	await get_tree().create_timer(1.0).timeout
	await show_tutorial_step("NICE JOB! You shattered it to pieces!")
	
	vending_machine.add_charge(1)
	# FIX: Hapus argumen 'false' biar dia tetep nunggu player baca dan pencet E
	await show_tutorial_step("Killing zombies gives you points.\nLook! The Gacha Machine is ready. Try pulling the handle with pressing enter!")
	
	while inventory[0] == "" and inventory[1] == "" and inventory[2] == "":
		await get_tree().process_frame
		
	await get_tree().create_timer(1.0).timeout
	await show_tutorial_step("Awesome! You got a new item.\nUse Arrow Keys to select items in your inventory.")
	
	await show_tutorial_step("You are now ready to face the real horde.\nGood luck, defender!")
	
	TransitionManager.change_scene("res://scenes/main_menu.tscn")

func get_texture_for(item_name: String) -> Texture2D:
	match item_name:
		"item_ban": return tex_ban
		"item_metal_gear": return tex_metal_gear
		"item_battery": return tex_battery
	return null

func update_inventory_ui():
	var icons = [icon_1, icon_2, icon_3]
	var slots = [inv_slot_1, inv_slot_2, inv_slot_3]
	for i in range(3):
		var item_name = inventory[i]
		if item_name != "": icons[i].texture = get_texture_for(item_name)
		else: icons[i].texture = null

	var target_node = inv_top_slot if is_top_grid_selected else slots[selected_bottom_index]
	var target_center = target_node.get_global_rect().get_center()
	var selector_half_size = inv_selector.get_global_rect().size / 2.0
	
	inv_selector.global_position = target_center - selector_half_size
	inv_selector.pivot_offset = inv_selector.size / 2.0
	inv_selector.scale = Vector2(1.3, 1.3) 
	var tw = create_tween()
	tw.tween_property(inv_selector, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var selected_item_name = default_item if is_top_grid_selected else inventory[selected_bottom_index]
	if selected_item_name == "" or not ammo_dict.has(selected_item_name):
		player.set_equipped_item(null) 
	else:
		player.set_equipped_item(ammo_dict[selected_item_name])

func is_inventory_full() -> bool:
	return not ("" in inventory)

func receive_gacha_item(item_name: String):
	for i in range(inventory.size()):
		if inventory[i] == "":
			inventory[i] = item_name
			update_inventory_ui()
			return

func consume_current_item(item_name: String):
	if item_name == default_item: return 
	if not is_top_grid_selected:
		inventory[selected_bottom_index] = ""
		is_top_grid_selected = true 
		update_inventory_ui() 

func _on_zombie_passed(body):
	if body.has_method("take_damage"):
		body.queue_free()

func add_score(points):
	pass 
func record_gacha():
	pass
