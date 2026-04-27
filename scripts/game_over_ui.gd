extends CanvasLayer

@onready var stats_label = $CenterContainer/VBoxContainer/StatsLabel
@onready var btn_replay = $CenterContainer/VBoxContainer/BtnReplay
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

func _ready():
	# Hubungkan tombol dengan fungsinya
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

# Fungsi ini nanti dipanggil oleh main.gd buat ngoper data
func set_stats(durasi, skor, gacha, item_dict):
	var teks = "Survived: %d secs\n" % durasi
	teks += "Score: %d\n" % skor
	teks += "Gacha Pull: %d times\n" % gacha
	teks += "Items used:\n"
	teks += "- Spark Plug: %d\n" % item_dict.get("Busi", 0)
	teks += "- Used Tires: %d\n" % item_dict.get("Ban", 0)
	teks += "- Metal Gear: %d\n" % item_dict.get("MetalGear", 0)
	teks += "- Battery: %d" % item_dict.get("Aki", 0)
	
	stats_label.text = teks

func _on_replay_pressed():
	# Unpause game dan reload scene main
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	# Unpause game dan pindah ke scene main menu (sesuaikan nama file main menu lu nanti)
	get_tree().paused = false
	print("Pindah ke Main Menu!") 
	# get_tree().change_scene_to_file("res://main_menu.tscn")
