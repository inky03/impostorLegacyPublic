package funkin.game;

import funkin.objects.note.*;

class Rating
{
	public static function judgeNote(note:Note, diff:Float = 0):Null<Rating>
	{
		final data:Null<Array<Rating>> = PlayState.instance?.ratingsData;
		
		if (data == null) return null;
		
		switch (note.noteType)
		{ // custom notetypes get custom ways of being judged
			// case "mine": // example case, replace if needed
			default:
				// hey NVE devs, i think you could call noteScript.executeFunc("onJudgeNote", [diff]) here
				// just in case other notetypes need to change how they are judged
				// up to you, though @crowplexus
				for (i in 0...data.length - 1)
					if (diff <= data[i].hitWindow) return data[i];
		}
		return data[data.length - 1];
	}
	
	/**
	 * Same as `Rating.judgeNote` but only judges a window of time
	 *
	 * e.g: try 22.5 to get an Epic
	**/
	public static function judgeTime(time:Float = 0):Null<Rating>
	{
		final data = PlayState.instance?.ratingsData;
		if (data == null) return null;
		
		for (i in 0...data.length - 1)
			if (time <= data[i].hitWindow) return data[i];
		return data[data.length - 1];
	}
	
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Float> = 0; // ms
	public var noteSplash:Bool = true;
	public var ratingMod:Float = 1;
	public var healthMod:Float = 1;
	public var score:Int = 350;
	
	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = Reflect.field(ClientPrefs, name + 'Window');
		if (hitWindow == null) hitWindow = 0;
		
		setup();
	}
	
	public function increase(map:Map<String, Int>, mod:Int = 1):Void
	{
		map.set(name, (map.get(name) ?? 0) + mod);
	}
	
	function setup()
	{
		switch (name)
		{
			case 'epic':
				score = 350;
				ratingMod = 1;
				noteSplash = true;
				
			case 'sick':
				score = 350;
				ratingMod = 1;
				noteSplash = true;
				
			case 'good':
				score = 200;
				ratingMod = .7;
				noteSplash = false;
				
			case 'bad':
				score = 100;
				ratingMod = .4;
				healthMod = -.5;
				noteSplash = false;
				
			case 'shit':
				score = 50;
				ratingMod = 0;
				healthMod = -3;
				noteSplash = false;
		}
	}
}
