extends CanvasLayer

@onready var stats_label = $CenterContainer/VBoxContainer/StatsLabel
@onready var btn_replay = $CenterContainer/VBoxContainer/BtnReplay
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

@onready var sfx_game_over = $SfxGameOver 
@onready var sfx_click = $SfxClick 

func _ready():
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	if sfx_game_over:
		sfx_game_over.play()

func set_stats(durasi, skor, gacha, item_dict):
	var teks = "Survived %d secs\n" % durasi
	teks += "Score %d\n" % skor
	teks += "Gacha Pull %d times\n" % gacha
	teks += "Items used this round\n"
	
	teks += "Spark Plug %d\n" % item_dict.get("item_busi", 0)
	teks += "Used Tires %d\n" % item_dict.get("item_ban", 0)
	teks += "Metal Gear %d\n" % item_dict.get("item_metal_gear", 0)
	teks += "Battery %d" % item_dict.get("item_battery", 0)
	
	stats_label.text = teks

func _on_replay_pressed():
	if sfx_click: sfx_click.play()
	get_tree().paused = false
	TransitionManager.change_scene("res://scenes/main.tscn")

func _on_menu_pressed():
	if sfx_click: sfx_click.play()
	get_tree().paused = false
	TransitionManager.change_scene("res://scenes/main_menu.tscn")
