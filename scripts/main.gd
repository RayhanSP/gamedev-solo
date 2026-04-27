extends Node2D

@onready var time_manager = $TimeManager
@onready var spawn_point = $SpawnPoint

@export var zombie_scene: PackedScene

# === VARIABEL SISTEM ===
var wave_level: int = 1
var phase_timer: float = 0.0
var phase_duration: float = 15.0 # Tiap 15 detik ganti suasana

# === VARIABEL SPAWNER ===
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 

func _ready():
	print(">> GAME MULAI! Wave 1: Pagi Hari")
	randomize()
	_kalkulasi_delay_spawn() # Set delay awal

func _process(delta):
	# 1. LOGIKA GANTI WAKTU (Panggil TimeManager)
	phase_timer += delta
	if phase_timer >= phase_duration:
		phase_timer = 0.0
		advance_phase()
	
	# 2. LOGIKA SPAWNER ZOMBIE
	spawn_timer += delta
	if spawn_timer >= current_spawn_delay:
		spawn_timer = 0.0
		_kalkulasi_delay_spawn() # Acak lagi delay untuk wave berikutnya
		spawn_zombie_wave()

# Fungsi untuk ngacak delay biar kedatangannya gak gampang ditebak
func _kalkulasi_delay_spawn():
	# Base delay berkurang 0.2 detik per wave, mentok paling cepat 1.5 detik
	var base_delay = max(1.5, 3.0 - (wave_level * 0.2))
	
	# Tambahin randomisasi -0.3 s/d +0.5 detik biar ritmenya gak kaku
	current_spawn_delay = base_delay + randf_range(-0.3, 0.5)

func advance_phase():
	wave_level += 1
	
	# Suruh TimeManager nge-play animasinya!
	if time_manager and time_manager.has_method("transition_to_next"):
		time_manager.transition_to_next()
	
	print(">> WAVE LEVEL ", wave_level, "! Kesusahan Naik!")

func spawn_zombie_wave():
	if not zombie_scene:
		print("Peringatan: Zombie Scene kosong di Main!")
		return
		
	# Matematika linear: Wave 1-2 (max 1), Wave 3-4 (max 2), Wave 5-6 (max 3)
	var max_zombies = 1 + int((wave_level - 1) / 2.0)
	var zombies_to_spawn = randi_range(1, max_zombies) 
	
	# Looping untuk rombongan
	for i in range(zombies_to_spawn):
		var zombie = zombie_scene.instantiate()
		add_child(zombie)
		
		var spawn_pos = spawn_point.global_position
		
		# Acak Y lumayan lebar biar mereka jalan di "lajur" aspal yang beda
		spawn_pos.y += randf_range(-30, 30) 
		
		# Acak X dikit aja, karena nanti kita kasih jeda waktu keluarnya
		spawn_pos.x += randf_range(-10, 10)
		
		zombie.global_position = spawn_pos
		
		# --- KUNCI BIAR GAK BERBARIS ---
		# Beri jeda waktu acak (0.3 s/d 1.2 detik) sebelum zombi berikutnya muncul!
		if i < zombies_to_spawn - 1:
			await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
