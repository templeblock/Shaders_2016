#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 adsk_results_pass1


vec3  adsk_hsv2rgb( vec3 hsv );
vec3  adskEvalDynCurves( ivec3 curve, vec3 x );
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );


uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform float x1;
uniform float x2;
uniform int samples;
uniform float width;
uniform float height;
uniform vec2 pos;
uniform float noise_scale;
uniform vec3 fgcol;
uniform vec3 bgcol;
uniform bool use_noise;
uniform bool show_noise;
uniform bool swap_uv;
uniform float fg_clamp;

vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}



void main(void) {
	vec2 st = gl_FragCoord.xy / res;
	vec2 tmp = st;
	tmp.y /= 0.0;
	tmp.x /= noise_scale;

	float lut = 1.0;

	if (use_noise) {
		lut = texture2D(INPUT1, tmp).a;
	}

	float col = 0.0;

	vec2 coords = st;

	if (swap_uv) {
		coords.x = coords.y;
		coords.y = st.x;
	}

	coords = coords * 2.0 - 1.0;

	coords -= pos;

	for (int i = 0 ; i < samples ; i++) {
		float s = float(i) / float(samples - 1);
		float p1 = mix(x1, x2,s*lut);
		float p2 = mix(x1, -x2,s*lut);
		float w = texel.x * width;

		col += step(coords.x, p1) - step(coords.x, p1 - w);
		col += step(coords.x, p2) - step(coords.x, p2 - w);
	}

	col *= step(coords.y, height);
	col *= step(-coords.y, height);

	col *= fg_clamp;


	vec3 f_offset = getRGB( fgcol.x / 360.0, fgcol.z * .01 ) * vec3( fgcol.y * 0.01);
    vec3 col1 = f_offset;

    vec3 b_offset = getRGB( bgcol.x / 360.0, bgcol.z * .01 ) * vec3( bgcol.y * 0.01);
    vec3 col2 = b_offset;

	col1 *= vec3(col);


	vec4 outcol = adsk_getBlendedValue(17, vec4(col1, 0.0), vec4(col2, 0.0));

	col = clamp(col, 0.0, 1.0);
	outcol.a = col;

	if (show_noise) {
		outcol.a = lut;
	}

	gl_FragColor =  outcol;
}
