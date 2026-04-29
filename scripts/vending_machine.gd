extends Node2D

@onready var anim = $AnimatedSprite2D

var gacha_pool = [
	"item_ban", "item_ban", "item_ban",
	"item_metal_gear", "item_metal_gear",
	"item_battery"
]

var is_gacha_running = false 
var available_charges = 0 

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	update_machine_state()

func _input(event):
	if event.is_action_pressed("gacha_pull") and not get_tree().paused:
		_trigger_gacha()

func add_charge(amount):
	available_charges += amount
	print(">> Gacha Charge bertambah! Sisa: ", available_charges)
	update_machine_state()

func update_machine_state():
	if is_gacha_running: return
	if available_charges > 0:
		anim.play("ready") 
	else:
		anim.play("idle") 

func _on_animation_finished():
	if is_gacha_running: return
	if anim.animation == "idle" and available_charges <= 0:
		anim.play("text_final")
		await get_tree().create_timer(3.0).timeout
		if not is_gacha_running and available_charges <= 0:
			anim.play("idle")

func _trigger_gacha():
	if is_gacha_running or available_charges <= 0: return
	
	var main_scene = get_tree().current_scene
	
	# CEK INVENTORY PENUH SEBELUM NGE-ROLL
	if main_scene.has_method("is_inventory_full") and main_scene.is_inventory_full():
		# Pastikan lu udah bikin node WarningLabel manual di HUD seperti request sebelumnya
		main_scene.show_floating_text("INVENTORY FULL!")
		return
	
	if main_scene.has_method("record_gacha"):
		main_scene.record_gacha()
		
	print(">> Memulai Proses Gacha...")
	is_gacha_running = true
	available_charges -= 1
	
	anim.play("pull_handle")
	await get_tree().create_timer(0.4).timeout 
	anim.play("dispense")
	await get_tree().create_timer(1.2).timeout 
	
	var hadiah = gacha_pool.pick_random()
	print("!!! DAPET ITEM: ", hadiah.to_upper(), " !!!")
	
	# ===============================================
	# ANIMASI ITEM POP-UP DENGAN GLOWING OUTLINE (SHADER)
	# ===============================================
	if main_scene.has_method("get_texture_for"):
		var tex = main_scene.get_texture_for(hadiah)
		var pop_sprite = Sprite2D.new()
		pop_sprite.texture = tex
		add_child(pop_sprite)
		
		# --- RUMUS SHADER UNTUK GLOWING OUTLINE (KUNING) ---
		var shader_code = """
			shader_type canvas_item;
			render_mode unshaded; // Biar tetep nyala terang walau malam

			// Warna outline (Kuning Overbright buat efek glow)
			uniform vec4 outline_color : source_color = vec4(2.0, 2.0, 0.0, 1.0); 
			uniform float width : hint_range(0.0, 10.0) = 1.0;

			void fragment() {
				vec2 size = TEXTURE_PIXEL_SIZE * width;
				float alpha = texture(TEXTURE, UV).a;
				
				// Cek tetangga pixel buat bikin outline
				float outline = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a; // Kiri
				outline = max(outline, texture(TEXTURE, UV + vec2(size.x, 0.0)).a); // Kanan
				outline = max(outline, texture(TEXTURE, UV + vec2(0.0, -size.y)).a); // Atas
				outline = max(outline, texture(TEXTURE, UV + vec2(0.0, size.y)).a); // Bawah
				
				// Gabungkan warna asli dengan outline coklat
				vec4 col = texture(TEXTURE, UV);
				// Kalau pixel asli transparan tapi ada tetangga solid, kasih warna outline
				vec3 final_color = mix(outline_color.rgb, col.rgb, col.a);
				float final_alpha = max(col.a, outline);
				
				COLOR = vec4(final_color, final_alpha);
			}
		"""
		
		# Buat Material baru dan pasang Shadernya lewat code
		var mat = ShaderMaterial.new()
		var shdr = Shader.new()
		shdr.code = shader_code
		mat.shader = shdr
		
		# Pasang material ke sprite item yang loncat
		pop_sprite.material = mat
		pop_sprite.modulate = Color(1, 1, 1, 1) # Balikin modulate ke normal
		# --------------------------------------------------
		
		pop_sprite.position = Vector2(0, -20) # Muncul dari moncong mesin
		pop_sprite.scale = Vector2(0.1, 0.1)
		
		var tw = create_tween().set_parallel(true)
		# Loncatan pendek (height sudah di-nerf dari request sebelumnya)
		tw.tween_property(pop_sprite, "position:y", -45.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pop_sprite, "scale", Vector2(1.5, 1.5), 0.6).set_trans(Tween.TRANS_BOUNCE)
		# Fade out
		tw.chain().tween_property(pop_sprite, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(pop_sprite.queue_free)
	# ===============================================
	
	if main_scene.has_method("receive_gacha_item"):
		main_scene.receive_gacha_item(hadiah)
	
	is_gacha_running = false
	update_machine_state()
