#version 120

float adsk_getLuminance( in vec3 color );
float adsk_highlights( in float pixel, in float halfPoint ); 
float adsk_shadows( in float pixel, in float halfPoint ); 

uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

uniform float saturation;
uniform vec3 color;
uniform float strength_in;
uniform float gamma;
uniform float shadow_gain;
uniform float highlight_gain;
uniform bool invert_thresh;

vec3 to_yuv(vec3 col)
{
    mat3 yuv = mat3
    (
        .2126, .7152, .0722,
        -.09991, -.33609, .436,
        .615, -.55861, -.05639
    );

    return col * yuv;
}

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


vec3 histo(vec4 front)
{
    vec3 col = front.rgb;

    float mid = .5;

    float lum = adsk_getLuminance(col);
    vec3 shadows = vec3(0.0);
    shadows.r = adsk_shadows(col.r, mid);
    shadows.g = adsk_shadows(col.g, mid);
    shadows.b = adsk_shadows(col.b, mid);

    vec3 highlights = vec3(1.0);
    highlights.r = adsk_highlights(col.r, mid);
    highlights.g = adsk_highlights(col.g, mid);
    highlights.b = adsk_highlights(col.b, mid);

    shadows *= shadow_gain + 1.0;
    highlights *= highlight_gain;


    shadows *= col;
    highlights *= col;

    vec3 comp = highlights + shadows;

    return comp;
}

void main(void)
{
    vec2 st = gl_FragCoord.xy / res;
    vec4 front = texture2D(adsk_results_pass2, st);
    float strength = texture2D(adsk_results_pass1, st).a;

    vec4 col = front;

    vec3 comp = histo(col);
    float lum = adsk_getLuminance(comp);

    comp = pow(comp, vec3(1.0 / gamma));

    comp = to_yuv(comp);

    comp.gb *= saturation;
    if (invert_thresh) {
        comp.r = 1.0 - comp.r;
    }

    comp = to_rgb(comp);

    comp *= color;

    col = clamp(col, 0.0, 10.0);

    gl_FragColor = vec4(comp, front.a);
}
