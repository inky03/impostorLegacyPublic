package funkin.states.options;

import flixel.util.FlxStringUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.ui.FlxBar;
import flixel.math.FlxPoint;

import funkin.states.*;
import funkin.objects.*;
import funkin.objects.Character;
import funkin.objects.menu.AmongControls;

using StringTools;

class NoteOffsetState extends MusicBeatState
{
	var boyfriend:Character;
	var gf:Character;
	
	public var camHUD:FunkinCamera;
	public var camGame:FunkinCamera;
	
	var barPercent:Float = 0;
	var delayMin:Int = 0;
	var delayMax:Int = 500;
	var timeBarBG:FlxSprite;
	var timeBar:FlxBar;
	var timeTxt:FlxText;
	var beatText:Alphabet;
	var beatTween:FlxTween;
	
	override public function create()
	{
		// Cameras
		camGame = new FunkinCamera();
		camHUD = new FunkinCamera();
		camHUD.bgColor.alpha = 0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		
		FlxG.camera.zoom = .8;
		FlxG.camera.scroll.set(120, 130);
		
		persistentUpdate = true;
		FlxG.sound.pause();
		// Stage
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);
		
		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		
		// Characters
		gf = new Character(400, 130, ClientPrefs.gfSkin != 'default' ? ClientPrefs.gfSkin : 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		boyfriend = new Character(770, 100, ClientPrefs.bfSkin != 'default' ? ClientPrefs.bfSkin : 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(gf);
		add(boyfriend);
		
		// Note delay stuff
		
		beatText = new Alphabet(0, 0, 'Beat Hit!', true, false, 0.05, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = true;
		timeTxt.cameras = [camHUD];
		
		var bottomControls:AmongControls = new AmongControls([
			['arrow', 'opt_category_adjustdelay'], // select
			['esc', 'back'] // back
		], true);
		bottomControls.camera = camHUD;
		add(bottomControls);
		
		barPercent = ClientPrefs.noteOffset;
		updateNoteDelay();
		
		timeBarBG = new FlxSprite(0, timeTxt.y + 8).loadGraphic(Paths.image('timeBar'));
		timeBarBG.setGraphicSize(Std.int(timeBarBG.width * 1.2));
		timeBarBG.updateHitbox();
		timeBarBG.cameras = [camHUD];
		timeBarBG.screenCenter(X);
		
		timeBar = new FlxBar(0, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'barPercent', delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.createFilledBar(0xFF2e412e, 0xFF44d844);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.cameras = [camHUD];
		
		add(timeBarBG);
		add(timeBar);
		add(timeTxt);
		
		Conductor.bpm = 100.0;
		Conductor.bpmChangeMap.resize(0);
		FunkinSound.playMusic(Paths.music('offsetSong'), 1, true);
		
		super.create();
	}
	
	var holdTime:Float = 0;
	
	override public function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		
		if (controls.UI_LEFT_P)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset - 1, delayMax));
			updateNoteDelay();
		}
		else if (controls.UI_RIGHT_P)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset + 1, delayMax));
			updateNoteDelay();
		}
		
		var mult:Int = 1;
		if (controls.UI_LEFT || controls.UI_RIGHT)
		{
			holdTime += elapsed;
			if (controls.UI_LEFT) mult = -1;
		}
		
		if (controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;
		
		if (holdTime > 0.5)
		{
			barPercent += 100 * elapsed * mult;
			barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
			updateNoteDelay();
		}
		
		if (controls.RESET)
		{
			holdTime = 0;
			barPercent = 0;
			updateNoteDelay();
		}
		
		if (controls.BACK)
		{
			zoomTween?.cancel();
			beatTween?.cancel();
			
			// trace('WHY ARE YOU DOING THIS TO ME');
			try
			{
				timeBar.destroy();
				FunkinSound.playMusic(Paths.music('freakyMenu'));
				FlxG.switchState(funkin.states.options.OptionsState.new);
			}
			catch (e)
			{
				trace(e);
			}
		}
		
		super.update(elapsed);
	}
	
	var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;
	
	override public function beatHit()
	{
		super.beatHit();
		
		if (lastBeatHit == curBeat)
		{
			return;
		}
		
		gf.dance();
		
		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			
			FlxG.camera.zoom = 0.85;
			
			if (zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: .8}, 1,
				{
					ease: FlxEase.quartOut,
					onComplete: (_) -> zoomTween = null
				});
				
			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			beatTween?.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1,
				{
					ease: FlxEase.sineIn,
					onComplete: (_) -> beatTween = null
				});
		}
		
		lastBeatHit = curBeat;
	}
	
	function updateNoteDelay()
	{
		ClientPrefs.noteOffset = Math.round(barPercent);
		timeTxt.text = '${Math.floor(barPercent)}  ms';
	}
}
