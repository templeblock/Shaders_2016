#version 120


#define ratio adsk_result_frameratio
#define luma(col) dot(col, vec3(0.2126, 0.7152, 0.0722))
#define PI 3.141592653589793238462643383279502884197969
#define INPUT1 adsk_results_pass1
#define INPUT2 adsk_results_pass2
#define INPUT3 adsk_results_pass3
#define INPUT4 adsk_results_pass4
#define center vec2(.5)

uniform float ratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform sampler2D INPUT1;
uniform sampler2D INPUT2;
uniform sampler2D INPUT3;
uniform sampler2D INPUT4;

uniform float red_scale;
uniform float green_scale;
uniform float blue_scale;
uniform float matte_scale;

uniform float red_rotate;
uniform float green_rotate;
uniform float blue_rotate;
uniform float matte_rotate;

uniform float red_x;
uniform float red_y;
uniform float green_x;
uniform float green_y;
uniform float blue_x;
uniform float blue_y;
uniform float matte_x;
uniform float matte_y;

uniform float matte_hue;
uniform float matte_contrast;
uniform float matte_saturation;

uniform int matte_out;
uniform bool output_matte;
uniform bool chroma_only;

vec2 scale(vec2 coords, float scale_amount)
{
	coords -= center;
	coords.x *= ratio;

	coords /= scale_amount + 1.0;

	coords.x /= ratio;
	coords += center;

	return coords;
}

vec2 rotate(vec2 coords, float rot, bool c)
{
	float r = radians(rot);
  mat2 rm = mat2(
      cos(r), sin(r),
      -sin(r), cos(r)
  );

	if (! c) {
		coords -= center;
		coords.x *= ratio;
	}

  coords *= rm;

	if (! c) {
		coords.x /= ratio;
		coords += center;
	}

  return coords;
}

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

vec2 move(vec2 coords, vec2 movexy)
{
	coords -= movexy;

	return coords;
}

void main(void) {
	vec2 st = gl_FragCoord.xy / res;

	vec2 rst = scale(st, red_scale);
	vec2 gst = scale(st, green_scale);
	vec2 bst = scale(st, blue_scale);
	vec2 mst = scale(st, matte_scale);

	rst = rotate(rst, red_rotate, false);
	gst = rotate(gst, green_rotate, false);
	bst = rotate(bst, blue_rotate, false);
	mst = rotate(mst, matte_rotate, false);

	rst = move(rst, vec2(red_x, red_y));
	gst = move(gst, vec2(green_x, green_y));
	bst = move(bst, vec2(blue_x, blue_y));
	mst = move(mst, vec2(matte_x, matte_y));

	vec3 red = texture2D(INPUT1, rst).rgb;
	vec3 green = texture2D(INPUT2, gst).rgb;
	vec3 blue = texture2D(INPUT3, bst).rgb;
	vec3 matte = texture2D(INPUT4, mst).rgb;

	matte = to_yuv(matte);
	matte.gb = rotate(matte.gb, matte_hue, true);
	if (chroma_only) {
		matte.r = .5;
	}

	matte = to_rgb(matte);

	matte = mix(vec3(.5), matte, matte_contrast / 100 + 100 / 100);
	matte = mix(vec3(luma(matte)), matte, matte_saturation / 100 + 100 / 100);
	matte = clamp(matte, 0.0, 1.0);

	vec3 comp = vec3(0.0);

	comp = mix(comp, red, matte.r);
	comp = mix(comp, green, matte.g);
	comp = mix(comp, blue, matte.b);

	float a = matte.r;

	if (matte_out == 1) {
		a = matte.g;
	} else if (matte_out == 2) {
		a = matte.b;
	}

	if (output_matte) {
		comp = matte;
	}

	gl_FragColor = vec4(comp, a);
}
