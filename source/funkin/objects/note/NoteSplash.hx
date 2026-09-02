package funkin.objects.note;

import flixel.FlxSprite;

import funkin.game.shaders.RGBShader;
import funkin.data.*;
import funkin.states.*;
import funkin.data.NoteSkin;

// @:nullSafety
class NoteSplash extends funkin.game.modchart.ModchartNote
{
	/**
	 * The notedata of the splash
	 */
	public var data(get, set):Int;
	
	public var player:Int = 0;
	
	private var _note:Null<Note>;
	private var _strum:Null<StrumNote>;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public var skin:NoteSkin;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		this._note = null;
		this._strum = null;
		
		this.data = noteData;
		this.player = player;
		
		loadAnims(NoteUtil.getSkinFromID(player).splashTexture);
		
		final skin = NoteUtil.getSkinFromID(player);
		if (skin != null)
		{
			scale.set(skin.splashScale, skin.splashScale);
			baseScale.copyFrom(scale);
		}
		
		animation.onFinish.add((anim) -> if (anim.contains('splash')) kill());
	}
	
	public function setupNoteSplash(strum:StrumNote, ?note:Note, ?texture:String, ?graphicsInput:RGBGraphics, ?field:PlayField)
	{
		_note = note ?? null;
		_strum = strum ?? null;
		
		data = note?.noteData ?? 0;
		
		player = field?.player ?? 0;
		
		skin = NoteUtil.getSkinFromID(player);
		
		texture ??= 'noteSplashes';
		
		antialiasing = skin?.antialiasing ?? true;
		
		if (_textureLoaded != texture) loadAnims(texture);
		
		updateHitbox();
		
		final randomAnim:String = 'splash-${FlxG.random.int(0, (skin.noteSplashVariants ?? 1) - 1)}';
		
		if (animation.exists(randomAnim))
		{
			playAnim(randomAnim, true);
		}
		else if (animation.exists('splash'))
		{
			playAnim('splash', true);
		}
		else
		{
			kill();
		}
		
		setColors(graphicsInput?.getColors());
		
		_position();
	}
	
	public override function playAnim(anim:String, force:Bool = false, isReversed:Bool = false, frame:Int = 0):Void
	{
		super.playAnim(anim, force, isReversed, frame);
		
		centerOffsets();
		centerOrigin();
	}
	
	public function setColors(?colors:Array<FlxColor>):Void
	{
		if (colors == null) return;
		
		final sanitzedColourArray = colors ?? NoteUtil.colorToArray(skin.colors[data]);
		
		rgbShader.enabled = skin.inEngineColoring;
		rgbShader.setColors(sanitzedColourArray);
	}
	
	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		
		final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
		
		switch (skin)
		{
			default:
				final data = _skin.splashAnims ?? NoteUtil.DEFAULT_NOTESPLASH_ANIMATIONS;
				
				for (anim in data[noteData % data.length])
				{
					if (anim.anim == null || anim.xmlName == null) continue;
					
					final animName = anim.anim;
					final offsets = anim.offsets;
					
					@:nullSafety(Off)
					addAnimByPrefix(animName, anim.xmlName, anim.fps, false);
					addOffset(animName, offsets[0], offsets[1]);
				}
		}
		
		_textureLoaded = skin;
	}
	
	// doing this so the splash tracks the location of the strumnote if ur moving the notes actively with modmanager
	function _position()
	{
		if (_strum != null)
		{
			final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
			
			final offsets = _skin.splashOffsets != null ? _skin.splashOffsets[data] : null;
			
			setPosition(_strum.x + (_strum.width - width) * .5, _strum.y + (_strum.height - height) * .5);
			spriteOffset.set(offsets?.x, offsets?.y);
		}
	}
	
	inline function get_data():Int return noteData;
	
	inline function set_data(v:Int):Int return noteData = v;
}
