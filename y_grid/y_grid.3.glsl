#version 120

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

uniform sampler2D Front;
uniform sampler2D Matte;
//uniform sampler2D adsk_results_pass1;
//uniform sampler2D adsk_results_pass2;
uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform vec3 back_color;

vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;

    vec3 col2 = vec3(0.0);

    vec3 b_offset = getRGB( back_color.x / 360.0, back_color.z * .01 ) * vec3( back_color.y * 0.01);
    col2 = b_offset;

    gl_FragColor.rgb = col2;
}
