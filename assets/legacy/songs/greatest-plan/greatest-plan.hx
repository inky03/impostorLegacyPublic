import funkin.utils.MathUtil;

function onLoad()
{
	mom = new Character(1110, 200, isStoryMode ? 'bf' : ClientPrefs.equipment.get('playerSkin') ?? 'bf', true);
	startCharacterPos(mom);
	stage.add(mom);
}

function onStartCountdown()
{
	triggerEventNote('Play Animation', 'intro', 'bf');
}

function onCreatePost()
{
	pauseOverwrite = 'henry';
	canFollow = false;
	boyfriend.setPosition(308, 200);
	dad.setPosition(-1200, 20);
	for (i in [boyfriend, dad])
	{
		startCharacterPos(i); // better than a whole ass stage thats exactly like henry.
	}
	playHUD.iconP1.changeIcon(mom.healthIcon);
	playHUD.iconP2.changeIcon('henry');
	playHUD.healthBar.setColors(0xFFbdd7d8, mom.healthColour);
	if (hasColor) playHUD.scoreTxt.color = boyfriend.healthColour;
	
	pet.zIndex = 1;
	refreshZ();
}

function onEvent(name, v1, v2)
{
	switch (v1)
	{
		case 'p1':
			camSpecialThing([130, 450], [130, 450], 1.3);
			
		case 'bf':
			playHUD.iconP1.changeIcon('henry');
			playHUD.iconP2.changeIcon(mom.healthIcon);
			playHUD.healthBar.setColors(mom.healthColour, 0xFFbdd7d8);
			if (hasColor) playHUD.scoreTxt.color = boyfriend.healthColour;
			// healthBar.createColoredEmptyBar(0xFF31b0d1);
		
		case 'charles':
			playHUD.iconP2.changeIcon('charles');
			playHUD.healthBar.setColors(0xFFff3333, 0xFFbdd7d8);
			if (hasColor) playHUD.scoreTxt.color = dad.healthColour;
			// healthBar.createColoredEmptyBar(0xFFff3333);
		
		case 'zoom':
			camGame.zoom += .2;
		
		case 'enter':
			FlxTween.tween(dad, {x: -380}, 4, {ease: FlxEase.expoOut});
			pauseOverwrite = 'charles';
	}
}
