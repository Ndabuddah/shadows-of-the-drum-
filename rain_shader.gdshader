shader_type canvas_item;

uniform float rain_speed : hint_range(0.1, 5.0) = 2.0;
uniform float rain_density : hint_range(0.1, 2.0) = 1.0;
uniform float rain_angle : hint_range(-1.0, 1.0) = 0.2;
uniform vec4 rain_color : hint_color = vec4(0.7, 0.8, 1.0, 0.6);

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = world_position * 0.01;
    uv.x += TIME * rain_angle;
    uv.y += TIME * rain_speed;
    
    vec2 grid = floor(uv * rain_density * 10.0);
    vec2 local_uv = fract(uv * rain_density * 10.0);
    
    float rain_drop = random(grid);
    
    if (rain_drop > 0.7) {
        float drop_y = fract(local_uv.y + TIME * rain_speed * 2.0);
        float drop_x = abs(local_uv.x - 0.5);
        
        float drop_shape = smoothstep(0.1, 0.0, drop_x) * smoothstep(1.0, 0.8, drop_y);
        
        COLOR = mix(COLOR, rain_color, drop_shape * rain_color.a);
    }
}