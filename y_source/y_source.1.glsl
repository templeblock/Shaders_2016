#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Back;
uniform sampler2D Matte;
uniform float falloff;

uniform bool front_is_back;
uniform float transparency;

uniform vec3 front_pos;
uniform vec3 front_scale;
uniform float front_rotate;
uniform vec2 front_center;

uniform vec3 matte_pos;
uniform vec3 matte_scale;
uniform float matte_rotate;
uniform vec2 matte_center;

vec2 scale_coords(vec2 coords, vec3 scale, vec2 center)
{
	vec2 scale_val = vec2(scale.x, scale.y) / vec2(100) * vec2(scale.z) / vec2(100);
	coords -= center;
	coords /= scale_val;
	coords += center;

	return coords;
}

vec2 rot_coords(vec2 coords, float rot, vec2 center)
{
	float rotation = radians(rot);
	mat2 rm = mat2( cos(-rotation), -sin(-rotation),
	                sin(-rotation), cos(-rotation) );

	coords -= center;
	coords.x *= ratio;
	coords *= rm;
	coords.x /= ratio;
	coords += center;

	return coords;
}

vec2 trans_coords(vec2 coords, vec3 pos)
{
	coords -= vec2(.5);
	coords -= pos.xy * texel;
	coords += vec2(.5);

	coords = scale_coords(coords, vec3(pos.z) + vec3(100), vec2(.5));

	return coords;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec2 front_coords = st;

	front_coords = scale_coords(front_coords, front_scale, front_center);
	front_coords = rot_coords(front_coords, front_rotate, front_center);
	front_coords = trans_coords(front_coords, front_pos);
	vec3 front = texture2D(Front, front_coords).rgb;

	vec2 matte_coords = st;

	matte_coords = scale_coords(matte_coords, matte_scale, matte_center);
	matte_coords = rot_coords(matte_coords, matte_rotate, matte_center);
	matte_coords = trans_coords(matte_coords, matte_pos);

	vec3 matte = texture2D(Matte, matte_coords).rgb;

	vec3 back = texture2D(Back, st).rgb;

	if (front_is_back) {
		back = texture2D(Front, st).rgb;
	}

	vec3 comp = mix(back, front, matte * ((100 - transparency) / 100.0));

	gl_FragColor = vec4(comp, luma(matte));
}
