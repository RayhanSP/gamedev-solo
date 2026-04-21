extends Node

@onready var canvas_modulate = $"../CanvasModulate"
@onready var layers = {
	"day": $"../ParallaxBackground/LayerDay",
	"evening": $"../ParallaxBackground/LayerEvening",
	"night": $"../ParallaxBackground/LayerNight",
	"midnight": $"../ParallaxBackground/LayerMidnight"
}

var time_colors = {
	"day": Color("#ffffff"),
	"evening": Color("#ffb38a"),
	"night": Color("#4a5b78"),
	"dusk": Color("#ff9d8a"),
	"midnight": Color("344158ff")
}

var cycle_sequence = ["day", "evening", "night", "dusk"]
var current_index = 0
var completed_cycles = 0
var target_for_midnight = 0
var current_time = "day" 

func _ready():
	randomize()
	target_for_midnight = randi_range(2, 4) 
	
	for layer in layers.values():
		layer.modulate.a = 0.0
	layers["day"].modulate.a = 1.0
	canvas_modulate.color = time_colors["day"]

func transition_to_next():
	var next_index = (current_index + 1) % cycle_sequence.size()
	var next_time = cycle_sequence[next_index]
	
	if next_time == "day":
		completed_cycles += 1
		if completed_cycles >= target_for_midnight:
			trigger_midnight()
			return 
	
	perform_transition(next_time)
	current_index = next_index

# DURASI DIPERCEPAT: Defaultnya gue ubah dari 4.0 jadi 2.0 detik
func perform_transition(new_time: String, duration: float = 1.5):
	var old_layer_name = current_time 
	var old_layer
	
	if old_layer_name == "dusk":
		old_layer = layers["evening"]
	else:
		old_layer = layers[old_layer_name]
	
	var new_layer
	if new_time == "dusk":
		new_layer = layers["evening"]
		# TRIK SAKTI: Ambil nilai scale yang udah di-stretch, lalu di-negatifkan
		var current_stretch = abs(new_layer.scale.x)
		new_layer.scale.x = -current_stretch
		
		# Ambil lebar layar otomatis (biar gak hardcoded 576 lagi)
		new_layer.position.x = get_viewport().get_visible_rect().size.x
	else:
		# Untuk waktu selain Dusk, pastikan scale balik positif (normal)
		new_layer = layers[new_time] if new_time != "evening" else layers["evening"]
		new_layer.scale.x = abs(new_layer.scale.x)
		new_layer.position.x = 0

	current_time = new_time

	# 1. Animasi awan lama jatuh ke bawah (Pop-out)
	animate_clouds_popout(old_layer)

	# 2. Transisi Fade layar (Lebih cepat)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(old_layer, "modulate:a", 0.0, duration)
	tween.tween_property(new_layer, "modulate:a", 1.0, duration)
	tween.tween_property(canvas_modulate, "color", time_colors[new_time], duration)
	
	# 3. Animasi awan baru naik dari bawah (Pop-up)
	animate_clouds_popup(new_layer)

func trigger_midnight():
	print("!!! MIDNIGHT EVENT STARTED !!!")
	# Durasi midnight juga gue percepat jadi 3.0 detik
	perform_transition("midnight", 3.0)
	
	completed_cycles = 0
	target_for_midnight = randi_range(2, 4)
	
	await get_tree().create_timer(10.0).timeout
	print("Midnight Berakhir, balik ke Siang...")
	perform_transition("day", 2.0)
	current_index = 0 

# ====================================================
# FUNGSI ANIMASI AWAN
# ====================================================

func animate_clouds_popup(layer):
	for child in layer.get_children():
		if child is Sprite2D and child.name.matchn("awan*"):
			# MENGUNCI POSISI ASLI (Hanya dilakukan sekali)
			if not child.has_meta("base_y"):
				child.set_meta("base_y", child.position.y)
			
			var base_y = child.get_meta("base_y")
			
			# Setup sebelum animasi: Taruh di bawah & transparan
			child.position.y = base_y + 100 
			child.modulate.a = 0
			
			var pop_duration = 0.7 
			var cloud_tween = create_tween().set_parallel(true)
			
			# Mantul naik ke posisi asli
			cloud_tween.tween_property(child, "position:y", base_y, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			cloud_tween.tween_property(child, "modulate:a", 1.0, pop_duration).set_trans(Tween.TRANS_LINEAR)

func animate_clouds_popout(layer):
	for child in layer.get_children():
		if child is Sprite2D and child.name.matchn("awan*"):
			# Pastikan meta posisi asli sudah ada
			if not child.has_meta("base_y"):
				child.set_meta("base_y", child.position.y)
				
			var base_y = child.get_meta("base_y")
			var pop_duration = 0.6 
			
			var cloud_tween = create_tween().set_parallel(true)
			
			# EASE_IN & TRANS_BACK: Awan bakal naik/ancang-ancang dikit, baru terjun bebas ke bawah
			cloud_tween.tween_property(child, "position:y", base_y + 100, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			cloud_tween.tween_property(child, "modulate:a", 0.0, pop_duration).set_trans(Tween.TRANS_LINEAR)

# ====================================================

func _input(event):
	if event.is_action_pressed("ui_right"):
		print(">> Memaksa ganti waktu...")
		transition_to_next()
