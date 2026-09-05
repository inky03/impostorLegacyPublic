using StringTools;

var ext:String = 'stages/freeplay/attack/';
var peopleloggo:FlxSprite;
var crowd:FlxSprite;
var nickt:FlxSprite;
var offbi:FlxSprite;
var orbyy:FlxSprite;
var cooper:FlxSprite;
var biddle:Character;

function onLoad()
{
	var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'monotoneback'));
	add(bg);
	
	crowd = new FlxSprite(850, 850);
	crowd.frames = Paths.getSparrowAtlas(ext + 'crowd');
	crowd.animation.addByPrefix('bop', 'tess n gus fring instance 1', 24, false);
	crowd.animation.play('bop');
	add(crowd);
	
	var fg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'fg'));
	add(fg);
	
	nickt = new FlxSprite(600, 700);
	nickt.frames = Paths.getSparrowAtlas(ext + 'nick t');
	nickt.animation.addByPrefix('bop', 'nick t idle', 24, false);
	nickt.animation.addByPrefix('okay', 'nick t animation', 24, false);
	nickt.animation.play('bop');
	nickt.animation.onFinish.add((animName) -> {
		if (animName == 'okay')
		{
			nickt.animation.play('bop', true);
		}
	});
	nickt.animation.onFrameChange.add((animName) -> {
		switch (animName)
		{
			case 'bop':
				nickt.offset.set(0, 0);
			case 'shutup':
				nickt.offset.set(-4, -2);
		}
	});
	add(nickt);
	
	offbi = new FlxSprite(1250, 625);
	offbi.frames = Paths.getSparrowAtlas(ext + 'offbi');
	offbi.animation.addByPrefix('bop', 'offbi', 24, false);
	offbi.animation.play('bop');
	add(offbi);
	
	orbyy = new FlxSprite(850, 629);
	orbyy.frames = Paths.getSparrowAtlas(ext + 'neworbyy');
	orbyy.animation.addByPrefix('bop', 'idle', 24, false);
	orbyy.animation.addByPrefix('shutup', 'shutup', 24, false);
	// I don't like this method but Idk if theres a better way
	orbyy.animation.onFinish.add((animName) -> {
		if (animName == 'shutup')
		{
			orbyy.animation.play('bop', true);
		}
	});
	orbyy.animation.onFrameChange.add((animName) -> {
		switch (animName)
		{
			case 'bop':
				orbyy.offset.set(0, 0);
			case 'shutup':
				orbyy.offset.set(129, 2);
		}
	});
	orbyy.animation.play('bop');
	add(orbyy);
	
	loggo = new FlxSprite(950, 775);
	loggo.frames = Paths.getSparrowAtlas(ext + 'loggoattack');
	loggo.animation.addByPrefix('bop', 'loggfriend', 24, false);
	loggo.animation.play('bop');
	add(loggo);
	
	cooper = new FlxSprite(1950, 750);
	cooper.frames = Paths.getSparrowAtlas(ext + 'cooper');
	cooper.animation.addByPrefix('bop', 'bg seat 1 instance 1', 24, false);
	cooper.animation.play('bop');
	add(cooper);
	
	biddle = new Character(1590, 445, 'biddle', true);
	game.startCharacterPos(biddle);
	add(biddle);
	
	var backlights:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'backlights'));
	backlights.blend = 0;
	add(backlights);
	
	var lamp:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'lamp'));
	add(lamp);
}

function onUpdatePost()
{
	if (ClientPrefs.inDevMode)
	{
		if (showDevInfo) dbText = dbText + '\nPress 1,2,4,5 to switch Monototone Attack character';
		if (FlxG.keys.justPressed.ONE)
		{
			PlayState.attackCharacter = 0;
			FlxG.resetState();
		}
		if (FlxG.keys.justPressed.TWO)
		{
			PlayState.attackCharacter = 1;
			FlxG.resetState();
		}
		if (FlxG.keys.justPressed.FOUR)
		{
			PlayState.attackCharacter = 2;
			FlxG.resetState();
		}
		if (FlxG.keys.justPressed.FIVE)
		{
			PlayState.attackCharacter = 3;
			FlxG.resetState();
		}
	}
}

function postModifierRegister():Void
{
	game.playFields.members[2].owner = game.gf;
	game.playFields.members[3].owner = biddle;
	
	for (i in playFields.members)
	{
		final player:Bool = (i.ID == PlayState.attackCharacter);
		final orgID = (3 - i.ID);
		final wrap = Math.floor(orgID / 2) == Math.floor((3 - PlayState.attackCharacter) / 2);
		
		i.isPlayer = i.playerControls = i.noteSplashes = player;
		i.autoPlayed = !player;
		
		if (ClientPrefs.middleScroll) continue;
		
		if (wrap)
		{
			i.zIndex = 999;
			
			if (i.ID >= 2 && !ClientPrefs.middleScroll) modManager.setValue("transformX", 315 * (i.ID == 2 ? -1 : 1), i.ID);
		}
		else
		{
			i.underlay.kill();
			
			modManager.setValue("noteAlpha", 1, i.ID);
			modManager.setValue("alpha", 0.7, i.ID);
			modManager.setValue("stealth", 0.5, i.ID);
			modManager.setValue("transformZ", -1, i.ID);
			modManager.setValue("transformY", -90 * (ClientPrefs.downScroll ? -1 : 1), i.ID);
			modManager.setValue("stealthPastReceptors", 1, i.ID);
			
			if (i.ID >= 2)
			{
				final space = 865;
				// modManager.setValue("opponentSwap", 0.5, i.ID);
				modManager.setValue("transformX", i.ID == 2 ? -(space) : space, i.ID);
			}
			else modManager.setValue("opponentSwap", -0.85, i.ID);
		}
	}
	
	refreshZ(playFields);
	
	if (PlayState.attackCharacter >= 2)
	{
		iconP2.changeIcon('fabs');
		iconP1.changeIcon('biddle');
		
		FlxG.signals.postUpdate.addOnce(function() {
			healthBar.setColors(gf.healthColour, biddle.healthColour);
		});
	}
	
	if (PlayState.attackCharacter == 1 || PlayState.attackCharacter == 2)
	{
		healthBar.leftToRight = true;
		iconP1.flipX = !iconP1.flipX;
		iconP2.flipX = !iconP2.flipX;
		switch (PlayState.attackCharacter)
		{
			case 1:
				iconP1.changeIcon('attack');
				iconP2.changeIcon('bfclow');
			case 2:
				iconP1.changeIcon('fabs');
				iconP2.changeIcon('biddle');
		}
	}
}

function onSpawnNotePost(note)
{
	final orgID = (3 - note.player);
	final wrap = Math.floor(orgID / 2) == Math.floor((3 - PlayState.attackCharacter) / 2);
	
	note.zIndex = wrap ? 999 : 0;
	refreshZ(notes);
}

function onCreatePost()
{
	var lightoverlay:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'frontlight'));
	lightoverlay.antialiasing = ClientPrefs.globalAntialiasing;
	lightoverlay.blend = 0;
	add(lightoverlay);
	
	var purple:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'purple'));
	purple.antialiasing = ClientPrefs.globalAntialiasing;
	add(purple);
	
	camCurTarget = game.gf;
	
	snapCamToPos(1185, 1025);
}

function onEndSong()
{
	// trace(PlayState.attackCharacter);
	GameFlags.giveFlag(Std.string(PlayState.attackCharacter));
	
	var hasAll:Bool = true;
	for (i in 0...4)
	{
		if (!GameFlags.hasFlag(Std.string(i)))
		{
			hasAll = false;
			break;
		}
	}
	
	if (hasAll)
	{
		game.unlockAchievementPopup('all_four');
	}
	
	return 0;
}

function onCountdownStarted()
{
	var fakeStartTimer = new FlxTimer().start((Conductor.crotchet / 1000) / playbackRate, function(tmr:FlxTimer) {
		biddle.onBeatHit(tmr.loopsLeft);
		if (tmr.loopsLeft % 2 == 0)
		{
			cooper.animation.play('bop', true);
			crowd.animation.play('bop', true);
			nickt.animation.play('bop', true);
		}
		if (tmr.loopsLeft % 2 == 1)
		{
			offbi.animation.play('bop', true);
			orbyy.animation.play('bop', true);
			loggo.animation.play('bop', true);
		}
	}, 5);
}

function onBeatHit()
{
	if (curBeat % 2 == 0)
	{
		cooper.animation.play('bop', true);
		crowd.animation.play('bop', true);
		if (nickt.animation.curAnim.name != 'okay') nickt.animation.play('bop', true);
	}
	else if (curBeat % 2 == 1)
	{
		offbi.animation.play('bop', true);
		if (orbyy.animation.curAnim.name != 'shutup') orbyy.animation.play('bop', true);
		loggo.animation.play('bop', true);
	}
	
	biddle.onBeatHit(curBeat);
}

function onEvent(eventName, value1, value2)
{
	if (eventName == 'Attack Events')
	{
		switch (value1)
		{
			case 'force camera':
				switch (value2)
				{
					case 'fabs':
						camCurTarget = game.gf;
					case 'biddle':
						camCurTarget = biddle;
					default:
						camCurTarget = null;
				}
			case 'orbyy':
				orbyy.animation.play('shutup', true);
			case 'forehead':
				nickt.animation.play('okay', true);
				FlxTween.tween(orbyy, {alpha: 0.1}, 0.4);
				FlxTween.tween(offbi, {alpha: 0.1}, 0.4);
				FlxTween.tween(loggo, {alpha: 0.1}, 0.4);
				FlxTween.tween(gf, {alpha: 0.1}, 0.4);
				FlxTween.tween(biddle, {alpha: 0.1}, 0.4);
				FlxTween.tween(dad, {alpha: 0.25}, 0.4);
				FlxTween.tween(boyfriend, {alpha: 0.25}, 0.4);
			case 'forehead after':
				FlxTween.tween(orbyy, {alpha: 1}, 0.4);
				FlxTween.tween(offbi, {alpha: 1}, 0.4);
				FlxTween.tween(loggo, {alpha: 1}, 0.4);
				FlxTween.tween(gf, {alpha: 1}, 0.4);
				FlxTween.tween(biddle, {alpha: 1}, 0.4);
				FlxTween.tween(dad, {alpha: 1}, 0.4);
				FlxTween.tween(boyfriend, {alpha: 1}, 0.4);
		}
	}
}
