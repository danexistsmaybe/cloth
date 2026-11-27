// Dirt: a light top edge that quickly darkens with depth, with per-pixel brightness noise.
// All distances are in the node's local pixels, so the pattern stays fixed to the ground.
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.55, 0.36, 0.20, 1.0);
uniform vec4 deep_color : source_color = vec4(0.09, 0.05, 0.03, 1.0);
// Depth at which the color reaches deep_color.
uniform float fade_depth : hint_range(1.0, 500.0) = 80.0;
// Largest brightness change, as a fraction of the color.
uniform float noise_strength : hint_range(0.0, 1.0) = 0.25;
// Width and height of one noise grain.
uniform float grain_size : hint_range(1.0, 16.0) = 2.0;

varying vec2 local_position;

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

void vertex() {
    local_position = VERTEX;
}

void fragment() {
    vec2 cell = floor(local_position / grain_size);
    float depth = clamp(cell.y * grain_size / fade_depth, 0.0, 1.0);
    // Ease out, so most of the darkening happens near the top.
    float blend = 1.0 - (1.0 - depth) * (1.0 - depth);
    vec3 color = mix(top_color.rgb, deep_color.rgb, blend);
    color *= 1.0 + (hash(cell) * 2.0 - 1.0) * noise_strength;
    COLOR = vec4(color, 1.0);
}
