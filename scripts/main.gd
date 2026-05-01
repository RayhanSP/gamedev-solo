extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint
@onready var defense_area = $HouseDefenseArea
@onready var player = $Player

@export var zombie_scene: PackedScene
@export var mini_boss_scene: PackedScene 
@export var game_over_scene: PackedScene
@export var pause_scene: PackedScene

@onready var zombie_bar = $HUD/ZombieBar
@onready var warning_symbol = $HUD/WarningSymbol
@export var bar_textures: Array[Texture2D] 

@onready var hud = $HUD
@onready var count_label = $HUD/ZombieBar/CountLabel
@onready var time_label = $HUD/TimeLabel
@onready var score_label = $HUD/ScoreLabel
@onready var btn_pause = $HUD/BtnPause
@onready var vending_machine = $VendingMachine

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

@onready var warning_label = $HUD/WarningLabel
var warning_base_y: float
var warning_tween: Tween

# === AUDIO NODES ===
@onready var sfx_error = $SfxError
@onready var sfx_select = $SfxSelect
@onready var bgm_player = $BGMPlayer

var base_bgm_vol = -5.0 
var muffled_bgm_vol = -15.0 
var is_game_paused = false
var is_gacha_muffle = false

@export var all_ammo_scenes: Array[PackedScene] 
var ammo_dict = {}

@export var tex_ban: Texture2D
@export var tex_metal_gear: Texture2D
@export var tex_battery: Texture2D

var inventory = ["", "", ""] 
var is_top_grid_selected = true 
var selected_bottom_index = 0 
var default_item = "item_busi"

var score: int = 0
var gacha_count: int = 0
var total_duration: float = 0.0
var items_used: Dictionary = {"item_busi": 0, "item_ban": 0, "item_metal_gear": 0, "item_battery": 0}
var gacha_points_progress: int = 0

var wave_level: int = 1
var phase_timer: float = 0.0
var phase_duration: float = 15.0 
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 
var zombies_passed: int = 0
var max_zombies_allowed: int = 10
var is_game_over: bool = false
var is_warning_active: bool = false

var is_midnight_mode: bool = false
var night_cycles_passed: int = 0
var target_night_for_boss: int = 2 

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
	if bgm_player:
		bgm_player.volume_db = base_bgm_vol
	count_label.text = "0 / 10"
	score_label.text = "0"
	if bar_textures.size() > 0:
		zombie_bar.texture = bar_textures[0]
	warning_symbol.modulate.a = 0.0 
	if warning_label:
		warning_base_y = warning_label.position.y
		warning_label.visible = false
	if pull_ready_label:
		var base_y = pull_ready_label.position.y
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(pull_ready_label, "position:y", base_y - 6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(pull_ready_label, "position:y", base_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	update_inventory_ui()

func _process(delta):
	if is_game_over: return
	total_duration += delta
	var mins = int(total_duration) / 60
	var secs = int(total_duration) % 60
	time_label.text = "%02d:%02d" % [mins, secs]
	if not is_midnight_mode:
		phase_timer += delta
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

func update_bgm_volume():
	if not bgm_player: return
	if is_game_paused or is_gacha_muffle:
		bgm_player.volume_db = muffled_bgm_vol
	else:
		bgm_player.volume_db = base_bgm_vol

func set_gacha_muffle(status: bool):
	is_gacha_muffle = status
	update_bgm_volume()

func _on_pause_pressed():
	if is_game_over: return 
	get_tree().paused = true 
	is_game_paused = true
	update_bgm_volume()
	if pause_scene:
		var ui = pause_scene.instantiate()
		add_child(ui)
		ui.tree_exited.connect(_on_pause_menu_closed)

func _on_pause_menu_closed():
	is_game_paused = false
	update_bgm_volume()

func advance_phase():
	wave_level += 1
	if time_manager and time_manager.has_method("transition_to_next"):
		time_manager.transition_to_next()
		if time_manager.current_time == "night":
			night_cycles_passed += 1
			if night_cycles_passed >= target_night_for_boss:
				trigger_midnight_mode()

func trigger_midnight_mode():
	is_midnight_mode = true
	show_floating_text("MIDNIGHT MODE!")
	current_spawn_delay += 5.0
	if time_manager and time_manager.has_method("force_midnight"):
		time_manager.force_midnight()
	await get_tree().create_timer(3.0).timeout
	if mini_boss_scene and not is_game_over:
		var boss = mini_boss_scene.instantiate()
		add_child(boss)
		boss.global_position = spawn_point.global_position

func on_boss_died():
	is_midnight_mode = false
	show_floating_text("BOSS DEFEATED!")
	night_cycles_passed = 0
	target_night_for_boss = randi_range(2, 4)
	if time_manager and time_manager.has_method("end_midnight"):
		time_manager.end_midnight()
	spawn_timer = 0.0
	_kalkulasi_delay_spawn()

func _input(event):
	if is_game_over or get_tree().paused: return
	if event.is_action_pressed("pause_game"):
		_on_pause_pressed()
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

func show_floating_text(msg: String):
	if msg == "INVENTORY FULL!" and sfx_error:
		sfx_error.play() 
	if not warning_label: return
	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()
	warning_label.text = msg
	warning_label.visible = true
	warning_label.position.y = warning_base_y
	warning_label.modulate.a = 1.0
	warning_tween = create_tween().set_parallel(true)
	warning_tween.tween_property(warning_label, "position:y", warning_base_y - 40, 1.5).set_ease(Tween.EASE_OUT)
	warning_tween.tween_property(warning_label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
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

func _on_zombie_passed(body):
	# GEMBOK 1: Kalau udah game over, zombi yang nyusul masuk dicuekin aja!
	if is_game_over: return 
	
	if body.has_method("take_damage"):
		if "is_boss" in body and body.is_boss == true:
			print(">> GAME OVER INSTAN! BOS MASUK!")
			body.queue_free() 
			trigger_game_over()
			return
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

# ==========================================
# --- REVISI: GAME OVER IRIS ANIMATION ---
# ==========================================
func trigger_game_over():
	# GEMBOK 2: Cegah fungsi tereksekusi dua kali!
	if is_game_over: return 
	is_game_over = true
	
	if bgm_player:
		bgm_player.stop()
	
	# 1. Hitung posisi normal (0.0 sampai 1.0) untuk shader
	var screen_size = get_viewport().get_visible_rect().size
	var player_screen_pos = player.get_global_transform_with_canvas().get_origin()
	var center_uv = player_screen_pos / screen_size
	
	# 2. Jalankan Iris Out
	if TransitionManager.has_method("iris_out"):
		TransitionManager.iris_out(center_uv)
		await TransitionManager.transition_finished
	
	# 3. Tampilkan UI
	if game_over_scene:
		var ui = game_over_scene.instantiate()
		add_child(ui)
		
		# PENTING: Sembunyikan transition overlay agar UI tidak tertutup warna hitam
		TransitionManager.hide_overlay()
		
		ui.process_mode = Node.PROCESS_MODE_ALWAYS 
		if ui.has_method("set_stats"):
			ui.set_stats(int(total_duration), score, gacha_count, items_used)
			
	await get_tree().process_frame
	get_tree().paused = true

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
	if is_midnight_mode:
		current_spawn_delay = 999.0 
	else:
		var base_delay = max(1.5, 3.0 - (wave_level * 0.2))
		current_spawn_delay = base_delay + randf_range(-0.3, 0.5)

func spawn_zombie_wave():
	if not zombie_scene or is_midnight_mode: return
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
