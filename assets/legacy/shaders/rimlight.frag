#pragma header

uniform float angle;
uniform float distance;
uniform vec4 rimlightColor;

uniform vec4 bounds;

void main() {
	vec4 textureColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	
	if (textureColor.a == 0.)
	{
		gl_FragColor = vec4(0.);
	}
	else
	{
		vec2 pixelSize = (1. / openfl_TextureSize);
		
		vec2 distanceScaled = vec2(cos(radians(angle)) * pixelSize.x * distance, sin(radians(angle)) * pixelSize.y * distance);
		vec2 overlapCoord = vec2(openfl_TextureCoordv.x + distanceScaled.x, openfl_TextureCoordv.y - distanceScaled.y);
		
		float overlapAlpha = 0.;
		if (overlapCoord.x >= bounds.x && overlapCoord.x < bounds.z && overlapCoord.y >= bounds.y && overlapCoord.y < bounds.w) overlapAlpha = texture2D(bitmap, overlapCoord).a;
		
		vec4 outColor = mix(rimlightColor * textureColor.a, textureColor, overlapAlpha * rimlightColor.a);
		gl_FragColor = vec4(outColor.rgb * openfl_Alphav, outColor.a * openfl_Alphav);
	}
}
