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


uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform vec2 p1;
uniform vec2 p2;
uniform int thickness;
uniform int softness;
uniform float mid_width;
uniform float bend;
uniform int num_lines;
uniform float spacing;
uniform bool clip_ends;
uniform vec3 bgcol;
uniform vec3 fgcol;
uniform bool clamp_fg;
uniform bool clamp_bg;
uniform bool clamp_output;

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


float draw(vec2 p1, vec2 p2)
{
	vec2 st = gl_FragCoord.xy / res;

	if (p1 == p2) {
		return 0.0;	
	}

	vec2 mid_point = (p1 + p2) * vec2(.5);

	st.x *= ratio;
	p1.x *= ratio;
	p2.x *= ratio;

	vec2 og = st;

	st.y += bend * distance(st, p1) * distance(st, p2);
	st.x += bend * distance(st, p1) * distance(st, p2);


	//normalize this vector so the value of the cross product doesn't
	//change as the distance between the two points change
	vec2 pp = normalize(p1 - p2);
	vec2 pp2 = st - p2;

	//cross product;
	//float c1 = (st.x - p2.x) * (p1.y - p2.y) - (st.y - p2.y) * (p1.x - p2.x);
	//float c1 = (st.x - p2.x) * (pp.y) - (st.y - p2.y) * (pp.x);
	float c1 = pp2.x * pp.y - pp2.y * pp.x;
	c1 = abs(c1);

	float dot1 = dot(normalize(p1 - st), pp);
	float angle1 = acos(dot1);
	float dot2 = dot(normalize(st - p2), pp);
	float angle2 = acos(dot2);

	float half_pi = PI * .5;

	float t = thickness * ratio * .5;
	float t_texel = t * texel.x;

	float l1 = smoothstep(t_texel, 1.0, c1);
	float l2 = smoothstep(0.0, texel.x / (t / (t * .01 * softness)), l1);
	
	if (clip_ends) {
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle1);
		l2 += smoothstep(half_pi - .01 * softness, half_pi, angle2);
		l2 = clamp(l2, 0.0, 1.0);
	}



	return 1.0 - l2;
}



void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	float col = 0.0;
	for (int i = 0 ; i < num_lines ; i++) {
		vec2 pp2 = rotate(p2, p1, PI * spacing * .01 * i);
		col += draw(p1, pp2);
		pp2 = rotate(p2, p1, -PI * spacing * .01 * i);
		col += draw(p1, pp2);
	}

    vec3 f_offset = getRGB( fgcol.x / 360.0, fgcol.z * .01 ) * vec3( fgcol.y * 0.01);
    vec3 col1 = f_offset;

    vec3 b_offset = getRGB( bgcol.x / 360.0, bgcol.z * .01 ) * vec3( bgcol.y * 0.01);
    vec3 col2 = b_offset;

	if (clamp_fg) {
		col = clamp(col, 0.0, 1.0);
	}

	vec3 comp = mix(vec3(0.0), col1, col);

	if (clamp_bg) {
		col = clamp(col, 0.0, 1.0);
	}

	comp /= vec3(col);
	comp = mix(col2, comp, col);

	if (clamp_output) {
		comp = clamp(comp, 0.0, 1.0);
		col = clamp(col, 0.0, 1.0);
	}

	gl_FragColor = vec4(comp, col); 
}
