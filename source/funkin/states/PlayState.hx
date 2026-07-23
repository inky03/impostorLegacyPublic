package funkin.states;

import haxe.Timer;
import haxe.ds.Vector;

import openfl.events.KeyboardEvent;

import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.helpers.FlxBounds;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxStringUtil;

import funkin.input.InputSystem;
import funkin.input.InputEvent;
import funkin.objects.Character;
import funkin.backend.Difficulty;
import funkin.game.RatingInfo;
import funkin.objects.note.*;
import funkin.objects.note.Note;
import funkin.game.huds.BaseHUD;
import funkin.scripts.*;
import funkin.data.Song;
import funkin.data.StageData;
import funkin.game.Rating;
import funkin.objects.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.states.editors.*;
import funkin.game.modchart.*;
import funkin.game.StoryMeta;
import funkin.game.Countdown;
import funkin.game.marathon.*;
import funkin.objects.menu.AwardPopup;
import funkin.objects.menu.BeansPopup;
import funkin.audio.SyncedFlxSoundGroup;
#if VIDEOS_ALLOWED
import funkin.video.FunkinVideoSprite;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X:Float = 42; // redundant
	public static var STRUM_X_MIDDLESCROLL:Float = -278; // redundant
	
	public static var meta:Null<Metadata> = null; // bad?
	
	public static var SONG:Null<Song> = null;
	
	public static var storyMeta:StoryMeta = new StoryMeta();
	
	public static var isStoryMode:Bool = false;
	public static var isChallenge:Bool = false;
	
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	
	public static var isPixelStage:Bool = false;
	
	/**
	 * Static reference to the state. used for other classes to reference
	 */
	public static var instance:Null<PlayState> = null;
	
	/**
	 * Helper function to ready PlayState for conveniently.
	 * 
	 * will return null if done successfully. Otherwise, the exception will be returned.
	 */
	public static function prepareForSong(songName:String, difficulty:Int = 1, isStoryMode:Bool = false):Null<haxe.Exception>
	{
		try
		{
			PlayState.SONG = Chart.fromSong(songName, difficulty);
			PlayState.storyMeta.difficulty = difficulty;
			PlayState.isStoryMode = isStoryMode;
			
			return null;
		}
		catch (e)
		{
			// Logger.log('Failed to prepare for song.\nException $e', ERROR);
			return e;
		}
	}
	
	/**
	 * Multiplier to the game speed
	 */
	public var playbackRate(default, set):Float = 1;
	
	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic) audio.pitch = value;
		
		if (!paused) FlxG.timeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		
		playbackRate = value;
		#else
		playbackRate = 1;
		#end
		return playbackRate;
	}
	
	public var volumeMult(default, set):Float = 1;
	
	function set_volumeMult(value:Float):Float
	{
		audio.volume *= (value / volumeMult);
		
		return volumeMult = value;
	}
	
	public var modManager:ModManager;
	public var modifiersRegistered:Bool = false;
	public var generatedFields:Bool = false;
	public var holdSubdivisions:Int = 1;
	
	var speedChanges:Array<SpeedEvent> = [{}];
	
	public var currentSV:SpeedEvent = {};
	
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	
	public var variables:Map<String, Dynamic> = new Map();
	
	public static var marathonModifiers:Array<MaraModifier> = [];
	
	/**
	 * Disables automatic camera movements if enabled.
	 */
	public var isCameraOnForcedPos:Bool = false;
	
	public var cameraLerping:Bool = true;
	
	/**
	 * Container of all boyfriend characters used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var boyfriendGroup:CharacterGroup;
	
	/**
	 * Container of all dad characters used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var dadGroup:CharacterGroup;
	
	/**
	 * Container of all gf characters used in the state
	 * 
	 * Exists for the `Change Character` event.
	 */
	public var gfGroup:CharacterGroup;
	
	/**
		Reference to the current dad
	**/
	public var dad:Character;
	
	/**
		Reference to the current girlfriend
	**/
	public var gf:Character;
	
	/**
		Reference to the current girlfriend
	**/
	public var boyfriend:Character;
	
	/**
		scary
	**/
	public var pet:Pet;
	
	/**
		Reference to the player stage X position
	**/
	public var BF_X:Float = 770;
	
	/**
		Reference to the player stage Y position
	**/
	public var BF_Y:Float = 100;
	
	/**
		Reference to the opponent stage X position
	**/
	public var DAD_X:Float = 100;
	
	/**
		Reference to the opponent stage Y position
	**/
	public var DAD_Y:Float = 100;
	
	/**
		Reference to the girlfriend stage X position
	**/
	public var GF_X:Float = 400;
	
	/**
		Reference to the girlfriend stage Y position
	**/
	public var GF_Y:Float = 130;
	
	/**
		Reference to the pet stage X position
	**/
	public var PET_X:Float = 0;
	
	/**
		Reference to the pet stage Y position
	**/
	public var PET_Y:Float = 0;
	
	/**
	 * A container of where all sprites placed
	 */
	public var stage:Stage;
	
	public var songSpeedTween:Null<FlxTween> = null;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var spawnTime:Float = 3000;
	
	/**
	 * Specialized container for song audio
	 */
	public var audio:PlayableSong;
	
	public var notes:FlxTypedGroup<Note>;
	public var queueNotes:Array<QueueNote> = [];
	public var eventNotes:Array<EventNote> = [];
	
	/**
	 * Target the game camera follows
	 */
	var camFollow:FlxObject;
	
	/**
	 * Previous cameras target. used in story mode for a more seamless transition
	 */
	static var prevCamFollow:Null<FlxObject> = null;
	
	/**
	 * List of FlxCameras that follow camFollow
	**/
	public var followingCams:Array<FlxCamera> = [];
	
	/**
	 * Container of all strumline underlays
	 */
	public var underlays:Null<FlxTypedGroup<LaneUnderlay>> = null;
	
	/**
	 * Container of all strumlines in use
	 */
	public var playFields:Null<FlxTypedGroup<PlayField>> = null;
	
	/**
	 * The oppononents Strum field
	 */
	public var opponentStrums(get, never):Null<PlayField>;
	
	function get_opponentStrums()
	{
		for (i in playFields?.members)
			if (i.ID == 1) return i;
		return playFields?.members[1];
	}
	
	/**
	 * The players Strum field
	 */
	public var playerStrums(get, never):Null<PlayField>;
	
	function get_playerStrums()
	{
		for (i in playFields?.members)
			if (i.ID == 0) return i;
		return playFields?.members[0];
	}
	
	// i dont understand the need to change the ids tbh
	function getFieldFromID(id:Int):Null<PlayField>
	{
		for (i in playFields?.members)
			if (i.ID == id) return i;
		return playFields?.members[id];
	}
	
	@:isVar public var strumLineNotes(get, null):Array<StrumNote>;
	
	@:noCompletion function get_strumLineNotes()
	{
		final notes:Array<StrumNote> = [];
		if (playFields != null && playFields.length != 0)
		{
			for (field in playFields.members)
			{
				for (sturm in field.members)
					notes.push(sturm);
			}
		}
		return notes;
	}
	
	/**
	 * The container that all notesplashes are held in
	 */
	public var grpNoteSplashes:FlxTypedContainer<NoteSplash>;
	
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	
	var curSong:String = "";
	
	/**
	 * The minimum and max bound that health can be within
	 */
	public var healthBounds:FlxBounds<Float> = new FlxBounds(0.0, 2.0);
	
	@:isVar public var health(default, set):Float = 1;
	
	@:noCompletion function set_health(value:Float):Float
	{
		health = value;
		callHUDFunc(hud -> hud.onHealthChange(value));
		return value;
	}
	
	var songPercent:Float = 0;
	
	public var combo:Int = 0;
	public var missCombo:Int = 0;
	public var ratingsData:Array<Rating> = [
		new Rating('sick'),
		new Rating('good'),
		new Rating('bad'),
		new Rating('shit')
	];
	
	public var epics:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	var generatedMusic:Bool = false;
	
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	
	var updateTime:Bool = true;
	
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var startOnTime:Float = 0;
	
	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var pressMissDamage:Float = .05;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;
	
	public var botplayTxt:FlxText;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	
	public var defaultScoreAddition:Bool = true;
	
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	
	public var defaultCamZoomAdd:Float = 0;
	
	/**
	 * Default camera zoom the game will attempt to return to.
	 * 
	 * set via the Stage json
	 */
	public var defaultCamZoom:Float = 1.05;
	
	/**
	 * Default `camHUD` zoom the game will attempt to return to.
	 */
	public var defaultHudZoom:Float = 1;
	
	public var beatsPerZoom:Int = 0;
	
	var totalBeat:Int = 0;
	var totalShake:Int = 0;
	var timeBeat:Float = 1;
	var gameZ:Float = 0.015;
	var hudZ:Float = 0.03;
	var gameShake:Float = 0.003;
	var hudShake:Float = 0.003;
	var shakeTime:Bool = false;
	
	public var inCutscene:Bool = false;
	public var ingameCutscene:Bool = false;
	
	public var genNotesBeforeCountdown:Bool = true;
	
	public var skipCountdown:Bool = false;
	public var countdownSounds:Bool = true;
	public var countdownDelay:Float = 0;
	
	/**
	 * The length of the music track in miliseconds
	 * 
	 * Used for discord RPC and the time bar.
	 * 
	 * Can be manually changed.
	 */
	public var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];
	
	/**
	 * The shown description in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcDescription:String = '';
	
	/**
	 * The shown paused Description in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcPausedDescription:String = '';
	
	/**
	 * The shown song name in the discord RPC.
	 * 
	 * Can be manually changed.
	 */
	var rpcSongName:String = '';
	
	/**
	 * Pause character portrait overwrite variable
	**/
	public var pauseOverwrite(get, set):String;
	
	public var pauseOverride:String = '';
	
	/**
	 * Variable that determines whether PlayState will automatically handle Discord RPC.
	 *
	 * Useful for if you want custom Discord RPC messages and PlayState gets in the way.
	**/
	public var automatedDiscord:Bool = true;
	
	/**
	 * Group of general scripts.
	 */
	public var scripts:ScriptGroup;
	
	/**
	 * Group of note type scripts. these have some special functions for their use
	 */
	public var noteTypeScripts:ScriptGroup;
	
	/**
	 * Group of event scripts. these have some special functions for their use
	 */
	public var eventScripts:ScriptGroup;
	
	public var arrowSkins:Array<String> = [];
	
	// ????
	public var script_NOTEOffsets:Vector<FlxPoint>;
	public var script_STRUMOffsets:Vector<FlxPoint>;
	public var script_SUSTAINOffsets:Vector<FlxPoint>;
	public var script_SUSTAINENDOffsets:Vector<FlxPoint>;
	
	public var introSoundsSuffix:String = '';
	
	// Debug buttons
	var debugKeysChart:Array<FlxKey>;
	var debugKeysCharacter:Array<FlxKey>;
	
	/**
	 * once set to a target, the camera will only follow them.
	 */
	public var camCurTarget:Null<Character> = null;
	
	public var playHUD:Null<BaseHUD> = null;
	
	/**
	 * Called when the Song should start
	 * 
	 * Change this to set custom behavior
	 * 
	 * Generally though your custom callback Should end with `startCountdown` to start the song
	 */
	public var songStartCallback:Null<Void->Void> = null;
	
	/**
	 * Called when the Song should end
	 * 
	 * Change this to set custom behavior
	 */
	public var songEndCallback:Null<Void->Void> = null;
	
	/*
	 * Niche impostor song specific vars
	 */
	public static var attackCharacter:Int = 0; // who ur playing as in monotone attack
	public static var totalMisses:Int = 0;
	public static var missLimit:Bool = false;
	public var focusPlayer:Null<Character> = null;
	
	public var allowBFSkin:Bool;
	public var allowGFSkin:Bool;
	public var allowPet:Bool;
	
	public var input:InputSystem;
	
	var tauntCharacter(get, set):Null<Character>;
	
	inline function get_tauntCharacter():Null<Character> return focusPlayer;
	inline function set_tauntCharacter(v:Null<Character>):Null<Character> return focusPlayer = v;
	
	inline function get_pauseOverwrite():String return pauseOverride;
	inline function set_pauseOverwrite(v:String):String return pauseOverride = v;
	
	@:noCompletion public function set_cpuControlled(val:Bool):Bool
	{
		if (playFields != null && playFields.members.length != 0)
		{
			for (field in playFields.members)
			{
				if (field.isPlayer) field.autoPlayed = val;
			}
		}
		return (cpuControlled = val);
	}
	
	function applyStageData(file:Null<StageFile>):Void
	{
		if (file == null) return;
		
		defaultCamZoom = file.defaultZoom;
		FlxG.camera.zoom = file.defaultZoom;
		isPixelStage = file.isPixelStage;
		
		BF_X = file.boyfriend[0];
		BF_Y = file.boyfriend[1];
		
		GF_X = file.girlfriend[0];
		GF_Y = file.girlfriend[1];
		
		DAD_X = file.opponent[0];
		DAD_Y = file.opponent[1];
		
		PET_X = (file.pet == null ? (BF_X + 370) : file.pet[0]);
		PET_Y = (file.pet == null ? (BF_Y + 849) : file.pet[1]);
		
		if (file.camera_speed != null) cameraSpeed = file.camera_speed;
		
		boyfriendCameraOffset = file.camera_boyfriend ?? [0, 0];
		
		opponentCameraOffset = file.camera_opponent ?? [0, 0];
		
		girlfriendCameraOffset = file.camera_girlfriend ?? [0, 0];
		
		boyfriendGroup ??= new CharacterGroup(BF_X, BF_Y, BF);
		dadGroup ??= new CharacterGroup(DAD_X, DAD_Y, DAD);
		gfGroup ??= new CharacterGroup(GF_X, GF_Y, GF);
		
		pet ??= new Pet('');
		pet.setPosition(PET_X, PET_Y);
		
		boyfriendGroup.zIndex = (file.bfZIndex ?? 0);
		dadGroup.zIndex = (file.dadZIndex ?? 0);
		gfGroup.zIndex = (file.gfZIndex ?? 0);
		pet.zIndex = (file.petZIndex ?? boyfriendGroup.zIndex);
	}
	
	// null checking
	function callHUDFunc(hud:BaseHUD->Void):Void if (playHUD != null) hud(playHUD);
	
	override public function create():Void
	{
		FlxG.sound.music?.stop();
		
		FunkinAssets.cache.clearStoredMemory();
		
		funkin.backend.DebugDisplay.addPlugin(() -> 'curStep: $curStep • curBeat: $curBeat • curSection: $curSection');
		
		skipCountdown = false;
		countdownSounds = true;
		
		instance = this;
		
		GameOverSubstate.resetVariables();
		
		scripts = new ScriptGroup(this);
		eventScripts = new ScriptGroup(this);
		noteTypeScripts = new ScriptGroup(this);
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = 'breakfast'; // Reset to default
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// If u have kutty enabled
		if (ClientPrefs.useEpicRankings) ratingsData.unshift(new Rating('epic'));
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		grpNoteSplashes = new FlxTypedContainer<NoteSplash>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		SONG ??= Chart.fromPath(Paths.json('test/test'));
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkins = SONG.arrowSkins;
		
		// set up rpc stuff
		rpcDescription = isStoryMode == true ? 'Story Mode' : 'Freeplay';
		rpcPausedDescription = 'Paused - ' + rpcDescription;
		rpcSongName = SONG.song;
		
		scripts.set('isStoryMode', isStoryMode);
		scripts.set('attackCharacter', attackCharacter);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		
		// Check for bf/gf skins
		// SOMEONE GOT THE CODE WRONG IM GONNA FUCKING KILL YOUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU YOU'RE GOING TO DIE
		// i think it was me... im so sorry.
		allowBFSkin = (!isStoryMode && (SONG.allowBFskin ?? true));
		allowGFSkin = (!isStoryMode && (SONG.allowGFskin ?? true));
		allowPet = (!isStoryMode && (SONG.allowPet ?? true));
		
		stage = new Stage(SONG.stage);
		applyStageData(stage.stageData);
		
		stage.buildStage();
		
		if (stage.runScript(scripts))
		{
			scripts.addScript(stage.script);
			
			Logger.log('script: ' + stage.script.name + ' intialized');
		}
		
		if (isPixelStage) introSoundsSuffix = '-pixel';
		
		if (!ScriptConstants.stopping(scripts.call("onAddSpriteGroups")))
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
			stage.add(pet);
		}
		
		inline function addSongScripts(directory)
		{
			for (file in Paths.listAllFilesInDirectory(directory, LOOSE).filter(path -> FunkinScript.isHxFile(path)))
			{
				final scriptPath = FunkinScript.getPath(file);
				
				initFunkinScript(file);
			}
		}
		addSongScripts('scripts');
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (allowPet)
		{
			pet.loadPet(ClientPrefs.equipment.get('pet'));
			checkStageFlag(pet);
			startPetScript(pet);
		}
		
		if (!stage.stageData.hide_girlfriend)
		{
			gf = new Character((allowGFSkin ? ClientPrefs.equipment.get('speakerSkin') : null) ?? gfVersion);
			checkStageFlag(gf);
			gfGroup.addChar(gf);
			gfGroup.parent = gf;
			startCharacterScript(gf.curCharacter, gf);
		}
		
		dad = new Character(SONG.player2);
		checkStageFlag(dad);
		dadGroup.addChar(dad);
		dadGroup.parent = dad;
		startCharacterScript(dad.curCharacter, dad);
		
		boyfriend = new Character((allowBFSkin ? ClientPrefs.equipment.get('playerSkin') : null) ?? SONG.player1, true);
		checkStageFlag(boyfriend);
		boyfriendGroup.addChar(boyfriend);
		boyfriendGroup.parent = boyfriend;
		startCharacterScript(boyfriend.curCharacter, boyfriend);
		
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null) gf.visible = false;
		}
		
		Conductor.songPosition = -5000;
		
		underlays = new FlxTypedGroup<LaneUnderlay>();
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		
		notes = new FlxTypedGroup<Note>();
		add(notes);
		
		playHUD = new funkin.game.huds.PsychHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		playHUD.insert(playHUD.underlayOrder, underlays);
		
		meta = Metadata.getSong();
		
		modManager = new ModManager(this);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		
		add(camFollow);
		
		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		botplayTxt = new FlxText(400, 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		if (ClientPrefs.downScroll) botplayTxt.y = FlxG.height - botplayTxt.height - 55;
		add(botplayTxt);
		
		notes.cameras = [camHUD];
		playFields.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		addSongScripts('songs/${Paths.sanitize(SONG.song)}/');
		addSongScripts('songs/${Paths.sanitize(SONG.song)}/scripts/');
		
		scripts.call('preNoteGeneration', []);
		
		if (genNotesBeforeCountdown) generatePlayfields();
		generateSong(SONG.song);
		
		if (!ClientPrefs.opponentStrums || ClientPrefs.middleScroll)
		{
			for (playField in playFields)
			{
				if (playField.isPlayer)
				{
					if (ClientPrefs.middleScroll) modManager.setValue('opponentSwap', .5, playField.ID);
					
					continue;
				}
				
				playField.visible = false;
				
				modManager.setValue('alpha', 1, playField.ID);
			}
		}
		
		if (!ClientPrefs.opponentLaneUnderlay)
		{
			for (i => playField in playFields)
			{
				if (playField.isPlayer) continue;
				
				playField.underlay.kill();
			}
		}
		
		#if FLX_DEBUG
		FlxG.watch.addFunction('Conductor: ', () -> Conductor.songPosition);
		FlxG.watch.addFunction('SongTime: ', () -> FlxStringUtil.formatTime(Conductor.songPosition / 1000)
			+ ' / '
			+ FlxStringUtil.formatTime(audio.songLength / 1000));
			
		FlxG.watch.addFunction('curSec: ', () -> curSection);
		FlxG.watch.addFunction('curBeat: ', () -> curBeat);
		FlxG.watch.addFunction('curStep: ', () -> curStep);
		#end
		
		moveCameraSection();
		
		noteTypeMap?.clear();
		noteTypeMap = null;
		
		audio?.stop();
		
		startingSong = true;
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		Paths.music(Paths.sanitize('breakfast'));
		
		// Updating Discord Rich Presence.
		resetDiscordRPC();
		
		input = new InputSystem(controls);
		input.addEventListener(InputEvent.INPUT_PRESSED, onInputPress);
		input.addEventListener(InputEvent.INPUT_RELEASED, onInputRelease);
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		scripts.call('onCreatePost', []);
		
		callHUDFunc(hud -> hud.cachePopUpScore());
		
		super.create();
		
		FunkinAssets.cache.clearUnusedMemory();
		
		refreshZ(stage);
	}
	
	function set_songSpeed(value:Float):Float
	{
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrotchet, 350 / songSpeed * playbackRate);
		return value;
	}
	
	public function addCharacterToList(newCharacter:String, type:Int):Void
	{
		final group = switch (type)
		{
			case 1:
				dadGroup;
			case 2:
				(gf != null ? gfGroup : dadGroup);
			default:
				boyfriendGroup;
		}
		
		final newCharacter = group.addToList(newCharacter);
		startCharacterScript(newCharacter.curCharacter, newCharacter);
	}
	
	function startCharacterScript(name:String, char:Character):Void
	{
		var hscriptPath = FunkinScript.getPath('data/characters/$name', LOOSE);
		if (!FunkinAssets.exists(hscriptPath, TEXT)) hscriptPath = FunkinScript.getPath('characters/$name', LOOSE);
		
		if (FunkinAssets.exists(hscriptPath, TEXT))
		{
			var script = initFunkinScript(hscriptPath, false, false);
			
			script?.set('parent', char);
			
			if (script?.exists('onLoad')) script.call('onLoad');
		}
	}
	
	function startPetScript(pet:Pet):Void
	{
		final name:String = pet.curPet;
		
		var hscriptPath = FunkinScript.getPath('data/pets/$name', LOOSE);
		if (!FunkinAssets.exists(hscriptPath, TEXT)) hscriptPath = FunkinScript.getPath('pets/$name', LOOSE);
		
		if (FunkinAssets.exists(hscriptPath, TEXT))
		{
			var script = initFunkinScript(hscriptPath, false, false);
			
			script?.set('parent', pet);
			
			if (script?.exists('onLoad')) script.call('onLoad');
		}
	}
	
	/**
	 * Creates a new `FunkinScript` from filepath and calls `onLoad`. Returns `null` if it couldnt be found
	 * @param name sets a custom name to the script
	 */
	public function initFunkinScript(filePath:String, ?name:String, autoOnLoad:Bool = true, unique:Bool = true):Null<FunkinScript>
	{
		var name:String = (name ?? filePath);
		
		if (scripts.exists(name))
		{
			if (!unique)
			{
				var c:Int = 1;
				
				while (scripts.exists('${name}_$c'))
					c++;
					
				name += '_$c';
			}
			else
			{
				return null;
			}
		}
		
		var script:FunkinScript = FunkinScript.fromFile(filePath, name, scripts.scriptShareables);
		if (script.__garbage)
		{
			script = FlxDestroyUtil.destroy(script);
			return null;
		}
		Logger.log('script: ' + filePath + ' intialized');
		if (autoOnLoad && script.exists('onLoad')) script.call('onLoad');
		scripts.addScript(script);
		return script;
	}
	
	public function getModchartObject(tag:String):Dynamic
	{
		if (variables.exists(tag)) return variables.get(tag);
		if (modchartObjects.exists(tag)) return modchartObjects.get(tag);
		return null;
	}
	
	function checkStageFlag(guy:IFlags):Void
	{
		var variants:Null<haxe.DynamicAccess<String>> = guy.getFlag('variants');
		if (variants == null) return;
		
		for (flag => variant in variants)
		{
			if (!stage.getFlag(flag) && (SONG.flags == null || !SONG.flags.get(flag))) continue;
			
			if (guy is Character)
			{
				cast(guy, Character).loadCharacter(variant);
			}
			else if (guy is Pet)
			{
				cast(guy, Pet).loadPet(variant);
			}
			
			return;
		}
	}
	
	function startCharacterPos(?char:Character, gfCheck:Bool = false):Void
	{
		if (char == null) return;
		
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
	
	public function startVideo(name:String):Void
	{
		#if VIDEOS_ALLOWED
		final fileName = Paths.video(name);
		
		if (FunkinAssets.exists(fileName, BINARY))
		{
			inCutscene = true;
			var bg = new flixel.system.FlxBGSprite();
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);
			
			var vid = new FlxVideo();
			FlxG.addChildBelowMouse(vid);
			vid.onEndReached.add(() -> {
				remove(bg);
				startAndEnd();
				
				FlxG.removeChild(vid);
				vid.dispose();
			});
			vid.load(fileName);
			vid.play();
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#else
		startAndEnd();
		#end
	}
	
	inline function startAndEnd():Void
	{
		endingSong ? endSong() : startCountdown();
	}
	
	public function generatePlayfields()
	{
		if (generatedFields) return;
		
		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
		
		for (lane in 0...SONG.lanes)
		{
			final character = (lane == 1 ? dad : boyfriend);
			final isPlayer = (lane != 1);
			
			final auto = (lane != 0 || cpuControlled);
			
			var strums = new PlayField(0, 0, SONG.keys, character, isPlayer, auto, lane, arrowSkins[lane]);
			// strums.scale = NoteUtil.getSkinFromID(lane).scale;
			scripts.call('preReceptorGeneration', [strums, lane]);
			strums.generateReceptors();
			strums.ID = lane;
			
			playFields.add(strums);
			underlays.add(strums.underlay);
			
			strums.onNoteHit.add((note, field) -> {
				setFocusPlayerFromNote(note);
				
				if (field.ID == 1) camZooming = true;
				
				if (field.playerControls || (!audio.splitVocals && !audio.trackSwap)) audio.hit();
				
				if (field.playerControls && field.showRatings && !note.isSustainNote)
				{
					combo++;
					popUpScore(note);
				}
			});
			strums.onNoteMiss.add((note, field) -> {
				if (note.canMiss || !field.playerControls) return;
				
				setFocusPlayerFromNote(note);
				
				audio.miss();
				if (instakillOnMiss) doDeathCheck(true);
				if (!practiceMode) songScore -= 10;
				
				totalPlayed++;
				songMisses++;
				breakCombo();
				
				if (songMisses > totalMisses && missLimit) doDeathCheck(true);
				
				RecalculateRating(true);
			});
			strums.onMissPress.add((key, field) -> {
				if (!field.playerControls) return;
				
				audio.miss();
				if (instakillOnMiss) doDeathCheck(true);
				if (!practiceMode) songScore -= 10;
				
				if (!endingSong) songMisses++;
				totalPlayed++;
				breakCombo();
				
				if (songMisses > totalMisses && missLimit) doDeathCheck(true);
				
				RecalculateRating();
			});
			
			strums.showRatings = true;
			strums.noteSplashes = (lane == 0);
			
			final splashGrp = strums.splashLayer;
			splashGrp.camera = camHUD;
			splashLayering.push(splashGrp);
			
			for (strum in strums) strum.alpha = 0;
		}
		
		modManager.receptors = [for (i in playFields) i.members];
		
		modManager.lanes = SONG.lanes;
		modManager.keys = SONG.keys;
		
		generatedFields = true;
		scripts.call('postReceptorGeneration');
		
		modManager.registerEssentialModifiers();
		modManager.registerDefaultModifiers();
		modManager.registerScriptedModifiers();
		modifiersRegistered = true;
		
		scripts.call('postModifierRegister');
	}
	
	public function setFocusPlayerFromNote(note:Note)
	{
		final playField = note.playField;
		
		if (playField?.isPlayer) // jsut made some bullshit
		{
			focusPlayer = (note.owner ?? (note.gfNote ? gf : null));
			focusPlayer ??= (note.singers == null ? playField.owner : note.singers[0]);
			
			if (focusPlayer == boyfriend) focusPlayer = null; // ok
		}
	}
	
	var startTimer:FlxTimer = null;
	var finishTimer:FlxTimer = null;
	
	public var countdownReady:Null<FlxSprite> = null;
	public var countdownSet:Null<FlxSprite> = null;
	public var countdownGo:Null<FlxSprite> = null;
	
	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			scripts.call('onStartCountdown', []);
			return;
		}
		
		inCutscene = false;
		
		if (!ScriptConstants.stopping(scripts.call('onStartCountdown')))
		{
			// if its not 0 we can assume this was manually triggered
			if (!genNotesBeforeCountdown) generatePlayfields();
			
			new FlxTimer().start(countdownDelay, (t:FlxTimer) -> {
				startedCountdown = true;
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crotchet * 5;
				scripts.call('onCountdownStarted', []);
				
				for (playField in playFields) playField.fadeIn((isStoryMode && !seenCutscene) || skipArrowStartTween);
				
				var swagCounter:Int = 0;
				
				if (startOnTime < 0) startOnTime = 0;
				
				if (startOnTime > 0)
				{
					clearNotesBefore(startOnTime);
					setSongTime(startOnTime - 350);
					return;
				}
				else if (skipCountdown)
				{
					setSongTime(0);
					return;
				}
				
				startTimer = new FlxTimer().start(Conductor.crotchet / 1000, function(tmr:FlxTimer) {
					if (swagCounter < 4) handleBoppers(tmr.loopsLeft);
					
					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					introAssets.set('default', ['ready', 'set', 'go']);
					introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
					
					var introAlts:Array<String> = introAssets.get('default');
					var antialias:Bool = ClientPrefs.globalAntialiasing;
					if (isPixelStage)
					{
						introAlts = introAssets.get('pixel');
						antialias = false;
					}
					
					switch (swagCounter)
					{
						case 0:
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						case 1:
							countdownReady = makeCountdownSprite(introAlts[0]);
							insert(members.indexOf(notes), countdownReady);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						case 2:
							countdownSet = makeCountdownSprite(introAlts[1]);
							insert(members.indexOf(notes), countdownSet);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						case 3:
							countdownGo = makeCountdownSprite(introAlts[2]);
							
							insert(members.indexOf(notes), countdownGo);
							
							if (countdownSounds) FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
							
						case 4:
					}
					
					scripts.call('onCountdownTick', [swagCounter]);
					
					swagCounter += 1;
				}, 5);
			});
		}
	}
	
	function makeCountdownSprite(path:String):FlxSprite
	{
		final spr = new FlxSprite().loadGraphic(Paths.image(path));
		spr.scrollFactor.set();
		spr.updateHitbox();
		
		if (PlayState.isPixelStage) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		spr.screenCenter();
		spr.antialiasing = isPixelStage ? false : ClientPrefs.globalAntialiasing;
		
		spr.cameras = [camHUD];
		
		FlxTween.tween(spr, {alpha: 0}, Conductor.crotchet / 1000,
			{
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					remove(spr);
					spr.destroy();
				}
			});
		return spr;
	}
	
	public function addBehindGF(obj:FlxObject):Void
	{
		insert(members.indexOf(gfGroup), obj);
	}
	
	public function addBehindBF(obj:FlxObject):Void
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	
	public function addBehindDad(obj:FlxObject):Void
	{
		insert(members.indexOf(dadGroup), obj);
	}
	
	inline function disposeNote(note:Note):Void
	{
		note.kill();
		note.garbage = true;
		notes.remove(note, true);
	}
	
	public function clearNotesBefore(time:Float):Void
	{
		while (queueNotes.length > 0 && queueNotes[0].strumTime - 350 < time)
			queueNotes.shift();
			
		var i:Int = (notes.length - 1);
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time) disposeNote(daNote);
			
			--i;
		}
	}
	
	public function setSongTime(time:Float):Void
	{
		if (time < 0) time = 0;
		
		audio.pause();
		audio.time = time;
		#if FLX_PITCH audio.pitch = playbackRate; #end
		audio.play();
		
		audio.hit();
		
		Conductor.songPosition = time;
	}
	
	function startSong():Void
	{
		startingSong = false;
		
		audio.inst.onComplete = finishSong.bind(false);
		
		#if FLX_PITCH
		audio.pitch = playbackRate;
		#end
		
		if (startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;
		
		songLength = audio.songLength;
		
		audio.volume = 1 * volumeMult;
		audio.play();
		
		if (paused) audio.pause();
		
		// Updating Discord Rich Presence (with Time Left)
		if (automatedDiscord) DiscordClient.changePresence(rpcDescription, rpcSongName, null, true, songLength);
		
		scripts.call('onSongStart', []);
		callHUDFunc(hud -> hud.onSongStart());
	}
	
	var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	var eventsPushed:Array<String> = [];
	var noteTypesPushed:Array<String> = [];
	
	var _parsedEvents:Null<Array<EventNote>> = null;
	
	/**
	 * makes an event note (internal)
	 */
	inline function makeEv(time:Float, ev:String, v1:String, v2:String)
	{
		final ev:EventNote =
			{
				strumTime: time + ClientPrefs.noteOffset,
				event: ev,
				value1: v1,
				value2: v2
			};
		return ev;
	}
	
	/**
	 * returns all events from both the loaded chart and events json
	 * 
	 * these are not sorted
	 */
	function getEventsDirect():Array<EventNote>
	{
		if (_parsedEvents != null) return _parsedEvents;
		
		final events:Array<EventNote> = [];
		
		final songName:String = Paths.sanitize(SONG.song);
		
		var file:String = Paths.json('$songName/data/events');
		
		if (FunkinAssets.exists(file))
		{
			final eventsData:Array<Dynamic> = Chart.fromPath(file).events;
			
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					events.push(makeEv(event[0], event[1][i][0], event[1][i][1], event[1][i][2]));
				}
			}
		}
		
		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
				events.push(makeEv(event[0], event[1][i][0], event[1][i][1], event[1][i][2]));
		}
		
		return (_parsedEvents = events);
	}
	
	function generateSong(dataPath:String):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');
		
		songSpeed = SONG.speed;
		
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		final songData = SONG;
		Conductor.bpm = songData.bpm;
		
		curSong = songData.song;
		
		audio = new PlayableSong();
		audio.populate(SONG);
		audio.hit();
		add(audio);
		
		#if FLX_PITCH
		audio.pitch = playbackRate;
		#end
		
		audio.volume = 0;
		
		scripts.set('vocals', audio);
		scripts.set('inst', audio.inst);
		
		// layering for notesplash stuff
		for (i in splashLayering)
			add(i);
			
		final noteData:Array<SongSection> = songData.notes;
		
		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = ChartEditorState.noteTypeList[type];
				
				if (!noteTypeMap.exists(type)) noteTypeMap.set(type, true);
			}
		}
		
		for (type in noteTypeMap.keys())
		{
			if (!noteTypesPushed.contains(type))
			{
				var baseScriptFile = 'data/notetypes/$type';
				if (!FunkinAssets.exists(FunkinScript.getPath(baseScriptFile), TEXT)) baseScriptFile = 'notetypes/$type';
				
				final scriptFile = FunkinScript.getPath(baseScriptFile);
				
				if (FunkinAssets.exists(scriptFile, TEXT)) noteTypeScripts.addScript(initFunkinScript(scriptFile, type));
				
				noteTypesPushed.push(type);
			}
		}
		
		var events = getEventsDirect();
		
		#if debug
		var cpuTime = Sys.time();
		#end
		
		if (ClientPrefs.inDevMode)
		{
			var crotchet:Float = (60000 / SONG.bpm), time:Float = 0;
			var allNotes:Array<Array<Dynamic>> = [];
			var sectionTimes:Array<{start:Float, end:Float}> = [];
			
			for (i => section in noteData)
			{
				if (section.changeBPM) crotchet = (60000 / section.bpm);
				
				var minTime:Float = time;
				time += (crotchet * (section.sectionBeats ?? 4));
				sectionTimes.push({start: minTime, end: time});
				
				for (songNotes in section.sectionNotes)
				{
					songNotes.push(i);
					allNotes.push(songNotes);
				}
				
				section.sectionNotes.resize(0);
			}
			
			allNotes.sort(function(a, b) return (a[0] > b[0] ? 1 : -1));
			
			final killDifference:Float = 3;
			
			var lastNotes:Array<Array<Dynamic>> = [for (_ in 0...songData.keys) null];
			var i:Int = 0, dupes:Int = 0, fixed:Int = 0;
			
			while (i < allNotes.length)
			{
				var note = allNotes[i++];
				
				if (note[1] >= 0)
				{
					var lastNote = lastNotes[note[1]];
					if (lastNote != null && Math.abs(lastNote[0] - note[0]) < killDifference)
					{
						dupes++;
						continue;
					}
					
					lastNotes[note[1]] = note;
				}
				
				var time:Float = (note[0] + 5);
				var oldSection:Int = note.pop();
				var trueSection:Int = Lambda.findIndex(sectionTimes, (section:{start:Float, end:Float}) -> (time >= section.start && time < section.end));
				
				if (trueSection == -1) trueSection == oldSection;
				
				if (trueSection != oldSection) fixed++;
				
				noteData[trueSection].sectionNotes.push(note);
			}
			
			if (fixed > 0 || dupes > 0) trace('corrected $fixed notes / removed $dupes duplicates');
		}
		
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % SONG.keys);
				var playfield:Int = 0;
				
				playfield = Std.int(songNotes[1] / SONG.keys);
				
				if (playfield < 0) // legacy event notes
				{
					events.push(
						{
							strumTime: daStrumTime + ClientPrefs.noteOffset,
							event: songNotes[2],
							value1: songNotes[3],
							value2: songNotes[4]
						});
						
					continue;
				}
				
				if (playfield >= SONG.lanes) continue;
				
				var oldNote:Note = null;
				
				var type:Dynamic = songNotes[3];
				if (!Std.isOfType(type, String)) type = ChartEditorState.noteTypeList[type];
				
				var susLength:Float = songNotes[2];
				var swagNote = new QueueNote(daStrumTime, susLength, daNoteData, type, false, playfield);
				
				if (section.gfSection && playfield == (section.mustHitSection ? 0 : 1)) swagNote.gfNote = true;
				if ((section?.altAnim ?? false) && (type == '' || type == null)) swagNote.noteType = 'Alt Animation';
				
				queueNotes.push(swagNote);
				
				if (susLength > 0)
				{
					swagNote.tail = [];
					
					var susStep:Int = Std.int(Conductor.getStep(daStrumTime + 3)),
						endStep:Float = Conductor.getStep(daStrumTime + susLength);
						
					while (susStep < endStep)
					{
						var time:Float = Math.max(Conductor.stepToSeconds(susStep), daStrumTime);
						var length:Float = (Conductor.stepToSeconds(Math.min(susStep + 1, endStep)) - time);
						
						var sustainNote = new QueueNote(time, length, daNoteData, swagNote.noteType, true, playfield);
						sustainNote.gfNote = swagNote.gfNote;
						
						swagNote.tail.push(sustainNote);
						susStep++;
					}
					
					var time:Float = (daStrumTime + susLength);
					
					var sustainNote = new QueueNote(time, Conductor.getCrotchetAtTime(time) / 4, daNoteData, swagNote.noteType, true, playfield);
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.isSustainEnd = true;
					
					swagNote.tail.push(sustainNote);
				}
			}
		}
		
		for (event in events)
		{
			final eventName = event.event;
			
			if (!eventsPushed.contains(eventName))
			{
				var baseScriptFile:String = 'data/events/$eventName';
				if (!FunkinAssets.exists(FunkinScript.getPath(baseScriptFile), TEXT)) baseScriptFile = 'events/$eventName';
				
				final scriptFile = FunkinScript.getPath(baseScriptFile);
				
				if (FunkinAssets.exists(scriptFile, TEXT)) eventScripts.addScript(initFunkinScript(scriptFile, eventName));
				
				firstEventPush(event);
				
				eventsPushed.push(eventName);
			}
			
			event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.push(event);
			eventPushed(event);
		}
		
		eventNotes.sort(function(a:EventNote, b:EventNote) return (a.strumTime > b.strumTime ? 1 : -1));
		queueNotes.sort(function(a:QueueNote, b:QueueNote) return (a.strumTime > b.strumTime ? 1 : -1));
		
		speedChanges.sort(SortUtil.svSort);
		
		#if debug
		trace('loading chart took: ' + (Sys.time() - cpuTime));
		#end
		
		checkEventNote();
		generatedMusic = true;
	}
	
	public function getNoteInitialTime(time:Float):Float
	{
		return getTimeFromSV(time, getSV(time));
	}
	
	public inline function getTimeFromSV(time:Float, event:SpeedEvent):Float return event.position
		+ (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);
		
	public function getSV(time:Float):SpeedEvent
	{
		var event:SpeedEvent = {};
		
		for (shit in speedChanges)
		{
			if (shit.startTime <= time && shit.startTime >= event.startTime)
			{
				if (shit.startSpeed == null) shit.startSpeed = event.speed;
				event = shit;
			}
		}
		
		return event;
	}
	
	public inline function getVisualPosition() return getTimeFromSV(Conductor.songPosition, currentSV);
	
	function eventPushed(event:EventNote):Void
	{
		switch (event.event)
		{
			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if (event.event == 'Constant SV')
				{
					var b = Std.parseFloat(event.value1);
					speed = Math.isNaN(b) ? songSpeed : (songSpeed / b);
				}
				else
				{
					speed = Std.parseFloat(event.value1);
					if (Math.isNaN(speed)) speed = 1;
				}
				
				speedChanges.sort(SortUtil.svSort);
				speedChanges.push(
					{
						position: getNoteInitialTime(event.strumTime),
						songTime: event.strumTime,
						startTime: event.strumTime,
						speed: speed
					});
				
			case 'Change Noteskin':
				var fieldID:Int = 0;
				switch (event.value2.toLowerCase())
				{
					case 'dad' | 'opponent' | '1':
						fieldID = 1;
					default:
						fieldID = Std.parseInt(event.value1);
						if (Math.isNaN(fieldID)) fieldID = 0;
				}
				
				var skin = new NoteSkin(event.value1, SONG.keys, fieldID);
				
				// load the skin so game no lag when change le skin
				Paths.getAtlasFrames(skin.noteTexture);
				Paths.getAtlasFrames(skin.splashTexture);
				Paths.getAtlasFrames(skin.sustainSplashTexture);
				
				skin = FlxDestroyUtil.destroy(skin);
				
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}
				
				addCharacterToList(event.value2, charType);
			default:
				callEventScript(event.event, 'onPush', [event]);
		}
		scripts.call('onEventPush', [event]);
	}
	
	function firstEventPush(event:EventNote):Void
	{
		switch (event.event)
		{
			default:
				callEventScript(event.event, 'onFirstPush', [event]);
		}
		scripts.call('onFirstEventPush', [event]);
	}
	
	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnValue:Dynamic = scripts.call('eventEarlyTrigger', [event.event, event.value1, event.value2]);
		if (returnValue != ScriptConstants.CONTINUE_FUNC) return returnValue;
		
		returnValue = callEventScript(event.event, 'offsetStrumTime', [event]);
		if (returnValue != ScriptConstants.CONTINUE_FUNC) return returnValue;
		
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		
		return 0;
	}
	
	public var skipArrowStartTween:Bool = false;
	
	var splashLayering:Array<Dynamic> = [];
	
	override function openSubState(SubState:FlxSubState):Void
	{
		if (paused)
		{
			audio?.pause();
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = false);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = false);
			
			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.pause());
			#end
			
			FlxG.timeScale = 1;
			
			for (field in playFields?.members)
			{
				if (!field.inControl || !field.playerControls) continue;
				
				for (strum in field.members)
				{
					strum.playAnim('static');
					strum.resetAnim = 0;
				}
			}
		}
		scripts.call('onSubstateOpen', []);
		super.openSubState(SubState);
	}
	
	override function closeSubState():Void
	{
		if (paused)
		{
			if (!startingSong)
			{
				audio.time = Conductor.songPosition;
				audio.play();
			}
			
			FlxTimer.globalManager.forEach((i:FlxTimer) -> if (!i.finished) i.active = true);
			FlxTween.globalManager.forEach((i:FlxTween) -> if (!i.finished) i.active = true);
			
			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.resume());
			#end
			
			paused = false;
			playbackRate = playbackRate;
			scripts.call('onResume', []);
			
			resetDiscordRPC(startTimer != null && startTimer.finished);
		}
		scripts.call('onSubstateClose', []);
		super.closeSubState();
	}
	
	override public function onFocus():Void
	{
		if (health > 0 && !paused)
		{
			resetDiscordRPC(Conductor.songPosition > 0.0);
		}
		
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (health > 0 && !paused) resetDiscordRPC(false);
		
		super.onFocusLost();
	}
	
	/**
	 * Sets the Discord RPC to display the default in song descriptions.
	 * @param showTime if showTime, the RPC will show the current song progress.
	 */
	inline function resetDiscordRPC(showTime:Bool = false)
	{
		if (!showTime) DiscordClient.changePresence(rpcDescription, rpcSongName, dad.healthIcon);
		else DiscordClient.changePresence(rpcDescription, rpcSongName, dad.healthIcon, true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
	}
	
	function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		audio.pitch = playbackRate;
		audio.resync(audio.inst.time);
		Conductor.songPosition = audio.inst.time;
	}
	
	public var canAccessEditors:Bool = true;
	
	public var paused:Bool = false;
	public var canReset:Bool = true;
	
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	
	override public function update(elapsed:Float):Void
	{
		canPlayAwardSound = true;
		
		if (cameraLerping && !inCutscene)
		{
			final lerpRate = 0.04 * cameraSpeed;
			FlxG.camera.followLerp = lerpRate;
		}
		
		if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();
		
		if (controls.PAUSE && startedCountdown && canPause)
		{
			if (!ScriptConstants.stopping(scripts.call('onPause'))) openPauseMenu();
		}
		
		if (canAccessEditors && !endingSong && !inCutscene)
		{
			if (FlxG.keys.anyJustPressed(debugKeysChart)) openChartEditor();
			
			if (FlxG.keys.anyJustPressed(debugKeysCharacter)) openCharacterEditor();
		}
		
		if (health > healthBounds.max) health = healthBounds.max;
		
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += (elapsed * 1000);
				
				if (Conductor.songPosition >= 0) startSong();
			}
		}
		else
		{
			Conductor.songPosition += (elapsed * 1000);
			
			if (Math.abs(getSongTime() - Conductor.songPosition) > 1000 / 60 / playbackRate) Conductor.songPosition = getSongTime();
			
			Conductor.lastSongPos = Conductor.songPosition;
		}
		
		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();
		
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong) health = 0;
		
		checkEventNote();
		
		if (modifiersRegistered)
		{
			modManager.updateTimeline(curDecStep);
			modManager.update(elapsed);
		}
		
		final spawnOffset:Float = (spawnTime / songSpeed);
		
		while (queueNotes.length > 0 && (queueNotes[0].strumTime - Conductor.songPosition) < spawnOffset)
			recycleNote(queueNotes.shift());
			
		var tempVector = funkin.backend.math.Vector3.get();
		
		final canUpdateModchart:Bool = (modifiersRegistered && playFields != null);
		
		inline function modchart(obj:Dynamic, id:Int, offsets:haxe.ds.Vector<FlxPoint>)
		{
			final pos = modManager.getPos(0, 0, 0, curDecBeat, obj.noteData, id, obj, tempVector);
			final offsets = (offsets != null ? offsets[obj.noteData] : null);
			
			modManager.updateObject(curDecBeat, obj, pos, id);
			
			obj.spriteOffset.set(offsets?.x, offsets?.y);
			
			return pos;
		}
		
		if (canUpdateModchart)
		{
			for (playField in playFields)
			{
				final id = playField.ID, skin = playField._skin;
				
				playField.forEachAlive(function(strum) modchart(strum, id, skin.receptorOffsets));
			}
		}
		
		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled) keyShit();
				else if (boyfriend.holdTimer > Conductor.stepCrotchet * 0.0011 * boyfriend.singDuration
					&& boyfriend.getAnimName().startsWith('sing')
					&& !boyfriend.getAnimName().endsWith('miss')) boyfriend.dance(boyfriend.forceDance);
			}
			
			var i:Int = 0;
			while (i < notes.length)
			{
				var daNote = notes.members[i ++];
				
				if (!daNote.alive) {
					notes.remove(daNote, true);
					i --;
					continue;
				}
				
				final field = daNote.playField;
				
				if (field.inControl && field.autoPlayed)
				{
					if (!daNote.wasGoodHit && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition) field.onNoteHit.dispatch(daNote, field);
				}
				
				// Kill extremely late notes and cause misses
				if (!daNote.tooLate && !daNote.wasGoodHit && daNote.isLate())
				{
					daNote.tooLate = true;
					
					if (!daNote.ignoreNote && !daNote.canMiss && !daNote.tailState.missed && (!daNote.isSustainNote || daNote.strum.coyoteTime <= 0) && !endingSong) field.onNoteMiss.dispatch(daNote,
						field);
				}
				
				if ((daNote.tooLate && Conductor.songPosition >= noteKillOffset + daNote.strumTime + daNote.sustainLength)
					|| (daNote.wasGoodHit && (Conductor.songPosition >= daNote.strumTime + daNote.sustainLength
						|| (daNote.isSustainEnd && daNote.clipRect != null && daNote.clipRect.height <= 0)))) field.disposeNote(daNote);
						
				if (!canUpdateModchart || !daNote.alive || !daNote.exists) {
					i --;
					continue;
				}
				
				// ok modchart stuff
				
				final skin = daNote.skin;
				
				final visPos = ((daNote.visualTime - Conductor.visualPosition) * songSpeed);
				final diff = (daNote.strumTime - Conductor.songPosition);
				
				final pos = modManager.getPos(daNote.strumTime, visPos, diff, curDecBeat, daNote.noteData, daNote.lane, daNote, tempVector);
				
				modManager.updateObject(curDecBeat, daNote, pos, daNote.lane);
				
				daNote.spriteOffset.x = (skin.noteOffsets[daNote.noteData].x + daNote.offsetX);
				daNote.spriteOffset.y = (skin.noteOffsets[daNote.noteData].y + daNote.offsetY);
				
				if (daNote.isSustainNote)
				{
					final futureSongPos = Conductor.getBeat(Conductor.songPosition + daNote.sustainLength);
					
					final visPos = ((daNote.visualTime + daNote.visualLength - Conductor.visualPosition) * songSpeed);
					final diff = (daNote.strumTime + daNote.sustainLength - Conductor.songPosition);
					
					var nextPos = modManager.getPos(daNote.strumTime + daNote.sustainLength, visPos, diff, Conductor.getBeat(futureSongPos), daNote.noteData, daNote.lane, daNote);
					
					final rad = Math.atan2(nextPos.y - pos.y, nextPos.x - pos.x);
					
					final deg = (rad * 180 / Math.PI);
					
					daNote.angle = (deg - 90);
					
					if (daNote.wasGoodHit && daNote.tailState?.splash != null && field.trackSustainSplashes) daNote.tailState.splash.angle = daNote.angle;
					
					daNote.spriteOffset.x += skin.sustainOffsets[daNote.noteData].x;
					daNote.spriteOffset.y += skin.sustainOffsets[daNote.noteData].y;
					if (daNote.isSustainEnd)
					{
						daNote.spriteOffset.x += skin.susEndOffsets[daNote.noteData].x;
						daNote.spriteOffset.y += skin.susEndOffsets[daNote.noteData].y;
					}
					else
					{
						final dist:Float = Math.sqrt(Math.pow(pos.y - nextPos.y, 2) + Math.pow(pos.x - nextPos.x, 2));
						
						daNote.scale.y = daNote.baseScale.y = (dist / (daNote.frameHeight - (daNote.antialiasing ? 1 : 0)));
					}
					
					daNote.clip(daNote.playField.members[daNote.noteData]);
					
					nextPos.put();
				}
			}
		}
		
		if (canUpdateModchart)
		{
			for (playField in playFields)
			{
				final id = playField.ID, skin = playField._skin;
				
				playField.grpSusSplashes.forEachAlive(function(splash) modchart(splash, id, skin.sustainSplashOffsets));
				
				if (playField.trackNoteSplashes) playField.grpNoteSplashes.forEachAlive(function(splash) modchart(splash, id, skin.splashOffsets));
			}
		}
		
		tempVector.put();
		
		scripts.call('onUpdate', [elapsed]);
		
		super.update(elapsed);
		input.update();
		
		if (controls.NOTE_TAUNT_P && !inCutscene && !cpuControlled)
		{
			var focusPlayer:Character = (focusPlayer ?? boyfriend);
			
			if (focusPlayer.canTaunt && focusPlayer.hasAnim('hey'))
			{
				focusPlayer.playAnim('hey');
				focusPlayer.specialAnim = focusPlayer.holding = true;
			}
		}
		
		if (camZooming)
		{
			FlxG.camera.zoom = MathUtil.decayLerp(FlxG.camera.zoom, defaultCamZoom + defaultCamZoomAdd, 6.25 * camZoomingDecay, elapsed);
			camHUD.zoom = MathUtil.decayLerp(camHUD.zoom, defaultHudZoom, 6.25 * camZoomingDecay, elapsed);
		}
		
		doDeathCheck();
		
		for (i in followingCams)
		{
			i.zoom = FlxG.camera.zoom;
			i.scroll.copyFrom(FlxG.camera.scroll);
		}
		
		if (#if debug true || #end chartingMode || ClientPrefs.inDevMode)
		{
			if (!endingSong && !startingSong)
			{
				if (FlxG.keys.justPressed.ONE)
				{
					KillNotes();
					audio.inst.onComplete();
				}
				if (FlxG.keys.justPressed.TWO)
				{
					setSongTime(Conductor.songPosition + 10000);
					clearNotesBefore(Conductor.songPosition);
				}
			}
			if (FlxG.keys.justPressed.SIX)
			{
				cpuControlled = !cpuControlled;
				botplayTxt.visible = !botplayTxt.visible;
			}
		}
		
		scripts.call('onUpdatePost', [elapsed]);
	}
	
	public function recycleNote(queueNote:QueueNote, ?parent:Note, ?prevNote:Note):Note
	{
		var note:Note = notes.recycle(Note, () -> new Note());
		
		note.preRecycle(queueNote, parent, prevNote);
		
		if (parent != null) return note;
		
		if (queueNote.tail != null)
		{
			final note:Note = spawnNote(note);
			
			if (note != null)
			{
				var prevNote:Note = note;
				
				for (tail in queueNote.tail)
				{
					final tail:Note = recycleNote(tail, note, prevNote);
					
					note.tail.push(tail);
					
					prevNote = tail;
				}
				
				for (tail in note.tail)
					spawnNote(tail);
			}
			
			return note;
		}
		else
		{
			return spawnNote(note);
		}
	}
	
	inline function spawnNote(note:Note):Null<Note>
	{
		note.postRecycle();
		
		if (ScriptConstants.stopping(callNoteTypeScript(note.noteType, 'spawnNote', [note]))
			|| ScriptConstants.stopping(scripts.call('onSpawnNote', [note], false, [note.noteType])))
		{
			note.kill();
			
			return null;
		}
		
		final expectedPlayfield:Null<PlayField> = getFieldFromID(note.lane);
		
		if (expectedPlayfield == null)
		{
			note.kill();
			
			return null;
		}
		else if (expectedPlayfield.autoPlayed && note.strumTime <= Conductor.songPosition && !note.ignoreNote /* && !note.blockHit */)
		{
			expectedPlayfield.onNoteHit.dispatch(note, expectedPlayfield);
			note.kill();
			
			return null;
		}
		else if (!expectedPlayfield.autoPlayed && note.isLate() && !note.ignoreNote && !note.canMiss && !endingSong) // dont Even bother
		{
			expectedPlayfield.onNoteMiss.dispatch(note, expectedPlayfield);
			note.kill();
			
			return null;
		}
		else
		{
			expectedPlayfield.addNote(note);
			notes.remove(note, true);
			notes.insert(0, note);
			note.spawned = true;
			
			if (!ScriptConstants.stopping(callNoteTypeScript(note.noteType, 'postSpawnNote', [note]))) scripts.call('onSpawnNotePost', [note], false, [note.noteType]);
			
			return note;
		}
	}
	
	function openPauseMenu():Void
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		
		audio?.pause();
		openSubState(new PauseSubState());
		
		if (automatedDiscord) DiscordClient.changePresence(rpcPausedDescription, rpcSongName);
	}
	
	function openChartEditor():Void
	{
		ChartEditorState.song = SONG;
		FlxG.camera.followLerp = 0;
		
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		FlxG.switchState(ChartEditorState.new);
	}
	
	function openCharacterEditor():Void
	{
		FlxG.camera.followLerp = 0;
		
		persistentUpdate = false;
		paused = true;
		CoolUtil.cancelMusicFadeTween();
		
		disableModifiers();
		FlxG.switchState(() -> new CharacterEditorState(SONG.player2, true));
		
		DiscordClient.changePresence("Character Editor", null, null, true);
	}
	
	public function updateScoreBar(miss:Bool = false):Void
	{
		if (!ScriptConstants.stopping(scripts.call('onUpdateScore', [miss])))
		{
			callHUDFunc(hud -> hud.onUpdateScore(songScore, funkin.utils.MathUtil.floorDecimal(ratingPercent * 100, 2), songMisses, miss));
			
			ScriptConstants.stopping(scripts.call('onUpdateScorePost', [miss]));
		}
	}
	
	public var isDead:Bool = false;
	
	function doDeathCheck(instakill:Bool = false):Bool
	{
		final healthDeath:Bool = ((healthBounds.max > healthBounds.min && health <= healthBounds.min) || (healthBounds.min > healthBounds.max && health >= healthBounds.min));
		
		if ((instakill || healthDeath) && !practiceMode && !isDead)
		{
			if (!ScriptConstants.stopping(scripts.call('onGameOver')))
			{
				final char = playerStrums.owner;
				
				char.stunned = true;
				deathCounter++;
				
				paused = true;
				
				audio.stop();
				
				persistentUpdate = false;
				persistentDraw = false;
				
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				
				openSubState(new GameOverSubstate(char));
				
				// Game Over doesn't get his own variable because it's only used here
				if (automatedDiscord) DiscordClient.changePresence("Game Over - " + rpcDescription, rpcSongName);
				
				isDead = true;
				totalBeat = 0;
				return true;
			}
		}
		return false;
	}
	
	public function checkEventNote():Void
	{
		while (eventNotes.length > 0)
		{
			final leStrumTime:Float = eventNotes[0].strumTime;
			
			if (Conductor.songPosition < leStrumTime) break;
			
			final value1:String = eventNotes[0].value1 ?? '';
			final value2:String = eventNotes[0].value2 ?? '';
			
			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}
	
	function changeCharacter(name:String, charType:Int):Void
	{
		var prevChar:Null<Character> = null;
		
		var newChar:Character = switch (charType)
		{
			case 0:
				prevChar = boyfriend;
				boyfriend = boyfriendGroup.change(name);
				
			case 1:
				prevChar = dad;
				dad = dadGroup.change(name);
				
			case 2:
				prevChar = gf;
				(gf = gfGroup.change(name)).danceSpeed = prevChar.danceSpeed;
				gf;
			
			default:
				null;
		}
		
		for (field in playFields)
		{
			if (field.owner == prevChar) field.owner = newChar;
		}
		
		callHUDFunc(hud -> hud.onCharacterChange());
	}
	
	public function triggerEventNote(eventName:String, value1:String, value2:String):Void
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}
				
				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;
				
				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnimForDuration('cheer', time);
						dad.specialAnim = true;
					}
					else if (gf != null)
					{
						gf.playAnimForDuration('cheer', time);
						gf.specialAnim = true;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnimForDuration('hey', time);
					boyfriend.specialAnim = true;
				}
				
			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1) value = 1;
				if (gf != null) gf.danceSpeed = value;
			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;
					
					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}
				
			case 'Camera Zoom':
				FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
				
				var val1:Float = Std.parseFloat(value1);
				if (Math.isNaN(val1)) val1 = 1;
				
				var targetZoom = defaultCamZoom * val1;
				if (value2 != '')
				{
					var split = value2.split(',');
					var duration:Float = 0;
					var leEase:String = 'linear';
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) leEase = split[1].trim();
					if (Math.isNaN(duration)) duration = 0;
					
					if (duration > 0) FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: FlxEase.circOut});
					else FlxG.camera.zoom = targetZoom;
				}
				defaultCamZoom = targetZoom;
				
			case 'HUD Fade':
				FlxTween.cancelTweensOf(camHUD, ['alpha']);
				
				var leAlpha:Float = Std.parseFloat(value1);
				if (Math.isNaN(leAlpha)) leAlpha = 1;
				
				var duration:Float = Std.parseFloat(value2);
				if (Math.isNaN(duration)) duration = 1;
				
				if (duration > 0) FlxTween.tween(camHUD, {alpha: leAlpha}, duration);
				else camHUD.alpha = leAlpha;
			case 'Play Animation':
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) val2 = 0;
						
						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
				
			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;
				
				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}
				
			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;
						
						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
				
			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;
					
					if (duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration);
				}
				
			case 'Change Noteskin':
				var fieldID:Int = 0;
				switch (value2.toLowerCase())
				{
					case 'dad' | 'opponent' | '1':
						fieldID = 1;
					default:
						fieldID = Std.parseInt(value2);
						if (Math.isNaN(fieldID)) fieldID = 0;
				}
				
				var skin = new NoteSkin(value1, SONG.keys, fieldID);
				skin.ID = fieldID;
				
				getFieldFromID(fieldID).changeSkin(skin);
				
			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}
				
				var curChar:Character = boyfriend;
				switch (charType)
				{
					case 2:
						curChar = gf;
					case 1:
						curChar = dad;
					case 0:
						curChar = boyfriend;
				}
				
				var newCharacter:String = value2;
				var anim:String = '';
				var frame:Int = 0;
				if (newCharacter.startsWith(curChar.curCharacter) || curChar.curCharacter.startsWith(newCharacter))
				{
					if (!curChar.isAnimNull())
					{
						anim = curChar.getAnimName();
						frame = curChar.animCurFrame;
					}
				}
				
				changeCharacter(value2, charType);
				if (anim != '')
				{
					var char:Character = boyfriend;
					switch (charType)
					{
						case 2:
							char = gf;
						case 1:
							char = dad;
						case 0:
							char = boyfriend;
					}
					
					if (!char.isAnimNull())
					{
						char.playAnim(anim, true);
						char.animCurFrame = frame;
					}
				}
			case 'Change Scroll Speed':
				if (songSpeedType == "constant") return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;
				
				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
				
				if (val2 <= 0) songSpeed = newValue;
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2,
						{
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween) {
								songSpeedTween = null;
							}
						});
				}
				
			case 'Camera Zoom Chain':
				var split1:Array<String> = value1.split(',');
				var gameZoom:Float = Std.parseFloat(split1[0].trim());
				var hudZoom:Float = Std.parseFloat(split1[1].trim());
				
				if (!Math.isNaN(gameZoom)) gameZ = 0.015;
				if (!Math.isNaN(hudZoom)) hudZ = 0.03;
				
				if (split1.length == 4)
				{
					var shGame:Float = Std.parseFloat(split1[2].trim());
					var shHUD:Float = Std.parseFloat(split1[3].trim());
					
					if (!Math.isNaN(shGame)) gameShake = shGame;
					if (!Math.isNaN(shHUD)) hudShake = shHUD;
					shakeTime = true;
				}
				else shakeTime = false;
				
				var split2:Array<String> = value2.split(',');
				var toBeat:Int = Std.parseInt(split2[0].trim());
				var tiBeat:Float = Std.parseFloat(split2[1].trim());
				
				if (Math.isNaN(toBeat)) toBeat = 4;
				if (Math.isNaN(tiBeat)) tiBeat = 1;
				
				totalBeat = toBeat;
				timeBeat = tiBeat;
				
			case 'Screen Shake Chain':
				var split1:Array<String> = value1.split(',');
				var gmShake:Float = Std.parseFloat(split1[0].trim());
				var hdShake:Float = Std.parseFloat(split1[1].trim());
				
				if (!Math.isNaN(gmShake)) gameShake = gmShake;
				if (!Math.isNaN(hdShake)) hudShake = hdShake;
				
				var toBeat:Int = Std.parseInt(value2);
				if (!Math.isNaN(toBeat)) totalShake = 4;
				
				totalShake = toBeat;
				
			case 'Set Cam Zoom':
				defaultCamZoom = Std.parseFloat(value1);
				
			case 'Set Cam Pos':
				var split:Array<String> = value1.split(',');
				var xPos:Float = Std.parseFloat(split[0].trim());
				var yPos:Float = Std.parseFloat(split[1].trim());
				if (Math.isNaN(xPos)) xPos = 0;
				if (Math.isNaN(yPos)) yPos = 0;
				switch (value2)
				{
					case 'bf' | 'boyfriend':
						boyfriendCameraOffset[0] = xPos;
						boyfriendCameraOffset[1] = yPos;
					case 'gf' | 'girlfriend':
						girlfriendCameraOffset[0] = xPos;
						girlfriendCameraOffset[1] = yPos;
					case 'dad' | 'opponent':
						opponentCameraOffset[0] = xPos;
						opponentCameraOffset[1] = yPos;
				}
				
			case 'Set Property':
				try
				{
					var props:Array<String> = value1.split('.');
					if (props.length > 1) Reflect.setProperty(ReflectUtil.getPropertyLoop(props, true), props[props.length - 1], value2);
					else Reflect.setProperty(this, value1, value2);
				}
				catch (e)
				{
					Logger.log('Event [Set Property] failed Exception: ${e.toString()}', ERROR);
				}
		}
		
		scripts.call('onEvent', [eventName, value1, value2]);
		
		callEventScript(eventName, 'onTrigger', [value1, value2]);
	}
	
	function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null) return;
		
		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			
			if (ClientPrefs.camFollowsCharacters)
			{
				final displacement = gf.getSingDisplacement();
				
				camFollow.x += displacement.x;
				camFollow.y += displacement.y;
				
				displacement.putWeak();
			}
			
			scripts.call('onMoveCamera', ['gf']);
			scripts.set('whosTurn', 'gf');
			return;
		}
		
		var isDad = !SONG.notes[curSection].mustHitSection;
		moveCamera(isDad);
		scripts.call('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}
	
	public function getCharacterCameraPos(char:Null<Character>):FlxPoint
	{
		if (char == null) return FlxPoint.weak();
		
		final desiredPos = char.getMidpoint();
		
		final offsets = char.isPlayer ? boyfriendCameraOffset : opponentCameraOffset;
		
		desiredPos.y += -100 + char.cameraPosition[1] + offsets[1];
		
		if (char.isPlayer)
		{
			desiredPos.x -= 100 + char.cameraPosition[0];
		}
		else
		{
			desiredPos.x += 100 + char.cameraPosition[0];
		}
		
		desiredPos.x += offsets[0];
		
		return desiredPos;
	}
	
	public function moveCamera(isDad:Bool):Void
	{
		var desiredPos:Null<FlxPoint> = null;
		var curCharacter:Null<Character> = null;
		
		if (opponentStrums != null && playerStrums != null) curCharacter = isDad ? opponentStrums.owner : playerStrums.owner;
		else curCharacter = isDad ? dad : boyfriend;
		
		if (camCurTarget != null) curCharacter = camCurTarget;
		
		desiredPos = getCharacterCameraPos(curCharacter);
		
		camFollow.x = desiredPos.x;
		camFollow.y = desiredPos.y;
		
		if (ClientPrefs.camFollowsCharacters)
		{
			final displacement = curCharacter.getSingDisplacement();
			
			camFollow.x += displacement.x;
			camFollow.y += displacement.y;
			
			displacement.putWeak();
		}
		
		desiredPos.put();
		
		scripts.set('whosTurn', isDad ? 'dad' : 'boyfriend');
	}
	
	/**
	 * 'Snaps the camera to a position.'
	 * @param lockPosition 'if true, locks the camera position after snapping.'
	 */
	function snapCamToPos(x:Float = 0, y:Float = 0, lockPosition:Bool = false):Void
	{
		camFollow.setPosition(x, y);
		FlxG.camera.snapToTarget();
		if (lockPosition) isCameraOnForcedPos = true;
	}
	
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		
		audio.volume = 0;
		audio.stop();
		audio.stopInst();
		
		if (songEndCallback == null)
		{
			FlxG.log.error('songEndCallback is null! using default callback.');
			songEndCallback = endSong;
		}
		
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			songEndCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				songEndCallback();
			});
		}
	}
	
	public var transitioning = false;
	
	public var popUpQueued:Int = 0;
	public var canPlayAwardSound:Bool = true;
	public var popUpEndCallback:Void->Void = null;
	
	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEachAlive(function(daNote:Note) {
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= 0.05 * healthLoss;
			});
			
			for (daNote in queueNotes)
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= 0.05 * healthLoss;
				
			if (doDeathCheck()) return;
		}
		
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		
		deathCounter = 0;
		seenCutscene = false;
		
		disableModifiers();
		
		if (!ScriptConstants.stopping(scripts.call('onEndSong')) && !transitioning)
		{
			playbackRate = 1;
			
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyMeta.difficulty, percent, songMisses);
			unlockJsonAwards(curSong);
			
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
			
			if (isStoryMode || isChallenge)
			{
				storyMeta.score += songScore;
				storyMeta.misses += songMisses;
				
				storyMeta.playlist.remove(storyMeta.playlist[0]);
				
				if (storyMeta.playlist.length <= 0)
				{
					if (WeekData.weeksList[storyMeta.curWeek] != null)
					{
						unlockJsonAwards(curSong, [WeekData.weeksList[storyMeta.curWeek]]);
					}
					
					var popup:BeansPopup = new BeansPopup(Std.int(storyMeta.score / 600), storyMeta.currency);
					popup.camera = camOther;
					add(popup);
					
					popUpQueued++;
					popup.onFinish = dequeuePopup;
					
					popUpEndCallback = function() {
						removeModifiers();
						
						if (WeekData.weeksList[storyMeta.curWeek] != null)
						{
							if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
							{
								StoryMenuState.weekCompleted.set(WeekData.weeksList[storyMeta.curWeek], true);
								
								FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
								
								Highscore.saveWeekScore(WeekData.getWeekFileName(), storyMeta.score, storyMeta.difficulty);
							}
						}
						
						changedDifficulty = false;
						
						if (!ScriptConstants.stopping(scripts.call('postEndSong')))
						{
							FlxG.sound.playMusic(Paths.music('freakyMenu'));
							CoolUtil.cancelMusicFadeTween();
							
							FlxG.switchState(StoryMenuState.new);
						}
					}
				}
				else
				{
					prevCamFollow = camFollow;
					
					final difficulty:String = Difficulty.getDifficultyFilePath();
					final songLowercase = Paths.sanitize(storyMeta.playlist[0].toLowerCase());
					
					trace('LOADING: ' + Paths.sanitize(storyMeta.playlist[0]) + difficulty);
					
					PlayState.SONG = Chart.fromSong(songLowercase, PlayState.storyMeta.difficulty);
					
					popUpEndCallback = function() {
						if (!ScriptConstants.stopping(scripts.call('postEndSong')))
						{
							CoolUtil.cancelMusicFadeTween();
							FlxG.sound.music.stop();
							
							FlxG.switchState(PlayState.new);
						}
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				
				var popup:BeansPopup = new BeansPopup(Std.int(songScore / 600), funkin.data.CosmicubeData.currentCurrency);
				popup.camera = camOther;
				add(popup);
				
				popUpQueued++;
				popup.onFinish = dequeuePopup;
				
				popUpEndCallback = function() {
					CoolUtil.cancelMusicFadeTween();
					removeModifiers();
					
					if (!ScriptConstants.stopping(scripts.call('postEndSong')))
					{
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						changedDifficulty = false;
						
						FlxG.switchState(FreeplayState.new);
					}
				}
			}
			transitioning = true;
			
			if (popUpQueued == 0 && popUpEndCallback != null) popUpEndCallback();
		}
		
		audio.stop();
		audio.stopInst();
	}
	
	function dequeuePopup():Void
	{
		popUpQueued--;
		
		if (#if debug true || #end ClientPrefs.inDevMode) trace('$popUpQueued left');
		
		if (popUpQueued == 0 && popUpEndCallback != null) popUpEndCallback();
	}
	
	public function unlockAchievementPopup(id:String):Bool
	{
		if (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false)) return false;
		if (!GameFlags.giveAchievement(id)) return false;
		
		popUpAchievement(id);
		
		return true;
	}
	
	public function unlockJsonAwards(?currentSong:String = null, ?extraCompletedWeeks:Array<String> = null):Int
	{
		if (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false)) return 0;
		
		var unlockedCount:Int = 0;
		for (id in GameFlags.unlockAwardsFromJson(currentSong, extraCompletedWeeks))
		{
			popUpAchievement(id);
			unlockedCount++;
		}
		
		if (ProgressionUtil.checkSRanksAchievement())
		{
			unlockAchievementPopup('five_s_ranks');
			unlockedCount++;
		}
		if (ProgressionUtil.checkPAchievement())
		{
			unlockAchievementPopup('first_p');
			unlockedCount++;
		}
		if (ProgressionUtil.checkHundredAchievement())
		{
			unlockAchievementPopup('the_hundred');
			unlockedCount++;
		}
		
		return unlockedCount;
	}
	
	public inline function popUpAchievement(id:String):AwardPopup
	{
		var popUp:AwardPopup = new AwardPopup(id, canPlayAwardSound);
		popUp.camera = camOther;
		add(popUp);
		
		canPlayAwardSound = false;
		
		popUpQueued++;
		popUp.onFinish = dequeuePopup;
		
		return popUp;
	}
	
	public function KillNotes():Void
	{
		while (notes.length > 0)
			disposeNote(notes.members[0]);
			
		queueNotes.resize(0);
		eventNotes.resize(0);
	}
	
	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	
	public var showCombo:Bool = true;
	public var showRating:Bool = true;
	
	function popUpScore(note:Note = null):Void
	{
		if (note.hitCausesMiss || note.canMiss) return;
		
		audio.playerVolume = 1 * volumeMult;
		
		final rating:Rating = note.ratingData;
		
		var field:PlayField = note.playField;
		
		if (!practiceMode && !cpuControlled && !(field?.autoPlayed ?? false))
		{
			if (defaultScoreAddition) songScore += rating.score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				totalNotesHit += (note.ratingMod = rating.ratingMod);
				rating.increase();
				
				RecalculateRating(false);
			}
		}
		
		scripts.call('onPopUpScore', [note, rating]);
		callHUDFunc(hud -> hud.popUpScore(rating.image, combo)); // only pushing the image bc is anyone ever gonna need anything else???
		scripts.call('onPopUpScorePost', [note, rating]);
	}
	
	public inline function getSongTime():Float
	{
		if (audio.inst?.playing)
		{
			return Math.max(@:privateAccess audio.inst._channel.position, audio.inst.time);
		}
		else
		{
			return Conductor.songPosition;
		}
	}
	
	function onInputPress(event:InputEvent):Void
	{
		if (cpuControlled || paused || !startedCountdown) return;
		
		final key:Int = event.noteData;
		
		var prevTime:Float = getSongTime();
		Conductor.songPosition -= (lime.system.System.getTimer() - event.timer);
		
		if (generatedMusic && !endingSong)
		{
			var anyInput:Bool = false;
			var ghostTapped:Bool = true;
			
			for (field in playFields.members)
			{
				if (!field.canInput()) continue;
				
				anyInput = true;
				
				var topNote:Note = null; // we only need the top most note !
				
				for (note in field.getNotes(key))
				{
					if (note.isSustainNote)
					{
						ghostTapped = false;
						
						continue;
					}
					
					final higherPriority:Bool = (topNote == null || note.hitPriority > topNote.hitPriority);
					if (higherPriority || (!higherPriority && note.strumTime < topNote.strumTime)) topNote = note;
				}
				
				if (topNote != null)
				{
					field.onNoteHit.dispatch(topNote, field);
					
					ghostTapped = false;
				}
				else if (field.playAnims)
				{
					var strum = field.members[key];
					
					if (strum != null)
					{
						strum.playAnim('pressed');
						strum.resetAnim = 0;
					}
				}
			}
			
			if (ghostTapped && anyInput)
			{
				scripts.call('onGhostTap', [key]);
				
				if (!ClientPrefs.ghostTapping)
				{
					for (field in playFields.members)
					{
						if (field.canInput()) field.onMissPress.dispatch(key, field);
					}
					
					if (!ScriptConstants.stopping(scripts.call('noteMissPress', [key])))
					{
						health -= (healthLoss * pressMissDamage * (++missCombo + 1) / 2);
						
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));
					}
				}
			}
		}
		
		Conductor.songPosition = prevTime;
		
		scripts.call('onKeyPress', [key]);
		scripts.call('onInputPress', [key]);
	}
	
	function onInputRelease(event:InputEvent):Void
	{
		final key:Int = event.noteData;
		
		if (!startedCountdown || paused) return;
		
		for (field in playFields.members)
		{
			if (field.inControl && !field.autoPlayed && field.playerControls)
			{
				var spr:StrumNote = field.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
				
				for (splash in field.grpSusSplashes)
				{
					if (splash.alive && splash.noteData == key && !splash.completed) splash.kill();
				}
			}
		}
		scripts.call('onKeyRelease', [key]);
		scripts.call('onInputRelease', [key]);
	}
	
	// Hold notes
	var holders:Array<Character> = [];
	
	function keyShit():Void
	{
		if (!startedCountdown || !generatedMusic || boyfriend.stunned) return;
		
		// HOLDING
		final up:Bool = controls.NOTE_UP;
		final right:Bool = controls.NOTE_RIGHT;
		final down:Bool = controls.NOTE_DOWN;
		final left:Bool = controls.NOTE_LEFT;
		final taunting:Bool = (controls.NOTE_TAUNT && (focusPlayer ?? boyfriend)?.canTaunt);
		
		var i:Int = notes.length;
		while (--i >= 0)
		{
			var daNote = notes.members[i];
			
			if (!daNote.alive) continue;
			
			if (daNote.isSustainNote && !daNote.blockHit && !daNote.tooLate && !daNote.playField.autoPlayed
				&& daNote.playField.inControl && daNote.playField.playerControls)
			{
				final holding:Bool = input.inputPressed(daNote.noteData);
				
				if (daNote.wasGoodHit)
				{
					final splash = daNote.tailState.splash;
					
					if (holding && splash != null && !splash.alive)
					{
						splash.playAnim('start${splash.noteData}');
						splash.revive();
					}
				}
				else if (holding && Conductor.songPosition >= daNote.strumTime)
				{
					daNote.playField.onNoteHit.dispatch(daNote, daNote.playField);
				}
				else if (!holding && !daNote.ignoreNote && !endingSong && daNote.strum.coyoteTime <= 0 && !daNote.tailState.missed)
				{
					daNote.playField.onNoteMiss.dispatch(daNote, daNote.playField);
				}
			}
		}
		
		if (!left && !down && !up && !right && !taunting)
		{
			for (field in playFields)
			{
				if (field.playerControls && field.owner?.holding) field.owner.holding = false;
			}
			
			if (holders.length > 0)
			{
				for (holder in holders)
					holder.holding = false;
					
				holders.resize(0);
			}
		}
	}
	
	inline function breakCombo():Void
	{
		if (combo > 5 && gf?.animOffsets.exists('sad'))
		{
			gf.playAnim('sad');
			gf.specialAnim = true;
		}
		
		combo = 0;
	}
	
	public function characterSing(char:Character, note:Note, hold:Bool = false):Void // this is really dirty but i dont care aauaaaaauauauugaauauau
	{
		PlayField.characterSing(char, note, hold);
	}
	
	@:inheritDoc
	override function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= stage;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function destroy()
	{
		instance = null;
		
		playbackRate = 1;
		
		scripts.call('onDestroy', [], true);
		
		scripts = FlxDestroyUtil.destroy(scripts);
		eventScripts = FlxDestroyUtil.destroy(eventScripts);
		noteTypeScripts = FlxDestroyUtil.destroy(noteTypeScripts);
		
		input = FlxDestroyUtil.destroy(input);
		
		modManager = FlxDestroyUtil.destroy(modManager);
		
		FlxDestroyUtil.destroyArray(NoteUtil.noteskins);
		NoteUtil.noteskins.resize(0);
		
		Conductor.bpmChangeMap.resize(0);
		
		super.destroy();
	}
	
	override function stepHit()
	{
		super.stepHit();
		
		final maxToleratedOffset:Float = (1000 / 60 * playbackRate);
		
		if (audio.inst?.playing)
		{
			if (Math.abs(audio.inst.time - (Conductor.songPosition - Conductor.offset)) > maxToleratedOffset
				|| (SONG.needsVoices && audio.getDesyncDifference(Math.abs(Conductor.songPosition - Conductor.offset)) > maxToleratedOffset)) resyncVocals();
		}
		
		if (lastStepHit >= curStep) return;
		
		lastStepHit = curStep;
		
		scripts.call('onStepHit');
		
		callHUDFunc(hud -> hud.stepHit());
	}
	
	var lastStepHit:Int = -1;
	var lastBeatHit:Int = -1;
	var lastSection:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();
		
		if (lastBeatHit >= curBeat) return;
		
		handleBoppers(curBeat);
		
		if (camZooming && ClientPrefs.camZooms && (curBeat == 0 || (beatsPerZoom > 0 && curBeat % beatsPerZoom == 0))) camZoom();
		
		lastBeatHit = curBeat;
		
		if (totalBeat > 0)
		{
			if (curBeat % timeBeat == 0)
			{
				triggerEventNote('Add Camera Zoom', '' + gameZ, '' + hudZ);
				totalBeat -= 1;
				
				if (shakeTime) triggerEventNote('Screen Shake', (((1 / (Conductor.bpm / 60)) / 2) * timeBeat)
					+ ', '
					+ gameShake, (((1 / (Conductor.bpm / 60)) / 2) * timeBeat)
					+ ', '
					+ hudShake);
			}
		}
		
		scripts.call('onBeatHit');
		callHUDFunc(hud -> hud.beatHit());
	}
	
	// rework this
	public function handleBoppers(beat:Int)
	{
		gf?.onBeatHit(beat);
		boyfriend?.onBeatHit(beat);
		dad?.onBeatHit(beat);
		pet?.onBeatHit(beat);
	}
	
	override function sectionHit():Void
	{
		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				scripts.set('bpm', Conductor.bpm);
			}
			scripts.set('mustHitSection', SONG.notes[curSection].mustHitSection);
			scripts.set('altAnim', SONG.notes[curSection].altAnim);
			scripts.set('gfSection', SONG.notes[curSection].gfSection);
		}
		
		if (camZooming && ClientPrefs.camZooms && beatsPerZoom <= 0) camZoom();
		
		super.sectionHit();
		
		scripts.call('onSectionHit');
		callHUDFunc(hud -> hud.sectionHit());
	}
	
	inline function camZoom():Void
	{
		FlxG.camera.zoom += 0.015 * camZoomingMult;
		camHUD.zoom += 0.03 * camZoomingMult;
	}
	
	/**
	 * Attempts to call a function on a event script by event name
	 */
	public function callEventScript(scriptName:String, func:String, args:Array<Dynamic>):Dynamic
	{
		if (!eventScripts.exists(scriptName)) return ScriptConstants.CONTINUE_FUNC;
		
		final script = eventScripts.getScript(scriptName);
		
		return callScript(script, func, args);
	}
	
	/**
	 * Attempts to call a function on a note script by note type
	 */
	public function callNoteTypeScript(noteType:String, func:String, args:Array<Dynamic>):Dynamic
	{
		if (!noteTypeScripts.exists(noteType)) return ScriptConstants.CONTINUE_FUNC;
		
		final script = noteTypeScripts.getScript(noteType);
		
		return callScript(script, func, args);
	}
	
	/**
	 * calls a function directly on a script if it exists
	 */
	public function callScript(script:FunkinScript, event:String, args:Array<Dynamic>):Dynamic
	{
		if (!script.exists(event)) return ScriptConstants.CONTINUE_FUNC;
		
		var ret:Dynamic = script.call(event, args)?.returnValue;
		
		return ret ?? ScriptConstants.CONTINUE_FUNC;
	}
	
	public var ratingPercent:Float = 0.0;
	public var ratingFC:String = '';
	
	public function RecalculateRating(badHit:Bool = false)
	{
		if (!ScriptConstants.stopping(scripts.call('onRecalculateRating')))
		{
			if (totalPlayed > 0) ratingPercent = (totalNotesHit / totalPlayed);
			
			ratingFC = getRatingFC();
		}
		
		updateScoreBar(badHit);
	}
	
	public dynamic function getRatingFC():String
	{
		if (songMisses >= 10) return 'Clear';
		if (songMisses > 0) return 'SDCB';
		if (bads + shits > 0) return 'FC';
		if (goods > 0) return 'GFC';
		if (sicks > 0) return 'SFC';
		if (epics > 0) return 'KFC';
		return '';
	}
	
	override public function startOutro(onOutroComplete:() -> Void)
	{
		if (stage != null && isPixelStage != stage.stageData.isPixelStage) isPixelStage = stage.stageData.isPixelStage;
		super.startOutro(onOutroComplete);
	}
	
	public function updateModifiers()
	{
		for (mod in marathonModifiers)
		{
			trace(mod);
			mod.onActive();
		}
	}
	
	public function disableModifiers()
	{
		for (mod in marathonModifiers)
		{
			mod.onRemove();
		}
	}
	
	public function removeModifiers()
	{
		for (mod in marathonModifiers)
		{
			mod.onRemove();
		}
		
		marathonModifiers.resize(0);
	}
}
