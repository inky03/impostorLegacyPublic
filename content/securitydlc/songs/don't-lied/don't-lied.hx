import funkin.backend.FunkinShader.FunkinRuntimeShader;

var lightsShader:FunkinRuntimeShader;
public var dimShader = (ClientPrefs.shaders ? new funkin.game.shaders.ColorMatrixShader() : null);
public var hudDarkShader:ExtraDropShadowShader;
public var darkShader:ExtraDropShadowShader;
public var vignette:Bool = false;
var ouch:Bool = false;
var hesDying:Bool = false;
var dieMiss:Bool = false;
var isDark:Bool = false;
var fakeIcon:FlxSprite;
var variant = boyfriend.getFlag('variants')?.stabbed;
var noshader:Bool = false;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

function onLoad()
{
    videoCutscene('dontlied', true);

	addCharacterToList('bfweird', 0);
	
	darkShader = new funkin.game.shaders.ExtraDropShadowShader();
	darkShader.antialiasStages = 4;
	darkShader.threshold = .03;
	darkShader.setHollowColorMatrix([
		0, 0, 0, 0, 255,
		0, 0, 0, 0, 255,
		0, 0, 0, 0, 255,
		0, 0, 0, 1, 0
	]);
	darkShader.setColorMatrix([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 1, 0
	]);
	
	hudDarkShader = new funkin.game.shaders.ExtraDropShadowShader().copyFrom(darkShader);
	hudDarkShader.threshold = .12;
	hudDarkShader.setHollowColorMatrix([
		0, 0, 0, 0, 224,
		0, 0, 0, 0, 224,
		0, 0, 0, 0, 224,
		0, 0, 0, 1, 0
	]);
	
	darkShader.addLayer([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 1, 0
	], -70, 22, 0);
	darkShader.addLayer([
		0, 0, 0, 0, 255,
		0, 0, 0, 0, 255,
		0, 0, 0, 0, 255,
		0, 0, 0, 1, 0
	], 140, 10, 0);
	darkShader.addLayer([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 1, 0
	], -32, 12, 0);
	
	darkShader.attachedSprite = boyfriend;
	boyfriend.useRenderTexture = true;
	boyfriend.shader = null;
}

function onCreatePost()
{
	fakeIcon = new HealthIcon('purple', false);
	fakeIcon.cameras = [camHUD];
	fakeIcon.setPosition(playHUD.iconP2.x, playHUD.iconP2.y);
	playHUD.iconP2.visible = false;
	if (!ClientPrefs.hideHud) playHUD.insert(playHUD.members.indexOf(playHUD.iconP2), fakeIcon);
}
function onUpdate(elapsed)
{
	fakeIcon.x = playHUD.healthBar.barCenter - (150 / 2) - 26 * 2;
}

function onStepHit() //a way to do events in the song script instead of events.json
{
	switch (curStep)
	{
		case 18:
	    	FlxTween.tween(camGame, {zoom: 0.75}, 1, {ease: FlxEase.quadInOut});
		case 80:
	    	FlxTween.tween(camGame, {zoom: 0.78}, 1, {ease: FlxEase.quadInOut});
		case 132:
	    	FlxTween.tween(camGame, {zoom: 0.75}, 0.5, {ease: FlxEase.quadInOut});
		case 140:
	    	FlxTween.tween(camGame, {zoom: 0.78}, 0.5, {ease: FlxEase.quadOut});
		case 144:
	    	FlxTween.tween(camGame, {zoom: 0.79}, 0.5, {ease: FlxEase.quadOut});
		case 208:
	    	FlxTween.tween(camGame, {zoom: 0.8}, 0.5, {ease: FlxEase.quadOut});
		case 224:
	    	FlxTween.tween(camGame, {zoom: 0.79}, 0.5, {ease: FlxEase.quadOut});
		case 272:
	    	FlxTween.tween(camGame, {zoom: 0.7}, 2, {ease: FlxEase.quadOut});
		case 408:
	    	FlxTween.tween(camGame, {zoom: 0.85}, 1, {ease: FlxEase.quadInOut});
		case 416:
	    	FlxTween.tween(camGame, {zoom: 0.7}, 2, {ease: FlxEase.quadOut});
		case 612:
	    	FlxTween.tween(camGame, {zoom: 0.75}, 0.2, {ease: FlxEase.quadOut});
        case 654:
	    	FlxTween.tween(camGame, {zoom: 0.68}, 0.5, {ease: FlxEase.quadOut});
        case 662:
	    	FlxTween.tween(camGame, {zoom: 0.75}, 1, {ease: FlxEase.quadOut});
		case 672:
	    	FlxTween.tween(camGame, {zoom: 0.78}, 0.2, {ease: FlxEase.quadOut});
        case 676:
	    	FlxTween.tween(camGame, {zoom: 0.8}, 0.2, {ease: FlxEase.quadOut});
        case 678:
	    	FlxTween.tween(camGame, {zoom: 0.73}, 2, {ease: FlxEase.quadInOut});
        case 736:
	    	FlxTween.tween(camGame, {zoom: 0.70}, 1, {ease: FlxEase.quadOut});
        case 800:
	    	FlxTween.tween(camGame, {zoom: 0.75}, 1, {ease: FlxEase.quadOut});
        case 928:
	    	FlxTween.tween(camGame, {zoom: 0.7}, 1, {ease: FlxEase.quadOut});
        case 1056:
	    	FlxTween.tween(camGame, {zoom: 0.73}, 0.5, {ease: FlxEase.quadOut});
        case 1180:
	    	FlxTween.tween(camGame, {zoom: 0.70}, 0.5, {ease: FlxEase.quadOut});
	    	
		case 1184:
	    	triggerEventNote('Lights out', '', '');
	    	camSpecialThing([640, 450], [980, 480]);
            FlxTween.tween(camGame, {zoom: 0.9}, 20, {ease: FlxEase.quadInOut});
			PlayState.instance.triggerEventNote("Alt Idle Animation", "Dad", "-alt");
			fakeIcon.changeIcon('purple', false);
			
		case 1232:
	    	dad.x = 690;
	    	
		case 1376:
	    	triggerEventNote('Lights on', '', '');
			camSpecialThing([640, 450], [810, 450]);
			
        case 1394:
			hesDying = true;
            FlxTween.tween(camGame, {zoom: 0.85}, 1, {ease: FlxEase.quadInOut});
			dad.animation.play(boyfriend.getFlag('seeThrough') ? 'ghoststab' : 'stab', true);
			dad.specialAnim = true;
		case 1396:
			boyfriend.canTaunt = false;
	    	blooodfuckkk.alpha = 0.8;
            camSpecialThing([640, 450], [810, 470]);
	    	FlxTween.tween(blooodfuckkk, {alpha: 0.2}, 2, {ease: FlxEase.quadInOut});
			gf.animation.play('sad', true);
			gf.specialAnim = true;
	    	FlxTween.tween(dad, {x: dad.x - 75}, 6, {ease: FlxEase.quadInOut});
	    	
			if (variant != null)
			{
				changeCharacter(variant, 0);
			}
	    	else
	    	{
	    		// this is gona look really funny on jads
	    		dieMiss = boyfriend.skipDance = true;
	    	}
        	ouch = true;
			if (boyfriend.curCharacter == 'yellowplayablestabbed')
			{
				boyfriend.animation.play('stabbed', true);
				boyfriend.specialAnim = true;
			}
		case 1408:
			ouch = false; //well that was short
			for (anim in boyfriend.animation.getAnimationList()) anim.frameRate = Std.int(anim.frameRate * .75);
			
            FlxTween.tween(camGame, {zoom: 0.9}, 20);
		    FlxTween.tween(loBlack2, {alpha: 1}, 20);
		    
			triggerEventNote("Alt Idle Animation", "Dad", boyfriend.getFlag('seeThrough') ? '-bruh' : '-fart'); 
	}
	if (curBeat >= 1184) light.animation.play('lightsoff', true);
}
function onEvent(name, v1, v2)
{
	switch (name)
	{
		case 'Lights out':
			isDark = true;
        	camGame.flash(ClientPrefs.flashing ? FlxColor.WHITE : FlxColor.BLACK, 0.5); //checks if user has photosensitive mode on
			gf.alpha = 0.001;
			pet.kill();
			playHUD.iconP1.shader = hudDarkShader;
			
			var dark:Null<String> = boyfriend.getFlag('variants')?.dark;
			if (dark != null)
			{
				changeCharacter(dark, 0);
				boyfriend.shader = null;
				noshader = true;
			}
			else if (boyfriend.getFlag('dark') != true)
			{
				boyfriend.shader = darkShader;
			}
            dad.shader = null;
			dad.alpha = 0.001;
            loBlack.alpha = 1;
            guy2.alpha = 0.001;
            guy3.alpha = 0.001;
			fakeIcon.kill();
			playHUD.healthBar.setColors(FlxColor.BLACK, 0xffe0e0e0);
			playHUD.healthBar.bg.setColorTransform(0, 0, 0, 1, 224, 224, 224);
			light.alpha = 0.001;
			
		case 'Lights on':
			isDark = false;
            loBlack.alpha = 0.001;
			
			if (noshader) changeCharacter(hasBfSkin ? ClientPrefs.bfSkin : PlayState.SONG.player1, 0);
			boyfriend.shader = null;
			dad.alpha = 1;
			gf.alpha = 1;
			playHUD.iconP1.shader = null;
			camGame.flash(FlxColor.BLACK, 0.35);
            guy2.alpha = 1;
            guy3.alpha = 1;
			playHUD.healthBar.bg.setColorTransform();
			
			if (!ClientPrefs.hideHud)
			{
				fakeIcon.revive();
				fakeIcon.changeIcon('purplehi');
			}
			
			light.alpha = 1;
	}
}

function opponentNoteHit(note)
{	
	if (health > 0.2) health -= 0.02;
}

function onGhostAnim(anim, note)
{
	if (isDark) return Function_Stop;
}
function goodNoteHitPre(note)
{
	if (ouch)
	{
		if (dieMiss && boyfriend.hasAnim('singLEFTmiss'))
			note.animSuffix = 'miss';
		if (boyfriend.curCharacter == 'yellowplayablestabbed')
			note.noAnimation = true;
	}
}
function goodNoteHit(note)
{
	if (hesDying) {
		if (FlxG.random.bool(30)) FlxTween.shake(boyfriend, .005, .05, FlxAxes.X);
		if (FlxG.random.bool(30)) FlxTween.shake(boyfriend, .003, .05, FlxAxes.Y);
		
		if (health > 0.2)
			health -= 0.035;
	}
}