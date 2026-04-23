extends Node2D

@onready var anim = $AnimatedSprite2D
@onready var gacha_btn = $UI_Gacha/GachaButton

var gacha_pool = [
	"busi", "busi", "busi", "busi",
	"ban", "ban", "ban",
	"aki", "aki",
	"jackpot_heal"
]

# Flag buat nandain mesin lagi dipake, biar animasi idle gak nyela
var is_gacha_running = false 

func _ready():
	# Hubungkan signal saat sebuah animasi selesai
	anim.animation_finished.connect(_on_animation_finished)
	gacha_btn.pressed.connect(_on_gacha_btn_pressed)
	
	start_idle_sequence()

func start_idle_sequence():
	if is_gacha_running: return
	anim.play("idle")

# Fungsi ini otomatis kepanggil tiap kali SATU putaran animasi selesai
func _on_animation_finished():
	if is_gacha_running: return
	
	# Kalau animasi idle (rolling text) beres, pindah ke teks statis
	if anim.animation == "idle":
		anim.play("text_final")
		
		# Tahan di teks statis selama 3 detik
		await get_tree().create_timer(3.0).timeout
		
		# Pastikan player belum mencet tombol gacha selama nunggu 3 detik tadi
		if not is_gacha_running:
			start_idle_sequence()

func _on_gacha_btn_pressed():
	if is_gacha_running: return
	
	print(">> Memulai Proses Gacha...")
	is_gacha_running = true
	gacha_btn.disabled = true
	
	# FASE 1: Tarik Tuas (Anticipation) - Cepat aja
	anim.play("pull_handle")
	await get_tree().create_timer(0.4).timeout 
	
	# FASE 2: Mesin Berputar / Dispense
	anim.play("dispense")
	# Durasi ideal mesin gacha nahan ketegangan: 1.2 sampai 1.5 detik
	await get_tree().create_timer(1.2).timeout 
	
	# FASE 3: Kasih Hadiah
	var hadiah = gacha_pool.pick_random()
	print("!!! DAPET ITEM: ", hadiah.to_upper(), " !!!")
	
	# FASE 4: Reset mesin ke kondisi awal
	is_gacha_running = false
	gacha_btn.disabled = false
	start_idle_sequence()
