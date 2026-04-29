extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint
@onready var defense_area = $HouseDefenseArea
@onready var player = $Player

@export var zombie_scene: PackedScene
@export var game_over_scene: PackedScene
@export var pause_scene: PackedScene

# === UI ZOMBIE BAR & WARNING ===
@onready var zombie_bar = $HUD/ZombieBar
@onready var warning_symbol = $HUD/WarningSymbol
@export var bar_textures: Array[Texture2D] 

# === HUD TAMBAHAN & GACHA ===
@onready var hud = $HUD
@onready var count_label = $HUD/ZombieBar/CountLabel
@onready var time_label = $HUD/TimeLabel
@onready var score_label = $HUD/ScoreLabel
@onready var btn_pause = $HUD/BtnPause
@onready var vending_machine = $VendingMachine

# === INVENTORY NODES & VARIABLES ===
@onready var inv_top_slot = $HUD/InventoryUI/TopSlot
@onready var inv_slot_1 = $HUD/InventoryUI/BottomSlots/Slot1
@onready var inv_slot_2 = $HUD/InventoryUI/BottomSlots/Slot2
@onready var inv_slot_3 = $HUD/InventoryUI/BottomSlots/Slot3

@onready var icon_top = $HUD/InventoryUI/TopSlot/Icon
@onready var icon_1 = $HUD/InventoryUI/BottomSlots/Slot1/Icon
@onready var icon_2 = $HUD/InventoryUI/BottomSlots/Slot2/Icon
@onready var icon_3 = $HUD/InventoryUI/BottomSlots/Slot3/Icon
@onready var inv_selector = $HUD/InventoryUI/Selector
@onready var pull_ready_label = $HUD/InventoryUI/PullReadyLabel 

# === WARNING LABEL (NEW) ===
@onready var warning_label = $HUD/WarningLabel
var warning_base_y: float
var warning_tween: Tween

@export var all_ammo_scenes: Array[PackedScene] 
var ammo_dict = {}

@export var tex_ban: Texture2D
@export var tex_metal_gear: Texture2D
@export var tex_battery: Texture2D

var inventory = ["", "", ""] 
var is_top_grid_selected = true 
var selected_bottom_index = 0 
var default_item = "item_busi"

# === STATISTIK PERMAINAN ===
var score: int = 0
var gacha_count: int = 0
var total_duration: float = 0.0
var items_used: Dictionary = {"item_busi": 0, "item_ban": 0, "item_metal_gear": 0, "item_battery": 0}
var gacha_points_progress: int = 0

# === VARIABEL SISTEM WAKTU & SPAWNER ===
var wave_level: int = 1
var phase_timer: float = 0.0
var phase_duration: float = 15.0 
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 
var zombies_passed: int = 0
var max_zombies_allowed: int = 10
var is_game_over: bool = false
var is_warning_active: bool = false

func _ready():
	randomize()
	_kalkulasi_delay_spawn()
	
	defense_area.body_entered.connect(_on_zombie_passed)
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_pressed)
	
	for scene in all_ammo_scenes:
		if scene:
			var scene_name = scene.resource_path.get_file().get_basename()
			ammo_dict[scene_name] = scene
	
	count_label.text = "0 / 10"
	score_label.text = "0"
	
	if bar_textures.size() > 0:
		zombie_bar.texture = bar_textures[0]
	warning_symbol.modulate.a = 0.0 
	
	# Simpan posisi awal Warning Label
	if warning_label:
		warning_base_y = warning_label.position.y
		warning_label.visible = false
	
	# === ANIMASI FLOATING "PULL READY" ===
	if pull_ready_label:
		var base_y = pull_ready_label.position.y
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(pull_ready_label, "position:y", base_y - 6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(pull_ready_label, "position:y", base_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	update_inventory_ui()

func _process(delta):
	if is_game_over: return
		
	total_duration += delta
	phase_timer += delta
	
	var mins = int(total_duration) / 60
	var secs = int(total_duration) % 60
	time_label.text = "%02d:%02d" % [mins, secs]
	
	if phase_timer >= phase_duration:
		phase_timer = 0.0
		advance_phase()
	
	spawn_timer += delta
	if spawn_timer >= current_spawn_delay:
		spawn_timer = 0.0
		_kalkulasi_delay_spawn() 
		spawn_zombie_wave()

	if pull_ready_label and vending_machine:
		pull_ready_label.visible = (vending_machine.available_charges > 0)

# ==========================================
# --- FUNGSI INVENTORY & SELECTOR ---
# ==========================================
func _input(event):
	if is_game_over or get_tree().paused: return
	if event.is_action_pressed("pause_game"):
		_on_pause_pressed()
		
	if event.is_action_pressed("ui_up"):
		is_top_grid_selected = true
		update_inventory_ui()
	elif event.is_action_pressed("ui_down"):
		for i in range(3):
			if inventory[i] != "":
				is_top_grid_selected = false
				selected_bottom_index = i
				update_inventory_ui()
				break
	elif event.is_action_pressed("ui_left"):
		if not is_top_grid_selected:
			var current = selected_bottom_index
			while current > 0:
				current -= 1
				if inventory[current] != "":
					selected_bottom_index = current
					update_inventory_ui()
					break
	elif event.is_action_pressed("ui_right"):
		if not is_top_grid_selected:
			var current = selected_bottom_index
			while current < 2:
				current += 1
				if inventory[current] != "":
					selected_bottom_index = current
					update_inventory_ui()
					break

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
		if item_name != "":
			icons[i].texture = get_texture_for(item_name)
		else:
			icons[i].texture = null

	var target_node
	if is_top_grid_selected:
		target_node = inv_top_slot
	else:
		target_node = slots[selected_bottom_index]
	
	var target_center = target_node.get_global_rect().get_center()
	var selector_half_size = inv_selector.get_global_rect().size / 2.0
	
	inv_selector.global_position = target_center - selector_half_size
	inv_selector.pivot_offset = inv_selector.size / 2.0
	inv_selector.scale = Vector2(1.3, 1.3) 
	
	var tw = create_tween()
	tw.tween_property(inv_selector, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var selected_item_name = default_item
	if not is_top_grid_selected:
		selected_item_name = inventory[selected_bottom_index]
		
	if selected_item_name == "" or not ammo_dict.has(selected_item_name):
		player.set_equipped_item(null) 
	else:
		player.set_equipped_item(ammo_dict[selected_item_name])

func is_inventory_full() -> bool:
	return not ("" in inventory)

# --- REVISI: EFEK TEKS MELAYANG PAKAI NODE MANUAL ---
func show_floating_text(msg: String):
	if not warning_label: return
	
	# Hentikan animasi sebelumnya kalau player nge-spam tombol
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
		
	warning_label.text = msg
	warning_label.visible = true
	warning_label.position.y = warning_base_y
	warning_label.modulate.a = 1.0
	
	warning_tween = create_tween().set_parallel(true)
	# Teks naik 40 pixel dari posisi aslinya
	warning_tween.tween_property(warning_label, "position:y", warning_base_y - 40, 1.5).set_ease(Tween.EASE_OUT)
	warning_tween.tween_property(warning_label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
	# Sembunyikan node saat animasi selesai
	warning_tween.chain().tween_property(warning_label, "visible", false, 0.0)

func receive_gacha_item(item_name: String):
	for i in range(inventory.size()):
		if inventory[i] == "":
			inventory[i] = item_name
			update_inventory_ui()
			return

func consume_current_item(item_name: String):
	if items_used.has(item_name): items_used[item_name] += 1
	else: items_used[item_name] = 1
	
	if item_name == default_item:
		return 
		
	if not is_top_grid_selected:
		inventory[selected_bottom_index] = ""
		is_top_grid_selected = true 
		update_inventory_ui() 

# ==========================================
# --- SISANYA TETAP SAMA ---
# ==========================================
func _on_pause_pressed():
	if is_game_over: return 
	get_tree().paused = true 
	if pause_scene:
		var ui = pause_scene.instantiate()
		add_child(ui)

func _on_zombie_passed(body):
	if body.has_method("take_damage"):
		zombies_passed += 1
		count_label.text = str(zombies_passed) + " / 10"
		update_zombie_bar_ui()
		body.queue_free()
		
		if zombies_passed >= max_zombies_allowed:
			trigger_game_over()

func update_zombie_bar_ui():
	var index = clamp(zombies_passed, 0, bar_textures.size() - 1)
	if bar_textures.size() > 0:
		zombie_bar.texture = bar_textures[index]
	
	zombie_bar.pivot_offset = zombie_bar.size / 2.0 
	var bar_tween = create_tween()
	bar_tween.tween_property(zombie_bar, "scale", Vector2(1.2, 0.7), 0.05)
	bar_tween.tween_property(zombie_bar, "scale", Vector2(0.8, 1.2), 0.1)
	bar_tween.tween_property(zombie_bar, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	if zombies_passed >= 6 and not is_warning_active:
		activate_warning_symbol()

func activate_warning_symbol():
	is_warning_active = true
	var warning_tween = create_tween().set_loops() 
	warning_tween.tween_property(warning_symbol, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	warning_tween.tween_property(warning_symbol, "modulate:a", 0.1, 0.25).set_trans(Tween.TRANS_SINE)

func trigger_game_over():
	is_game_over = true
	get_tree().paused = true 
	if game_over_scene:
		var ui = game_over_scene.instantiate()
		add_child(ui)
		if ui.has_method("set_stats"):
			ui.set_stats(int(total_duration), score, gacha_count, items_used)

func add_score(points): 
	score += points
	score_label.text = str(score)
	
	score_label.pivot_offset = score_label.size / 2.0 
	var score_tween = create_tween()
	score_tween.tween_property(score_label, "scale", Vector2(1.3, 0.7), 0.05)
	score_tween.tween_property(score_label, "scale", Vector2(0.8, 1.3), 0.1)
	score_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	if vending_machine and vending_machine.available_charges == 0:
		gacha_points_progress += points
		if gacha_points_progress >= 5:
			vending_machine.add_charge(1)
			gacha_points_progress = 0 

func record_gacha(): 
	gacha_count += 1

func _kalkulasi_delay_spawn():
	var base_delay = max(1.5, 3.0 - (wave_level * 0.2))
	current_spawn_delay = base_delay + randf_range(-0.3, 0.5)

func advance_phase():
	wave_level += 1
	if time_manager and time_manager.has_method("transition_to_next"):
		time_manager.transition_to_next()

func spawn_zombie_wave():
	if not zombie_scene: return
	var max_zombies = 1 + int((wave_level - 1) / 2.0)
	var zombies_to_spawn = randi_range(1, max_zombies) 
	for i in range(zombies_to_spawn):
		var zombie = zombie_scene.instantiate()
		add_child(zombie)
		var spawn_pos = spawn_point.global_position
		spawn_pos.y += randf_range(-30, 30) 
		spawn_pos.x += randf_range(-10, 10)
		zombie.global_position = spawn_pos
		if i < zombies_to_spawn - 1:
			await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
