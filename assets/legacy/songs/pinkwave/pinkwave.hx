function onCreatePost()
{
	pretenderDark = add(new flixel.system.FlxBGSprite());
	pretenderDark.color = FlxColor.BLACK;
	pretenderDark.kill();
	
	if (isStoryMode) songEndCallback = pretender;
}

function onLoad() readDialogue();

function pretender()
{
	inCutscene = true;
	triggerEventNote('Camera Follow Pos', 400, 150);
	canPause = false;
	camZooming = true;
	
	for (i in [tomato, longus, greymira, ventNotSus, pretenderDark])
	{
		i.animation.play('anim', true);
	}
	
	if (ClientPrefs.flashing)
	{
		pretenderDark.revive();
		pretenderDark.alpha = 0;
		pretenderDark.color = FlxColor.BLACK;
		
		for (t in [81, 83, 92, 94, 96, 98, 100]) {
			FlxTimer.wait(t / 24, () -> pretenderDark.alpha = 1);
			FlxTimer.wait((t + 1) / 24, () -> pretenderDark.alpha = 0);
		}
		
		FlxTimer.wait(102 / 24, () -> {
			pretenderDark.color = FlxColor.WHITE;
			pretenderDark.alpha = 1;
			
			FlxTween.color(pretenderDark, 4 / 24, FlxColor.WHITE, FlxColor.BLACK);
		});
	}
	else
	{
		FlxTimer.wait(102 / 24, () -> pretenderDark.revive());
	}
	FlxG.sound.play(Paths.sound('stage/pretender_kill'));
	defaultCamZoom = 0.75;
	
	FlxTween.tween(camHUD, {alpha: 0}, 0.4);
	FlxTween.tween(gf, {alpha: 0.1}, 0.4);
	FlxTween.tween(dad, {alpha: 0.25}, 0.4);
	FlxTween.tween(boyfriend, {alpha: 0.25}, 0.4);
	
	new FlxTimer().start(9, function(tmr:FlxTimer) {
		endSong();
	});
}
