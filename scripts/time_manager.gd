extends Node

@onready var canvas_modulate = $"../CanvasModulate"

# Layer Langit (Yang di dalam ParallaxBackground)
@onready var sky_layers = {
	"day": $"../ParallaxBackground/LayerDay",
	"evening": $"../ParallaxBackground/LayerEvening",
	"night": $"../ParallaxBackground/LayerNight",
	"midnight": $"../ParallaxBackground/LayerMidnight"
}

# Layer Rumah (Sprite2D biasa di luar Parallax)
@onready var house_layers = {
	"day": $"../HouseLayers/HouseDay",
	"evening": $"../HouseLayers/HouseEvening",
	"night": $"../HouseLayers/HouseNight",
	"midnight": $"../HouseLayers/HouseMidnight"
}

# Nilai 0.25 berarti warna aslinya cuma diambil 25%, sisanya 75% dicampur putih
var tint_strength: float = 0.5 

# Color.WHITE.lerp() akan mencampur warna putih dengan warna target lu
var time_colors = {
	"day": Color("#ffffff"), # Siang hari tetep putih murni
	"evening": Color.WHITE.lerp(Color("#ffb38a"), tint_strength),
	"night": Color.WHITE.lerp(Color("#4a5b78"), tint_strength),
	"dusk": Color.WHITE.lerp(Color("#ff9d8a"), tint_strength),
	"midnight": Color.WHITE.lerp(Color("#38222b"), tint_strength) 
}

var cycle_sequence = ["day", "evening", "night", "dusk"]
var current_index = 0
var completed_cycles = 0
var target_for_midnight = 0
var current_time = "day" 

func _ready():
	randomize()
	target_for_midnight = randi_range(2, 4) 
	
	# Sembunyikan semua di awal
	for key in sky_layers:
		sky_layers[key].modulate.a = 0.0
		house_layers[key].modulate.a = 0.0
		
	# Tampilkan Siang
	sky_layers["day"].modulate.a = 1.0
	house_layers["day"].modulate.a = 1.0
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

func perform_transition(new_time: String, duration: float = 2.0):
	var old_time = current_time 
	
	# 1. Tentukan Node Langit (Lama & Baru)
	var old_sky = sky_layers["evening"] if old_time == "dusk" else sky_layers[old_time]
	var new_sky
	
	# 2. Tentukan Node Rumah (Lama & Baru) - Rumah GAK AKAN FLIP
	var old_house = house_layers["evening"] if old_time == "dusk" else house_layers[old_time]
	var new_house = house_layers["evening"] if new_time == "dusk" else house_layers[new_time]

	# Logika Flip Langit buat Dusk
	if new_time == "dusk":
		new_sky = sky_layers["evening"]
		var stretch = abs(new_sky.scale.x)
		new_sky.scale.x = -stretch
		new_sky.position.x = get_viewport().get_visible_rect().size.x
	elif new_time == "evening":
		new_sky = sky_layers["evening"]
		new_sky.scale.x = abs(new_sky.scale.x)
		new_sky.position.x = 0
	else:
		new_sky = sky_layers[new_time]
		new_sky.scale.x = abs(new_sky.scale.x)
		new_sky.position.x = 0

	current_time = new_time

	# Animasi Awan & Fade
	animate_clouds_popout(old_sky)
	
# 1. Pastikan rumah baru dirender di depan rumah lama biar nge-cover sempurna
	new_house.z_index = 1
	old_house.z_index = 0

	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade Langit & Awan (Tetap crossfade karena langit emang butuh nyampur)
	tween.tween_property(old_sky, "modulate:a", 0.0, duration)
	tween.tween_property(new_sky, "modulate:a", 1.0, duration)
	
	# Fade Warna Dunia
	tween.tween_property(canvas_modulate, "color", time_colors[new_time], duration)
	
	# Transisi Rumah: HANYA fade-in rumah baru. Rumah lama biarin solid.
	tween.tween_property(new_house, "modulate:a", 1.0, duration)
	
	# Setelah semua animasi di atas selesai (chain), sembunyikan rumah lama secara instan
	tween.chain().tween_callback(func():
		if old_house != new_house:
			old_house.modulate.a = 0.0
		new_house.z_index = 0 # Reset z_index rumah baru ke normal
	)
	
	animate_clouds_popup(new_sky)

func trigger_midnight():
	print("!!! MIDNIGHT EVENT STARTED !!!")
	perform_transition("midnight", 3.0)
	completed_cycles = 0
	target_for_midnight = randi_range(2, 4)
	
	await get_tree().create_timer(10.0).timeout
	perform_transition("day", 2.0)
	current_index = 0 

func animate_clouds_popup(layer):
	for child in layer.get_children():
		if child is Sprite2D and child.name.matchn("awan*"):
			if not child.has_meta("base_y"): child.set_meta("base_y", child.position.y)
			var base_y = child.get_meta("base_y")
			child.position.y = base_y + 100 
			child.modulate.a = 0
			var cloud_tween = create_tween().set_parallel(true)
			cloud_tween.tween_property(child, "position:y", base_y, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			cloud_tween.tween_property(child, "modulate:a", 1.0, 0.7)

func animate_clouds_popout(layer):
	for child in layer.get_children():
		if child is Sprite2D and child.name.matchn("awan*"):
			if not child.has_meta("base_y"): child.set_meta("base_y", child.position.y)
			var base_y = child.get_meta("base_y")
			var cloud_tween = create_tween().set_parallel(true)
			cloud_tween.tween_property(child, "position:y", base_y + 100, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			cloud_tween.tween_property(child, "modulate:a", 0.0, 0.6)

func _input(event):
	if event.is_action_pressed("ui_right"):
		transition_to_next()
