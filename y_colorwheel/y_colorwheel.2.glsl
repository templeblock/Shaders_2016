#version 120

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D adsk_results_pass1;
uniform vec2 picker;
uniform bool output_color;
uniform vec2 center;
uniform float width;
uniform bool show_ring;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(adsk_results_pass1, st);

	vec2 c = center;

	c.x *= ratio;
	st.x *= ratio;

	float d = distance(c, st);

	st.x /= ratio;

	vec3 col = texture2D(adsk_results_pass1, picker).rgb;

	float w = (1.0 - width) * 10.0;

	float aa_mt = clamp((1.0 - d * (w - w * .05)) * (res.x * .1), 0.0, 1.0);
	float aa_mt2 = clamp((1.0 - d * (w + w * .05)) * (res.x * .1), 0.0, 1.0);

	if (! output_color) {
		if (show_ring) {
			col = mix(front.rgb, col, aa_mt);
			col = mix(col, front.rgb, aa_mt2);
		} else {
			col = front.rgb;
		}
	}

	gl_FragColor = vec4(col, front.a); 
}
