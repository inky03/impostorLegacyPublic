package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.input.keyboard.FlxKey;

import funkin.backend.DebugDisplay;

@:nullSafety(Strict)
class Main extends Sprite
{
	public static final PSYCH_VERSION:String = '0.5.2h';
	public static final NMV_VERSION:String = '1.0';
	public static final FUNKIN_VERSION:String = '0.2.7';
	public static final LEGACY_VERSION:String = '1.1.2b';
	
	public static final startMeta =
		{
			width: 1280,
			height: 720,
			fps: 60,
			skipSplash: #if debug true #else false #end,
			startFullScreen: false,
			initialState: funkin.states.TitleState
		};
		
	static function __init__()
	{
		funkin.utils.MacroUtil.haxeVersionEnforcement();
		
		openfl.utils._internal.Log.level = openfl.utils._internal.Log.LogLevel.INFO;
	}
	
	public function new()
	{
		super();
		
		funkin.Mods.updateModList();
		funkin.Mods.loadTopMod();
		
		#if (CRASH_HANDLER && !debug)
		funkin.backend.CrashHandler.init();
		#end
		
		initHaxeUI();
		
		#if (windows && cpp)
		// cpp.Windows.setDarkMode();
		cpp.Windows.setDpiAware();
		#end
		
		// load save data before creating FlxGame
		ClientPrefs.loadDefaultKeys();
		ClientPrefs.tryBindingSave('funkin');
		
		final game = new funkin.backend.FunkinGame(startMeta.width, startMeta.height, Init, startMeta.fps, startMeta.fps, true, startMeta.startFullScreen);
		
		// btw game has to be a variable for this to work ig - Orbyy
		@:privateAccess
		game._customSoundTray = funkin.objects.FunkinSoundTray;
		addChild(game);
		
		// prevent accept button when alt+enter is pressed
		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) -> {
			if (e.keyCode == FlxKey.ENTER && e.altKey) e.stopImmediatePropagation();
		}, false, 100);
		
		DebugDisplay.init();
		
		FlxG.signals.gameResized.add(onResize);
		
		#if DISABLE_TRACES
		haxe.Log.trace = (v:Dynamic, ?infos:haxe.PosInfos) -> {}
		#end
		
		#if sys
		FlxG.stage.window.onClose.add(function() {
			@:privateAccess MusicBeatState.addPlayTimeDelta();
			ClientPrefs.flush();
			Sys.println('saved data');
			funkin.Mods.writeModList();
			Sys.println('saved mods');
			
			#if hxvlc
			hxvlc.util.Handle.dispose(); // this is jsut from base game ok
			#end
			
			Sys.println('GOOD BYE CRUEL WORLD');
			
			Sys.exit(0);
		});
		#end
	}
	
	@:access(flixel.FlxCamera)
	static function onResize(w:Int, h:Int)
	{
		final scale:Float = Math.max(1, Math.min(w / FlxG.width, h / FlxG.height));
		
		if (FlxG.cameras != null)
		{
			for (i in FlxG.cameras.list)
			{
				if (i != null && i.filters != null) resetSpriteCache(i.flashSprite);
			}
		}
		
		if (FlxG.game != null)
		{
			resetSpriteCache(FlxG.game);
		}
	}
	
	@:nullSafety(Off)
	public static function resetSpriteCache(sprite:Sprite):Void
	{
		if (sprite == null) return;
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
	
	function initHaxeUI():Void
	{
		#if haxeui_core
		haxe.ui.Toolkit.init();
		haxe.ui.Toolkit.theme = 'dark';
		haxe.ui.Toolkit.autoScale = false;
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
		#end
	}
}
