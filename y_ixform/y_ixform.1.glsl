#version 120

uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;
uniform sampler2D Matte;
uniform sampler2D Strength;

uniform float pos_x, pos_y;
uniform float scale, scale_x, scale_y;
uniform float rot;
uniform float skew_x, skew_y;

uniform float trans;

uniform bool repeat_texture;
uniform bool warped_only;

//const vec2 center = vec2(.5);

uniform vec2 center;

bool isInTex( const vec2 coords )
{
	    return coords.x >= 0.0 && coords.x <= 1.0 &&
		            coords.y >= 0.0 && coords.y <= 1.0;
}


vec2 pre(vec2 coords)
{
	coords -= center;
	coords.x *= adsk_result_frameratio;

	return coords;
}

vec2 post(vec2 coords)
{
	coords.x /= adsk_result_frameratio;
	coords += center;

	return coords;
}

vec2 rotate_coords(vec2 coords, float rot)
{
	mat2 rm = mat2(
		cos(rot), sin(rot),
		-sin(rot), cos(rot)
	);

	coords = pre(coords);
	coords *= rm;
	coords = post(coords);

	return coords;
}

vec2 scale_coords(vec2 coords, vec2 scale_val)
{
	coords = pre(coords);
	coords /= scale_val + vec2(1.0);
	coords = post(coords);

	return coords;
}

vec2 skew_coords(vec2 coords, vec2 skew_val)
{
	mat2 sm = mat2(
		1.0, skew_val.x,
		skew_val.y, 1.0
	);

	coords *= sm;

	return coords;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 back = texture2D(Front, st).rgb;

	float strength = texture2D(Strength, st).r;

	vec2 fcoords = st;

	vec2 s = vec2(strength);

	fcoords = scale_coords(fcoords, vec2(scale) * vec2(scale_x, scale_y) * s);
	fcoords = skew_coords(fcoords, vec2(skew_x, skew_y) * s);
	fcoords = fcoords - vec2(pos_x, pos_y) * s;
	fcoords = rotate_coords(fcoords, rot * strength);

	vec3 front = texture2D(Front, fcoords).rgb;
	float matte = texture2D(Matte, fcoords).r;

/*
	if (isInTex(fcoords)) {
		front = texture2D(Front, fcoords).rgb;
	} else {
		fcoords = 1.0 - fcoords;
		front = texture2D(Front, fcoords).rgb;
	}
	*/

	if (! repeat_texture && ! isInTex(fcoords)) {
		front = vec3(0.0);
		matte = 0.0;
	}

	float alpha = mix(matte, 0.0, trans);

	vec3 comp = mix(back, front, alpha);
	if (warped_only) {
		comp = front * vec3(alpha) * vec3(strength);
	}

	gl_FragColor = vec4(comp, alpha);
}
