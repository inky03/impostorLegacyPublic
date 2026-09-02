package funkin.game.modchart.modifiers;

import funkin.backend.math.Vector3;

class ReverseModifier extends NoteModifier
{
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getOrder() return REVERSE;
	
	override function getName() return 'reverse';
	
	public inline function getReverseValue(dir:Int, player:Int, scrolling:Bool = false)
	{
		final suffix:String = (scrolling ? 'Scroll' : '');
		
		final keys:Int = modMgr.receptors[player].length;
		var val:Float = 0;
		
		if (dir >= keys / 2) val += getSubmodValue("split" + suffix, player);
		if (dir % 2 == 1) val += getSubmodValue("alternate" + suffix, player);
		if (dir >= keys / 4 && dir <= keys * 3 / 4 - 1) val += getSubmodValue("cross" + suffix, player);
		
		if (!scrolling) val += getValue(player) + getSubmodValue("reverse" + Std.string(dir), player);
		else val += getSubmodValue("reverse" + suffix, player);
		
		if (getSubmodValue("unboundedReverse", player) == 0)
		{
			val %= 2;
			if (val > 1) val = 2 - val;
		}
		
		if (ClientPrefs.downScroll) val = 1 - val;
		
		return val;
	}
	
	public function getScrollReversePerc(dir:Int, player:Int) return getReverseValue(dir, player) * 100;
	
	override function shouldExecute(player:Int, val:Float) return true;
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		final swag:Float = (Note.swagWidth * .5);
		
		final perc:Float = getReverseValue(data, player);
		var shift:Float = MathUtil.scale(perc, 0, 1, 50 + swag, FlxG.height - 50 - swag);
		shift = MathUtil.scale(getSubmodValue("centered", player), 0, 1, shift, FlxG.height / 2);
		
		final mult:Float = MathUtil.scale(perc, 0, 1, 1, -1);
		pos.y = (shift + (visualDiff * mult));
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = [
			"cross",
			"split",
			"alternate",
			"reverseScroll",
			"crossScroll",
			"splitScroll",
			"alternateScroll",
			"centered",
			"unboundedReverse"
		];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('reverse${i}');
		}
		return subMods;
	}
}
