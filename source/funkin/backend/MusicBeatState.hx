package funkin.backend;

import funkin.scripting.PluginsManager;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

import funkin.backend.BaseTransitionState;
import funkin.states.transitions.SwipeTransition;
import funkin.input.Controls;
import funkin.scripts.*;

class MusicBeatState extends FlxUIState
{
	static final _defaultTransState:Class<BaseTransitionState> = SwipeTransition;
	
	// change these to change the transition
	public static var transitionInState:Null<Class<BaseTransitionState>> = null;
	public static var transitionOutState:Null<Class<BaseTransitionState>> = null;
	
	public function new() super();
	
	public var curSection:Int = 0;
	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	
	public var curSectionStep:Int = 0;
	public var nextSectionStep:Int = 0;
	
	public var curDecSection:Float = 0;
	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	
	private var controls(get, never):Controls;
	
	// poppy playtime (rozebud edition)
	private static var playTimeHooksBound:Bool = false;
	private static var playTimeDirty:Bool = false;
	private static var playTimeTimestamp:Float = -1;
	private static var playTimeDirtyTimer:Float = 0;
	private static final PLAY_TIME_SAVE_INTERVAL:Float = 30;
	
	// script related vars
	public var scripted:Bool = false;
	public var scriptName:String = '';
	public var scriptGroup:ScriptGroup = new ScriptGroup();
	
	inline function isHardcodedState()
	{
		final ret:Null<Any> = scriptGroup?.call('customMenu');
		
		return (#if (target.static) !(ret is Bool) || #end ret != true);
	}
	
	public function initStateScript(?scriptName:String, callOnLoad:Bool = true):Bool
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		scriptGroup.scriptShareables.set('parent', this);
		
		this.scriptName = scriptName;
		
		final scriptFile = FunkinScript.getPath('scripts/states/$scriptName');
		if (scriptGroup.exists(scriptFile)) return true;
		
		if (FunkinAssets.exists(scriptFile))
		{
			var newScript = FunkinScript.fromFile(scriptFile, scriptName, scriptGroup.scriptShareables);
			if (newScript.__garbage)
			{
				newScript = FlxDestroyUtil.destroy(newScript);
				return false;
			}
			
			scriptGroup.parent = this;
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			scriptGroup.addScript(newScript);
			scripted = true;
		}
		
		if (callOnLoad) scriptGroup.call('onLoad', []);
		
		return scripted;
	}
	
	inline function get_controls():Controls return Controls.instance;
	
	private static inline function now():Float
	{
		return haxe.Timer.stamp();
	}
	
	private static function beginPlayTimeTracking():Void
	{
		if (playTimeTimestamp < 0) playTimeTimestamp = now();
	}
	
	private static function stopPlayTimeTracking():Void
	{
		playTimeTimestamp = -1;
	}
	
	private static function addPlayTimeDelta():Void
	{
		if (playTimeTimestamp < 0) return;
		
		final newTime:Float = now();
		final delta:Float = newTime - playTimeTimestamp;
		playTimeTimestamp = newTime;
		
		if (delta <= 0) return;
		
		ClientPrefs.totalPlayTime += delta;
		playTimeDirtyTimer += delta;
		
		if (playTimeDirtyTimer >= PLAY_TIME_SAVE_INTERVAL)
		{
			playTimeDirtyTimer %= PLAY_TIME_SAVE_INTERVAL;
			playTimeDirty = true;
		}
	}
	
	private static function bindPTH():Void
	{
		if (playTimeHooksBound) return;
		playTimeHooksBound = true;
		
		// flush when states switch
		FlxG.signals.preStateSwitch.add(function() {
			addPlayTimeDelta();
			flushPlayTime();
			stopPlayTimeTracking();
		});
		
		// pause/flush when alt-tabbed
		FlxG.signals.focusLost.add(function() {
			addPlayTimeDelta();
			flushPlayTime();
			stopPlayTimeTracking();
		});
		
		// resume timestamp on refocus
		FlxG.signals.focusGained.add(beginPlayTimeTracking);
	}
	
	private static function flushPlayTime():Void
	{
		if (!playTimeDirty) return;
		playTimeDirty = false;
		ClientPrefs.flushSave();
	}
	
	override function create()
	{
		updateMods();
		
		super.create();
		bindPTH();
		beginPlayTimeTracking();
		
		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(Type.createInstance(transitionOutState ?? _defaultTransState, [TransitionStatus.OUT]));
		}
		
		FlxTransitionableState.skipNextTransOut = false;
		
		PluginsManager.callOnScripts('onStateCreate');
	}
	
	var _updatedMods:Bool = false;
	
	public function updateMods(hard:Bool = false):Void
	{
		if (!hard && _updatedMods) return;
		
		_updatedMods = true;
		
		#if MODS_ALLOWED
		Mods.updateModList();
		Mods.pushGlobalMods();
		#end
	}
	
	/**
	 * Sorts a `FlxTypedGroup` based on objects `zIndex`.
	 * 
	 * used for stage layering primarily
	 * @param group 
	 */
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
		addPlayTimeDelta();
		
		final oldStep:Int = curStep;
		
		curDecSection = Conductor.getSection(Conductor.songPosition - ClientPrefs.noteOffset);
		updateCurStep();
		updateBeat();
		
		if (curStep > oldStep)
		{
			for (step in oldStep...curStep)
			{
				curBeat = Math.floor((curStep = (step + 1)) / 4);
				
				if (curStep >= 0)
				{
					stepHit();
					
					if (curStep % 4 == 0) beatHit();
				}
				
				updateSection();
			}
		}
		else if (curStep < oldStep)
		{
			updateSection(true);
		}
		
		final scriptArgs = [elapsed];
		scriptGroup.call('onUpdate', scriptArgs);
		PluginsManager.callOnScripts('onUpdate', scriptArgs);
		super.update(elapsed);
	}
	
	inline function updateSection(rollback:Bool = false):Void
	{
		final lastSection:Int = curSection;
		
		if (rollback)
		{
			curSection = Math.floor(curDecSection);
			updateSectionStep();
			
			if (curSection != lastSection && curSection >= 0) sectionHit();
		}
		else
		{
			while (curStep >= nextSectionStep)
			{
				curSection ++;
				curSectionStep = nextSectionStep;
				nextSectionStep += (getBeatsOnSection() * 4);
				
				if (curSection >= 0) sectionHit();
			}
		}
	}
	
	inline function updateSectionStep():Void
	{
		curSectionStep = Math.round(Conductor.getStep(Conductor.sectionToSeconds(curSection)));
		nextSectionStep = Math.round(Conductor.getStep(Conductor.sectionToSeconds(curSection + 1)));
	}
	
	inline function updateBeat():Void curBeat = Math.floor(curDecBeat = (curDecStep / 4));
	
	inline function updateCurStep():Void curStep = Math.floor(curDecStep = Conductor.getStep(Conductor.songPosition - ClientPrefs.noteOffset));
	
	public inline function getBeatsOnSection():Int return (PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4);
	
	public static function getState():MusicBeatState
	{
		return cast FlxG.state;
	}
	
	public static function getSubState(?state:flixel.FlxState)
	{
		state ??= FlxG.state;
		
		return (state.subState == null || state.subState is BaseTransitionState ? state : getSubState(state.subState));
	}
	
	public function stepHit():Void
	{
		scriptGroup.call('onStepHit', [curStep]);
		PluginsManager.callOnScripts('onStepHit');
	}
	
	public function beatHit():Void
	{
		scriptGroup.call('onBeatHit', [curBeat]);
		PluginsManager.callOnScripts('onBeatHit');
	}
	
	public function sectionHit():Void
	{
		scriptGroup.call('onSectionHit', [curSection]);
		PluginsManager.callOnScripts('onSectionHit');
	}
	
	override function startOutro(onOutroComplete:() -> Void)
	{
		final sub = getSubState()?.subState;
		
		if (sub is BaseTransitionState)
		{
			switch (@:privateAccess (cast sub : BaseTransitionState).status) // okey
			{
				case IN | FULL: return;
				
				default:
			}
		}
		
		if (!FlxTransitionableState.skipNextTransIn)
		{
			getSubState().openSubState(Type.createInstance(transitionInState ?? _defaultTransState, [TransitionStatus.IN, onOutroComplete]));
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = false;
		
		super.startOutro(onOutroComplete);
	}
	
	override function destroy()
	{
		scriptGroup.call('onDestroy');
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
	
	override function closeSubState()
	{
		scriptGroup.call('onCloseSubState', []);
		super.closeSubState();
	}
}
