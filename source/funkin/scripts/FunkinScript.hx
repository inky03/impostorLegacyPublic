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
		
		set("StringTools", StringTools);
		set("Date", Date);
		set("Sys", Sys);
		
		set("Type", Type);
		set("script", this);
		set("Dynamic", Dynamic);
		set('modFolder', modFolder);
		
		set('StringMap', haxe.ds.StringMap);
		set('IntMap', haxe.ds.IntMap);
		set('ObjectMap', haxe.ds.ObjectMap);
		
		set("Main", Main);
		set("Lib", openfl.Lib);
		set("Assets", lime.utils.Assets);
		set("OpenFlAssets", openfl.utils.Assets);
		
		set('curBpm', Conductor.bpm);
		set('Function_Cancel', funkin.scripting.ScriptConstants.CANCEL_FUNC);
		set('Function_Halt', funkin.scripting.ScriptConstants.HALT_FUNC);
		set('Function_Stop', funkin.scripting.ScriptConstants.STOP_FUNC);
		set('Function_Continue', funkin.scripting.ScriptConstants.CONTINUE_FUNC);
		set('version', Main.NMV_VERSION.trim());
		
		// set flixel related stuff
		set("FlxG", flixel.FlxG);
		set("FlxSprite", flixel.FlxSprite);
		set("FunkinSprite", funkin.objects.FunkinSprite);
		set("FlxTypedGroup", flixel.group.FlxGroup.FlxTypedGroup);
		set("FlxSpriteGroup", flixel.group.FlxSpriteGroup);
		set("FlxCamera", flixel.FlxCamera);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxSound", flixel.sound.FlxSound);
		set('FlxText', flixel.text.FlxText);
		set("FlxRuntimeShader", funkin.backend.FunkinShader.FunkinRuntimeShader);
		set("FlxFlicker", flixel.effects.FlxFlicker);
		set('FlxSpriteUtil', flixel.util.FlxSpriteUtil);
		set("FlxBackdrop", flixel.addons.display.FlxBackdrop);
		set("FlxTiledSprite", flixel.addons.display.FlxTiledSprite);
		set('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		set('FlxParticle', flixel.effects.particles.FlxParticle);
		set('FlxEmitter', flixel.effects.particles.FlxEmitter);
		
		set('FlxCameraFollowStyle', flixel.FlxCamera.FlxCameraFollowStyle);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		
		set("FlxAnimate", animate.FlxAnimate);
		set("FlxAnimateFrames", animate.FlxAnimateFrames);
		set("FlxSpriteElement", animate.internal.elements.FlxSpriteElement);
		
		set('Controls', funkin.input.Controls);
		
		// abstracts
		set("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		set('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		set("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		set('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
		
		set("keyToString", (key:Int) -> {
			return flixel.input.keyboard.FlxKey.toStringMap.get(key);
		});
		set("keyFromString", (str:String) -> {
			return flixel.input.keyboard.FlxKey.fromStringMap.get(str);
		});
		
		// modchart related
		set("ModManager", funkin.game.modchart.ModManager);
		set("SubModifier", funkin.game.modchart.SubModifier);
		set("NoteModifier", funkin.game.modchart.NoteModifier);
		set("ScriptedModifier", funkin.game.modchart.ScriptedModifier);
		set("EventTimeline", funkin.game.modchart.EventTimeline);
		set("Modifier", funkin.game.modchart.Modifier);
		set("StepCallbackEvent", funkin.game.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.game.modchart.events.CallbackEvent);
		set("ModEvent", funkin.game.modchart.events.ModEvent);
		set("EaseEvent", funkin.game.modchart.events.EaseEvent);
		set("SetEvent", funkin.game.modchart.events.SetEvent);
		
		// FNF-specific things
		set("Paths", Paths);
		set("PathsTestMode", PathsTestMode);
		set("MusicBeatState", funkin.backend.MusicBeatState);
		set("Conductor", funkin.backend.Conductor);
		set("ClientPrefs", funkin.data.ClientPrefs);
		set("Lang", funkin.data.Lang);
		set("GameFlags", funkin.data.GameFlags);
		
		set("PlayState", PlayState);
		set("StageData", funkin.data.StageData);
		set('FunkinSound', funkin.audio.FunkinSound);
		
		// utils
		set('MathUtil', funkin.utils.MathUtil);
		set("CoolUtil", funkin.utils.CoolUtil);
		set('CameraUtil', funkin.utils.CameraUtil);
		set('WindowUtil', funkin.utils.WindowUtil);
		set('ProgressionUtil', funkin.utils.ProgressionUtil);
		
		// custom
		set('FlxColor', funkin.scripts.ScriptClasses.ScriptedFlxColor);
		set('Random', funkin.scripts.ScriptClasses.ScriptedFlxRandom);
		
		// script
		set("FunkinScript", FunkinScript);
		set('ScriptConstants', funkin.scripting.ScriptConstants);
		
		// for compat
		set('HScriptState', funkin.scripting.ScriptedState);
		set('HScriptSubstate', funkin.scripting.ScriptedSubstate);
		
		set('ScriptedState', funkin.scripting.ScriptedState);
		set('ScriptedSubstate', funkin.scripting.ScriptedSubstate);
		
		set("GameOverSubstate", funkin.states.substates.GameOverSubstate);
		
		// objects
		set("Note", funkin.objects.note.Note);
		set("Bar", funkin.objects.Bar);
		#if VIDEOS_ALLOWED
		set("FunkinVideoSprite", funkin.video.FunkinVideoSprite);
		#end
		set("HealthIcon", HealthIcon);
		set("Character", funkin.objects.Character);
		set("NoteSplash", NoteSplash);
		set("BGSprite", BGSprite);
		set("StrumNote", StrumNote);
		set("Alphabet", Alphabet);
		set("AttachedSprite", AttachedSprite);
		set("AttachedAlphabet", AttachedAlphabet);
		
		set("CutsceneHandler", funkin.objects.CutsceneHandler);
		
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
			trace(e.details());
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
