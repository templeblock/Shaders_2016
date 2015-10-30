#version 120

uniform sampler2D Back, Strength;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main(void)
{
    vec2 st = gl_FragCoord.xy / res;
   	vec3 back = texture2D(Back, st).rgb;
    float strength = texture2D(Strength, st).r;

    gl_FragColor = vec4(back, strength);
}
