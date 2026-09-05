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
	final UNDERLAY_PADDING = 2;
	
	public var disableTime:Float = 4;
	public var traceCount(default, set):Int = 0;
	
	@:allow(funkin.backend.plugins.DebugTextPlugin)
	private var _trace = '';
	
	var _dirty:Bool = false;
	
	var _underlay:FlxSprite;
	
	public function new(text:String, color:FlxColor = FlxColor.WHITE)
	{
		super(17, 25, FlxG.width, text, 16);
		
		setFormat(Paths.font('consolas.ttf'), 16, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = .75;
		borderColor = 0x80000000;
		
		setText(text);
		
		_underlay = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		_underlay.color = FlxColor.BLACK;
		_underlay.alpha = 0;
		_underlay.scrollFactor.set();
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
		if (_dirty)
		{
			_dirty = false;
			camera = CameraUtil.lastCamera;
			
			this.text = '${traceCount > 1 ? '[$traceCount] - ' : ''}$_trace';
			this.fieldWidth = (FlxG.width - x * 2);
			this.regenGraphic();
		}
		
		if (_underlay.exists)
		{
			_underlay.scale.set(this.textField.textWidth + 4 + UNDERLAY_PADDING * 2 /*FlxG.width - x * 2 + UNDERLAY_PADDING*/, height);
			_underlay.updateHitbox();
			
			_underlay.setPosition(x - UNDERLAY_PADDING, y);
			_underlay.camera = this.camera;
			_underlay.alpha = (this.alpha * .4);
			
			_underlay.draw();
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
