var farCloudBg:FlxSprite;
var airFarClouds:FlxBackdrop;
var airMidClouds:FlxBackdrop;
var airCloseClouds:FlxBackdrop;
var airshipPlatform:FlxBackdrop;
var airSpeedlines:FlxBackdrop;
var airBigCloud:FlxSprite;
public var bfPlatform:FlxSprite;
public var gfBoard:FlxSprite;
public var petBoard:FlxSprite;
var airshipskyflash:FlxSprite;

// character legs
var blackScream:Bool = false;

// other vars
var bgspeed:Float = (ClientPrefs.photosensitive ? 7 : 9); // background scroll speed
var bigCloudSpeed:Float = 10;

function onLoad()
{
	game.camGame.height += 8;
	
	var sky:FlxSprite = new FlxSprite(-1500, -897.55).loadGraphic(Paths.image('stages/airship/danger/sky'));
	sky.setGraphicSize(5000, sky.height * 1.5 * 4);
	sky.updateHitbox();
	sky.scrollFactor.set(0, 0);
	add(sky);
	
	farCloudBg = new FlxSprite(-1500).makeGraphic(50, 50, 0xffc0dbff);
	farCloudBg.setGraphicSize(3000, 1200);
	farCloudBg.scrollFactor.set(.1, .1);
	farCloudBg.antialiasing = false;
	farCloudBg.updateHitbox();
	add(farCloudBg);
	
	airFarClouds = new FlxBackdrop(Paths.image('stages/airship/danger/farthestClouds'), FlxAxes.X, -2);
	airFarClouds.setPosition(3385.95, -142.2);
	airFarClouds.scrollFactor.set(0.1, 0.1);
	airFarClouds.scale.set(2, 2);
	airFarClouds.updateHitbox();
	add(airFarClouds);
	
	farCloudBg.y = (airFarClouds.y + airFarClouds.height - 1);
	
	airMidClouds = new FlxBackdrop(Paths.image('stages/airship/danger/backClouds'), FlxAxes.X, -2, 299, 0);
	airMidClouds.setPosition(3352.4, 76.55);
	airMidClouds.scrollFactor.set(0.2, 0.2);
	airMidClouds.scale.set(2, 2);
	airMidClouds.updateHitbox();
	add(airMidClouds);
	
	var airship:FlxSprite = new FlxSprite(1114.75, -873.05).loadGraphic(Paths.image('stages/airship/danger/airship'));
	airship.scrollFactor.set(0.25, 0.25);
	airship.scale.set(2, 2);
	airship.updateHitbox();
	add(airship);
	
	var fan:FlxSprite = new FlxSprite(2285.4, 102);
	fan.frames = Paths.getSparrowAtlas('stages/airship/danger/airshipFan');
	fan.animation.addByPrefix('idle', 'ala avion instance 1', 24, true);
	fan.animation.play('idle');
	fan.scrollFactor.set(0.27, 0.27);
	add(fan);
	
	airBigCloud = new FlxSprite(3507.15, -744.2).loadGraphic(Paths.image('stages/airship/danger/bigCloud'));
	airBigCloud.scrollFactor.set(0.4, 0.4);
	airBigCloud.scale.set(2, 2);
	airBigCloud.updateHitbox();
	add(airBigCloud);
	
	airCloseClouds = new FlxBackdrop(Paths.image('stages/airship/danger/frontClouds'), FlxAxes.X, -3, 808, 0);
	airCloseClouds.setPosition(6092.2, 422.15);
	airCloseClouds.scrollFactor.set(0.3, 0.3);
	airCloseClouds.scale.set(2, 2);
	airCloseClouds.updateHitbox();
	add(airCloseClouds);
	
	airshipskyflash = new FlxSprite(0, -200);
	airshipskyflash.frames = Paths.getSparrowAtlas('stages/airship/danger/screamsky');
	airshipskyflash.animation.addByPrefix('bop', 'scream sky', 24, false);
	airshipskyflash.setGraphicSize(Std.int(airshipskyflash.width * 4)); // REAL funny guys.
	airshipskyflash.updateHitbox();
	airshipskyflash.setGraphicSize(Std.int(airshipskyflash.width * 3));
	airshipskyflash.antialiasing = true;
	add(airshipskyflash);
	airshipskyflash.alpha = 0.0001;
	
	airshipPlatform = new FlxBackdrop(Paths.image('stages/airship/danger/fgPlatform'), FlxAxes.X);
	airshipPlatform.setPosition(-7184.8, 282.25);
	airshipPlatform.scale.set(2, 2);
	airshipPlatform.updateHitbox();
	add(airshipPlatform);
	
	// TODO: Rewrite this this is a little dire to look at
	
	bfPlatform = new FlxSprite(1542, 350);
	bfPlatform.zIndex = (boyfriendGroup.zIndex - 1);
	bfPlatform.frames = Paths.getSparrowAtlas('stages/common/platform');
	bfPlatform.animation.addByPrefix('bop', 'danger', 24, true);
	bfPlatform.animation.play('bop');
	bfPlatform.visible = false;
	
	gfBoard = new FlxSprite(850, 550);
	gfBoard.zIndex = (gfGroup.zIndex - 1);
	gfBoard.frames = Paths.getSparrowAtlas('stages/airship/danger/dangerboards');
	gfBoard.animation.play('bop');
	gfBoard.visible = false;
	
	petBoard = new FlxSprite(1900, 500);
	petBoard.zIndex = (pet.zIndex + 1);
	petBoard.frames = Paths.getSparrowAtlas('stages/airship/danger/dangerboards');
	petBoard.animation.addByPrefix('bop', 'cart', 24, true);
	petBoard.animation.play('bop');
	petBoard.visible = false;
	
	add(bfPlatform);
	add(gfBoard);
	add(petBoard);
}

function onCreatePost()
{
	if (gf.getFlag('floating') != true && gf.getFlag('runner') != true)
		gfBoard.visible = true;
	
	if (gf.getFlag('dangerSkateboard'))
	{
		gfBoard.animation.addByPrefix('bop', 'skateboard', 24, true);
		gfBoard.x += 110;
		gfBoard.y -= 50;
	}
	else
	{
		gfBoard.animation.addByPrefix('bop', 'speakerwheel', 24, true);
	}
	
	gfBoard.animation.play('bop');

	if (hasBfSkin && boyfriend.getFlag('floating') != true && boyfriend.getFlag('runner') != true)
	{
		bfPlatform.visible = true;
		boyfriend.x += 50;
		boyfriend.y -= 235;
	}
	
	if (hasPet && pet.getFlag('floating') != true && pet.getFlag('runner') != true)
	{
		petBoard.visible = true;
		pet.y -= 20;
	}

	airSpeedlines = new FlxBackdrop(Paths.image('stages/airship/danger/speedlines'), FlxAxes.X, 1, 787.95, 0);
	airSpeedlines.setPosition(-3352.1, -1035.95);
	airSpeedlines.alpha = 0.2;
	airSpeedlines.scrollFactor.set(1.3, 1.3);
	add(airSpeedlines);
}

function onUpdate(elapsed) // to anyone else reading this script I'm sorry its just huge
{
	if (ClientPrefs.inDevMode)
	{
		if (FlxG.keys.pressed.Q) bgspeed -= elapsed * 15;
		if (FlxG.keys.pressed.E) bgspeed += elapsed * 15;
	}
	
	final delta:Float = (elapsed * bgspeed * playbackRate);
	
	if (!isDead)
	{
		if (!blackScream) game.camGame.shake(0.0008, 0.01);
		game.camGame.y = Math.sin((Conductor.songPosition / 280) * (Conductor.bpm / 60) * 1.0) * 2 - 2;
		game.camHUD.scroll.y = Math.sin((Conductor.songPosition / 300) * (Conductor.bpm / 60) * -1.0) * 0.6;
		game.camHUD.scrollAngle = Math.sin((Conductor.songPosition / 350) * (Conductor.bpm / 60) * -1.0) * 0.6;
	}
	
	airFarClouds.x -= (delta * 7);
	airMidClouds.x -= (delta * 13);
	airCloseClouds.x -= (delta * 50);
	airshipPlatform.x -= (delta * 300);
	airSpeedlines.x -= (delta * 350);
	
	if (airBigCloud != null)
	{
		airBigCloud.x -= (delta * bigCloudSpeed);
		if (airBigCloud.x < -4163.7)
		{
			airBigCloud.x = FlxG.random.float(3931.5, 4824.05);
			airBigCloud.y = FlxG.random.float(-1087.5, -307.35);
			bigCloudSpeed = FlxG.random.float(7, 15);
		}
	}
}

function getDisplacement(left_x:Float = -4000, get_x:Float = 0, returnX:Float = 4000)
{
	// to prevent weird clipping
	var dp:Float = left_x - get_x;
	return (returnX - dp);
}

function onGameOverStart()
{
	FlxTween.tween(FlxG.camera, {zoom: .65}, 8, {ease: FlxEase.expoOut, startDelay: .5});
}

function onEvent(ev, v1, v2)
{
	if (ev == 'Legacy')
	{
		switch (v1)
		{
			case 'scream danger':
				blackScream = true;
				airshipskyflash.alpha = 1;
				airshipskyflash.animation.play('bop', false);
				
				dad.playAnim('scream2', true);
				dad.specialAnim = true;
				dad.animSuffix = '-mad';
			case 'unscream danger':
				dadLegs.playAnim('legs-mad', true);
				
				blackScream = false;
				FlxTween.tween(airshipskyflash, {alpha: 0}, 0.6, {ease: FlxEase.quartOut});
			case 'bye gf':
				FlxTween.tween(gf, {x: gf.x - 3500}, 4, {ease: FlxEase.quartIn, onComplete: function() gf.kill()});
				FlxTween.tween(pet, {x: pet.x - 3500}, 8, {ease: FlxEase.quartIn, onComplete: function() pet.kill()});
				FlxTween.tween(gfBoard, {x: gfBoard.x - 3500}, 4, {ease: FlxEase.quartIn, onComplete: function() gfBoard.kill()});
				FlxTween.tween(petBoard, {x: petBoard.x - 3500}, 8, {ease: FlxEase.quartIn, onComplete: function() petBoard.kill()});
				FlxTween.num(bgspeed, (ClientPrefs.photosensitive ? 9 : 14), 5, {ease: FlxEase.quadIn}, function(v:Float) {
					bgspeed = v;
				});
		}
	}
}
