import funkin.game.shaders.ColorSwap;

import flixel.effects.particles.FlxEmitterMode;

public var ext = 'stages/mira/greenhouse/';
public var greymira:FlxSprite;
public var longus:FlxSprite;
public var tomato:FlxSprite;
public var ventNotSus:FlxSprite;
var bluemira:FlxSprite;
var pot:FlxSprite;
var vines:FlxSprite;
var pretenderDark:FlxSprite;
var heartEmitter:FlxEmitter;
var heartsImage:FlxSprite;
var pinkVignette:FlxSprite;
var pinkVignette2:FlxSprite;
var vignetteTween:FlxTween;
var whiteTween:FlxTween;
var pinkCanPulse:Bool = false;
var heartColorShader:ColorSwap; // = new ColorSwap();
var cloud1:FlxSprite;
var cloud2:FlxSprite;
var cloud3:FlxSprite;
var cloud4:FlxSprite;
var cloudbig:FlxSprite;

function onLoad()
{
	heartColorShader = new ColorSwap();
	
	var bg:FlxSprite = new FlxSprite(-1500, -800).loadGraphic(Paths.image(ext + 'bg sky'));
	bg.antialiasing = true;
	add(bg);
	
	var sun:FlxSprite = new FlxSprite(-400, -1100).loadGraphic(Paths.image(ext + 'the sun'));
	sun.scrollFactor.set(0.8, 0.8);
	sun.blend = BlendMode.ADD;
	add(sun);
	
	pinkVignette = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'vignette'));
	pinkVignette.camera = camHUD;
	pinkVignette.alpha = 0.0001;
	pinkVignette.antialiasing = true;
	pinkVignette.blend = BlendMode.ADD;
	
	pinkVignette2 = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'vignette2'));
	pinkVignette2.cameras = camHUD;
	pinkVignette2.antialiasing = true;
	pinkVignette2.alpha = 0.0001;
	
	add(pinkVignette2);
	add(pinkVignette);
	
	heartsImage = new FlxSprite(-25, 0);
	heartsImage.cameras = [camOther];
	heartsImage.frames = Paths.getSparrowAtlas(ext + 'hearts');
	heartsImage.animation.addByPrefix('boil', 'Symbol 2', 24, true);
	heartsImage.animation.play('boil');
	heartsImage.antialiasing = true;
	heartsImage.alpha = 0.0001;
	heartsImage.shader = heartColorShader.shader;
	add(heartsImage);
	
	var bg:FlxSprite = new FlxSprite(-1300, -100).loadGraphic(Paths.image(ext + 'cloud fathest'));
	add(bg);
	
	var bg:FlxSprite = new FlxSprite(-1300, 0).loadGraphic(Paths.image(ext + 'cloud front'));
	add(bg);
	
	cloud1 = new FlxBackdrop(Paths.image(ext + 'cloud 1'));
	cloud1.setPosition(0, -1000);
	cloud1.velocity.x = -9;
	add(cloud1);
	
	cloud2 = new FlxBackdrop(Paths.image(ext + 'cloud 2'));
	cloud2.setPosition(0, -1200);
	cloud2.velocity.x = (-9 * 3);
	add(cloud2);
	
	cloud3 = new FlxBackdrop(Paths.image(ext + 'cloud 3'));
	cloud3.setPosition(0, -1400);
	cloud3.velocity.x = (-9 * 2);
	add(cloud3);
	
	cloud4 = new FlxBackdrop(Paths.image(ext + 'cloud 4'));
	cloud4.setPosition(0, -1600);
	cloud4.velocity.x = (-9 * .1);
	add(cloud4);
	
	cloudbig = new FlxBackdrop(Paths.image(ext + 'bigcloud'));
	cloudbig.setPosition(0, -1200);
	cloudbig.velocity.x = (-9 * .5);
	add(cloudbig);
	
	var bg:FlxSprite = new FlxSprite(-1200, -750).loadGraphic(Paths.image(ext + 'glasses'));
	add(bg);
	
	greymira = new FlxSprite(-140, -40);
	greymira.frames = Paths.getSparrowAtlas(ext + 'gray');
	greymira.animation.addByPrefix('bop', 'grey0', 18, false);
	greymira.animation.addByPrefix('anim', 'gray anim0', 24, false);
	greymira.animation.play('bop');
	greymira.scale.set(0.9, 0.9);
	greymira.animation.onFrameChange.add((animName, frameNumber, frameIndex) -> {
		if (animName == 'anim')
		{
			greymira.offset.set(259, 14);
		}
	});
	add(greymira);
	
	longus = new FlxSprite(745, -45);
	longus.frames = Paths.getSparrowAtlas(ext + 'longus');
	longus.animation.addByPrefix('bop', 'longus0', 24, false);
	longus.animation.addByPrefix('anim', 'longus anim0', 24, false);
	longus.animation.play('bop');
	longus.animation.onFrameChange.add((animName, frameNumber, frameIndex) -> {
		if (animName == 'anim')
		{
			longus.offset.set(475, -4);
		}
	});
	add(longus);
	
	tomato = new FlxSprite(936, 195);
	tomato.frames = Paths.getSparrowAtlas(ext + 'tomato');
	tomato.animation.addByPrefix('bop', 'tomato0', 24, false);
	tomato.animation.addByPrefix('anim', 'tomatongus anim0', 24, false);
	tomato.animation.play('bop');
	tomato.animation.onFrameChange.add((animName, frameNumber, frameIndex) -> {
		if (animName == 'anim')
		{
			tomato.offset.set(153, 43);
		}
	});
	add(tomato);
	
	ventNotSus = new FlxSprite(-100, -200);
	ventNotSus.frames = Paths.getSparrowAtlas(ext + 'black_pretender');
	ventNotSus.animation.addByPrefix('anim', 'black', 24, false);
	add(ventNotSus);
	
	var bg:FlxSprite = new FlxSprite(0, -650).loadGraphic(Paths.image(ext + 'what is this'));
	add(bg);
	
	var bg2:FlxSprite = new FlxSprite(-900, -10).loadGraphic(Paths.image(ext + 'lmao'));
	add(bg2);
	
	var bg3:FlxSprite = new FlxSprite(1200, 140).loadGraphic(Paths.image(ext + 'help'));
	add(bg3);
	
	rhmmira = new FlxSprite(1050, 125);
	rhmmira.frames = Paths.getSparrowAtlas(ext + 'crew');
	rhmmira.animation.addByPrefix('bop', 'RHM', 24, false);
	rhmmira.animation.play('bop');
	rhmmira.antialiasing = true;
	rhmmira.scrollFactor.set(1.2, 1);
	
	bluemira = new FlxSprite(-1350, 0);
	bluemira.frames = Paths.getSparrowAtlas(ext + 'crew');
	bluemira.animation.addByPrefix('bop', 'blue', 24, false);
	bluemira.animation.play('bop');
	bluemira.antialiasing = true;
	bluemira.scrollFactor.set(1.2, 1);
	
	pot = new FlxSprite(-1550, 650).loadGraphic(Paths.image(ext + 'front pot'));
	pot.antialiasing = true;
	pot.setGraphicSize(Std.int(pot.width * 1));
	pot.scrollFactor.set(1.2, 1);
	
	vines = new FlxSprite(-1200, -1200);
	vines.frames = Paths.getSparrowAtlas(ext + 'vines');
	vines.animation.addByPrefix('bop', 'green', 24, true);
	vines.animation.play('bop');
	vines.antialiasing = true;
	vines.scrollFactor.set(1.4, 1);
	
	heartEmitter = new FlxEmitter(-1200, 1000);
	
	for (i in 0...100)
	{
		var p = new FlxParticle();
		p.frames = Paths.getSparrowAtlas(ext + 'littleheart');
		p.animation.addByPrefix('littleheart', 'littleheart', 24, true);
		p.animation.play('littleheart');
		p.exists = false;
		p.animation.curAnim.curFrame = FlxG.random.int(0, 2);
		p.shader = heartColorShader.shader;
		heartEmitter.add(p);
	}
	heartEmitter.launchMode = FlxEmitterMode.SQUARE;
	heartEmitter.velocity.set(-50, -400, 50, -800, -100, 0, 100, -800);
	heartEmitter.scale.set(3.4, 3.4, 3.4, 3.4, 0, 0, 0, 0);
	heartEmitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
	heartEmitter.width = 4200.45;
	heartEmitter.alpha.set(1, 1);
	heartEmitter.lifespan.set(4, 4.5);
	heartEmitter.start(false, FlxG.random.float(0.3, 0.4), 100000);
	heartEmitter.emitting = false;
}

function onCreatePost()
{
	camSpecialThing([100, 200], [380, 200], 0.5);
	add(bluemira);
	add(rhmmira);
	add(pot);
	add(vines);
	add(heartEmitter);
}

function onStartCountdown()
{
	var fakeStartTimer = new FlxTimer().start((Conductor.crotchet / 1000) / playbackRate, function(tmr:FlxTimer) {
		if (tmr.loopsLeft % 2 == 0)
		{
			longus.animation.play('bop');
			tomato.animation.play('bop');
			greymira.animation.play('bop');
			rhmmira.animation.play('bop');
		}
		if (tmr.loopsLeft % 1 == 0) bluemira.animation.play('bop', true);
	}, 5);
}

function onBeatHit()
{
	if (curBeat % 2 == (curSong == 'Pinkwave' ? 0 : 1) && pinkCanPulse)
	{
		pinkVignette.alpha = 1;
		if (vignetteTween != null) vignetteTween.cancel();
		vignetteTween = FlxTween.tween(pinkVignette, {alpha: 0.2}, 1.2, {ease: FlxEase.sineOut});
		
		if (whiteTween != null) whiteTween.cancel();
		heartColorShader.flash = 0.5;
		whiteTween = FlxTween.tween(heartColorShader, {flash: 0}, 0.75, {ease: FlxEase.sineOut});
	}
	if (!inCutscene) // sobs
	{
		if (curBeat % 2 == 0)
		{
			longus.animation.play('bop', true);
			tomato.animation.play('bop', true);
			greymira.animation.play('bop', true);
			rhmmira.animation.play('bop', true);
		}
		if (curBeat % 1 == 0)
		{
			bluemira.animation.play('bop', true);
		}
	}
}

function onEvent(eventName, value1, value2)
{
	switch (eventName)
	{
		case 'pink toggle':
			if (pinkCanPulse == false)
			{
				pinkCanPulse = true;
				
				heartsImage.alpha = 1;
				pinkVignette.alpha = 1;
				pinkVignette2.alpha = 0.3;
				
				var fadeTime:Float = Std.parseFloat(value1) * 1.2;
				if (Math.isNaN(fadeTime)) fadeTime = 0;
				
				heartColorShader.flash = 1;
				FlxTween.tween(heartColorShader, {flash: 0}, fadeTime, {ease: FlxEase.cubeInOut});
				heartEmitter.emitting = true;
				return;
			}
			else
			{
				var fadeTime:Float = Std.parseFloat(value1) * 2;
				if (Math.isNaN(fadeTime)) fadeTime = 0;
				
				if (vignetteTween != null) vignetteTween.cancel();
				if (whiteTween != null) whiteTween.cancel();
				
				heartsImage.alpha = 1;
				pinkVignette.alpha = 1;
				pinkVignette2.alpha = 0.4;
				
				heartColorShader.flash = 1;
				
				FlxTween.tween(heartsImage, {alpha: 0}, fadeTime, {ease: FlxEase.cubeInOut});
				FlxTween.tween(heartColorShader, {flash: 0}, fadeTime, {ease: FlxEase.cubeInOut});
				FlxTween.tween(pinkVignette, {alpha: 0}, fadeTime, {ease: FlxEase.cubeInOut});
				FlxTween.tween(pinkVignette2, {alpha: 0}, fadeTime, {ease: FlxEase.cubeInOut});
				// heartsImage.visible = false;
				// pinkVignette.visible = false;
				// pinkVignette2.visible = false;
				
				pinkCanPulse = false;
				heartEmitter.emitting = false;
				return;
			}
	}
}
