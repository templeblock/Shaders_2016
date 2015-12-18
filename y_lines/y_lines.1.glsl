#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 Front


vec3  adsk_hsv2rgb( vec3 hsv );
vec3  adsk_rgb2hsv( vec3 hsv );
float adsk_getLuminance( vec3 );
float adskEvalDynCurves( int curve, float x );
vec3  adskEvalDynCurves( ivec3 curve, vec3 x );
vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor );


uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform vec2 p1;
uniform vec2 p2;
uniform float thickness;
uniform float softness;
uniform float mid_width;
uniform float bend;
uniform int num_lines;
uniform float spacing;
uniform int clip_end;
uniform vec3 bgcol;
uniform vec3 fgcol;
uniform bool clamp_fg;
uniform float fg_clamp_max;
uniform float fg_clamp_min;
uniform bool clamp_bg;
uniform bool clamp_output;
uniform int emmit_from;
uniform int blend_mode;
uniform int spawn_type;
uniform int spawn_type_key;
uniform bool spawn_key;
uniform float mid_distance;
uniform float mid_scale;

bool isInTex( const vec2 coords )
{
   return coords.x >= 0.0 && coords.x <= 1.0 &&
          coords.y >= 0.0 && coords.y <= 1.0;
}

vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}

float draw(vec2 point1, vec2 point2)
{
	vec2 st = gl_FragCoord.xy / res;

	if (point1 == point2) {
		return 0.0;	
	}

	st.x *= ratio;
	point1.x *= ratio;
	point2.x *= ratio;

	vec2 og = st;

	st.y += bend * distance(st, point1) * distance(st, point2);
	st.x += bend * distance(st, point1) * distance(st, point2);


	//normalize this vector so the value of the cross product doesn't
	//change as the distance between the two points change
	vec2 pp = normalize(point1 - point2);
	vec2 pp2 = st - point2;

	//cross product;
	//float c1 = (st.x - p2.x) * (p1.y - p2.y) - (st.y - p2.y) * (p1.x - p2.x);
	//float c1 = (st.x - p2.x) * (pp.y) - (st.y - p2.y) * (pp.x);
	float c1 = pp2.x * pp.y - pp2.y * pp.x;
	c1 = abs(c1);

	float dot1 = dot(normalize(point1 - st), pp);
	float angle1 = acos(dot1);
	float dot2 = dot(normalize(st - point2), pp);
	float angle2 = acos(dot2);

	float half_pi = PI * .5;

	float t = thickness * ratio * .5;
	float t_texel = t * texel.x;

	float l1 = smoothstep(t_texel, 1.0, c1);
	float l2 = smoothstep(0.0, texel.x / (t / (t * .01 * softness)), l1);
	
	if (clip_end == 1) {
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle1);
		l2 = clamp(l2, 0.0, 1.0);
	} else if (clip_end == 2) {
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle2);
		l2 = clamp(l2, 0.0, 1.0);
	} else if (clip_end == 3) {
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle1);
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle2);
		l2 = clamp(l2, 0.0, 1.0);
	}

	return 1.0 - l2;
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

float emmit0(float col, vec2 point1, vec2 point2, int i, float op)
{
	vec2 p;

	p = rotate(point2, point1, PI * op * spacing * .01 * i);
	col += draw(point1, p);
	p = rotate(point2, point1, -PI * op * spacing * .01 * i);
	col += draw(point1, p);

	return col;
}


void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	float col = 0.0;
	vec2 pp1 = p1;
	vec2 pp2 = p2;

	vec2 point1 = p1;
	vec2 point2 = p2;

	vec2 mid_point = (point1 + point2) * vec2(mid_distance);
	mid_point.y /= mid_scale;

	float ops[11];
	ops[0] = sin(st.x);
	ops[1] = cos(st.x);
	ops[2] = sin(st.y);
	ops[3] = cos(st.y);
	ops[4] = cos(st.x) * sin(st.y);
	ops[5] = cos(st.y) * sin(st.x);
	ops[6] = tan(st.x);
	ops[7] = tan(st.y);
	ops[8] = sin(st.x * PI);
	ops[9] = sin(st.x * PI) * sin(st.y * PI);
	ops[10] = 1.0;

	int stype = spawn_type;

	if (spawn_key) {
		stype = spawn_type_key;
	}

	for (int i = 0 ; i < num_lines ; i++) {
		if (emmit_from == 0) {
			col = emmit0(col, point1, point2, i, 1.0);
		} else if (emmit_from == 1) {
			col = emmit0(col, point2, point1, i, ops[stype]);
		} else if (emmit_from == 2) {
			col = emmit0(col, mid_point, point1, i, ops[stype]);
		} else if (emmit_from == 3) {
			col = emmit0(col, point1, point2, i, 1.0);
			col = max(col, emmit0(col, point2, point1, i, ops[stype]));
		} else if (emmit_from == 4) {
			col = emmit0(col, point1, point2, i, 1.0);
			col = max(col, emmit0(col, point2, point1, i, ops[stype]));
			col = max(col, emmit0(col, mid_point, point1, i, ops[10 - stype]));
		}
	}

    vec3 f_offset = getRGB( fgcol.x / 360.0, fgcol.z * .01 ) * vec3( fgcol.y * 0.01);
    vec3 col1 = f_offset;

    vec3 b_offset = getRGB( bgcol.x / 360.0, bgcol.z * .01 ) * vec3( bgcol.y * 0.01);
    vec3 col2 = b_offset;

	col *= fg_clamp_max;

	if (clamp_fg) {
		col = clamp(col, 0.0, 1.0);
	}

	if (clamp_bg) {
		col2 = clamp(col2, 0.0, 1.0);
	}

	vec4 comp = vec4(0.0);
	comp.rgb = vec3(col) * col1;
	comp = adsk_getBlendedValue(blend_mode, comp, vec4(col2, 0.0));

	if (clamp_output) {
		comp = clamp(comp, 0.0, 1.0);
		col = clamp(col, 0.0, 1.0);
	}

	comp.a = col;

	gl_FragColor = comp;
}
