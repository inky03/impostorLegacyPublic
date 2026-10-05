package funkin.states.substates;

import funkin.backend.MusicBeatSubstate;
import funkin.objects.HealthIcon;

class AttackCharSelectSubstate extends MusicBeatSubstate
{
	var curSelection:Int = 0;
	var bg:flixel.system.FlxBGSprite;
	var selectionArrow:FlxSprite;
	var overlayCamera:FunkinCamera;
	
	public var canMove = false;
	
	var clowfoe:HealthIcon;
	var monotone:HealthIcon;
	var fabs:HealthIcon;
	var biddle:HealthIcon;
	var iconArray:Array<HealthIcon> = [];
	
	override function create()
	{
		/**
		 * TODo: Clean up this menu
		**/
		canMove = false;
		
		overlayCamera = new FunkinCamera();
		overlayCamera.bgColor = 0x00000000;
		overlayCamera.antialiasing = ClientPrefs.globalAntialiasing;
		FlxG.cameras.add(overlayCamera, false);
		
		camera = overlayCamera;
		
		bg = new flixel.system.FlxBGSprite();
		bg.color = FlxColor.BLACK;
		bg.alpha = 0;
		add(bg);
		
		clowfoe = new HealthIcon('bfclow', false);
		clowfoe.screenCenter();
		clowfoe.x -= 480;
		clowfoe.alpha = 0;
		add(clowfoe);
		iconArray.push(clowfoe);
		
		monotone = new HealthIcon('attack', false);
		monotone.screenCenter();
		monotone.x -= 160;
		monotone.alpha = 0;
		add(monotone);
		iconArray.push(monotone);
		
		fabs = new HealthIcon('fabs', false);
		fabs.screenCenter();
		fabs.x += 160;
		fabs.alpha = 0;
		add(fabs);
		iconArray.push(fabs);
		
		biddle = new HealthIcon('biddle', false);
		biddle.screenCenter();
		biddle.x += 480;
		biddle.alpha = 0;
		add(biddle);
		iconArray.push(biddle);
		
		selectionArrow = new FlxSprite(0, 550).loadGraphic(Paths.image('menu/freeplay/miss/missAmountArrow'));
		selectionArrow.alpha = 0;
		selectionArrow.flipY = true;
		add(selectionArrow);
		
		var introTweenCount:Int = 0;
		function completeIntroTween():Void
		{
			introTweenCount--;
			if (introTweenCount <= 0)
			{
				canMove = true;
			}
		}
		
		for (obj in members)
		{
			if (obj == null || !Std.isOfType(obj, FlxSprite)) continue;
			
			var sprite:FlxSprite = cast obj;
			FlxTween.cancelTweensOf(sprite);
			sprite.alpha = 0;
			var targetAlpha:Float = obj == bg ? 0.5 : 1;
			introTweenCount++;
			FlxTween.tween(sprite, {alpha: targetAlpha}, 0.35,
				{
					ease: FlxEase.circOut,
					onComplete: function(_) completeIntroTween()
				});
		}
		changeSelection(0);
		
		var bottomControls = new funkin.objects.menu.AmongControls([
			['arrow', 'select'], // select
			['enter', 'conf'], // conf
			['esc', 'back'] // back
		], false);
		bottomControls.zIndex = 10;
		add(bottomControls);
		
		bottomControls.alpha = 0;
		FlxTween.tween(bottomControls, {alpha: 1}, 0.35, {ease: FlxEase.circOut});
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		if (canMove)
		{
			if (controls.UI_RIGHT_P) changeSelection(1);
			if (controls.UI_LEFT_P) changeSelection(-1);
			
			if (FlxG.mouse.justPressed)
			{
				for (i => icon in iconArray)
				{
					if (!FlxG.mouse.overlaps(icon, camera)) continue;
					
					if (curSelection != i)
					{
						changeSelection(i - curSelection);
					}
					else
					{
						confirm();
					}
				}
			}
			
			if (controls.ACCEPT) confirm();
			
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
				cancel();
			}
		}
		super.update(elapsed);
	}
	
	function changeSelection(by:Int)
	{
		if (by != 0) FlxG.sound.play(Paths.sound('hover'), .5);
		
		curSelection = FlxMath.wrap(curSelection + by, 0, 3);
		
		selectionArrow.x = iconArray[curSelection].x + 25;
	}
	
	function confirm()
	{
		if (!canMove) return;
		
		canMove = false;
		
		PlayState.attackCharacter = curSelection;
		
		FlxG.sound.play(Paths.sound('confirmMenu'), .5);
		
		FreeplayState.loadSong('Monotone Attack');
	}
	
	function cancel()
	{
		if (!canMove) return;
		
		for (obj in members)
		{
			if (obj == null || !Std.isOfType(obj, FlxSprite)) continue;
			
			var sprite:FlxSprite = cast obj;
			FlxTween.cancelTweensOf(sprite);
			FlxTween.tween(sprite, {alpha: 0}, 0.25,
				{
					ease: FlxEase.circIn,
					onComplete: (t:FlxTween) -> {
						sprite.kill();
					}
				});
		}
		FlxTimer.wait(0.25, close);
	}
}
