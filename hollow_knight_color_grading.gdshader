shader_type canvas_item;

// Hollow Knight-inspired color grading shader
// Creates muted, desaturated atmosphere with dramatic contrast

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float saturation : hint_range(0.0, 2.0) = 0.6;
uniform float contrast : hint_range(0.0, 3.0) = 1.3;
uniform float brightness : hint_range(-1.0, 1.0) = -0.1;
uniform vec3 shadow_tint : source_color = vec3(0.2, 0.25, 0.35);
uniform vec3 highlight_tint : source_color = vec3(0.9, 0.95, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;

vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(SCREEN_TEXTURE, uv);
    
    // Desaturate
    vec3 hsv = rgb_to_hsv(color.rgb);
    hsv.y *= saturation;
    color.rgb = hsv_to_rgb(hsv);
    
    // Adjust contrast and brightness
    color.rgb = ((color.rgb - 0.5) * contrast) + 0.5 + brightness;
    
    // Apply shadow and highlight tinting
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 shadows = mix(color.rgb, shadow_tint, (1.0 - luminance) * 0.5);
    vec3 highlights = mix(shadows, highlight_tint, luminance * 0.3);
    color.rgb = highlights;
    
    // Vignette effect
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * vignette_strength;
    color.rgb *= vignette;
    
    // Clamp values
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    
    COLOR = color;
}