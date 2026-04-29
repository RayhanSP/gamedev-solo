extends CanvasLayer

@onready var stats_label = $CenterContainer/VBoxContainer/StatsLabel
@onready var btn_replay = $CenterContainer/VBoxContainer/BtnReplay
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

func _ready():
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

func set_stats(durasi, skor, gacha, item_dict):
	var teks = "Survived: %d secs\n" % durasi
	teks += "Score: %d\n" % skor
	teks += "Gacha Pull: %d times\n" % gacha
	teks += "Items used:\n"
	
	teks += "- Spark Plug: %d\n" % item_dict.get("item_busi", 0)
	teks += "- Used Tires: %d\n" % item_dict.get("item_ban", 0)
	teks += "- Metal Gear: %d\n" % item_dict.get("item_metal_gear", 0)
	teks += "- Battery: %d" % item_dict.get("item_battery", 0)
	
	stats_label.text = teks

func _on_replay_pressed():
	# Ganti reload_current_scene dengan transisi ke main.tscn
	# Ini akan me-restart game secara bersih dengan efek pixel wipe
	TransitionManager.change_scene("res://scenes/main.tscn")

func _on_menu_pressed():
	# Kembali ke main menu dengan transisi
	TransitionManager.change_scene("res://scenes/main_menu.tscn")
