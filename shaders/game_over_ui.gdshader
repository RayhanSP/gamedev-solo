shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	// Bikin agak gelap dikit (70% dari warna asli) biar teks UI kelihatan
	COLOR = vec4(color.rgb * 0.7, color.a); 
}