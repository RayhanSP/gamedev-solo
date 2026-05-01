shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 100.0) = 16.0; // Atur makin gede makin retro kotak-kotaknya
uniform vec2 center_uv = vec2(0.5, 0.5); 
uniform float aspect_ratio = 1.7778; 

void fragment() {
    // 1. Ambil resolusi layar saat ini
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    
    // 2. Bikin UV jadi kotak-kotak (Efek Pixelate)
    vec2 grid = resolution / pixel_size;
    vec2 pixelated_uv = floor(UV * grid) / grid;
    
    // 3. Hitung jarak menggunakan UV yang udah dibikin kotak-kotak
    vec2 dist_vec = pixelated_uv - center_uv;
    dist_vec.x *= aspect_ratio;
    float dist = length(dist_vec);
    
    // 4. Jarak maksimum biar menutupi seluruh layar
    float max_dist = length(vec2(aspect_ratio, 1.0));
    float radius = max_dist * (1.0 - progress);
    
    if (dist > radius) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Gelap Hitam Pekat
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparan
    }
}