package funkin.states;

import funkin.input.TurboControl;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxStringUtil;

import funkin.data.Chart;
import funkin.backend.Difficulty;
import funkin.states.editors.ChartEditorState;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.utils.MathUtil;
import funkin.game.shaders.ColorSwap;
import funkin.game.shaders.RimLight;
// import sys.io.File;
import funkin.data.WeekData;
import funkin.data.CosmicubeData;
import funkin.objects.menu.FreeplayCard;
import funkin.objects.menu.AmongControls;

typedef FreeplayWeek =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var section:String;
	var ?mod:String;
	var title:String;
	var ?graphic:String;
}

abstract SongInformation(Array<Dynamic>) to Array<Dynamic>
{
	public var songName(get, never):String;
	public var icon(get, never):String;
	public var portrait(get, never):String;
	public var color(get, never):FlxColor;
	public var lock(get, never):String;
	public var requiredSongs(get, never):Array<String>;
	public var cost(get, never):Int;
	public var credit(get, never):String;
	public var currency(get, never):String;
	public var hideUntilDoubleTrouble(get, never):Bool;
	public var mod(get, never):Null<String>;
	
	function get_songName():String return Std.string(this[0] ?? 'UNKNOWN?');
	
	function get_icon():String return Std.string(this[1] ?? 'red');
	
	function get_portrait():String return (this[2] ?? 'unknown');
	
	function get_color():FlxColor return (this[3] ?? FlxColor.GRAY);
	
	function get_lock():String return Std.string(this[4] ?? 'story');
	
	function get_requiredSongs():Array<String> return ((cast this[5]) ?? [Paths.sanitize(songName)]);
	
	function get_cost():Int return (this[6] ?? 0);
	
	function get_credit():String return Std.string(this[7] ?? 'data5');
	
	function get_currency():String return Std.string(this[8] ?? 'beans');
	
	function get_hideUntilDoubleTrouble():Bool return (this[9] == true);
	
	function get_mod():Null<String> return this[10];
}

enum UnlockAnimPhase
{
	NONE;
	UNLOCKING(card:FreeplayCard);
	WAIT;
	RETURNING;
}

class FreeplayState extends AmongUIState
{
	public var weeks:Array<FreeplayWeek> = []; // Freeplay Weeks, put your shit in here
	
	public static var curMonth:Int = 0;
	public static var curSelect:Int = 0;
	
	var smoothMonth:Float = 0;
	var smoothSelect:Float = 0;
	
	var reload_timer:Float = 0;
	
	// Tween bullshit
	var portraitTween:FlxTween;
	var portraitAlphaTween:FlxTween;
	var colorTween:FlxTween;
	
	// Portrait bullshit
	var porGlow:FlxSprite;
	var portrait:FlxSprite;
	var rimlight:RimLight;
	
	var ext:String = 'menu/freeplay/';
	var prevPort:String = '';
	
	var prevSel:Int = 0;
	var lerpScore:Float;
	var lerpRating:Float;
	var intendedScore:Float;
	var intendedRating:Float;
	var localWeeks:Array<String> = [''];
	
	public var cachedCards:FlxTypedGroup<FreeplayCard>;
	
	public var cards:FlxTypedGroup<FreeplayCard>;
	
	public var circles:FlxSpriteGroup; // freeplay section bubbles
	
	var week_songs:Array<SongInformation> = [];
	var ws_lock:Array<Bool> = [];
	
	var infoText:FlxText;
	var sectionText:FlxText;
	var score_rating:Array<String>;
	
	var CARD_X:Float = 70;
	var CARD_Y:Float = (FlxG.height * .45);
	var TAB_DISTANCE:Float = 320;
	var TAB_RADIUS:Float = 5.3; // higher make less ciruclar
	
	var CARD_DISTANCE:Float = 117;
	var CARD_X_SHIFT:Float = -70;
	var CARD_FADE:Float = .25;
	
	var CARD_LERP = .25;
	
	var animateCards:Array<FreeplayCard> = [];
	var unlockTimer:FlxTimer = null;
	var finishingCutscene:Bool = false;
	var cutscenePhase:UnlockAnimPhase = NONE;
	
	var menuWeekSelect:FlxSprite;
	
	var turboGroup:TurboControlGroup;
	var controlDOWN:TurboControl = TurboControl.fromControl('ui_down');
	var controlUP:TurboControl = TurboControl.fromControl('ui_up');
	var controlLEFT:TurboControl = TurboControl.fromControl('ui_left');
	var controlRIGHT:TurboControl = TurboControl.fromControl('ui_right');
	
	override function create()
	{
		super.create();
		
		Mods.currentModDirectory = null;
		
		smoothMonth = curMonth;
		
		add(turboGroup = new TurboControlGroup());
		turboGroup.add(controlDOWN);
		turboGroup.add(controlUP);
		turboGroup.add(controlLEFT);
		turboGroup.add(controlRIGHT);
		
		circles = new FlxSpriteGroup();
		circles.camera = camUpper;
		circles.zIndex = 22;
		add(circles);
		
		// 1.1 feature
		menuWeekSelect = new FlxSprite(12, 8).loadGraphic(Paths.image('menu/common/menuOther'));
		menuWeekSelect.x = FlxG.width - (menuWeekSelect.width + 12); // im
		menuWeekSelect.camera = camUpper;
		menuWeekSelect.zIndex = 25;
		add(menuWeekSelect);
		
		PlayState.isStoryMode = false;
		PlayState.chartingMode = false;
		
		FunkinAssets.cache.clearStoredMemory();
		// FunkinAssets.cache.clearUnusedMemory();
		
		DiscordClient.changePresence("Freeplay Menu");
		
		funkin.data.CosmicubeData.reload();
		
		PlayState.missLimit = false;
		
		persistentUpdate = true;
		FlxG.mouse.visible = true;
		
		initStateScript(); // unnecessary
		
		add(upperBar);
		add(backButton).revive();
		add(beanIcon);
		add(beanText);
		
		localWeeks = ClientPrefs.unlockedSongs;
		CosmeticsSubstate.preloadForFreeplay();
		
		score_rating = [Lang.str('score'), Lang.str('accuracy')];
		
		addWeeks();
		
		porGlow = new FlxSprite(-11.1 + 496, -12.65).loadGraphic(Paths.image(ext + 'backGlow'));
		porGlow.color = FlxColor.RED;
		add(porGlow);
		
		portrait = new FlxSprite(304, -100).loadGraphic(Paths.image(ext + 'portraits/red')); // loadAtlasFrames(Paths.getAtlasFrames(ext + 'portraits'));
		add(portrait);
		
		add(rimlight = new RimLight(315, 10, portrait));
		
		infoText = new FlxText(0, 91, FlxG.width - 6, 'If you can read this I fucked something up terribly', 48);
		infoText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.camera = camUpper;
		add(infoText);
		
		// look mom! new controls system!
		var bottomControls:AmongControls = new AmongControls([
			['arrow', 'select'], // select
			['enter', 'conf'], // conf
			['esc', 'back'], // back
			['tab', 'locker'], // locker
			['reset', 'reset_score']
		], false);
		bottomControls.camera = camUpper;
		bottomControls.zIndex = 12;
		add(bottomControls);
		
		sectionText = new FlxText(0, 80, FlxG.width, '---', 35);
		sectionText.setFormat(Paths.font("AmaticSC-Bold.ttf", false), 70, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sectionText.camera = camUpper;
		sectionText.borderSize = 3;
		sectionText.zIndex = 20;
		add(sectionText);
		
		scriptGroup.call('onCreatePost', []);
		changeSection(0, false);
	}
	
	function refreshCards()
	{
		if (cards == null)
		{
			cards = new FlxTypedGroup();
			add(cards);
			
			cachedCards = new FlxTypedGroup();
		}
		
		scriptGroup.call('onSectionChange', [curMonth]);
		var num = 0;
		
		week_songs = [];
		ws_lock = [];
		var SECTION_SONGS = cast weeks[curMonth].songs;
		
		// essentially we put all the cards into a cache and then retrieve however we actually need
		while (cards.length > 0)
		{
			var card = cards.remove(cards.members[cards.length - 1], true);
			cachedCards.add(card);
			card.kill();
		}
		
		for (i in 0...SECTION_SONGS.length)
		{
			// trace(SECTION_SONGS[i]); im sorry it was annoying
			final song:SongInformation = SECTION_SONGS[i];
			if (song.hideUntilDoubleTrouble && !ClientPrefs.doubletrouble) continue;
			final isLocked:Bool = checkLock(song);
			
			var animate:Bool = false;
			
			ws_lock.push(isLocked);
			week_songs.push(song);
			
			if (ClientPrefs.checkoutUnlockedSongs.contains(song.songName) == isLocked)
			{
				if (isLocked)
				{
					ClientPrefs.checkoutUnlockedSongs.remove(song.songName);
				}
				else
				{
					ClientPrefs.checkoutUnlockedSongs.push(song.songName);
					if (song.lock == 'special') animate = true;
				}
			}
			
			Mods.currentModDirectory = song.mod;
			
			var c = cachedCards.recycle(FreeplayCard);
			c.initCard(song, ws_lock[num] || animate);
			c.ID = (num++);
			cards.add(c);
			c.zIndex = 5;
			
			if (animate) animateCards.push(c);
		}
		
		snapCards(curSelect);
		for (card in cards)
			card.x -= 700;
			
		animateUnlock();
		refreshZ();
		scriptGroup.call('onSectionPost', [curMonth]);
	}
	
	function animateUnlock(fast:Bool = false):Void
	{
		if (animateCards.length == 0) return finishUnlockCutscene();
		
		var oldSelect:Int = curSelect;
		var card:FreeplayCard = animateCards.shift();
		
		FlxTween.cancelTweensOf(this, ['smoothSelect']);
		FlxTween.tween(this, {smoothSelect: card.ID}, .75, {ease: FlxEase.quartOut, startDelay: fast ? 0 : .25});
		
		cutscenePhase = UNLOCKING(card);
		unlockTimer = new FlxTimer().start(fast ? 0 : .25, function(_) {
			cutscenePhase = WAIT;
			unlockAnim(card, true);
			
			unlockTimer = new FlxTimer().start(1.8, function(_) {
				unlockTimer = null;
				
				animateUnlock();
			});
		});
	}
	
	function getSongInfo(songID:String):Array<String>
	{
		var txt = Paths.getPath('songs/' + Paths.sanitize(songID) + '/info.txt', NORMAL);
		var info:Array<String> = CoolUtil.coolTextFile(txt);
		if (info != null && info.length > 0) return info;
		return ['UNKNOWN', 'NO SONG INFO FOUND'];
	}
	
	function skipUnlockCutscene():Void
	{
		unlockTimer?.cancel();
		
		switch (cutscenePhase)
		{
			case UNLOCKING(card):
				unlockAnim(card, true);
				
			default:
		}
		
		animateUnlock(true);
	}
	
	function finishUnlockCutscene():Void
	{
		if (cutscenePhase == RETURNING || cutscenePhase == NONE) return;
		
		FlxTween.cancelTweensOf(this, ['smoothSelect']);
		
		smoothSelect = curSelect;
		cutscenePhase = RETURNING;
		
		FlxTimer.wait(.6, function() {
			cutscenePhase = NONE;
		});
	}
	
	function changeSection(by:Int = 0, ?backToTop = true)
	{
		curMonth += by;
		
		if (curMonth >= weeks.length)
		{
			smoothMonth -= weeks.length;
			curMonth = 0;
		}
		else if (curMonth < 0)
		{
			smoothMonth += weeks.length;
			curMonth = weeks.length - 1;
		}
		
		FlxTween.cancelTweensOf(this, ['smoothMonth']);
		FlxTween.tween(this, {smoothMonth: curMonth}, .3, {ease: FlxEase.quartOut});
			
		sectionText.text = weeks[curMonth].title;
		if (backToTop) smoothSelect = curSelect = 0;
		else smoothSelect = curSelect;
		
		refreshCards();
		changeSong(0, true);
		
		if (by != 0) FlxG.sound.play(Paths.sound(by > 0 ? 'panelAppear' : 'panelDisappear'), 0.5);
	}
	
	inline function moveCard(c:FreeplayCard, selection:Float, instant:Bool = false):Void
	{
		if (c == null) return;
		
		final dist:Float = (c.ID - selection);
		
		final targetX = (Math.abs(dist) * CARD_X_SHIFT + Math.round(CARD_X));
		final targetY = (dist * CARD_DISTANCE + Math.round(CARD_Y));
		final targetAlpha = (1 - Math.abs(dist) * CARD_FADE);
		
		if (instant)
		{
			c.x = targetX;
			c.y = targetY;
			c.alpha = targetAlpha;
		}
		else
		{
			c.x = MathUtil.fpsLerp(c.x, targetX, CARD_LERP);
			c.y = MathUtil.fpsLerp(c.y, targetY, CARD_LERP);
			c.alpha = MathUtil.fpsLerp(c.alpha, targetAlpha, CARD_LERP);
		}
	}
	
	inline function snapCards(selection:Float)
	{
		for (card in cards)
			moveCard(card, selection, true);
	}
	
	function changeSong(by:Int = 0, change = false)
	{
		prevSel = curSelect;
		
		curSelect += by;
		
		if (curSelect < 0) snapCards(week_songs.length);
		else if (curSelect >= week_songs.length) snapCards(-1);
		
		curSelect = FlxMath.wrap(curSelect, 0, week_songs.length - 1);
		
		final song:SongInformation = week_songs[curSelect];
		
		Mods.currentModDirectory = song.mod;
		
		if (by != 0)
		{
			FlxTween.cancelTweensOf(this, ['smoothSelect']);
			FlxG.sound.play(Paths.sound('hover'), 0.5);
			smoothSelect = curSelect;
		}
		
		changePortrait(change);
		
		scriptGroup.call('onSongChange', [song.songName]);
		intendedScore = Highscore.getScore(song.songName, 1);
		intendedRating = Highscore.getRating(song.songName, 1);
	}
	
	function changePortrait(reset:Bool)
	{
		var song = week_songs[curSelect];
		
		var porty:String = song.portrait;
		var color:FlxColor = song.color;
		
		localCurrency = (song.lock == 'shop' && ws_lock[curSelect] ? song.currency : CosmicubeData.currentCurrency);
		
		scriptGroup.call('onPortraitChange', [porty, prevPort]);
		if (prevPort != porty)
		{
			portrait.loadGraphic(Paths.image(ext + 'portraits/' + porty)); // animation.play(week_songs[curSelect][2]);
			// thank you ashley
			portrait.updateHitbox();
			portrait.offset.x += (portrait.frameWidth - 1215) * .5 * portrait.scale.x;
			portrait.offset.y += (portrait.frameHeight - 1097) * .5 * portrait.scale.y;
		}
		
		if (ws_lock[curSelect])
		{
			rimlight.rimlightColor = color;
			
			portrait.color = FlxColor.BLACK;
			portrait.shader = rimlight.shader;
		}
		else
		{
			portrait.shader = null;
			portrait.color = FlxColor.WHITE;
		}
		
		if (!reset)
		{
			if (prevPort != porty)
			{
				if (portraitTween != null)
				{
					portraitTween.cancel();
				}
				if (portraitAlphaTween != null)
				{
					portraitAlphaTween.cancel();
				}
				if (colorTween != null)
				{
					colorTween.cancel();
				}
				portrait.x = 504.65;
				portrait.alpha = 0;
				colorTween = FlxTween.color(porGlow, 0.2, porGlow.color, color);
				portraitTween = FlxTween.tween(portrait, {x: 304.65}, 0.3, {ease: FlxEase.expoOut});
				portraitAlphaTween = FlxTween.tween(portrait, {alpha: 1}, 0.3, {ease: FlxEase.expoOut});
			}
		}
		else
		{
			if (portraitTween != null)
			{
				portraitTween.cancel();
			}
			if (portraitAlphaTween != null)
			{
				portraitAlphaTween.cancel();
			}
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			portrait.x = 504.65;
			portrait.alpha = 0;
			colorTween = FlxTween.color(porGlow, 0.2, porGlow.color, color);
			portraitTween = FlxTween.tween(portrait, {x: 304.65}, 0.3, {ease: FlxEase.expoOut});
			portraitAlphaTween = FlxTween.tween(portrait, {alpha: 1}, 0.3, {ease: FlxEase.expoOut});
		}
		
		prevPort = porty;
	}
	
	function acceptSong()
	{
		var s:SongInformation = week_songs[curSelect];
		
		if (ws_lock[curSelect])
		{
			if (s.lock == 'shop') localCurrency = s.currency;
			
			if (s.lock == 'shop' && localBeans >= Std.int(s.cost))
			{
				trace('buy');
				ws_lock[curSelect] = false;
				unlockAnim(cards.members[curSelect]);
				lockMovement = true;
				localWeeks.push(s.songName);
				localBeans -= Std.int(s.cost);
				return;
			}
			FlxG.sound.play(Paths.sound('locked'), 0.7);
			if (ClientPrefs.flashing)
			{
				FlxG.camera.shake(0.005, 0.25);
				camUpper.shake(0.005, 0.25);
			}
			
			var c = cards.members[curSelect];
			FlxTween.cancelTweensOf(c.card);
			FlxTween.cancelTweensOf(c.name);
			FlxTween.cancelTweensOf(c.lock);
			FlxTween.color(c.card, 0.6, 0xFFFF4444, 0xFF4A4A4A, {ease: FlxEase.sineOut});
			FlxTween.color(c.name, 0.6, 0xFFFF4444, 0xFFFFFFFF, {ease: FlxEase.sineOut});
			FlxTween.color(c.lock, 0.6, 0xFFFF4444, 0xFFFFFFFF, {ease: FlxEase.sineOut});
		}
		else
		{
			lockMovement = true;
			
			switch (s.songName)
			{
				case 'Defeat':
					openSubState(new MissCounterSubstate(function(misses:Int) loadSong(week_songs[curSelect][0])));
					return;
					
				case 'Monotone Attack':
					openSubState(new AttackCharSelectSubstate());
					return;
			}
			
			FlxG.sound.play(Paths.sound('panelAppear'), .5);
			loadSong(week_songs[curSelect][0]);
		}
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		
		lockMovement = false;
	}
	
	override function update(elapsed:Float)
	{
		if (!lockMovement && cutscenePhase == NONE)
		{
			if (FlxG.keys.justPressed.TAB || FlxG.gamepads.anyJustPressed(X))
			{
				lockMovement = true;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				openSubState(new CosmeticsSubstate());
			}
			if (FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(Y) || (FlxG.mouse.overlaps(menuWeekSelect) && FlxG.mouse.justPressed))
			{
				lockMovement = true;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				openSubState(new WeekPickerSubstate(this, curMonth));
			}
			
			if (controls.RESET) resetScorePrompt();
			
			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
			}
			
			if (controlLEFT.PRESSED) changeSection(-1);
			else if (controlRIGHT.PRESSED) changeSection(1);
			
			if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.mouse.y >= circles.findMinY() && FlxG.mouse.y <= circles.findMaxY())
				{
					changeSection(FlxG.mouse.wheel > 0 ? 1 : -1);
				}
				else if (FlxG.mouse.y >= (upperBar.y + upperBar.height))
				{
					changeSong(FlxG.mouse.wheel < 0 ? 1 : -1, false);
				}
			}
			
			if (controlUP.PRESSED) changeSong(-1, false);
			else if (controlDOWN.PRESSED) changeSong(1, false);
			
			if (controls.ACCEPT) acceptSong();
			
			if (ClientPrefs.inDevMode && FlxG.keys.justPressed.ONE) trace(getSongInfo(week_songs[curSelect][0]));
		}
		
		if (cutscenePhase != NONE && controls.ACCEPT) skipUnlockCutscene();
		
		var clickedTab:Null<FlxSprite> = null, clickedWeek:Null<Int> = null, scrollFrom:Null<Float> = null;
		
		for (tab in circles)
		{
			final diff:Float = (tab.ID - 4);
			final scrollDiff:Float = (diff - FlxMath.mod(smoothMonth, 1));
			final cos:Float = FlxMath.fastCos((1 - scrollDiff / TAB_RADIUS) * Math.PI / 2);
			
			final weekIndex:Int = Std.int(FlxMath.mod(diff + Math.floor(smoothMonth), weeks.length));
			final week:FreeplayWeek = weeks[weekIndex];
			
			if (tab.graphic?.key != week.graphic)
			{
				tab.loadGraphic(week.graphic);
				
				tab.setGraphicSize(-1, 71);
				tab.updateHitbox();
			}
			
			// tab.color = FlxColor.interpolate(FlxColor.BLUE, FlxColor.RED, tab.ID / 9);
			
			tab.x = ((FlxG.width - tab.width) * .5 + cos * TAB_DISTANCE);
			
			tab.alpha = Math.max(0, 1 - FlxEase.quintIn(Math.abs(scrollDiff / 5)) * .6 - FlxEase.quintOut(Math.abs(scrollDiff / 5)) * .4);
			
			if (!lockMovement && clickedTab == null && FlxG.mouse.justPressed && FlxG.mouse.overlaps(tab))
			{
				/*if (
					clickedTab == null ||
					Math.abs(FlxG.mouse.x - (tab.x + tab.width * .5)) < Math.abs(FlxG.mouse.x - (clickedTab.x + clickedTab.width * .5))
				)*/
				
				clickedTab = tab;
				clickedWeek = weekIndex;
				scrollFrom = (smoothMonth + weekIndex - curMonth - diff);
			}
		}
		
		if (clickedWeek != null)
		{
			smoothMonth = scrollFrom;
			
			goToSection(clickedWeek);
		}
		
		for (c in cards)
		{
			moveCard(c, smoothSelect);
			
			if (FlxG.mouse.y >= (upperBar.y + upperBar.height) && FlxG.mouse.overlaps(c) && FlxG.mouse.justPressed && !lockMovement && cutscenePhase == NONE)
			{
				if (curSelect != c.ID)
				{
					curSelect = c.ID;
					smoothSelect = curSelect;
					changeSong(0, false);
					FlxG.sound.play(Paths.sound('hover'), 0.5);
				}
				else acceptSong();
			}
		}
		
		lerpScore = MathUtil.fpsLerp(lerpScore, intendedScore, .32);
		lerpRating = MathUtil.fpsLerp(lerpRating, intendedRating, .18);
		
		var scoreVal:String = FlxStringUtil.formatMoney(Math.round(lerpScore), false);
		var accVal:String = (Math.round(lerpRating * 10000) / 100) + '%';
		
		var scoreLine:String = Lang.hasSpecial('rightToLeft') ? '$scoreVal :${score_rating[0]}' : '${score_rating[0]}: $scoreVal';
		var accLine:String = Lang.hasSpecial('rightToLeft') ? '$accVal :${score_rating[1]}' : '${score_rating[1]}: $accVal';
		
		infoText.text = scoreLine + '\n' + accLine;
		
		super.update(elapsed);
	}
	
	function resetScorePrompt():Void
	{
		if (ws_lock[curSelect]) return;
		
		var song:SongInformation = week_songs[curSelect];
		
		openSubState(new funkin.states.substates.ResetScoreSubState(song.songName, 1, song.icon));
		
		subStateClosed.addOnce(function(_) {
			cards.members[curSelect].initCard(song);
			
			intendedScore = Highscore.getScore(song.songName, 1);
			intendedRating = Highscore.getRating(song.songName, 1);
		});
		
		lockMovement = true;
	}
	
	// Convert to public static for my menu support. I'm a fat gay boy.
	// hello
	public function goToSection(sect:Int, wrap:Bool = false)
	{
		if (sect == curMonth) return;
		
		if (wrap)
		{
			final diff:Int = (sect - curMonth);
			if (diff < -weeks.length * .5) smoothMonth -= weeks.length;
			if (diff > weeks.length * .5) smoothMonth += weeks.length;
		}
		
		changeSection(sect - curMonth);
	}
	
	function checkLock(song:SongInformation)
	{
		if (localWeeks.contains(song.songName)) return false; // we can probably merge these two returns
		if (ClientPrefs.forceUnlock) return false; // creative mode
		// trace(song);
		
		switch (song.lock)
		{
			case 'special' | 'story':
				for (song in song.requiredSongs)
				{
					if (!ProgressionUtil.songIsClear(song)) return true;
				}
			case 'shop':
				return !localWeeks.contains(song.songName);
		}
		
		return false;
	}
	
	public function unlockAnim(c:FreeplayCard, cutscene:Bool = false)
	{
		final funnyMembers = [c.lock, c.card, c.icon, c.name, c.bean, c.priceText, c.credit, c.note];
		function setBrightness(n:Float)
		{
			final b:Float = (n * 255);
			for (member in funnyMembers)
			{
				final ct = member.colorTransform;
				member.setColorTransform(ct.redMultiplier, ct.greenMultiplier, ct.blueMultiplier, member.alpha, b, b, b);
			}
		}
		
		FlxG.sound.play(Paths.sound('unlockSong'), .9);
		
		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			c.lock.offset.set(0, 3);
			c.lock.animation.play('unlock');
			
			FlxTween.num(0, 1, 1.2, {ease: FlxEase.expoIn}, setBrightness);
			
			new FlxTimer().start(1.3, function(tmr:FlxTimer) {
				if (!cutscene)
				{
					changePortrait(true);
					lockMovement = false;
				}
				
				FlxTween.num(1, 0, 1.2, {ease: FlxEase.expoOut}, setBrightness);
				c.unlockCard();
				
				for (i in cards.members.concat(cachedCards.members))
					i.refreshPriceTxt();
			});
		});
	}
	
	public static function loadSong(song:String, silent:Bool = false):Void
	{
		// PlayState.storyMeta.difficulty = 1; // This would be 2 but I just made them all normal difficulty because -hard was annoying lol
		
		final ret = PlayState.prepareForSong(song);
		
		if (ret != null) return trace('THIS CHART IS INVALID! FUCK!');
		
		final switchToCharter:Bool = (FlxG.keys.pressed.SHIFT && ClientPrefs.inDevMode);
		
		if (switchToCharter) ChartEditorState.song = PlayState.SONG;
		
		FlxG.switchState(switchToCharter ? ChartEditorState.new : PlayState.new);
	}
	
	override function destroy()
	{
		super.destroy();
		
		ClientPrefs.unlockedSongs = localWeeks;
		ClientPrefs.flush();
	}
	
	function addWeeks():Void
	{
		weeks.resize(0);
		
		WeekData.reloadWeekFiles(true);
		FreeplaySectionData.sort();
		
		function fetchWeekSongs(weekData:WeekData):Array<Array<Dynamic>>
		{
			var cachedPortraits:Array<String> = [];
			var songs:Array<Array<Dynamic>> = [];
			
			if (weekData == null) return songs;
			
			// maybe should just rewrite the way the song stuff is read instead of mangling it to match lol
			for (song in weekData.songs)
			{
				var cost:Float = (song[6] ?? 0);
				var shouldHideUntilDoubleTrouble:Bool = (song[8] == true);
				var rgb:Array<Int> = song[2];
				var data:Array<Dynamic> = [
					song[0], song[1], song[3], FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]),
					(cost > 0 ? 'shop' : (song[7] == true ? 'special' : 'story')), song[5] ?? [Paths.sanitize(song[0])], cost,
					song[4], weekData.currency, shouldHideUntilDoubleTrouble, weekData.folder
				];
				
				// Lagspike prevention down below
				// check the array to see if it contains the string of the portrait so we don't cache the same portrait if its already been cached
				if (!cachedPortraits.contains(song[3]))
				{
					cachedPortraits.push(song[3]);
					
					final image:String = 'menu/freeplay/portraits/${song[3]}';
					if (Paths.fileExists('images/$image.png', LOOSE)) Paths.image(image, LOOSE);
				}
				songs.push(data);
			}
			
			return songs;
		}
		
		for (section in FreeplaySectionData.freeplaySectionsList)
		{
			var sectionData:FreeplaySectionData = FreeplaySectionData.freeplaySections.get(section);
			
			if (sectionData == null) continue;
			
			var freeplayWeek:FreeplayWeek =
				{
					title: sectionData.title,
					mod: sectionData.folder,
					section: section,
					songs: []
				}
				
			for (week in sectionData.weeks)
			{
				for (song in fetchWeekSongs(WeekData.weeksLoaded.get(week)))
					freeplayWeek.songs.push(song);
			}
			
			Mods.currentModDirectory = freeplayWeek.mod;
			
			freeplayWeek.graphic = Paths.image('${ext}sections/${freeplayWeek.section}')?.key; // yeaa go to HELL !!!
			
			weeks.push(freeplayWeek);
		}
		
		Mods.currentModDirectory = null;
		
		for (circ in circles) circ.destroy();
		circles.clear();
		
		for (i in 0 ... 10)
		{
			final circ:FlxSprite = circles.add(new FlxSprite());
			
			circ.ID = i;
			circ.zIndex = Std.int(Math.abs(i - 5));
		}
		
		circles.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
}
