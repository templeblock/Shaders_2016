//http://www.crytek.com/download/Sousa_Graphics_Gems_CryENGINE3.pdf
//http://psgraphics.blogspot.com/2011/01/improved-code-for-concentric-map.html
//https://www.shadertoy.com/view/MtlGRn

#version 120

#extension GL_ARB_shader_texture_lod : enable

#define INPUT1 Front
#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969
#define fstops_min 0.0
#define fstops_max 4.0
#define max_focal 10.0

float adsk_getLuminance( in vec3 color );
float adsk_highlights( in float pixel, in float halfPoint );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform float aperture;
uniform float focal_length;
uniform float focal_distance;
uniform vec2 depth_pick;
uniform bool pick_depth;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(INPUT1, st).rgb;
	float depth = adsk_getLuminance(front);
	depth = clamp(depth, 0.0000, 1.0);

	float fp = focal_distance;

	if (pick_depth) {
		fp = texture2D(INPUT1, depth_pick).r;
	}

	float blur_factor = 1.0 - smoothstep(fp - focal_length, depth - focal_length, depth);
	blur_factor += 1.0 - smoothstep(fp + focal_length, depth + focal_length, depth);
	blur_factor = mix(blur_factor, 1.0, 1.0 - distance(fp, depth));
	blur_factor = 1.0 - blur_factor;
	blur_factor *= aperture;

	blur_factor = clamp(blur_factor, 0.0, 1.0);

	gl_FragColor = vec4(front, 1.0 - blur_factor);
}
