#version 120

// Change the folling 4 lines to suite
#define STRENGTH some_input
//#define VERTICAL 
//#define STRENGTH_CHANNEL 

#define PI 3.141592653589793238462643383279502884197969

#define INPUT adsk_results_pass3
uniform sampler2D INPUT;
uniform sampler2D adsk_results_pass1;

#ifdef STRENGTH_CHANNEL
	uniform sampler2D STRENGTH;
#endif

#ifndef VERTICAL
	const vec2 dir = vec2(0.0, 1.0);
#else
	const vec2 dir = vec2(1.0, 0.0);
#endif


uniform float blur_amount;
uniform float edge_strength;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

vec4 gblur()
{
	 //The blur function is the work of Lewis Saunders.
	vec2 xy = gl_FragCoord.xy;

	float strength = 1.0;

	//Optional texture used to weight amount of blur
	#ifdef STRENGTH_CHANNEL
		strength = texture2D(STRENGTH, gl_FragCoord.xy / res).r;
	#endif


	float bias = 1.0;
	float sigma = blur_amount * bias * strength + .001;
	float support = sigma * 3.0;

	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * PI) * sigma);
	g.y = exp(-0.5 / (sigma * sigma));
	g.z = g.y * g.y;

	vec4 a = g.x * texture2D(INPUT, xy * texel);
	float energy = g.x;
	g.xy *= g.yz;

	for(float i = 1; i <= support; i++) {
        a += g.x * texture2D(INPUT, (xy - dir * i) * texel);
        a += g.x * texture2D(INPUT, (xy + dir * i) * texel);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}

	a /= energy;

	vec4 edge = a * vec4(edge_strength + 1.0);
	edge = clamp(edge, 0.0, 1.0);

	return edge;
}

void main(void)
{
	vec4 edge = gblur();
	
	gl_FragColor = edge;
}
