#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 Front

uniform float ratio;
uniform float adsk_time;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

float rand(vec2 co){
	float time = floor(adsk_time + 100);
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453 * time);
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;
	float noise = rand(st);

	vec3 input1 = texture2D(INPUT1, st).rgb;

	gl_FragColor = vec4(input1, noise);
}
