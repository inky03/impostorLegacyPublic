package funkin.game.shaders;

/**
 * Based on FNF's `DropShadowShader`, with more features and support for multiple lighting layers!
 * This shader is used for more complex shading effects (ex. skins on Lights Down, Reactor, Defeat, etc).
 * 
 * A 4 x 5 color matrix (refer to OpenFL's [ColorMatrixFilter](https://api.openfl.org/openfl/filters/ColorMatrixFilter.html) for reference)
 * is used to transform color for shading and lighting layers, which allows to do, for example, saturation changes and hue rotation!
 * 
 * You can mess with color matrix here: https://kazzkiq.github.io/svg-color-filter/. Note offsets (the last row of the matrix) must be multiplied by 255 when working with this shader.
*/
@:access(animate.internal.filters.AdjustColorFilter)
class ExtraDropShadowShader extends flixel.system.FlxAssets.FlxShader
{
	/**
	 * Whether anti-aliasing should be applied or not, used to smooth out any hard edges the brightness thresholding creates, regardless of `roughness`.
	 * Defaults to true, but won't do any effect until changing `antialiasStages`.
	 */
	public var antialiasing(get, set):Bool;
	/**
	 * The amount of anti-alias samples per-pixel.
	 * Defaults to 0, which removes any smoothing.
	 */
	public var antialiasStages(get, set):Float;
	
	/**
	 * The mode to apply on the color transforms of every layer.
	 */
	public var operation(default, set):LayerOperation = REPLACE;
	/**
	 * The color matrix to apply on all colors outside of the brightness `threshold`, which can be modified to apply effects on stuff such as outlines.
	 */
	public var hollowColorMatrix(get, set):Array<Float>;
	/**
	 * The initial color matrix to apply on all colors within the brightness `threshold`, used for shading.
	 */
	public var colorMatrix(get, set):Array<Float>;
	/**
	 * An array with all lighting layers being applied to this drop shadow effect.
	 * A maximum of 6 layers can be used at a time.
	 */
	public var layers:Array<ExtraDropShadowLayer>;
	/**
	 * The mode to use to measure color against this drop shadow's threshold.
	 */
	public var thresholdMode(get, set):ThreshMode;
	/**
	 * The brightness threshold for `colorMatrix` to be applied instead of `hollowColorMatrix`.
	 * Defaults to 0, which always applies the `colorMatrix`.
	 * 
	 * This threshold isn't exact and may be additionally controlled with `roughness`.
	 */
	public var threshold(get, set):Float;
	/**
	 * Controls the roughness of the brightness threshold, used to smooth out any hard edges the brightness thresholding creates.
	 * Defaults to 1, but can be increased to make the threshold transition sharper.
	 */
	public var roughness(get, set):Float;
	/**
	 * How much of this drop shadow effect's `colorMatrix` can get applied at maximum.
	 */
	public var strength(get, set):Float;
	
	/**
	 * The sprite this drop shadow effect is attached to.
	 * Note that setting this will automatically set the respective sprite's shader.
	 */
	public var attachedSprite(default, set):FlxSprite = null;
	var __attachedSpriteHook:String -> Int -> Int -> Void;
	
	/**
	 * The number of lighting layers that are currently active in this drop shadow effect.
	 */
	public var activeLayers(get, never):Int;
	
	/**
	 * Copies another drop shadow effect into this drop shadow effect.
	 * 
	 * @param	from	The drop shadow effect to copy from.
	 * @return	This `ExtraDropShadowShader` instance (useful for chaining)
	 */
	public function copyFrom(from:ExtraDropShadowShader):ExtraDropShadowShader
	{
		for (i => layer in layers) layer.copyFrom(from.layers[i]);
		
		antialiasStages = from.antialiasStages;
		thresholdMode = from.thresholdMode;
		threshold = from.threshold;
		operation = from.operation;
		roughness = from.roughness;
		strength = from.strength;
		
		for (i in 0 ... 16)
		{
			shadowMultipliers.value[i] = from.shadowMultipliers.value[i];
			hollowMultipliers.value[i] = from.hollowMultipliers.value[i];
		}
		for (i in 0 ... 4)
		{
			shadowOffsets.value[i] = from.shadowOffsets.value[i];
			hollowOffsets.value[i] = from.hollowOffsets.value[i];
		}
		
		return this;
	}
	/**
	 * Sets this drop shadow effect's `colorMatrix`.
	 * 
	 * @param	matrix	The color matrix.
	 * @return	This `ExtraDropShadowShader` instance (useful for chaining)
	 */
	public function setColorMatrix(matrix:Array<Float>):ExtraDropShadowShader
	{
		colorMatrix = matrix;
		
		return this;
	}
	/**
	 * Sets this drop shadow effect's `colorMatrix` by Adobe Animate/Flash's Adjust Color calculation.
	 * 
	 * @param	brightness	The Adjust Color brightness.
	 * @param	hue			The Adjust Color hue.
	 * @param	contrast	The Adjust Color contrast.
	 * @param	saturation	The Adjust Color saturation.
	 * @return	This `ExtraDropShadowShader` instance (useful for chaining)
	 */
	public function setAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowShader
	{
		return setColorMatrix(animate.internal.filters.AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	/**
	 * Sets this drop shadow effect's `hollowColorMatrix`.
	 * 
	 * @param	matrix	The color matrix.
	 * @return	This `ExtraDropShadowShader` instance (useful for chaining)
	 */
	public function setHollowColorMatrix(matrix:Array<Float>):ExtraDropShadowShader
	{
		hollowColorMatrix = matrix;
		
		return this;
	}
	/**
	 * Sets this drop shadow effect's `hollowColorMatrix` by Adobe Animate/Flash's Adjust Color calculation.
	 * 
	 * @param	brightness	The Adjust Color brightness.
	 * @param	hue			The Adjust Color hue.
	 * @param	contrast	The Adjust Color contrast.
	 * @param	saturation	The Adjust Color saturation.
	 * @return	This `ExtraDropShadowShader` instance (useful for chaining)
	 */
	public function setHollowAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowShader
	{
		return setHollowColorMatrix(animate.internal.filters.AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	
	/**
	 * Adds a new layer to this drop shadow effect.
	 * If the drop shadow effect already reached the maximum amount of layers `null` will be returned.
	 * 
	 * @param	colorMatrix	The color matrix to use for the layer.
	 * @param	angle		The angle to use for the layer.
	 * @param	distance	The distance to use for the layer.
	 * @param	threshold	The threshold to use for the layer.
	 * @param	strength	The strength to use for the layer.
	 * @param	roughness	The threshold roughness to use for the layer.
	 * @return	The new `ExtraDropShadowLayer` that was added (useful for chaining)
	 */
	public function addLayer(colorMatrix:Array<Float>, angle:Float = 0, distance:Float = 20, threshold:Float = .01, strength:Float = 1, roughness:Float = 1):ExtraDropShadowLayer
	{
		var rimlight:ExtraDropShadowLayer = getFreeLayer();
		
		if (rimlight == null)
		{
			trace('we outta rimlight\'s');
			return null;
		}
		
		return rimlight.setColorMatrix(colorMatrix).setAttributes(angle, distance, threshold, strength, roughness);
	}
	
	/**
	 * Updates the drop shadow shader's frame information (used internally)
	 */
	public function updateFrameInfo(frame:Null<flixel.graphics.frames.FlxFrame>):Void
	{
		if (frame == null) return;
		
		frameBounds.value[0] = frame.uv.left;
		frameBounds.value[1] = frame.uv.top;
		frameBounds.value[2] = frame.uv.right;
		frameBounds.value[3] = frame.uv.bottom;
		angOffset.value[0] = (frame.angle * flixel.math.FlxAngle.TO_RAD);
	}
	
	function getFreeLayer():Null<ExtraDropShadowLayer>
	{
		for (rimlight in layers)
		{
			if (!rimlight.active) return rimlight;
		}
		
		return null;
	}
	
	function set_attachedSprite(sprite:FlxSprite):FlxSprite
	{
		if (attachedSprite != null)
		{
			if (attachedSprite.shader == this) attachedSprite.shader = null;
			
			attachedSprite.animation.onFrameChange.remove(__attachedSpriteHook);
		}
		
		attachedSprite = sprite;
		
		if (sprite != null)
		{
			sprite.animation.onFrameChange.add(__attachedSpriteHook);
			
			updateFrameInfo(sprite.frame);
			
			sprite.shader = this;
		}
		
		return sprite;
	}
	
	function set_operation(op:LayerOperation):LayerOperation
	{
		stack.value = [op == STACK];
		
		return operation = op;
	}
	
	@:glFragmentSource('
		#pragma header
		
		// cant set uniofrm arrays in openfl so i guess i just have to deal with this SUTPID shit
		uniform mat4 rimlightMultipliers0; uniform mat4 rimlightMultipliers1; uniform mat4 rimlightMultipliers2;
		uniform mat4 rimlightMultipliers3; uniform mat4 rimlightMultipliers4; uniform mat4 rimlightMultipliers5;
		
		uniform vec4 rimlightOffsets0; uniform vec4 rimlightOffsets1; uniform vec4 rimlightOffsets2;
		uniform vec4 rimlightOffsets3; uniform vec4 rimlightOffsets4; uniform vec4 rimlightOffsets5;
		
		uniform mat3 rimlightData0; uniform mat3 rimlightData1; uniform mat3 rimlightData2;
		uniform mat3 rimlightData3; uniform mat3 rimlightData4; uniform mat3 rimlightData5;
		/*
		[
		angle, 		distance, 	threshold,
		strength, 	roughness, 	idk
		idk, 		idk, 		idk
		]
		
		cant qwait for this to bite me in the butt
		*/
		
		uniform bool aa;
		uniform float aaStages;
		uniform vec2 scale;
		
		uniform float uThreshold;
		uniform float uRoughness;
		uniform float uShadowStrength;
		uniform int uThreshMode;
		uniform bool stack;
		
		uniform mat4 hollowMultipliers;
		uniform vec4 hollowOffsets;
		
		uniform mat4 shadowMultipliers;
		uniform vec4 shadowOffsets;
		
		uniform float angOffset;
		uniform vec4 frameBounds;
		
		float intensity(vec4 color) {
			return (uThreshMode == 0 ? dot(color.rgb, vec3(.2126, .7152, .0722)) : max(max(color.r, color.g), color.b));
		}
		
		float cutoff(vec4 color, float thresh, float roughness) {
			if (thresh <= 0.) return 1.;
			
			return clamp((intensity(color) - thresh) * (1. - thresh) * 4. * roughness, 0., 1.);
		}
		
		vec2 hash22(vec2 p) {
			vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
			p3 += dot(p3, p3.yzx + 33.33);
			return fract((p3.xx + p3.yz) * p3.zy);
		}
		
		float antialias(vec2 coord, float thresh, float roughness) { // form the fnf shader
			if (aaStages == 0. || !aa) return cutoff(texture2D(bitmap, coord), thresh, roughness);
			
			const int MAX_AA = 8;

			float AA_TOTAL_PASSES = (aaStages * aaStages + 1.);
			const float AA_JITTER = .5;
			
			float intensity = cutoff(texture2D(bitmap, coord), thresh, roughness);
			for (int i = 0; i < MAX_AA * MAX_AA; i++) {
				int x = (i / MAX_AA);
				int y = (i - (MAX_AA * int(i/MAX_AA)));
				
				if (float(x) >= aaStages || float(y) >= aaStages) continue;
				
				vec2 offset = (AA_JITTER * (2. * hash22(vec2(float(x), float(y))) - 1.) / openfl_TextureSize);
				intensity += cutoff(texture2D(bitmap, coord + offset), thresh, roughness);
			}
			
			return (intensity / AA_TOTAL_PASSES);
		}
		
		float getLayerIntensity(vec4 color, mat3 data) {
			float strength = data[1].x;
			
			if (strength <= 0.) return 0.;
			
			float angle = data[0].x;
			float dist = data[0].y;
			
			vec2 coord = vec2(
				openfl_TextureCoordv.x + dist * cos(angle + angOffset) / scale.x / openfl_TextureSize.x,
				openfl_TextureCoordv.y - dist * sin(angle + angOffset) / scale.y / openfl_TextureSize.y
			);
			
			if (!aa) coord = (floor(coord * openfl_TextureSize) / openfl_TextureSize);
			
			float rimIntensity = (1. - texture2D(bitmap, coord).a);
			if (frameBounds.z > 0 && (coord.x < frameBounds.x || coord.y < frameBounds.y || coord.x >= frameBounds.z || coord.y >= frameBounds.w)) rimIntensity = 1.;
			
			return (rimIntensity * strength * antialias(openfl_TextureCoordv, data[0].z, data[1].y));
		}
		
		vec4 applyLayer(vec4 tintedColor, vec4 baseColor, mat4 multipliers, vec4 offsets, float intensity) {
			if (intensity <= 0.) return tintedColor;
			
			return mix(tintedColor, clamp((stack ? tintedColor : baseColor) * multipliers + offsets, 0., 1.), intensity);
		}
		
		void main() {
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			
			if (color.a == 0.) {
				gl_FragColor = vec4(0.);
			} else {
				if (color.a > 0.) color.rgb /= color.a;
				
				if (openfl_HasColorTransform || hasColorTransform) color = clamp(color * vec4(openfl_ColorMultiplierv.rgb, 1.) + openfl_ColorOffsetv, 0., 1.);
				
				vec4 tinted = clamp(color * hollowMultipliers + hollowOffsets, 0., 1.);
				tinted = applyLayer(tinted, color, shadowMultipliers, shadowOffsets, antialias(openfl_TextureCoordv, uThreshold, uRoughness * 4.) * uShadowStrength);
				
				tinted = applyLayer(tinted, color, rimlightMultipliers5, rimlightOffsets5, getLayerIntensity(color, rimlightData5));
				tinted = applyLayer(tinted, color, rimlightMultipliers4, rimlightOffsets4, getLayerIntensity(color, rimlightData4));
				tinted = applyLayer(tinted, color, rimlightMultipliers3, rimlightOffsets3, getLayerIntensity(color, rimlightData3));
				tinted = applyLayer(tinted, color, rimlightMultipliers2, rimlightOffsets2, getLayerIntensity(color, rimlightData2));
				tinted = applyLayer(tinted, color, rimlightMultipliers1, rimlightOffsets1, getLayerIntensity(color, rimlightData1));
				tinted = applyLayer(tinted, color, rimlightMultipliers0, rimlightOffsets0, getLayerIntensity(color, rimlightData0));
				
				gl_FragColor = vec4(tinted.rgb * tinted.a, tinted.a);
				if (hasTransform) gl_FragColor *= openfl_Alphav;
			}
		}
		
		// written by emi3
	')
	
	/**
	 * Creates a new `ExtraDropShadowShader`.
	 */
	public function new()
	{
		super();
		
		__attachedSpriteHook = function(_, _, _)
		{
			if (attachedSprite == null) return;
			
			antialiasing = attachedSprite.antialiasing;
			scale.value[0] = attachedSprite.scale.x;
			scale.value[1] = attachedSprite.scale.y;
			
			if (attachedSprite is animate.FlxAnimate && cast(attachedSprite, animate.FlxAnimate).isAnimate) {
				for (i in 0 ... 4) frameBounds.value[i] = 0;
				
				return;
			}
			
			updateFrameInfo(attachedSprite.frame);
		}
		
		angOffset.value = [0];
		frameBounds.value = [0, 0, 0, 0];
		shadowMultipliers.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		shadowOffsets.value = [0, 0, 0, 0];
		hollowMultipliers.value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		hollowOffsets.value = [0, 0, 0, 0];
		uShadowStrength.value = [1];
		uThreshMode.value = [1];
		uThreshold.value = [0];
		uRoughness.value = [1];
		scale.value = [1, 1];
		aaStages.value = [0];
		aa.value = [true];
		
		layers = [
			for (id in 0 ... 6) {
				new ExtraDropShadowLayer(
					Reflect.field(this, 'rimlightMultipliers$id').value = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
					Reflect.field(this, 'rimlightOffsets$id').value = [0, 0, 0, 0],
					Reflect.field(this, 'rimlightData$id').value = [0, 0, 0, -1, 1, 0, 0, 0, 0]
				);
			}
		];
		
		operation = REPLACE;
	}
	
	inline function get_colorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? shadowOffsets.value[Math.floor(i / 5)] : shadowMultipliers.value[i - Math.floor(i / 5)])];
	}
	inline function set_colorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) shadowMultipliers.value[i] = matrix[i + Math.floor(i / 4)];
		for (i in 0 ... 4) shadowOffsets.value[i] = (matrix[i * 5 + 4] / 255);
		
		return matrix;
	}
	
	inline function get_hollowColorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? hollowOffsets.value[Math.floor(i / 5)] : hollowMultipliers.value[i - Math.floor(i / 5)])];
	}
	inline function set_hollowColorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) hollowMultipliers.value[i] = matrix[i + Math.floor(i / 4)];
		for (i in 0 ... 4) hollowOffsets.value[i] = (matrix[i * 5 + 4] / 255);
		
		return matrix;
	}
	
	inline function get_activeLayers():Int
	{
		var i:Int = 0;
		for (rimlight in layers) if (rimlight.active) i ++;
		
		return i;
	}
	
	inline function get_antialiasing():Bool return aa.value[0];
	inline function set_antialiasing(v:Bool):Bool return aa.value[0] = v;
	
	inline function get_antialiasStages():Float return aaStages.value[0];
	inline function set_antialiasStages(v:Float):Float return aaStages.value[0] = v;
	
	inline function get_roughness():Float return uRoughness.value[0];
	inline function set_roughness(v:Float):Float return uRoughness.value[0] = v;
	
	inline function get_threshold():Float return uThreshold.value[0];
	inline function set_threshold(v:Float):Float return uThreshold.value[0] = v;
	
	inline function get_strength():Float return uShadowStrength.value[0];
	inline function set_strength(v:Float):Float return uShadowStrength.value[0] = v;
	
	inline function get_thresholdMode():ThreshMode return (uThreshMode.value[0] == 0 ? LUMINANCE : VALUE);
	inline function set_thresholdMode(v:ThreshMode):ThreshMode
	{
		uThreshMode.value[0] = (v == VALUE ? 1 : 0);
		
		return v;
	}
}

// puppy 's first private class >w<Ok sorry
/**
 * Represents a lighting layer in the `ExtraDropShadowShader`
 */
@:access(animate.internal.filters.AdjustColorFilter)
private class ExtraDropShadowLayer
{
	/**
	 * Whether this lighting layer is active or not.
	 */
	public var active(get, set):Bool;
	
	/**
	 * This lighting layer's angle.
	 */
	public var angle(get, set):Float;
	/**
	 * This lighting layer's distance.
	 */
	public var distance(get, set):Float;
	/**
	 * This lighting layer's brightness threshold, which can be adjusted to make lighting not leak into outlines.
	 * This threshold isn't exact and may be additionally controlled with `roughness`.
	 */
	public var threshold(get, set):Float;
	/**
	 * Controls the roughness of the brightness threshold, used to smooth out any hard edges the brightness thresholding creates.
	 * Defaults to 1, but can be increased to make the threshold transition sharper.
	 */
	public var roughness(get, set):Float;
	/**
	 * How much of this lighting layer's `colorMatrix` can get applied at maximum.
	 */
	public var strength(get, set):Float;
	
	/**
	 * This lighting layer's color matrix.
	 */
	public var colorMatrix(get, set):Array<Float>;
	/**
	 * This lighting layer's color multipliers.
	 */
	public var multipliers:Array<Float>;
	/**
	 * This lighting layer's color offsets.
	 */
	public var offsets:Array<Float>;
	var data:Array<Float>;
	
	/**
	 * Creates a new `ExtraDropShadowShader`
	 */
	public function new(multipliers:Array<Float>, offsets:Array<Float>, data:Array<Float>)
	{
		this.multipliers = multipliers;
		this.offsets = offsets;
		this.data = data;
	}
	
	/**
	 * Copies another lighting layer into this lighting layer.
	 * 
	 * @param	from	The lighting layer to copy from.
	 * @return	This `ExtraDropShadowLayer` instance (useful for chaining)
	 */
	public function copyFrom(from:ExtraDropShadowLayer):ExtraDropShadowLayer
	{
		for (i in 0 ... 16) multipliers[i] = from.multipliers[i];
		for (i in 0 ... 4) offsets[i] = from.offsets[i];
		
		return setAttributes(from.angle, from.distance, from.threshold, from.strength, from.roughness);
	}
	/**
	 * Sets this lighting layer's attributes.
	 * 
	 * @param	colorMatrix	The color matrix to use.
	 * @param	angle		The angle to use.
	 * @param	distance	The distance to use.
	 * @param	threshold	The threshold to use.
	 * @param	strength	The strength to use.
	 * @param	roughness	The threshold roughness to use.
	 * @return	This `ExtraDropShadowLayer` instance (useful for chaining)
	 */
	public inline function setAttributes(angle:Float = 0, distance:Float = 20, threshold:Float = .01, strength:Float = 1, roughness:Float = 1):ExtraDropShadowLayer
	{
		this.angle = angle;
		this.distance = distance;
		this.threshold = threshold;
		this.strength = strength;
		this.roughness = roughness;
		
		return this;
	}
	/**
	 * Sets this lighting layer's `colorMatrix`.
	 * 
	 * @param	matrix	The color matrix.
	 * @return	This `ExtraDropShadowLayer` instance (useful for chaining)
	 */
	public function setColorMatrix(matrix:Array<Float>):ExtraDropShadowLayer
	{
		colorMatrix = matrix;
		
		return this;
	}
	/**
	 * Sets this lighting layer's `colorMatrix` by Adobe Animate/Flash's Adjust Color calculation.
	 * 
	 * @param	brightness	The Adjust Color brightness.
	 * @param	hue			The Adjust Color hue.
	 * @param	contrast	The Adjust Color contrast.
	 * @param	saturation	The Adjust Color saturation.
	 * @return	This `ExtraDropShadowLayer` instance (useful for chaining)
	 */
	public function setAdjustColor(brightness:Float = 0, hue:Float = 0, contrast:Float = 0, saturation:Float = 0):ExtraDropShadowLayer
	{
		return setColorMatrix(animate.internal.filters.AdjustColorFilter.getColorMatrix(brightness, hue, contrast, saturation));
	}
	
	inline function get_active():Bool return (strength > 0);
	inline function set_active(active:Bool):Bool
	{
		strength = (active ? Math.abs(strength) : -Math.abs(strength));
		return active;
	}
	
	inline function get_angle():Float return (data[0] * flixel.math.FlxAngle.TO_DEG);
	inline function set_angle(v:Float):Float return data[0] = (v * flixel.math.FlxAngle.TO_RAD);
	
	inline function get_distance():Float return data[1];
	inline function set_distance(v:Float):Float return data[1] = v;
	
	inline function get_threshold():Float return data[2];
	inline function set_threshold(v:Float):Float return data[2] = v;
	
	inline function get_strength():Float return data[3];
	inline function set_strength(v:Float):Float return data[3] = v;
	
	inline function get_roughness():Float return data[4];
	inline function set_roughness(v:Float):Float return data[4] = v;
	
	inline function get_colorMatrix():Array<Float>
	{
		return [for (i in 0 ... 20) (i % 5 == 4 ? (offsets[Math.floor(i / 5)] * 255) : multipliers[i - Math.floor(i / 5)])];
	}
	inline function set_colorMatrix(matrix:Array<Float>):Array<Float>
	{
		for (i in 0 ... 16) multipliers[i] = (matrix[i + Math.floor(i / 4)] ?? 0);
		for (i in 0 ... 4) offsets[i] = ((matrix[i * 5 + 4] ?? 0) / 255);
		
		return matrix;
	}
}

/**
 * The mode to use when applying color on every layer of the extra drop shadow
 */
enum abstract LayerOperation(String) to String
{
	/**
	 * Performs the color transform on the original texture's color, essentially overwriting the color from the last layer
	 */
	var OVERWRITE = 'replace';
	/**
	 * Same as `OVERWRITE`
	 */
	var REPLACE = 'replace';
	
	/**
	 * Performs the color transform on the last layer's color, essentially stacking color transformations
	 */
	var STACK = 'stack';
}

/**
 * The mode to use to measure color against the extra drop shadow threshold
 */
enum abstract ThreshMode(String) to String
{
	/**
	 * Uses luminance (perceived color brightness).
	 * Might be more viable for smoothing
	 */
	var LUMINANCE = 'luminance';
	/**
	 * Same as `LUMINANCE`
	 */
	var LUMINOSITY = 'luminance';
	
	/**
	 * Uses value (maximum of RGB channels).
	 * Might be more viable when working with dark sprites
	 */
	var VALUE = 'value';
	/**
	 * Same as `VALUE`
	 */
	var BRIGHTNESS = 'value';
}