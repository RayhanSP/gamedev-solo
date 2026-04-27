extends Node2D

@onready var anim = $AnimatedSprite2D
@onready var gacha_btn = $UI_Gacha/GachaButton

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
	gacha_btn.pressed.connect(_on_gacha_btn_pressed)
	
	# Default tombol mati di awal
	gacha_btn.disabled = true
	update_machine_state()

# Fungsi untuk dipanggil dari main.gd saat poin mencapai 5
func add_charge(amount):
	available_charges += amount
	print(">> Gacha Charge bertambah! Sisa: ", available_charges)
	update_machine_state()

# Fungsi sakti untuk ngecek status mesin
func update_machine_state():
	if is_gacha_running: return
	
	if available_charges > 0:
		gacha_btn.disabled = false
		anim.play("ready") # Mainkan animasi 1 sprite "ready" lu
	else:
		gacha_btn.disabled = true
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

func _on_gacha_btn_pressed():
	if is_gacha_running or available_charges <= 0: return
	
	print(">> Memulai Proses Gacha...")
	is_gacha_running = true
	gacha_btn.disabled = true
	
	# Kurangi jatah gacha
	available_charges -= 1
	
	anim.play("pull_handle")
	await get_tree().create_timer(0.4).timeout 
	
	anim.play("dispense")
	await get_tree().create_timer(1.2).timeout 
	
	var hadiah = gacha_pool.pick_random()
	print("!!! DAPET ITEM: ", hadiah.to_upper(), " !!!")
	
	is_gacha_running = false
	update_machine_state() # Bakal ngecek otomatis: kalau charge masih ada, balik ke "READY". Kalau habis, balik "IDLE".
