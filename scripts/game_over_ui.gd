extends CanvasLayer

@onready var stats_label = $CenterContainer/VBoxContainer/StatsLabel
@onready var btn_replay = $CenterContainer/VBoxContainer/BtnReplay
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

func _ready():
	# Hubungkan tombol dengan fungsinya
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

# Fungsi ini dipanggil oleh main.gd buat ngoper data statistik akhir
func set_stats(durasi, skor, gacha, item_dict):
	var teks = "Survived: %d secs\n" % durasi
	teks += "Score: %d\n" % skor
	teks += "Gacha Pull: %d times\n" % gacha
	teks += "Items used:\n"
	
	# Pastikan keys di sini sesuai dengan dictionary yang dikirim dari main.gd
	teks += "- Spark Plug: %d\n" % item_dict.get("item_busi", 0)
	teks += "- Used Tires: %d\n" % item_dict.get("item_ban", 0)
	teks += "- Metal Gear: %d\n" % item_dict.get("item_metal_gear", 0)
	teks += "- Battery: %d" % item_dict.get("item_battery", 0)
	
	stats_label.text = teks

func _on_replay_pressed():
	# Unpause game dan reload scene main
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	# Unpause game dan pindah ke scene main menu
	get_tree().paused = false
	print("Pindah ke Main Menu!") 
	# Jika sudah ada scene menu:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
