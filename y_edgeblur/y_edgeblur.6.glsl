#version 120

// Change the folling 4 lines to suite
#define STRENGTH some_input
//#define VERTICAL 
//#define STRENGTH_CHANNEL 

#define PI 3.141592653589793238462643383279502884197969

#define INPUT adsk_results_pass5
uniform sampler2D INPUT;
uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass4;
uniform bool show_edges;

#ifdef STRENGTH_CHANNEL
	uniform sampler2D STRENGTH;
#endif

#ifndef VERTICAL
	const vec2 dir = vec2(0.0, 1.0);
#else
	const vec2 dir = vec2(1.0, 0.0);
#endif


uniform float blur_amount_fg;
uniform int alpha_out;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

uniform int i_colorspace;


vec3 adjust_cgamma(vec3 col, float gamma)
{
    if (col.r >= 0.0) {
        col.r = pow(col.r, 1.0 / gamma);
    }

    if (col.g >= 0.0) {
        col.g = pow(col.g, 1.0 / gamma);
    }

    if (col.b >= 0.0) {
        col.b = pow(col.b, 1.0 / gamma);
    }

    return col;
}


vec3 to_rec709(vec3 col)
{
    if (col.r < .018) {
        col.r *= 4.5;
    } else if (col.r >= 0.0) {
        col.r = (1.099 * pow(col.r, .45)) - .099;
    }

    if (col.g < .018) {
        col.g *= 4.5;
    } else if (col.g >= 0.0) {
        col.g = (1.099 * pow(col.g, .45)) - .099;
    }

    if (col.b < .018) {
        col.b *= 4.5;
    } else if (col.b >= 0.0) {
        col.b = (1.099 * pow(col.b, .45)) - .099;
    }


    return col;
}

vec3 to_sRGB(vec3 col)
{
    if (col.r >= 0.0) {
        col.r = (1.055 * pow(col.r, 1.0 / 2.4)) - .055;
    }

    if (col.g >= 0.0) {
        col.g = (1.055 * pow(col.g, 1.0 / 2.4)) - .055;
    }

    if (col.b >= 0.0) {
        col.b = (1.055 * pow(col.b, 1.0 / 2.4)) - .055;
    }

    return col;
}


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
	float sigma = blur_amount_fg * bias * strength + .001;
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

	return a;
}

void main(void)
{
	vec2 st = gl_FragCoord.xy / res;
	vec4 front = texture2D(adsk_results_pass1, st);
	float edge = texture2D(adsk_results_pass4, st).a;
	vec4 blur = gblur();
	vec3 comp = mix(front.rgb, blur.rgb, edge);

	if (i_colorspace == 0) {
        comp = to_rec709(comp);
    } else if (i_colorspace == 1) {
        comp = to_sRGB(comp);
    } else if (i_colorspace == 2) {
        //linear
    } else if (i_colorspace == 3) {
        comp = adjust_cgamma(comp, 2.2);
    } else if (i_colorspace == 4) {
        comp = adjust_cgamma(comp, 1.8);
    }


	float a = edge;
	if (alpha_out == 1) {
		a = front.a;
	} else if (alpha_out == 2) {
		a = front.a + edge;
	}

	if (show_edges) {
		comp = vec3(edge);
		a = 1.0;
	}

	gl_FragColor = vec4(comp, a);
}
