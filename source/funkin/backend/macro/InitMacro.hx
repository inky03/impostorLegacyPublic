package funkin.backend.macro;

#if macro
import haxe.macro.Compiler;
#end

class InitMacro
{
	static final scriptableClasses:Array<String> = [
		'openfl.events.EventDispatcher',
		'openfl.display.DisplayObject', 'openfl.display.DisplayObjectContainer', 'openfl.display.InteractiveObject', 'openfl.display.Sprite', 'openfl.display.Bitmap',
		
		'flixel.FlxBasic', 'flixel.FlxObject', 'flixel.FlxSprite', 'flixel.FlxStrip', 'flixel.FlxState', 'flixel.FlxSubState', 'flixel.text.FlxText',
		'flixel.system.ui.FlxSoundTray', 'flixel.addons.ui.FlxUIState', 'flixel.addons.transition.FlxTransitionableState',
		
		'funkin.game.modchart.events.BaseEvent',
		'funkin.game.modchart.Modifier', 'funkin.game.modchart.NoteModifier', 'funkin.game.modchart.modifiers.PathModifier',
		'funkin.backend.MusicBeatState', 'funkin.backend.MusicBeatSubstate',
		
		'animate.FlxAnimate'
	];
	static final scriptablePackages:Array<String> = [
		'flixel.group', 'flixel.effects',
		
		'funkin.objects', 'funkin.game.huds'
	];
	
	public static macro function init():Void
	{
		// trace('amog');
		
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxSprite())', 'flixel.FlxSprite');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxCamera())', 'flixel.FlxCamera');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxText())', 'flixel.text.FlxText');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxGraphic())', 'flixel.graphics.FlxGraphic');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxDrawBaseItem())', 'flixel.graphics.tile.FlxDrawBaseItem');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxDrawItem())', 'flixel.graphics.tile.FlxDrawQuadsItem');
		Compiler.addMetadata('@:build(funkin.backend.macro.FlxMacro.buildFlxDrawItem())', 'flixel.graphics.tile.FlxDrawTrianglesItem');
		
		Compiler.addMetadata('@:nullSafety(Off)', 'hxvlc.openfl.Video');
		
		Compiler.include('funkin');
		Compiler.include('animate');
		Compiler.include('flixel', true, ['flixel.addons.nape.*', 'flixel.addons.editors.*', 'flixel.addons.tile.FlxRayCastTilemap', 'flixel.system.macros']);
		
		// hscript
		Compiler.addGlobalMetadata('flixel', '@:build(insanity.macro.Patcher.patch())');
		Compiler.addGlobalMetadata('flixel.group', '@:build(insanity.macro.Patcher.patch(true))');
		Compiler.addGlobalMetadata('flixel.effects', '@:build(insanity.macro.Patcher.patch(true))');
		Compiler.addGlobalMetadata('funkin.objects.menu', '@:build(insanity.macro.Patcher.patch(true))');
		
		Compiler.addGlobalMetadata('', '@:build(insanity.macro.ScriptableMacro.buildScriptable([], [], (cls) -> {
			for (ccls in ["${scriptableClasses.join('", "')}"]) if (ccls == cls) return true;
			for (ccls in ["${scriptablePackages.join('", "')}"]) if (cls.indexOf(ccls) == 0) return true;
			return false;
		}))');
	}
}
