#version 120

#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Matte;
uniform float angle;
uniform float r_angle;
uniform float g_angle;
uniform float b_angle;
uniform float c_angle;
uniform float m_angle;
uniform float y_angle;
uniform float o_angle;
uniform float r_s;
uniform float g_s;
uniform float b_s;
uniform float c_s;
uniform float m_s;
uniform float y_s;
uniform float o_s;
uniform float r_f;
uniform float g_f;
uniform float b_f;
uniform float c_f;
uniform float m_f;
uniform float y_f;
uniform float o_f;
uniform bool yuv;
uniform int matte_out;

vec2 rotate(vec2 uv, float aa)
{
	float a = radians(aa);

	mat2 rotationMatrice = mat2( cos(-a), -sin(-a),
                          sin(-a), cos(-a) );

	return uv * rotationMatrice;
}


vec3 to_yuv(vec3 col)
{
	mat3 yuv = mat3
	(
		.2126, .7152, .0722,
		-.09991, -.33609, .436,
		.615, -.55861, -.05639
	);

	return col * yuv;
}

vec3 to_rgb(vec3 col)
{
	mat3 rgb = mat3
	(
		1.0, 0.0, 1.28033,
		1.0, -.21482, -.38059,
		1.0, 2.12798, 0.0
	);

	return col * rgb;
}

float diff(vec3 a, vec3 b, float f)
{
	vec2 q = a.gb;
	vec2 r = b.gb;

	q = normalize(q);
	r = normalize(r);

	float angle = acos(dot(q, r)) / PI;
	float falloff = pow(1.0 - angle, f);

	return clamp(falloff, 0.0, 1.0);
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	float matte = texture2D(Matte, st).r;

	front = to_yuv(front);
	vec3 orig = front;

	vec2 uv = front.gb;
	float y = front.r;
	float u = front.g;
	float v = front.b;

	vec3 red = (vec3(y, -.09985, .61465) );
	vec3 green = (vec3(y, -.33594, -.55859) );
	vec3 blue = (vec3(y, .43579, -.05637) );
	vec3 cyan = (vec3(y, .09985, -.61475) );
	vec3 magenta = (vec3(y, .33594, .55859) );
	vec3 yellow = (vec3(y, -.43579, .05637) );
	vec3 orange = (vec3(y, -.31787, .64307) );

	float r_d = diff(red, front, r_f);
	front.gb = mix(front.gb, rotate(front.gb, r_angle) * vec2(r_s), r_d);

	float g_d = diff(green, front, g_f);
	front.gb = mix(front.gb, rotate(front.gb, g_angle) * vec2(g_s), g_d);

	float b_d = diff(blue, front, b_f);
	front.gb = mix(front.gb, rotate(front.gb, b_angle) * vec2(b_s), b_d);

	float c_d = diff(cyan, front, c_f);
	front.gb = mix(front.gb, rotate(front.gb, c_angle) * vec2(c_s), c_d);

	float m_d = diff(magenta, front, m_f);
	front.gb = mix(front.gb, rotate(front.gb, m_angle) * vec2(m_s), m_d);

	float y_d = diff(yellow, front, y_f);
	front.gb = mix(front.gb, rotate(front.gb, y_angle) * vec2(y_s), y_d);

	float o_d = diff(orange, front, o_f);
	front.gb = mix(front.gb, rotate(front.gb, o_angle) * vec2(o_s), o_d);

	if (! yuv) {
		front = to_rgb(front);
		orig = to_rgb(orig);
	}

	front = mix(orig, front, matte);

	if (matte_out == 1) {
		matte = r_d;
	} else if (matte_out == 2) {
		matte = g_d;
	} else if (matte_out == 3) {
		matte = b_d;
	} else if (matte_out == 4) {
		matte = c_d;
	} else if (matte_out == 5) {
		matte = m_d;
	} else if (matte_out == 6) {
		matte = y_d;
	} else if (matte_out == 7) {
		matte = o_d;
	}


	gl_FragColor = vec4(front, matte);
}
