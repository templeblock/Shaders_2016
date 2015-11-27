#version 120

#define ratio adsk_result_frameratio
#define INPUT1 adsk_results_pass4

float adsk_getLuminance( in vec3 color );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;

uniform float chroma_width;

bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
}

vec2 barrelDistortion(vec2 coord, float amt)
{

    vec2 cc = gl_FragCoord.xy/res.xy  - vec2(0.5);
    float distortion = dot(cc * .3, cc);
    return coord + cc * amt * -.05;
}

vec4 offset_color(float amount)
{
    //when times goes past half samples lo is black;
    float lo = step(amount ,0.5);
    float hi = 1.0 - lo;

    float a = 1.0 / 6.0;
    float b = 5.0 / 6.0;

    // times gets closer to samples, x gets brighter, when times == samples, x is clamped to white;
    float x = clamp( (amount - a) / (b - a), 0.0, 1.0 );

    //when x gets brigher, w becomes darker
    float w = clamp(1.0 - abs(2.0 * x - 1.0), 0.0, 1.0);

    // times starts red and as it gets closer to samples it goes orange, green, blue
    vec3 rgb = vec3(lo, 1.0, hi) * vec3(1.0 - w, w, 1.0 - w);

    // if times starts at 0 and goes to 3, the result is, dark, bright, darker dark
    //float lum =  adsk_getLuminance(rgb);
    float lum = adsk_getLuminance(rgb);

    vec4 color = vec4(rgb, lum);

    return color;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;

    vec4 front = texture2D(INPUT1, st);
    vec4 warped = vec4(0.0);
    vec4 total = vec4(0.0);

    float samples = 24.0;
    float sample_norm = 1.0 / samples;

    for (int i = 0; i < samples; i++)
    {
        float amount = float(i) * sample_norm;
        vec4 color = offset_color(amount);

        total += color;

        vec2 coords = st;

        coords = barrelDistortion(coords, chroma_width * amount * front.a);

        /*
        if (isInTex(coords))
        {
            warped += color * texture2D(INPUT1, coords);
        }
        */
        warped += color * texture2D(INPUT1, coords);
    }

    warped /= total;
    warped.a = 1.0 - front.a;

    gl_FragColor = warped;
}
