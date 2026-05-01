extends CanvasLayer

@onready var btn_resume = $CenterContainer/VBoxContainer/BtnResume
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

@onready var sfx_click = $SfxClick

var is_closing = false # GEMBOK ANTI HANTU

func _ready():
	btn_resume.pressed.connect(_on_resume)
	btn_menu.pressed.connect(_on_menu)

func _on_resume():
	if is_closing: return
	is_closing = true
	
	# MATIKAN FUNGSI DETEKSI INPUT BIAR GAK NELEN TOMBOL P LAGI!
	set_process_input(false)
	
	if sfx_click: sfx_click.play()
	
	# Sembunyikan UI dan lepas pause detik itu juga!
	visible = false
	get_tree().paused = false
	
	if sfx_click: await sfx_click.finished
	queue_free()

func _on_menu():
	if is_closing: return
	is_closing = true
	set_process_input(false)
	
	if sfx_click: sfx_click.play()
	get_tree().paused = false 
	TransitionManager.change_scene("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("pause_game") and not is_closing:
		get_viewport().set_input_as_handled()
		_on_resume()
