// If we move the ui edits in utils to the playhud then ill make this its own hud class otherwise heres my chopped cooked buns w salad code
import flixel.util.FlxSort;

import funkin.utils.SortUtil;
import funkin.game.shaders.RGBPalette;
import String; // yea. ok. whatever.

var finaleUIActive:Bool = false;
var ext:String = 'ui/finale/';
var newBar:Bar;
var blackPIcon:FlxSprite;

public var skinColors:Map<String, Array<FlxColor>> = [
	// public so hypothetically you can push your own
	// but u can use character flags now
	
	//              base        highlight   shadow
	'character' => [0xFFFD132B, 0xFFFC5D6A, 0xFF700E4A],
];

function onCreatePost()
{
	var isRGB:Bool = (boyfriend.healthColour != -13520687);
	var playerBar:String = (isRGB ? 'insideRGB' : 'insideBLUE');
	
	newBar = new Bar(0, FlxG.height - 198, ext + 'healthbarBG', function() return game.playHUD.healthLerp, game.healthBounds.min, game.healthBounds.max);
	newBar.barWidth -= 230;
	newBar.leftBar.loadGraphic(Paths.image(ext + 'insideRED'));
	newBar.rightBar.loadGraphic(Paths.image(ext + playerBar));
	newBar.leftToRight = false;
	newBar.forEachAlive(obj -> {
		obj.scale.set(0.6, 0.6);
		obj.updateHitbox();
	});
	if (ClientPrefs.downScroll)
	{
		newBar.flipY = true;
		newBar.y = -75;
	}
	newBar.screenCenter(FlxAxes.X);
	newBar.setColors(FlxColor.WHITE, FlxColor.WHITE);
	// dumb ordering shit fuck i hate it!
	newBar.bg.zIndex = 0;
	newBar.rightBar.zIndex = 1;
	newBar.leftBar.zIndex = 1;
	newBar.visible = false;
	playHUD.insert(0, newBar);
	newBar.sort(SortUtil.sortByZ, FlxSort.ASCENDING);
	
	if (isRGB)
	{
		var rgbShader = initRGBPalette(boyfriend);
		newBar.rightBar.shader = rgbShader.shader;
	}
	
	blackPIcon = new FlxSprite(45, ClientPrefs.downScroll ? -125 : 390);
	blackPIcon.frames = Paths.getSparrowAtlas('icons/icon-blackFinale');
	blackPIcon.scale.set(0.8, 0.8);
	blackPIcon.updateHitbox();
	blackPIcon.animation.addByPrefix('winning', 'black icon calm0', 24, true);
	blackPIcon.animation.addByPrefix('losing', 'black icon mad0', 24, true);
	blackPIcon.animation.play('winning');
	blackPIcon.offset.set(0, 0);
	blackPIcon.visible = false;
	playHUD.add(blackPIcon);
}

public function finaleUIOn()
{
	finaleUIActive = true;
	playHUD.healthBar.kill();
	playHUD.healthBar = newBar;
	newBar.revive();
	newBar.visible = true;
	playHUD.iconP1.visible = true;
	blackPIcon.visible = true;
	playHUD.iconP1.x = newBar.x + (newBar.width / 1.4) + 40;
	playHUD.iconP1.y = newBar.y + 60;
	if (ClientPrefs.downScroll) playHUD.iconP1.y += 10;
}

function onUpdate(elapsed)
{
	if (!finaleUIActive) return;
	
	var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(newBar.valueFunction(), newBar.bounds.min, newBar.bounds.max), newBar.bounds.min, newBar.bounds.max, 0, 100);
	newBar.percent = (newPercent != null ? newPercent : 0);
	updateParasiteIcon((100 - playHUD.healthBar.percent) * 0.01);
}

function updateParasiteIcon(curHealth:Float)
{
	if (curHealth < 0.2)
	{
		blackPIcon.animation.play('losing');
		blackPIcon.offset.set(0, 39);
	}
	else
	{
		blackPIcon.animation.play('winning');
		blackPIcon.offset.set(0, 0);
	}
}

function initRGBPalette(character:Character)
{
	var newRGB = new RGBPalette();
	var flagColors = character.getFlag('finaleHealthBarColor');
	
	if (flagColors != null)
	{
		newRGB.setColors([for (color in flagColors) (Std.isOfType(color, String) ? Std.parseInt(color) : Std.int(color))]);
	}
	else if (skinColors.exists(character.curCharacter))
	{
		newRGB.setColors(skinColors.get(character.curCharacter));
	}
	else // auto color
	{
		var color = boyfriend.healthColour;
		var hsb = [FlxColor.getHue(color), FlxColor.getSaturation(color), FlxColor.getBrightness(color)];
		newRGB.setColors([ // the dazzen formula.
			color,
			FlxColor.fromHSB(FlxMath.mod(hsb[0] - 30 + FlxColor.getYellow(color) * 80, 360), Math.min(hsb[1] * .75, 1), Math.min(hsb[2] * 2, 1.5)),
			FlxColor.subtract(
				FlxColor.fromHSB(
					FlxMath.mod(hsb[0] - 70 + 90 * (FlxColor.getCyan(color) - FlxColor.getYellow(color) * .6 + FlxColor.getMagenta(color) * .6) + 100 * (FlxColor.getGreenFloat(color) - FlxColor.getCyan(color) * .5), 360),
					Math.min(hsb[1] * 2 - (1 - FlxColor.getBrightness(color)), 1),
					FlxMath.bound(hsb[2] * .9 - FlxColor.getMagenta(color) * .85 - FlxColor.getCyan(color) * .35 + FlxColor.getBlueFloat(color) * .35 + FlxColor.getYellow(color) * .7 - (.6 - hsb[1]) * .2, 0, 1)
				),
				FlxColor.fromRGB(64, 24, 16)
			)
		]);
	}
	
	return newRGB;
}

function opponentNoteHit(note)
{
	if (!finaleUIActive) return;
	
	if (health > .2) health -= (Math.max(health - .2, 0) * (note.isSustainNote ? .005 : .1));
}
