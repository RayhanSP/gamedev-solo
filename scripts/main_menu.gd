extends Control

@onready var btn_play = $MainMenuUI/VBoxContainer/BtnPlay
@onready var btn_tutorial = $MainMenuUI/VBoxContainer/BtnTutorial
@onready var btn_quit = $MainMenuUI/VBoxContainer/BtnQuit

# === AUDIO NODE ===
@onready var sfx_click = $SfxClick

func _ready():
	# Sambungkan tombol
	btn_play.pressed.connect(_on_play_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	if sfx_click: sfx_click.play()
	TransitionManager.change_scene("res://scenes/main.tscn")

func _on_tutorial_pressed():
	if sfx_click: sfx_click.play()
	print(">> Masuk Tutorial (Dummy)")

func _on_quit_pressed():
	if sfx_click: 
		sfx_click.play()
	
	# Sembunyikan UI agar transisi hitamnya bersih
	if has_node("MainMenuUI"):
		$MainMenuUI.visible = false 
	
	# Panggil transisi ke hitam sebelum quit
	if TransitionManager.has_method("fade_to_black"):
		TransitionManager.fade_to_black()
		await TransitionManager.transition_finished
	else:
		await sfx_click.finished
		
	print(">> Keluar Game")
	get_tree().quit()
