package funkin.scripts;

import extensions.hscript.Sharables;
import extensions.hscript.InterpEx;

import insanity.Config;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;

using funkin.backend.Logger;

@:access(funkin.states.PlayState)
@:access(insanity.backend.Interp)
class FunkinScript extends insanity.Script implements IFlxDestroyable
{
	/**
	 * List of all accepted hscript extensions
	 */
	public static final H_EXTS:Array<String> = ['hx', 'hxs', 'hscript'];
	
	/**
	 * wrapper for `Paths.getPath` but attempts to append a supported hx extension to its path
	 * @param path 
	 * @return String
	 */
	public static function getPath(path:String, mode:PathsTestMode = NORMAL):String
	{
		for (extension in H_EXTS)
		{
			final file = '$path.$extension';
			
			final targetPath = Paths.getPath(file, mode);
			if (FunkinAssets.exists(targetPath)) return targetPath;
		}
		return path;
	}
	
	/**
	 * Helper to check if a path ends with a support hx extension
	 */
	public static function isHxFile(path:String):Bool
	{
		for (extension in H_EXTS)
			if (path.endsWith(extension)) return true;
			
		return false;
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		Config.interpClass = InterpEx;
		
		for (cls in [
			// so many classes... please hlep me
			
			'StringTools', 'Date', 'Sys', 'Type',
			'haxe.ds.StringMap', 'haxe.ds.IntMap', 'haxe.ds.ObjectMap',
			'Main', 'openfl.Lib', 'lime.utils.Assets',
			
			'openfl.display.BlendMode',
			
			'flixel.FlxG', 'flixel.FlxSprite',
			'flixel.group.FlxGroup.FlxTypedGroup', 'flixel.group.FlxSpriteGroup',
			'flixel.math.FlxMath', 'flixel.util.FlxTimer', 'flixel.tweens.FlxTween', 'flixel.tweens.FlxEase',
			'flixel.sound.FlxSound', 'flixel.text.FlxText', 'flixel.effects.FlxFlicker', 'flixel.util.FlxSpriteUtil', 'flixel.ui.FlxBar',
			'flixel.addons.display.FlxBackdrop', 'flixel.addons.display.FlxTiledSprite',
			'flixel.effects.particles.FlxParticle', 'flixel.effects.particles.FlxEmitter',
			'flixel.util.FlxAxes', 'flixel.math.FlxPoint', 'flixel.input.keyboard.FlxKey',
			'animate.FlxAnimate', 'animate.FlxAnimateFrames', 'animate.internal.elements.FlxSpriteElement',
			
			'funkin.objects.FunkinSprite',
			
			'funkin.Paths', 'funkin.backend.MusicBeatState', 'funkin.backend.Conductor', 'funkin.data.ClientPrefs', 'funkin.data.Lang', 'funkin.input.Controls',
			'funkin.states.PlayState', 'funkin.states.substates.GameOverSubstate', 'funkin.data.StageData', 'funkin.data.GameFlags', 'funkin.audio.FunkinSound',
			
			'funkin.scripts.FunkinScript',
			
			#if VIDEOS_ALLOWED
			'funkin.video.FunkinVideoSprite'
			#end
		])
		{
			Config.globalImports.set(cls, INormal);
		}
		
		for (pack in ['funkin.utils', 'funkin.game.modchart', 'funkin.game.modchart.events', 'funkin.objects', 'funkin.objects.note', 'funkin.scripting'])
		{
			Config.globalImports.set(pack, IAll);
		}
		
		Config.globalImports.set('openfl.utils.Assets', IAsName('OpenFlAssets')); // lpwkey why is the one with the alias and not lime's
		Config.globalImports.set('funkin.scripts.ScriptClasses.ScriptedFlxColor', IAsName('FlxColor')); // wil be removed eventually
		Config.globalImports.set('funkin.scripts.ScriptClasses.ScriptedFlxRandom', IAsName('Random'));
		Config.globalImports.set('funkin.backend.FunkinShader.FunkinRuntimeShader', IAsName('FlxRuntimeShader'));
		Config.globalImports.set('funkin.backend.FunkinCamera', IAsName('FlxCamera'));
		
		for (f in ['Cancel', 'Halt', 'Stop', 'Continue']) // work around for NOW because its messed up  !?!?!??!?!?!?
			Config.globalVariables.set('Function_$f', insanity.backend.Expr.Mirror.MProperty(funkin.scripting.ScriptConstants, '${f.toUpperCase()}_FUNC'));
	}
	
	/**
	 * Creates a new `FunkinScript` from a string
	 * @param script 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String, autoExecute:Bool = true)
	{
		return new FunkinScript(script, name, additionalVars, shareables, modFolder, autoExecute);
	}
	
	/**
	 * Creates a new `FunkinScript` from a filepath
	 * 
	 * @param file 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String, autoExecute:Bool = true)
	{
		name ??= file;
		
		modFolder ??= Paths.getModFolder(file, 'scripts');
		
		return new FunkinScript(FunkinAssets.getContent(file), name, additionalVars, shareables, modFolder, autoExecute);
	}
	
	/**
	 * is true if parsing failed
	 */
	@:noCompletion public var __garbage:Bool = false;
	
	public var modFolder:Null<String>;
	
	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String, autoExecute:Bool = true, ?env:insanity.Environment)
	{
		super('', name, env ?? FunkinModuleCollection.instance); // evil
		
		parser = new extensions.hscript.ParserEx();
		parser.allowTypes = parser.allowJSON = parser.allowMetadata = true;
		
		this.name = name;
		this.parse(script);
		
		final interpEx:InterpEx = cast interp;
		interpEx.sharedFields = shareables;
		interpEx.setParent(FlxG.state);
		interpEx.argumentOverflow = true;
		
		this.modFolder = modFolder;
		
		if (additionalVars != null)
		{
			for (key => obj in additionalVars)
				set(key, additionalVars.get(obj));
		}
		
		if (autoExecute) start();
	}
	
	public inline function addParent(parent:Dynamic):Dynamic
	{
		return (cast interp : InterpEx).addParent(parent);
	}
	
	public inline function removeParent(parent:Dynamic):Dynamic
	{
		return (cast interp : InterpEx).removeParent(parent);
	}
	
	public override dynamic function onParsingError(exception:haxe.Exception):Void {
		log('$exception', cast {fileName: name, lineNumber: parser.line}, FATAL);
		__garbage = true;
	}
	public override dynamic function onProgramError(exception:haxe.Exception):Void {
		log('$exception', interp.posInfos(), FATAL);
		__garbage = true;
	}
	
	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		if (!exists(func)) return null;
		
		if (theObject != null)
		{
			extraVars ??= [];
			extraVars.set("this", theObject);
		}
		
		if (extraVars != null)
		{
			for (key => val in extraVars)
				set(key, val);
		}
		
		return call(func, parameters ?? []);
	}
	
	@:inheritDoc
	public override function setDefaults():Void
	{
		super.setDefaults();
		
		var setImport = interp.imports.set;
		
		set("script", this);
		set('modFolder', modFolder);
		
		set('curBpm', Conductor.bpm);
		set('version', Main.NMV_VERSION.trim());
		
		set("keyToString", (key:Int) -> {
			return flixel.input.keyboard.FlxKey.toStringMap.get(key);
		});
		set("keyFromString", (str:String) -> {
			return flixel.input.keyboard.FlxKey.fromStringMap.get(str);
		});
		
		// for compat
		setImport('HScriptState', funkin.scripting.ScriptedState);
		setImport('HScriptSubstate', funkin.scripting.ScriptedSubstate);
		
		set('inGameOver', false);
		
		set("game", FlxG.state);
		set("state", FlxG.state);
		
		if (FlxG.state is PlayState)
		{
			final game:PlayState = cast FlxG.state;
			
			set("inPlaystate", true);
			set('bpm', PlayState.SONG.bpm);
			set('scrollSpeed', PlayState.SONG.speed);
			set('songName', PlayState.SONG.song);
			set('isStoryMode', PlayState.isStoryMode);
			set('difficulty', PlayState.storyMeta.difficulty);
			set('weekRaw', PlayState.storyMeta.curWeek);
			set('seenCutscene', PlayState.seenCutscene);
			set('week', funkin.data.WeekData.weeksList[PlayState.storyMeta.curWeek]);
			set('difficultyName', funkin.backend.Difficulty.difficulties[PlayState.storyMeta.difficulty]);
			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);
			
			set("global", game.variables);
			set("getInstance", funkin.scripting.ScriptConstants.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> game.variables.set(varName, val));
			set('getVar', (varName:String) -> game.variables.get(varName));
			
			set('initScript', (path:String) -> {
				path = FunkinScript.getPath(path);
				if (!game.scripts.exists(path)) game.initFunkinScript(path);
			});
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set("newShader", newShader);
	}
	
	static inline function formatPosInfos(pos:haxe.PosInfos, x:String = '', prefix:String = '')
	{
		var fileName:String = (pos.fileName ?? 'hscript');
		var method:String = (pos.methodName == null ? '' : ':${pos.methodName}');
		var line:String = (pos.lineNumber < 0 ? '' : ':${pos.lineNumber}');
		
		final modPath:String = Paths.mods(Mods.currentModDirectory + '/');
		if (fileName.startsWith(modPath)) fileName = fileName.replace(modPath, '');
		#if ASSET_REDIRECT else if (fileName.startsWith(Paths.trail)) fileName = fileName.replace(Paths.trail, ''); #end
		
		var prefix = '[$prefix$fileName$method$line]';
		
		return '$prefix $x';
	}
	
	public static function log(x:Dynamic, pos:haxe.PosInfos, severity:Severity = PRINT):Void // hey its me severity
	{
		final prefix:String = severity.scriptPrefix;
		var out:String = formatPosInfos(pos, Std.string(x), prefix.length == 0 ? '' : '$prefix:');
		
		DebugTextPlugin.addText(out, Logger.getHexColourFromSeverity(severity));
		
		if (prefix.length > 0)
		{
			out = out.fg(Logger.getAnsiColourFromSeverity(severity)).reset();
			if (severity == FATAL) out = out.attr(INTENSITY_BOLD);
		}
		
		Sys.println(out);
	}
	
	override function call(funcToRun:String, ?args:Array<Dynamic>):Any
	{
		if (funcToRun == null || interp == null) return null;
		
		if (!exists(funcToRun)) {
			log('No function named $funcToRun', interp.posInfos(), ERROR);
			return null;
		}
		
		return Reflect.callMethod(interp, get(funcToRun), args ?? []);
	}
	
	static function newShader(?fragFile:String, ?vertFile:String)
	{
		var fragPath = fragFile != null ? Paths.fragment(fragFile) : null;
		var vertPath = vertFile != null ? Paths.vertex(vertFile) : null;
		
		if (fragPath != null)
		{
			if (FunkinAssets.exists(fragPath)) fragPath = FunkinAssets.getContent(fragPath);
		}
		
		if (vertPath != null)
		{
			if (FunkinAssets.exists(vertPath)) vertPath = FunkinAssets.getContent(vertPath);
		}
		
		return new funkin.backend.FunkinShader.FunkinRuntimeShader(fragPath, vertPath);
	}
	
	public override function start():Any
	{
		if (program == null)
		{
			__garbage = true;
			return null;
		}
		
		interp.inTry = true;
		
		return super.start();
	}
	
	public function destroy():Void
	{
		program = null;
		interp = null;
		parser = null;
	}
	
	// compattttt
	public function tryExecute():Void
	{
		start();
	}
	
	public function get(field:String):Dynamic
	{
		return variables.get(field);
	}
	public function set(field:String, v:Dynamic):Dynamic
	{
		variables.set(field, v);
		return v;
	}
	public function exists(field:String):Bool
	{
		return variables.exists(field);
	}
}
