import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var ext = 'stages/dlc/beach/';
public var maroon:Character;
public var grey:Character;
var rimlight;

function onLoad()
{
	var bg:FlxSprite = new FlxSprite(-980, -300).loadGraphic(Paths.image(ext + 'sky'));
	add(bg);

	var stars1:FlxSprite = new FlxSprite(-980, -200).loadGraphic(Paths.image(ext + 'stars1'));
	stars1.scrollFactor.set(0.9,0.9);
	add(stars1);

	var stars2:FlxSprite = new FlxSprite(-980, -300).loadGraphic(Paths.image(ext + 'stars2'));
	stars2.scrollFactor.set(0.8,0.8);
	add(stars2);

	var sand:FlxSprite = new FlxSprite(-980, 650).loadGraphic(Paths.image(ext + 'sand'));
	add(sand);

	var sun:FlxSprite = new FlxSprite(450, 20).loadGraphic(Paths.image(ext + 'sun'));
	sun.scrollFactor.set(0.99,0.99);
	sun.blend = BlendMode.ADD;
	add(sun);

	sea = new FlxSprite(-1000, 500);
	sea.frames = Paths.getSparrowAtlas(ext + 'sea');
	sea.animation.addByPrefix('bop', 'bop', 24, true);
	sea.animation.play('bop', true);
	add(sea);
}

function onUpdatePost() {
    var uv = boyfriend.frame.uv;
    rimlight.setFloatArray('uFrameBounds', [uv.x, uv.y, uv.width, uv.height]);
    rimlight.setFloat('angOffset', boyfriend.frame.angle * Math.PI / 180);
}

function onCreatePost()
{
	maroon = new Character(-200, 430, 'maroon');
	game.startCharacterPos(maroon);
	add(maroon);
	maroon.danceEveryNumBeats = 1;

	maroonParasite = new Character(-490, 260, 'maroonParasite');
	game.startCharacterPos(maroonParasite);
	add(maroonParasite);
	maroonParasite.alpha = 0.0001;
	
	grey = new Character(-900, 380, 'grey');
	game.startCharacterPos(grey);
	add(grey);
	grey.danceEveryNumBeats = 1;

	snapCamToPos(900, 500);
	camSpecialThing([900, 500], [1200, 500]);

	var subtract:FlxSprite = new FlxSprite(-980, -300).loadGraphic(Paths.image(ext + 'subtract'));
	subtract.blend = BlendMode.SUBTRACT;
	add(subtract);

    boyfriend.shader = rimlight = newShader('rimlight1');
    boyfriend.useRenderTexture = true;

    dad.shader = rimlight2 = newShader('rimlight1');
    dad.useRenderTexture = true;

    maroon.shader = rimlight2;
    maroon.useRenderTexture = true;

    grey.shader = rimlight2;
    grey.useRenderTexture = true;

    rimlight.setFloatArray('dropColor', [236, 136, 0]);
    
    rimlight.setBool('useMask', false);
    rimlight.setFloat('AA_STAGES', 100); // antialiasing detail (use wiht care)
    rimlight.setFloat('thr', 0.01); // sprites lihgter than this point (from 0 to 1) will suffer th effects of rim light
    
    rimlight.setFloat('hue', 0);
    rimlight.setFloat('saturation', -20);
    rimlight.setFloat('brightness', 0);
    
    rimlight.setFloat('str', 1); // strength
    rimlight.setFloat('dist', 14); // distance
    rimlight.setFloat('ang', 135 * Math.PI / 180); // angle (radians)

    rimlight2.setFloatArray('dropColor', [236, 136, 0]);
    
    rimlight2.setBool('useMask', false);
    rimlight2.setFloat('AA_STAGES', 100); // antialiasing detail (use wiht care)
    rimlight2.setFloat('thr', .2); // sprites lihgter than this point (from 0 to 1) will suffer th effects of rim light
    
    rimlight2.setFloat('hue', 10);
    rimlight2.setFloat('saturation', -20);
    rimlight2.setFloat('brightness', 0);
    
    rimlight2.setFloat('str', 1); // strength
    rimlight2.setFloat('dist', 20); // distance
    rimlight2.setFloat('ang', 45 * Math.PI / 180); // angle (radians)
	
}
function opponentNoteHitPre(note)
{
	if (note.noteType == 'Opponent 2 Sing')
	{
		note.owner = maroon;
		note.owner = maroonParasite;
	}
	if (note.noteType == 'Opponent 3 Sing')
	{
		note.owner = grey;
	}
}

function onBeatHit()
{
	if (curBeat % 2 == 0)
	{
		maroon.onBeatHit(curBeat);
		grey.onBeatHit(curBeat);
	}
}
function onCountdownTick()
{
	if (curBeat % 2 == 0)
	{
		maroon.onBeatHit(curBeat);
		grey.onBeatHit(curBeat);
	}
}
function onStepHit()
{
	if (curStep == 10)
	{
		
	}
	if (curStep == 50)
	{
		FlxTween.tween(dad, { x: dad.x + 150 }, 0.5, { ease: FlxEase.quadOut });
	    maroon.shader = null;
		maroon.alpha = 0.0001;
		maroonParasite.alpha = 1;
		maroonParasite.useRenderTexture = true;

		camSpecialThing([700, 500], [1000, 500]);
	}
	if (curStep == 70)
	{
		camSpecialThing([700, 500], [1000, 500]);
		iconP2.changeIcon('tt1');
	}
	if (curStep == 90)
	{
		iconP2.changeIcon('tt2');
	}
	if (curStep == 110)
	{
		iconP2.changeIcon('tt3');
	}
}