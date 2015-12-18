#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 Front


vec3  adsk_hsv2rgb( vec3 hsv );
vec3  adskEvalDynCurves( ivec3 curve, vec3 x );
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform float radius;
uniform int number;
uniform float ring_width;
uniform float spacing;
uniform vec2 p1;
uniform vec2 p2;
uniform float mixx;
uniform int branches;
uniform float aspect;
uniform vec3 fgcol;
uniform vec3 bgcol;
uniform float fg_max;
uniform float softness;
uniform bool show_center_ring;
uniform float scale;
uniform bool clamp_fg;
uniform bool clamp_bg;
uniform bool clamp_out;

vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}


vec2 rotate(vec2 coords, vec2 center, float rotation)
{
    mat2 rm = mat2( cos(-rotation), -sin(-rotation),
                          sin(-rotation), cos(-rotation) );

    coords -= center;
    coords.x *= ratio;
    coords *= rm;
    coords.x /= ratio;
    coords += center;

    return coords;
}

float draw(vec2 coords, vec2 c, float r)
{
	coords.x *= ratio;
	c.x *= ratio;

	vec2 o_coords = coords;

	coords -= c;
	coords.x *= aspect;
	coords += c;

	float col = 0.0;
	float d = distance(c, coords);

	float outer = r;
	float inner = outer - float(ring_width) * texel.x;

	float outer_circle = 1.0 - smoothstep(outer, outer + softness * .001, d);
	float inner_circle = 1.0 - smoothstep(inner, inner + softness * .001, d);

	col = outer_circle - inner_circle;
	col = clamp(col, 0.0, 1.0);

	return col;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	float col = 0.0;
	vec4 xxx = vec4(0.0);

	float half_pi = PI * .5;
	float two_pi = PI * 2.0;
	float branch_inc = two_pi / float(branches);

	vec2 mid_point = mix(p1, p2, .5);
	float d1 = 1.0 - distance(st, mid_point);

	for (int j = 0 ; j < branches ; j++) {
		for (int i = 0 ; i < number ; i++) {
			vec2 coords = st;
			vec2 center = mix(p1, p2, float(i) / float(number - 1.));
			float r = (radius + float(i) * spacing) * texel.x;

			if (number == 1.) {
				center = p1;
			}

			if (j == 0 && i == 0 && show_center_ring) {
				col += draw(coords, center, r);
			} else if (i > 0) {
				coords -= vec2(scale) * (1.0 - distance(coords, p1)) * (1.0 - distance(coords, p2));
				coords = rotate(coords, p1, float(j) * branch_inc);
				col += draw(coords, center, r);
			}
		}
	}

	vec3 f_offset = getRGB( fgcol.x / 360.0, fgcol.z * .01 ) * vec3( fgcol.y * 0.01);
    vec3 col1 = f_offset;

    vec3 b_offset = getRGB( bgcol.x / 360.0, bgcol.z * .01 ) * vec3( bgcol.y * 0.01);
    vec3 col2 = b_offset;

	if (clamp_fg) {
		col = clamp(col, 0.0, 1.0);
	}

	col *= fg_max;

	col1 = col1 * col;


	vec4 outcol = adsk_getBlendedValue(17, vec4(col1, 0.0), vec4(col2, 0.0));
	col = clamp(col, 0.0, 1.0);
	outcol.a = col;

	if (clamp_out) {
		outcol = clamp(outcol, 0.0, 1.0);
	}

	gl_FragColor = outcol;
}
