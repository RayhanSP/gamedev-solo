extends CanvasLayer

signal transition_finished
@onready var color_rect = $ColorRect

func _ready():
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Update rasio layar agar lingkaran tidak lonjong
func _update_aspect():
	var size = get_viewport().get_visible_rect().size
	color_rect.material.set_shader_parameter("aspect_ratio", size.x / size.y)

func change_scene(target_path: String):
	_update_aspect()
	color_rect.show()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.material.set_shader_parameter("center_uv", Vector2(0.5, 0.5))
	
	var tween = create_tween()
	tween.tween_method(_set_shader_progress, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	get_tree().paused = false
	get_tree().change_scene_to_file(target_path)
	
	var tween2 = create_tween()
	tween2.tween_method(_set_shader_progress, 1.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween2.finished
	
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func iris_out(center_uv: Vector2):
	_update_aspect()
	color_rect.show()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.material.set_shader_parameter("center_uv", center_uv)
	
	var tween = create_tween()
	tween.tween_method(_set_shader_progress, 0.0, 1.0, 1.0).set_ease(Tween.EASE_IN)
	await tween.finished
	
	emit_signal("transition_finished")

func fade_to_black():
	_update_aspect()
	color_rect.show()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.material.set_shader_parameter("center_uv", Vector2(0.5, 0.5))
	
	var tween = create_tween()
	tween.tween_method(_set_shader_progress, 0.0, 1.0, 0.8)
	await tween.finished
	
	emit_signal("transition_finished")

func hide_overlay():
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_shader_progress(value: float):
	color_rect.material.set_shader_parameter("progress", value)
