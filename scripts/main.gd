extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint
@onready var defense_area = $HouseDefenseArea

@export var zombie_scene: PackedScene
@export var game_over_scene: PackedScene

# === UI ZOMBIE BAR & WARNING ===
@onready var zombie_bar = $HUD/ZombieBar
@onready var warning_symbol = $HUD/WarningSymbol
@export var bar_textures: Array[Texture2D] 

# === HUD TAMBAHAN & GACHA ===
@onready var count_label = $HUD/ZombieBar/CountLabel
@onready var time_label = $HUD/TimeLabel
@onready var score_label = $HUD/ScoreLabel
#@onready var btn_pause = $HUD/BtnPause
@onready var vending_machine = $VendingMachine

# === STATISTIK PERMAINAN ===
var score: int = 0
var gacha_count: int = 0
var total_duration: float = 0.0
var items_used: Dictionary = {"Busi": 0, "Ban": 0, "MetalGear": 0, "Aki": 0}
var gacha_points_progress: int = 0

# === VARIABEL SISTEM WAKTU ===
var wave_level: int = 1
var phase_timer: float = 0.0
var phase_duration: float = 15.0 

# === VARIABEL SPAWNER ===
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 

# === VARIABEL ZOMBIE BAR (PENGGANTI HOUSE HP) ===
var zombies_passed: int = 0
var max_zombies_allowed: int = 10
var is_game_over: bool = false
var is_warning_active: bool = false

func _ready():
	print(">> GAME MULAI! Wave 1: Pagi Hari")
	randomize()
	_kalkulasi_delay_spawn()
	
	defense_area.body_entered.connect(_on_zombie_passed)
	#btn_pause.pressed.connect(_on_pause_pressed)
	
	# Set tampilan awal UI
	count_label.text = "0 / 10"
	score_label.text = "0"
	
	if bar_textures.size() > 0:
		zombie_bar.texture = bar_textures[0]
	warning_symbol.modulate.a = 0.0 # Pastikan awal-awal hilang

func _process(delta):
	if is_game_over: return
		
	total_duration += delta
	phase_timer += delta
	
	# Format Waktu ke MM:SS (Menit:Detik)
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

# --- FUNGSI PAUSE ---
#func _on_pause_pressed():
	#get_tree().paused = !get_tree().paused
	#if get_tree().paused:
		#btn_pause.text = "RESUME"
	#else:
		#btn_pause.text = "PAUSE"

# --- FUNGSI ZOMBIE MASUK RUMAH ---
func _on_zombie_passed(body):
	if body.has_method("take_damage"):
		zombies_passed += 1
		print(">> GAWAT! Zombie masuk! Total di dalam: ", zombies_passed)
		
		# Update label indikator X/10
		count_label.text = str(zombies_passed) + " / 10"
		
		# Panggil fungsi transisi UI funky
		update_zombie_bar_ui()
		
		body.queue_free()
		
		if zombies_passed >= max_zombies_allowed:
			trigger_game_over()

# --- FUNGSI TRANSISI UI FUNKY & WARNING ---
func update_zombie_bar_ui():
	# 1. Ganti Gambar Sprite
	var index = clamp(zombies_passed, 0, bar_textures.size() - 1)
	if bar_textures.size() > 0:
		zombie_bar.texture = bar_textures[index]
	
	# 2. Efek Transisi Funky (Squash & Stretch Bounce)
	zombie_bar.pivot_offset = zombie_bar.size / 2.0 
	
	var bar_tween = create_tween()
	bar_tween.tween_property(zombie_bar, "scale", Vector2(1.2, 0.7), 0.05)
	bar_tween.tween_property(zombie_bar, "scale", Vector2(0.8, 1.2), 0.1)
	bar_tween.tween_property(zombie_bar, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# 3. Logika Warning Symbol (Mulai kedut saat zombie >= 6)
	if zombies_passed >= 6 and not is_warning_active:
		activate_warning_symbol()

func activate_warning_symbol():
	is_warning_active = true
	print("!!! PERINGATAN BAHAYA AKTIF !!!")
	
	var warning_tween = create_tween().set_loops() # Looping terus menerus
	warning_tween.tween_property(warning_symbol, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	warning_tween.tween_property(warning_symbol, "modulate:a", 0.1, 0.25).set_trans(Tween.TRANS_SINE)

# --- FUNGSI GAME OVER & STATS ---
func trigger_game_over():
	is_game_over = true
	get_tree().paused = true 
	
	if game_over_scene:
		var ui = game_over_scene.instantiate()
		add_child(ui)
		if ui.has_method("set_stats"):
			ui.set_stats(int(total_duration), score, gacha_count, items_used)

# FUNGSI SCORING & GACHA CHARGE
func add_score(points): 
	score += points
	score_label.text = str(score)
	
	gacha_points_progress += points
	if gacha_points_progress >= 5:
		var charges_gained = int(gacha_points_progress / 5)
		gacha_points_progress = gacha_points_progress % 5 
		
		# Suruh mesin gacha nambahin charge
		if vending_machine and vending_machine.has_method("add_charge"):
			vending_machine.add_charge(charges_gained)

func record_gacha(): gacha_count += 1
func record_item_use(item_name):
	if items_used.has(item_name): items_used[item_name] += 1

# --- FUNGSI SPAWNER & WAKTU ---
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
