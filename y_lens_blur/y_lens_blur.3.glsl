//http://www.crytek.com/download/Sousa_Graphics_Gems_CryENGINE3.pdf
//http://psgraphics.blogspot.com/2011/01/improved-code-for-concentric-map.html
//https://www.shadertoy.com/view/MtlGRn

#version 120

#extension GL_ARB_shader_texture_lod : enable

#define INPUT1 adsk_results_pass1
#define INPUT2 adsk_results_pass2
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

uniform bool old;
uniform float max_lod;
uniform float lod_cc_mult;
uniform bool mipmap;
uniform float mm_scale;

uniform sampler2D INPUT1;
uniform sampler2D INPUT2;
uniform int sides;
uniform float fstops;
uniform int samples;
uniform float width;
uniform float aspect;
uniform float gain;
uniform float rotate;
uniform float threshold;
uniform bool show_kernel;
uniform bool show_threshold;
uniform bool clamp_output;

uniform float amount;
uniform float n_size;
uniform float seed;

float noise_a = amount + 1.0;


uniform int make_depth;
uniform int grad_center;
uniform vec2 grad_1;
uniform vec2 grad_2;


vec2 g_hash( vec2 p )
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0* n_size*fract(sin(p + 0.01* seed)*43758.5453123);
}

float get_threshold(vec3 col, float t)
{
	float luma = adsk_getLuminance(col);
	float h = adsk_highlights(luma, t);

	return h;
}

float get_f(float stops, float f_min, float f_max)
{
	float f = (stops - f_min) / (f_max - f_min);

	return f;
}

vec2 to_concentric(vec2 coords)
{
    float phi;
    float r;

    float a = 2.0 * coords.x - 1.0;
    float b = 2.0 * coords.y - 1.0;
	vec2 ret;

    if (a * a > b * b) {
		if (abs(a) > 1e-8) {
        	r = a;
        	phi = (PI / 4) * (b / a);
			ret = vec2(phi, r);
		} else {
			ret = vec2(0.0, a);
		}
    } else {
		if (abs(b) > 1e-8) {
        	r = b;
        	phi = (PI/2) - (PI/4)*(a/b);
			ret = vec2(phi, r);
		} else {
			ret = vec2(0.0, b);
		}
    }

    //return vec2(r * cos(phi), r * sin(phi));
	//return ret;
	return mix(g_hash(ret), ret, 0.95 + noise_a*0.05);
}


vec2 rotate_coords(vec2 coords, float ra)
{
	ra = radians(ra);

	mat2 r = mat2( cos(-ra), -sin(-ra),
                   sin(-ra), cos(-ra) );

	if (show_kernel) {
		coords *= r;
	} else {
		coords.x *= ratio;
		coords *= r;
		coords.x /= ratio;
	}

	return coords;
}

vec2 get_ngon(float f, vec2 c_coords, int num_sides) {
	c_coords = to_concentric(c_coords);

	c_coords.x = c_coords.x + f * (PI * .5);

	if (f > 0.0) {
		c_coords.y = c_coords.y * pow(( cos(PI / num_sides) / 
						cos(c_coords.x - ((2.0 * (PI / num_sides)) * floor(((num_sides * c_coords.x) + PI) / (2.0 * PI))))), f);
	}

	c_coords = vec2(cos(c_coords.x), sin(c_coords.x)) * vec2(c_coords.y);

	return c_coords;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec4 input1 = texture2D(INPUT1, st);
	float blur_factor = texture2D(INPUT2, st).r;

	float w = 1.0;

	float f = get_f(fstops, fstops_min, fstops_max);

	vec2 coord = (st - vec2(0.5)) * 4.0 * vec2(ratio, 1.0);

	float v = 0.0;
	float s = samples;
	vec4 color = input1;

	for(float y = 0.0; y <= 1.0; y += 1.0 / s){
    	for(float x = 0.0; x <= 1.0; x += 1.0 / s){
            vec2 c = get_ngon(f, vec2(x, y), sides);
			if (! show_kernel) {
				c *= vec2(width * .1 / ratio * aspect, width * .1);
				c = rotate_coords(c, rotate);

				vec2 sample_coords = st + c * vec2(blur_factor);
				vec4 blur = texture2D(INPUT1, sample_coords);

				if (mipmap){
						float lod = min(width * 20 * blur_factor, max_lod);
						
						blur = texture2DLod(INPUT1, sample_coords, lod);
						blur *= vec4(1.0 + lod * lod_cc_mult);
				}

				if (old) {
					color += blur;
				} else {
					color += blur * (vec4(mix(1.0, gain, blur_factor)) + smoothstep(vec4(threshold), vec4(1.0), blur * vec4(gain) * vec4(blur_factor)));
				}

				w++;
			} else {
				c.x *= aspect;
				c = rotate_coords(c, rotate);
				v = mix(1.0, v, pow(smoothstep(0.0, 0.05, length(coord - c)), 8.0));
			}
		}
    }    


	if (! show_kernel) {
		color /= vec4(w);
		vec3 t = vec3(get_threshold(color.rgb, .5));
		t = smoothstep(vec3(0.0), vec3(threshold), t);
		if (old) {
			color.rgb = mix(color.rgb, color.rgb * vec3(gain), t * vec3(blur_factor));
		}
	} else {
		color.rgb = vec3(v);
	}

	if (show_threshold) {
		vec3 t = vec3(get_threshold(color.rgb, .5));
		t = smoothstep(vec3(0.0), vec3(threshold), t);
		color.rgb = t;
	}

	if (clamp_output) {
		color = clamp(color, 0.0, 1.0);
	}

	gl_FragColor = color;
}
