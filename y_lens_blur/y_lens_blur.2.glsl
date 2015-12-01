//http://www.crytek.com/download/Sousa_Graphics_Gems_CryENGINE3.pdf
//http://psgraphics.blogspot.com/2011/01/improved-code-for-concentric-map.html
//https://www.shadertoy.com/view/MtlGRn

#version 120

#extension GL_ARB_shader_texture_lod : enable

#define INPUT0 adsk_results_pass1
#define INPUT1 Depth
#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

float adsk_getLuminance( in vec3 color );
float adsk_highlights( in float pixel, in float halfPoint );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;


uniform sampler2D INPUT0;
uniform sampler2D INPUT1;

uniform float far;
uniform float aperture;
uniform float focal_distance;
uniform float focal_length;
uniform vec2 depth_pick;
uniform bool pick_depth;

uniform float gain;
uniform float threshold;
uniform bool show_threshold;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(INPUT0, st);
	float depth = texture2D(INPUT1, st).r;
	depth = clamp(depth, 0.0001, .9999);

	float fp = focal_distance;

	if (pick_depth) {
		fp = texture2D(INPUT1, depth_pick).r;
	}

	float blur_factor;

	blur_factor = distance(fp, depth) * aperture;
    blur_factor = (1.0 - blur_factor) * focal_length;
	blur_factor = 1.0 - blur_factor;

	float luma = adsk_getLuminance(front.rgb);
	float t = step(threshold, luma) * blur_factor;
	front.rgb = mix(front.rgb, front.rgb * vec3(gain), t); 

	if (show_threshold) {
		front.rgb = vec3(t);
	}

	gl_FragColor = vec4(front.rgb, blur_factor);
}
