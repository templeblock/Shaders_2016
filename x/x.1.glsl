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

uniform int total;
uniform int tris;
uniform float rr;
uniform float size;
uniform int num;
uniform int rows;


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

float get_height(float a, float c)
{
	float b = sqrt( (c * c) - (a * a) );

	return b;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	//int total = 16;

	float col = 0.0;
	float tri = 0.0;

	float Y = .5;

	vec2 left = vec2(.5 - size * .5, Y);
	vec2 right = vec2(.5 + size * .5, Y);
	vec2 top = rotate(left, 5.0 * PI / 3.0, right);

	float height = get_height(size * .5, distance(left, top));

	float y_off = rows - 1;
	left.y += height * y_off;
	top.y +=  height * y_off;
	right.y += height * y_off;

	st.x *= ratio;
	left.x *= ratio;
	right.x *= ratio;
	top.x *= ratio;

	int row = 0;
	int w = 0;
	vec2 cp;
	int in_row = 1;

	for (int i = 0 ; i < total ; i++) {
		vec2 uv = in_tri(st, top, left, right);

		col = min(min(uv.x, uv.y), 1.0 - (uv.x + uv.y));
		col = smoothstep(texel.x, texel.x + .01, col);
		col = clamp(col, 0.0, 1.0);

		col *= 1.0 - i / (total * .95);

		/*
		float circle = .002;
		col += 1.0 - smoothstep(circle, circle + texel.x, distance(st, left));
		col += 1.0 - smoothstep(circle, circle + texel.x, distance(st, right));
		col += 1.0 - smoothstep(circle, circle + texel.x, distance(st, top));
		*/

		tri += col;
		col = 0.0;

		vec2 l = left;
		vec2 t = top;
		vec2 r = right;

		w++;

		if (w == in_row) {
			row++;
			in_row = row * 2 + 1;
			w = 0;
			top.y -= height;
			left.y -= height;
			right.y -= height;

			top.x -= size * ratio * row;
			left.x -= size * ratio * row;
			right.x -= size * ratio * row;

			top.x += size * .5 * ratio;
			left.x += size * .5 * ratio;
			right.x += size * .5 * ratio;
		} else {
			top = right;
			left = t;
			right = vec2(left.x + size * ratio, left.y);
		}
	}

	gl_FragColor = vec4(tri);
}
