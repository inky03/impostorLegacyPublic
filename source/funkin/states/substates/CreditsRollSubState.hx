package funkin.states.substates;

class CreditsRollSubState extends funkin.backend.MusicBeatSubstate
{
	public var canSkip:Bool = false;
	
	public var onSkip:Void->Void = null;
	public var onFinish:Void->Void = null;
	
	public var camCredits:FunkinCamera;
	
	public function new(skippable:Bool = false, ?onFinish:Void->Void, ?onSkip:Void->Void)
	{
		super();
		
		this.bgColor = FlxColor.BLACK;
		
		this.canSkip = skippable;
		this.onFinish = onFinish;
		this.onSkip = onSkip;
	}
	
	public override function create():Void
	{
		super.create();
		
		FlxG.cameras.add(camera = camCredits = new FunkinCamera(), false);
		camCredits.bgColor = 0;
		
		initStateScript();
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (controls.BACK && canSkip)
		{
			if (onSkip != null) onSkip();
			
			close();
		}
		
		scriptGroup.call('onUpdatePost', [elapsed]);
	}
	
	public override function destroy():Void
	{
		FlxG.cameras.remove(camCredits);
		
		super.destroy();
	}
}
