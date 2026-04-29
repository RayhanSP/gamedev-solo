extends CanvasLayer

@onready var btn_resume = $CenterContainer/VBoxContainer/BtnResume
@onready var btn_menu = $CenterContainer/VBoxContainer/BtnMenu

func _ready():
	btn_resume.pressed.connect(_on_resume)
	btn_menu.pressed.connect(_on_menu)

func _on_resume():
	get_tree().paused = false # Jalankan game lagi
	queue_free() # Hapus menu pause ini dari layar

func _on_menu():
	get_tree().paused = false # Wajib di-unpause sebelum pindah scene
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Biar bisa unpause pakai tombol "Tab" lagi
func _input(event):
	if event.is_action_pressed("pause_game"): # Ganti dengan nama action lu jika beda
		_on_resume()
