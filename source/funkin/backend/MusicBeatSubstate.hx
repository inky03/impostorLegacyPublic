package funkin.backend;

import flixel.FlxSubState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.input.Controls;
import funkin.scripts.*;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}
	
	public var curSection:Int = 0;
	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	
	public var curSectionStep:Int = 0;
	public var nextSectionStep:Int = 0;
	
	public var curDecSection:Float = 0;
	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	
	private var controls(get, never):Controls;
	
	inline function get_controls():Controls return Controls.instance;
	
	public var scripted:Bool = false;
	public var scriptName:String = '';
	public var scriptPrefix:String = 'substates';
	public var scriptGroup:ScriptGroup = new ScriptGroup();
	
	public function initStateScript(?scriptName:String, callOnLoad:Bool = true):Bool
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		scriptGroup.scriptShareables.set('parent', this);
		
		this.scriptName = scriptName;
		
		final scriptFile = FunkinScript.getPath('scripts/$scriptPrefix/$scriptName');
		if (scriptGroup.exists(scriptFile)) return true;
		
		if (FunkinAssets.exists(scriptFile))
		{
			var _script = FunkinScript.fromFile(scriptFile, scriptName, scriptGroup.scriptShareables);
			if (_script.__garbage)
			{
				_script = FlxDestroyUtil.destroy(_script);
				return false;
			}
			
			scriptGroup.parent = this;
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			scriptGroup.addScript(_script);
			scripted = true;
		}
		
		if (callOnLoad) scriptGroup.call('onLoad', []);
		
		return scripted;
	}
	
	inline function isHardcodedState()
	{
		final ret:Null<Any> = scriptGroup?.call('customMenu');
		
		return (#if (target.static) !(ret is Bool) || #end ret != true);
	}
	
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
		final oldStep:Int = curStep;
		
		curDecSection = Conductor.getSection(Conductor.songPosition - ClientPrefs.noteOffset);
		updateCurStep();
		updateBeat();
		
		if (curStep > oldStep)
		{
			for (step in oldStep...curStep)
			{
				curStep = step + 1;
				
				updateBeat();
				
				if (curStep >= 0) stepHit();
				
				updateSection();
			}
		}
		else if (curStep < oldStep)
		{
			updateSection(true);
		}
		
		scriptGroup.call('onUpdate', [elapsed]);
		
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
	
	inline function updateBeat():Void curBeat = Std.int((curDecBeat = curDecStep / 4) / 4);
	
	inline function updateCurStep():Void curStep = Std.int(curDecStep = Conductor.getStep(Conductor.songPosition - ClientPrefs.noteOffset));
	
	public inline function getBeatsOnSection():Int return (PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4);
	
	public function stepHit():Void
	{
		scriptGroup.call('onStepHit', [curStep]);
		
		if (curStep % 4 == 0) beatHit();
	}
	
	public function beatHit():Void
	{
		scriptGroup.call('onBeatHit', [curBeat]);
	}
	
	public function sectionHit()
	{
		scriptGroup.call('onSectionHit', [curSection]);
	}
	
	override function destroy()
	{
		scriptGroup.call('onDestroy', []);
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
}
