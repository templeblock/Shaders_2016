#version 120

#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define third .33333333333333333333333333333333
#define INPUT1 Front

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform int rows;
uniform float rr;


vec2 rotate(vec2 point, float r, vec2 c)
{
	mat2 rm = mat2(
		cos(r), -sin(r),
		sin(r), cos(r)
	);

	point -= c;
	point.x *= ratio;
	point *= rm;
	point.x /= ratio;
	point += c;

	return point;
}

vec2 bary(vec2 pos, vec2 top, vec2 left, vec2 right)
{
	vec2 v0 = top - left;
	vec2 v1 = right - left;
	vec2 v2 = pos - left;

	float dot00 = dot(v0, v0);
	float dot01 = dot(v0, v1);
	float dot02 = dot(v0, v2);
	float dot11 = dot(v1, v1);
	float dot12 = dot(v1, v2);

	float id = 1.0 / (dot00 * dot11 - dot01 * dot01);
	float u = (dot11 * dot02 - dot01 * dot12) * id;
	float v = (dot00 * dot12 - dot01 * dot02) * id;

	/* 
		TRIVIA
		uv.x goes from bottom 0.0 to top 1.0
		bottom_edge = uv.x;

		 uv.y goes from left_edge 0.0 to bottom right corner 1.0
		left_edge = uv.y;

		right_edge = 1.0 - (uv.x + uv.y);
	*/

	return vec2(u,v);
}

vec2 in_tri(vec2 p1, vec2 p2, vec2 p3, vec2 p4)
{
	// get the barycentric coords to find boundary of the triangle 
	// point, top, left, right
	vec2 uv = bary(p1, p2, p3, p4);

	if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x + uv.y < 1.0) {
		return uv;
	} else {
		if (uv.x >= 0.0 && uv.y >= 0.0) {
			uv = -uv;
		} else {
			uv = vec2(-1);
		}
		return uv;
	}
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	float col = 0.0;
	float rotation = 2.0 * PI * .33333;

	float size = .1;
	vec2 center = vec2(.5, .5);
	vec2 top = vec2(center.x, center.y + size * .5);
	vec2 left = rotate(top, rotation, center);
	vec2 right = rotate(top, rotation * 2.0, center);

	top = vec2(.5, .5);
	center = vec2(.5) - vec2(0, size);
	left = rotate(top, rotation, center);
	right = rotate(top, rotation * 2.0, center);

	float height = size * 2.0;


	vec2 tl = top;
	vec2 ll = left;
	vec2 rl = right;

	st.y -= rr;;
	col = height;


	for (int i = 0 ; i < rows ; i++) {
		int columns = i + i + 1;


		for (int j = 0 ; j < columns ; j++) {
			vec2 t = top;
			vec2 l = left;
			vec2 r = right;

			if (j == 0 && i == 0) {
				//
			} else if (j == 0 && i > 0) {
				left = rotate(top, PI, left);
				right = rotate(left, rotation * .5, l);
				top = l;
			} else if (mod(j + 1, 2.0) == 0.0) {
				top = right;
				right = t;	
				left = rotate(t, -PI * .33333 , top);
			} else {
				top = left;
				left = t;
				right = rotate(top, -PI * .33333, t);
			}
				
			vec2 uv = in_tri(st, top, left, right);
			col += step(0.0, uv.x + uv.y);
		}

		left = rotate(right, PI, vec2(.5, right.y));
		right = rotate(left, PI, vec2(.5, left.y));
		top = rotate(top, PI, vec2(.5, top.y));
	}



	gl_FragColor = vec4(col);
}
