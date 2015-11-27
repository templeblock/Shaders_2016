#version 120

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Back;
uniform sampler2D Matte;

uniform float blend;
uniform bool clamp_out;
uniform bool strength;
uniform bool swap;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	vec3 back = texture2D(Back, st).rgb;
	float matte = texture2D(Matte, st).r;

	if (swap) {
		vec3 tmp = front;
		front = back;
		back = tmp;
	}

	vec3 comp = vec3(1.0);
	float b = blend;
	if (strength) {
		b = blend * matte;
	}

	comp = mix(front, back, matte * b);

	if (clamp_out) {
		comp = clamp(comp, 0.0, 1.0);
	}

	gl_FragColor = vec4(comp, matte);
}
