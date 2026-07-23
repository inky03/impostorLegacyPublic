package funkin.backend.among;

import flixel.util.FlxStringUtil;
import flixel.addons.display.FlxBackdrop;

import funkin.data.CosmicubeData;

class AmongUIState extends MusicBeatState
{
	var camUpper:FlxCamera;
	var backButton:FlxSprite;
	var upperBar:FlxSprite;
	var beanIcon:FlxSprite;
	var beanText:FlxText;
	
	var starsBG:FlxSprite;
	var starsFG:FlxSprite;
	
	public var localBeans(default, set):Int;
	public var localCurrency(default, set):Null<String>;
	public var lockMovement:Bool = false;
	
	public var returnState:Class<flixel.FlxState> = MainMenuState;
	
	public override function create():Void
	{
		super.create();
		
		var ext:String = 'menu/common';
		
		camUpper = new FlxCamera();
		camUpper.bgColor.alpha = 0;
		FlxG.cameras.add(camUpper, false);
		
		starsBG = new FlxBackdrop(Paths.image('$ext/starBG'));
		starsBG.scrollFactor.set();
		starsBG.velocity.x = -4.5;
		starsBG.zIndex = -2;
		add(starsBG);
		
		starsFG = new FlxBackdrop(Paths.image('$ext/starFG'));
		starsFG.scrollFactor.set();
		starsFG.velocity.x = -9;
		starsFG.zIndex = -1;
		add(starsFG);
		
		upperBar = new FlxSprite(-2, -1.4, Paths.image('$ext/topBar'));
		backButton = new FlxSprite(12, 8).loadGraphic(Paths.image('$ext/menuBack'));
		backButton.kill();
		
		beanIcon = new FlxSprite(30, 100);
		beanIcon.zIndex = 3;
		
		beanText = new FlxText(110, 105, 300, '---', 35);
		beanText.setFormat(Paths.font("ariblk.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		beanText.borderSize = 3;
		beanText.zIndex = 2;
		
		beanIcon.camera = beanText.camera = upperBar.camera = backButton.camera = camUpper;
		
		localCurrency = CosmicubeData.currentCurrency;
	}
	
	public override function update(elapsed:Float):Void
	{
		if (!lockMovement && (controls.BACK || (backButton.alive && FlxG.mouse.justPressed && FlxG.mouse.overlaps(backButton, camUpper)))) exit();
		
		super.update(elapsed);
	}
	
	public function exit():Void
	{
		if (lockMovement) return;
		
		lockMovement = true;
		
		FlxG.sound.play(Paths.sound('cancelMenu'), .6);
		FlxG.switchState(() -> Type.createInstance(returnState, []));
	}
	
	override function destroy():Void
	{
		upperBar = FlxDestroyUtil.destroy(upperBar);
		backButton = FlxDestroyUtil.destroy(backButton);
		beanText = FlxDestroyUtil.destroy(beanText);
		beanIcon = FlxDestroyUtil.destroy(beanIcon);
		
		CosmicubeData.setMoney(localCurrency, localBeans);
		
		ClientPrefs.flush();
		
		super.destroy();
	}
	
	function set_localBeans(v:Int):Int
	{
		beanText.text = FlxStringUtil.formatMoney(v, false);
		
		return localBeans = v;
	}
	
	function set_localCurrency(v:Null<String>):Null<String>
	{
		if (localCurrency != v)
		{
			if (localCurrency != null) CosmicubeData.setMoney(localCurrency, localBeans); // save the last one
			
			FlxTween.cancelTweensOf(beanIcon);
			FlxTween.cancelTweensOf(beanText);
			
			if (v == null || v.length == 0)
			{
				FlxTween.tween(beanIcon, {x: beanIcon.x - 30, alpha: 0}, .2, {ease: FlxEase.quartIn});
				FlxTween.tween(beanText, {x: beanText.x - 30, alpha: 0}, .2, {ease: FlxEase.quartIn});
				
				localBeans = 0;
				
				return localCurrency = v;
			}
			
			beanIcon.revive();
			beanText.revive();
			beanIcon.loadGraphic(Paths.image('currency/$v', LOOSE));
			
			localBeans = CosmicubeData.getMoney(v);
			
			beanIcon.x = 0;
			beanText.x = 80;
			beanText.alpha = beanIcon.alpha = 0;
			
			FlxTween.tween(beanIcon, {x: beanIcon.x + 30, alpha: 1}, .2, {ease: FlxEase.quartOut});
			FlxTween.tween(beanText, {x: beanText.x + 30, alpha: 1}, .2, {ease: FlxEase.quartOut});
		}
		
		return localCurrency = v;
	}
}
