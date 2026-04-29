extends CanvasLayer

@onready var btn_resume = $CenterContainer/VBoxContainer/BtnResume
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

func _ready():
	btn_resume.pressed.connect(_on_resume)
	btn_menu.pressed.connect(_on_menu)

func _on_resume():
	get_tree().paused = false
	queue_free()

func _on_menu():
	# Pastikan game di-unpause sebelum pindah agar main menu tidak freeze
	get_tree().paused = false 
	TransitionManager.change_scene("res://scenes/main_menu.tscn")

func _input(event):
	# Jika pencet P lagi saat menu pause aktif, langsung resume
	if event.is_action_pressed("pause_game"):
		# Mencegah input ini menembus ke node lain
		get_viewport().set_input_as_handled()
		_on_resume()
