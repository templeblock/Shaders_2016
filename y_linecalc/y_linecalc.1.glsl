#version 120

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;

uniform int numlines;
uniform float t_y;
uniform float trans;
uniform float guide_width;
uniform bool show_guide;
uniform bool show_red;

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
	float matte = 0.0;

	float y_coord = gl_FragCoord.y * texel.y;
	float pos_over_center = t_y * texel.y + .5;
	float line_num = numlines * texel.y;

	if (y_coord < pos_over_center + line_num / 2) {
		float guide = step(pos_over_center - line_num / 2, y_coord);
		front = mix(front, max(front, vec3(guide)), 1.0 - trans / 100);
	}

	if (show_red) {
		//find the bottom, make white;
		float alpha = step(pos_over_center - (line_num) / 2, y_coord);
		//find the bottom plus a few pixels, make white
		float edge = step(pos_over_center - (line_num + 2 * texel.y) / 2 , y_coord);
		alpha = mix(edge, 0.0, alpha);

		//repeat for top
		alpha += step(pos_over_center + (line_num + 1 * texel.y) / 2, y_coord);
		edge = step(pos_over_center + (line_num + 3 * texel.y) / 2, y_coord);

		alpha = mix(alpha, 0.0, edge);

		front = mix(front, vec3(1.0, 0.0, 0.0), alpha);
	}

	if (show_guide) {
		if (gl_FragCoord.x < guide_width) {
			front = mix(front, 1.0 - to_rgb(vec3(.5,st.x,st.y)), vec3(1.0 - mod(gl_FragCoord.y, 2.0)));
			front = mix(front, to_rgb(vec3(.5,st.x,st.y)), vec3(mod(gl_FragCoord.y, 2.0)));
		}
	}


	gl_FragColor.rgb = front;
}
