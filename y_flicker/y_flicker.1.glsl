#version 120
#extension GL_ARB_shader_texture_lod : enable

float adsk_getLuminance( vec3 );

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

uniform sampler2D LockFrame, Front;
uniform float lod;
uniform int operation;
uniform bool match_chroma;


void main(void)
{
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = vec3(0.0);
	vec3 front_avg = texture2DLod(Front, st, lod).rgb;
	vec3 lock_frame = texture2DLod(LockFrame, st, lod).rgb;

	vec3 new_gain = vec3(0.0);

	if (operation == 1) {
		if (lock_frame.r != 0.0) {
			new_gain.r = front_avg.r / lock_frame.r;
		}
		if (lock_frame.g != 0.0) {
			new_gain.g = front_avg.r / lock_frame.g;
		}
		if (lock_frame.b != 0.0) {
			new_gain.b = front_avg.b / lock_frame.b;
		}
		front = texture2D(LockFrame, st).rgb;
	} else {
		new_gain = lock_frame / max(front_avg, vec3(.00001));

		if (front_avg.r != 0.0) {
			new_gain.r = lock_frame.r / front_avg.r;
		}
		if (front_avg.g != 0.0) {
			new_gain.g = lock_frame.r / front_avg.g;
		}
		if (front_avg.b != 0.0) {
			new_gain.b = lock_frame.b / front_avg.b;
		}

		front = texture2D(Front, st).rgb;
	}

	new_gain = clamp(new_gain, -5.0, 5.0);

	float gdif = adsk_getLuminance(new_gain.rgb);

	if (match_chroma) {
		front *= new_gain;
	} else {
		front *= gdif;
	}

	gl_FragColor.rgb = front;
}
