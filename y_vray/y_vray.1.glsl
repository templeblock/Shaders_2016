#version 120

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D GI;
uniform sampler2D Light;
uniform sampler2D Reflect;
uniform sampler2D Spec;
uniform sampler2D Refr;
uniform sampler2D SelfIllum;
uniform sampler2D Matte;

uniform bool gi_clamp;
uniform bool light_clamp;
uniform bool reflect_clamp;
uniform bool spec_clamp;
uniform bool refr_clamp;
uniform bool self_clamp;

uniform float gi_mix;
uniform float light_mix;
uniform float reflect_mix;
uniform float spec_mix;
uniform float refr_mix;
uniform float self_mix;

uniform float gi_gamma;
uniform float light_gamma;
uniform float reflect_gamma;
uniform float spec_gamma;
uniform float refr_gamma;
uniform float self_gamma;

uniform float gi_gain;
uniform float light_gain;
uniform float reflect_gain;
uniform float spec_gain;
uniform float refr_gain;
uniform float self_gain;

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec3 comp = vec3(0.0);

	vec3 gi = texture2D(GI, st).rgb;
	vec3 light = texture2D(Light, st).rgb;
	vec3 reflect_p = texture2D(Reflect, st).rgb;
	vec3 spec = texture2D(Spec, st).rgb;
	vec3 refr = texture2D(Refr, st).rgb;
	vec3 selfillum = texture2D(SelfIllum, st).rgb;
	float matte = texture2D(Matte, st).r;

	gi = pow(gi, vec3(1.0 / gi_gamma));
	light = pow(light, vec3(1.0 / light_gamma));
	reflect_p = pow(reflect_p, vec3(1.0 / reflect_gamma));
	spec = pow(spec, vec3(1.0 / spec_gamma));
	refr = pow(refr, vec3(1.0 / refr_gamma));
	selfillum = pow(selfillum, vec3(1.0 / self_gamma));

	gi *= gi_gain;
	light *= light_gain;
	reflect_p *= reflect_gain;
	spec *= spec_gain;
	refr *= refr_gain;
	selfillum *= self_gain;

	if (gi_clamp) {
		gi = clamp(gi, 0.0, 1.0);
	}


	if (light_clamp) {
		light = clamp(light, 0.0, 1.0);
	}


	if (reflect_clamp) {
		reflect_p = clamp(reflect_p, 0.0, 1.0);
	}


	if (spec_clamp) {
		spec = clamp(spec, 0.0, 1.0);
	}


	if (refr_clamp) {
		refr = clamp(refr, 0.0, 1.0);
	}


	if (self_clamp) {
		selfillum = clamp(selfillum, 0.0, 1.0);
	}

	comp = mix(comp, gi + comp, gi_mix);
	comp = mix(gi, comp + light, light_mix);
	comp = mix(comp, comp + reflect_p, reflect_mix);
	comp = mix(comp, comp + spec, spec_mix);
	comp = mix(comp, comp + refr, refr_mix);
	comp = mix(comp, comp + selfillum, self_mix);

	gl_FragColor = vec4(comp, matte);
}
