package funkin.backend.plugins;

import openfl.display.BitmapData;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;

/**
 * Plugin that shows debug content in game without the need of a console
 */
@:nullSafety
class DebugTextPlugin extends FlxTypedGroup<DebugText>
{
	static var instance:Null<DebugTextPlugin> = null;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new DebugTextPlugin());
			FlxG.signals.preStateSwitch.add(clearTxt);
		}
	}
	
	static inline function posText()
	{
		if (instance == null) return;
		
		var y:Float = 25;
		
		instance.forEachAlive((txt:DebugText) ->
		{
			txt.y = y;
			y += txt.height;
		});
	}
	
	static function grabText(message:String):DebugText
	{
		if (instance == null) return new DebugText(message);
		
		for (text in instance)
		{
			if (text == null) continue;
			
			if (text.alive && text._trace == message) return text;
		}
		
		return instance.recycle(DebugText, () -> new DebugText(message));
	}
	
	public static function addText(message:String, colour:FlxColor = FlxColor.WHITE)
	{
		if (instance == null) return;
		
		final text = grabText(message);
		
		text.traceCount++;
		text.color = colour;
		text.setText(message);
		text.resetValues();
		text.revive();
		
		instance.remove(text, true);
		instance.insert(0, text);
		
		posText();
	}
	
	static function clearTxt()
	{
		if (instance == null) return;
		
		instance.forEach(text -> text?.destroy());
		
		instance.clear();
	}
}

class DebugText extends FlxText
{
	public var disableTime:Float = 4;
	public var traceCount(default, set):Int = 0;
	
	@:allow(funkin.backend.plugins.DebugTextPlugin)
	private var _trace = '';
	
	var _dirty:Bool = false;
	
	public function new(text:String, color:FlxColor = FlxColor.WHITE)
	{
		super(10, 10, FlxG.width, text, 16);
		
		setFormat(Paths.DEFAULT_FONT, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
		this.color = color;
		
		setText(text);
	}
	
	public function setText(input:String)
	{
		this._trace = input;
		_dirty = true;
	}
	
	public function resetValues()
	{
		this.disableTime = 4;
		this.alpha = 1;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		disableTime -= elapsed;
		if (y >= FlxG.height) kill();
		
		if (disableTime <= 0)
		{
			traceCount = 0;
			kill();
		}
		else if (disableTime < 1) alpha = disableTime;
	}
	
	override function draw()
	{
		camera = CameraUtil.lastCamera;
		
		if (_dirty)
		{
			final traceCounter = traceCount > 1 ? '[' + '$traceCount' + ']' + ' - ' : '';
			
			this.text = '$traceCounter$_trace';
			_dirty = false;
		}
		super.draw();
	}
	
	inline function set_traceCount(v:Int)
	{
		if (v == traceCount) return v;
		
		_dirty = true;
		
		return traceCount = v;
	}
}
