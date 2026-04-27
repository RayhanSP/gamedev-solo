extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint
@onready var defense_area = $HouseDefenseArea # Pastikan nama node-nya persis!

@export var zombie_scene: PackedScene

# === VARIABEL SISTEM WAKTU ===
var wave_level: int = 1
var phase_timer: float = 0.0
var phase_duration: float = 15.0 

# === VARIABEL SPAWNER ===
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 

# === VARIABEL HOUSE HEALTH (NEW) ===
var house_hp: int = 10
var is_game_over: bool = false

func _ready():
	print(">> GAME MULAI! Wave 1: Pagi Hari | House HP: ", house_hp)
	randomize()
	_kalkulasi_delay_spawn()
	
	# Sambungkan sinyal dari area pertahanan ke fungsi _on_zombie_passed
	defense_area.body_entered.connect(_on_zombie_passed)

func _process(delta):
	# Kalau game over, hentikan semua timer spawner dan fase waktu
	if is_game_over:
		return
		
	# 1. LOGIKA GANTI WAKTU 
	phase_timer += delta
	if phase_timer >= phase_duration:
		phase_timer = 0.0
		advance_phase()
	
	# 2. LOGIKA SPAWNER ZOMBIE
	spawn_timer += delta
	if spawn_timer >= current_spawn_delay:
		spawn_timer = 0.0
		_kalkulasi_delay_spawn() 
		spawn_zombie_wave()

# --- FUNGSI HOUSE HEALTH & GAME OVER ---
func _on_zombie_passed(body):
	# Pastikan yang lewat beneran zombi (punya fungsi take_damage)
	if body.has_method("take_damage"):
		house_hp -= 1
		print(">> GAWAT! Zombie masuk rumah! HP Sisa: ", house_hp)
		
		# Hapus zombi dari memori biar gak numpuk di luar layar
		body.queue_free()
		
		if house_hp <= 0:
			trigger_game_over()

func trigger_game_over():
	is_game_over = true
	print("!!! GAME OVER !!! RUMAH HANCUR DIMAKAN ZOMBIE !!!")
	# Nanti di sini lu bisa panggil fungsi untuk nampilin Death Screen / UI Game Over
	# Contoh sementara:
	# get_tree().paused = true # (Opsional) Bikin game langsung freeze

# --- FUNGSI SPAWNER & WAKTU (Tetap sama seperti sebelumnya) ---
func _kalkulasi_delay_spawn():
	var base_delay = max(1.5, 3.0 - (wave_level * 0.2))
	current_spawn_delay = base_delay + randf_range(-0.3, 0.5)

func advance_phase():
	wave_level += 1
	if time_manager and time_manager.has_method("transition_to_next"):
		time_manager.transition_to_next()
	print(">> WAVE LEVEL ", wave_level, "! Kesusahan Naik!")

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
