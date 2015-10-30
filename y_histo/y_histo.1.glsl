#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

float adsk_getLuminance( in vec3 color );
float adsk_highlights( in float pixel, in float halfPoint ); 
float adsk_shadows( in float pixel, in float halfPoint );

uniform sampler2D Front;
uniform sampler2D Back;
uniform sampler2D Matte;

uniform float mid;
//float mid = .5;
uniform float shadow_gain;
uniform float highlight_gain;
uniform bool clamp_output;
uniform bool negate_input;
uniform bool midtones;
uniform bool mono;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	float matte = texture2D(Matte, st).r;

	float lum = adsk_getLuminance(front);
	vec3 shadows = vec3(0.0);
	shadows.r = adsk_shadows(front.r, mid);
	shadows.g = adsk_shadows(front.g, mid);
	shadows.b = adsk_shadows(front.b, mid);

	vec3 highlights = vec3(1.0);
	highlights.r = adsk_highlights(front.r, mid);
	highlights.g = adsk_highlights(front.g, mid);
	highlights.b = adsk_highlights(front.b, mid);

	shadows *= shadow_gain + 1.0;
	highlights *= highlight_gain;

	shadows *= front;
	highlights *= front;

	vec3 comp = mix(front, highlights + shadows, matte);

	if (midtones) {
		comp = (clamp(highlights * 2.0, 0.0, 1.0) - highlights) * 2.0;

	}

	if (negate_input) {
		comp = vec3(1.0) - comp;
	}


	if (clamp_output)
	{
		comp = clamp(comp, 0.0, 1.0);
	}


	if (mono) {
			float lum = adsk_getLuminance(comp);
			comp = vec3(lum);
	}


	gl_FragColor = vec4(comp, matte);
}
