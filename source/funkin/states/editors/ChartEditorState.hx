package funkin.states.editors;

import funkin.data.Chart;

import haxe.Json;
import haxe.io.Bytes;
import haxe.ds.IntMap;

import lime.media.AudioBuffer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
import openfl.geom.Rectangle;

import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSort;
import flixel.util.FlxGradient;
import flixel.group.FlxGroup;

import funkin.backend.Conductor;
import funkin.backend.Difficulty;
import funkin.data.CharacterData;
import funkin.data.StageData;
import funkin.data.Song;
import funkin.scripts.*;
import funkin.objects.*;
import funkin.objects.note.*;
import funkin.states.*;
import funkin.states.editors.ui.*;
import funkin.states.editors.ui.ChartEditorKit;
import funkin.backend.MusicBeatSubstate;
import funkin.audio.SyncedFlxSoundGroup;

#if sys
import openfl.media.Sound;

import sys.FileSystem;
import sys.io.File;
#end

using funkin.states.editors.ui.ToolKitUtils;

// this was neat //probably will rewrite the uhhh sing4 being idle later
class OurLittleFriend extends FlxSprite
{
	var _colors:Array<FlxColor> = [FlxColor.MAGENTA, FlxColor.CYAN, FlxColor.LIME, FlxColor.RED, FlxColor.WHITE];
	var _dances:Array<String> = ['left', 'down', 'up', 'right', 'idle'];
	
	var _offsetPath:String = '';
	
	public var offsets:IntMap<Array<Float>> = new IntMap();
	
	public function new(char:String)
	{
		super();
		final basePath = 'images/editors/friends/$char';
		if (FunkinAssets.exists(Paths.getCorePath('$basePath.png')))
		{
			frames = Paths.getSparrowAtlas(basePath.substr(basePath.indexOf('/') + 1));
			animation.addByPrefix('idle', 'i', 24);
			animation.addByPrefix('left', 'l', 24, false);
			animation.addByPrefix('down', 'd', 24, false);
			animation.addByPrefix('up', 'u', 24, false);
			animation.addByPrefix('right', 'r', 24, false);
			
			setGraphicSize(100);
			updateHitbox();
			
			buildOffsets(basePath);
			
			sing(4);
		}
	}
	
	function buildOffsets(?path:String)
	{
		path ??= _offsetPath;
		if (FunkinAssets.exists(Paths.getCorePath('$path.txt'))) for (k => i in File.getContent(Paths.getCorePath('$path.txt')).trim().split('\n'))
		{
			var value = i.trim().split(',');
			offsets.set(k, [Std.parseFloat(value[0]), Std.parseFloat(value[1])]);
		}
		
		_offsetPath = path;
	}
	
	public function sing(dir:Int)
	{
		animation.play(_dances[dir], true);
		
		color = _colors[dir];
		
		centerOffsets();
		
		if (offsets.exists(dir))
		{
			offset.x += offsets.get(dir)[0] * scale.x;
			offset.y += offsets.get(dir)[1] * scale.y;
		}
		// else offset.set();
	}
}

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
@:access(funkin.objects.note.Note)
class ChartEditorState extends haxe.ui.backend.flixel.UIState
{
	public static var instance:ChartEditorState;
	
	public var notetypeScripts:Map<String, FunkinScript> = [];
	
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		[
			'',
			'Alt Animation',
			'Hey!',
			'Hurt Note',
			'GF Sing',
			'No Animation',
			'Ghost Note',
			#if debug 'Test Owner Note' #end
		];
		
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	
	public var audio:PlayableSong;
	
	public var ignoreWarnings = false;
	
	public static var camHUD:FlxCamera;
	
	var undos = [];
	var redos = [];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		// my auto formatter is forcing it to be liek this. i will fix it later
		['Change Noteskin', 'Changes the Noteskin of a specific strumline.\n\nValue 1: Name of the Noteskin to change to\nValue 2: ID of the Strumline (0 = Player, 1 = Opponent, etc.)'],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['HUD Fade', "Fades the HUD camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Fade', "Fades the game camera\n\nValue 1: Alpha\nValue 2: Duration"],
		['Camera Flash', "Value 1: Color, Alpha (Optional)\nValue 2: Fade duration"],
		['Camera Zoom', "Changes the Camera Zoom.\n\nValue 1: Zoom Multiplier (1 is default)\n\nIn case you want a tween, use Value 2 like this:\n\n\"3, elasticOut\"\n(Duration, Ease Type)"],
		['Camera Zoom Chain', "Value 1: Camera Zoom Values (0.015, 0.03)\n(also you can add another two values to make it\nzoom screen shake(0.015, 0.03, 0.01, 0.01))\n\nValue 2: Total Amount of Beat Cam Zooms and\nthe space with eachother (4, 1)"],
		['Screen Shake Chain', "Value 1: Screen Shake Values (0.003, 0.0015)\n\nValue 2: Total Amount of Screen Shake per beat]"], ['Set Cam Zoom', "Value 1: Zoom"],
		['Set Cam Pos', "Value 1: X\nValue 2: Y"], ["Mult SV", "Changes the notes' scroll velocity via multiplication.\nValue 1: Multiplier"],
		["Constant SV", "Uses scroll velocity to set the speed to a constant number.\nValue 1: Constant"]];
		
	public var variables:Map<String, Dynamic> = new Map();
	
	var _file:FileReference;
	
	public var ui:ChartEditorUI;
	
	public static var goToPlayState:Bool = false;
	
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';
	
	var bpmTxt:FlxText;
	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var highlight:FlxSprite;
	
	public static var GRID_SIZE:Int = 40;
	
	public var CAM_OFFSET:Float = 0;
	
	var dummyArrow:FlxSprite;
	var renderedNotes:FlxTypedGroup<EditorNote>;
	var renderedNoteType:FlxTypedGroup<AttachedFlxText>;
	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;
	var prevGridBG:FlxSprite;
	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	
	var selectionBox:DebugBounds;
	
	public static var song:Song;
	
	var curSelectedNotes:Array<Array<Dynamic>> = [];
	var holdingNotes:Array<Array<Dynamic>> = [null, null, null, null, null, null, null, null];
	var playbackSpeed:Float = 1;
	
	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var cameraIcon:FlxSprite;
	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;
	var zoomTxt:FlxText;
	var zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;
	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;
	
	public static var quantization:Int = 16;
	public static var curQuant = 3;
	
	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
	
	public static var lanes:Int = 2;
	public static var initialKeyCount:Int = 4;
	public static var startTime:Float = 0;
	
	var text:String = "";
	
	public static var textBox:FlxSprite;
	public static var clickForInfo:FlxText;
	public static var bPos:FlxPoint;
	public static var vortex:Bool = false;
	
	var bfHitsound:Bool = false;
	var dadHitsound:Bool = false;
	
	var vortexControlArray:Array<Bool>;
	
	public var mouseQuant:Bool = false;
	
	var bg:FlxSprite;
	var gradient:FlxBackdrop;
	var canAddNotes:Bool = true;
	var littleBF:OurLittleFriend;
	var littleDad:OurLittleFriend;
	var littleStage:FlxSprite;
	var dadIcon:String = 'dad';
	var bfIcon:String = 'bf';
	var gfIcon:String = 'gf';
	var endOffset:Int = 17;
	var songEnded:Bool = false;
	
	override function create()
	{
		super.create();
		
		instance = this;
		
		if (song == null)
		{
			PlayState.SONG = song = (PlayState.SONG ?? {
				song: 'test',
				trackSwap: false,
				notes: [],
				events: [],
				bpm: 100.0,
				needsVoices: true,
				arrowSkins: ['default', 'default'],
				player1: 'bf',
				player2: 'bf',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				keys: 4,
				lanes: 2,
				allowBFskin: true,
				allowGFskin: true,
				allowPet: true
			});
		}
		
		PlayState.chartingMode = true;
		
		Conductor.bpm = song.bpm;
		Conductor.mapBPMChanges(song);
		initialKeyCount = song.keys;
		
		if (song.notes.length == 0) addSection();
		
		ClientPrefs.load();
		
		FlxG.sound.music?.stop();
		
		add(audio = new PlayableSong());
		
		DiscordClient.changePresence("Chart Editor" /* sorry that was boring */);
		
		camHUD = new FlxCamera();
		camHUD.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);
		
		camPos = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(camPos);
		
		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		
		gradient = new FlxBackdrop(Y);
		add(gradient);
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		add(bg);
		createFriends();
		
		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);
		
		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);
		
		bfIcon = CharacterParser.fetchInfo(song.player1).healthicon;
		dadIcon = CharacterParser.fetchInfo(song.player2).healthicon;
		gfIcon = CharacterParser.fetchInfo(song.gfVersion).healthicon;
		
		leftIcon = new HealthIcon(bfIcon);
		rightIcon = new HealthIcon(dadIcon);
		cameraIcon = new FlxSprite().loadGraphic(Paths.image('editors/camera'));
		
		renderedNotes = new FlxTypedGroup<EditorNote>();
		renderedNoteType = new FlxTypedGroup<AttachedFlxText>();
		
		if (curSec >= song.notes.length) curSec = song.notes.length - 1;
		
		addSection();
		
		currentSongName = Paths.sanitize(song.song);
		loadSong();
		reloadGradient();
		reloadGridLayer();
		
		gridZoom(true);
		
		bpmTxt = new FlxText(10, 30, 0, "", 16);
		bpmTxt.scrollFactor.set();
		bpmTxt.camera = camHUD;
		add(bpmTxt);
		
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * ((song.keys * song.lanes) + 1)), 4);
		add(strumLine);
		
		quant = new AttachedSprite('editors/chart_quant', 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		reloadStrumShit();
		add(strumLineNotes);
		
		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);
		
		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
			{name: "Visuals", label: 'Visuals'}
		];
		
		zoomTxt = new FlxText(10, 20 + 380 + 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.camera = camHUD;
		add(zoomTxt);
		bpmTxt.y = zoomTxt.y + 20;
		
		buildUI();
		
		prepareNotesUI();
		prepareEventsUI();
		
		add(renderedNotes);
		add(renderedNoteType);
		
		add(leftIcon);
		add(rightIcon);
		add(cameraIcon);
		
		selectionBox = new DebugBounds();
		selectionBox.negativeSize = true;
		selectionBox.bgAlpha = .5;
		selectionBox.kill();
		add(selectionBox);
		
		if (lastSong != currentSongName) changeSection();
		lastSong = currentSongName;
		
		updateGrid();
		
		FlxG.mouse.visible = true;
	}
	
	override function destroy():Void
	{
		Conductor.bpmChangeMap.resize(0);
		
		super.destroy();
	}
	
	public function buildUI():Void
	{
		root.cameras = [camHUD];
		
		add(ui = new ChartEditorUI(this));
	}
	
	function createFriends()
	{
		// temp
		var isInfry:Bool = FlxG.random.bool(50);
		
		littleBF = new OurLittleFriend(isInfry ? 'dingalingdemon' : 'bf');
		littleBF.setPosition(210, FlxG.height - littleBF.height - 50);
		littleBF.scrollFactor.set();
		littleBF.camera = camHUD;
		
		littleDad = new OurLittleFriend(isInfry ? "opp" : 'fella');
		littleDad.setPosition(10, FlxG.height - littleDad.height - 50);
		littleDad.scrollFactor.set();
		littleDad.camera = camHUD;
		
		littleStage = new FlxSprite().loadGraphic(Paths.image('editors/friends/${isInfry ? "stage" : 'platform'}'));
		littleStage.scrollFactor.set();
		littleStage.scale.set(littleDad.scale.x, littleDad.scale.x);
		littleStage.updateHitbox();
		littleStage.x = littleDad.x;
		littleStage.y = littleDad.y + littleDad.height + (isInfry ? -10 : 0);
		littleStage.camera = camHUD;
		
		add(littleStage);
		add(littleDad);
		add(littleBF);
	}
	
	inline function resetLittleFriends()
	{
		littleBF?.sing(4);
		littleDad?.sing(4);
	}
	
	inline function reloadGradient():Void
	{
		if (ClientPrefs.editorGradVis)
		{
			gradient.revive();
			gradient.loadGraphic(FlxGradient.createGradientBitmapData(1, FlxG.height * 4, [
				ClientPrefs.editorGradColors[0],
				ClientPrefs.editorGradColors[1],
				ClientPrefs.editorGradColors[0],
			]));
			gradient.screenCenter(X);
			gradient.scrollFactor.set();
			
			bg.setColorTransform(-.25, -.25, -.25, 1, 60, 60, 60);
			bg.blend = SUBTRACT;
		}
		else
		{
			gradient.kill();
			
			bg.setColorTransform();
			bg.color = 0xff222222;
			bg.blend = NORMAL;
		}
	}
	
	var box1Colors:Array<Int> = [];
	var box2Colors:Array<Int> = [];
	
	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic> = [];
	
	function copySection():Void
	{
		notesCopied.resize(0);
		sectionToCopy = curSec;
		
		for (i in 0...song.notes[curSec].sectionNotes.length)
		{
			var note:Array<Dynamic> = song.notes[curSec].sectionNotes[i];
			notesCopied.push(note);
		}
		
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (event in song.events)
		{
			var strumTime:Float = event[0];
			if (endThing > event[0] && event[0] >= startThing)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...event[1].length)
				{
					var eventToPush:Array<Dynamic> = event[1][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				notesCopied.push([strumTime, -1, copiedEventArray]);
			}
		}
	}
	
	function pasteSection():Void
	{
		if (notesCopied.length < 1) return;
		
		var addToTime:Float = Conductor.stepCrotchet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
		// ADDTOTIME HAS TO BE REWRITTEN
		
		for (note in notesCopied)
		{
			var copiedNote:Array<Dynamic> = [];
			var newStrumTime:Float = note[0] + addToTime;
			
			if (note[1] < 0 && ui.songDialog.sectionEventsCheckbox.selected)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...note[2].length)
				{
					var eventToPush:Array<Dynamic> = note[2][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				song.events.push([newStrumTime, copiedEventArray]);
			}
			else if (note[1] >= 0 && ui.songDialog.sectionNotesCheckbox.selected)
			{
				if (note[4] != null)
				{
					copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
				}
				else
				{
					copiedNote = [newStrumTime, note[1], note[2], note[3]];
				}
				song.notes[curSec].sectionNotes.push(copiedNote);
			}
		}
		updateGrid();
	}
	
	function clearSection():Void
	{
		if (ui.songDialog.sectionNotesCheckbox.selected) song.notes[curSec].sectionNotes.resize(0);
		
		if (ui.songDialog.sectionEventsCheckbox.selected)
		{
			var i:Int = song.events.length - 1;
			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			while (i > -1)
			{
				var event:Array<Dynamic> = song.events[i];
				if (event != null && endThing > event[0] && event[0] >= startThing)
				{
					song.events.remove(event);
				}
				--i;
			}
		}
		
		updateGrid();
		updateNoteUI();
	}
	
	function cloneSection(before:Int):Void
	{
		var copySec:Int = (curSec - before);
		
		if (before == 0 || song.notes[copySec] == null) return;
		
		for (note in song.notes[copySec].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrotchet * (getSectionBeats(curSec) * 4 * before);
			
			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
			song.notes[curSec].sectionNotes.push(copiedNote);
		}
		
		var startThing:Float = sectionStartTime(-before);
		var endThing:Float = sectionStartTime(-before + 1);
		for (event in song.events)
		{
			var strumTime:Float = event[0];
			if (endThing > event[0] && event[0] >= startThing)
			{
				strumTime += Conductor.stepCrotchet * (getSectionBeats(curSec) * 4 * before);
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...event[1].length)
				{
					var eventToPush:Array<Dynamic> = event[1][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				song.events.push([strumTime, copiedEventArray]);
			}
		}
		updateGrid();
	}
	
	var currentType:Int = 0;
	
	function prepareNotesUI():Void
	{
		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length)
		{
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}
		
		var directories:Array<String> = [];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('data/notetypes/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/data/notetypes/'));
		
		directories.push(Paths.mods('notetypes/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/notetypes/'));
		
		for (mod in Mods.globalMods)
		{
			directories.push(Paths.mods(mod + '/data/notetypes/'));
			directories.push(Paths.mods(mod + '/notetypes/'));
		}
		#end
		
		for (directory in directories)
		{
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				if (FunkinAssets.isDirectory(path)) continue;
				
				for (ext in FunkinScript.H_EXTS)
				{
					if (!file.endsWith(ext)) continue;
					
					var fileToCheck:String = file.substr(0, file.length - ext.length - 1);
					
					if (noteTypeMap.exists(fileToCheck)) continue;
					
					displayNameList.push(fileToCheck);
					noteTypeMap.set(fileToCheck, key);
					noteTypeIntMap.set(key, fileToCheck);
					
					key++;
				}
			}
		}
		
		for (i => name in displayNameList)
			displayNameList[i] = (name.length == 0 ? 'None' : '$i. $name');
			
		ui.songDialog.noteTypeDropdown.populateList([for (name in displayNameList) ToolKitUtils.makeSimpleDropDownItem(name)]);
		ui.songDialog.noteTypeDropdown.selectedItem = displayNameList[0];
	}
	
	function prepareEventsUI():Void
	{
		#if MODS_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];
		
		#if MODS_ALLOWED
		directories.push(Paths.mods('data/events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/data/events/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/data/events/'));
			
		directories.push(Paths.mods('events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/events/'));
		for (mod in Mods.globalMods)
			directories.push(Paths.mods(mod + '/events/'));
		#end
		
		var eventexts = ['.txt', '.hx', '.hxs', '.hscript'];
		var removeShit = [4, 3, 4, 8];
		
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (!FunkinAssets.exists(directory)) continue;
			
			for (file in FunkinAssets.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				for (ext in 0...eventexts.length)
				{
					if (FunkinAssets.isDirectory(path) || file == 'readme.txt' || !file.endsWith(eventexts[ext])) continue;
					
					var fileToCheck:String = file.substr(0, file.length - removeShit[ext]);
					
					if (eventPushedMap.exists(fileToCheck)) break;
					
					eventPushedMap.set(fileToCheck, true);
					
					for (x in ['.hx', '.hxs', '.hscript'])
					{
						if (file.endsWith(x))
						{
							eventStuff.push([fileToCheck, 'scripted description']);
							break;
						}
						else
						{
							eventStuff.push([fileToCheck, File.getContent(path)]);
							break;
						}
					}
					
					break;
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end
		
		ui.songDialog.eventDropdown.populateList([for (ev in eventStuff) {id: ev[0], text: (ev[0].length == 0 ? 'None' : ev[0])}]);
		ui.songDialog.eventDropdown.selectedIndex = 0;
		
		ui.updateEventUI();
	}
	
	function changeEventSelected(change:Int = 0)
	{
		updateNoteUI();
	}
	
	function loadSong():Void
	{
		final instVolume:Float = (audio.inst?.volume ?? 1), playerVolume:Float = audio.playerVolume, opponentVolume:Float = audio.opponentVolume;
		
		audio.stop();
		audio.populate(song);
		audio.pause();
		
		audio.inst.volume = instVolume;
		audio.playerVolume = playerVolume;
		audio.opponentVolume = opponentVolume;
		
		generateSong();
		audio.pause();
		Conductor.songPosition = sectionStartTime();
		audio.time = Conductor.songPosition;
	}
	
	function generateSong()
	{
		audio.inst.onComplete = function() {
			Conductor.songPosition = (audio.songLength - endOffset);
			songEnded = true;
			
			toggleMusic(false);
		};
	}
	
	inline function getSelectedEvents():Array<Array<Dynamic>>
	{
		return [for (note in curSelectedNotes) if (note[2] == null) note];
	}
	
	inline function getSelectedNotes():Array<Array<Dynamic>>
	{
		return [for (note in curSelectedNotes) if (note[2] != null) note];
	}
	
	function gridZoom(snap:Bool = false):Void
	{
		final defaultGridWidth:Float = (GRID_SIZE * (4 * 2 + 1));
		final maxWidth:Float = 840;
		
		final stupidCenter:Float = (defaultGridWidth * .5 + 5);
		
		FlxTween.cancelTweensOf(this, ['CAM_OFFSET']);
		FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
		
		var nextZoom:Float = Math.min(maxWidth / gridBG.width, 1);
		var nextOffset:Float = (gridBG.width * .5 - (stupidCenter / nextZoom));
		
		if (snap)
		{
			camPos.x = (strumLine.x + (CAM_OFFSET = nextOffset));
			FlxG.camera.zoom = nextZoom;
		}
		else
		{
			FlxTween.tween(this, {CAM_OFFSET: nextOffset}, 0.325, {ease: FlxEase.quadOut});
			FlxTween.tween(FlxG.camera, {zoom: nextZoom}, 0.325, {ease: FlxEase.quadOut});
		}
	}
	
	var updatedSection:Bool = false;
	
	inline function sectionStartTime(add:Int = 0):Float
	{
		return Conductor.sectionToSeconds(curSec + add);
	}
	
	inline function getSectionIndex(time:Float = 0):Int
	{
		return Conductor.getSectionRounded(time);
	}
	
	var lastConductorPos:Float;
	var colorSine:Float = 0;
	
	override function update(elapsed:Float)
	{
		final mouseControl:Bool = (!ToolKitUtils.isHaxeUIHovered(camHUD));
		
		ToolKitUtils.update();
		
		var keyboardControl:Bool = (ToolKitUtils.currentFocus == null);
		
		if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.SPACE && ui.songDialog.hidden)
		{
			ui.songDialog.show();
			keyboardControl = false;
		}
		
		if (audio.time < 0)
		{
			Conductor.songPosition = 0;
			toggleMusic(false);
		}
		else if (songEnded || audio.time > (audio.songLength - endOffset)) // fuck gou
		{
			Conductor.songPosition = (audio.songLength - endOffset);
			toggleMusic(false);
			songEnded = false;
		}
		
		Conductor.songPosition = audio.time;
		updateCurStep();
		updateBeat();
		
		strumLineUpdateY();
		
		super.update(elapsed);
		
		bg.scale.x = bg.scale.y = (1 / FlxG.camera.zoom);
		
		if (gradient.alive)
		{
			gradient.scale.x = FlxG.camera.viewWidth;
			gradient.y = FlxMath.lerp(gradient.y, gradient.y - 10, 1 - Math.exp(-elapsed * 3));
		}
		
		if (Math.ceil(strumLine.y) >= gridBG.height)
		{
			if (song.notes[curSec + 1] == null) addSection();
			
			changeSection(curSec + 1, false);
		}
		else if (strumLine.y <= -1)
		{
			changeSection(curSec - 1, false);
		}
		
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);
		
		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT) dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		}
		else
		{
			dummyArrow.visible = false;
		}
		
		if (mouseControl) mouseInput(elapsed);
		
		if (keyboardControl)
		{
			FlxG.sound.muteKeys = ClientPrefs.muteKeys;
			FlxG.sound.volumeUpKeys = ClientPrefs.volumeUpKeys;
			FlxG.sound.volumeDownKeys = ClientPrefs.volumeDownKeys;
			
			keyboardInput(elapsed);
		}
		else if (FlxG.sound.muteKeys.length > 0)
		{
			FlxG.sound.muteKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = [];
		}
		
		strumLineNotes.visible = quant.visible = vortex;
		
		audio.pitch = playbackSpeed;
		
		bpmTxt.text = '${calculateTime(FlxMath.roundDecimal(audio.time, 2))} / ${calculateTime(audio.songLength)} - Beat Snap: ${quantization}th'
			+ '\nSection: $curSec - Step: $curStep - Beat: ${FlxMath.roundDecimal(curDecBeat, 2)}';
			
		var playedSound:Array<Bool> = [for (_ in 0 ... song.lanes) false]; // Prevents ouchy sex sounds
		
		renderedNotes.forEachAlive(function(note:EditorNote) {
			note.alpha = (note.interactable ? 1 : .6);
			
			if (curSelectedNotes.contains(note.chartData))
			{
				colorSine += elapsed;
				var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
				note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
			}
			else if (note.color != FlxColor.WHITE)
			{
				note.color = FlxColor.WHITE;
			}
			
			var time:Float = (note.strumTime + 1.6);
			
			if (time <= Conductor.songPosition)
			{
				note.alpha *= .5;
				
				if (lastConductorPos <= time && audio.playing && note.noteData > -1)
				{
					var fullData:Int = (note.noteData + note.lane * song.keys);
					
					var strum = strumLineNotes.members[fullData];
					if (strum != null)
					{
						strum.copyNoteColor(note);
						strum.playAnim('confirm', true);
						strum.resetAnim = (note.sustainLength / 1000) + 0.15;
					}
					
					var char:OurLittleFriend = note.mustPress ? littleBF : littleDad;
					char.sing(note.noteData % 4);
					
					if (!playedSound[note.lane] && ((bfHitsound && note.mustPress) || (dadHitsound && !note.mustPress)))
					{
						var soundToPlay = 'hitsound';
						if (song.player1 == 'gf') soundToPlay = ('GF_' + Std.string(note.noteData + 1)); // Easter egg
						
						FlxG.sound.play(Paths.sound(soundToPlay)).pan = (note.noteData < (song.keys * .5) ? -0.3 : 0.3); // would be coolio
						playedSound[note.lane] = true;
					}
				}
			}
		});
		
		if (metronomeVolume > 0 && Math.floor(Conductor.getBeat(lastConductorPos)) != Math.floor(Conductor.getBeat(Conductor.songPosition)))
			FlxG.sound.play(Paths.sound('Metronome_Tick'), metronomeVolume);
		
		for (strum in strumLineNotes)
		{
			strum.y = strumLine.y;
			strum.alpha = MathUtil.fpsLerp(strum.alpha, FlxG.sound.music.playing ? 1 : .35, .35);
		}
		
		lastConductorPos = Conductor.songPosition;
		camPos?.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);
	}
	
	public function mouseInput(elapsed:Float):Void
	{
		if (!selectionBox.alive && FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(renderedNotes))
			{
				for (note in renderedNotes)
				{
					if (!note.interactable || !FlxG.mouse.overlaps(note)) continue;
					
					if (FlxG.keys.pressed.CONTROL)
					{
						selectNote(note);
					}
					else if (FlxG.keys.pressed.ALT)
					{
						selectNote(note);
						note.chartData[3] = noteTypeIntMap.get(currentType);
						updateGrid();
					}
					else
					{
						deleteNote(note);
						break;
					}
				}
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}
		
		if (!selectionBox.alive && FlxG.mouse.justPressedRight)
		{
			selectionBox.revive();
			selectionBox.setPosition(FlxG.mouse.x, FlxG.mouse.y);
		}
		if (selectionBox.alive)
		{
			if (!FlxG.mouse.pressedRight) deselect();
			else selectionBox.setSize(FlxG.mouse.x - selectionBox.x, FlxG.mouse.y - selectionBox.y);
		}
		
		if (FlxG.mouse.wheel != 0)
		{
			toggleMusic(false);
			
			var delta:Float = (FlxG.mouse.wheel * Conductor.stepCrotchet * .8);
			
			if (!mouseQuant) audio.time = FlxMath.bound(audio.time - delta, 0, audio.songLength - endOffset);
			else scrollQuantized(FlxG.mouse.wheel > 0);
		}
	}
	
	public function deselect():Void
	{
		if (!selectionBox.alive) return;
		
		selectionBox.kill();
		
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		
		final pad:Float = (GRID_SIZE / 4);
		final hitbox = selectionBox.getHitbox();
		final testRect = flixel.math.FlxRect.get();
		
		for (note in renderedNotes)
		{
			if (!note.interactable) continue;
			
			testRect.set(note.x + pad, note.y + pad, note.width - pad * 2, note.height - pad * 2);
			
			if (!hitbox.overlaps(testRect)) continue;
			
			if (!curSelectedNotes.contains(note.chartData)) curSelectedNotes.push(note.chartData);
		}
		
		testRect.put();
		hitbox.put();
		
		updateGrid();
		updateNoteUI();
	}
	
	public function keyboardInput(elapsed:Float):Void
	{
		var prevControlArray:Array<Dynamic> = vortexControlArray;
		if (vortex)
		{
			vortexControlArray = [ // TODO : make this better im crying
				FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
				FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
			];
		}
		
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) return saveLevel();
		
		if (FlxG.keys.justPressed.ENTER) return enterSong();
		
		if (FlxG.keys.justPressed.E) changeNoteSustain(Conductor.stepCrotchet);
		if (FlxG.keys.justPressed.Q) changeNoteSustain(-Conductor.stepCrotchet);
		
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			PlayState.chartingMode = false;
			FlxG.switchState(funkin.states.editors.MasterEditorMenu.new);
			FunkinSound.playMusic(Paths.music('freakyMenu'));
			return;
		}
		
		if (FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL)
		{
			undo();
		}
		
		if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
		{
			--curZoom;
			updateZoom();
		}
		if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
		{
			curZoom++;
			updateZoom();
		}
		
		if (FlxG.keys.justPressed.ESCAPE && FlxG.keys.pressed.SHIFT) enterSong(startTime > 0 ? startTime : audio.time);
		if (FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			toggleMusic(false);
			openSubState(new ChartingOptionsSubmenu());
		}
		
		if (FlxG.keys.justPressed.SPACE && audio.time < (audio.songLength - endOffset)) togglePause();
		
		if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
		{
			if (FlxG.keys.pressed.SHIFT) resetSection(true);
			else resetSection();
		}
		
		// ARROW VORTEX SHIT NO DEADASS
		
		if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
		{
			toggleMusic(false);
			
			var holdingShift:Float = 1;
			if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
			else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;
			
			var delta:Float = (700 * FlxG.elapsed * holdingShift);
			
			audio.time = FlxMath.bound(audio.time + delta * (FlxG.keys.pressed.W ? -1 : 1), 0, audio.songLength - endOffset);
		}
		
		if (FlxG.keys.justPressed.RIGHT) changeQuantization(1);
		if (FlxG.keys.justPressed.LEFT) changeQuantization(-1);
		
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) scrollQuantized(FlxG.keys.justPressed.UP);
		
		var style = currentType;
		
		if (FlxG.keys.pressed.SHIFT)
		{
			style = 3;
		}
		
		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT) shiftThing = 4;
		
		if (FlxG.keys.justPressed.D) changeSection(curSec + shiftThing);
		if (FlxG.keys.justPressed.A) changeSection(curSec - shiftThing);
		
		if (FlxG.keys.justPressed.DELETE)
		{
			var deleteNotes:Array<Array<Dynamic>> = [];
			
			for (note in curSelectedNotes)
			{
				if (note[2] != null) deleteNotes.push(note);
				else song.events.remove(note);
			}
			
			if (deleteNotes.length > 0)
			{
				for (section in song.notes)
				{
					final secnotes = section.sectionNotes;
					for (note in deleteNotes)
						secnotes.remove(note);
				}
			}
			
			curSelectedNotes.resize(0);
			
			updateGrid();
		}
		
		if (vortex)
		{
			for (i in 0...vortexControlArray.length)
			{
				if (!vortexControlArray[i])
				{
					holdingNotes[i] = null;
				}
				else if (prevControlArray != null && vortexControlArray[i] != prevControlArray[i])
				{
					doANoteThing(quantize(audio.time), i, style);
				}
			}
			
			stretchNotes();
		}
		
		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;
		
		if (!holdingShift && pressedLB || holdingShift && holdingLB) playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB) playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB)) playbackSpeed = 1;
	}
	
	public function changeQuantization(mod:Int = 0):Int
	{
		curQuant = Std.int(MathUtil.euclideanMod(curQuant + mod, quantizations.length));
		
		quant.animation.play('q', true, false, curQuant);
		
		return quantization = quantizations[curQuant];
	}
	
	public function scrollQuantized(up:Bool):Void
	{
		final leniency:Float = 1.25;
		
		toggleMusic(false);
		
		if (vortex && vortexControlArray != null)
		{
			for (i in 0...vortexControlArray.length)
			{
				var note:Array<Dynamic> = holdingNotes[i];
				
				if (vortexControlArray[i] && holdingNotes[i] == null) doANoteThing(quantize(audio.time), i, FlxG.keys.pressed.SHIFT ? 3 : currentType);
			}
		}
		
		updateCurStep();
		var beat:Float = (curDecStep / 4);
		var increase:Float = (1 / (quantization / 4));
		var nextBeat:Float = ((up ? Math.ceil : Math.floor)((beat + (increase * leniency) * (up ? -1 : 1)) / increase) * increase);
		
		var time:Float = Conductor.beatToSeconds(nextBeat);
		time = FlxMath.bound(time, 0, audio.songLength - endOffset);
		
		if (time < 0) return changeSection(-1);
		else if (time > (audio.songLength - endOffset)) return changeSection(0);
		
		if (!vortex)
		{
			audio.time = time;
		}
		else
		{
			FlxTween.cancelTweensOf(audio, ['time']);
			FlxTween.tween(audio, {time: time}, .07, {ease: FlxEase.circOut});
		}
	}
	
	function stretchNotes():Void
	{
		if (holdingNotes == null)
		{
			return trace('what');
		}
		
		var changed:Bool = false;
		
		for (data in holdingNotes)
		{
			if (data == null) continue;
			
			var newLength:Float = Math.max(quantize(audio.time) - data[0], 0);
			
			if (data[2] != newLength)
			{
				data[2] = newLength;
				
				for (note in renderedNotes)
				{
					if (note.chartData != data || !note.alive) continue;
					
					updateSustain(note, getYfromStrum(data[0] + (note.sustainLength = data[2]) /* im so weird */) - getYfromStrum(data[0]) + GRID_SIZE * .5);
				}
				
				changed = true;
			}
		}
		
		if (changed) updateNoteUI();
	}
	
	public static function quantize(time:Float, ?quant:Int):Float
	{
		var q:Float = (1 / ((quant ?? quantization) / 4));
		return Conductor.beatToSeconds(MathUtil.quantize(Conductor.getBeat(time), q));
	}
	
	function updateZoom()
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}
	
	function reloadStrumShit()
	{
		if (strumLineNotes != null)
		{
			strumLineNotes.clear();
			
			for (i in 0...(song.keys * song.lanes))
			{
				var note:StrumNote = new StrumNote(0, 0, 0, i % song.keys);
				
				note.playAnim('static', true);
				note.setPosition(GRID_SIZE * (i + 1), strumLine.y);
				note.setGraphicSize(GRID_SIZE);
				note.scrollFactor.set(1, 1);
				note.updateHitbox();
				note.alpha = 0;
				
				strumLineNotes.add(note);
			}
		}
	}
	
	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	
	function reloadGridLayer()
	{
		gridLayer.killMembers();
		
		if (strumLine == null)
		{
			strumLine = new FlxSprite(0, 50).makeGraphic(1, 1, FlxColor.WHITE);
			insert(FlxMath.maxInt(members.indexOf(strumLineNotes), 0), strumLine);
		}
		
		strumLine.setGraphicSize(Std.int(GRID_SIZE * ((song.keys * song.lanes) + 1)), 4);
		strumLine.updateHitbox();
		
		// this is all kind of cringe but its okay
		final rowsPerBeat:Int = Std.int(4 * zoomList[curZoom]);
		
		final prevRows:Int = ((getSectionBeats(curSec - 1) ?? 0) * rowsPerBeat);
		final curRows:Int = ((getSectionBeats() ?? 0) * rowsPerBeat);
		final nextRows:Int = ((getSectionBeats(curSec + 1) ?? 0) * rowsPerBeat);
		
		final columns:Int = Std.int((song.keys * song.lanes) + 1);
		
		var light = ClientPrefs.editorBoxColors[0],
			dark = ClientPrefs.editorBoxColors[1];
			
		inline function prepareGrid(sprite:FlxSprite, columns:Int, rows:Int, key:String, ?sub:Int, alpha:Int = 255):FlxSprite
		{
			sprite.makeGraphic(columns, rows, key);
			
			sprite.antialiasing = false;
			sprite.setGraphicSize(sprite.width * GRID_SIZE, sprite.height * GRID_SIZE);
			sprite.updateHitbox();
			
			var bm = sprite.graphic.bitmap;
			
			for (y in 0...bm.height)
			{
				for (x in 0...bm.width)
				{
					var checker:Bool = ((x + y) % 2 == 0);
					
					var alpha:Int = alpha;
					var sub:Null<Int> = sub;
					
					if ((!song.notes[curSec].mustHitSection && (x < (song.keys + 1) || x >= (song.keys * 2 + 1))) ||
						(song.notes[curSec].mustHitSection && (x < 1 || x >= (song.keys + 1)))) sub ??= 50;
						
					sub ??= 0;
					
					var lightColor:FlxColor = FlxColor.fromRGB(light.red - sub, light.green - sub, light.blue - sub, alpha);
					var darkColor:FlxColor = FlxColor.fromRGB(dark.red - sub, dark.green - sub, dark.blue - sub, alpha);
					
					bm.setPixel32(x, y, checker ? lightColor : darkColor);
				}
			}
			
			return sprite;
		}
		
		prevGridBG = nextGridBG = null;
		
		prepareGrid(gridBG = gridLayer.recycle(FlxSprite), columns, curRows, 'charterGrid${columns}x${curRows}');
		
		if (curSec > 0) prepareGrid(prevGridBG = gridLayer.recycle(FlxSprite), columns, prevRows, 'charterPrevGrid${columns}x${prevRows}', 50, 128);
		
		if (curSec < song.notes.length) prepareGrid(nextGridBG = gridLayer.recycle(FlxSprite), columns, nextRows, 'charterNextGrid${columns}x${nextRows}', 50, 128);
		
		gridBG.setPosition(0, 0);
		if (prevGridBG != null) prevGridBG.setPosition(0, -prevGridBG.height);
		if (nextGridBG != null) nextGridBG.setPosition(0, gridBG.height);
		
		#if desktop
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices)
		{
			updateWaveform();
		}
		#end
		
		updateGrid();
		
		for (i in 0...lanes) // separators
		{
			var line = gridLayer.recycle(FlxSprite);
			line.makeGraphic(1, 1, FlxColor.WHITE);
			
			line.x = (gridBG.x + (i * song.keys + 1) * GRID_SIZE - 2);
			line.y = (prevGridBG?.y ?? gridBG.y);
			
			line.scale.set(4, (prevGridBG?.height ?? 0) + gridBG.height + (nextGridBG?.height ?? 0));
			line.updateHitbox();
			
			gridLayer.remove(line, true);
			gridLayer.add(line);
		}
		
		lastSecBeats = getSectionBeats();
		if (sectionStartTime(1) >= audio.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
		
		updateHeads();
	}
	
	inline function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum(Conductor.songPosition);
	}
	
	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	
	function updateWaveform(hard:Bool = false)
	{
		#if desktop
		final instWave:Bool = (FlxG.save.data.chart_waveformInst ?? false);
		final vocalsWave:Bool = (FlxG.save.data.chart_waveformVoices ?? false);
		final opponentVocalsWave:Bool = (FlxG.save.data.chart_waveformOpponentVoices ?? false);
		
		waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(GRID_SIZE * 16), 0, 'wave');
		waveformSprite.setGraphicSize(Std.int(GRID_SIZE * song.keys * 2), Std.int(gridBG.height));
		waveformSprite.updateHitbox();
		
		if (!hard && !instWave && !vocalsWave && !opponentVocalsWave) return;
		
		waveformSprite.pixels.fillRect(new Rectangle(0, 0, waveformSprite.pixels.width, waveformSprite.pixels.height), 0);
		
		waveformPrinted = false;
		
		var st:Float = sectionStartTime(),
			et:Float = (st + Conductor.crotchet * getSectionBeats());
			
		inline function drawWave(sound:FlxSound, fromX:Float = 0, ?toX:Float, amp:Float = 1)
		{
			var buffer = sound?._sound?.__buffer;
			if (buffer == null) return;
			
			toX ??= waveformSprite.frameWidth;
			
			wavData[0][0].resize(0);
			wavData[0][1].resize(0);
			wavData[1][0].resize(0);
			wavData[1][1].resize(0);
			
			var bytes:Bytes = buffer.data.toBytes();
			wavData = waveformData(buffer, bytes, st, et, amp, wavData, Std.int(waveformSprite.frameHeight));
			
			final gSize:Float = (toX - fromX);
			final hSize:Float = (gSize / 2);
			
			var lmin:Float = 0, lmax:Float = 0;
			var rmin:Float = 0, rmax:Float = 0;
			
			final leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
			final rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);
			final length:Int = leftLength > rightLength ? leftLength : rightLength;
			
			for (i in 0...length)
			{
				lmin = FlxMath.bound((wavData[0][0][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				lmax = FlxMath.bound((wavData[0][1][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				
				rmin = FlxMath.bound((wavData[1][0][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				rmax = FlxMath.bound((wavData[1][1][i] ?? 0) * (gSize / 1.12), -hSize, hSize) / 2;
				
				final w:Float = ((lmin + rmin + lmax + rmax) * amp);
				final x:Float = (hSize - w * .5 + fromX);
				
				waveformSprite.pixels.fillRect(new Rectangle(x, i, w, 1), FlxColor.BLUE);
			}
		}
		
		final both:Bool = (instWave && (vocalsWave || opponentVocalsWave));
		final scale:Float = waveformSprite.frameWidth;
		
		if (instWave) drawWave(audio.inst, scale * (both ? 1 / 3 : 0), scale * (both ? 2 / 3 : 1));
		if (vocalsWave) drawWave(audio.playerVocals?.getFirstAlive(), 0, scale * (both ? 1 / 3 : .5));
		if (opponentVocalsWave) drawWave(audio.opponentVocals?.getFirstAlive(), scale * (both ? 2 / 3 : .5), null);
		
		waveformPrinted = true;
		#end
	}
	
	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];
		
		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;
		
		var index:Int = Std.int(time * khz);
		
		var samples:Float = ((endTime - time) * khz);
		
		if (steps == null) steps = 1280;
		
		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);
		
		var gotIndex:Int = 0;
		
		var lmin:Float = 0;
		var lmax:Float = 0;
		
		var rmin:Float = 0;
		var rmax:Float = 0;
		
		var rows:Float = 0;
		
		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;
		
		if (array == null) array = [[[0], [0]], [[0], [0]]];
		
		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);
				
				if (byte > 65535 / 2) byte -= 65535;
				
				var sample:Float = (byte / 65535);
				
				if (sample > 0)
				{
					if (sample > lmax) lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin) lmin = sample;
				}
				
				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);
					
					if (byte > 65535 / 2) byte -= 65535;
					
					sample = (byte / 65535);
					
					if (sample > 0)
					{
						if (sample > rmax) rmax = sample;
					}
					else if (sample < 0)
					{
						if (sample < rmin) rmin = sample;
					}
				}
			}
			
			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;
				
				gotIndex++;
				
				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;
				
				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;
				
				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
				else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;
				
				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
				else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;
				
				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
					else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;
					
					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
					else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
					else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;
					
					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
					else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}
				
				lmin = 0;
				lmax = 0;
				
				rmin = 0;
				rmax = 0;
			}
			
			index++;
			rows++;
			if (gotIndex > steps) break;
		}
		
		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}
	
	function changeNoteSustain(value:Float):Void
	{
		var changed:Bool = false;
		
		for (note in curSelectedNotes)
		{
			if (note[0] < 0 || note[2] == null) continue;
			
			note[2] = Math.max(note[2] + value, 0);
			changed = true;
		}
		
		if (!changed) return;
		
		updateNoteUI();
		updateGrid();
	}
	
	function calculateTime(miliseconds:Float = 0):String
	{
		var seconds = Std.int(miliseconds / 1000);
		var minutes = Std.int(seconds / 60);
		seconds = seconds % 60;
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
	}
	
	function resetSection(songBeginning:Bool = false, pause:Bool = true):Void
	{
		updateGrid();
		
		toggleMusic(false);
		// Basically old shit from changeSection???
		audio.time = sectionStartTime();
		
		resetLittleFriends();
		
		if (songBeginning)
		{
			audio.time = 0;
			curSec = 0;
		}
		
		updateCurStep();
		
		updateGrid();
		updateSectionUI();
		updateWaveform();
	}
	
	var metronomeVolume:Float = 1;
	
	function updateVolume():Void
	{
		metronomeVolume = (ui.songDialog.metronomeMuteCheckbox.value ? 0 : ui.songDialog.metronomeVolumeStepper.value);
		
		audio.inst.volume = (ui.songDialog.instrumentalMuteCheckbox.value ? 0 : ui.songDialog.instrumentalVolumeStepper.value);
		
		audio.opponentVolume = (ui.songDialog.opponentMuteCheckbox.value ? 0 : ui.songDialog.opponentVolumeStepper.value);
		
		audio.playerVolume = (ui.songDialog.playerMuteCheckbox.value ? 0 : ui.songDialog.playerVolumeStepper.value);
	}
	
	public function toggleMusic(play:Bool, ?volume:Float):Void
	{
		if (play && !audio.playing)
		{
			audio.play(true, audio.time);
			
			Conductor.songPosition = audio.time;
		}
		else if (!play && audio.playing)
		{
			resetLittleFriends();
			
			audio.pause();
			
			audio.time = Conductor.songPosition;
		}
	}
	
	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		curSec = sec;
		
		if (updateMusic)
		{
			toggleMusic(false);
			
			var newTime:Float;
			
			if (curSec >= 0)
			{
				newTime = sectionStartTime();
			}
			else
			{
				newTime = audio.songLength - endOffset;
				
				curSec = getSectionIndex(newTime);
			}
			
			if (newTime < audio.songLength)
			{
				audio.time = newTime;
				
				if (song.notes.length <= curSec)
				{
					var old:Int = song.notes.length;
					
					while (song.notes.length <= curSec)
						addSection();
						
					trace('populated ${song.notes.length - old} sections');
				}
			}
			else
			{
				audio.time = curSec = 0;
			}
			
			updateCurStep();
		}
		
		Conductor.bpm = (Conductor.getBPMFromSeconds(sectionStartTime())?.bpm ?? song.bpm);
		
		var blah1:Float = getSectionBeats();
		var blah2:Float = getSectionBeats(curSec + 1);
		if (sectionStartTime(1) > audio.songLength) blah2 = 0;
		
		if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
		{
			reloadGridLayer();
		}
		else
		{
			updateGrid();
		}
		updateSectionUI();
		
		Conductor.songPosition = audio.time;
		updateWaveform();
		strumLineUpdateY();
		resetLittleFriends();
	}
	
	function updateSectionUI():Void
	{
		var sec = song.notes[curSec];
		
		ui.songDialog.sectionBeatsStepper.value = getSectionBeats();
		ui.songDialog.mustHitCheckbox.value = sec.mustHitSection;
		ui.songDialog.gfSectionCheckbox.value = sec.gfSection;
		ui.songDialog.bpmCheckbox.value = sec.changeBPM;
		ui.songDialog.bpmStepper.value = sec.bpm;
		
		updateHeads();
	}
	
	function updateHeads():Void
	{
		var mustHit:Bool = song.notes[curSec].mustHitSection;
		var isGF:Bool = song.notes[curSec].gfSection;
		
		rightIcon.visible = (song.lanes > 1);
		
		leftIcon.updateOffset = rightIcon.updateOffset = false;
		
		leftIcon.changeIcon((isGF && mustHit) ? gfIcon : bfIcon);
		rightIcon.changeIcon((isGF && !mustHit) ? gfIcon : dadIcon);
		
		leftIcon.setGraphicSize(45);
		leftIcon.updateHitbox(); // absolute duct tape
		rightIcon.setGraphicSize(45);
		rightIcon.updateHitbox();
		
		leftIcon.x = (GRID_SIZE * (song.keys * .5 + 1) - leftIcon.width * .5);
		rightIcon.x = (GRID_SIZE * (song.keys * 1.5 + 1) - rightIcon.width * .5);
		
		leftIcon.y = (-leftIcon.height);
		rightIcon.y = (-rightIcon.height);
		
		var focusedIcon:HealthIcon = (mustHit ? leftIcon : rightIcon);
		
		cameraIcon.setGraphicSize(30);
		cameraIcon.updateHitbox();
		cameraIcon.setPosition(focusedIcon.x - 20, focusedIcon.y - 20);
	}
	
	function updateNoteUI():Void
	{
		var notes = getSelectedNotes();
		
		var minTime:Float = Lambda.fold(curSelectedNotes, (note, r) -> Math.min(note[0], r), Math.POSITIVE_INFINITY);
		var minLength:Float = Lambda.fold(notes, (note, r) -> Math.max(note[2], r), 0);
		
		ui.songDialog.strumTimeStepper.changeSilent(minTime);
		ui.songDialog.sustainLengthStepper.changeSilent(minLength);
		
		if (notes.length == 1)
		{
			currentType = (noteTypeMap.get(notes[0][3]) ?? 0);
			
			ui.songDialog.noteTypeDropdown.selectedIndex = currentType;
		}
		
		ui.updateEventUI();
	}
	
	function updateGrid():Void
	{
		renderedNoteType.killMembers();
		
		var alive:Array<Array<Dynamic>> = [];
		
		for (note in renderedNotes)
		{
			if (!note.alive) continue;
			
			if (note.section < curSec - 1 || note.section > curSec + 1)
			{
				note.kill();
			}
			else
			{
				alive.push(note.chartData);
				
				note.interactable = (note.section == curSec);
				
				refreshNote(note);
				addNoteTooltip(note);
				
				note.setPosition((note.noteData + note.lane * song.keys) * GRID_SIZE + GRID_SIZE, getYfromStrum(note.strumTime));
				updateSustain(note, getYfromStrum(note.strumTime + note.sustainLength) - getYfromStrum(note.strumTime) + GRID_SIZE * .5);
			}
		}
		
		for (section in FlxMath.maxInt(curSec - 1, 0) ... FlxMath.minInt(curSec + 2, song.notes.length))
		{
			final startThing:Float = sectionStartTime(section - curSec);
			final endThing:Float = sectionStartTime(section - curSec + 1);
			
			for (i in song.events)
			{
				if (i[0] >= startThing && i[0] < endThing && !alive.remove(i)) spawnNote(i, section - curSec);
			}
			
			for (i in song.notes[section].sectionNotes)
			{
				if (!alive.remove(i)) spawnNote(i, section - curSec);
			}
		}
	}
	
	function spawnNote(i:Array<Dynamic>, offset:Int = 0):Void
	{
		var note:EditorNote = setupNote(i, offset);
		
		addNoteTooltip(note);
	}
	
	function addNoteTooltip(note:EditorNote):Void
	{
		if (note.noteData < 0)
		{
			var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
			if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;
			
			var daText:AttachedFlxText = renderedNoteType.recycle(AttachedFlxText, function() return new AttachedFlxText(0, 0, 400, '', 12));
			
			daText.text = text;
			daText.fieldWidth = 400;
			daText.setFormat(Paths.DEFAULT_FONT, 12, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
			daText.borderSize = 1;
			daText.xAdd = -410;
			daText.yAdd = (note.eventLength > 1 ? 8 : 0);
			daText.alpha = (note.interactable ? 1 : .5);
			daText.sprTracker = note;
			
			return;
		}
		
		if (note.noteType != null && note.noteType.length > 0) // TODO also add this to EditorNote im jsust lazy
		{
			final type:Null<Int> = noteTypeMap.get(note.noteType);
			final theType:String = (type == null ? '?' : Std.string(type));
			
			var daText:AttachedFlxText = renderedNoteType.recycle(AttachedFlxText, function() return new AttachedFlxText(0, 0, 100, '', 24));
			
			daText.text = theType;
			daText.fieldWidth = 100;
			daText.setFormat(Paths.DEFAULT_FONT, 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			daText.alpha = (note.interactable ? 1 : .5);
			daText.borderSize = 1;
			daText.xAdd = -32;
			daText.yAdd = 6;
			daText.sprTracker = note;
		}
	}
	
	function setupNote(i:Array<Dynamic>, offset:Int = 0):EditorNote
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var shifted = i[4];
		
		var intendedData = daNoteInfo;
		if (!shifted)
		{
			if (daNoteInfo % song.keys != daNoteInfo % initialKeyCount)
			{
				shifted = true;
				intendedData = daNoteInfo + (song.keys - initialKeyCount);
			}
		}
		
		if (daNoteInfo != intendedData && offset == 0)
		{
			for (p in song.notes[curSec].sectionNotes)
			{
				if (p[0] == daStrumTime && p[1] == daNoteInfo && !p[4])
				{
					song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][1] = intendedData;
					song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][4] = true;
					trace('previous data: $daNoteInfo | new data: $intendedData | song.notes data: ${song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][1]} | youre not gonna shift again..? ${song.notes[curSec].sectionNotes[song.notes[curSec].sectionNotes.indexOf(p)][4]}');
				}
			}
		}
		
		var note:EditorNote = renderedNotes.recycle(EditorNote, function() return new EditorNote(null, null, null, null, true));
		note._reset();
		note.chartData = i;
		note.sustainLength = 0;
		note.alreadyShifted = true;
		note.section = (curSec + offset);
		
		note.interactable = (offset == 0);
		
		refreshNote(note);
		
		return note;
	}
	
	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}
	
	inline function refreshNote(note:EditorNote):Void
	{
		final i = note.chartData;
		
		final strumTime:Float = note.chartData[0];
		final noteData = note.chartData[1];
		final dir = (noteData % song.keys);
		final lane:Int = FlxMath.maxInt(Math.floor(noteData / song.keys), 0);
		
		if (dir >= 0 && (note.noteData != dir || note.lane != lane || (i[2] != null && note.noteType != i[3])))
		{
			note.lane = lane;
			note.noteData = dir;
			note.strumTime = strumTime;
			note.mustPress = ((note.lane = note.player = lane) != 1);
			note.animation?.destroyAnimations();
			note.reAssignable = true;
			note.loadNoteAnims();
			note._resetTexture();
		}
		else
		{
			if (strumTime != note.strumTime && note.isQuant)
			{
				note.quant = NoteUtil.getQuant(Conductor.getBeat(strumTime));
				note.updateColors();
			}
		}
		
		note.strumTime = strumTime;
		
		if (i[2] != null)
		{ // Common note
			if (i[3] != null && i[3] != '')
			{
				if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
				{
					i[3] = noteTypeIntMap.get(i[3]);
				}
				if (i.length > (song.keys - 1) && (i[song.keys - 1] == null || i[song.keys - 1].length < 1))
				{
					i.remove(i[3]);
				}
			}
			
			note.sustainLength = i[2];
			note.noteType = i[3];
		}
		else
		{ // Event note
			if (note.texture != 'event') // maybe i shoudl just recyclce these separately cus its a hard performance hit though
			{
				note.loadGraphic(Paths.image('editors/eventArrow'));
				@:bypassAccessor note.texture = 'event'; // jsut for reload
			}
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.sustainLength = 0;
			note.noteData = -1;
		}
		
		note.setGraphicSize(GRID_SIZE);
		note.updateHitbox();
		
		updateSustain(note, getYfromStrum(note.strumTime + note.sustainLength) - getYfromStrum(note.strumTime) + GRID_SIZE * .5);
		note.setPosition((note.noteData + note.lane * song.keys) * GRID_SIZE + GRID_SIZE, getYfromStrum(note.strumTime));
	}
	
	inline function updateSustain(note:EditorNote, height:Float):FlxSprite
	{
		var minHeight:Float = ((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		
		note.sustainHeight = (height >= minHeight ? height : 0);
		
		return note.sustainSprite;
	}
	
	private function addSection(sectionBeats:Int = 4):Void
	{
		var sec:SongSection =
			{
				sectionBeats: sectionBeats,
				bpm: song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				altAnim: false
			};
			
		song.notes.push(sec);
	}
	
	function selectNote(note:EditorNote):Void
	{
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		curSelectedNotes.push(note.chartData);
		
		if (note.noteData >= 0)
		{
			var noteDataToCheck:Int = (note.noteData + note.lane * song.keys);
		}
		else if (curSelectedNotes.length == 1)
		{
			curEventSelected = Std.int(curSelectedNotes[0][1].length) - 1;
		}
		changeEventSelected();
		
		updateNoteUI();
	}
	
	function deleteNote(note:EditorNote):Void
	{
		var noteDataToCheck:Int = note.noteData;
		
		if (note.noteData > -1) // Normal Notes
		{
			noteDataToCheck = (note.noteData + note.lane * song.keys);
			
			song.notes[curSec].sectionNotes.remove(note.chartData);
		}
		else // Events
		{
			song.events.remove(note.chartData);
		}
		
		curSelectedNotes.remove(note.chartData);
		
		note.kill();
		
		for (tooltip in renderedNoteType)
		{
			if (tooltip.sprTracker == note) tooltip.kill();
		}
	}
	
	public function doANoteThing(cs:Float, d:Int, style:Int)
	{
		for (note in renderedNotes)
		{
			if (note.alive && Math.abs(cs - quantize(note.strumTime)) < 3 && d == (note.noteData + note.lane * song.keys)) return deleteNote(note);
		}
		
		holdingNotes[d] = addNote(cs, d, style);
	}
	
	function clearSong():Void
	{
		for (daSection in 0...song.notes.length)
		{
			song.notes[daSection].sectionNotes = [];
		}
		
		updateGrid();
	}
	
	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Array<Dynamic>
	{
		// curUndoIndex++;
		// var newsong = song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;
		
		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;
		
		var newNote:Array<Dynamic> = null;
		
		if (!FlxG.keys.pressed.SHIFT) curSelectedNotes.resize(0);
		
		if (noteData > -1)
		{
			newNote = [noteStrum, noteData, noteSus, noteTypeIntMap.get(daType), true];
			song.notes[curSec].sectionNotes.push(newNote);
			
			if (FlxG.keys.pressed.CONTROL) choirNotes([newNote]);
		}
		else
		{
			var event = eventStuff[ui.songDialog.eventDropdown.selectedIndex][0];
			var text1 = ui.songDialog.value1Field.value;
			var text2 = ui.songDialog.value2Field.value;
			
			newNote = [noteStrum, [[event, text1, text2]]];
			song.events.push(newNote);
			
			if (!FlxG.keys.pressed.SHIFT || curSelectedNotes.length == 0) curEventSelected = 0;
		}
		
		curSelectedNotes.push(newNote);
		
		changeEventSelected();
		
		spawnNote(newNote);
		updateNoteUI();
		
		return newNote;
	}
	
	function choirNotes(notesArray:Array<Dynamic>):Void
	{
		final notes:Array<Dynamic> = song.notes[curSec].sectionNotes;
		final duetNotes:Array<Array<Dynamic>> = [];
		
		if (notesArray.length == 0) notesArray = notes;
		
		for (note in notesArray)
		{
			if (note[1] < 0) continue;
			
			for (i in 0...song.lanes)
			{
				var newData:Int = Std.int((note[1] % song.keys) + i * song.keys);
				var overlap:Bool = false;
				
				for (otherNote in notes)
				{
					if (Math.abs(otherNote[0] - note[0]) < 3 && otherNote[1] == newData)
					{
						overlap = true;
						break;
					}
				}
				
				if (!overlap) duetNotes.push([note[0], newData, note[2], note[3]]);
			}
		}
		
		for (note in duetNotes)
		{
			curSelectedNotes.push(note);
			notes.push(note);
		}
	}
	
	function mirrorNotes(notesArray:Array<Dynamic>, axes:flixel.util.FlxAxes = X):Void
	{
		if (notesArray.length > 0)
		{
			if (axes.x)
			{
				var minData:Int = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> (note[1] > -1 ? FlxMath.minInt(note[1], r) : r), 9999);
				var maxData:Int = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> FlxMath.maxInt(note[1], r), 0);
				
				for (note in notesArray)
				{
					if (note[1] < 0) continue;
					
					note[1] = (maxData - note[1] + minData);
				}
			}
			
			if (axes.y)
			{
				var minTime:Float = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Float) -> Math.min(note[0], r), Math.POSITIVE_INFINITY);
				var maxTime:Float = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Float) -> Math.max(note[0], r), Math.NEGATIVE_INFINITY);
				
				for (note in notesArray)
				{
					if (note[1] < 0) continue;
					
					note[0] = (maxTime - note[0] + minTime);
				}
			}
		}
		else
		{
			final minTime:Float = sectionStartTime();
			final maxTime:Float = (startTime + getSectionBeats() * Conductor.crotchet);
			
			for (note in song.notes[curSec].sectionNotes)
			{
				if (note[1] < 0) continue;
				
				if (axes.x) note[1] = ((song.keys - (note[1] % song.keys) - 1) + Std.int(note[1] / song.keys) * song.keys);
				
				if (axes.y) note[0] = (maxTime - note[0] + minTime);
			}
		}
	}
	
	function transformNoteStrumlines(notesArray:Array<Dynamic>, fun:(noteStrumline:Int, minStrumline:Int, maxStrumline:Int) -> Int):Void
	{
		var minStrumline:Int, maxStrumline:Int;
		
		if (notesArray.length == 0)
		{
			minStrumline = 0;
			maxStrumline = (song.lanes - 1);
			notesArray = song.notes[curSec].sectionNotes;
		}
		else
		{
			minStrumline = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> (note[1] > -1 ? FlxMath.minInt(getStrumline(note[1]), r) : r), 9999);
			maxStrumline = Lambda.fold(notesArray, (note:Array<Dynamic>, r:Int) -> FlxMath.maxInt(getStrumline(note[1]), r), 0);
		}
		
		for (note in notesArray)
		{
			if (note[1] < 0) continue;
			
			var newStrumline:Int = fun(getStrumline(note[1]), minStrumline, maxStrumline);
			note[1] = ((note[1] % song.keys) + newStrumline * song.keys);
		}
	}
	
	function shiftStrumlineTransform(noteStrumline:Int, minStrumline:Int, maxStrumline:Int):Int
	{
		return ((noteStrumline + 1) % (maxStrumline - minStrumline + 1) + minStrumline);
	}
	
	function swapStrumlineTransform(noteStrumline:Int, minStrumline:Int, maxStrumline:Int):Int
	{
		return (maxStrumline - noteStrumline + minStrumline);
	}
	
	inline function getStrumline(index:Int):Int return Std.int(index / song.keys);
	
	// will figure this out l8r
	// lol you didnt so i had to
	function redo()
	{
		// song = redos[curRedoIndex];
	}
	
	function undo()
	{
		// redos.push(song);
		undos.pop();
		// song.notes = undos[undos.length - 1];
		///trace(song.notes);
		// updateGrid();
	}
	
	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		final leZoom:Float = (doZoomCalc ? zoomList[curZoom] : 1);
		
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrotchet);
	}
	
	inline function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		final leZoom:Float = (doZoomCalc ? zoomList[curZoom] : 1);
		
		return (gridBG.y + (Conductor.getStep(strumTime) - Conductor.getStep(sectionStartTime())) * leZoom * GRID_SIZE);
	}
	
	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];
		
		for (i in song.notes)
		{
			noteData.push(i.sectionNotes);
		}
		
		return noteData;
	}
	
	function loadJson(song:String):Void
	{
		reloadGridLayer();
		
		try
		{
			final songName = Paths.sanitize(song);
			ChartEditorState.song = Chart.fromPath(Paths.json('$songName/data/${Difficulty.getDifficultyFilePath()}'));
		}
		catch (e)
		{
			Logger.log('error loading chart\nException: ${e.toString()}', ERROR, true);
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		FlxG.resetState();
	}
	
	public static function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify(
			{
				"song": song
			});
		FlxG.save.flush();
	}
	
	function clearEvents()
	{
		for (note in renderedNotes) if (note.noteData < 0) note.kill();
		song.events = [];
		updateGrid();
	}
	
	private function saveLevel()
	{
		if (song.events != null && song.events.length > 1) song.events.sort(sortByTime);
		var json =
			{
				"song": song
			};
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.sanitize(song.song) + ".json");
		}
	}
	
	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
	
	private function saveEvents()
	{
		if (song.events != null && song.events.length > 1) song.events.sort(sortByTime);
		var eventsSong:Dynamic =
			{
				events: song.events
			};
		var json =
			{
				"song": eventsSong
			}
			
		var data:String = Json.stringify(json, "\t");
		
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}
	
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}
	
	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}
	
	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
	
	function getSectionBeats(?section:Int):Null<Int>
	{
		return (song.notes[section ?? curSec]?.sectionBeats ?? 4);
	}
	
	public static function enterSong(?time:Float)
	{
		autosaveSong();
		
		if (time != null) PlayState.startOnTime = time;
		PlayState.SONG = song;
		
		instance?.audio.stop();
		
		FlxG.switchState(PlayState.new);
	}
	
	public function togglePause()
	{
		toggleMusic(!audio.playing);
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}

class ChartingOptionsSubmenu extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = [
		'Resume',
		'Play from beginning',
		'Play from here',
		'Set start time',
		'Play from start time' /*, 'Botplay'*/,
		'Exit to Editor Menu'
	]; // shamelessly stolen from andromeda im sorry
	var curSelected:Int = 0;
	var canexit:Bool = false;
	
	public function new()
	{
		super();
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.6;
		add(bg);
		
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		for (i in 0...menuItems.length)
		{
			var item = new Alphabet(0, 70 * i, menuItems[i], true, false);
			item.isMenuItem = true;
			item.targetY = i;
			item.scrollFactor.set();
			// if(menuItems[i] == 'Botplay'){
			// 	if(PlayState.instance.cpuControlled)
			// 		item.color = FlxColor.GREEN;
			// 	else
			// 		item.color = FlxColor.RED;
			// }
			grpMenuShit.add(item);
		}
		
		new FlxTimer().start(0.05, function(shit:FlxTimer) {
			canexit = true;
		});
		changeSelection();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE && canexit) close();
		
		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		
		if (upP) changeSelection(-1);
		if (downP) changeSelection(1);
		if (accepted)
		{
			switch (menuItems[curSelected])
			{
				case 'Resume':
					close();
					
				case 'Play from beginning':
					ChartEditorState.enterSong();
					
				case 'Play from here':
					ChartEditorState.enterSong(ChartEditorState.instance.audio.time);
					
				case 'Play from start time':
					ChartEditorState.enterSong(ChartEditorState.startTime);
					
				case 'Set start time':
					ChartEditorState.startTime = ChartEditorState.instance.audio.time;
					
				case 'Exit to Editor Menu':
					FlxG.switchState(() -> new MasterEditorMenu());
					FunkinSound.playMusic(Paths.music('freakyMenu'));
			}
		}
	}
	
	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		if (curSelected < 0) curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length) curSelected = 0;
		
		var bullShit:Int = 0;
		
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		trace(menuItems[curSelected]);
	}
}
