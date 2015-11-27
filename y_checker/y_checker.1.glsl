#version 120

#define ratio adsk_result_frameratio

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;
uniform sampler2D Front;
uniform sampler2D Matte;

uniform float size;
uniform vec3 col1;
uniform vec3 col2;
uniform bool usebg;

uniform int i_colorspace;

vec3 from_sRGB(vec3 col) 
{ 
    if (col.r >= 0.0) { 
        col.r = pow((col.r +.055)/ 1.055, 2.4); 
    } 
 
    if (col.g >= 0.0) { 
        col.g = pow((col.g +.055)/ 1.055, 2.4); 
    } 
 
    if (col.b >= 0.0) { 
        col.b = pow((col.b +.055)/ 1.055, 2.4); 
    } 

    return col;
}

vec3 from_rec709(vec3 col)
{
    if (col.r < .081) {
        col.r /= 4.5;
    } else {
        col.r = pow((col.r +.099)/ 1.099, 1 / .45);
    }

    if (col.g < .081) {
        col.g /= 4.5;
    } else {
        col.g = pow((col.g +.099)/ 1.099, 1 / .45);
    }

    if (col.b < .081) {
        col.b /= 4.5;
    } else {
        col.b = pow((col.b +.099)/ 1.099, 1 / .45);
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


vec3 getRGB( float hue, float sat)
{
    vec3 rgb =  adsk_hsv2rgb( vec3( hue, sat, 1.0 ) );

    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;
    vec3 source = texture2D(Front, st).rgb;
    float matte = texture2D(Matte, st).r;
    float col = 0.0;

    vec2 coords_offset = (gl_FragCoord.xy - vec2(.5)) - res * vec2(.5);

    float x = mod(coords_offset.x + .5 - size * .25,  size);
    float y = mod(coords_offset.y + .5 - size * .25,  size);

    col = step(size / 2.0, x) + step(size / 2.0, y);
    col = abs(1.0 - col);

    vec3 g_offset = getRGB( col1.x / 360.0, col1.z * .01 ) * vec3( col1.y * 0.01);
    vec3 col1 = g_offset;

    vec3 b_offset = getRGB( col2.x / 360.0, col2.z * .01 ) * vec3( col2.y * 0.01);
    vec3 col2 = b_offset;

    if (i_colorspace == 0) {
        col1 = from_rec709(col1);
        col2 = from_rec709(col2);
        source = from_rec709(source);
    } else if (i_colorspace == 1) {
        col1 = from_sRGB(col1);
        col2 = from_sRGB(col2);
        source = from_sRGB(source);
    } else if (i_colorspace == 2) {
        //linear
    } else if (i_colorspace == 3) {
        col1 = adjust_gamma(col1, 2.2);
        col2 = adjust_gamma(col2, 2.2);
        source = adjust_gamma(source, 2.2);
    } else if (i_colorspace == 4) {
        col1 = adjust_gamma(col1, 1.8);
        col2 = adjust_gamma(col2, 1.8);
        source = adjust_gamma(source, 1.8);
    }

    vec3 comp = vec3(1.0);


    if (usebg) {
        comp = mix(col2, col1, col);
    } else {
        comp =mix(source, col1, col);
    }

    comp = mix(source, comp, matte);

    gl_FragColor = vec4(comp, matte);
}
