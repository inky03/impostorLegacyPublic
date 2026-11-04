package funkin.states.substates;

import funkin.input.TurboControl;

import flixel.group.FlxSpriteGroup;

import funkin.states.*;
import funkin.states.options.OptionsState;
import funkin.utils.CameraUtil;
import funkin.states.substates.CosmeticsSubstate;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxStringUtil;

class PauseSubState extends funkin.backend.MusicBeatSubstate
{
	public static var instance:PauseSubState;
	public static var songName:String = '';
	
	var pauseMusic:FlxSound;
	var pauseGroup:FlxSpriteGroup;
	var options:Array<String> = ['resumesong', 'restartsong', 'options', 'backtomenu'];
	
	var pauseBG:FlxSprite;
	var optionText:Array<FlxText> = [];
	
	var curSelect:Int = 0;
	
	var viewingMode:Bool = false;
	var looksie:FlxSprite;
	var infoTitle:FlxText;
	var infoSubtext:FlxText;
	
	var turboGroup:TurboControlGroup;
	var controlLEFT:TurboControl = TurboControl.fromControl('ui_left');
	var controlRIGHT:TurboControl = TurboControl.fromControl('ui_right');
	
	public var skipToTimeOption:Null<FlxText> = null;
	var skipToTime:Float;
	
	override function create()
	{
		add(turboGroup = new TurboControlGroup());
		turboGroup.add(controlLEFT).rate = (1 / 45);
		turboGroup.add(controlRIGHT).rate = (1 / 45);
		
		var cam:FlxCamera = CameraUtil.lastCamera;
		instance = this;
		
		initStateScript('PauseSubState');
		
		pauseMusic = new FlxSound();
		pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);
		
		pauseGroup = new FlxSpriteGroup();
		pauseGroup.cameras = [cam];
		
		pauseBG = new flixel.system.FlxBGSprite();
		pauseBG.color = FlxColor.BLACK;
		pauseBG.alpha = 0;
		pauseGroup.add(pauseBG);
		
		var glow:FlxSprite = new FlxSprite(500, -12.65).loadGraphic(Paths.image('menu/freeplay/backGlow'));
		glow.flipX = false;
		glow.color = PlayState.instance.dad.healthColorArray != null ? PlayState.instance.dad.healthColour : FlxColor.WHITE;
		pauseGroup.add(glow);
		
		var dwp:String = getDadPortrait();
		var p:String = portraitExists(dwp) ? dwp : 'placeholder';
		var portrait:FlxSprite = new FlxSprite(0, -125).loadGraphic(Paths.image('menu/freeplay/portraits/' + p));
		portrait.offset.x += (portrait.frameWidth - 1215) * 0.5 * portrait.scale.x;
		portrait.offset.y += (portrait.frameHeight - 1097) * 0.5 * portrait.scale.y;
		portrait.x = FlxG.width;
		pauseGroup.add(portrait);
		
		FlxTween.tween(portrait, {x: 304.65}, 0.3, {ease: FlxEase.circOut});
		
		var pad:Int = 15;
		
		infoTitle = new FlxText(0, pad, FlxG.width - pad, 'ME');
		infoTitle.setFormat(Paths.font('liberbold.ttf', false), 24, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pauseGroup.add(infoTitle);
		
		infoSubtext = new FlxText(0, 30 + pad, FlxG.width - pad, 'I MADE THE SONG');
		infoSubtext.setFormat(Paths.font('liber.ttf', false), 24, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pauseGroup.add(infoSubtext);
		
		assignValues(getSongInfo(PlayState.SONG.song));
		
		if (PlayState.chartingMode)
		{
			options.insert(2, 'skiptotime');
			options.insert(3, 'leavechartingmode');
		}
		
		var scale:Float = Math.min(300 / (options.length * 60), 1);
		
		for (i in 0...options.length)
		{
			var opt = new FlxText(-640, 0, -1, Lang.str(options[i]));
			
			if (options[i] == 'skiptotime') skipToTimeOption = opt;
			
			opt.setFormat(Paths.font('liber.ttf'), Std.int(48 * scale), FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			opt.borderSize = 2;
			opt.y = FlxG.height / 2 + (i * 60 * scale) - opt.height;
			opt.ID = i;
			pauseGroup.add(opt);
			optionText.push(opt);
		}
		
		looksie = new FlxSprite(0, FlxG.height - 100).loadGraphic(Paths.image('menu/pause/looksie'));
		looksie.origin.set(25, 75);
		looksie.cameras = [cam];
		looksie.flipX = true;
		
		add(pauseGroup);
		add(looksie);
		cameras = [cam];
		
		skipToTime = Math.max(PlayState.instance.getSongTime(), 0);
		updateSkipTimeOption();
		
		FlxG.sound.play(Paths.sound('panelAppear'), 0.5);
		super.create();
	}
	
	function updateSkipTimeOption():Void
	{
		if (skipToTimeOption == null) return;
		
		final skipStr:String = Lang.str('skiptotime');
		
		if (skipToTimeOption.ID != curSelect)
		{
			skipToTimeOption.text = skipStr;
			return;
		}
		
		final timeStr:String = FlxStringUtil.formatTime(skipToTime / 1000, false);
		final lengthStr:String = FlxStringUtil.formatTime((PlayState.instance.audio.inst?.length ?? PlayState.instance.songLength) / 1000, false);
		
		skipToTimeOption.text = (Lang.hasSpecial('rightToLeft') ? '$timeStr / $lengthStr \t$skipStr' : '$skipStr \t$timeStr / $lengthStr');
	}
	
	public function changeSkipTime(secs:Float /* wait thats funny */):Void
	{
		if (skipToTimeOption == null) return;
		
		skipToTime = FlxMath.mod(skipToTime + secs * 1000, PlayState.instance.audio.inst?.length ?? PlayState.instance.songLength);
		updateSkipTimeOption();
	}
	
	override function update(elapsed:Float)
	{
		if (pauseMusic != null && pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		super.update(elapsed);
		
		var cam = cameras != null && cameras.length > 0 ? cameras[0] : FlxG.camera;
		var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(cam);
		
		if (!viewingMode)
		{
			if (controlLEFT.PRESSED) changeSkipTime(-1);
			if (controlRIGHT.PRESSED) changeSkipTime(1);
			
			if (controls.UI_UP_P || FlxG.mouse.wheel > 0) changeSelection(-1);
			if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0) changeSelection(1);
			
			if (ClientPrefs.inDevMode && (FlxG.keys.justPressed.TAB || FlxG.gamepads.anyJustPressed(X)))
			{
				// lockMovement = true;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				openSubState(new CosmeticsSubstate());
			}
			
			if (controls.ACCEPT) acceptChoice();
		}
		
		if (controls.BACK)
		{
			if (viewingMode)
			{
				changeView(false);
			}
			else
			{
				FlxG.sound.play(Paths.sound('paneldisAppear'), 0.5);
				close();
			}
		}
		
		// quick bugfix
		pauseBG.alpha = FlxMath.lerp(pauseBG.alpha, 0.8, FlxMath.bound(elapsed * 15.6, 0, 1)) * pauseGroup.alpha;
		
		var looksieHover = looksie.overlapsPoint(mousePos, true, cam);
		var looksieScale:Float = FlxMath.lerp(looksie.scale.x, looksieHover ? 1.25 : 1, FlxMath.bound(elapsed * 15.6, 0, 1));
		looksie.scale.set(looksieScale, looksieScale);
		
		if (looksieHover && FlxG.mouse.justPressed)
		{
			changeView(!viewingMode);
		}
		
		pauseGroup.alpha = FlxMath.lerp(pauseGroup.alpha, viewingMode ? 0 : 1, FlxMath.bound(elapsed * 15.6, 0, 1));
		looksie.alpha = FlxMath.lerp(looksie.alpha, viewingMode ? 0.3 : 1, FlxMath.bound(elapsed * 15.6, 0, 1));
		
		for (item in optionText)
		{
			if (item.overlapsPoint(mousePos, true, cam) && FlxG.mouse.justPressed && !viewingMode)
			{
				if (curSelect == item.ID)
				{
					acceptChoice();
				}
				else
				{
					curSelect = item.ID;
					changeSelection(0);
				}
			}
			
			item.x = FlxMath.lerp(item.x, curSelect == item.ID ? 75 : 55, FlxMath.bound(elapsed * 15.6, 0, 1));
			item.alpha = FlxMath.lerp(item.alpha, curSelect == item.ID ? 1 : 0.3, FlxMath.bound(elapsed * 15.6, 0, 1)) * pauseGroup.alpha;
		}
	}
	
	override function destroy()
	{
		if (pauseMusic != null) pauseMusic.destroy();
		super.destroy();
	}
	
	public static function getDadPortrait():String
	{
		// bruh
		if (PlayState.instance.pauseOverride != '') return PlayState.instance.pauseOverride;
		
		var character = PlayState.instance.dad?.curCharacter;
		
		if (PlayState.instance.dad?.pausePortrait != '') return PlayState.instance.dad?.pausePortrait;
		
		return (portraitExists(character) ? character : PlayState.instance.dad?.healthIcon);
	}
	
	static function portraitExists(id:String):Bool
	{
		return Paths.fileExists('images/menu/freeplay/portraits/$id.png');
	}
	
	public static function getSongInfo(songID:String):Array<String>
	{
		var txt = Paths.getPath('songs/' + Paths.sanitize(songID) + '/info.txt', NORMAL);
		var info:Array<String> = CoolUtil.coolTextFile(txt);
		if (info != null && info.length > 0) return info;
		return ['UNKNOWN', 'NO SONG INFO FOUND'];
	}
	
	function assignValues(info:Array<String>):Void
	{
		infoTitle.text = info[0];
		infoSubtext.text = info[1] + (info[2] != null ? '\n' + info[2] : '');
	}
	
	function changeView(view:Bool):Void
	{
		FlxG.sound.play(Paths.sound('menu/looksie'));
		scriptGroup.call('onLooksie', [view]);
		viewingMode = view;
	}
	
	function changeSelection(by:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('hover'), 0.5);
		curSelect = FlxMath.wrap(curSelect + by, 0, options.length - 1);
		updateSkipTimeOption();
	}
	
	function acceptChoice():Void
	{
		scriptGroup.call('onSelect', [options[curSelect]]);
		
		switch (options[curSelect])
		{
			case 'resumesong':
				close();
				
			case 'restartsong':
				restartSong();
				
			case 'skiptotime':
				final curTime:Float = PlayState.instance.getSongTime();
				
				if (curTime > skipToTime)
				{
					PlayState.startOnTime = skipToTime;
					
					FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
					
					FlxG.resetState();
				}
				else if (curTime < skipToTime)
				{
					PlayState.startOnTime = skipToTime;
					
					PlayState.instance.setSongTime(skipToTime);
					PlayState.instance.clearNotesBefore(skipToTime);
					
					PlayState.startOnTime = 0; // die
					
					close();
				}
				
			case 'leavechartingmode':
				PlayState.chartingMode = false;
				close();
				
			case 'options':
				PlayState.instance.paused = true;
				PlayState.instance.audio?.stop();
				OptionsState.onPlayState = true;
				FlxG.switchState(() -> new OptionsState());
				
			case 'backtomenu':
				returnToMain();
		}
	}
	
	public function returnToMain():Void
	{
		PlayState.deathCounter = 0;
		PlayState.seenCutscene = false;
		PlayState.instance.removeModifiers();
		FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : PlayState.isChallenge ? new MarathonMenuState() : new FreeplayState());
		CoolUtil.cancelMusicFadeTween();
		FunkinSound.playMusic(Paths.music('freakyMenu'));
		PlayState.changedDifficulty = false;
	}
	
	public function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true;
		PlayState.instance.audio?.stop();
		FlxG.resetState();
	}
}
