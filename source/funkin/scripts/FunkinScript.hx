package funkin.scripts;

import extensions.hscript.Sharables;
import extensions.hscript.InterpEx;

import insanity.Config;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;

@:access(funkin.states.PlayState)
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
			
			'flixel.FlxG', 'flixel.FlxSprite', 'flixel.FlxCamera',
			'flixel.group.FlxGroup.FlxTypedGroup', 'flixel.group.FlxSpriteGroup',
			'flixel.math.FlxMath', 'flixel.util.FlxTimer', 'flixel.tweens.FlxTween', 'flixel.tweens.FlxEase',
			'flixel.sound.FlxSound', 'flixel.text.FlxText', 'flixel.effects.FlxFlicker', 'flixel.util.FlxSpriteUtil', 'flixel.ui.FlxBar',
			'flixel.addons.display.FlxBackdrop', 'flixel.addons.display.FlxTiledSprite',
			'flixel.effects.particles.FlxParticle', 'flixel.effects.particles.FlxEmitter',
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
		Config.globalImports.set('funkin.scripts.ScriptClasses.ScriptedFlxRandom', IAsName('Random'));
		Config.globalImports.set('funkin.backend.FunkinShader.FunkinRuntimeShader', IAsName('FlxRuntimeShader'));
		
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
		super('', name, env); // evil
		
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
		log('$exception', null, ERROR);
	}
	public override dynamic function onProgramError(exception:haxe.Exception):Void {
		log('$exception', interp.posInfos(), ERROR);
	}
	
	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		if (!exists(func)) return null;
		
		var daFunc = get(func);
		// if (!Reflect.isFunction(daFunc)) return null; Well unsafety is ok
		
		var returnVal:Dynamic = null;
		var defaultShit:Map<String, Dynamic> = [];
		
		if (theObject != null)
		{
			extraVars ??= [];
			extraVars.set("this", theObject);
		}
		
		if (extraVars != null)
		{
			for (key => val in extraVars)
				defaultShit.set(key, val);
		}
		
		returnVal = call(daFunc, parameters ?? []);
		
		for (key => val in defaultShit)
			set(key, val);
		
		return returnVal;
	}
	
	@:inheritDoc
	override function setDefaults()
	{
		super.setDefaults();
		
		var setImport = interp.imports.set;
		
		set("script", this);
		set('modFolder', modFolder);
		
		set('curBpm', Conductor.bpm);
		set('version', Main.NMV_VERSION.trim());
		
		// abstracts  (these will be removed but its ok)
		setImport('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		setImport("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		setImport('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		setImport("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		setImport('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		// custom
		setImport('FlxColor', funkin.scripts.ScriptClasses.ScriptedFlxColor);
		setImport('Random', funkin.scripts.ScriptClasses.ScriptedFlxRandom);
		
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
		
		if ((FlxG.state is PlayState))
		{
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
			set('healthGainMult', PlayState.instance.healthGain);
			set('healthLossMult', PlayState.instance.healthLoss);
			set('botPlay', PlayState.instance.cpuControlled);
			set('practice', PlayState.instance.practiceMode);
			set('mustHitSection', PlayState.SONG?.notes[0]?.mustHitSection ?? false);
			
			set("global", PlayState.instance.variables);
			set("getInstance", funkin.scripting.ScriptConstants.getInstance);
			
			set('setVar', (varName:String, val:Dynamic) -> PlayState.instance.variables.set(varName, val));
			set('getVar', (varName:String) -> PlayState.instance.variables.get(varName));
			
			set('initScript', (path:String) -> {
				path = FunkinScript.getPath(path);
				if (!PlayState.instance.scripts.exists(path)) PlayState.instance.initFunkinScript(path);
			});
		}
		else
		{
			set("inPlaystate", false);
		}
		
		set("newShader", newShader);
	}
	
	public static function log(x:Dynamic, pos:haxe.PosInfos, severity:Severity = PRINT) { // hey its me severity
		Logger.log(Std.string(x), severity, true, pos);
	}
	
	override function call(funcToRun:String, ?args:Array<Dynamic>):Any {
		if (funcToRun == null || interp == null) return null;
		
		if (!exists(funcToRun)) {
			log('No function named $funcToRun', interp.posInfos(), ERROR);
			return null;
		}
		
		try {
			return Reflect.callMethod(interp, get(funcToRun), args ?? []);
		} catch (e:haxe.Exception) {
			log(e, interp.posInfos(), ERROR);
		}
		
		return null;
	}
	
	static function newShader(?fragFile:String, ?vertFile:String) {
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
	
	public function destroy():Void
	{
		program = null;
		interp = null;
		parser = null;
	}
	
	// compattttt
	public function tryExecute():Void {
		start();
	}
	
	public function get(field:String):Dynamic {
		return variables.get(field);
	}
	public function set(field:String, v:Dynamic):Dynamic {
		variables.set(field, v);
		return v;
	}
	public function exists(field:String):Bool {
		return variables.exists(field);
	}
}
