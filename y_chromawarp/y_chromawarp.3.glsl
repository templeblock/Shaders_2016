//Heavily Inspired from https://www.shadertoy.com/view/XssGz8

#version 120

//float adsk_getLuminance( vec3 );
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722));


uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

#define towarp adsk_results_pass1
#define PI 3.141592653589793238462643383279502884197969
#define EPSILON 0.000011

//uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass4, adsk_results_pass5;

uniform sampler2D towarp;
uniform sampler2D adsk_results_pass2;
uniform int samples;
uniform vec2 center;
uniform float scale, scale_x, scale_y;
uniform bool repeat_texture;
uniform float pos_x, pos_y, pos_z;
uniform bool warp_matte;
uniform bool front_is_back;
uniform bool matte_is_strength;

bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
}

vec4 offset_color(float amount)
{
	//when times goes past half samples lo is black;
	float lo = step(amount ,0.5);
    float hi = 1.0 - lo;

	float a = 1.0 / 6.0;
	float b = 5.0 / 6.0;

	// times gets closer to samples, x gets brighter, when times == samples, x is clamped to white;
	float x = clamp( (amount - a) / (b - a), 0.0, 1.0 );

	//when x gets brigher, w becomes darker
	float w = clamp(1.0 - abs(2.0 * x - 1.0), 0.0, 1.0);

	// times starts red and as it gets closer to samples it goes orange, green, blue
	vec3 rgb = vec3(lo, 1.0, hi) * vec3(1.0 - w, w, 1.0 - w);

	// if times starts at 0 and goes to 3, the result is, dark, bright, darker dark
	//float lum =  adsk_getLuminance(rgb);
	float lum = luma(rgb); 

	// linearize

	vec4 color = vec4(rgb, lum);
	vec4 gamma = vec4(1.0 / 2.2);

	color =  pow(color, gamma);
	
	return color;
}

vec2 scale_coords(vec2 coords, vec2 center, vec2 scale_amount)
{
	coords -= center;
	coords /= scale_amount;
	coords += center;

	return coords;
}

void main()
{	
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(towarp, st);
	vec4 comp = vec4(0.0);
	vec4 warped = vec4(0.0);
	vec4 total = vec4(0.0);
	vec4 back = texture2D(adsk_results_pass2, st);

	float matte = front.a;
	float strength = back.a;

	if (matte_is_strength) {
		strength = matte;
	}

	float sample_norm = 1.0 / float(samples);

	for (int i = 0; i < samples; i++)
	{
		float amount = float(i) * sample_norm;
		vec4 color = offset_color(amount);

		total += color;

		vec2 coords = st;

		coords = coords - vec2(pos_x, pos_y) * texel * vec2(strength) * amount;
		if (i == 0) {
			coords = scale_coords(coords, vec2(.5), vec2(1.0));
		} else {
			coords = scale_coords(coords, center, vec2(scale_x * scale * texel.x * amount * strength + 1.0, scale_y * scale * texel.y * amount * strength + 1.0));
			coords = scale_coords(coords, vec2(.5), vec2(pos_z * texel * amount * strength + 1.0));
		}

		if (isInTex(coords))
		{
			warped += color * texture2D(towarp, coords);
		}
	}

	warped /= total;
	comp = mix(front, warped, strength);

	if (warp_matte)
	{
		matte = warped.a;
	}

	if (front_is_back) {
		back = front;
	}

	comp = mix(back, comp, matte);

	comp.a = matte;

	gl_FragColor = comp;
}
