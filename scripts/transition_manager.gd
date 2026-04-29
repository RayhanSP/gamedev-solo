extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.hide()

# Fungsi sakti yang akan dipanggil dari manapun
func change_scene(target_path: String):
	color_rect.show()
	color_rect.material.set_shader_parameter("progress", 0.0)
	
	# 1. Animasi gelap menutup dari luar ke dalam
	var tween = create_tween()
	tween.tween_method(_set_shader_progress, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	# 2. Pindah scene saat layar gelap total
	get_tree().paused = false # Jaga-jaga kalau dipanggil dari posisi game over/pause
	get_tree().change_scene_to_file(target_path)
	
	# 3. Animasi gelap membuka dari dalam ke luar
	tween = create_tween()
	tween.tween_method(_set_shader_progress, 1.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	color_rect.hide()

func _set_shader_progress(value: float):
	color_rect.material.set_shader_parameter("progress", value)
