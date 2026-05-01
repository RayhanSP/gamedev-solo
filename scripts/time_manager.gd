extends Node

@onready var canvas_modulate = $"../CanvasModulate"

@onready var sky_layers = {
	"day": $"../ParallaxBackground/LayerDay",
	"evening": $"../ParallaxBackground/LayerEvening",
	"night": $"../ParallaxBackground/LayerNight",
	"midnight": $"../ParallaxBackground/LayerMidnight"
}

@onready var house_layers = {
	"day": $"../HouseLayers/HouseDay",
	"evening": $"../HouseLayers/HouseEvening",
	"night": $"../HouseLayers/HouseNight",
	"midnight": $"../HouseLayers/HouseMidnight"
}

var tint_strength: float = 0.5 

var time_colors = {
	"day": Color("#ffffff"), 
	"evening": Color.WHITE.lerp(Color("#ffb38a"), tint_strength),
	"night": Color.WHITE.lerp(Color("#4a5b78"), tint_strength),
	"dusk": Color.WHITE.lerp(Color("#ff9d8a"), tint_strength),
	"midnight": Color.WHITE.lerp(Color("#38222b"), tint_strength) 
}

var cycle_sequence = ["day", "evening", "night", "dusk"]
var current_index = 0
var current_time = "day" 

func _ready():
	randomize()
	for key in sky_layers:
		sky_layers[key].modulate.a = 0.0
		house_layers[key].modulate.a = 0.0
		
	sky_layers["day"].modulate.a = 1.0
	house_layers["day"].modulate.a = 1.0
	canvas_modulate.color = time_colors["day"]

func transition_to_next():
	var next_index = (current_index + 1) % cycle_sequence.size()
	var next_time = cycle_sequence[next_index]
	
	perform_transition(next_time)
	current_index = next_index

# Dipanggil manual dari main.gd saat boss spawn
func force_midnight():
	perform_transition("midnight", 2.0)

# Dipanggil manual dari main.gd saat boss mati
func end_midnight():
	perform_transition("day", 2.0)
	current_index = 0

func perform_transition(new_time: String, duration: float = 2.0):
	var old_time = current_time 
	var old_sky = sky_layers["evening"] if old_time == "dusk" else sky_layers[old_time]
	var new_sky
	var old_house = house_layers["evening"] if old_time == "dusk" else house_layers[old_time]
	var new_house = house_layers["evening"] if new_time == "dusk" else house_layers[new_time]

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

	animate_clouds_popout(old_sky)
	new_house.z_index = 1
	old_house.z_index = 0

	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(old_sky, "modulate:a", 0.0, duration)
	tween.tween_property(new_sky, "modulate:a", 1.0, duration)
	tween.tween_property(canvas_modulate, "color", time_colors[new_time], duration)
	tween.tween_property(new_house, "modulate:a", 1.0, duration)
	
	tween.chain().tween_callback(func():
		if old_house != new_house:
			old_house.modulate.a = 0.0
		new_house.z_index = 0
	)
	
	animate_clouds_popup(new_sky)

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
