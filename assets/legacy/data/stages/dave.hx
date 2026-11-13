var daveDIE:FlxSprite;
var ext:String = 'stages/freeplay/dave/';

function onLoad()
{
	var bg:FlxSprite = add(new FlxSprite().loadGraphic(Paths.image(ext + 'DAVE')));
	daveDIE = add(new FlxSprite(0, 455).loadGraphic(Paths.image(ext + 'hole')));
	daveDIE.alpha = .001;
	
	Paths.sound('stage/davewindowsmash');
}

function onCreatePost()
{
	snapCamToPos(900, 720);
	camSpecialThing([820, 710], [980, 730], 0.8); // bf cam pos is different for the same reason picos is in drippypop
}

function onEvent(eventName, value1, value2)
{
	switch (eventName)
	{
		case 'Le Window':
			dad.playAnim('die');
			dad.canDance = false;
			
		case 'Dave AUGH':
			daveDIE.alpha = 1;
			dad.alpha = 0;
			FlxG.sound.play(Paths.sound('stage/davewindowsmash'));
			if (ClientPrefs.flashing) FlxG.camera.shake(0.02, 0.3, null, true, FlxAxes.XY);
	}
}
