#version 120

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

//uniform sampler2D adsk_results_pass1;
//uniform sampler2D adsk_results_pass2;
uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform float width_x;
uniform float width_y;
uniform float line_x;
uniform float line_y;
uniform float line_width;
uniform float grid_width;
uniform float x_offset;
uniform float y_offset;

uniform vec3 grid_color;
uniform vec3 back_color;

uniform bool offset_width;
uniform bool keep_aspect;
uniform int options;

vec2 center = vec2(.5);

vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}

void main(void) {
    vec2 fc = gl_FragCoord.xy;

    vec3 col1 = vec3(1.0);
    float alpha = 0.0;
    vec3 comp = vec3(0.0);

    float center_offset = 0.0;

    vec2 grid_offset = vec2(x_offset, y_offset);
    vec2 coords_offset = (fc - vec2(.5)) - res * vec2(.5);

    if (options == 1 || options == 3) {
        coords_offset.x /= adsk_result_frameratio;
    }

    if (options == 2 || options == 3) {
        grid_offset -= vec2(grid_width + width_x, grid_width + width_y) * vec2(.5);
    }

    coords_offset -= grid_offset;

    float x = mod(coords_offset.x + .5 -(line_width * line_x) * .5,  grid_width + width_x + (line_width * line_x));
    float y = mod(coords_offset.y + .5 -(line_width * line_y) * .5,  grid_width + width_y + (line_width * line_y));

    alpha  = step(grid_width + width_x, x) + step(grid_width + width_y, y);
    alpha = clamp(alpha, 0.0, 1.0);

    vec3 g_offset = getRGB( grid_color.x / 360.0, grid_color.z * .01 ) * vec3( grid_color.y * 0.01);
    col1 = g_offset;

    gl_FragColor = vec4(col1, alpha);
}
