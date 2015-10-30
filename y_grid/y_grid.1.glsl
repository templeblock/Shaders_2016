#version 120

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

uniform sampler2D Front;
uniform sampler2D Matte;
uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

vec2 center = vec2(.5);

void main(void) {
    vec2 st = gl_FragCoord.xy / res;

    vec3 front = texture2D(Front, st).rgb;
    float matte = texture2D(Matte, st).r;

    gl_FragColor = vec4(front, matte);
}
