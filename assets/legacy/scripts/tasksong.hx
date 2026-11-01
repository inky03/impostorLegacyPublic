import flixel.text.FlxText;
import flixel.tweens.FlxTween;

public var taskGroup:FlxSpriteGroup = new FlxSpriteGroup(0, 200);
var whiteBox:FlxSprite;
var bg:FlxSprite;
var text:FlxText;
var subtext:FlxText;
var size:Float = 0;
var hasTaskSong:Bool = true;

function onCreatePost()
{
	taskGroup.camera = camOther;
	add(taskGroup);
	
	text = new FlxText(0, 0, 0, 'ME');
	text.setFormat(Paths.font("liberbold.ttf", false), 24, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	
	subtext = new FlxText(0, 30, 0, 'I MADE THE SONG');
	subtext.setFormat(Paths.font("liber.ttf", false), 24, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	
	bg = new FlxSprite(24 / -2, 24 / -2);
	var info = getInfo('info');
	if (info == null)
	{
		hasTaskSong = false;
		return;
	}
	assignValues(info);
	
	bg.alpha = 0.3;
	
	for (item in [bg, text, subtext])
	{
		taskGroup.add(item);
	}
}

function assignValues(info:Array<String>)
{
	taskGroup.x = 0;
	text.text = info[0];
	subtext.text = info[1] + (info[2] != null ? '\n' + info[2] : '');
	size = (subtext.fieldWidth > text.fieldWidth) ? subtext.fieldWidth : text.fieldWidth;
	bg.makeGraphic(Math.floor(size + 24), Std.int(text.height + subtext.height + 15), FlxColor.WHITE);
	bg.height = text.height + subtext.height;
	
	taskGroup.x -= size + 15;
}

function getInfo(?info = 'info')
{
	var txt = Paths.getPath('songs/' + Paths.sanitize(songName) + '/' + info + '.txt', null, PathsTestMode.NORMAL);
	var taskSong:Array<String> = CoolUtil.coolTextFile(txt);
	// if (ClientPrefs.inDevMode) trace(taskSong);
	
	return taskSong.length > 0 ? taskSong : null;
}

/**
	Only for Torture. That's right. I made it a lot nicer for you torture.
	I love you torture.
**/
function switchCredits(?task = 'info')
{
	var info = getInfo(task);
	assignValues(info);
	startTaskSong();
}

function onCountdownTick(t)
{
	if (t == 0 && hasTaskSong) // if it just started
		startTaskSong();
}

function onEvent(event, value1, value2)
{
	if (event == 'Legacy' && value1 == 'Show Task Song')
	{
		taskGroup.visible = true;
		
		switchCredits(value2.length > 0 ? value2 : null);
		startTaskSong();
	}
}

public function startTaskSong()
{
	taskGroup.x = 0;
	taskGroup.x -= size + 15;
	FlxTween.cancelTweensOf(taskGroup);
	
	FlxTween.tween(taskGroup, {x: taskGroup.x + (size + 15) + (24 / 2)}, 1,
		{
			ease: FlxEase.quintInOut,
			onComplete: function(twn:FlxTween) {
				FlxTween.tween(taskGroup, {x: taskGroup.x - (size + 15) - 50}, 1,
					{
						ease: FlxEase.quintInOut,
						startDelay: 2
					});
			}
		});
}
