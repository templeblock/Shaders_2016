#version 120

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform int edge_width;
uniform float edge_inc;

vec4 get_edge(int i)
{
	vec2 st = gl_FragCoord.xy / res;
	vec4 edge = vec4(0.0);

	mat4 samples[3];

	for (int x = 0; x <= 2; x++) {
		for (int y = 0; y <= 2; y++) {
			samples[x][y] = texture2D(adsk_results_pass1, st + vec2(x - 1, y - 1) * vec2(i) * (texel * edge_inc));
		}
	}

	vec4 horiz = samples[2][0] + samples[1][0]+ samples[0][0] - samples[2][2] - samples[1][2] - samples[0][2];
	vec4 vert = samples[0][2] + samples[0][1] + samples[0][0] - samples[2][2] - samples[2][1] - samples[2][0];

	edge += sqrt(horiz * horiz + vert * vert);

	return edge;
}

void main(void) {
	vec4 edge = vec4(0.0);

	for (int i = 1; i <= edge_width; i++ ) {
		edge += get_edge(i);
	}

	edge /= vec4(edge_width);

	gl_FragColor = edge;
}
