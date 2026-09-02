import funkin.data.ClientPrefs;
import flixel.FlxSprite;
import Reflect;

var ext = 'stages/skeld/monotone/';
var bbg:FlxSprite;
var introTween:FlxTween;
var black:FlxSprite;
var yapsesh:FlxSprite;
var bgblue:FlxSprite;
var blueRoom:FlxSpriteGroup;
var redRoom:FlxSpriteGroup;
var greenRoom:FlxSpriteGroup;
var bggreen:FlxSprite;
var tower:FlxSprite;
var defeatthing:FlxSprite;
var bggreen:FlxSprite;
var greentower:FlxSprite;
var platform:FlxSprite;
var speedlines:FlxBackdrop;
var funTime:Float;
var blackImage:FlxSprite;
var lightoverlay:FlxSprite;
var lightoverlay2:FlxSprite;
var hsv1:HSLColorSwap = (ClientPrefs.shaders ? new funkin.game.shaders.HSLColorSwap() : null);
var spinPet = false;
public var copyPet:FunkinSprite;

function onDestroy()
{
	FlxG.camera.bgColor = 0xFF000000;
}

function onLoad()
{
	FlxG.camera.bgColor = 0xFF201F34;
	blueRoom = new FlxSpriteGroup();
	redRoom = new FlxSpriteGroup();
	greenRoom = new FlxSpriteGroup();
	redRoom.alpha = 0.0001;
	greenRoom.alpha = 0.0001;
	
	pet.origin.set(pet.width / 2, pet.height - 50);
	
	// kino.lua
	// awesome reference ty
	var bars:FlxSpriteGroup = new FlxSpriteGroup();
	bars.cameras = [camHUD];
	add(bars);
	
	for (i in 0...2) // maybe this is doin too much idk
	{
		var bar = new FlxSprite().makeGraphic(FlxG.width + 3, 90, FlxColor.BLACK);
		bar.y = i == 1 ? 630 : 0;
		bars.add(bar);
	}
	
	// var bgref:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ext + 'SkeldBack'));
	// bgref.setGraphicSize(Std.int(bgref.width * 2));
	// add(bgref);
	
	bbg = new FlxSprite(50, 531).loadGraphic(Paths.image(ext + 'back'));
	bbg.setGraphicSize(Std.int(bbg.width * 2));
	bbg.updateHitbox();
	// bbg.alpha = 0.5;
	add(bbg);
	
	bgblue = new FlxSprite(0, 25).loadGraphic(Paths.image(ext + 'backthings'));
	bgblue.setGraphicSize(Std.int(bgblue.width * 2));
	blueRoom.add(bgblue);
	
	floor = new FlxSprite(0, 1150).loadGraphic(Paths.image(ext + 'Floor'));
	floor.setGraphicSize(Std.int(floor.width * 2));
	blueRoom.add(floor);
	
	bgred = new FlxSprite(0, 25).loadGraphic(Paths.image(ext + 'backthingsred'));
	bgred.setGraphicSize(Std.int(bgred.width * 2));
	redRoom.add(bgred);
	
	floor = new FlxSprite(0, 1150).loadGraphic(Paths.image(ext + 'Floor'));
	floor.setGraphicSize(Std.int(floor.width * 2));
	redRoom.add(floor);
	
	// DEFEAT!
	defeatthing = new FlxSprite(330, 500);
	defeatthing.loadGraphic(Paths.image('stages/void/defeatpulse'));
	defeatthing.setGraphicSize(Std.int(defeatthing.width * 4));
	defeatthing.antialiasing = ClientPrefs.globalAntialiasing;
	defeatthing.scrollFactor.set(0.8, 0.8);
	defeatthing.alpha = 0;
	add(defeatthing);
	
	// THIS THING
	bgblue2 = new FlxSprite(570, -150).loadGraphic(Paths.image(ext + 'Reactor'));
	bgblue2.setGraphicSize(Std.int(bgblue2.width * 2));
	blueRoom.add(bgblue2);
	
	bgred2 = new FlxSprite(570, -150).loadGraphic(Paths.image(ext + 'ReactorRed'));
	bgred2.setGraphicSize(Std.int(bgred2.width * 2));
	redRoom.add(bgred2);
	
	// LIGHTS
	bgblue3 = new FlxSprite(350, 460).loadGraphic(Paths.image(ext + 'Reactorlight'));
	bgblue3.setGraphicSize(Std.int(bgblue3.width * 2));
	bgblue3.blend = BlendMode.ADD;
	blueRoom.add(bgblue3);
	
	bgred3 = new FlxSprite(350, 460).loadGraphic(Paths.image(ext + 'ReactorLightRed'));
	bgred3.setGraphicSize(Std.int(bgred3.width * 2));
	bgred3.blend = BlendMode.ADD;
	redRoom.add(bgred3);
	
	add(blueRoom);
	add(redRoom);
	
	wires = new FlxSprite(0, -100).loadGraphic(Paths.image(ext + 'wires1'));
	wires.updateHitbox();
	add(wires);
	
	bggreen = new FlxSprite(-200, -1600).loadGraphic(Paths.image(ext + 'evilejected'));
	bggreen.scrollFactor.set(0, 0);
	bggreen.setGraphicSize(Std.int(bggreen.width * 2));
	add(bggreen);
	
	greentower = new FlxSprite(550, 0).loadGraphic(Paths.image(ext + 'brombom'));
	greentower.setGraphicSize(Std.int(greentower.width * 1.5));
	greentower.scrollFactor.set(0.1, 0.1);
	greentower.updateHitbox();
	add(greentower);
	
	bggreen.alpha = 0;
	greentower.alpha = 0;
	
	platform = new FlxSprite(1340, 1110);
	platform.frames = Paths.getSparrowAtlas('stages/common/platform');
	platform.animation.addByPrefix('bop', 'floating', 24, true);
	platform.animation.play('bop');
	platform.alpha = 0.00001;
	
	add(platform);
	
	// pet 2
	copyPet = new funkin.objects.Pet(142, PET_Y);
}

function onGameOverStart()
{
	FlxG.camera.bgColor = FlxColor.BLACK;
}

function onCreatePost()
{
	blackImage = new flixel.system.FlxBGSprite();
	blackImage.color = FlxColor.BLACK;
	blackImage.alpha = 0;
	stage.insert(stage.members.indexOf(dadGroup) + 1, blackImage);

	var clonePet = (pet.getFlag('variants')?.monotone ?? pet.getFlag('customMonotone'));

	if (clonePet == null) clonePet = pet.curPet;

	copyPet.loadPet(clonePet);
	copyPet.flipX = !copyPet.flipX;
	copyPet.x -= (copyPet._petOffset.x * 2);
	add(copyPet);

	var grayscale:ExtraDropShadowShader = new funkin.game.shaders.ExtraDropShadowShader();
	grayscale.threshold = .05;
	grayscale.strength = .85;
	grayscale.setColorMatrix([
		0.31, 0.52, 0.17, 0, 0,
		0.31, 0.52, 0.17, 0, 0,
		0.31, 0.52, 0.17, 0, 0,
		0,    0,    0,    1, 0
	]);
	grayscale.attachedSprite = copyPet;
	copyPet.useRenderTexture = true;

	if (Paths.fileExists('scripts/vent.hx')) initScript('scripts/vent');
	
	// cache characters
	preloadVariant('falling');
	preloadVariant('defeat');
	preloadVariant('windy');

	addCharacterToList('greenEjected', 1);
	addCharacterToList('monotone', 1);
	addCharacterToList('red', 1);
	addCharacterToList('blackdk', 1);
	
	if (hasBfSkin)
	{
		final shift:Null<String> = (boyfriend.getFlag('variants')?.monotone ?? boyfriend.getFlag('customMonotone'));
		
		changeCharacter(shift ?? boyfriend.curCharacter, 1);
		
		if (dad.isPlayerInEditor) // i mean it works !
		{
			dad.baseFlipX = !dad.baseFlipX;
			
			var swapAnims:Map<String, String> = [
				'singLEFT' => 'singRIGHT',
				'danceLeft' => 'danceRight'
			];
			var ogAnims = dad.animation.getNameList().copy();
			for (animName in ogAnims)
			{
				for (name => newName in swapAnims)
				{
					if (StringTools.startsWith(animName, name))
					{
						dad.swapAnims(animName, newName + animName.substr(name.length));
					}
				}
			}
		}
		
		if (shift == null) dad.x = (-boyfriend.x - dad.baseFrameWidth + (dad.getFlag('monotoneXOffset') ?? 0) + 1920);
	}
	
	camHUD.alpha = .0001; // doy
	
	snapCamToPos(960, 700); // fr
	camSpecialThing([960, 700], [960, 700]); // camera
	
	lightoverlay = new FlxSprite(500, 275).loadGraphic(Paths.image(ext + 'overlay'));
	lightoverlay.setGraphicSize(Std.int(lightoverlay.width * 4));
	lightoverlay.blend = BlendMode.SUBTRACT;
	if (ClientPrefs.shaders) lightoverlay.shader = hsv1.shader;
	add(lightoverlay);
	
	lightoverlay2 = new FlxSprite(500, 275).loadGraphic(Paths.image(ext + 'overlay2'));
	lightoverlay2.blend = BlendMode.ADD;
	lightoverlay2.setGraphicSize(Std.int(lightoverlay2.width * 4));
	if (ClientPrefs.shaders) lightoverlay2.shader = hsv1.shader;
	add(lightoverlay2);
	
	// black screen sprite
	black = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xff000000);
	black.camera = camOther;
	add(black);
	black.visible = true;
	
	// count your seconds i will tickle you! okay maybe not
	// Loggo. No other comment
	yapsesh = new FlxSprite(0, 0);
	yapsesh.frames = Paths.getSparrowAtlas(ext + 'dialogue');
	yapsesh.animation.addByPrefix('bop', 'dialogue', 22, false);
	yapsesh.camera = camOther;
	yapsesh.zIndex = 12;
	yapsesh.screenCenter();
	yapsesh.setGraphicSize(Std.int(yapsesh.width * 0.6));
	yapsesh.alpha = 0.0001;
	add(yapsesh);
	
	speedlines = new FlxBackdrop().loadGraphic(Paths.image(ext + 'speedlines'));
	speedlines.scale.set(3, 3);
	speedlines.updateHitbox();
	speedlines.scrollFactor.set(.3, .3);
	speedlines.alpha = 0.00001;
	add(speedlines);
	
	pauseOverwrite = 'monotone';
}

function onSongStart()
{
	if (hasBfSkin) game.unlockAchievementPopup('double_trouble');
}

function onEvent(n, v1, v2)
{
	switch (n)
	{
		case 'Legacy': // handle all of this shit boy im lowkey editing the events in the chart editor AND visual studio
			if (v1 == 'red' || v1 == 'green' || v1 == 'monotone' || v1 == 'black')
			{
				if (ClientPrefs.shaders)
				{
					hsv1.hue = 0;
				}
				else
				{
					lightoverlay.setColorTransform();
					lightoverlay2.setColorTransform();
				}
				
				pauseOverwrite = '';
				if (v1 != 'green' && v1 != 'black') setVariant();
				
				platform.alpha = 0.001;
				defeatthing.alpha = 0.001;
				bggreen.alpha = 0.001;
				lightoverlay2.alpha = 1;
				speedlines.alpha = 0.001;
				greentower.alpha = 0.001;
				redRoom.alpha = 0.001;
				blueRoom.alpha = 0.001;
				greenRoom.alpha = 0.001;
				defeatness(v1 == 'black');
				// we can set alphas to 0
				// but i dont WANT TO! slams food off my desk
				// its okay i got it
			}
			switch (v1)
			{
				case 'crisis_line': // blah blah!
					yapsesh.alpha = 1;
					yapsesh.animation.play('bop');
				case 'red': // RED'S TURN BOY
					defeatthing.alpha = 0.001;
					redRoom.alpha = 1;
					if (ClientPrefs.shaders)
					{
						hsv1.hue = -118 / 255;
					}
					else
					{
						lightoverlay.setColorTransform(.2, .2, .2, 1, 0, 128, 20);
						lightoverlay2.setColorTransform(0, 0, 0, 1, 255, 0, 20);
					}
					triggerEventNote('Change Character', 'dad', 'red');
					spinPet = false; // im sorry im sorry im sorry
					bbg.alpha = 1;
				case 'monotone': // MONTONE'S TURN BOY
					triggerEventNote('Change Character', 'dad', 'monotone');
					defeatthing.alpha = 0.001;
					blueRoom.alpha = 1;
					dad.originalFlipX = dad.originalFlipX;
					spinPet = false;
					bbg.alpha = 1;
				case 'green':
					setVariant('falling');
					spinPet = true;
					triggerEventNote('Change Character', 'dad', 'greenEjected');
					bggreen.alpha = 1;
					lightoverlay2.alpha = 0.001;
					greentower.alpha = 1;
					speedlines.alpha = 0.5;
					if (hasBfSkin && boyfriend.getFlag('floating') != true) platform.alpha = 1;
					greentower.y = 0.001;
					FlxTween.tween(greentower, {y: -300}, 20);
					bbg.alpha = 0.001;
					defeatthing.alpha = 0.001;
				case 'black':
					setVariant('defeat');
					
					triggerEventNote('Change Character', 'dad', 'blackdk');
					defeatthing.alpha = 0.5;
					lightoverlay2.alpha = 0.001;
					spinPet = false;
					bbg.alpha = 0.001;
				case 'ending':
					FlxTween.tween(lightoverlay2, {alpha: 0}, 10);
					FlxTween.tween(blackImage, {alpha: 1}, 12);
				case 'off':
					triggerEventNote('flash', '2', '');
				case 'on':
					triggerEventNote('flash', '3', '');
			}
		case 'flash':
			if (v1 == '2')
			{
				black.visible = true;
				black.alpha = 1;
			}
			if (v1 == '3')
			{
				black.visible = false;
				yapsesh.visible = false;
			}
	}
	
	if (dad.curCharacter == 'monotone') copyPet.kill();
}

var oldPet:Null<String> = null;
var oldBf:Null<String> = null;

function setVariant(?variant:String):Void
{
	var custom:Null<String> = (variant == null || boyfriend.getFlag('variants') == null ? null : Reflect.field(boyfriend.getFlag('variants'), variant));
	if (custom != null)
	{
		oldBf ??= boyfriend.curCharacter;
		changeCharacter(custom, 0);
	}
	else if (oldBf != null)
	{
		changeCharacter(oldBf, 0);
		oldBf = null;
	}
	
	custom = (variant == null || pet.getFlag('variants') == null ? null : Reflect.field(pet.getFlag('variants'), variant));
	if (custom != null)
	{
		oldPet ??= pet.curPet;
		pet.loadPet(custom);
	}
	else if (oldPet != null)
	{
		pet.loadPet(oldPet);
		oldPet = null;
	}
}

function preloadVariant(variant:String):Void
{
	var custom:Null<String> = (boyfriend.getFlag('variants') == null ? null : Reflect.field(boyfriend.getFlag('variants'), variant));
	if (custom != null) addCharacterToList(custom, 0);
	
	custom = (pet.getFlag('variants') == null ? null : Reflect.field(pet.getFlag('variants'), variant));
	if (custom != null) new funkin.objects.Pet().loadPet(custom).destroy();
}

function onUpdate(elapsed:Float):Void
{
	if (ClientPrefs.inDevMode)
	{
		if (FlxG.keys.justPressed.Z) triggerEventNote('Legacy', 'red');
		if (FlxG.keys.justPressed.X) triggerEventNote('Legacy', 'black');
		if (FlxG.keys.justPressed.C) triggerEventNote('Legacy', 'green');
		if (FlxG.keys.justPressed.V) triggerEventNote('Legacy', 'monotone');
	}
}

function onUpdatePost(elapsed:Float):Void
{
	if (speedlines != null) speedlines.y = (Conductor.songPosition * -2 * (ClientPrefs.flashing ? 1.75 : .75));
	
	if (spinPet)
	{
		pet.x = (1850 + copyPet._petOffset.x);
		pet.y = (800 + copyPet._petOffset.y);
		pet.scrollFactor.set(1.2, 1.2);
		if (pet.getFlag('spin') != false) pet.angularVelocity = 450;
		pet.setColorTransform(1, 1, 1, 1, 0, 20, 40, -127);
		pet.colorTransform.alphaMultiplier = 2;
		pet.x += Math.sin(Conductor.songPosition / 150) * 400 * FlxG.elapsed;
		pet.y = 800 + Math.sin(Conductor.songPosition / 150) * 50;
	}
	else
	{
		pet.angle = pet.angularVelocity = 0;
		pet.x = (PET_X - pet.width * .5 + copyPet._petOffset.x);
		pet.y = (PET_Y - pet.height + copyPet._petOffset.y);
		pet.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		pet.scrollFactor.set(1, 1);
		pet.setColorTransform();
	}
}

function onBeatHit()
{
	if (curBeat % 4 == 0)
	{
		defeatthing.scale.set(5.5, 5); 
		defeatScaleTween = FlxTween.tween(defeatthing.scale, {x: 4, y: 4}, .8, {ease: FlxEase.sineOut});
	}
	
	copyPet.dance();
	
	switch (curBeat)
	{
		case 6:
			FlxTween.tween(black, {alpha: 0}, 15);
			introTween = FlxTween.tween(camGame, {zoom: 0.4}, 20);
		case 64:
			introTween.cancel();
			camSpecialThing([960, 750], [960, 750], 0.4);
		case 81:
			camSpecialThing([850, 750], [1050, 750], 0.45);
		case 88:
			camSpecialThing([700, 800], [700, 800], 0.8);
		case 95:
			camSpecialThing([850, 750], [1050, 750], 0.5);
		case 112:
			camSpecialThing([960, 750], [960, 750], 0.5);
		case 128:
			camSpecialThing([850, 750], [1050, 750], 0.6);
		case 192:
			camSpecialThing([960, 750], [960, 750], 0.5);
		case 208:
			camSpecialThing([850, 750], [1050, 750], 0.6);
		case 224:
			camSpecialThing([960, 700], [960, 700], 0.5);
		case 254:
			camSpecialThing([1300, 800], [1300, 800], 0.6);
		case 262:
			camSpecialThing([1400, 800], [1400, 800], 0.7);
		case 270:
			camSpecialThing([1450, 800], [1450, 800], 0.8);
		case 278:
			camSpecialThing([1500, 800], [1500, 800], 0.9);
		case 294:
			camSpecialThing([850, 700], [850, 700], 0.4);
		case 312:
			camSpecialThing([850, 750], [1050, 750], 0.45);
		case 328:
			camSpecialThing([650, 750], [650, 750], 0.55);
		case 334:
			camSpecialThing([650, 750], [650, 750], 0.45);
		case 344:
			camSpecialThing([1400, 800], [1300, 800], 0.7);
		case 360:
			camSpecialThing([960, 700], [960, 700], 0.5);
		case 456:
			camSpecialThing([850, 750], [1050, 750], 0.6);
	}
}

var bfRimlight:ExtraDropShadowShader;
var petRimlight:ExtraDropShadowShader;

function defeatness(ya:Bool)
{
	if (!ClientPrefs.shaders) return;
	
	if (bfRimlight == null)
	{
		bfRimlight = new funkin.game.shaders.ExtraDropShadowShader();
		
		bfRimlight.threshold = .05;
		bfRimlight.strength = .85;
		bfRimlight.setColorMatrix([
			.4, .5, -.2, 0, -50,
			-.25, .7, -.15, 0, -20,
			.42, -.35, .85, 0, -72,
			0, 0, 0, 1, 0
		]);
		bfRimlight.addLayer([
			.7, .5, 1, 0, 192,
			.3, .4, -.5, 0, 64,
			-.1, .2, .35, 0, 74,
			0, 0, 0, 1, 0
		], 10, 14, .01);
		bfRimlight.addLayer(
			bfRimlight.addLayer([
				.9, .6, .4, 0, 4,
				-.2, .5, .1, 0, -18,
				-.2, .2, .4, 0, -28,
				0, 0, 0, 1, 0
			], 12, 40, .01, .4)
		.colorMatrix, 96, 24, .01, .4);
		
		petRimlight = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(bfRimlight);
	}
	
	if (ya)
	{
		if (hasBfSkin && boyfriend.getFlag('backlit') != true)
		{
			bfRimlight.attachedSprite = boyfriend;
			boyfriend.useRenderTexture = true;
		}
		
		if (hasPet)
		{
			petRimlight.attachedSprite = pet;
			pet.useRenderTexture = true;
		}
	}
	else
	{
		boyfriend.shader = pet.shader = null;
	}
}
