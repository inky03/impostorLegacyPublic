package funkin.states.substates;

import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.backend.MusicBeatSubstate;

import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxSpriteGroup;

typedef FreeplayWeek =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var section:String;
	var ?mod:String;
	var title:String;
}

class WeekPickerSubstate extends MusicBeatSubstate
{
	// IM GOING TO KILL MYSEEEEEEEEEEEEEELF
	public var weeks:Array<FreeplayWeek> = []; // Freeplay Weeks, put your shit in here
	public var parent:FreeplayState;
	
	var bg:FlxSprite;
	var bgThing:FlxSprite;
	var cubeCamera:FlxCamera;
	var menuBackButton:FlxSprite;
	var otherTitleText:FlxText;
	
	var bubl:FlxSpriteGroup;
	var CIRCLE_PADDING:Float = 12;
	var CIRC_WRAP = 7;
	var curSelection:Int = 0;
	var WEEKS_WRAP = 0;
	var lockMovement:Bool = true;
	final uiTweenOffsetY:Float = 120;
	
	public function new(parent:FreeplayState, month:Int = 0)
	{
		camera = CameraUtil.lastCamera;
		
		this.weeks = (this.parent = parent).weeks;
		curSelection = month;
		
		super();
		
		bg = new flixel.system.FlxBGSprite();
		bg.color = FlxColor.BLACK;
		bg.alpha = 0;
		add(bg);
		// sorry bullshit
		bgThing = new FlxSprite().loadGraphic(Paths.image('menu/freeplay/resetPrompt'));
		bgThing.screenCenter();
		add(bgThing);
		(cubeCamera = new FunkinCamera(bgThing.x + 6, bgThing.y + 67, 620, 234)).bgColor = FlxColor.BLACK;
		FlxG.cameras.add(cubeCamera, false);
		
		otherTitleText = new FlxText(340, 205, 0, Lang.str('freeplay'), 50);
		otherTitleText.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 50, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		otherTitleText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		add(otherTitleText);
		
		menuBackButton = new FlxSprite(bgThing.x + bgThing.width - 5, bgThing.y + 5).loadGraphic(Paths.image('menu/common/menuBack'));
		menuBackButton.x -= menuBackButton.width;
		add(menuBackButton);
	}
	
	override function create()
	{
		var iX = 0;
		var iY = .05;
		
		WEEKS_WRAP = weeks.length;
		var starsBG:FlxBackdrop = new FlxBackdrop(Paths.image('menu/common/starBG'));
		starsBG.camera = cubeCamera;
		starsBG.scrollFactor.set();
		starsBG.velocity.x = -4.5;
		add(starsBG);
		
		bubl = new FlxSpriteGroup();
		bubl.camera = cubeCamera;
		add(bubl);
		for (i in 0...WEEKS_WRAP)
		{
			if (iX > CIRC_WRAP)
			{
				iX = 0;
				iY += 1;
			}
			
			Mods.currentModDirectory = weeks[i].mod;
			
			var w:String = weeks[i].section;
			var circ:FlxSprite = new FlxSprite(0, Std.int(iY * 78)).loadGraphic(Paths.image('menu/freeplay/sections/$w'));
			circ.setGraphicSize(-1, 71);
			circ.updateHitbox();
			circ.x = iX * 78; // Std.int(FlxMath.remapToRange(iX, 0, CIRC_WRAP - 1, 0, Math.min((CIRC_WRAP - 1) * (71 + CIRCLE_PADDING), 1110)) - circ.width);
			circ.ID = i;
			bubl.add(circ);
			
			iX += 1;
		}
		
		bubl.x = Std.int((cubeCamera.width - bubl.width) * .5 - bubl.findMinX());
		
		Mods.currentModDirectory = null;
		
		super.create();
		changeSelection();
		
		FlxTween.tween(bg, {alpha: .72}, .35, {ease: FlxEase.circOut});
		
		for (obj in [bgThing, otherTitleText, menuBackButton])
		{
			var alpha:Float = obj.alpha;
			obj.alpha = 0;
			obj.y += uiTweenOffsetY;
			var tween = FlxTween.tween(obj, {y: obj.y - uiTweenOffsetY, alpha: alpha}, .35, {ease: FlxEase.circOut});
			
			if (obj == bgThing)
			{
				tween.onUpdate = function(_) {
					cubeCamera.y = bgThing.y + 67;
				};
			}
		}
		
		for (obj in bubl.members)
		{
			if (obj == null) continue;
			
			var alpha:Float = obj.alpha;
			obj.alpha = 0;
			FlxTween.tween(obj, {alpha: alpha}, .35, {ease: FlxEase.circOut});
		}
		
		new FlxTimer().start(.35, function(_) lockMovement = false);
	}
	
	function updateItems()
	{
		for (i in bubl)
			i.alpha = i.ID == curSelection ? 1 : .72;
	}
	
	function changeSelection(by = 0)
	{
		if (curSelection + by > WEEKS_WRAP - 1 || curSelection + by < 0) return;
		if (by != 0) FlxG.sound.play(Paths.sound('hover'), 0.5);
		
		curSelection = Std.int(FlxMath.bound(curSelection + by, 0, WEEKS_WRAP - 1));
		updateItems();
		// trace([WEEKS_WRAP, curSelection]);
	}
	
	function acceptWeek(sect:Int)
	{
		parent.goToSection(sect, true);
		FlxG.sound.play(Paths.sound('panelAppear'), .5);
		close();
	}
	
	function closeWeek()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'), 1);
		close();
	}
	
	override function update(elapsed:Float)
	{
		if (lockMovement)
		{
			super.update(elapsed);
			return;
		}
		
		if (FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getWorldPosition();
			
			if (menuBackButton.overlapsPoint(mousePos))
			{
				closeWeek();
			}
			for (i in bubl.members)
			{
				if (FlxG.mouse.overlaps(i, cubeCamera))
				{
					if (curSelection == i.ID)
					{
						acceptWeek(curSelection);
						break;
					}
					curSelection = i.ID;
					FlxG.sound.play(Paths.sound('hover'), 0.5);
					updateItems();
				}
			}
		}
		if (controls.UI_LEFT_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(CIRC_WRAP + 1);
		if (controls.UI_UP_P) changeSelection(-CIRC_WRAP - 1);
		if (controls.UI_RIGHT_P) changeSelection(1);
		if (controls.BACK) closeWeek();
		if (controls.ACCEPT)
		{
			acceptWeek(curSelection);
		}
		var ugh = FlxMath.bound((curSelection - CIRC_WRAP - 1) / (CIRC_WRAP + 1), 0, WEEKS_WRAP);
		cubeCamera.scroll.y = FlxMath.lerp(cubeCamera.scroll.y, Math.floor(ugh) * 78, FlxMath.bound(elapsed * 15.6, 0, 1));
	}
	
	override function destroy()
	{
		for (obj in members)
		{
			if (obj != null) FlxTween.cancelTweensOf(obj);
		}
		
		if (cubeCamera != null)
		{
			FlxG.cameras.remove(cubeCamera, true);
			cubeCamera = null;
		}
		
		super.destroy();
	}
}
