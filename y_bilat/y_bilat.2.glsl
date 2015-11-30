#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 adsk_results_pass1

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;


void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(INPUT1, st);

	gl_FragColor = vec4(front.rgb * front.a, front.a);
}
