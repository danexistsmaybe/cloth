shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform sampler2D chalk : source_color;
uniform sampler2D blackboard : source_color;

void fragment() {
    vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
    if (screen.x + screen.y + screen.z > .3) {
        COLOR = texture(chalk, .4*UV).a*vec4(1,1,1,1) + 1.*texture(blackboard, UV);
    } else {
        COLOR = texture(blackboard, UV);
    }
}