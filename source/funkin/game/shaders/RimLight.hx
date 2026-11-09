package funkin.game.shaders;

// Written by Rozebud, teehee!!

class RimLight extends FlxBasic
{
	public var shader(default, null):RimLightShader = new RimLightShader();
	
	public var angle(default, set):Float = 0;
	public var distance(default, set):Float = 10;
	public var rimlightColor(default, set):FlxColor = FlxColor.WHITE;
	public var refSprite:FlxSprite;
	
	public function new(angle:Float = 0, distance:Float = 10, rimlightColor:FlxColor = FlxColor.WHITE, refSprite:FlxSprite)
	{
		super();
		
		this.angle = angle;
		this.distance = distance;
		this.refSprite = refSprite;
		this.rimlightColor = rimlightColor;
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		uvUpdate();
	}
	
	public function uvUpdate():Void
	{
		if (refSprite.frame == null) return;
		shader.setFloatArray('bounds', [refSprite.frame.uv.left, refSprite.frame.uv.top, refSprite.frame.uv.right, refSprite.frame.uv.bottom]);
	}
	
	function set_angle(v:Float):Float
	{
		shader.setFloat('angle', v);
		return angle = v;
	}
	
	function set_distance(v:Float):Float
	{
		shader.setFloat('distance', v);
		return distance = v;
	}
	
	function set_rimlightColor(v:FlxColor):FlxColor
	{
		shader.setFloatArray('rimlightColor', [v.redFloat, v.greenFloat, v.blueFloat, v.alphaFloat]);
		return rimlightColor = v;
	}
}

class RimLightShader extends funkin.backend.FunkinShader.FunkinRuntimeShader
{
	public function new()
	{
		super(FunkinAssets.getContent(Paths.fragment('rimlight')));
	}
}
