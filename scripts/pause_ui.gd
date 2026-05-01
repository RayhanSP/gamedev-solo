extends CanvasLayer

@onready var btn_resume = $CenterContainer/VBoxContainer/BtnResume
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

@onready var sfx_click = $SfxClick

func _ready():
	btn_resume.pressed.connect(_on_resume)
	btn_menu.pressed.connect(_on_menu)

func _on_resume():
	if sfx_click: sfx_click.play()
	
	# Sembunyikan UI dan lepas pause detik itu juga!
	visible = false
	get_tree().paused = false
	
	if sfx_click: await sfx_click.finished
	queue_free()

func _on_menu():
	if sfx_click: sfx_click.play()
	get_tree().paused = false 
	TransitionManager.change_scene("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_on_resume()
