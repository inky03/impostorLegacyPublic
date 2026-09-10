var ext = 'stages/mira/greenhouse/pretender/';
var cloud1:FlxSprite;
var cloud2:FlxSprite;
var cloud3:FlxSprite;
var cloud4:FlxSprite;
var cloudbig:FlxSprite;
var blueMira:FlxSprite;
var super2:FlxSprite;
var super2Tween:FlxTween;

function onLoad()
{
	var sky:FlxSprite = new FlxSprite(-1500, -800).loadGraphic(Paths.image(ext + 'bg sky'));
	sky.antialiasing = ClientPrefs.globalAntialiasing;
	add(sky);
	
	var sun:FlxSprite = new FlxSprite(0, -140).loadGraphic(Paths.image(ext + 'the sun'));
	sun.scrollFactor.set(0.8, 0.8);
	sun.blend = BlendMode.ADD;
	add(sun);
	
	var cloudfar:FlxSprite = new FlxSprite(-1300, -300).loadGraphic(Paths.image(ext + 'cloud fathest'));
	cloudfar.antialiasing = ClientPrefs.globalAntialiasing;
	add(cloudfar);
	
	var cloudfront:FlxSprite = new FlxSprite(-1300, -100).loadGraphic(Paths.image(ext + 'cloud front'));
	cloudfront.antialiasing = ClientPrefs.globalAntialiasing;
	add(cloudfront);
	
	cloud1 = new FlxBackdrop(Paths.image(ext + 'cloud 1'));
	cloud1.setPosition(0, -1200);
	cloud1.velocity.x = -9;
	add(cloud1);
	
	cloud2 = new FlxBackdrop(Paths.image(ext + 'cloud 2'));
	cloud2.setPosition(0, -1300);
	cloud2.velocity.x = (-9 * 3);
	add(cloud2);
	
	cloud3 = new FlxBackdrop(Paths.image(ext + 'cloud 3'));
	cloud3.setPosition(0, -1500);
	cloud3.velocity.x = (-9 * 2);
	add(cloud3);
	
	cloud4 = new FlxBackdrop(Paths.image(ext + 'cloud 4'));
	cloud4.setPosition(0, -1800);
	cloud4.velocity.x = (-9 * .1);
	add(cloud4);
	
	cloudbig = new FlxBackdrop(Paths.image(ext + 'bigcloud'));
	cloudbig.setPosition(0, -1300);
	cloudbig.velocity.x = (-9 * .5);
	add(cloudbig);
	
	var ground:FlxSprite = new FlxSprite(-1200, -750).loadGraphic(Paths.image(ext + 'ground'));
	ground.antialiasing = ClientPrefs.globalAntialiasing;
	add(ground);
	
	var plantfront:FlxSprite = new FlxSprite(-2, -680).loadGraphic(Paths.image(ext + 'front plant'));
	plantfront.antialiasing = ClientPrefs.globalAntialiasing;
	add(plantfront);
	
	var plant1:FlxSprite = new FlxSprite(1000, 190).loadGraphic(Paths.image(ext + 'knocked over plant'));
	plant1.antialiasing = ClientPrefs.globalAntialiasing;
	add(plant1);
	
	var plant2:FlxSprite = new FlxSprite(-800, 260).loadGraphic(Paths.image(ext + 'knocked over plant 2'));
	plant2.antialiasing = ClientPrefs.globalAntialiasing;
	add(plant2);
	
	var deadmungus:FlxSprite = new FlxSprite(950, 250).loadGraphic(Paths.image(ext + 'tomatodead'));
	deadmungus.antialiasing = ClientPrefs.globalAntialiasing;
	add(deadmungus);
	
	var ripbozo:FlxSprite = new FlxSprite(900, 500).loadGraphic(Paths.image(ext + 'ripbozo'));
	ripbozo.scale.set(0.6, 0.6); // accurate to his size
	ripbozo.updateHitbox();
	ripbozo.antialiasing = ClientPrefs.globalAntialiasing;
	add(ripbozo);
	
	var rhmdead:FlxSprite = new FlxSprite(1150, 630).loadGraphic(Paths.image(ext + 'rhm dead'));
	rhmdead.scrollFactor.set(1.1, 1);
	rhmdead.antialiasing = ClientPrefs.globalAntialiasing;
	add(rhmdead);
	
	bluemira = new FlxSprite(-1150, 400);
	bluemira.frames = Paths.getSparrowAtlas(ext + 'blued');
	bluemira.animation.addByPrefix('bop', 'bob bop', 24, false);
	bluemira.animation.play('bop');
	bluemira.scrollFactor.set(1.2, 1);
	bluemira.antialiasing = ClientPrefs.globalAntialiasing;
}

function onBeatHit()
{
	if (curBeat % 4 == 0)
	{
		bluemira.animation.play('bop');
		
		if (super2Tween != null) super2Tween.cancel();
		super2Tween = FlxTween.tween(super2, {alpha: 0.62}, 0.4, {ease: FlxEase.linear});
	}
	else if (curBeat % 4 == 2)
	{
		if (super2Tween != null) super2Tween.cancel();
		super2Tween = FlxTween.tween(super2, {alpha: 0.68}, 0.4, {ease: FlxEase.linear});
	}
}

function onStartCountdown()
{
	var fakeStartTimer = new FlxTimer().start((Conductor.crotchet / 1000) / playbackRate, function(tmr:FlxTimer) {
		if (tmr.loopsLeft % 2 == 0) bluemira.animation.play('bop');
	}, 5);
}

function onCreatePost()
{
	if (ClientPrefs.bfSkin == 'pinkplayable')
	{
		triggerEventNote('Change Character', 'dad', 'minigreyopscary');
		triggerEventNote('Change Character', 'boyfriend', 'pinkplayable');
		game.dad.x = -300;
		game.dad.y = 350;
	}
	if (ClientPrefs.gfSkin == 'blackspeaker')
	{
		triggerEventNote('Change Character', 'gf', 'blackspeaker');
		gf.flipX = true;
	}
	if (ClientPrefs.shaders)
	{
		var rimlightBase:ExtraDropShadowShader = new funkin.game.shaders.ExtraDropShadowShader();
		
		rimlightBase.setColorMatrix([
			 0.3,  0.2,    0, 0,  9,
			-0.5, 0.77,  0.2, 0, 13,
			   0, -0.1, 0.69, 0, 20,
			   0,    0,    0, 1,  0
		]);
		rimlightBase.threshold = .02;
		rimlightBase.strength = .7;
		rimlightBase.addLayer(rimlightBase.addLayer([
			1.5,  0,  0, 0, -8,
			  0, .8, .1, 0, 59,
			 .1,  0, .8, 0, 57,
			  0,  0,  0, 1,  0
		], 20, 25, .01).colorMatrix, 90, 15, .01);
		
		if (gf.getFlag('backlit') != true)
		{
			gfRim = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(rimlightBase);
			gfRim.layers[0].distance = gfRim.layers[1].distance = 20;
			gfRim.layers[0].angle = 60;
			gfRim.layers[1].angle = 120;
			gfRim.attachedSprite = gf;
			gf.useRenderTexture = true;
		}
		
		if (ClientPrefs.bfSkin == 'pinkplayable')
		{
			bfRim = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(rimlightBase);
			bfRim.layers[0].angle = 120;
			bfRim.layers[1].angle = 120;
			bfRim.attachedSprite = boyfriend;
			boyfriend.useRenderTexture = true;
		}
		if (dad.curCharacter == 'minigreyop')
		{
			dadRim = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(rimlightBase);
			dadRim.layers[0].angle = 120;
			dadRim.layers[1].angle = 120;
			dadRim.attachedSprite = dad;
			dad.useRenderTexture = true;
		}
	}
	var pot = new FlxSprite(-1550, 650).loadGraphic(Paths.image(ext + 'front pot'));
	pot.scrollFactor.set(1.2, 1);
	pot.antialiasing = ClientPrefs.globalAntialiasing;
	
	var vines = new FlxSprite(-1450, -700).loadGraphic(Paths.image(ext + 'green'));
	vines.scrollFactor.set(1.2, 1);
	vines.antialiasing = ClientPrefs.globalAntialiasing;
	
	var super1:FlxSprite = new FlxSprite(-1270, -700).loadGraphic(Paths.image(ext + 'overlay1'));
	super1.antialiasing = ClientPrefs.globalAntialiasing;
	super1.blend = BlendMode.ADD;
	super1.alpha = 0.6;
	
	super2 = new FlxSprite(-1270, -700).loadGraphic(Paths.image(ext + 'overlay2'));
	super2.antialiasing = ClientPrefs.globalAntialiasing;
	super2.blend = BlendMode.SUBTRACT;
	super2.alpha = 0.8;
	
	var pretenderLighting:FlxSprite = new FlxSprite(-1670, -700).loadGraphic(Paths.image(ext + 'lightingpretender'));
	pretenderLighting.alpha = 0.35;
	pretenderLighting.antialiasing = ClientPrefs.globalAntialiasing;
	
	add(bluemira);
	add(pot);
	add(vines);
	add(super2);
	add(super1);
	add(pretenderLighting);
	
	// I think we should just make it so the song in the json doesn't allow skins
	// but if it detects the skin in clientprefs is pink playable then it changes to her
	snapCamToPos(450, 300);
	camSpecialThing([160, 200], [380, 200], 0.5);
}

function onSongStart()
{
	if (ClientPrefs.bfSkin == 'pinkplayable')
	{
		game.unlockAchievementPopup('lets_be_friends');
	}
}
