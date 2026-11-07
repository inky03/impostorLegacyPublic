import funkin.game.shaders.DropShadowShader;
import funkin.states.substates.PauseSubState;

var ext = 'stages/void/finale/';
var defeatFinaleStuff:FlxSpriteGroup = new FlxSpriteGroup();
var finaleBGStuff:FlxSpriteGroup = new FlxSpriteGroup();
var finaleFGStuff:FlxSpriteGroup = new FlxSpriteGroup();
var finaleFlashbackStuff:FlxSprite;
var finaleDarkFG:FlxSprite;
var finaleLight:FlxSprite;
var lightoverlay:FlxSprite;
var finaleMode:Bool = false;
var bars:FlxSpriteGroup;
public var rimlightExcludedSkins:Array<String> = ['blackp']; // ig we need this now

function onLoad()
{
	var bars:FlxSpriteGroup = new FlxSpriteGroup();
	bars.cameras = [camHUD];
	add(bars);
	
	for (i in 0...2) // maybe this is doin too much idk
	{
		var bar = new FlxSprite().makeScaledGraphic(FlxG.width + 3, 90, FlxColor.BLACK);
		bar.y = i == 1 ? 630 : 0;
		bars.add(bar);
	}
	
	finaleFlashbackStuff = new FlxSprite(-290, -160);
	finaleFlashbackStuff.frames = Paths.getSparrowAtlas(ext + 'finaleFlashback');
	finaleFlashbackStuff.animation.addByPrefix('moog', 'finaleFlashback moog', 24, false);
	finaleFlashbackStuff.animation.addByPrefix('toog', 'finaleFlashback toog', 24, false);
	finaleFlashbackStuff.animation.addByPrefix('doog', 'finaleFlashback doog', 24, false);
	finaleFlashbackStuff.animation.play('moog');
	finaleFlashbackStuff.setGraphicSize(Std.int(finaleFlashbackStuff.width * 1.6));
	finaleFlashbackStuff.alpha = 0.001;
	finaleFlashbackStuff.scrollFactor.set(); // this matters !??
	
	var defeatthing:FlxSprite = new FlxSprite(-400, 2000, Paths.image('stages/void/finale/defeat'));
	// defeatthing.frames = Paths.getSparrowAtlas('stages/void/defeat');
	// defeatthing.animation.addByPrefix('bop', 'defeat', 24, false);
	// defeatthing.animation.play('bop');
	defeatthing.setGraphicSize(Std.int(defeatthing.width * 1.3));
	defeatthing.scrollFactor.set(0.8, 0.8);
	defeatFinaleStuff.add(defeatthing);
	
	var mainoverlayDK:FlxSprite = new FlxSprite(250, 475).loadGraphic(Paths.image('stages/void/defeatfnf'));
	mainoverlayDK.setGraphicSize(Std.int(mainoverlayDK.width * 4));
	mainoverlayDK.updateHitbox();
	mainoverlayDK.alpha = 0.0001;
	defeatFinaleStuff.add(mainoverlayDK);
	
	var bg0:FlxSprite = new FlxSprite(-600, -400).makeScaledGraphic(3000, 2000, 0xFF0D0A1B);
	
	var bgScale = 1.3;
	
	var bg1:FlxSprite = new FlxSprite(800, -270).loadFromSheet(ext + 'props', 'dead');
	bg1.updateHitbox();
	bg1.scrollFactor.set(0.8, 0.8);
	bg1.scale.set(bgScale, bgScale);
	
	var bg2:FlxSprite = new FlxSprite(-790, -530).loadFromSheet(ext + 'props', 'bg');
	bg2.updateHitbox();
	bg2.scrollFactor.set(0.9, 0.9);
	bg2.scale.set(bgScale, bgScale);
	
	var bg3:FlxSprite = new FlxSprite(370, 1200).loadFromSheet(ext + 'props', 'splat');
	bg3.updateHitbox();
	bg3.scale.set(bgScale, bgScale);
	
	var bg4:FlxSprite = new FlxSprite(990, -380).loadFromSheet(ext + 'props', 'lamp');
	bg4.updateHitbox();
	bg4.scale.set(bgScale, bgScale);
	
	var bg5:FlxSprite = new FlxSprite(-750, 160).loadFromSheet(ext + 'props', 'fore');
	bg5.updateHitbox();
	bg5.scale.set(bgScale, bgScale);
	
	var dark:FlxSprite = new FlxSprite(-950, -160).loadFromSheet(ext + 'props', 'dark');
	dark.scale.set(1.3, 1.3);
	dark.blend = BlendMode.MULTIPLY;
	
	finaleLight = new FlxSprite(-230, -200);
	finaleLight.frames = Paths.getSparrowAtlas(ext + 'light');
	finaleLight.animation.addByPrefix('bop', 'light', 24, false);
	finaleLight.animation.play('bop');
	finaleLight.setGraphicSize(Std.int(finaleLight.width * 4)); // GRRR
	finaleLight.updateHitbox();
	finaleLight.setGraphicSize(Std.int(finaleLight.width * 1.1));
	finaleLight.scrollFactor.set(0.8, 0.8);
	finaleLight.blend = BlendMode.ADD;
	
	finaleBGStuff.add(bg0);
	finaleBGStuff.add(bg1);
	finaleBGStuff.add(bg2);
	finaleFGStuff.add(bg3);
	finaleFGStuff.add(bg4);
	finaleFGStuff.add(bg5);
	if (!ClientPrefs.lowQuality)finaleFGStuff.add(dark);
	finaleFGStuff.add(finaleLight);
	
	finaleBGStuff.alpha = 0.001;
	finaleFGStuff.alpha = 0.001;
	
	add(defeatFinaleStuff);
	add(finaleBGStuff);
}

function onCreatePost()
{
	addCharacterToList('blackparasite', 1);
	
	camHUD.alpha = 0.001;
	playHUD.iconP1.visible = false;
	playHUD.iconP2.visible = false;
	playHUD.healthBar.visible = false;
	playHUD.timeBar.visible = false;
	playHUD.timeTxt.visible = false;
	canFollow = false;
	camSpecialThing([750, 800], [750, 800], 0.8);
	
	add(finaleFGStuff);
	if (!ClientPrefs.lowQuality) add(finaleFlashbackStuff);
	
	lightoverlay = new FlxSprite(-550, 250).loadGraphic(Paths.image('stages/void/iluminao omaga'));
	lightoverlay.scale.set(4, 4);
	lightoverlay.updateHitbox();
	lightoverlay.blend = BlendMode.ADD;
	lightoverlay.antialiasing = ClientPrefs.globalAntialiasing;
	add(lightoverlay);
	
	finaleDarkFG = new FlxSprite(-1000, -900).makeScaledGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
	finaleDarkFG.scrollFactor.set();
	add(finaleDarkFG);
	
	dadGroup.zIndex = 1;
	finaleFGStuff.zIndex = 2;
	finaleFlashbackStuff.zIndex = 3;
	lightoverlay.zIndex = 4;
	finaleDarkFG.zIndex = 5;
	
	opponentStrums.visible = false;
	modManager.setValue("alpha", 1, 1);
	refreshZ();
	
	if (ClientPrefs.shaders)
	{
		var blackRimlightBase:ExtraDropShadowShader = new funkin.game.shaders.ExtraDropShadowShader();
		
		blackRimlightBase.threshold = .05;
		blackRimlightBase.strength = .85;
		blackRimlightBase.setColorMatrix([
			.4, .5, -.2, 0, -50,
			-.25, .7, -.15, 0, -20,
			.42, -.35, .85, 0, -72,
			0, 0, 0, 1, 0
		]);
		blackRimlightBase.addLayer([
			.7, .5, 1, 0, 192,
			.3, .4, -.5, 0, 64,
			-.1, .2, .35, 0, 74,
			0, 0, 0, 1, 0
		], 10, 14, .01);
		blackRimlightBase.addLayer(
			blackRimlightBase.addLayer([
				.9, .6, .4, 0, 4,
				-.2, .5, .1, 0, -18,
				-.2, .2, .4, 0, -28,
				0, 0, 0, 1, 0
			], 12, 40, .01, .4)
		.colorMatrix, 96, 24, .01, .4);
		
		if (hasBfSkin && boyfriend.getFlag('backlit') != true)
		{
			bfRim = blackRimlightBase;
			bfRim.attachedSprite = boyfriend;
			boyfriend.useRenderTexture = true;
		}
		
		if (hasPet)
		{
			petRim = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(blackRimlightBase);
			petRim.attachedSprite = pet;
			pet.useRenderTexture = true;
		}
	}
	
	PauseSubState.songName = 'blackPause';
}

function onBeatHit()
{
	if (!ClientPrefs.lowQuality && curBeat % 4 == 0) finaleLight.animation.play('bop');
}

function onUpdate(elapsed)
{
	if (Conductor.songPosition >= 0 && Conductor.songPosition < 9600)
	{
		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, FlxMath.bound(elapsed * 0.01, 0, 1));
	}
}

function onSongStart()
{
	// finaleDarkFG.alpha = FlxMath.lerp(finaleDarkFG.alpha, 0, FlxMath.bound(elapsed * 0.5, 0, 1));
	FlxTween.tween(finaleDarkFG, {alpha: 0}, 9.6);
}

function onMoveCamera(isDad)
{
	if (finaleMode) if (isDad == 'boyfriend')
	{
		game.defaultCamZoom = 0.5;
	}
	else
	{
		game.defaultCamZoom = 0.4;
	}
}

function onEvent(name, v1, v2)
{
	switch (name)
	{
		case 'Finale Flashback Change':
			finaleFlashbackStuff.alpha = 0.5;
			switch (v1)
			{
				case 'moog':
					finaleFlashbackStuff.animation.play('moog');
				case 'toog':
					finaleFlashbackStuff.animation.play('toog');
				case 'doog':
					finaleFlashbackStuff.animation.play('doog');
				case 'flash':
					FlxG.camera.fade(FlxColor.WHITE, 1.2, false, function() {
						FlxG.camera.fade(FlxColor.RED, 0.6, true);
						finaleFlashbackStuff.alpha = 0;
					});
			}
			
		case 'Finale Drop':
			finaleMode = true;
			camSpecialThing([500, 600], [700, 700]);
			health = 0.2; // used to be 0.1 but im nicer
			finaleBGStuff.alpha = 1;
			finaleFGStuff.alpha = 1;
			defeatFinaleStuff.visible = false;
			lightoverlay.visible = false;
			healthBar.visible = true;
			canFollow = true;
			finaleUIOn();
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, 0xFFff1266, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			playHUD.updateIconPos = false;
			camGame.flash(0xFFff1266, 0.75);
		case 'Finale End':
			camOther.flash(0xFFff1266, 5);
			camHUD.visible = false;
			camGame.visible = false;
	}
}
