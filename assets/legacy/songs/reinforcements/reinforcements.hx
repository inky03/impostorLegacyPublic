var ext = 'stages/henry/';
var armedGuy:FlxSprite;

function onLoad()
{
	if (PlayState.isStoryMode)
	{
		armedGuy = new FlxSprite(-800, -300);
		armedGuy.frames = Paths.getSparrowAtlas(ext + 'i_schee_u_enry');
		armedGuy.animation.addByPrefix('crash', 'rhm intro shadow', 16, false);
		armedGuy.antialiasing = true;
		armedGuy.visible = false;
		songEndCallback = iSeeYouEnry;
	}
}

function onCreatePost()
{
	pauseOverwrite = 'henry';
	addMomChar('ellie', [-60, 210], [dadGroup, 1]);
	mom.visible = false;
}

function iSeeYouEnry()
{
	canPause = false;
	inCutscene = true;
	FlxTween.tween(camHUD, {alpha: 0}, 0.4);
	FlxG.sound.play(Paths.sound('stage/rhm_crash'));
	dad.playAnim('armed');
	dad.specialAnim = true;
	mom.playAnim('armed');
	mom.specialAnim = true;
	triggerEventNote('Optional Captions', 'rhm', '630'); // i fixed it
	
	new FlxTimer().start(2.1, function(tmr:FlxTimer) {
		if (ClientPrefs.flashing) camGame.shake(0.005, 0.9);
	});
	
	new FlxTimer().start(2.8, function(tmr:FlxTimer) {
		armedGuy.alpha = 1;
		armedGuy.animation.play('crash');
	});
	new FlxTimer().start(3, function(tmr:FlxTimer) {
		camGame.alpha = 0;
		camOther.flash(FlxColor.WHITE, 3);
		triggerEventNote('Optional Captions', '0', '0');
	});
	new FlxTimer().start(6, function(tmr:FlxTimer) {
		endSong();
	});
}
