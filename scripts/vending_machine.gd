extends Node2D

@onready var anim = $AnimatedSprite2D

var gacha_pool = [
	"busi", "busi", "busi", "busi",
	"ban", "ban", "ban",
	"aki", "aki",
	"jackpot_heal"
]

var is_gacha_running = false 
var available_charges = 0 # Menyimpan jatah gacha

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	update_machine_state()

# --- FUNGSI INPUT (ENTER UNTUK GACHA) ---
func _input(event):
	# Pastikan tombol ditekan, dan game tidak sedang Game Over/Paused
	if event.is_action_pressed("gacha_pull") and not get_tree().paused:
		_trigger_gacha()

# Fungsi untuk dipanggil dari main.gd saat poin mencapai 5
func add_charge(amount):
	available_charges += amount
	print(">> Gacha Charge bertambah! Sisa: ", available_charges)
	update_machine_state()

# Fungsi sakti untuk ngecek status mesin
func update_machine_state():
	if is_gacha_running: return
	
	if available_charges > 0:
		anim.play("ready") # Mainkan animasi 1 sprite "ready" lu
	else:
		anim.play("idle") # Balik ke animasi muter biasa kalau poin habis

func _on_animation_finished():
	if is_gacha_running: return
	
	# Kalau lagi idle (charge habis) dan beres 1 putaran, pindah ke text_final
	if anim.animation == "idle" and available_charges <= 0:
		anim.play("text_final")
		await get_tree().create_timer(3.0).timeout
		
		# Pastikan player gak tiba-tiba dapet charge pas lagi nunggu 3 detik
		if not is_gacha_running and available_charges <= 0:
			anim.play("idle")

func _trigger_gacha():
	if is_gacha_running or available_charges <= 0: return
	
	var main_scene = get_tree().current_scene
	if main_scene.has_method("record_gacha"):
		main_scene.record_gacha()
		
	print(">> Memulai Proses Gacha...")
	is_gacha_running = true
	
	# Kurangi jatah gacha
	available_charges -= 1
	
	anim.play("pull_handle")
	await get_tree().create_timer(0.4).timeout 
	
	anim.play("dispense")
	await get_tree().create_timer(1.2).timeout 
	
	var hadiah = gacha_pool.pick_random()
	print("!!! DAPET ITEM: ", hadiah.to_upper(), " !!!")
	
	is_gacha_running = false
	update_machine_state()
