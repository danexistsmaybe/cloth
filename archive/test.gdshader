shader_type canvas_item;

void vertex() {
    
}

void fragment() {
    COLOR = mix(vec4(.8,0,1,1), vec4(0,0,0,1), 2.*abs(UV.y-.5));
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
