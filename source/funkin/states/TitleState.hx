package funkin.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;

import funkin.data.WeekData;
import funkin.objects.Alphabet;

@:nullSafety
class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var closedState:Bool = false;
	
	// For a potential loading screen but i dont think its necessary
	public static var funFacts:Array<String> = [
		'You need at least 4,870 beans to unlock every song.', // its true
		'Despite its\' name, Double Kill only features one kill.', // double kill
		'I\'m the black impostor! I am gonna kill you!', // defeat
		'The Airship contains many wacky trinkets in i! Try the teleporter today!', // henry
		'"Why don\'t we begin?"', // torture
		'The shapeshifter\'s name is Monotone.', // doc
		'"Impostor Trouble? Now it is double."', // double trouble
		'Beat the Tomongus week to unlock a new song!',
		'I don\'t want to get rid of this'
	];
	
	var skippedIntro:Bool = false;
	var transitioning:Bool = false;
	
	var introEndingText:Array<String> = ['VS', 'IMPOSTOR', 'LEGACY'];
	var randomIntroText:Array<String> = [];
	
	// objects
	var starFG:Null<FlxSprite> = null;
	var starBG:Null<FlxSprite> = null;
	var textGroup:Null<FlxGroup> = null;
	var ngSpr:Null<FlxSprite> = null;
	var logo:Null<FlxSprite> = null;
	var titleText:Null<FlxSprite> = null;
	
	public static function init():Void
	{
		FunkinAssets.cache.clearStoredMemory();
		FunkinAssets.cache.clearUnusedMemory();
		
		// for some reason the plugin scripts dont run sometimes when first loaded. oh well
		funkin.scripting.PluginsManager.prepareSignals();
		funkin.scripting.PluginsManager.populate();
	}
	
	override public function create():Void
	{
		if (FlxG.save.data.photosensitive == null && !FlashingState.leftState)
		{
			CoolUtil.setTransSkip();
			FlxG.switchState(FlashingState.new);
			
			return super.create();
		}
		
		if (ClientPrefs.finaleState == COMPLETE)
		{
			if (!ProgressionUtil.songIsClear('finale'))
			{
				ClientPrefs.finaleState = ACTIVE; // failsafe for a realy specific case
			}
			else if (!ClientPrefs.doubletrouble)
			{
				ClientPrefs.doubletrouble = true;
			}
		}
		
		init();
		
		randomIntroText = FlxG.random.getObject(getIntroText());
		
		initStateScript();
		
		startIntro();
		
		super.create();
		
		#if ASSET_REDIRECT
		if (Paths.fileExists('images/cursor.png'))
			FlxG.mouse.load(openfl.display.BitmapData.fromFile(Paths.getPath('images/cursor.png')));
		#else
		FlxG.mouse.load('assets/images/cursor.png');
		#end
		
		persistentUpdate = true;
		
		FlxG.mouse.visible = true;
	}
	
	function startIntro()
	{
		if (!initialized)
		{
			FunkinSound.playMusic(Paths.music('freakyMenu'), 0);
		}
		
		Conductor.bpm = 102;
		Conductor.bpmChangeMap.resize(0);
		
		if (isHardcodedState() && !ScriptConstants.stopping(scriptGroup.call('onStartIntro')))
		{
			starBG = new FlxBackdrop(Paths.image('menu/common/starBG'));
			starBG.alpha = 0.001;
			add(starBG);
			
			starFG = new FlxBackdrop(Paths.image('menu/common/starFG'));
			starFG.alpha = 0.001;
			add(starFG);
			
			logo = new FlxSprite(-150, -10).loadAtlasFrames(Paths.getAtlasFrames('logoBumpin'));
			logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logo.animation.play('bump');
			logo.screenCenter(X);
			add(logo);
			
			titleText = new FlxSprite(300, FlxG.height * 0.855).loadAtlasFrames(Paths.getAtlasFrames('menu/title/startText'));
			titleText.animation.addByPrefix('idle', "EnterIdle", 24, false);
			titleText.animation.addByPrefix('press', "EnterStart", 24, false);
			titleText.animation.play('idle');
			titleText.y -= 55;
			
			logo.scale.set(0.84, 0.84);
			logo.updateHitbox();
			logo.screenCenter(X);
			logo.x += 20;
			
			add(titleText);
			
			textGroup = new FlxGroup();
			add(textGroup);
			
			ngSpr = new FlxSprite(0, FlxG.height * 0.52, Paths.image('menu/title/funkin'));
			add(ngSpr);
			ngSpr.visible = false;
			ngSpr.screenCenter(X);
			
			logo.alpha = 0.001;
			titleText.alpha = 0.001;
		}
		
		if (initialized)
		{
			skipIntro();
		}
		else
		{
			initialized = true;
			closedState = false;
		}
		
		scriptGroup.call('onCreatePost', []);
	}
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		if (starFG != null && starBG != null)
		{
			starBG.x = FlxMath.lerp(starBG.x, starBG.x - 0.5, elapsed * 9);
			starFG.x = FlxMath.lerp(starFG.x, starFG.x - 1, elapsed * 9);
		}
		
		if (!isHardcodedState())
		{
			super.update(elapsed);
			return;
		}
		
		final pressedEnter:Bool = FlxG.gamepads.lastActive?.justPressed.START || FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed;
		
		if (!transitioning && skippedIntro)
		{
			if (pressedEnter && !ScriptConstants.stopping(scriptGroup.call('onEnter')))
			{
				FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				transitioning = true;
				
				if (titleText != null)
				{
					titleText.animation.play('press');
					titleText.offset.set(278, 2);
				}
				
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				FlxTimer.wait(1, () -> {
					MainMenuState.fromTitle = true;
					FlxG.switchState(MainMenuState.new);
					closedState = true;
				});
			}
		}
		
		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}
		
		super.update(elapsed);
	}
	
	function createCoolText(textArray:Array<String>, offset:Float = 0)
	{
		if (textGroup == null) return;
		
		for (i in 0...textArray.length)
		{
			final text:Alphabet = new Alphabet(0, 0, textArray[i], true);
			text.screenCenter(X);
			text.y += (i * 60) + 200 + offset;
			
			textGroup.add(text);
		}
	}
	
	function addMoreText(text:String, offset:Float = 0)
	{
		if (textGroup == null) return;
		
		final coolText:Alphabet = new Alphabet(0, 0, text, true);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200 + offset;
		textGroup.add(coolText);
	}
	
	function deleteCoolText()
	{
		if (textGroup != null && textGroup.members[0] != null)
		{
			for (i in 0...textGroup.length)
			{
				var txt = textGroup.members[0];
				textGroup.remove(txt, true);
				
				txt = FlxDestroyUtil.destroy(txt);
			}
		}
	}
	
	function getIntroText():Array<Array<String>>
	{
		if (!FunkinAssets.exists(Paths.txt('introText'))) return [];
		
		final fullText:String = FunkinAssets.getContent(Paths.txt('introText'));
		
		return [for (i in fullText.split('\n')) i.split('--')];
	}
	
	var sickBeats:Int = 0; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	
	override function beatHit()
	{
		super.beatHit();
		
		if (!closedState)
		{
			sickBeats++;
			scriptGroup.set('curBeat', sickBeats);
		}
		
		if (!isHardcodedState() || ScriptConstants.stopping(scriptGroup.call('onBeatHit'))) return;
		
		// just in case
		if (isHardcodedState())
		{
			if (logo != null)
			{
				logo.animation.play('bump', true);
			}
			
			if (!closedState)
			{
				switch (sickBeats)
				{
					case 1:
						FunkinSound.playMusic(Paths.music('freakyMenu'), 0);
						
						if (ClientPrefs.finaleState != ACTIVE) FlxG.sound.music.fadeIn(4, 0, 0.7);
					case 2:
						createCoolText(['MOTORFROG']);
					case 4:
						addMoreText('presents');
					case 5:
						deleteCoolText();
					case 6:
						createCoolText(['This is a mod to'], -60);
					case 8:
						addMoreText('This game right below lol', -60);
						if (ngSpr != null) ngSpr.visible = true;
					case 9:
						deleteCoolText();
						if (ngSpr != null) ngSpr.visible = false;
					case 10:
						if (randomIntroText[0] != null) createCoolText([randomIntroText[0]]);
					case 12:
						if (randomIntroText[1] != null) addMoreText(randomIntroText[1]);
					case 13:
						deleteCoolText();
					case 14:
						if (introEndingText[0] != null) addMoreText(introEndingText[0]);
					case 15:
						if (introEndingText[1] != null) addMoreText(introEndingText[1]);
					case 16:
						if (introEndingText[2] != null) addMoreText(introEndingText[2]);
					case 17:
						skipIntro();
				}
			}
		}
	}
	
	public function skipIntro():Void
	{
		if (!ScriptConstants.stopping(scriptGroup.call('onSkipIntro')) && !skippedIntro)
		{
			ngSpr?.kill();
			textGroup?.kill();
			
			if (starFG != null && starBG != null)
			{
				starBG.alpha = 1;
				starFG.alpha = 1;
			}
			if (logo != null) logo.alpha = 1;
			if (titleText != null) titleText.alpha = 1;
			
			FlxG.camera.flash(FlxColor.WHITE, 4);
			
			skippedIntro = true;
		}
	}
}
