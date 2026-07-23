package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;

import funkin.data.Chart;
import funkin.data.Song;
import funkin.data.WeekData;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end

import openfl.utils.Assets as OpenFlAssets;

class HenryState extends MusicBeatState
{
	#if VIDEOS_ALLOWED
	var video:FunkinVideoSprite;
	
	var freezeFrame:FlxSprite;
	var grad:FlxSprite;
	
	var mic:FlxSprite;
	var stare:FlxSprite;
	var sock:FlxSprite;
	
	var canClick:Bool = false;
	var ext:String = 'stages/henry/cutscene/';
	var optionsObjs:Array<FlxSprite> = [];
	var objNames:Array<String> = ['mic', 'sock', 'stare'];
	
	override function create()
	{
		super.create();
		
		freezeFrame = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'finalframe'));
		freezeFrame.width = FlxG.width;
		freezeFrame.height = FlxG.height;
		freezeFrame.updateHitbox();
		freezeFrame.screenCenter();
		freezeFrame.visible = false;
		add(freezeFrame);
		
		grad = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'hguiofuhjpsod'));
		grad.width = FlxG.width;
		grad.height = FlxG.height;
		grad.updateHitbox();
		grad.screenCenter();
		grad.visible = false;
		add(grad);
		
		sock = new FlxSprite(0, 0);
		sock.frames = Paths.getSparrowAtlas(ext + 'Sock_Puppet_Option');
		sock.animation.addByPrefix('select', 'Sock Puppet Select', 24, false);
		sock.animation.addByPrefix('deselect', 'Sock Puppet', 24, false);
		
		stare = new FlxSprite(0, 0);
		stare.frames = Paths.getSparrowAtlas(ext + 'Stare_Down_Option');
		stare.animation.addByPrefix('select', 'Stare Down Select', 24, false);
		stare.animation.addByPrefix('deselect', 'Stare Down', 24, false);
		
		mic = new FlxSprite(0, 0);
		mic.frames = Paths.getSparrowAtlas(ext + 'Microphone_Option');
		mic.animation.addByPrefix('select', 'Microphone Select', 24, false);
		mic.animation.addByPrefix('deselect', 'Microphone', 24, false);
		
		var stupid:Int = 0;
		for (i in [mic, sock, stare])
		{
			i.scale.set(0.5, 0.5);
			i.updateHitbox();
			i.screenCenter();
			i.antialiasing = ClientPrefs.globalAntialiasing;
			i.visible = false;
			i.ID = stupid;
			
			if (i != stare) i.y -= FlxG.height * 0.15;
			add(i);
			
			stupid++; // this is fucking dumb
		}
		// obj specific position edits
		mic.x -= FlxG.width * 0.15;
		sock.x += FlxG.width * 0.15;
		stare.y += FlxG.height * 0.15;
		
		video = new FunkinVideoSprite(0, 0, false);
		video.onFormat(() -> {
			video.setGraphicSize(0, FlxG.height);
			video.antialiasing = ClientPrefs.globalAntialiasing;
			video.updateHitbox();
			video.screenCenter();
		});
		video.onStart(() -> {
			new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				// this is honestly really fucking stupid
				video.visible = true;
			});
		});
		add(video);
		video.onEnd(options, true);
		if (video.load(Paths.video(Paths.sanitize('henry/henryIntro')))) video.delayAndStart();
		
		optionsObjs = [mic, sock, stare];
	}
	
	var over:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (canClick)
		{
			for (i in [mic, sock, stare])
			{
				if (FlxG.mouse.overlaps(i))
				{
					if (!over)
					{
						over = true;
						FlxG.sound.play(Paths.sound('henrycutscene/' + objNames[i.ID]), 0.6);
						i.animation.play('select', true);
					}
					else if (FlxG.mouse.pressed)
					{
						fail(objNames[i.ID]);
					}
				}
				else
				{
					if (i.animation.curAnim != null) i.animation.play('deselect', true);
				}
			}
			
			if (!FlxG.mouse.overlaps(stare) && !FlxG.mouse.overlaps(mic) && !FlxG.mouse.overlaps(sock)) over = false; // i feel like this kind of sucks but whatever
		}
	}
	
	function fail(selection:String)
	{
		canClick = false;
		switch (selection)
		{
			case 'mic':
				FlxG.mouse.visible = false;
				video.onEnd(startWeek, true);
			default:
				video.onEnd(reset, true);
		}
		
		if (video.load(Paths.video(Paths.sanitize('henry/' + selection)))) video.delayAndStart();
	}
	
	function options():Void
	{
		freezeFrame.visible = true;
		grad.visible = true;
		video.visible = false;
		
		for (i in 0...objNames.length)
		{
			new FlxTimer().start(i + 1, function(tmr:FlxTimer) {
				optionsObjs[i].visible = true;
				FlxG.sound.play(Paths.sound('henrycutscene/' + objNames[i]), 0.6);
			});
		}
		
		new FlxTimer().start(3.25, function(tmr:FlxTimer) {
			canClick = true;
			FlxG.mouse.visible = true;
		});
	}
	
	function reset()
	{
		canClick = true;
		video.visible = false;
		for (i in [sock, stare, mic, freezeFrame, grad])
		{
			i.visible = true;
		}
	}
	#else
	override function create()
	{
		super.create();
		
		startWeek();
	}
	#end
	
	function startWeek():Void
	{
		WeekData.reloadWeekFiles(true);
		
		var henryWeek = WeekData.weeksLoaded.get('week9');
		
		if (henryWeek != null)
		{
			StoryMenuState.loadWeek(henryWeek);
		}
		else
		{
			trace('henry week doesnt exist ?');
			
			FlxG.switchState(StoryMenuState.new);
		}
	}
}
