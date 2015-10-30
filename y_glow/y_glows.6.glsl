#version 120

vec4 adsk_getBlendedValue( int blendType, vec4 srcColor, vec4 dstColor ); 

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3, adsk_results_pass5;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel  = vec2(1.0) / res;

uniform float matte_gain;
uniform bool show_threshold;
uniform float scale_source;
uniform int blend_mode;
uniform float gain;

uniform int i_colorspace;

vec3 adjust_cgamma(vec3 col, float gamma)
{
    if (col.r >= 0.0) {
        col.r = pow(col.r, 1.0 / gamma);
    }

    if (col.g >= 0.0) {
        col.g = pow(col.g, 1.0 / gamma);
    }

    if (col.b >= 0.0) {
        col.b = pow(col.b, 1.0 / gamma);
    }

    return col;
}


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

void main(void)
{
    vec2 st = gl_FragCoord.xy / res;
    vec4 front = texture2D(adsk_results_pass2, st);
    vec4 blur = texture2D(adsk_results_pass5, st);
    float strength = texture2D(adsk_results_pass1, st).a;

    float alpha = clamp(blur.a * (matte_gain + 1.0), 0.0, 1.0);

    vec4 source = front;
    source = mix(vec4(0.0), source, scale_source);
    blur = blur * mix(1.0, gain, strength);

    vec4 comp = front;

    comp = adsk_getBlendedValue(blend_mode, blur, source ); 

    comp = mix(source, comp, alpha * strength);
    comp.a = alpha;

    if (show_threshold) {
        comp = texture2D(adsk_results_pass3, st);
    }

    if (i_colorspace == 0) {
        comp.rgb = to_rec709(comp.rgb);
    } else if (i_colorspace == 1) {
        comp.rgb = to_sRGB(comp.rgb);
    } else if (i_colorspace == 2) {
        //linear
    } else if (i_colorspace == 3) {
        comp.rgb = adjust_cgamma(comp.rgb, 2.2);
    } else if (i_colorspace == 4) {
        comp.rgb = adjust_cgamma(comp.rgb, 1.8);
    }

    gl_FragColor = comp;
}
