package funkin.scripts;

import extensions.hscript.Sharables;
import extensions.hscript.IrisEx;

import crowplexus.iris.Iris;
import crowplexus.iris.ErrorSeverity;

import extensions.hscript.InterpEx;

import funkin.backend.plugins.DebugTextPlugin;
import funkin.objects.*;
import funkin.objects.note.*;

using crowplexus.iris.utils.Ansi;

@:access(crowplexus.iris.Iris)
@:access(funkin.states.PlayState)
class FunkinScript extends IrisEx implements IFlxDestroyable
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
	
	static inline function formatPosInfos(fileName:String = 'hscript', lineNumber:Int = 0, x:String = '', prefix:String = '')
	{
		var prefix = '[$prefix$fileName:$lineNumber]';
		
		final modPath:String = Paths.mods(Mods.currentModDirectory + '/');
		if (fileName.startsWith(modPath)) prefix = prefix.replace(modPath, '');
		#if ASSET_REDIRECT else if (fileName.startsWith(Paths.trail)) prefix = prefix.replace(Paths.trail, ''); #end
		
		return '$prefix - $x';
	}
	
	/**
	 * Initiates the debugging backend of Iris
	 */
	public static function init()
	{
		Iris.logLevel = (level, x, ?pos) -> {
			pos ??= Iris.getDefaultPos();
			
			final prefix:String = ErrorSeverityTools.getPrefix(level);
			final prefixEmpty:Bool = (prefix == '');
			
			var out = formatPosInfos(pos.fileName, pos.lineNumber, x, prefixEmpty ? '' : '$prefix:');
			
			if (!prefixEmpty)
			{
				out = out.fg(ErrorSeverityTools.getColor(level)).reset();
				if (level == FATAL) out = out.attr(INTENSITY_BOLD);
			}
			
			#if sys Sys.println #else trace #end (out.stripColor());
		}
		
		function log(x:String, ?pos:haxe.PosInfos, level:ErrorSeverity)
		{
			final prefix:String = ErrorSeverityTools.getPrefix(level);
			
			DebugTextPlugin.addText(formatPosInfos(pos.fileName, pos.lineNumber, x, prefix == '' ? '' : '$prefix:'), Logger.getHexColourFromSeverity(Severity.fromIris(level)));
			
			Iris.logLevel(level, x, pos);
		}
		
		Iris.warn = log.bind(_, _, WARN);
		
		Iris.error = log.bind(_, _, ERROR);
		
		Iris.fatal = log.bind(_, _, FATAL);
		
		Iris.print = log.bind(_, _, NONE);
	}
	
	/**
	 * Creates a new `FunkinScript` from a string
	 * @param script 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String)
	{
		return new FunkinScript(script, name, additionalVars, shareables, modFolder);
	}
	
	/**
	 * Creates a new `FunkinScript` from a filepath
	 * 
	 * @param file 
	 * @param name 
	 * @param additionalVars 
	 */
	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String)
	{
		name ??= file;
		
		modFolder ??= Paths.getModFolder(file, 'scripts');
		
		return new FunkinScript(FunkinAssets.getContent(file), name, additionalVars, shareables, modFolder);
	}
	
	/**
	 * is true if parsing failed
	 */
	@:noCompletion public var __garbage:Bool = false;
	
	public var modFolder:Null<String>;
	
	public function new(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?shareables:Sharables, ?modFolder:String)
	{
		super(script, {name: name, autoRun: false, autoPreset: false}, shareables);
		
		(cast interp : InterpEx).parent = FlxG.state;
		
		this.modFolder = modFolder;
		
		preset();
		
		if (additionalVars != null)
		{
			for (key => obj in additionalVars)
				set(key, additionalVars.get(obj));
		}
		
		tryExecute();
	}
	
	/**
	 * safer parsing
	 */
	inline function tryExecute()
	{
		var ret:Dynamic = null;
		try
		{
			ret = execute();
		}
		catch (e)
		{
			__garbage = true;
			Logger.log('[${name}]: PARSING ERROR: $e', ERROR, true);
		}
		return ret;
	}
	
	// kept for notescript stuff
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?theObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		extraVars ??= [];
		
		if (exists(func))
		{
			var daFunc = get(func);
			if (Reflect.isFunction(daFunc))
			{
				var returnVal:Dynamic = null;
				var defaultShit:Map<String, Dynamic> = [];
				
				if (theObject != null) extraVars.set("this", theObject);
				
				for (key in extraVars.keys())
				{
					defaultShit.set(key, get(key));
					set(key, extraVars.get(key));
				}
				
				try
				{
					returnVal = Reflect.callMethod(theObject, daFunc, parameters ?? []);
				}
				catch (e:haxe.Exception)
				{
					#if sys
					Sys.println(e.message);
					#end
				}
				
				for (key in defaultShit.keys())
				{
					set(key, defaultShit.get(key));
				}
				
				return returnVal;
			}
		}
		return null;
	}
	
	@:inheritDoc
	override function preset()
	{
		super.preset();
		
		#if hl
		set('Math', hl.HLFixes.HLMath);
		set('Std', hl.HLFixes.HLStd);
		set("trace", Reflect.makeVarArgs(function(x:Array<Dynamic>) {
			var pos = this.interp != null ? this.interp.posInfos() : Iris.getDefaultPos(this.name);
			
			Iris.print(Std.string(x[0]), pos);
		}));
		#end
		
		for (k => v in funkin.data.Defines.defines) parser.preprocesorValues.set(k, v);
		
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
		set('Defines', funkin.data.Defines);
		
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
		set("CoolUtil", funkin.utils.CoolUtil);
		set('WindowUtil', funkin.utils.WindowUtil);
		
		set("StageData", funkin.data.StageData);
		set("PlayState", PlayState);
		set('FunkinSound', funkin.audio.FunkinSound);
		
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
		
		set("newShader", (?fragFile:String, ?vertFile:String) -> {
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
		});
	}
}
