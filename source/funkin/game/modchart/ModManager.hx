// @author Nebula_Zorua
package funkin.game.modchart;

import flixel.FlxSprite;
import flixel.FlxG;

import funkin.game.modchart.modifiers.*;
import funkin.game.modchart.events.*;

// Weird amalgamation of Schmovin' modifier system, Andromeda modifier system and my own new shit -neb
// todo more safety this crashes too easily //still to do aha..
class ModManager implements IFlxDestroyable
{
	/**
	 * Essential mods for regular play
	 */
	public function registerEssentialModifiers()
	{
		quickRegister(new ReverseModifier(this));
		quickRegister(new ConfusionModifier(this));
		quickRegister(new PerspectiveModifier(this));
		quickRegister(new OpponentModifier(this)); // ur not that essential...
	}
	
	public function registerDefaultModifiers()
	{
		// registerEssentialModifiers();
		
		final quickRegs:Array<Class<NoteModifier>> = [
			//----------------
			
			FlipModifier,
			InvertModifier,
			DrunkModifier,
			BeatModifier,
			AlphaModifier,
			ReceptorScrollModifier,
			ScaleModifier,
			TransformModifier,
			InfinitePathModifier,
			AccelModifier,
			XModifier
		];
		
		for (mod in quickRegs)
			quickRegister(Type.createInstance(mod, [this]));
			
		quickRegister(new RotateModifier(this));
		quickRegister(new RotateModifier(this, 'center', Vector3.get(FlxG.width * 0.5, FlxG.height * 0.5)));
		quickRegister(new LocalRotateModifier(this, 'local'));
		quickRegister(new SubModifier("noteSpawnTime", this));
		setValue("noteSpawnTime", 2000);
		setValue("xmod", 1);
		for (i in 0...PlayState.SONG.keys)
			setValue('xmod$i', 1);
	}
	
	public function registerScriptedModifiers()
	{
		for (file in Paths.listAllFilesInDirectory('scripts/modifiers').filter(path -> funkin.scripts.FunkinScript.isHxFile(path)))
		{
			var name = file.withoutDirectory().withoutExtension();
			
			quickRegister(new ScriptedModifier(this, name));
			
			Logger.log('Registered scripted modifier: $name');
		}
	}
	
	private var state:MusicBeatState;
	
	public var lanes:Int = 2;
	public var keys:Int = 4;
	public var receptors:Array<Array<StrumNote>> = []; // for modifiers to be able to access receptors directly if they need to
	public var timeline:EventTimeline = new EventTimeline();
	
	public var notemodRegister:Map<String, Modifier> = [];
	public var miscmodRegister:Map<String, Modifier> = [];
	
	public var register:Map<String, Modifier> = [];
	
	public var modArray:Array<Modifier> = [];
	
	public var activeMods:Array<Array<String>> = [[], []]; // by player
	
	inline public function quickRegister(mod:Modifier) registerMod(mod.getName(), mod);
	
	public function registerMod(modName:String, mod:Modifier, registerSubmods:Bool = true)
	{
		final isNoteMod:Bool = (mod.getModType() == NOTE_MOD);
		final modRegister:Map<String, Modifier> = (isNoteMod ? notemodRegister : miscmodRegister);
		
		if (modRegister.exists(modName)) return Logger.log('Modifier "$modName" is already registered', WARN);
		
		modRegister.set(modName, mod);
		
		register.set(modName, mod);
		timeline.addMod(modName);
		modArray.push(mod);
		
		if (registerSubmods)
		{
			for (name in mod.submods.keys())
			{
				var submod = mod.submods.get(name);
				quickRegister(submod);
			}
		}
		
		setValue(modName, 0); // so if it should execute it gets added Automagically
		modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
		// TODO: sort by mod.getOrder()
	}
	
	inline public function get(modName:String) return register.get(modName);
	
	inline public function getPercent(modName:String, player:Int) return register.get(modName).getPercent(player);
	
	inline public function getValue(modName:String, player:Int) return register.get(modName).getValue(player);
	
	inline public function setPercent(modName:String, val:Float, player:Int = -1) setValue(modName, val / 100, player);
	
	public function setValue(modName:String, val:Float, player:Int = -1)
	{
		if (player == -1)
		{
			for (pN in 0...lanes)
				setValue(modName, val, pN);
		}
		else
		{
			var daMod = register.get(modName);
			if (daMod == null)
			{
				FlxG.log.error('mod [$modName] is not real or was not registered');
				// idk add a error u tried using a not real mod
				return;
			}
			
			var mod = daMod.parent == null ? daMod : daMod.parent;
			var name = mod.getName();
			// optimization shit!! :)
			// thanks 4mbr0s3 for giving an alternative way to do all of this cus andromeda has smth similar in Flexy but like
			// this is a better way to do it
			// (ofc its not EXACTLY what 4mbr0s3 did but.. y'know, it's close to it)
			
			// so this actually has an issue
			// this doesnt take into account any other submods
			// so if you turn a submod off
			// it turns the parent mod off, too, when it shouldnt
			// so what I need to do is like, check other submods before removing the parent
			
			if (activeMods[player] == null) activeMods[player] = [];
			
			register.get(modName).setValue(val, player);
			
			if (!activeMods[player].contains(name) && mod.shouldExecute(player, val))
			{
				if (daMod.getName() != name) activeMods[player].push(daMod.getName());
				activeMods[player].push(name);
			}
			else if (!mod.shouldExecute(player, val))
			{
				// there is prob a better way to do this
				// i just dont know it
				var modParent = daMod.parent;
				if (modParent == null)
				{
					for (name => mod in daMod.submods)
					{
						modParent = daMod; // because if this gets called at all, there's atleast 1 submod!!
						break;
					}
				}
				if (daMod != modParent) activeMods[player].remove(daMod.getName());
				if (modParent != null)
				{
					if (modParent.shouldExecute(player, modParent.getValue(player)))
					{
						activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
						return;
					}
					for (subname => submod in modParent.submods)
					{
						if (submod.shouldExecute(player, submod.getValue(player)))
						{
							activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
							return;
						}
					}
					activeMods[player].remove(modParent.getName());
				}
				else activeMods[player].remove(daMod.getName());
			}
			
			activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
		}
	}
	
	public function new(state:MusicBeatState)
	{
		this.state = state;
	}
	
	public function update(elapsed:Float)
	{
		for (mod in modArray)
		{
			if (mod.active && mod.doesUpdate()) mod.update(elapsed);
		}
	}
	
	public function updateTimeline(curStep:Float) timeline.update(curStep);
	
	public function getBaseX(direction:Int, player:Int):Float
	{
		var x:Float = (FlxG.width * 0.5) + Note.swagWidth * (direction - (keys / 2) + .5) - 3;
		switch (player)
		{
			case 0:
				x += FlxG.width * 0.5 - Note.swagWidth * (keys / 2) - 100;
			case 1:
				x -= FlxG.width * 0.5 - Note.swagWidth * (keys / 2) - 100;
		}
		
		return x;
	}
	
	public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int)
	{
		final note:Note = (obj is Note ? cast obj : null);
		
		obj.x = (pos.x - obj.width * .5);
		
		if (note != null && note.isSustainNote)
		{
			note.y = pos.y;
		}
		else
		{
			obj.y = (pos.y - obj.height * .5);
		}
		
		if (activeMods[player] != null)
		{
			for (name in activeMods[player])
			{
				var mod:Modifier = notemodRegister.get(name);
				if (mod == null || !obj.active) continue;
				
				if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
				else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
				else if (obj is NoteSplash) mod.updateNoteSplash(beat, cast obj, pos, player);
				else if (obj is SustainSplash) mod.updateSustainSplash(beat, cast obj, pos, player);
			}
		}
		
		obj.centerOrigin();
		obj.centerOffsets();
		
		if (note != null)
		{
			if (note.isSustainNote) note.origin.y = note.offset.y = 0;
			
			note.spriteOffset.x = note.typeOffsetX;
			note.spriteOffset.y = note.typeOffsetY;
		}
	}
	
	public inline function getBaseVisPosD(diff:Float, songSpeed:Float = 1)
	{
		return (0.45 * (diff) * songSpeed);
	}
	
	public inline function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1)
	{
		return -getBaseVisPosD(songPos - strumTime, songSpeed);
	}
	
	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3
	{
		if (pos == null) pos = Vector3.get();
		
		if (!obj.active) return pos;
		
		pos.x = getBaseX(data, player);
		pos.y = (50 + diff + Note.swagWidth * .5);
		pos.z = 0;
		
		if (activeMods[player] != null)
		{
			for (name in activeMods[player])
			{
				if (!obj.active || exclusions?.contains(name)) continue; // because some modifiers may want the path without reverse, for example. (which is actually more common than you'd think!)
				
				var mod:Modifier = notemodRegister.get(name);
				if (mod == null) continue;
				
				pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
			}
		}
		
		return pos;
	}
	
	public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1,
			?startVal:Float) queueEase(step, endStep, modName, percent * 0.01, style, player, startVal * 0.01);
			
	public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) queueSet(step, modName, percent * 0.01, player);
	
	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
	{
		if (player == -1)
		{
			for (p in 0...lanes)
			{
				queueEase(step, endStep, modName, target, style, p, startVal);
			}
		}
		else
		{
			final easeFunc = CoolUtil.getEaseFromString(style);
			
			timeline.addEvent(new EaseEvent(step, endStep, modName, target, easeFunc, player, this, startVal));
		}
	}
	
	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1)
	{
		if (player == -1)
		{
			for (p in 0...lanes)
			{
				queueSet(step, modName, target, p);
			}
		}
		else timeline.addEvent(new SetEvent(step, modName, target, player, this));
	}
	
	public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
	{
		timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
	}
	
	public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void) timeline.addEvent(new CallbackEvent(step, callback, this));
	
	public function destroy():Void
	{
		modArray = FlxDestroyUtil.destroyArray(modArray);
	}
}
