var path:String = 'stages/jorsawsee/turbulence/';
var frontClouds:FlxSpriteGroup = new FlxSpriteGroup();
var backClouds:FlxSpriteGroup = new FlxSpriteGroup();
var props:FlxSpriteGroup = new FlxSpriteGroup();
var moving:Array<FlxSpriteGroup> = [frontClouds, backClouds, props];
var shownPink:Bool = false;
var propNames:Array<String> = ['balloon0', 'balloon copy'];
var speedlines:FlxBackdrop;
var skyLight:FlxSprite;
var claw:FlxSprite;
var sun:FlxSprite;
var colorSwap:HSLColorSwap;
var coolX:Float = 5000;
var speed:Float = 2;

// this code is stupid

function onLoad()
{
	var skyDark:FlxSprite = new FlxSprite().loadGraphic(Paths.image(path + 'skyDark'));
	skyDark.setGraphicSize(FlxG.width * 3, skyDark.height * 1.1);
	skyDark.scrollFactor.set();
	skyDark.updateHitbox();
	skyDark.screenCenter();
	add(skyDark);
	
	skyLight = new FlxSprite().loadGraphic(Paths.image(path + 'skyLight'));
	skyLight.setGraphicSize(skyDark.width, skyDark.height);
	skyLight.scrollFactor.set();
	skyLight.updateHitbox();
	skyLight.screenCenter();
	add(skyLight);
	
	sun = new FlxSprite().loadGraphic(Paths.image(path + 'sun'));
	sun.scrollFactor.set(.05, .05);
	add(sun);
}

var nextFrontCloud:Float = 0;
var nextBackCloud:Float = 0;
var nextProp:Float = 0;

function onCreatePost()
{
	camSpecialThing([360, 400], [1000, 800]);
	snapCamToPos(800, 600);
	camZoomingDecay = .5;
	
	var overlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image(path + 'overlay'));
	overlay.scrollFactor.set();
	overlay.scale.set(4, 4);
	overlay.screenCenter();
	overlay.blend = 0;
	overlay.x -= 100;
	overlay.y += 50;
	add(overlay);
	
	speedlines = new FlxBackdrop().loadGraphic(Paths.image(path + 'speedlines'));
	speedlines.scale.set(3, 3);
	speedlines.updateHitbox();
	speedlines.scrollFactor.set(.3, .3);
	speedlines.alpha = .5;
	add(speedlines);
	
	claw = new FlxSprite(930, 800);
	claw.frames = Paths.getSparrowAtlas(path + 'claw');
	claw.animation.addByPrefix('anim', 'crane', 24, true);
	claw.animation.play('anim');
	add(claw);
	var rope:FlxSprite = new FlxSprite(-1280, 925).loadGraphic(Paths.image(path + 'rope'));
	add(rope);
	
	stage.insert(stage.members.indexOf(dadGroup), props);
	stage.insert(stage.members.indexOf(dadGroup), backClouds);
	stage.add(frontClouds);
	
	if (ClientPrefs.shaders)
	{
		colorSwap = new funkin.game.shaders.HSLColorSwap();
		boyfriend.shader = dad.shader = colorSwap.shader;
	}
	
	dad.scrollFactor.set(.9, .9);
	
	evil();
	
	if (boyfriend.gameoverLoopDeathSound == null) boyfriend.gameoverLoopDeathSound = 'Jorsawsee_Loop';
	if (boyfriend.gameoverConfirmDeathSound == null) boyfriend.gameoverConfirmDeathSound = 'Jorsawsee_End';
}

function evil():Void
{ // stupid bf claw stuff
	var controller = boyfriend.animation;
	
	var idleOffset = (boyfriend.animOffsets.get('idle') ?? boyfriend.animOffsets.get('danceLeft') ?? [0, 0]).copy();
	for (offset in boyfriend.animOffsets)
	{
		offset[0] -= idleOffset[0];
		offset[1] -= idleOffset[1];
	}
	
	boyfriend.legacyOffset = boyfriend.rotatableOffsets = false;
	boyfriend.setPosition(claw.x, claw.y);
	boyfriend.updateHitbox();
	
	if (boyfriend.isAnimate)
	{
		var curFrames = boyfriend.animation.curAnim.frames;
		var wholeBounds = boyfriend.timeline.getWholeBounds();
		var idleBounds = boyfriend.timeline.getBounds(curFrames[curFrames.length - 1]);
		
		boyfriend.setSize(idleBounds.width, idleBounds.height);
		boyfriend.origin.set((idleBounds.x - wholeBounds.x) + (idleBounds.width * .5), (idleBounds.y - wholeBounds.y) + (idleBounds.height * .5));
		
		boyfriend.x -= (idleBounds.x - wholeBounds.x);
		boyfriend.y -= (idleBounds.y - wholeBounds.y - idleBounds.width * .5 * boyfriend.scale.x + idleBounds.height * .5 / boyfriend.scale.x);
		
		for (name in boyfriend.animOffsets.keys())
		{
			var offset = boyfriend.animOffsets.get(name);
			var anim = controller.getByName(name);
			
			if (anim?.frames == null) continue;
			
			var poseBounds = anim.timeline.getBounds(anim.frames[anim.frames.length - 1]);
			
			offset[0] = Math.max(offset[1] * .5, 0);
			offset[1] = Math.max(offset[0] * .5, 0);
			
			if (boyfriend.timeline.name != anim.timeline.name) continue;
			
			offset[0] += Math.max((poseBounds.x - idleBounds.x) * .5, 0);
			offset[1] += Math.max((idleBounds.y - poseBounds.y) * .5, 0);
		}
	}
	else
	{
		for (offset in boyfriend.animOffsets)
		{
			offset[0] = Math.max(offset[1] * .5, 0);
			offset[1] = Math.max(offset[0] * .5, 0);
		}
	}
	
	boyfriend.angle = -90;
	
	var turbOffset = boyfriend.getFlag('turbulenceOffset'); // for the proportionally impaired
	if (turbOffset != null)
	{
		boyfriend.x += (turbOffset[0]);
		boyfriend.y += (turbOffset[1]);
	}
	
	boyfriend.x += ((boyfriend.height - boyfriend.width) * .5 + 50);
	boyfriend.y += ((claw.height - boyfriend.width * boyfriend.scale.x) * .5 + 10);
	
	// bro
	var renameAnims:Map<String, String> = [
		'singUP' => 'singLEFT',
		'singDOWN' => 'singRIGHT',
		'singLEFT' => 'singDOWN',
		'singRIGHT' => 'singUP'
	];
	var queued:Array<Dynamic> = [];
	
	for (anim in controller.getAnimationList())
	{
		for (a in renameAnims.keys())
		{
			if (StringTools.startsWith(anim.name, a))
			{
				var newName:String = ('temp' + renameAnims.get(a) + anim.name.substr(a.length));
				boyfriend.renameAnim(anim.name, newName);
				queued.push(anim);
				break;
			}
		}
	}
	for (anim in queued)
	{
		boyfriend.renameAnim(anim.name, anim.name.substr('temp'.length));
	}
	
	boyfriend.playAnim(boyfriend.getAnimName(), true);
}

function onMoveCamera(whosTurn:Bool):Void
{
	defaultCamZoom = (whosTurn == 'dad' ? .45 : .52);
}

var awesomeTime:Float = 0;

function spawnThing(time:Float, z:Float, ?prop:Bool = false):FlxSprite
{
	if (coolX >= time + z) return null; // cloud gone
	
	var group:FlxSpriteGroup = (prop ? props : (z < 3500 ? frontClouds : backClouds));
	
	var cloud:FlxSprite = group.recycle(FlxSprite);
	
	cloud.moves = false; // dirty workaround cus idk if theres custom data for sprites lmao
	cloud.velocity.x = time;
	cloud.velocity.y = z;
	cloud.zIndex = Std.int(-z);
	
	group.members.sort((a, b) -> a.zIndex - b.zIndex);
	
	cloud.acceleration.y = (prop ? 1 : 0);
	
	cloud.flipX = FlxG.random.bool(50);
	
	if (prop)
	{
		var variant:Int = propNames[FlxG.random.int(0, propNames.length)];
		var somewhereMidsong:Bool = (Conductor.songPosition >= (audio.songLength * .75 + FlxG.random.int(-11000, 11000)));
		// pink s forced to show somewhere at the near end of the song if she hasnt cus its fun
		
		if ((FlxG.random.int(10) || somewhereMidsong) && !shownPink)
		{
			cloud.flipX = false;
			shownPink = true;
			variant = 'pink';
		}
		
		cloud.frames ??= Paths.getSparrowAtlas(path + 'props');
		cloud.animation.addByPrefix(variant, variant, 24, true);
		cloud.animation.play(variant);
		
		var scale:Float = FlxMath.remapToRange(cloud.velocity.y, 22800, 41200, .72, .45);
		var scroll:Float = FlxMath.remapToRange(cloud.velocity.y, 22800, 41200, .3, .2);
		cloud.scale.set(scale, scale);
		cloud.scrollFactor.set(scroll, scroll);
		
		cloud.y = (FlxG.random.float(80, 350) - FlxMath.remapToRange(cloud.velocity.y, 22800, 41200, 0, 100));
		
		var m:Float = FlxMath.remapToRange(cloud.velocity.y, 22800, 41200, 1, .35); // farther becomes more Blue
		var blueness:Float = (1 - m);
		cloud.setColorTransform(m, m, m, 1, blueness * 100, blueness * 200, blueness * 255);
	}
	else
	{
		var variant:Int = FlxG.random.int(1, 4);
		
		cloud.frames ??= Paths.getSparrowAtlas(path + 'clouds');
		cloud.animation.addByPrefix('cloud' + variant, 'export cloud ' + variant);
		cloud.animation.play('cloud' + variant);
		
		var scale:Float = FlxMath.remapToRange(cloud.velocity.y, 1600, 4800, 1, .38);
		var scroll:Float = FlxMath.remapToRange(cloud.velocity.y, 1600, 4800, 1.2, .35);
		cloud.scale.set(scale, scale);
		cloud.scrollFactor.set(scroll, scroll);
		
		cloud.alpha = (FlxG.random.float(.7, .9) * FlxMath.remapToRange(cloud.velocity.y, 1600, 4800, 1, .25));
		cloud.y = (FlxG.random.float(1000, 1280) - FlxMath.remapToRange(cloud.velocity.y, 1600, 4800, 0, 900));
	}
}

var speedTween:FlxTween;

function onEvent(event:String, v1:Dynamic, v2:Dynamic)
{
	if (event == 'Turbulence Speed')
	{
		var newSpeed:Float = Std.parseFloat(v1);
		if (Math.isNaN(newSpeed)) newSpeed = 1;
		
		var duration:Float = Std.parseFloat(v2);
		if (Math.isNaN(duration)) duration = .5;
		
		if (speedTween != null) speedTween.cancel();
		speedTween = FlxTween.num(speed, newSpeed, duration, {ease: FlxEase.quadInOut}, function(n) speed = n);
		
		if (ClientPrefs.flashing) FlxTween.tween(speedlines, {alpha: .5 * newSpeed}, 1);
	}
	else if (event == 'Turbulence Ending')
	{
		camCurTarget = boyfriend;
		camZoomingMult = 0;
	}
}

function delta(n:Float, min:Float, max:Float)
{
	return FlxMath.bound(FlxMath.remapToRange(n, min, max, 0, 1), 0, 1);
}

public var crazy:Float = 1;
var musicTime:Float = 0;
var musicDelta:Float = 0;

function onUpdatePost(elapsed:Float):Void
{
	if (isDead) return;
	
	// props thingy
	
	var time:Float = getSongTime();
	musicDelta = (time - musicTime);
	musicTime = time;
	
	if (ClientPrefs.flashing)
	{
		camGame.shake(.001 * (crazy * 2 - 1), .1);
		camHUD.shake(.001 * (crazy - 1), .1);
	}
	else
	{
		crazy = 1;
	}
	
	camHUD.scroll.y = Math.sin((musicTime / 1000) * (Conductor.bpm / 60) * -1.0) * 8 * (crazy * .5 + .5);
	camHUD.scrollAngle = Math.sin((musicTime / 1200) * (Conductor.bpm / 60) * -1.0) * (crazy * .5 + .5);
	
	FlxG.camera.targetOffset.set(Math.sin(musicTime / 412) * 20 * crazy, // magic
		Math.cos(musicTime / 877) * 20 * crazy);
		
	coolX += (speed * musicDelta * (ClientPrefs.flashing ? 1 : .5));
	
	speedlines.x = (coolX * 1.5);
	
	while (coolX > nextFrontCloud)
	{
		spawnThing(nextFrontCloud - FlxG.random.float(0, 100), FlxG.random.float(1600, 2200));
		nextFrontCloud += FlxG.random.float(1000, 1200);
	}
	while (coolX > nextBackCloud)
	{
		spawnThing(nextBackCloud - FlxG.random.float(0, 300), FlxG.random.float(3800, 4800));
		nextBackCloud += FlxG.random.float(1800, 2800);
	}
	while (coolX > nextProp)
	{
		spawnThing(nextProp - FlxG.random.float(0, 600), FlxG.random.float(22800, 41200), true);
		nextProp += FlxG.random.float(5000, 20000);
	}
	
	for (grp in moving)
	{
		for (cloud in grp)
		{
			if (!cloud.alive) continue;
			
			var z:Float = cloud.velocity.y;
			var isProp:Bool = (cloud.acceleration.y > 0);
			
			cloud.x = ((coolX - cloud.velocity.x) / z * 2000 - 2500 - cloud.width);
			
			if (isProp) cloud.y += (Math.sin(Conductor.songPosition / z * 20) * .2);
			
			if (cloud.x >= FlxG.width * 3) cloud.kill();
		}
	}
	
	// sunset
	
	awesomeTime = FlxMath.remapToRange(musicTime, 0, audio.songLength, 16, 19);
	var songPercent:Float = (musicTime / audio.songLength);
	
	var sunRad:Float = ((1.5 - awesomeTime / 12) * Math.PI);
	sun.x = (400 + songPercent * 120 + Math.cos(sunRad) * 800);
	sun.y = (-100 - Math.sin(sunRad) * 800);
	
	skyLight.alpha = FlxMath.remapToRange(awesomeTime, 16, 19, 1, 0);
	
	if (colorSwap != null)
	{
		colorSwap.hue = (songPercent * -.03);
		colorSwap.lightness = (songPercent * -.24);
	}
	else
	{
		var sunsetColor:FlxColor = FlxColor.interpolate(FlxColor.WHITE, 0xffff9eaa, songPercent);
		
		dad.color = boyfriend.color = sunsetColor;
	}
}

function onGameOverPost()
{
	var bf:Character = subState.boyfriend;
	
	bf.angle = -90;
	
	FlxTween.tween(bf, {x: bf.x + 2000, angle: 90}, .55, {ease: FlxEase.quadIn, startDelay: .35});
	FlxTween.tween(bf, {y: bf.y + 1800}, .55, {ease: FlxEase.quartIn, startDelay: .33, onComplete: () -> bf.visible = false});
	
	FlxG.camera.followLerp = 0.02;
}

function goodNoteHit(note)
{
	if (note.noteType == 'Hey!' && boyfriend.hasAnim('hey'))
	{
		boyfriend.playAnim('hey', true);
		boyfriend.skipDance = true;
	}
}
