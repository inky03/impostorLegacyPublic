package funkin.game.modchart.modifiers;

import flixel.math.FlxPoint;

class ScaleModifier extends NoteModifier
{
	override function getName() return 'mini';
	
	override function getOrder() return PRE_REVERSE;
	
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	inline function getScale(prefix:String, sprite:FunkinSprite, scale:FlxPoint, data:Int, player:Int):FlxPoint
	{
		var isSus:Bool = false;
		
		if (sprite is Note) {
			final note:Note = cast sprite;
			isSus = (note.isSustainNote && !note.isSustainEnd);
		}
		
		final squish = lerp(1, 2, getSubmodValue("squish", player) + getSubmodValue('squish${data}', player));
		final stretch = lerp(1, .5, getSubmodValue("stretch", player) + getSubmodValue('stretch${data}', player));
		
		if (isSus)
		{
			scale.y = sprite.baseScale.y;
		}
		else
		{
			scale.y *= (1 - getValue(player));
			scale.y *= (1 - getSubmodValue('miniY', player));
			scale.y *= (1 - getSubmodValue('mini${data}Y', player));
			scale.y *= (1 - getSubmodValue('$prefix${data}ScaleY', player));
			
			scale.y /= squish;
			scale.y /= stretch;
		}
		
		scale.x *= (1 - getValue(player));
		scale.x *= (1 - getSubmodValue('miniX', player));
		scale.x *= (1 - getSubmodValue('mini${data}X', player));
		scale.x *= (1 - getSubmodValue('$prefix${data}ScaleX', player));
		
		scale.x *= squish;
		scale.x *= stretch;
		
		return scale;
	}
	
	function getObjectScale(obj:ModchartNote, prefix:String, player:Int):FlxPoint
	{
		if (getSubmodValue('${prefix}ScaleX', player) > 0 || getSubmodValue('${prefix}ScaleY', player) > 0)
		{
			var scaleX = getSubmodValue('${prefix}ScaleX', player);
			var scaleY = getSubmodValue('${prefix}ScaleY', player);
			if (scaleX == 0) scaleX = obj.baseScale.x;
			if (scaleY == 0) scaleY = obj.baseScale.y;
			
			return getScale(prefix, obj, FlxPoint.weak(scaleX, scaleY), obj.noteData, player);
		}
		
		return getScale(prefix, obj, FlxPoint.weak(obj.baseScale.x, obj.baseScale.y), obj.noteData, player);
	}
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		note.scale.copyFrom(getObjectScale(note, 'note', player));
	}
	
	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		receptor.scale.copyFrom(getObjectScale(receptor, 'receptor', player));
	}
	
	override function updateNoteSplash(beat:Float, splash:NoteSplash, pos:Vector3, player:Int)
	{
		splash.scale.copyFrom(getObjectScale(splash, 'noteSplash', player));
	}
	
	override function updateSustainSplash(beat:Float, splash:SustainSplash, pos:Vector3, player:Int)
	{
		splash.scale.copyFrom(getObjectScale(splash, 'sustainSplash', player));
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"squish",
			"stretch",
			"miniX",
			"miniY",
			"receptorScaleX",
			"receptorScaleY",
			"noteScaleX",
			"noteScaleY",
			"noteSplashScaleX",
			"noteSplashScaleY",
			"sustainSplashScaleX",
			"sustainSplashScaleY"
		];
		
		var receptors = modMgr.receptors[0];
		var kNum = receptors.length;
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('mini${i}X');
			subMods.push('mini${i}Y');
			subMods.push('squish${i}');
			subMods.push('stretch${i}');
			subMods.push('receptor${i}ScaleX');
			subMods.push('receptor${i}ScaleY');
			subMods.push('note${i}ScaleX');
			subMods.push('note${i}ScaleY');
			subMods.push('noteSplash${i}ScaleX');
			subMods.push('noteSplash${i}ScaleY');
			subMods.push('sustainSplash${i}ScaleX');
			subMods.push('sustainSplash${i}ScaleY');
		}
		return subMods;
	}
}
