package funkin.states.substates;

import funkin.backend.MusicBeatSubstate;
import funkin.data.CharacterData.CharacterParser;
import funkin.data.CosmicubeData;
import funkin.objects.menu.ScrollBar;
import funkin.objects.menu.AmongControls;
import funkin.input.TurboControl;

import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class CosmeticsSubstate extends MusicBeatSubstate
{
	static var hasPreloadedForSession:Bool = false;
	
	public static function preloadForFreeplay():Void
	{
		if (!hasPreloadedForSession)
		{
			Paths.image('menu/freeplay/select');
			Paths.image('menu/freeplay/skin thing');
			Paths.image('menu/common/reset');
			Paths.image('menu/common/menuBack');
			Paths.getSparrowAtlas('menu/cosmicube/node');
			Paths.image('menu/cosmicube/items/default');
			Paths.image('menu/cosmicube/items/defaultgf');
			hasPreloadedForSession = true;
		}
		
		var preloaded:Array<String> = [];
		
		for (itemID in ClientPrefs.cosmicubeUnlocks)
			if (itemID != null && !preloaded.contains(itemID)) preloaded.push(itemID);
		for (equipKey in ['playerSkin', 'speakerSkin', 'pet'])
		{
			var id = ClientPrefs.equipment.get(equipKey);
			if (id != null && !preloaded.contains(id)) preloaded.push(id);
		}
		
		for (id in preloaded)
		{
			if (!Paths.fileExists('images/menu/cosmicube/items/$id.png', LOOSE)) continue;
			Paths.image('menu/cosmicube/items/$id', LOOSE);
		}
	}
	
	var canMove:Bool = false;
	var isClosing:Bool = false;
	var inGrid:Bool = false; // False is the base Locker UI, true is the Grid containing all of your items of a certain type.
	var mouseMode:Bool = false;
	var overlayCameras:Array<FlxCamera>;
	var overlayCamera:FlxCamera;
	var gridCamera:FlxCamera;
	var gridCameras:Array<FlxCamera>;
	
	var bg:FlxSprite;
	var selectSprite:FlxSprite;
	var skinThingBg:FlxSprite;
	var skinTop:FlxSprite;
	var menuBackButton:FlxSprite;
	var resetButton:FlxSprite;
	var randomButton:FlxSprite;
	var resetLabel:FlxText;
	var randomLabel:FlxText;
	var titleText:FlxText;
	
	var categoryTexts:Array<FlxText> = [];
	var categoryPreviewBgs:Array<FlxSprite> = [];
	var categoryPreviewWhites:Array<FlxSprite> = [];
	var categoryPreviewOverlays:Array<FlxSprite> = [];
	var categoryPreviewPortraits:Array<FlxSprite> = [];
	var categoryPreviewPortraitIds:Array<String> = [];
	var categoryPreviewFallbacks:Array<FlxText> = [];
	var selectedCategory:Int = 0;
	
	static inline final GRID_COLS:Int = 3;
	static inline final GRID_CARD_SCALE:Float = 0.55;
	static inline final GRID_SPACING_X:Float = 160;
	static inline final GRID_SPACING_Y:Float = 160;
	static inline final SCROLLBAR_WIDTH:Int = 8;
	static inline final SCROLLBAR_MARGIN:Int = 40;
	
	var gridNodes:Array<FlxSprite> = [];
	var gridWhites:Array<FlxSprite> = [];
	var gridOverlays:Array<FlxSprite> = [];
	var gridPortraits:Array<FlxSprite> = [];
	var gridPortraitIds:Array<String> = [];
	var gridFallbacks:Array<FlxText> = [];
	var gridItemIds:Array<String> = [];
	var gridCursorIndex:Int = 0;
	var gridItemLabel:FlxText;
	var gridScrollBar:ScrollBar;
	var gridScrollY:Float = 0;
	var gridTargetScrollY:Float = 0;
	var gridOriginY:Float = 200;
	
	public var autoScroll:Bool = true;
	
	var bfSkinList:Array<String> = [];
	var gfSkinList:Array<String> = [];
	var petList:Array<String> = [];
	var cosmeticDisplayNames:Map<String, String> = [];
	var cosmeticDataById:Map<String, ShopItemData> = [];
	var cosmeticColorCache:Map<String, FlxColor> = [];
	var _portraitCache:Map<String, Bool> = [];
	var controlsDisplay:AmongControls;
	
	var initialBFSkin:String;
	var initialGFSkin:String;
	var initialPet:String;
	
	var prevMod:Null<String>;
	
	final previewCardScale:Float = 0.7;
	final uiTweenOffsetY:Float = 120;
	
	var turboGroup:TurboControlGroup;
	var controlDOWN:TurboControl = TurboControl.fromControl('ui_down');
	var controlUP:TurboControl = TurboControl.fromControl('ui_up');
	var controlLEFT:TurboControl = TurboControl.fromControl('ui_left');
	var controlRIGHT:TurboControl = TurboControl.fromControl('ui_right');
	
	override function create()
	{
		CosmicubeData.reload(false);
		
		add(turboGroup = new TurboControlGroup());
		turboGroup.add(controlDOWN);
		turboGroup.add(controlUP);
		turboGroup.add(controlLEFT);
		turboGroup.add(controlRIGHT);
		
		overlayCamera = new FlxCamera();
		overlayCamera.bgColor = 0x00000000;
		overlayCamera.antialiasing = ClientPrefs.globalAntialiasing;
		FlxG.cameras.add(overlayCamera, false);
		overlayCameras = [overlayCamera];
		
		initialBFSkin = ClientPrefs.bfSkin;
		initialGFSkin = ClientPrefs.gfSkin;
		initialPet = ClientPrefs.pet;
		
		bg = new flixel.system.FlxBGSprite();
		bg.alpha = 0;
		bg.color = FlxColor.BLACK;
		bg.cameras = overlayCameras;
		add(bg);
		
		selectSprite = new FlxSprite().loadGraphic(Paths.image('menu/freeplay/select'));
		selectSprite.cameras = overlayCameras;
		selectSprite.x = (FlxG.width - selectSprite.width) * 0.5;
		selectSprite.y = (FlxG.height - selectSprite.height) * 0.5;
		add(selectSprite);
		
		skinThingBg = new FlxSprite().loadGraphic(Paths.image('menu/freeplay/skin thing'));
		skinThingBg.antialiasing = ClientPrefs.globalAntialiasing;
		skinThingBg.cameras = overlayCameras;
		skinThingBg.scale.set(1.1, 1.1);
		skinThingBg.updateHitbox();
		skinThingBg.x = (FlxG.width - skinThingBg.width) * 0.5;
		skinThingBg.y = (FlxG.height - skinThingBg.height) * 0.5;
		skinThingBg.visible = false;
		add(skinThingBg);
		
		skinTop = new FlxSprite().loadGraphic(Paths.image('menu/freeplay/skin top'));
		skinTop.antialiasing = ClientPrefs.globalAntialiasing;
		skinTop.cameras = overlayCameras;
		skinTop.scale.set(1.1, 1.1);
		skinTop.updateHitbox();
		skinTop.x = (FlxG.width - skinTop.width) * 0.5;
		skinTop.y = 57;
		skinTop.visible = false;
		add(skinTop);
		
		var maskInsetLeft:Float = 31;
		var maskInsetRight:Float = 31;
		var maskInsetTop:Float = 35;
		var maskInsetBottom:Float = 32;
		gridCamera = new FlxCamera();
		gridCamera.bgColor = 0x00000000;
		gridCamera.antialiasing = ClientPrefs.globalAntialiasing;
		gridCamera.setPosition(skinThingBg.x + maskInsetLeft, skinThingBg.y + maskInsetTop);
		gridCamera.setSize(Std.int(skinThingBg.width - maskInsetLeft - maskInsetRight), Std.int(skinThingBg.height - maskInsetTop - maskInsetBottom));
		gridCamera.scroll.set(skinThingBg.x + maskInsetLeft, skinThingBg.y + maskInsetTop);
		FlxG.cameras.add(gridCamera, false);
		gridCameras = [gridCamera];
		gridOriginY = (skinThingBg.y + skinThingBg.height * 0.5) - GRID_SPACING_Y;
		
		menuBackButton = new FlxSprite(950, 90).loadGraphic(Paths.image('menu/common/menuBack'));
		menuBackButton.antialiasing = ClientPrefs.globalAntialiasing;
		menuBackButton.cameras = overlayCameras;
		add(menuBackButton);
		
		randomButton = new FlxSprite(1025, 390).loadGraphic(Paths.image('menu/common/random'));
		randomButton.antialiasing = ClientPrefs.globalAntialiasing;
		randomButton.scale.set(0.5, 0.5);
		randomButton.updateHitbox();
		randomButton.cameras = overlayCameras;
		add(randomButton);
		
		// labels are attached to buttons because i changed where they were positioned 9billiontrillion times
		randomLabel = new FlxText(0, 0, 0, Lang.str('rand', 'RANDOM'), 30);
		randomLabel.setFormat(Paths.font('AmaticSC-Bold.ttf'), 30, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		randomLabel.borderSize = 2;
		randomLabel.cameras = overlayCameras;
		randomLabel.x = randomButton.x + (randomButton.width - randomLabel.width) * 0.5;
		randomLabel.y = randomButton.y + randomButton.height + 2;
		add(randomLabel);
		
		resetButton = new FlxSprite(1025, 515).loadGraphic(Paths.image('menu/common/reset'));
		resetButton.antialiasing = ClientPrefs.globalAntialiasing;
		resetButton.scale.set(0.5, 0.5);
		resetButton.updateHitbox();
		resetButton.cameras = overlayCameras;
		add(resetButton);
		
		resetLabel = new FlxText(0, 0, 0, Lang.str('reset', 'RESET'), 30);
		resetLabel.setFormat(Paths.font('AmaticSC-Bold.ttf'), 30, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		resetLabel.borderSize = 2;
		resetLabel.cameras = overlayCameras;
		resetLabel.x = resetButton.x + (resetButton.width - resetLabel.width) * 0.5;
		resetLabel.y = resetButton.y + resetButton.height + 2;
		add(resetLabel);
		
		titleText = new FlxText(280, 88, 0, Lang.str('locker', 'LOCKER'), 62);
		titleText.setFormat(Paths.font('AmaticSC-Bold.ttf'), 50, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.cameras = overlayCameras;
		add(titleText);
		
		var nodeAtlas = Paths.getSparrowAtlas('menu/cosmicube/node');
		for (i in 0...3)
		{
			var label = ['BF', 'GF', 'PET'][i];
			var yPos:Float = 220 + (i * 140);
			
			var optText = new FlxText(510, yPos, 500, '', 30);
			optText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			optText.borderSize = 2;
			optText.antialiasing = false;
			optText.cameras = overlayCameras;
			categoryTexts.push(optText);
			
			createCategoryPreviewCard(nodeAtlas, 395, yPos + (optText.height * 0.5), label);
		}
		
		for (t in categoryTexts)
			add(t);
			
		loadCosmeticLists();
		
		gridItemLabel = new FlxText(0, 590, FlxG.width, '', 22);
		gridItemLabel.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		gridItemLabel.borderSize = 2;
		gridItemLabel.antialiasing = false;
		gridItemLabel.cameras = overlayCameras;
		gridItemLabel.visible = false;
		add(gridItemLabel);
		
		var scrollBarHeight:Int = Std.int(skinThingBg.height - SCROLLBAR_MARGIN * 2);
		var scrollBarX:Float = 370;
		var scrollBarY:Float = skinThingBg.y + SCROLLBAR_MARGIN;
		
		gridScrollBar = new ScrollBar(scrollBarX, scrollBarY, SCROLLBAR_WIDTH, scrollBarHeight, 0xFF2C3F3F, 0xFF6B999B);
		gridScrollBar.minThumbHeight = 40;
		gridScrollBar.cameras = overlayCameras = gridScrollBar.track.cameras = overlayCameras = gridScrollBar.thumb.cameras = overlayCameras;
		gridScrollBar.onScroll.add(function(scroll:Float, _) gridTargetScrollY = gridScrollY = (scroll * getGridMaxScroll()));
		gridScrollBar.onInteract.add(function() autoScroll = false);
		gridScrollBar.visible = false;
		add(gridScrollBar);
		
		controlsDisplay = new AmongControls([
			['arrow', 'select'],
			['enter', 'conf'],
			['esc', 'back']
		], false);
		controlsDisplay.cameras = overlayCameras;
		add(controlsDisplay);
		
		updateCategoryDisplay();
		
		var tweensLeft:Int = 0;
		
		tweensLeft++;
		FlxTween.tween(bg, {alpha: 0.72}, 0.35,
			{
				ease: FlxEase.circOut,
				onComplete: function(_) {
					tweensLeft--;
					if (tweensLeft <= 0) canMove = true;
				}
			});
			
		for (obj in members)
		{
			if (obj == null || obj == bg || obj == controlsDisplay || !Std.isOfType(obj, FlxSprite)) continue;
			
			var sprite:FlxSprite = cast obj;
			FlxTween.cancelTweensOf(sprite);
			sprite.y += uiTweenOffsetY;
			sprite.alpha = 0;
			tweensLeft++;
			FlxTween.tween(sprite, {y: sprite.y - uiTweenOffsetY, alpha: 1}, 0.35,
				{
					ease: FlxEase.circOut,
					onComplete: function(_) {
						tweensLeft--;
						if (tweensLeft <= 0) canMove = true;
					}
				});
		}
		
		super.create();
	}
	
	function createCategoryPreviewCard(nodeAtlas:FlxAtlasFrames, centerX:Float, centerY:Float, fallbackText:String):Void
	{
		var bgSprite = new FlxSprite();
		bgSprite.frames = nodeAtlas;
		bgSprite.animation.addByPrefix('main', 'back');
		bgSprite.animation.play('main');
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;
		bgSprite.scale.set(previewCardScale, previewCardScale);
		bgSprite.updateHitbox();
		bgSprite.x = centerX - (bgSprite.width * 0.5);
		bgSprite.y = centerY - (bgSprite.height * 0.5);
		bgSprite.cameras = overlayCameras;
		add(bgSprite);
		
		var whiteSprite = new FlxSprite();
		whiteSprite.frames = nodeAtlas;
		whiteSprite.animation.addByPrefix('main', 'emptysquare');
		whiteSprite.animation.play('main');
		whiteSprite.antialiasing = ClientPrefs.globalAntialiasing;
		whiteSprite.scale.set(previewCardScale, previewCardScale);
		whiteSprite.updateHitbox();
		whiteSprite.x = centerX - (whiteSprite.width * 0.5);
		whiteSprite.y = centerY - (whiteSprite.height * 0.5);
		whiteSprite.cameras = overlayCameras;
		add(whiteSprite);
		
		var portraitSprite = new FlxSprite();
		portraitSprite.antialiasing = ClientPrefs.globalAntialiasing;
		portraitSprite.cameras = overlayCameras;
		add(portraitSprite);
		
		var overlaySprite = new FlxSprite();
		overlaySprite.frames = nodeAtlas;
		overlaySprite.animation.addByPrefix('main', 'overlay');
		overlaySprite.animation.play('main');
		overlaySprite.antialiasing = ClientPrefs.globalAntialiasing;
		overlaySprite.scale.set(previewCardScale, previewCardScale);
		overlaySprite.updateHitbox();
		overlaySprite.x = centerX - (overlaySprite.width * 0.5);
		overlaySprite.y = centerY - (overlaySprite.height * 0.5);
		overlaySprite.cameras = overlayCameras;
		add(overlaySprite);
		
		var fallbackLabel = new FlxText(0, 0, bgSprite.width, fallbackText, 24);
		fallbackLabel.setFormat(Paths.font('ariblk.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		fallbackLabel.borderSize = 2;
		fallbackLabel.antialiasing = ClientPrefs.globalAntialiasing;
		fallbackLabel.x = bgSprite.x;
		fallbackLabel.y = bgSprite.y + ((bgSprite.height - fallbackLabel.height) * 0.5);
		fallbackLabel.cameras = overlayCameras;
		add(fallbackLabel);
		
		categoryPreviewBgs.push(bgSprite);
		categoryPreviewWhites.push(whiteSprite);
		categoryPreviewPortraits.push(portraitSprite);
		categoryPreviewPortraitIds.push('');
		categoryPreviewOverlays.push(overlaySprite);
		categoryPreviewFallbacks.push(fallbackLabel);
	}
	
	function updatePreviewCard(index:Int, id:String, defaultText:String):Void
	{
		final bgSprite = categoryPreviewBgs[index];
		final whiteSprite = categoryPreviewWhites[index];
		final overlaySprite = categoryPreviewOverlays[index];
		final portraitSprite = categoryPreviewPortraits[index];
		final fallbackLabel = categoryPreviewFallbacks[index];
		
		final cardColor:FlxColor = getCosmeticColor(id);
		bgSprite.color = cardColor;
		overlaySprite.color = cardColor;
		whiteSprite.color = FlxColor.WHITE;
		
		var portraitId:String = null;
		if (id != null && id.length > 0) portraitId = (id == 'default') ? (index == 1 ? 'defaultgf' : (index == 0 ? 'default' : null)) : id;
		
		var hasPortrait:Bool = false;
		if (portraitId != null && portraitId.length > 0)
		{
			if (!_portraitCache.exists(portraitId)) _portraitCache.set(portraitId, Paths.fileExists('images/menu/cosmicube/items/$portraitId.png', LOOSE));
			
			if (_portraitCache.get(portraitId))
			{
				if (categoryPreviewPortraitIds[index] != portraitId)
				{
					portraitSprite.loadGraphic(Paths.image('menu/cosmicube/items/$portraitId', LOOSE));
					portraitSprite.antialiasing = ClientPrefs.globalAntialiasing;
					portraitSprite.scale.set(previewCardScale, previewCardScale);
					portraitSprite.updateHitbox();
					categoryPreviewPortraitIds[index] = portraitId;
				}
				
				portraitSprite.x = bgSprite.x + ((bgSprite.width - portraitSprite.width) * 0.5);
				portraitSprite.y = bgSprite.y + ((bgSprite.height - portraitSprite.height) * 0.5);
				hasPortrait = true;
			}
		}
		
		portraitSprite.visible = hasPortrait;
		if (!hasPortrait) categoryPreviewPortraitIds[index] = '';
		fallbackLabel.text = (hasPortrait ? '' : defaultText);
		fallbackLabel.visible = !hasPortrait;
		fallbackLabel.y = bgSprite.y + ((bgSprite.height - fallbackLabel.height) * 0.5);
	}
	
	function setCategoryStuffVisible(vis:Bool):Void
	{
		for (t in categoryTexts)
			t.visible = vis;
		for (s in categoryPreviewBgs)
			s.visible = vis;
		for (s in categoryPreviewWhites)
			s.visible = vis;
		for (s in categoryPreviewOverlays)
			s.visible = vis;
		for (s in categoryPreviewPortraits)
			s.visible = vis;
		for (s in categoryPreviewFallbacks)
			s.visible = vis;
	}
	
	function updateCategoryDisplay():Void
	{
		var equipped:Array<String> = [
			ClientPrefs.bfSkin ?? 'default',
			ClientPrefs.gfSkin ?? 'default',
			ClientPrefs.pet ?? ''
		];
		
		for (i in 0...3)
		{
			categoryTexts[i].text = getCosmeticDisplayName(equipped[i], 'None');
			categoryTexts[i].color = (i == selectedCategory ? 0xFFFFE066 : FlxColor.WHITE);
		}
		
		updatePreviewCard(0, equipped[0], 'DEFAULT');
		updatePreviewCard(1, equipped[1], 'DEFAULT');
		updatePreviewCard(2, equipped[2], 'N/A');
	}
	
	function openGridForCategory(cat:Int):Void
	{
		inGrid = true;
		gridCursorIndex = 0;
		gridScrollY = 0;
		gridTargetScrollY = 0;
		
		setCategoryStuffVisible(false);
		
		var list:Array<String>;
		var catName:String;
		// cat like cat.. Heh. Meow. Heh. No its category sorry
		switch (cat)
		{
			case 0:
				list = bfSkinList;
				catName = Lang.str('shop_playerSkin', 'BF SKINS');
			case 1:
				list = gfSkinList;
				catName = Lang.str('shop_speakerSkin', 'GF SKINS');
			default:
				list = petList;
				catName = Lang.str('shop_pet', 'PETS');
		}
		
		gridItemIds = list.copy();
		
		var equippedId:String = switch (cat)
		{
			case 0: ClientPrefs.bfSkin;
			case 1: ClientPrefs.gfSkin;
			default: ClientPrefs.pet;
		};
		
		var startIdx = gridItemIds.indexOf(equippedId ?? '');
		if (startIdx < 0) startIdx = 0;
		gridCursorIndex = startIdx;
		
		selectSprite.visible = false;
		skinThingBg.visible = true;
		skinTop.visible = true;
		resetButton.visible = false;
		randomButton.visible = false;
		resetLabel.visible = false;
		resetLabel.active = false;
		randomLabel.visible = false;
		randomLabel.active = false;
		gridItemLabel.visible = true;
		menuBackButton.x = 850;
		menuBackButton.y = 60;
		titleText.text = catName;
		titleText.x = Math.round((FlxG.width - titleText.width) * 0.5);
		titleText.y = 88 - 28;
		
		setupGridCards();
		updateGridHighlights();
		snapGridScroll();
		updateGridScrollBar();
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}
	
	function closeGrid():Void
	{
		inGrid = false;
		clearGridCards();
		
		skinThingBg.visible = false;
		skinTop.visible = false;
		selectSprite.visible = true;
		resetButton.visible = true;
		randomButton.visible = true;
		resetLabel.visible = true;
		resetLabel.active = true;
		randomLabel.visible = true;
		randomLabel.active = true;
		gridItemLabel.visible = false;
		gridScrollBar.visible = false;
		menuBackButton.x = 950;
		menuBackButton.y = 90;
		titleText.text = Lang.str('locker', 'LOCKER');
		titleText.x = 280;
		titleText.y = 88;
		
		setCategoryStuffVisible(true);
		updateCategoryDisplay();
		
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
	}
	
	function setupGridCards():Void
	{
		clearGridCards();
		
		var nodeAtlas = Paths.getSparrowAtlas('menu/cosmicube/node');
		var gridOriginX:Float = (FlxG.width - (GRID_COLS * GRID_SPACING_X)) * 0.5 + GRID_SPACING_X * 0.5;
		
		for (i in 0...gridItemIds.length)
		{
			var col:Int = i % GRID_COLS;
			var row:Int = Std.int(i / GRID_COLS);
			var cx:Float = gridOriginX + col * GRID_SPACING_X;
			var cy:Float = gridOriginY + row * GRID_SPACING_Y;
			
			var bgSpr = new FlxSprite();
			bgSpr.frames = nodeAtlas;
			bgSpr.animation.addByPrefix('main', 'back');
			bgSpr.animation.play('main');
			bgSpr.antialiasing = ClientPrefs.globalAntialiasing;
			bgSpr.scale.set(GRID_CARD_SCALE, GRID_CARD_SCALE);
			bgSpr.updateHitbox();
			bgSpr.x = cx - (bgSpr.width * 0.5);
			bgSpr.y = cy - (bgSpr.height * 0.5);
			bgSpr.cameras = gridCameras;
			add(bgSpr);
			gridNodes.push(bgSpr);
			
			var whiteSpr = new FlxSprite();
			whiteSpr.frames = nodeAtlas;
			whiteSpr.animation.addByPrefix('main', 'emptysquare');
			whiteSpr.animation.play('main');
			whiteSpr.antialiasing = ClientPrefs.globalAntialiasing;
			whiteSpr.scale.set(GRID_CARD_SCALE, GRID_CARD_SCALE);
			whiteSpr.updateHitbox();
			whiteSpr.x = cx - (whiteSpr.width * 0.5);
			whiteSpr.y = cy - (whiteSpr.height * 0.5);
			whiteSpr.cameras = gridCameras;
			add(whiteSpr);
			gridWhites.push(whiteSpr);
			
			var portrait = new FlxSprite();
			portrait.antialiasing = ClientPrefs.globalAntialiasing;
			portrait.cameras = gridCameras;
			add(portrait);
			gridPortraits.push(portrait);
			gridPortraitIds.push('');
			
			var overlaySpr = new FlxSprite();
			overlaySpr.frames = nodeAtlas;
			overlaySpr.animation.addByPrefix('main', 'overlay');
			overlaySpr.animation.play('main');
			overlaySpr.antialiasing = ClientPrefs.globalAntialiasing;
			overlaySpr.scale.set(GRID_CARD_SCALE, GRID_CARD_SCALE);
			overlaySpr.updateHitbox();
			overlaySpr.x = cx - (overlaySpr.width * 0.5);
			overlaySpr.y = cy - (overlaySpr.height * 0.5);
			overlaySpr.cameras = gridCameras;
			add(overlaySpr);
			gridOverlays.push(overlaySpr);
			
			var fallback = new FlxText(bgSpr.x, 0, bgSpr.width, '', 18);
			fallback.setFormat(Paths.font('ariblk.ttf'), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			fallback.borderSize = 2;
			fallback.antialiasing = ClientPrefs.globalAntialiasing;
			fallback.cameras = gridCameras;
			add(fallback);
			gridFallbacks.push(fallback);
			
			updateCardVisuals(i);
		}
	}
	
	function clearGridCards():Void
	{
		for (arr in [gridNodes, gridWhites, gridOverlays, gridPortraits])
			for (s in arr)
			{
				remove(s, true);
				s.destroy();
			}
		for (s in gridFallbacks)
		{
			remove(s, true);
			s.destroy();
		}
		
		gridNodes = [];
		gridWhites = [];
		gridOverlays = [];
		gridPortraits = [];
		gridPortraitIds = [];
		gridFallbacks = [];
	}
	
	function updateCardVisuals(i:Int):Void
	{
		if (i < 0 || i >= gridItemIds.length) return;
		
		final id:String = gridItemIds[i];
		final bgSpr = gridNodes[i];
		final overlaySpr = gridOverlays[i];
		final whiteSpr = gridWhites[i];
		final portrait = gridPortraits[i];
		final fallback = gridFallbacks[i];
		
		final color:FlxColor = getCosmeticColor(id);
		bgSpr.color = color;
		overlaySpr.color = color;
		whiteSpr.color = FlxColor.WHITE;
		
		final portraitId = (id == null || id.length == 0) ? null : (id == 'default' ? (selectedCategory == 1 ? 'defaultgf' : (selectedCategory == 0 ? 'default' : null)) : id);
		var hasPortrait = false;
		if (portraitId != null && portraitId.length > 0)
		{
			if (!_portraitCache.exists(portraitId)) _portraitCache.set(portraitId, Paths.fileExists('images/menu/cosmicube/items/$portraitId.png', LOOSE));
			
			if (_portraitCache.get(portraitId))
			{
				if (gridPortraitIds[i] != portraitId)
				{
					portrait.loadGraphic(Paths.image('menu/cosmicube/items/$portraitId', LOOSE));
					portrait.antialiasing = ClientPrefs.globalAntialiasing;
					portrait.scale.set(GRID_CARD_SCALE, GRID_CARD_SCALE);
					portrait.updateHitbox();
					gridPortraitIds[i] = portraitId;
				}
				portrait.x = bgSpr.x + ((bgSpr.width - portrait.width) * 0.5);
				portrait.y = bgSpr.y + ((bgSpr.height - portrait.height) * 0.5);
				hasPortrait = true;
			}
		}
		
		portrait.visible = hasPortrait;
		if (!hasPortrait) gridPortraitIds[i] = '';
		
		final displayName = getCosmeticDisplayName(id, selectedCategory == 2 ? 'N/A' : 'DEFAULT');
		fallback.text = hasPortrait ? '' : displayName;
		fallback.visible = !hasPortrait;
		fallback.y = bgSpr.y + ((bgSpr.height - fallback.height) * 0.5);
	}
	
	function updateGridHighlights():Void
	{
		for (i in 0...gridNodes.length)
		{
			final selected = (i == gridCursorIndex);
			final equipped = isCurrentlyEquipped(gridItemIds[i]);
			final color = getCosmeticColor(gridItemIds[i]);
			
			gridNodes[i].color = color;
			gridOverlays[i].color = color;
			
			if (equipped)
			{
				gridWhites[i].color = 0xFF94FF6A;
				gridPortraits[i].color = FlxColor.WHITE;
				gridFallbacks[i].color = FlxColor.WHITE;
			}
			else if (selected)
			{
				gridWhites[i].color = 0xFFFFE066;
				gridPortraits[i].color = FlxColor.WHITE;
				gridFallbacks[i].color = FlxColor.WHITE;
			}
			else
			{
				gridWhites[i].color = 0xFF888888;
				gridPortraits[i].color = 0xFF888888;
				gridFallbacks[i].color = 0xFFAAAAAA;
			}
		}
		
		if (gridCursorIndex >= 0 && gridCursorIndex < gridItemIds.length)
		{
			final id = gridItemIds[gridCursorIndex];
			gridItemLabel.text = getCosmeticDisplayName(id, selectedCategory == 2 ? 'None' : 'Default');
			gridItemLabel.color = isCurrentlyEquipped(id) ? 0xFFFFE066 : FlxColor.WHITE;
		}
		else
		{
			gridItemLabel.text = '';
		}
	}
	
	function snapGridScroll():Void
	{
		var row:Int = Std.int(gridCursorIndex / GRID_COLS);
		var visibleTop:Float = gridOriginY;
		var visibleBottom:Float = gridOriginY + 2 * GRID_SPACING_Y;
		var rowY:Float = gridOriginY + row * GRID_SPACING_Y;
		
		if (rowY - gridTargetScrollY < visibleTop) gridTargetScrollY = rowY - visibleTop;
		else if (rowY - gridTargetScrollY > visibleBottom) gridTargetScrollY = rowY - visibleBottom;
		
		var maxScroll:Float = getGridMaxScroll();
		if (gridTargetScrollY > maxScroll) gridTargetScrollY = maxScroll;
		if (gridTargetScrollY < 0) gridTargetScrollY = 0;
	}
	
	function getGridMaxScroll():Float
	{
		var maxRow:Int = Std.int((gridItemIds.length - 1) / GRID_COLS);
		return Math.max(0, (maxRow - 2) * GRID_SPACING_Y);
	}
	
	function updateGridScrollBar():Void
	{
		if (gridScrollBar == null) return;
		
		var maxScroll = getGridMaxScroll();
		// i almost forgot to add this
		if (maxScroll <= 0)
		{
			gridScrollBar.visible = false;
			return;
		}
		
		gridScrollBar.visible = inGrid;
		if (!inGrid) return;
		
		var visibleRows:Int = 3;
		var totalRows:Int = Std.int(Math.max(1, Math.ceil(gridItemIds.length / GRID_COLS)));
		gridScrollBar.setMetrics(visibleRows, totalRows);
		
		if (autoScroll)
		{
			var scrollRatio:Float = FlxMath.bound(gridScrollY / maxScroll, 0, 1);
			gridScrollBar.setProgress(scrollRatio);
		}
	}
	
	function tickGridScroll(elapsed:Float):Void
	{
		if (autoScroll)
		{
			gridScrollY += (gridTargetScrollY - gridScrollY) * FlxMath.getElapsedLerp(.16, elapsed);
			gridScrollY = FlxMath.bound(gridScrollY, 0, getGridMaxScroll());
		}
		
		var gridOriginX:Float = (FlxG.width - (GRID_COLS * GRID_SPACING_X)) * 0.5 + GRID_SPACING_X * 0.5;
		for (i in 0...gridNodes.length)
		{
			var col:Int = i % GRID_COLS;
			var row:Int = Std.int(i / GRID_COLS);
			var cx:Float = gridOriginX + col * GRID_SPACING_X;
			var cy:Float = gridOriginY + row * GRID_SPACING_Y - gridScrollY;
			
			var bgSpr = gridNodes[i];
			bgSpr.x = cx - (bgSpr.width * 0.5);
			bgSpr.y = cy - (bgSpr.height * 0.5);
			
			gridWhites[i].setPosition(bgSpr.x, bgSpr.y);
			gridOverlays[i].setPosition(bgSpr.x, bgSpr.y);
			
			var portrait = gridPortraits[i];
			if (portrait.visible)
			{
				portrait.x = bgSpr.x + ((bgSpr.width - portrait.width) * 0.5);
				portrait.y = bgSpr.y + ((bgSpr.height - portrait.height) * 0.5);
			}
			
			gridFallbacks[i].x = bgSpr.x;
			gridFallbacks[i].y = bgSpr.y + ((bgSpr.height - gridFallbacks[i].height) * 0.5);
			
			var onScreen = (cy > 100 && cy < FlxG.height - 40);
			gridNodes[i].visible = onScreen;
			gridWhites[i].visible = onScreen;
			gridOverlays[i].visible = onScreen;
			gridPortraits[i].visible = onScreen && gridPortraits[i].graphic != null && gridPortraitIds[i].length > 0;
			gridFallbacks[i].visible = onScreen && gridFallbacks[i].text.length > 0;
		}
		
		updateGridScrollBar();
	}
	
	function gridMove(dx:Int, dy:Int):Void
	{
		if (gridItemIds.length == 0) return;
		
		var col:Int = gridCursorIndex % GRID_COLS;
		var row:Int = Std.int(gridCursorIndex / GRID_COLS);
		var maxRow:Int = Std.int((gridItemIds.length - 1) / GRID_COLS);
		
		if (dx != 0)
		{
			var maxCol:Int = (row == maxRow) ? ((gridItemIds.length - 1) % GRID_COLS) : (GRID_COLS - 1);
			col = FlxMath.wrap(col + dx, 0, maxCol);
		}
		
		if (dy != 0)
		{
			row = FlxMath.wrap(row + dy, 0, maxRow);
			
			var lastColOnRow = (row == maxRow) ? ((gridItemIds.length - 1) % GRID_COLS) : (GRID_COLS - 1);
			if (col > lastColOnRow) col = lastColOnRow;
		}
		
		var newIdx = row * GRID_COLS + col;
		if (newIdx >= gridItemIds.length) newIdx = gridItemIds.length - 1;
		if (newIdx < 0) newIdx = 0;
		
		if (newIdx != gridCursorIndex)
		{
			gridCursorIndex = newIdx;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			updateGridHighlights();
			snapGridScroll();
		}
		
		autoScroll = true;
	}
	
	function gridEquipCurrent():Void
	{
		if (gridCursorIndex < 0 || gridCursorIndex >= gridItemIds.length) return;
		
		final id = gridItemIds[gridCursorIndex];
		
		switch (selectedCategory)
		{
			case 0:
				ClientPrefs.bfSkin = id;
			case 1:
				ClientPrefs.gfSkin = id;
			case 2:
				ClientPrefs.pet = id;
		}
		
		autoScroll = true;
		
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		
		for (i in 0...gridItemIds.length)
			updateCardVisuals(i);
		updateGridHighlights();
	}
	
	function getPortraitId(id:String, catIndex:Int):String
	{
		if (id == null || id.length == 0) return null;
		if (id == 'default')
		{
			return (catIndex == 1) ? 'defaultgf' : (catIndex == 0 ? 'default' : null);
		}
		return id;
	}
	
	// not used anymore but keeping it around just in case
	function checkPortraitExists(portraitId:String):Bool
	{
		if (_portraitCache.exists(portraitId)) return _portraitCache.get(portraitId);
		var exists = Paths.fileExists('images/menu/cosmicube/items/$portraitId.png', LOOSE);
		_portraitCache.set(portraitId, exists);
		return exists;
	}
	
	function isCurrentlyEquipped(id:String):Bool
	{
		switch (selectedCategory)
		{
			case 0:
				return (ClientPrefs.bfSkin == id);
			case 1:
				return (ClientPrefs.gfSkin == id);
			case 2:
				return (ClientPrefs.pet == id);
			default:
				return false;
		}
	}
	
	function getCosmeticColor(id:String):FlxColor
	{
		if (id == null || id.length == 0 || id == 'default') return 0xff4a4a4a;
		if (cosmeticColorCache.exists(id)) return cosmeticColorCache.get(id);
		
		var resolvedColor:FlxColor = FlxColor.RED;
		var data = cosmeticDataById.get(id);
		
		if (data != null)
		{
			var info = (Paths.fileExists('data/characters/$id.json', LOOSE) ? CharacterParser.fetchInfo(id) : null);
			
			var color:Dynamic = data.color;
			color ??= info?.healthbar_colour;
			color ??= info?.healthbar_colors;
			
			if (Std.isOfType(color, Array))
			{
				var rgb:Array<Int> = cast color;
				if (rgb.length >= 3) resolvedColor = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
			}
			else if (Std.isOfType(color, Int))
			{
				resolvedColor = cast color;
			}
		}
		
		cosmeticColorCache.set(id, resolvedColor);
		return resolvedColor;
	}
	
	function getCosmeticDisplayName(id:String, noneText:String):String
	{
		if (id == null || id.length == 0) return noneText;
		if (id == 'default') return 'Default';
		
		var displayName = cosmeticDisplayNames.get(id);
		if (displayName != null && displayName.length > 0) return displayName;
		
		return id;
	}
	
	function loadCosmeticLists():Void
	{
		bfSkinList = ['default'];
		gfSkinList = ['default'];
		petList = [''];
		function addUnique(list:Array<String>, id:String):Void
		{
			if (!list.contains(id)) list.push(id);
		}
		
		cosmeticDisplayNames.clear();
		cosmeticDataById.clear();
		cosmeticColorCache.clear();
		
		var itemTypes:Map<String, String> = [];
		
		for (cube in CosmicubeData.cosmicubeList)
		{
			for (item in CosmicubeData.cosmicubeItems.get(cube))
			{
				itemTypes.set(item.fileName, Std.string(item.type));
				
				cosmeticDisplayNames.set(item.fileName, Lang.str('${item.fileName}_name', item.title ?? item.fileName));
				
				cosmeticDataById.set(item.fileName, item);
			}
		}
		
		for (itemID in ClientPrefs.cosmicubeUnlocks)
		{
			var itemType = itemTypes.get(itemID);
			if (itemType == null) continue;
			
			switch (itemType)
			{
				case 'playerSkin':
					addUnique(bfSkinList, itemID);
					
				case 'speakerSkin':
					addUnique(gfSkinList, itemID);
					
				case 'pet':
					addUnique(petList, itemID);
					
				default:
			}
		}
		
		if (initialBFSkin != 'default') addUnique(bfSkinList, initialBFSkin);
		if (initialGFSkin != 'default') addUnique(gfSkinList, initialGFSkin);
		if (initialPet != '') addUnique(petList, initialPet);
	}
	
	function hideEverything():Void
	{
		for (obj in members)
		{
			if (obj == null) continue;
			obj.visible = false;
			obj.active = false;
		}
	}
	
	function tweenOutAndClose():Void
	{
		if (bg != null)
		{
			FlxTween.cancelTweensOf(bg);
			FlxTween.tween(bg, {alpha: 0}, 0.28, {ease: FlxEase.circIn});
		}
		
		var tweenTargets:Array<FlxSprite> = [];
		for (obj in members)
		{
			if (obj == null || obj == bg || obj == controlsDisplay || !Std.isOfType(obj, FlxSprite)) continue;
			var sprite:FlxSprite = cast obj;
			FlxTween.cancelTweensOf(sprite);
			tweenTargets.push(sprite);
		}
		
		if (tweenTargets.length == 0)
		{
			hideEverything();
			close();
			return;
		}
		
		var left:Int = tweenTargets.length;
		for (sprite in tweenTargets)
		{
			FlxTween.tween(sprite, {y: sprite.y + uiTweenOffsetY, alpha: 0}, 0.28,
				{
					ease: FlxEase.circIn,
					onComplete: function(_) {
						left--;
						if (left <= 0)
						{
							hideEverything();
							close();
						}
					}
				});
		}
	}
	
	function confirmAndClose():Void
	{
		if (isClosing) return;
		isClosing = true;
		canMove = false;
		
		ClientPrefs.flush();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
		tweenOutAndClose();
	}
	
	function resetToDefaults():Void
	{
		if (isClosing) return;
		
		ClientPrefs.bfSkin = 'default';
		ClientPrefs.gfSkin = 'default';
		ClientPrefs.pet = '';
		ClientPrefs.flush();
		
		initialBFSkin = 'default';
		initialGFSkin = 'default';
		initialPet = '';
		
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
		
		if (inGrid)
		{
			for (i in 0...gridItemIds.length)
				updateCardVisuals(i);
			updateGridHighlights();
		}
		else
		{
			updateCategoryDisplay();
		}
	}
	
	function randomizeLoadout():Void
	{
		if (isClosing) return;
		
		ClientPrefs.bfSkin = bfSkinList[FlxG.random.int(0, bfSkinList.length - 1)];
		ClientPrefs.gfSkin = gfSkinList[FlxG.random.int(0, gfSkinList.length - 1)];
		ClientPrefs.pet = petList[FlxG.random.int(0, petList.length - 1)];
		ClientPrefs.flush();
		
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
		updateCategoryDisplay();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (canMove && !isClosing)
		{
			if (FlxG.mouse.justMoved || FlxG.mouse.wheel != 0) mouseMode = true;
			
			if (FlxG.mouse.justReleased)
			{
				if (FlxG.mouse.overlaps(menuBackButton, overlayCamera))
				{
					if (inGrid) closeGrid();
					else confirmAndClose();
				}
				else if (FlxG.mouse.overlaps(resetButton, overlayCamera))
				{
					if (resetButton.visible) resetToDefaults();
				}
				else if (FlxG.mouse.overlaps(randomButton, overlayCamera))
				{
					if (randomButton.visible) randomizeLoadout();
				}
			}
			
			if (inGrid)
			{
				if (controlLEFT.PRESSED || controlRIGHT.PRESSED || controlUP.PRESSED || controlDOWN.PRESSED) mouseMode = false;
				
				if (!mouseMode)
				{
					if (controlLEFT.PRESSED) gridMove(-1, 0);
					if (controlRIGHT.PRESSED) gridMove(1, 0);
					if (controlUP.PRESSED) gridMove(0, -1);
					if (controlDOWN.PRESSED) gridMove(0, 1);
				}
				
				if (controls.ACCEPT)
				{
					mouseMode = false;
					gridEquipCurrent();
				}
				if (controls.BACK)
				{
					mouseMode = false;
					closeGrid();
				}
				
				if (FlxG.mouse.wheel != 0)
				{
					autoScroll = true;
					
					gridTargetScrollY -= FlxG.mouse.wheel * GRID_SPACING_Y * 0.5;
					var maxScroll:Float = getGridMaxScroll();
					if (gridTargetScrollY > maxScroll) gridTargetScrollY = maxScroll;
					if (gridTargetScrollY < 0) gridTargetScrollY = 0;
				}
				
				if (mouseMode && !gridScrollBar.interacting)
				{
					var hovered:Int = -1;
					for (i in 0...gridNodes.length)
					{
						if (gridNodes[i].visible && FlxG.mouse.overlaps(gridNodes[i], gridCamera))
						{
							hovered = i;
							break;
						}
					}
					
					if (hovered != gridCursorIndex)
					{
						gridCursorIndex = hovered;
						if (hovered >= 0) FlxG.sound.play(Paths.sound('hover'), 0.4);
						updateGridHighlights();
					}
				}
				
				if (FlxG.mouse.justPressed)
				{
					for (i in 0...gridNodes.length)
					{
						if (gridNodes[i].visible && FlxG.mouse.overlaps(gridNodes[i], gridCamera))
						{
							gridCursorIndex = i;
							updateGridHighlights();
							gridEquipCurrent();
							break;
						}
					}
				}
				
				tickGridScroll(elapsed);
			}
			else
			{
				if (controls.UI_UP_P || controls.UI_DOWN_P) mouseMode = false;
				
				if (controls.UI_DOWN_P || controls.UI_UP_P || FlxG.mouse.wheel != 0)
				{
					var diff = FlxG.mouse.wheel != 0 ? -FlxG.mouse.wheel : controls.UI_DOWN ? 1 : -1;
					selectedCategory = FlxMath.wrap(selectedCategory + diff, 0, 2);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
					updateCategoryDisplay();
				}
				
				if (controls.ACCEPT)
				{
					mouseMode = false;
					openGridForCategory(selectedCategory);
				}
				if (controls.BACK)
				{
					mouseMode = false;
					confirmAndClose();
				}
				
				if (mouseMode && FlxG.mouse.justMoved)
				{
					for (i in 0...categoryTexts.length)
					{
						final isOver = FlxG.mouse.overlaps(categoryTexts[i], overlayCamera) || (categoryPreviewBgs[i] != null && FlxG.mouse.overlaps(categoryPreviewBgs[i], overlayCamera));
						if (isOver)
						{
							if (selectedCategory != i)
							{
								selectedCategory = i;
								FlxG.sound.play(Paths.sound('hover'), 0.5);
								updateCategoryDisplay();
							}
							break;
						}
					}
				}
				
				if (FlxG.mouse.justPressed)
				{
					for (i in 0...categoryTexts.length)
					{
						final isOver = FlxG.mouse.overlaps(categoryTexts[i], overlayCamera) || (categoryPreviewBgs[i] != null && FlxG.mouse.overlaps(categoryPreviewBgs[i], overlayCamera));
						
						if (isOver)
						{
							selectedCategory = i;
							updateCategoryDisplay();
							openGridForCategory(i);
							break;
						}
					}
				}
			}
		}
	}
	
	override function destroy()
	{
		ClientPrefs.flush();
		
		for (obj in members)
		{
			if (obj != null) FlxTween.cancelTweensOf(obj);
		}
		
		if (overlayCamera != null)
		{
			FlxG.cameras.remove(overlayCamera, true);
			overlayCamera = null;
		}
		
		if (gridCamera != null)
		{
			FlxG.cameras.remove(gridCamera, true);
			gridCamera = null;
		}
		
		super.destroy();
	}
}
