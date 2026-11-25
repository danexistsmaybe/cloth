shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform vec3 dither_color = vec3(1,1,1);

void vertex() {
}

float bright(vec4 c) {
    return dot(c.rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
    const float threshold_map[16] = float[](0.0, 0.5, 0.125, 0.625, 0.75, 0.25, 0.875, 0.375, 0.1875, 0.6875, 0.0625, 0.5625, 0.9375, 0.4375, 0.8125, 0.3125);
    int x = int(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x) % 4;
    int y = int(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y) % 4;
    COLOR = vec4(0,0,0,1);
    
    
    vec2 block_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE) * SCREEN_PIXEL_SIZE;
    vec4 a = texture(SCREEN_TEXTURE, block_uv + SCREEN_PIXEL_SIZE*vec2(0,0));
    vec4 b = texture(SCREEN_TEXTURE, block_uv + SCREEN_PIXEL_SIZE*vec2(1,0));
    vec4 c = texture(SCREEN_TEXTURE, block_uv + SCREEN_PIXEL_SIZE*vec2(0,1));
    vec4 d = texture(SCREEN_TEXTURE, block_uv + SCREEN_PIXEL_SIZE*vec2(1,1));
    
    COLOR += float(threshold_map[4*y+x] < bright((a+b+c+d)/4.)) * vec4(dither_color, 1);
    
    /*if (x%2 == 0 && y%2 == 0) {
        vec4 a = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,0));
        vec4 b = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(1,0));
        vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,1));
        vec4 d = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(1,1));
        COLOR += float(0. < bright((a+b+c+d)/4.)) * vec4(dither_color, 1);
    } else if (x%2 == 1 && y%2 == 0) {
        vec4 a = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(-1,0));
        vec4 b = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,0));
        vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(-1,1));
        vec4 d = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,1));
        COLOR += float(.5 < bright((a+b+c+d)/4.)) * vec4(dither_color, 1);
    } else if (x%2 == 0 && y%2 == 1) {
        vec4 a = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,-1));
        vec4 b = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(1,-1));
        vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,0));
        vec4 d = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(1,0));
        COLOR += float(.75 < bright((a+b+c+d)/4.)) * vec4(dither_color, 1);
    } else {
        vec4 a = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(-1,-1));
        vec4 b = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,-1));
        vec4 c = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(-1,0));
        vec4 d = texture(SCREEN_TEXTURE, SCREEN_UV + SCREEN_PIXEL_SIZE*vec2(0,0));
        COLOR += float(.25 < bright((a+b+c+d)/4.)) * vec4(dither_color, 1);
    }*/
	//[ 0.0,  0.5 ]
    //[ 0.75, 0.25]
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
