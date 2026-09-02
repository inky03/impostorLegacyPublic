import animate.internal.filters.AdjustColorFilter;
import funkin.utils.MathUtil;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitterMode;

var choice:Int = FlxG.random.int(0, 3);

var ext = 'stages/dlc/beach/';
public var maroon:Character;
public var grey:Character;

public var loBlack:FlxBGSprite;
public var focusblack:FlxBGSprite;

var rimlights:Map = new haxe.ds.ObjectMap();
var parasite:Bool = false;
var heartEmitter:FlxEmitter;

var boppers1file = ClientPrefs.shaders ? 'boppers1' : 'lqboppers1';
var boppers2file = ClientPrefs.shaders ? 'boppers2' : 'lqboppers2';
var cheffile = ClientPrefs.shaders ? 'chef' : 'lqchef';

// bg shader
var sunShader:HeatwaveShader = (ClientPrefs.shaders ? new funkin.game.shaders.HeatwaveShader() : null);
var seaShader:HeatwaveShader = (ClientPrefs.shaders ? new funkin.game.shaders.HeatwaveShader() : null);

// character shaders
var boilingShader:HeatwaveShader = (ClientPrefs.shaders ? new funkin.game.shaders.HeatwaveShader() : null); // thats enough boiling shaders bro :heart:
var chromShader:ChromaticAbberation = (ClientPrefs.shaders ? new funkin.game.shaders.ChromaticAbberation(0) : null);
var boilingFilter:ShaderFilter = (boilingShader != null ? new openfl.filters.ShaderFilter(boilingShader.shader) : null);
var chromFilter:ShaderFilter = (chromShader != null ? new openfl.filters.ShaderFilter(chromShader.shader) : null);

function onLoad()
{
	camGame.filters = [];
	
	var bg:FlxSprite = new FlxSprite(-700, -290).loadGraphic(Paths.image(ext + 'sky'));
	bg.active = false;
	add(bg);
	
	var sun:FlxSprite = new FlxSprite(705, 138).loadGraphic(Paths.image(ext + 'sun'));
	sun.scrollFactor.set(0.98, 0.98);
	sun.blend = BlendMode.ADD;
	sun.active = false;
	add(sun);
	
	FlxTween.tween(bg, {y: -200}, 180, {ease: FlxEase.linear});
	FlxTween.tween(sun, {y: 228}, 180);
	
	var land:FlxSprite = new FlxSprite(-700, 418).loadGraphic(Paths.image(ext + 'land'));
	land.active = false;
	add(land);
	
	// this is the separated sea sprite
	var sea:FlxSprite = new FlxSprite(-700, 418).loadGraphic(Paths.image(ext + 'sea'));
	sea.active = false;
	add(sea);
	
	tomatungus = new FlxSprite(2300, 450).loadGraphic(Paths.image(ext + 'tomatungusswim'));
	tomatungus.scrollFactor.set(0.9, 0.9);

	white = new FlxSprite(-700, 420).loadGraphic(Paths.image(ext + 'whiteejected'));
	white.scrollFactor.set(0.9, 0.9);

	noisemaker = new FlxSprite(1350, 440);
	noisemaker.frames = Paths.getSparrowAtlas(ext + boppers2file);
	noisemaker.animation.addByPrefix('bop1', 'noisemakerbop1', 24, false);
	noisemaker.animation.addByPrefix('bop2', 'noisemakerbop2', 24, false);
	noisemaker.animation.play('bop1');	

	alien = new FlxSprite(2030, 470);
	alien.frames = Paths.getSparrowAtlas(ext + boppers2file);
	alien.animation.addByPrefix('bop1', 'alienbop1', 24, false);
	alien.animation.addByPrefix('bop2', 'alienbop2', 24, false);
	alien.animation.addByPrefix('bop3', 'alienbop3', 24, false);
	alien.animation.play('bop1');
	
	egor = new FlxSprite(-400, 500);
	egor.frames = Paths.getSparrowAtlas(ext + boppers2file);
	egor.animation.addByPrefix('bop1', 'egorbop', 24, false);
	egor.animation.play('bop1');
	
	buckenberry = new FlxSprite(1970, 430);
	buckenberry.frames = Paths.getSparrowAtlas(ext + boppers1file);
	buckenberry.animation.addByPrefix('bop1', 'buckenbop1', 24, false);
	buckenberry.animation.addByPrefix('bop2', 'buckenbop2', 24, false);
	buckenberry.animation.addByPrefix('bop3', 'buckenbop3', 24, false);
	buckenberry.animation.play('bop1');
	
	rhm = new FlxSprite(2300, 450);
	rhm.frames = Paths.getSparrowAtlas(ext + boppers1file);
	rhm.animation.addByPrefix('bop1', 'rhmbop', 24, false);
	rhm.animation.play('bop1');

	longus = new FlxSprite(-300, 300);
	longus.frames = Paths.getSparrowAtlas(ext + boppers1file);
	longus.animation.addByPrefix('bop1', 'longusbop1', 24, false);
	longus.animation.addByPrefix('bop2', 'longusbop2', 24, false);
	longus.animation.addByPrefix('bop3', 'longusdead', 24, true);
	longus.animation.play('bop1');
	
	chef = new FlxSprite(1970, 460);
	chef.frames = Paths.getSparrowAtlas(ext + cheffile);
	chef.animation.addByPrefix('bop1', 'chefbop', 24, false);
	chef.alpha = 0.001;

	if (!ClientPrefs.lowQuality) {
		switch (choice)
		{
			case 0:
				add(tomatungus);
				add(longus);
				add(buckenberry);
				add(rhm);
			case 1:
				add(white);
				add(noisemaker);
				add(egor);
				add(alien);
			case 2:
				add(white);
				add(noisemaker);
				add(longus);
				add(buckenberry);
			case 3:
				add(tomatungus);
				add(egor);
				add(alien);
				add(rhm);
		}
		add(chef);
	}

	if (seaShader != null)
	{
		sea.shader = seaShader.shader;
		// seaShader.shader.distortTexture.input = Paths.image('stages/dlc/beach/blabla').bitmap; if u wanna change the distort texture -ashley
	}
	if (sunShader != null) sun.shader = add(sunShader).shader;
	
	if (boilingShader != null) add(boilingShader);
	if (chromShader != null) add(chromShader); // i mean this one wont do jackshit but -ashley
	
	heartEmitter = new FlxEmitter(-700, 1600);
	for (i in 0...100)
	{
		var p = new FlxParticle();
		p.frames = Paths.getSparrowAtlas(ext + 'littleheart');
		p.animation.addByPrefix('littleheart', 'littleheart', 24, true);
		p.animation.play('littleheart');
		p.exists = false;
		p.animation.curAnim.curFrame = FlxG.random.int(0, 2);
		heartEmitter.add(p);
	}

	heartEmitter.launchMode = FlxEmitterMode.SQUARE;
	heartEmitter.velocity.set(-50, -400, 50, -800, -100, 0, 100, -800);
	heartEmitter.scale.set(3.4, 3.4, 3.4, 3.4, 0, 0, 0, 0);
	heartEmitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
	heartEmitter.width = 3200.45;
	heartEmitter.alpha.set(1, 1);
	heartEmitter.lifespan.set(2, 4.5);
	heartEmitter.start(false, FlxG.random.float(0.6, 0.7), 100000);
	heartEmitter.emitting = false;

	focusblack = new flixel.system.FlxBGSprite();
	focusblack.color = FlxColor.BLACK;
	focusblack.alpha = 0;
	add(focusblack);
}

function onUpdatePost(elapsed:Float)
{
	if (seaShader != null) seaShader.update(elapsed * .5); // updating this one manually so its more slow -ashley
	
	if (chromShader != null) chromShader.amount = MathUtil.fpsLerp(chromShader.amount, 0, .06); // feel FREE to replace this is sample code -ashley
}

function onCreatePost()
{
	maroonParasite = new Character(-450, 240, 'maroonParasite');
	add(maroonParasite);
	
	maroon = new Character(-600, 430, 'maroonthreat');
	add(maroon);
	maroon.danceEveryNumBeats = 1;
	
	grey = new Character(-700, 380, 'greythreat');
	add(grey);
	grey.danceEveryNumBeats = 1;
	
	maroonParasite.kill();
	maroon.kill();
	grey.kill();
	
	startCharacterPos(maroonParasite);
	startCharacterPos(maroon);
	startCharacterPos(grey);
	
	var subtract:FlxSprite = new FlxSprite(200, 100).loadGraphic(Paths.image(ext + 'subtract'));
	subtract.blend = BlendMode.SUBTRACT;
	subtract.scale.set(2.2, 2.2);
	subtract.active = false;
	subtract.alpha = 1;
	add(subtract);
	FlxTween.tween(subtract, {alpha: 0}, 180, {ease: FlxEase.linear});
	
	var bluesubtract:FlxSprite = new FlxSprite(200, 100).loadGraphic(Paths.image(ext + 'bluesubtract'));
	bluesubtract.blend = BlendMode.SUBTRACT;
	bluesubtract.scale.set(2.2, 2.2);
	bluesubtract.active = false;
	bluesubtract.alpha = 0;
	add(bluesubtract);
	FlxTween.tween(bluesubtract, {alpha: 1}, 180, {ease: FlxEase.linear});
	
	var glow:FlxSprite = new FlxSprite(200, -150).loadGraphic(Paths.image(ext + 'add'));
	glow.blend = BlendMode.ADD;
	glow.scale.set(2.2, 2.2);
	glow.active = false;
	glow.alpha = 1;
	add(glow);
	FlxTween.tween(glow, {alpha: 0.5}, 180, {ease: FlxEase.linear});
	
	if (ClientPrefs.shaders)
	{
		for (character in [boyfriend, gf, dad, pet, grey, maroon, maroonParasite])
		{
			if (character == null) continue;
			
			var rimlight = new funkin.game.shaders.ExtraDropShadowShader();
			
			rimlight.setColorMatrix(AdjustColorFilter.getColorMatrix(0, 5, 0, -20));
			
			var light = AdjustColorFilter.getColorMatrix(0, 5, 0, -20);
			light[4] = 255;
			light[9] = 220;
			light[14] = 0;
			
			rimlight.addLayer(light, 45, 14);
			
			rimlight.attachedSprite = character;
			character.useRenderTexture = true;
			character.shader = null;
			
			rimlights.set(character, rimlight);
		}
		
		if (hasPet) pet.shader = rimlights.get(pet);
		boyfriend.shader = rimlights.get(boyfriend);
		dad.shader = rimlights.get(dad);
		gf.shader = rimlights.get(gf);
		
		rimlights.get(gf).layers[0].angle = 90;
		rimlights.get(dad).layers[0].distance = 20;
		rimlights.get(boyfriend).layers[0].angle = rimlights.get(pet).layers[0].angle = 135;
	}
	
	intro = new FunkinVideoSprite();
	intro.cameras = [camOther];
	
	intro.onFormat(() -> {
		intro.setGraphicSize(FlxG.width);
		intro.screenCenter();
		add(intro);
	});
	intro.onEnd(() -> {
		camGame.alpha = 1;
		camHUD.alpha = 1;
		camGame.flash(0xFFFFFFFF, 0.4);
		intro.kill();
	});
	intro.antialiasing = ClientPrefs.globalAntialiasing;
	intro.load(Paths.video('tthreat'), [FunkinVideoSprite.muted]);
	
	intro.play();
	intro.pause();
	intro.tiedToGame = false;
	
	loBlack = new flixel.system.FlxBGSprite();
	loBlack.color = FlxColor.BLACK;
	loBlack.alpha = 0;
	add(loBlack);
	
	snapCamToPos(1100, 550);
	camSpecialThing([950, 550], [950, 550]);

	add(heartEmitter);
}

function opponentNoteHitPre(note)
{
	if (note.noteType == 'Opponent 2 Sing')
	{
		note.owner = maroon;
	}
	if (note.noteType == 'Opponent 3 Sing')
	{
		note.owner = grey;
	}
	if (note.noteType == 'Opponent 4 Sing')
	{
		note.owner = maroonParasite;
	}
	if (note.noteType == 'Hey!')
	{
		note.owner = maroon;
		maroon.animation.play('hey', true);
		maroon.specialAnim = true;
	}
}
function goodNoteHit(note)
{
	if (note.noteType == 'Hooray')
	{
		game.boyfriend.playAnim('hooray', true);
		game.boyfriend.specialAnim = true;
	}
}

function onEvent(n, v1, v2)
{
	switch (n)
	{
		case 'Legacy':
			switch (v1)
			{
				case 'forcecamtarget':
					switch (v2)
					{
						case 'grey':
							camCurTarget = grey;
						case 'maroon':
							camCurTarget = parasite ? maroonParasite : maroon;
						default:
							camCurTarget = null;
					}
				case 'killintro':
					if (intro != null)
					{
						camGame.alpha = 1;
						camHUD.alpha = 1;
						intro.kill();
						camGame.flash(FlxColor.WHITE, 0.4);
					}
			}
	}
}

function onCountdownTick()
{
	if (curBeat % 2 == 0)
	{
		maroon.onBeatHit(curBeat);
		grey.onBeatHit(curBeat);
		buckenberry.animation.play('bop1');
		longus.animation.play('bop1');
		egor.animation.play('bop1');
		alien.animation.play('bop1');
		noisemaker.animation.play('bop1');
	}
}

function onBeatHit():Void
{
	// feel FREE to replace this is also sample code -ashley
	if (chromShader != null && curBeat % 2 == 0) chromShader.amount = 1;
	if (curBeat % 2 == 0)
	{
		maroon.onBeatHit(curBeat);
		grey.onBeatHit(curBeat);

		egor.animation.play('bop1');
		rhm.animation.play('bop1');
		if (curBeat <= 175)
			{
				noisemaker.animation.play('bop1');
				alien.animation.play('bop1');
				buckenberry.animation.play('bop1');
				longus.animation.play('bop1');
			}
		if (curBeat >= 175 && curBeat <= 330)
			{
				noisemaker.animation.play('bop2');
				alien.animation.play('bop2');
				buckenberry.animation.play('bop2');
				longus.animation.play('bop2');
			}
		if (curBeat >= 330)
			{
				noisemaker.animation.play('bop2');
				alien.animation.play('bop3');
				buckenberry.animation.play('bop3');
				longus.animation.play('bop3');
			}
	}

}
function onStepHit()
{ //                               MAIN EVENTS
if (curSong == 'Triple Threat') {
	switch (curStep)
	{
		case 5:
			heartEmitter.emitting = ClientPrefs.shaders;
			FlxTween.tween(tomatungus, {x: -1000}, 90, {ease: FlxEase.linear});
		case 240:
			heartEmitter.emitting = false;
			maroon.revive();
			maroon.shader = rimlights.get(maroon);
			FlxTween.tween(maroon, {x: maroon.x + 430}, 1, {ease: FlxEase.quadOut});
			dad.animation.play('wow', true);
			dad.specialAnim = true;
			FlxTween.tween(dad, {x: dad.x + 150}, 1, {ease: FlxEase.quadOut});
			camSpecialThing([850, 550], [950, 550]);
		case 260:
			iconP2.changeIcon('tt1');
		case 680:
			camGame.alpha = camHUD.alpha = 0;
			taskGroup.visible = false;
			intro.play();
			intro.tiedToGame = true;
		case 690:
			camSpecialThing([300, 660], [450, 660]);
			grey.revive();
			FlxTween.tween(dad, {x: dad.x + 75}, 1, {ease: FlxEase.quadOut});
			maroon.x = maroon.x + 100;
			maroon.y = maroon.y - 10;
			grey.shader = rimlights.get(grey);
			if (gf.curCharacter == 'gfweird'){
	    	PlayState.instance.triggerEventNote("Change Character", "gf", "gfweird-2");}
		case 808:
			triggerEventNote('Legacy', 'killintro', '');
			triggerEventNote('Alt Idle Animation', 'Dad', '-alt');
			iconP2.changeIcon('tt2');
			camGame.flash(ClientPrefs.flashing ? FlxColor.WHITE : FlxColor.BLACK, 0.5);
			if (chromFilter != null) camGame.filters.push(chromFilter);
			FlxTween.tween(white, {x: 2500}, 60, {ease: FlxEase.linear});
		case 900:
			camSpecialThing([950, 550], [950, 550]);
		case 950:
			camSpecialThing([600, 550], [950, 550]);
		case 1064:
			heartEmitter.emitting = ClientPrefs.shaders;
		case 1160:
			heartEmitter.emitting = false;
		case 1192:
			camGame.filters.remove(chromFilter);
		case 1300:
			if (boilingFilter != null) camGame.filters.push(boilingFilter);
			maroon.animation.play('shift', true);
			maroon.specialAnim = true;
		case 1304:
			boyfriend.animation.play('hey', true);
			boyfriend.specialAnim = true;
		case 1320:
			egor.kill();
			if (gf.curCharacter == 'gfweird-2') triggerEventNote('Change Character', 'gf', 'gfweird'); //this broke my bf sprite for sum reason
			longus.x = longus.x - 300;
			longus.y = longus.y + 390;
			camGame.flash(ClientPrefs.flashing ? FlxColor.RED : FlxColor.ORANGE, 2);
			iconP2.changeIcon('tt3');
			maroon.shader = null;
			maroon.kill();
			parasite = true;
			maroonParasite.revive();
			maroonParasite.shader = rimlights.get(maroonParasite);
			FlxTween.tween(dad, {x: dad.x + 160}, 1, {ease: FlxEase.quadOut});
			FlxTween.tween(maroonParasite, {x: maroonParasite.x + 50}, 1, {ease: FlxEase.quadOut});
			camSpecialThing([700, 550], [1000, 550]);
			triggerEventNote('Alt Idle Animation', 'Dad', '-bruh');
		case 1500:
			chef.alpha = 1;
			heartEmitter.emitting = ClientPrefs.shaders;
		case 1512:
			camSpecialThing([600, 550], [1050, 550]);
		case 1540:
			chef.animation.play('bop1', true);
		case 1576:
			camGame.filters.remove(boilingFilter);
			gf.animation.play('cheer', true);
			gf.specialAnim = true;
		case 1600:
			chef.kill();
		case 1640:
			heartEmitter.emitting = false;
			if (chromFilter != null) camGame.filters.push(chromFilter);
		case 1672:
			if (boilingFilter != null) camGame.filters.push(boilingFilter);
		case 1704:
			camSpecialThing([700, 550], [900, 550]);
			camGame.filters.remove(boilingFilter);
			camGame.filters.remove(chromFilter);
		case 1712:
			if (boilingFilter != null) camGame.filters.push(boilingFilter);
			heartEmitter.emitting = ClientPrefs.shaders;
		case 1728:
			camGame.filters.remove(boilingFilter);
		case 1744:
			if (chromFilter != null) camGame.filters.push(chromFilter);
		case 1768:
			heartEmitter.emitting = false;
			camGame.filters.remove(chromFilter);
		case 1848:
			dad.animation.play('bruh', true);
			dad.specialAnim = true;
			triggerEventNote('Alt Idle Animation', 'Dad', '-wtf');
		case 2064:
			dad.animation.play('holy shit', true);
			dad.specialAnim = true;
		case 2073:
			gf.animation.play('cheer', true);
			gf.specialAnim = true;
	}
}
}

// if (boilingFilter != null) camGame.filters.push(boilingFilter); //adds boiling shader
// camGame.filters.remove(boilingFilter); // removes boiling shader
// if (chromFilter != null) camGame.filters.push(chromFilter);
// camGame.filters.remove(chromFilter);
