package funkin.game.modchart;

import funkin.game.modchart.events.ModEvent;
import funkin.game.modchart.events.BaseEvent;

class EventTimeline
{
	public var modEvents:Map<String, Array<ModEvent>> = [];
	public var events:Array<BaseEvent> = [];
	
	public function new() {}
	
	public function addMod(modName:String) modEvents.set(modName, []);
	
	public function addEvent(event:BaseEvent)
	{
		if ((event is ModEvent))
		{
			var modEvent:ModEvent = cast event;
			var name = modEvent.modName;
			if (!modEvents.exists(name)) addMod(name);
			
			if (!modEvents.get(name).contains(modEvent)) modEvents.get(name).push(modEvent);
			
			modEvents.get(name).sort((a, b) -> Std.int(a.executionStep - b.executionStep));
		}
		else if (!events.contains(event))
		{
			events.push(event);
			events.sort((a, b) -> Std.int(a.executionStep - b.executionStep));
		}
	}
	
	inline function updateSchedule(schedule:Array<BaseEvent>, step:Float):Void
	{
		var i:Int = 0;
		
		while (i < schedule.length)
		{
			final event:BaseEvent = schedule[i];
			
			if (event.finished)
			{
				schedule.remove(event);
				continue;
			}
			
			if (event.ignoreExecution)
			{
				i ++;
				continue;
			}
			
			if (step >= event.executionStep)
			{
				event.run(step);
				
				if (event.finished)
				{
					schedule.remove(event);
				}
				else i ++;
			}
			else break;
		}
	}
	
	public inline function update(step:Float)
	{
		for (modName in modEvents.keys())
		{
			updateSchedule(cast modEvents.get(modName), step);
		}
		
		updateSchedule(events, step);
	}
}
