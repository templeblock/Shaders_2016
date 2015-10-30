#version 120

#define ratio adsk_result_frameratio

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

uniform sampler2D adsk_results_pass1;
uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform int i_colorspace;

vec3 to_rec709(vec3 col)
{
    if (col.r < .018) {
        col.r *= 4.5;
    } else if (col.r >= 0.0) {
        col.r = (1.099 * pow(col.r, .45)) - .099;
    }

    if (col.g < .018) {
        col.g *= 4.5;
    } else if (col.g >= 0.0) {
        col.g = (1.099 * pow(col.g, .45)) - .099;
    }

    if (col.b < .018) {
        col.b *= 4.5;
    } else if (col.b >= 0.0) {
        col.b = (1.099 * pow(col.b, .45)) - .099;
    }


    return col;
}

vec3 to_sRGB(vec3 col)
{
    if (col.r >= 0.0) {
        col.r = (1.055 * pow(col.r, 1.0 / 2.4)) - .055;
    }

    if (col.g >= 0.0) {
        col.g = (1.055 * pow(col.g, 1.0 / 2.4)) - .055;
    }

    if (col.b >= 0.0) {
        col.b = (1.055 * pow(col.b, 1.0 / 2.4)) - .055;
    }

    return col;
}

vec3 adjust_gamma(vec3 col, float gamma)
{
    col.r = pow(col.r, gamma);
    col.g = pow(col.g, gamma);
    col.b = pow(col.b, gamma);

    return col;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;
    vec4 checker = texture2D(adsk_results_pass1, st);

    vec3 comp = checker.rgb;
    float col = checker.a;

    if (i_colorspace == 0) {
        comp = to_rec709(comp);
    } else if (i_colorspace == 1) {
        comp = to_sRGB(comp);
    } else if (i_colorspace == 2) {
        //linear
    } else if (i_colorspace == 3) {
        comp = adjust_gamma(comp, 1.0 / 2.2);
    } else if (i_colorspace == 4) {
        comp = adjust_gamma(comp, 1.0 / 1.8);
    }

    //comp = clamp(comp, 0.0, 1.0);

    gl_FragColor = vec4(comp, col);
}
