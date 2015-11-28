#version 120

#define ratio adsk_result_frameratio
#define PI 3.141592653589793238462643383279502884197969

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;

vec2 center = vec2(.5);
uniform float gamma;
uniform bool mirror;
uniform int num_circles;
uniform float circle_width;
uniform float radius;
uniform float grad_rotation;
uniform int samples;
uniform float t;
uniform bool invert;

vec2 rotate_coords(vec2 coords, float ra)
{
    mat2 r = mat2( cos(-ra), -sin(-ra),
                   sin(-ra), cos(-ra) );

	coords -= vec2(.5);
	coords.x *= ratio;
	coords *= r;
	coords.x /= ratio;
	coords += vec2(.5);

    return coords;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	//vec3 front = texture2D(Front, st).rgb;

	vec2 p1 = vec2(1.0, .5);

	if (mirror) {
		p1 = rotate_coords(p1, radians(grad_rotation));
	}

	vec2 v1 = normalize(p1 - center);
	vec2 v2 = normalize(st - center);

	float angle = acos(dot(v1, v2));

	if (mirror) {
		angle *= 2.0;
	} else if (st.y < .5) {
		angle = 2 * PI - angle;
	}

	if (! mirror) {
		float w = 0.0;
		angle += radians(grad_rotation);
		angle = mod(angle, 2 * PI);
		float tmp_angle = angle;

		for (float i = 0; i < samples; i+=.25) {
			float tmp = angle + radians(i);	
			tmp = mod(tmp, 2 * PI);
			tmp_angle += tmp;
			w++;
		}

		tmp_angle /= w;
		angle = tmp_angle;
	}


	float angle_grad = angle / (2 * PI);
	if (invert) {
		angle_grad = 1.0 - angle_grad;
	}

	angle_grad = pow(angle_grad, 1.0 / gamma);
	angle_grad = pow(angle_grad, 1.0 / max(max(1.0 - t, angle_grad), .00001));
	angle_grad = clamp(angle_grad, 0.0, 1.0);
	
	float circle = 1.0;
	vec2 circle_coords = vec2(.5 + radius, .5);

	for (int i = 1; i <= num_circles; i++) {		
		circle_coords = rotate_coords(circle_coords, 2 * PI / num_circles);

		circle_coords.x *= ratio;
		st.x *= ratio;
		//float d = 1.0 - distance(circle_coords, st);
		float d = distance(circle_coords, st);
		circle_coords.x /= ratio;
		st.x /= ratio;
	
		circle *= smoothstep(circle_width * texel.x - texel.x * 10, circle_width * texel.x,   d);
	}

	circle = 1.0 - clamp(circle, 0.0, 1.0);

	float c = circle;
	c *= angle_grad;

	float matte = angle_grad;


	gl_FragColor= vec4(vec3(c), matte);
}
