extends Control

@onready var btn_play = $MainMenuUI/VBoxContainer/BtnPlay
@onready var btn_tutorial = $MainMenuUI/VBoxContainer/BtnTutorial
@onready var btn_quit = $MainMenuUI/VBoxContainer/BtnQuit

@onready var sfx_click = $SfxClick

func _ready():
	btn_play.pressed.connect(_on_play_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	if sfx_click: sfx_click.play()
	# Gak pake await, langsung jalanin transisi!
	TransitionManager.change_scene("res://scenes/main.tscn")

func _on_tutorial_pressed():
	if sfx_click: sfx_click.play()
	print(">> Masuk Tutorial (Dummy)")

func _on_quit_pressed():
	if sfx_click: sfx_click.play()
	
	# REVISI: Sembunyikan HANYA kontainer tombolnya, jangan keseluruhan layar!
	if has_node("MainMenuUI"):
		$MainMenuUI.visible = false 
		
	await sfx_click.finished
	get_tree().quit()
