#pragma header

uniform float block;

vec4 screenColor = vec4(0., 198. / 255. * .75, 134 / 255. * .75, .75);

float intensity(vec4 color) {
	return max(max(color.r, color.g), color.b);
}

void main() {
	vec2 px = (openfl_TextureSize / block);
	
	vec2 coord = (floor(openfl_TextureCoordv * px) / px);
	
	vec4 color = vec4(1., 1., 1., 0.);
	for (int x = -3; x < 3; x ++)
	{
		for (int y = -3; y < 3; y ++)
		{
			// darkens 6*6 around to get like more "noticeable" outlines. its kinda butt but it wokrs
			vec4 p = texture2D(bitmap, coord + vec2(x / px.x / 6., y / px.y / 6.));
			color.rgb = (color.a == 0 ? p.rgb : mix(color.rgb, min(color.rgb, p.rgb), .05));
			color.a = min(color.a + p.a / pow(5., 2.) * 3., 1.);
		}
	}
	
	color.rgb = max(color.rgb, .1 * color.a);
	color.rg *= .75;
	color.a *= .25;
	
	//float outline = clamp(pow(1. - intensity(color), 5.) * color.a, 0., 1.);
	//color = mix(color, screenColor, outline); these didnt work out .
	//color = (screenColor * outline); well this one almost did u can uncoment if u feel its better
	
	gl_FragColor = color;
}
