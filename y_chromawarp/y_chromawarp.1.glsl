#version 120

uniform sampler2D Front, Matte;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main(void)
{
    vec2 st = gl_FragCoord.xy / res;
   	vec3 front = texture2D(Front, st).rgb;
    float matte = texture2D(Matte, st).r;

    gl_FragColor = vec4(front, matte);
}
