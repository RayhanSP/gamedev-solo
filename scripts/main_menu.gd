extends Control

@onready var btn_play = $MainMenuUI/VBoxContainer/BtnPlay
@onready var btn_tutorial = $MainMenuUI/VBoxContainer/BtnTutorial
@onready var btn_quit = $MainMenuUI/VBoxContainer/BtnQuit

func _ready():
	# Sambungkan tombol
	btn_play.pressed.connect(_on_play_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	# Langsung pindah ke scene game utama!
	TransitionManager.change_scene("res://scenes/main.tscn")

func _on_tutorial_pressed():
	print(">> Masuk Tutorial (Dummy)")

func _on_quit_pressed():
	print(">> Keluar Game")
	get_tree().quit()
