#version 120

#define ratio adsk_result_frameratio

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D Front;

uniform float value;
uniform vec2 center;
uniform float width;

vec3 to_rgb(float hue, float saturation)
{
    // https://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV

    float chroma = value * saturation;
    float htmp = hue / 60.0;
    float x = chroma * (1.0 - abs(mod(htmp, 2) -1));

    vec3 rgb = vec3(0.0);

    if (htmp < 1.0) {
        rgb = vec3(chroma, x, 0);
    } else if (htmp < 2.0) {
        rgb = vec3(x, chroma, 0);
    } else if (htmp < 3.0) {
        rgb = vec3(0.0, chroma, x);
    } else if (htmp < 4.0) {
        rgb = vec3(0, x, chroma);
    } else if (htmp < 5.0) {
        rgb = vec3(x, 0., chroma);
    } else if (htmp < 6.0) {
        rgb = vec3(chroma, 0, x);
    }

    float m = value - chroma;
    rgb += vec3(m);

    return rgb;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;
    vec3 front = texture2D(Front, st).rgb;


    vec2 c = center;

    vec2 v = normalize(st - c);
    float angle = atan(v.y, v.x);

    if (angle < 0) {
        angle += 2.0 * 3.14;
    }
    
    // rotate everything cc by 90 degrees to make it more flame centric
    angle -= 3.14 / 2;

    if (angle < 0) {
        angle += 2.0 * 3.14;
    }

    // move the location of the colorwheel
    c.x *= ratio;
    st.x *= ratio;
    float d = distance(c, st);

    float w = (1.0 - width) * 10.0;
    vec3 col = to_rgb(degrees(angle), d * w);

    // anti-alias and then comp the colorwheel
    float aa_mt = clamp((1.0 - d * (w + w * .05)) * (res.x * .1), 0.0, 1.0);

    col = mix(front, col, aa_mt);
    float matte = mix(0.0, 1.0, aa_mt);

    gl_FragColor = vec4(col, matte);
}
