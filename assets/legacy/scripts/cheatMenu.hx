import flixel.addons.ui.FlxUIButton;

if (!ClientPrefs.inDevMode) return;

public var dbGroup:FlxSpriteGroup = new FlxSpriteGroup();

function onCreatePost()
{
	final GAYLINE:Int = 90;
	
	dbGroup.camera = camOther;
	
	closeButton = dbGroup.add(new FlxUIButton(GAYLINE - 52 - 8, 644, 'Reset\nSong', FlxG.resetState));
	closeButton.resize(52, 50);
	lqButton = dbGroup.add(new FlxUIButton(GAYLINE, 700, getBool('LowQ', ClientPrefs.lowQuality), () -> {
		lqButton.label.text = getBool('LowQ', ClientPrefs.lowQuality = !ClientPrefs.lowQuality);
	}));
	flButton = dbGroup.add(new FlxUIButton(GAYLINE * 2, 700, getBool('Flashing', ClientPrefs.flashing), () -> {
		flButton.label.text = getBool('Flashing', ClientPrefs.flashing = !ClientPrefs.flashing);
	}));
	shButton = dbGroup.add(new FlxUIButton(GAYLINE * 3, 700, getBool('Shaders', ClientPrefs.shaders), () -> {
		shButton.label.text = getBool('Shaders', ClientPrefs.shaders = !ClientPrefs.shaders);
	}));
	msButton = dbGroup.add(new FlxUIButton(GAYLINE * 4, 700, getBool('MScroll', ClientPrefs.middleScroll), () -> {
		msButton.label.text = getBool('MScroll', ClientPrefs.middleScroll = !ClientPrefs.middleScroll);
		recalculateMiddlescroll();
	}));
	dsButton = dbGroup.add(new FlxUIButton(GAYLINE * 5, 700, getBool('DScroll', ClientPrefs.downScroll), () -> {
		dsButton.label.text = getBool('DScroll', ClientPrefs.downScroll = !ClientPrefs.downScroll);
	}));
	
	playbackBG = dbGroup.add(new FlxUIButton(GAYLINE, 644));
	playbackBG.resize(440, 50);
	playbackBG.active = false;
	
	playbackSlider = dbGroup.add(new flixel.addons.ui.FlxSlider(game, 'playbackRate', GAYLINE + 6, 644, .25, 4, 413, 16, 6, 0xff333333, 0xff333333));
	playbackSlider.minLabel.alpha = playbackSlider.maxLabel.alpha = playbackSlider.body.alpha = .5;
	playbackSlider.minLabel.x += 4;
	playbackSlider.maxLabel.x += 3;
	playbackSlider.decimals = 2;
	playbackSlider.minLabel.y = playbackSlider.maxLabel.y = playbackSlider.valueLabel.y -= 5;
	playbackSlider.nameLabel.text = 'Playback Rate';
	playbackSlider.nameLabel.y += 5;
}

var warping:Bool = false;
function onUpdate()
{
	if (ClientPrefs.inDevMode || PlayState.chartingMode)
	{
		if (FlxG.keys.pressed.THREE)
		{
			playbackRate = (FlxG.keys.pressed.SHIFT ? .5 : 2);
			warping = true;
		}
		else if (warping)
		{
			playbackRate = 1;
			warping = false;
		}
	}
}

function recalculateMiddlescroll():Void
{
	for (playField in playFields)
	{
		if (playField.isPlayer)
		{
			modManager.setValue('opponentSwap', ClientPrefs.middleScroll ? .5 : 0, playField.ID);
			
			continue;
		}
		
		playField.visible = !ClientPrefs.middleScroll;
		
		modManager.setValue('alpha', ClientPrefs.middleScroll ? 1 : 0, playField.ID);
	}
}
