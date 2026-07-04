var ext = 'stages/dlc/horse/';
public var overlay:FlxSprite;
public var subtract:FlxSprite;
public var horse1:FlxSprite;
public var horse2:FlxSprite;
public var horse3:FlxSprite;
public var horse4:FlxSprite;
public var caught:FlxSprite;

function onLoad()
{
	var sky:FlxSprite = new FlxSprite(-600, -380).loadGraphic(Paths.image(ext + 'sky'));
	add(sky);

	var light:FlxSprite = new FlxSprite(1200, -700).loadGraphic(Paths.image(ext + 'light'));
	light.blend = BlendMode.ADD;
	add(light);

	var one:FlxSprite = new FlxSprite(-910, -200).loadGraphic(Paths.image(ext + '1'));
	one.scrollFactor.set(0.7,0.7);
	add(one);

	var two:FlxSprite = new FlxSprite(130, 380).loadGraphic(Paths.image(ext + '2'));
	two.scrollFactor.set(0.8,0.8);
	add(two);

	var three:FlxSprite = new FlxSprite(-600, 200).loadGraphic(Paths.image(ext + '3'));
	three.scrollFactor.set(0.9,0.9);
	add(three);

	var ground:FlxSprite = new FlxSprite(-550, 660).loadGraphic(Paths.image(ext + 'ground'));
	add(ground);

	//horse walks in
	horse1 = new FlxSprite(-2000,380);
	horse1.frames = Paths.getSparrowAtlas(ext + 'horses');
	horse1.animation.addByPrefix('trot', 'trot', 24, true);
	horse1.animation.play('trot', true);

	horse2 = new FlxSprite(-3500,380);
	horse2.frames = Paths.getSparrowAtlas(ext + 'horses');
	horse2.animation.addByPrefix('trot', 'trot', 28, true);
	horse2.animation.play('trot', true);

	horse3 = new FlxSprite(-3400,380);
	horse3.frames = Paths.getSparrowAtlas(ext + 'horses');
	horse3.animation.addByPrefix('trot', 'trot', 18, true);
	horse3.animation.play('trot', true);

	horse4 = new FlxSprite(-3480,380);
	horse4.frames = Paths.getSparrowAtlas(ext + 'horses');
	horse4.animation.addByPrefix('trot', 'trot', 12, true);
	horse4.animation.play('trot', true);

	add(horse1);
	add(horse2);
	add(horse3);
	add(horse4);
	
	caught = new FlxSprite(1400,470);
	caught.frames = Paths.getSparrowAtlas(ext + 'caughthorse');
	caught.animation.addByPrefix('idle', 'idle', 24, false);
	caught.visible = false;
	add(caught);
}
function onCreatePost()
{
	game.gf.scale.x *= 0.9;
	game.gf.scale.y *= 0.9;
	game.gf.color = 0xFFDDDDDD;
	game.boyfriend.color = 0xFFDDDDDD;
	game.dad.color = 0xFFDDDDDD;
	pet.color = 0xFFDDDDDD;

	snapCamToPos(900, 380);
	camSpecialThing([540, 380], [900, 380]);
	
	var front:FlxSprite = new FlxSprite(-700, 600).loadGraphic(Paths.image(ext + 'front'));
	front.scrollFactor.set(1.1,1.1);
	add(front);

	subtract = new FlxSprite(-600, -380).loadGraphic(Paths.image(ext + 'subtract'));
	subtract.blend = BlendMode.SUBTRACT;
	subtract.scrollFactor.set(1,1);
	subtract.alpha = 0.11;
	add(subtract);

	overlay = new FlxSprite(-600, -380).loadGraphic(Paths.image(ext + 'overlah'));
	overlay.blend = BlendMode.LIGHTEN;
	overlay.scrollFactor.set(1,1);
	overlay.alpha = 0.2;
	add(overlay);
}
function onBeatHit():Void
{
	if (curBeat % 2 == 0) caught.animation.play('idle', true);
}