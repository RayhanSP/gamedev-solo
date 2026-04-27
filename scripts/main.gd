extends Node2D

# === REFERENSI NODE VISUAL ===
# Kita kumpulkan node Parallax dan Rumah ke dalam array biar gampang di-loop
@onready var bg_layers = [
	$ParallaxBackground/LayerDay,
	$ParallaxBackground/LayerEvening,
	$ParallaxBackground/LayerNight,
	$ParallaxBackground/LayerMidnight
]

@onready var house_layers = [
	$HouseLayers/HouseDay,
	$HouseLayers/HouseEvening,
	$HouseLayers/HouseNight,
	$HouseLayers/HouseMidnight
]

@onready var spawn_point = $SpawnPoint

# === VARIABEL SCENERY & WAVE ===
var current_phase_index: int = 0
var phase_timer: float = 0.0
var phase_duration: float = 15.0 # Tiap 15 detik ganti suasana

# === VARIABEL SPAWNER ===
@export var zombie_scene: PackedScene
var wave_level: int = 1
var spawn_timer: float = 0.0
var current_spawn_delay: float = 3.0 # Awalnya spawn tiap 3 detik

func _ready():
	# Reset tampilan di awal game: Cuma nyalakan versi Day (Pagi)
	update_scenery_visibility()
	print(">> GAME MULAI! Wave 1: Pagi Hari")

func _process(delta):
	# 1. LOGIKA GANTI WAKTU / SCENERY (Tiap 15 Detik)
	phase_timer += delta
	if phase_timer >= phase_duration:
		phase_timer = 0.0
		advance_phase()
	
	# 2. LOGIKA SPAWNER ZOMBIE
	spawn_timer += delta
	if spawn_timer >= current_spawn_delay:
		spawn_timer = 0.0
		spawn_zombie_wave()

# Fungsi untuk naik level dan ganti pemandangan
func advance_phase():
	wave_level += 1
	
	# Update index pemandangan (mentok di index 3 / Midnight)
	if current_phase_index < bg_layers.size() - 1:
		current_phase_index += 1
		update_scenery_visibility()
		print(">> Waktu Berlalu! Ganti Scenery ke Fase: ", current_phase_index)
	else:
		print(">> MIDNIGHT MODE TERCAPAI! SURVIVE!!")
	
	# Update Difficulty Spawner (Makin Susah)
	# Mengurangi delay, tapi minimal mentok di 1.0 detik biar game gak crash
	current_spawn_delay = max(1.0, 3.0 - (wave_level * 0.3))
	print(">> WAVE LEVEL ", wave_level, "! Delay Spawn jadi: ", current_spawn_delay, " detik")

# Fungsi untuk mengatur nyala/mati layer background dan rumah
func update_scenery_visibility():
	for i in range(bg_layers.size()):
		# Kalau index-nya sama dengan fase sekarang, set true (nyala). Sisanya false (mati).
		bg_layers[i].visible = (i == current_phase_index)
		house_layers[i].visible = (i == current_phase_index)

func spawn_zombie_wave():
	if not zombie_scene:
		print("Peringatan: Zombie Scene belum dimasukkan ke Main node!")
		return
		
	# LOGIKA ROMBONGAN: Semakin tinggi wave, makin banyak zombi yang keluar barengan!
	var zombies_to_spawn = randi_range(1, wave_level) 
	
	for i in range(zombies_to_spawn):
		var zombie = zombie_scene.instantiate()
		add_child(zombie)
		
		# Set posisi awal di SpawnPoint
		var spawn_pos = spawn_point.global_position
		
		# Sebar posisi zombi sedikit biar gak numpuk di satu titik pixel persis
		spawn_pos.x += randf_range(10, 40) * i 
		spawn_pos.y += randf_range(-15, 15)
		
		zombie.global_position = spawn_pos
