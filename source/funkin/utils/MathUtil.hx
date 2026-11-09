package funkin.utils;

@:nullSafety(Strict)
class MathUtil
{
	/**
	 * Get the logarithm of a value with a given base.
	 * @param base The base of the logarithm.
	 * @param value The value to get the logarithm of.
	 * @return `log_base(value)`
	 */
	public static function logBase(base:Float, value:Float):Float
	{
		return Math.log(value) / Math.log(base);
	}
	
	/**
	 * Remaps a value from a range to a new range
	 * 
	 * Akin to `FlxMath.remapToRange`
	 * @param x Input value
	 * @param l1 Low bound of range 1
	 * @param h1 High bound of range 1
	 * @param l2 Low bound of range 2
	 * @param h2 High bound of range 2
	 * @return Input value remapped to range 2
	 */
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);
	
	/**
	 * Clamps/Bounds a value between a range that it cannot go below or over
	 * 
	 * Akin to `FlxMath.bound`
	 * @param n Input value
	 * @param l Low boundary
	 * @param h High Boundary
	 * @return Clamped value
	 */
	inline public static function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h) n = h;
		if (n < l) n = l;
		return n;
	}
	
	/**
	 * Creates or uses a provided point and rotates it around a given `x` and `y` by radians
	 * 
	 * Akin to `new FlxPoint(x,y).radians += angle`
	 * @return A rotated FlxPoint
	 */
	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		final p = point ?? FlxPoint.weak();
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}
	
	public static inline function quantizeAlpha(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}
	
	public static inline function quantize(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}
	
	/**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float) return FlxMath.lerp(v1, v2, FlxMath.getElapsedLerp(ratio, FlxG.elapsed));
	
	/**
	 * referenced via https://youtu.be/LSNQuFEDOyQ
	 * 
	 * A frame independent lerp. Primary purpose is for the camera
	 * 
	 * your decay should be around 1 - 25
	 */
	public static function decayLerp(a:Float, b:Float, decay:Float, elapsed:Float) return b + (a - b) * Math.exp(-decay * elapsed);
	
	/**
		Similar to FlxMath.wrap, but also supports floats.
		
		@param n Number to wrap.
		@param min Minimum number (inclusive).
		@param max Maximum number (up to but excluding max + 1).
		@result Result of wrap.
	**/
	public static inline function wrap(n:Float, min:Float, max:Float):Float return (euclideanMod(n - min, max - min + 1) + min);
	
	/**
		https://en.wikipedia.org/wiki/Modulo
		
		Simulates modulo with euclidean division.
		(Unlike Haxe's modulo operator, which uses truncated division, the result will never be negative)
		
		@param n Dividend of the operation.
		@param div Divisor of the operator.
		@result Result of euclidean division.
	**/
	public static inline function euclideanMod(n:Float, div:Float):Float {
		var mod:Float = (n % div);
		return (mod < 0 ? mod + Math.abs(div) : mod);
	}
	
	/**
	 * Alternative to `FlxMath.roundDecimal` but floors the value rather than rounding it
	 * @param value The number 
	 * @param precision The number of decimals
	 * @return The floored value
	 */
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);
		
		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;
			
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
	
	/**
		Makes a number array
		* @param	min starting number. default is 0
		* @param	max ending number
		* @return the new array
	**/
	public static inline function numberArray(?min:Int, max:Int):Array<Int>
	{
		if (min == null) min = 0;
		return [for (i in min...max) i];
	}
}
