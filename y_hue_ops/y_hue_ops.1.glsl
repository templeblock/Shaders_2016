#version 120

#define ratio adsk_result_frameratio

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

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 front = texture2D(Front, st).rgb;
	float matte = texture2D(Matte, st).r;

	front = to_yuv(front);
	vec3 orig = front;

	vec2 uv = front.gb;
	float u = front.g;
	float v = front.b;

	vec2 red = vec2(-.09985, .61465);
	vec2 green = vec2(-.33594, -.55859);
	vec2 blue = vec2(.43579, -.05637);
	vec2 cyan = vec2(.09985, -.61475);
	vec2 magenta = vec2(.33594, .55859);
	vec2 yellow = vec2(-.43579, .05637);
	vec2 orange = vec2(-.31787, .64307);

	float d_r = 1.0 - distance(uv, red) + (r_f - 1.0);
	d_r = clamp(d_r, 0.0, 1.0);

	float d_g = 1.0 - distance(uv, green) + (g_f - 1.0);
	d_g = clamp(d_g, 0.0, 1.0);

	float d_b = 1.0 - distance(uv, blue) + (b_f - 1.0);
	d_b = clamp(d_b, 0.0, 1.0);

	float d_c = 1.0 - distance(uv, cyan) + (c_f - 1.0);
	d_c = clamp(d_c, 0.0, 1.0);

	float d_m = 1.0 - distance(uv, magenta) + (m_f - 1.0);
	d_m = clamp(d_m, 0.0, 1.0);

	float d_y = 1.0 - distance(uv, yellow) + (y_f - 1.0);
	d_y = clamp(d_y, 0.0, 1.0);

	float d_o = 1.0 - distance(uv, orange) + (o_f - 1.0);
	d_o = clamp(d_o, 0.0, 1.0);

	front.gb = rotate(front.gb, r_angle * d_r);
	front.gb = rotate(front.gb, g_angle * d_g);
	front.gb = rotate(front.gb, b_angle * d_b);
	front.gb = rotate(front.gb, c_angle * d_c);
	front.gb = rotate(front.gb, m_angle * d_m);
	front.gb = rotate(front.gb, y_angle * d_y);
	front.gb = rotate(front.gb, o_angle * d_o);

	front.gb = mix(front.gb, front.gb * vec2(r_s), d_r);
	front.gb = mix(front.gb, front.gb * vec2(g_s), d_g);
	front.gb = mix(front.gb, front.gb * vec2(b_s), d_b);
	front.gb = mix(front.gb, front.gb * vec2(c_s), d_c);
	front.gb = mix(front.gb, front.gb * vec2(m_s), d_m);
	front.gb = mix(front.gb, front.gb * vec2(y_s), d_y);
	front.gb = mix(front.gb, front.gb * vec2(o_s), d_o);

	if (! yuv) {
		front = to_rgb(front);
		orig = to_rgb(orig);
	}

	front = mix(orig, front, matte);

	gl_FragColor = vec4(front, matte);
}
