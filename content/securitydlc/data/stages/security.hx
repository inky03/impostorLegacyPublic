import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var ext = 'stages/dlc/security/'; //directory of the stage images folder
public var tawny:FlxSprite;
public var deadtawny:FlxSprite;
public var greypet:FlxSprite; //made for song events in mind (songs/49/49.hx)

function onLoad()
{
	var bg:FlxSprite = new FlxSprite(-550, -270).loadGraphic(Paths.image(ext + 'wall'));
	add(bg);

	var cabinets:FlxSprite = new FlxSprite(-552, -140).loadGraphic(Paths.image(ext + 'cabinets'));
	cabinets.scrollFactor.set(0.95,1);
	add(cabinets);
	
	shit = new FlxSprite(350, 480);
	shit.frames = Paths.getSparrowAtlas(ext + 'shit');
	shit.animation.addByPrefix('bop', 'bop', 24, false);
	shit.animation.play('bop');
	shit.scrollFactor.set(0.93,1);
	add(shit);
	
	tawny = new FlxSprite(-130, 330);
	tawny.frames = Paths.getSparrowAtlas(ext + 'tawny');
	tawny.animation.addByPrefix('bop', 'bop', 24, false);
	tawny.animation.play('bop');
	tawny.scrollFactor.set(0.93,1);
	add(tawny);

	deadtawny = new FlxSprite(-130, 400).loadGraphic(Paths.image(ext + 'deadtawny'));
	deadtawny.scrollFactor.set(0.93,1);
	deadtawny.alpha = 0.001;
	add(deadtawny);

	var props:FlxSprite = new FlxSprite(180,20).loadGraphic(Paths.image(ext + 'props'));
	props.scrollFactor.set(0.98,1);
	add(props);

	var table:FlxSprite = new FlxSprite(35, 210).loadGraphic(Paths.image(ext + 'table'));
	table.scrollFactor.set(0.97,1);
	add(table);

	greypet = new FlxSprite(-80, 750);
	greypet.frames = Paths.getSparrowAtlas(ext + 'minigrey');
	greypet.animation.addByPrefix('idle', 'idle', 24, false);
	greypet.animation.play('idle');

	var substract:FlxSprite = new FlxSprite(-550, -270).loadGraphic(Paths.image(ext + 'substract'));
	substract.blend = BlendMode.SUBTRACT;
	substract.scrollFactor.set(0,0);
	substract.alpha = 0.4;
	add(substract);
}

function onCreatePost()
{
	snapCamToPos(800, 450);
	camSpecialThing([500, 450], [850, 450]);
	
	add(greypet);

	var vignette:FlxSprite = new FlxSprite(-550, -270).loadGraphic(Paths.image(ext + 'vignette'));
	vignette.scrollFactor.set(0,0);
	add(vignette);
	
	var light:FlxSprite = new FlxSprite(-250, -270).loadGraphic(Paths.image(ext + 'light'));
	light.scrollFactor.set(1.2,1.2);
	light.blend = BlendMode.ADD;
	add(light);
}

function onBeatHit()
{
	if (curBeat % 2 == 0)
	{
		shit.animation.play('bop');
	}
	if (curBeat % 1 == 0)
	{
		greypet.animation.play('idle');
		tawny.animation.play('bop');
	}
}

function onCountdownTick()
{
	if (curBeat % 2 == 0)
	{
		shit.animation.play('bop');
	}
	if (curBeat % 1 == 0)
	{
		tawny.animation.play('bop');
		greypet.animation.play('idle');
	}
}
function onEvent(name, v1, v2)
{
	switch (name)
	{
		case 'Legacy':
			switch (v1)
			{
				case 'noob':
					isCameraOnForcedPos = true;
					snapCamToPos(500, 510);
				case 'bf':
					isCameraOnForcedPos = true;
					snapCamToPos(850, 510);
				case 'normal':
					isCameraOnForcedPos = false;
			}
	}
}
// song events are put into the song script, so the stage can be reused without having the same events