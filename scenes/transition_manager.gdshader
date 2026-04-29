shader_type canvas_item;

// 0.0 = Terang/Kelihatan, 1.0 = Gelap Total
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 100.0) = 16.0; // Makin gede makin retro

void fragment() {
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = FRAGCOORD.xy;
    
    // Bikin efek pixelate (kotak-kotak)
    uv = floor(uv / pixel_size) * pixel_size;
    
    vec2 center = resolution / 2.0;
    float max_dist = length(center);
    float dist = distance(uv, center);
    
    // Jari-jari lingkaran terang yang makin mengecil kalau progress naik
    float radius = max_dist * (1.0 - progress);
    
    if (dist > radius) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Gelap
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparan
    }
}