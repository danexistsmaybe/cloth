shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float direction : hint_range(0.,6.28) = 0.;
uniform float linear_scale = 1.;
uniform float exp_scale = 1.;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec2 d = vec2(cos(direction), sin(direction));
	float t = dot(UV-.5, d);
	COLOR = mix(color1, color2, pow(linear_scale*t + .5, exp_scale));
}