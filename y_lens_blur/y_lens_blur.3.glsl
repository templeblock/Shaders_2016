//http://www.crytek.com/download/Sousa_Graphics_Gems_CryENGINE3.pdf
//http://psgraphics.blogspot.com/2011/01/improved-code-for-concentric-map.html
//https://www.shadertoy.com/view/MtlGRn

#version 120

#extension GL_ARB_shader_texture_lod : enable

#define INPUT0 adsk_results_pass1
#define INPUT1 adsk_results_pass2
#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

float adsk_getLuminance( in vec3 color );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT0;
uniform sampler2D INPUT1;

uniform float width;
uniform float gain;
uniform float threshold;
uniform bool show_threshold;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(INPUT0, st);
	float blur_factor = texture2D(INPUT1, st).a;

	float luma = adsk_getLuminance(front.rgb);

	float w = smoothstep(threshold, threshold + .25, luma);
	float t = (w * blur_factor) * (width * 10);
	t = clamp(t, 0.0, 1.0);
	front.rgb = mix(front.rgb, front.rgb * vec3(gain), t); 

	float matte = front.a;

	if (show_threshold) {
		matte = t;
	}

	gl_FragColor = vec4(front.rgb, matte);
}
