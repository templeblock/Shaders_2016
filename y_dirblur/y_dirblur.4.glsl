#version 120

// Change the folling 4 lines to suite
#define STRENGTH adsk_results_pass2
#define STRENGTH_CHANNEL 

uniform bool keep_inside;
uniform bool bidir;

uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass3;
uniform int i_colorspace;
uniform float direction;
uniform vec2 angle_vector;
uniform vec2 start_vector;
uniform bool soften_perp;
uniform int soften;
uniform bool use_angle;
uniform float angle_float;

#define PI 3.141592653589793238462643383279502884197969

#ifdef STRENGTH_CHANNEL
	uniform sampler2D STRENGTH;
#endif


uniform float blur_amount;
uniform float blur_red;
uniform float blur_green;
uniform float blur_blue;
float blur_matte = 1.0;

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

bool isInTex( const vec2 coords )
{
   return coords.x >= 0.0 && coords.x <= 1.0 &&
          coords.y >= 0.0 && coords.y <= 1.0;
}


vec2 rotate(vec2 coords, float the_angle)
{
	float rad = radians(the_angle);
	mat2 rm = mat2( cos(-rad), -sin(-rad),
                    sin(-rad), cos(-rad) );

	return coords * rm;
}

vec4 gblur()
{
	 //The blur function is the work of Lewis Saunders.
	vec2 xy = gl_FragCoord.xy;
	vec2 st = gl_FragCoord.xy / res;

	float strength = 1.0;

	//Optional texture used to weight amount of blur
	#ifdef STRENGTH_CHANNEL
		strength = texture2D(STRENGTH, gl_FragCoord.xy / res).a;
	#endif

	float br = blur_red * blur_amount *  strength;
	float bg = blur_green * blur_amount  * strength;
	float bb = blur_blue * blur_amount *  strength;
	float bm = blur_amount * strength;

	float support = max(max(max(br, bg), bb), bm) * 3.0;

	vec4 sigmas = vec4(br, bg, bb, bm);
	sigmas = max(sigmas, 0.0001);

	vec4 gx, gy, gz;
	gx = 1.0 / (sqrt(2.0 * PI) * sigmas);
	gy = exp(-0.5 / (sigmas * sigmas));
	gz = gy * gy;

	vec4 a = gx * texture2D(adsk_results_pass3, xy * texel);
	vec4 energy = gx;
	gx *= gy;
	gy *= gz;

	vec2 na = normalize(angle_vector - vec2(.5));
	if (use_angle) {
		na = rotate(vec2(0.0, 1.0), angle_float);
	}
	for(float i = 1; i <= support; i++) {
		if (isInTex(xy * texel)) {
        a += gx * texture2D(adsk_results_pass3, (xy - i * na) * texel);
		energy += gx;
		
		if (bidir) { 
			a += gx * texture2D(adsk_results_pass3, (xy + i * na) * texel);
			energy += gx;
		}

		gx *= gy;
		gy *= gz;
		}
	}

	a /= energy;

	if (soften_perp) {
		support = soften;
		gx = 1.0 / (sqrt(2.0 * PI) * sigmas);
		gy = exp(-0.5 / (sigmas * sigmas));
		gz = gy * gy;

		energy = gx;
		gx *= gy;

		for(float i = 1; i <= support; i++) {
			a += gx * texture2D(adsk_results_pass3, (xy - i * rotate(na, 90)) * texel);
			a += gx * texture2D(adsk_results_pass3, (xy + i * rotate(na, 90)) * texel);
			energy += gx * 2.0;

			gx *= gy;
			gy *= gz;
		}

		a /= energy;
	}

	return a;
}

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


void main(void)
{
	vec2 st = gl_FragCoord.xy / res;
	vec4 front = texture2D(adsk_results_pass1, st);
	vec4 blur = gblur();

	float matte = front.a;

	blur.rgb /= max(blur.a, .0001);

	vec3 xxx = blur.rgb;

	if (! keep_inside) {
		matte = blur.a;
	}

	matte = clamp(matte, 0.0, 1.0);

	vec4 comp = mix(front, blur, matte);

	if (i_colorspace == 0) {
        comp.rgb = to_rec709(comp.rgb);
    } else if (i_colorspace == 1) {
        comp.rgb = to_sRGB(comp.rgb);
    } else if (i_colorspace == 2) {
        //linear
    } else if (i_colorspace == 3) {
        comp.rgb = adjust_cgamma(comp.rgb, 2.2);
    } else if (i_colorspace == 4) {
        comp.rgb = adjust_cgamma(comp.rgb, 1.8);
    }

	//comp.rgb = xxx;
	gl_FragColor = vec4(comp.rgb, matte);
}
