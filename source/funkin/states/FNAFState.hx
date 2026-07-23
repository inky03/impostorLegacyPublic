package funkin.states;

import openfl.filters.ShaderFilter;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.text.FlxTypeText;

import funkin.backend.FunkinShader.FunkinRuntimeShader;
import funkin.FunkinAssets;
#if VIDEOS_ALLOWED import funkin.video.FunkinVideoSprite; #end

class FNAFState extends MusicBeatState
{
	var exiting:Bool = false;
	
	// room
	var camTarget:FlxSprite;
	var hudCam:FlxCamera;
	var camDrag:Float = 0.06;
	var camRangeX:Float = 200;
	var camRangeY:Float = 30;
	var cameraUnlocked:Bool = false;
	var clickCooldown:Float = 0;
	var screenZooming:Bool = false;
	
	// dialogue
	var dialogueLines:Array<String>;
	var postDialogueLines:Array<String>;
	var dialogueIndex:Int = 0;
	var postDialogueIndex:Int = 0;
	var dialogueActive:Bool = false;
	var dialogueEnded:Bool = false;
	var inPostDialogue:Bool = false;
	var monitorDialogueActive:Bool = false;
	var advanceKeyHeld:Bool = false;
	var advanceMouseHeld:Bool = false;
	
	var dlgBlackScreen:FlxSprite;
	var dlgOverlay:FlxSprite;
	var dlgText:FlxTypeText;
	var rtlDisplayText:FlxText;
	var rtlWrapMeasure:FlxText;
	var rtlMode:Bool = false;
	var rtlFullText:String = "";
	var dlgYesBro:FlxSprite;
	
	var glow:FlxSprite;
	var glowHovering:Bool = false;
	var leftscreen:FlxSprite;
	var leftscreenHovering:Bool = false;
	var rightscreen:FlxSprite;
	var rightscreenHovering:Bool = false;
	
	// computer
	var passwordActive:Bool = false;
	var passwordReady:Bool = false;
	var enteredCode:String = "";
	var inputCooldown:Float = 0;
	var cursorTimer:Float = 0;
	var cursorVisible:Bool = true;
	var fieldY:Float = 0;
	var monX:Float = 0;
	var monY:Float = 0;
	var monW:Float = 0;
	var monH:Float = 0;
	var videoScale:Float = 1.2;
	
	var compBg:FlxBackdrop;
	var compPanel:FlxSprite;
	var compStatic:FlxSprite;
	var compTitle:FlxText;
	var compInput:FlxText;
	var compCursor:FlxText;
	var compStatus:FlxText;
	var compImage:FlxSprite;
	var compLoader:FlxSprite;
	var compMusicImg:FlxSprite;
	var compMusicLabel:FlxText;
	
	// shaders
	var FNAFShaderThanksRozebud:FunkinRuntimeShader;
	var vhsShader:Null<FunkinRuntimeShader> = null;
	var vhsOn:Bool = false;
	var vhsFrame:Int = 0;
	var shaderDepth:Float = 4.0;
	var depthTween:FlxTween;
	
	// secrets
	#if VIDEOS_ALLOWED var secretVideo:FunkinVideoSprite; #end
	var videoPlaying:Bool = false;
	var audioPlaying:Bool = false;
	var secretAudio:FlxSound;
	var imageShowing:Bool = false;
	var imageTransitioning:Bool = false;
	var crashAfterVideo:Bool = false;
	var isLoading:Bool = false;
	
	// hint! sorry rozebud
	var hintTextA:FlxText;
	
	// called A cause i originally wanted 2 onscreen
	
	override function create()
	{
		super.create();
		
		if (ClientPrefs.fnafHintCode == '')
		{
			var hintCodes = [
				'DANKBARS', 'SECRET', 'DIRECT', 'REACTOR', 'FINALE', 'RIVALS', 'RASPBERRY', 'RAID',
				'CHALLENGE', 'SNEEP', 'FUNNI342', 'RUBATO', 'TRIPLETROUBLE', 'STORY', 'NOOB49', 'TRINKETS', 'DREAMJOB', 'EBK', 'WHITEPARASITE', 'BROIMPOSTOR',
				'COMMUNITYGAME', 'PENKARU', 'DEFEAT', 'LIGHTSDOWN', 'LIGHTSOUT', 'LIGHTSOFF', 'FLIPPY', 'DK',
				'HELLSCAPE', 'ZARED'
			];
			var hintWeights = [for (code in hintCodes) getHintCodeWeight(code)];
			ClientPrefs.fnafHintCode = randomFromArrayWeighted(hintCodes, hintWeights);
			ClientPrefs.flush();
		}
		
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		
		FlxG.cameras.bgColor = FlxColor.BLACK;
		
		dialogueLines = [Lang.str('weirdroute0'), Lang.str('weirdroute1'), Lang.str('weirdroute2')];
		postDialogueLines = [Lang.str('weirdroute3'), Lang.str('weirdroute4')];
		
		camTarget = new FlxSprite();
		camTarget.frames = Paths.getSparrowAtlas('bars/bars');
		camTarget.animation.addByPrefix('idle', 'peter', 12, true);
		camTarget.animation.play('idle');
		camTarget.scale.set(1.15, 1.15);
		camTarget.updateHitbox();
		camTarget.screenCenter();
		camTarget.alpha = 0;
		add(camTarget);
		
		glow = new FlxSprite(500, 1000).loadGraphic(Paths.image('bars/glow'));
		glow.setGraphicSize(Std.int(glow.width * 1.15));
		glow.alpha = 0;
		add(glow);
		
		leftscreen = new FlxSprite().loadGraphic(Paths.image('bars/leftscreen'));
		leftscreen.setGraphicSize(Std.int(leftscreen.width * 1.15));
		leftscreen.updateHitbox();
		leftscreen.alpha = 0;
		leftscreen.blend = ADD;
		add(leftscreen);
		
		rightscreen = new FlxSprite().loadGraphic(Paths.image('bars/rightscreen'));
		rightscreen.setGraphicSize(Std.int(rightscreen.width * 1.15));
		rightscreen.updateHitbox();
		rightscreen.alpha = 0;
		rightscreen.blend = ADD;
		add(rightscreen);
		
		// room/post shaders
		FNAFShaderThanksRozebud = buildShader('round');
		if (FNAFShaderThanksRozebud != null) FNAFShaderThanksRozebud.setFloat('depth', 4.0);
		
		if (ClientPrefs.shaders)
		{
			vhsShader = buildShader('vhs');
			if (vhsShader != null)
			{
				vhsShader.setInt('uFrame', 0);
				vhsShader.setFloat('uInterlace', 1.0);
			}
		}
		
		// hud camera
		hudCam = new FlxCamera();
		hudCam.bgColor = 0x00000000;
		FlxG.cameras.add(hudCam, false);
		applyCameraFilters();
		
		dlgBlackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		dlgBlackScreen.scrollFactor.set(0, 0);
		dlgBlackScreen.cameras = [hudCam];
		add(dlgBlackScreen);
		
		dlgOverlay = new FlxSprite().loadGraphic(Paths.image('bars/overlay'));
		dlgOverlay.scrollFactor.set(0, 0);
		dlgOverlay.setGraphicSize(FlxG.width, FlxG.height);
		dlgOverlay.updateHitbox();
		dlgOverlay.cameras = [hudCam];
		add(dlgOverlay);
		
		rtlMode = Lang.hasSpecial('rightToLeft');
		
		var tX = 170;
		var tY = FlxG.height - 108;
		var tW = FlxG.width - 340;
		var rtlTextY = tY - (rtlMode ? 30 : 0);
		
		dlgText = new FlxTypeText(tX, tY, tW, '', 30);
		dlgText.font = Paths.font('liber.ttf');
		dlgText.color = FlxColor.WHITE;
		dlgText.scrollFactor.set(0, 0);
		dlgText.sounds = [FlxG.sound.load(Paths.sound('textSoft'), 0.6)];
		dlgText.cameras = [hudCam];
		dlgText.visible = !rtlMode;
		add(dlgText);
		
		rtlDisplayText = new FlxText(tX, rtlTextY, tW, '', 30);
		rtlDisplayText.setFormat(Paths.font('liber.ttf'), 30, FlxColor.WHITE, rtlMode ? 'right' : 'left');
		rtlDisplayText.scrollFactor.set(0, 0);
		rtlDisplayText.cameras = [hudCam];
		rtlDisplayText.textField.wordWrap = true;
		rtlDisplayText.textField.multiline = true;
		rtlDisplayText.visible = rtlMode;
		add(rtlDisplayText);
		
		rtlWrapMeasure = new FlxText(tX, rtlTextY, tW, '', 30);
		rtlWrapMeasure.setFormat(Paths.font('liber.ttf'), 30, FlxColor.WHITE, rtlMode ? 'right' : 'left');
		rtlWrapMeasure.scrollFactor.set(0, 0);
		rtlWrapMeasure.cameras = [hudCam];
		rtlWrapMeasure.textField.wordWrap = true;
		rtlWrapMeasure.textField.multiline = true;
		rtlWrapMeasure.visible = false;
		add(rtlWrapMeasure);
		
		dlgYesBro = new FlxSprite().loadGraphic(Paths.image('bars/go button'));
		dlgYesBro.scrollFactor.set(0, 0);
		dlgYesBro.scale.set(0.5, 0.5);
		dlgYesBro.updateHitbox();
		dlgYesBro.x = rtlMode ? (tX + 10) : (tX + tW - dlgYesBro.width - 10);
		dlgYesBro.y = tY + 58;
		dlgYesBro.alpha = 0;
		dlgYesBro.cameras = [hudCam];
		add(dlgYesBro);
		
		if (ClientPrefs.fnafStateVisited)
		{
			// Skip intro sequence on repeat visits.
			dlgOverlay.visible = false;
			dlgText.alpha = 0;
			rtlDisplayText.alpha = 0;
			dlgYesBro.alpha = 0;
			camTarget.alpha = 0;
			cameraUnlocked = true;
			crossfadeMusic('amb', 1.0, 0.6);
			FlxTween.tween(dlgBlackScreen, {alpha: 0}, 1.0,
				{
					ease: FlxEase.quadOut,
					onComplete: function(_) {
						remove(dlgBlackScreen);
					}
				});
			FlxTween.tween(camTarget, {alpha: 1}, 1.0, {ease: FlxEase.quadOut});
		}
		else
		{
			ClientPrefs.fnafStateVisited = true;
			dialogueActive = true;
			beginLine(dialogueLines, 0);
		}
	}
	
	// shader helpers
	
	function buildShader(fragName:String):FunkinRuntimeShader
	{
		var path = Paths.fragment(fragName);
		if (path == null || !FunkinAssets.exists(path)) return null;
		var src = FunkinAssets.getContent(path);
		if (src == null) return null;
		return new FunkinRuntimeShader(src, null);
	}
	
	function applyCameraFilters()
	{
		var gf:Array<openfl.filters.BitmapFilter> = [];
		if (FNAFShaderThanksRozebud != null) gf.push(new ShaderFilter(FNAFShaderThanksRozebud));
		FlxG.camera.filters = gf;
		
		if (hudCam != null) hudCam.filters = (vhsOn && vhsShader != null) ? [new ShaderFilter(vhsShader)] : [];
	}
	
	function tickVHS()
	{
		if (!vhsOn || vhsShader == null) return;
		vhsFrame++;
		vhsShader.setInt('uFrame', vhsFrame);
		vhsShader.setFloat('uInterlace', 1.0);
	}
	
	function tweenDepth(target:Float, dur:Float)
	{
		if (depthTween != null) depthTween.cancel();
		var from = shaderDepth;
		depthTween = FlxTween.num(from, target, dur, {ease: FlxEase.quadOut}, function(v) {
			shaderDepth = v;
			if (FNAFShaderThanksRozebud != null) FNAFShaderThanksRozebud.setFloat('depth', v);
		});
	}
	
	function crossfadeMusic(key:String, dur:Float = 1.0, vol:Float = 0.6)
	{
		FunkinSound.playMusic(Paths.sound(key), 0);
		FlxTween.tween(FlxG.sound.music, {volume: vol}, dur, {ease: FlxEase.linear});
	}
	
	// dialogue flow
	
	function beginLine(lines:Array<String>, idx:Int)
	{
		dialogueEnded = false;
		FlxTween.cancelTweensOf(dlgYesBro);
		dlgYesBro.alpha = 0;
		rtlFullText = lines[idx];
		if (rtlMode) rtlDisplayText.text = '';
		
		dlgText.completeCallback = function() {
			dialogueEnded = true;
			if (rtlMode)
			{
				rtlDisplayText.text = formatArabicDialogueText(rtlFullText);
				Lang.arabicTextFix(rtlDisplayText);
			}
			FlxTween.tween(dlgYesBro, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
		};
		dlgText.resetText(lines[idx]);
		dlgText.start(0.045, true);
	}
	
	function startPostDialogue()
	{
		inPostDialogue = true;
		dialogueActive = true;
		postDialogueIndex = 0;
		
		dlgOverlay.visible = true;
		dlgOverlay.alpha = 0;
		dlgText.alpha = 1;
		dlgYesBro.alpha = 0;
		
		FlxTween.tween(dlgOverlay, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});
		beginLine(postDialogueLines, 0);
	}
	
	function advanceDialogue()
	{
		if (!dialogueEnded)
		{
			dlgText.skip();
			return;
		}
		
		if (inPostDialogue)
		{
			postDialogueIndex++;
			if (postDialogueIndex < postDialogueLines.length)
			{
				beginLine(postDialogueLines, postDialogueIndex);
			}
			else
			{
				dialogueActive = false;
				inPostDialogue = false;
				cameraUnlocked = true;
				FlxTween.tween(dlgOverlay, {alpha: 0}, 0.25,
					{
						ease: FlxEase.quadOut,
						onComplete: function(_) {
							dlgOverlay.visible = false;
						}
					});
				FlxTween.tween(dlgText, {alpha: 0}, 0.2, {ease: FlxEase.quadOut});
				FlxTween.tween(dlgYesBro, {alpha: 0}, 0.2);
			}
			return;
		}
		
		dialogueIndex++;
		if (dialogueIndex < dialogueLines.length)
		{
			beginLine(dialogueLines, dialogueIndex);
			return;
		}
		
		// dialogue finished, reveal the room
		dialogueActive = false;
		FlxTween.tween(dlgBlackScreen, {alpha: 0}, 2.5,
			{
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					remove(dlgBlackScreen);
					crossfadeMusic('amb', 2.5, 0.6);
				}
			});
		FlxTween.tween(dlgOverlay, {alpha: 0}, 1.5,
			{
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					dlgOverlay.visible = false;
				}
			});
		FlxTween.tween(dlgText, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(dlgYesBro, {alpha: 0}, 0.2);
		FlxTween.tween(camTarget, {alpha: 1}, 2.5,
			{
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					startPostDialogue();
				}
			});
	}
	
	function showMonitorMessage(text:String)
	{
		monitorDialogueActive = true;
		dialogueEnded = false;
		FlxTween.cancelTweensOf(dlgYesBro);
		dlgYesBro.alpha = 0;
		rtlFullText = text;
		if (rtlMode)
		{
			rtlDisplayText.text = '';
		}
		
		dlgOverlay.visible = true;
		dlgOverlay.alpha = 1;
		dlgText.alpha = 1;
		
		dlgText.completeCallback = function() {
			dialogueEnded = true;
			if (rtlMode)
			{
				rtlDisplayText.text = formatArabicDialogueText(rtlFullText);
				Lang.arabicTextFix(rtlDisplayText);
			}
			FlxTween.tween(dlgYesBro, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
		};
		dlgText.resetText(text);
		dlgText.start(0.045, true);
	}
	
	function formatArabicDialogueText(source:String):String
	{
		if (!rtlMode || source == null || source.length < 1 || rtlWrapMeasure == null) return source;
		
		var wrappedLines:Array<String> = [];
		for (paragraph in source.split("\n"))
		{
			if (paragraph.trim().length < 1)
			{
				wrappedLines.push("");
				continue;
			}
			
			var words = paragraph.split(" ");
			var currentLine:String = "";
			for (i in 0...words.length)
			{
				var word = words[words.length - 1 - i];
				var candidate = (currentLine.length > 0) ? (word + " " + currentLine) : word;
				rtlWrapMeasure.text = candidate;
				if (currentLine.length > 0 && rtlWrapMeasure.textField.numLines > 1)
				{
					wrappedLines.unshift(currentLine);
					currentLine = word;
				}
				else currentLine = candidate;
			}
			wrappedLines.unshift(currentLine);
		}
		rtlWrapMeasure.text = "";
		return wrappedLines.join("\n");
	}
	
	function openComputer()
	{
		if (passwordActive) return;
		
		FlxG.sound.play(Paths.sound('computerOpen'));
		crossfadeMusic('cpu', 0.35, 0.6);
		passwordActive = true;
		vhsOn = true;
		applyCameraFilters();
		passwordReady = false;
		enteredCode = "";
		glowHovering = false;
		
		FlxTween.cancelTweensOf(glow);
		glow.alpha = 0;
		
		if (compPanel == null) buildComputerUI();
		layoutPC();
		
		setComputerUIVisible(false);
		compPanel.alpha = 1;
		compTitle.alpha = 1;
		compInput.alpha = 1;
		compCursor.alpha = 1;
		compStatus.alpha = 1;
		compImage.visible = false;
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		
		compTitle.text = Lang.str('weirdroute7');
		compStatus.text = "";
		compInput.text = "";
		cursorTimer = 0;
		cursorVisible = true;
		
		FlxTween.cancelTweensOf(FlxG.camera);
		screenZooming = true;
		tweenDepth(0.0, 0.6);
		
		FlxTween.tween(FlxG.camera, {zoom: 4.1}, 0.45,
			{
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					screenZooming = false;
					compBg.visible = true;
					compPanel.visible = true;
					compTitle.visible = true;
					compInput.visible = true;
					compCursor.visible = true;
					compStatus.visible = true;
					if (hintTextA != null) hintTextA.visible = true;
					
					compStatic.visible = true;
					compStatic.alpha = 1;
					compStatic.animation.play('play');
					FlxTween.tween(compStatic, {alpha: 0}, 0.55,
						{
							ease: FlxEase.quadIn,
							startDelay: 0.3,
							onComplete: function(_) {
								compStatic.visible = false;
								passwordReady = true;
							}
						});
				}
			});
	}
	
	function closeComputer()
	{
		FlxG.sound.play(Paths.sound('computerclose'));
		crossfadeMusic('amb', 0.35, 0.6);
		passwordActive = false;
		vhsOn = false;
		applyCameraFilters();
		enteredCode = "";
		inputCooldown = 0;
		cursorTimer = 0;
		cursorVisible = true;
		
		FlxTween.cancelTweensOf(FlxG.camera);
		screenZooming = true;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.25,
			{
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					screenZooming = false;
				}
			});
		tweenDepth(4.0, 0.25);
		
		compBg.visible = false;
		FlxTween.cancelTweensOf(compStatic);
		compStatic.visible = false;
		compPanel.visible = false;
		compTitle.visible = false;
		compInput.visible = false;
		compCursor.visible = false;
		compStatus.visible = false;
		compImage.visible = false;
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		if (hintTextA != null) hintTextA.visible = false;
	}
	
	function returnToComputer()
	{
		passwordActive = true;
		vhsOn = true;
		applyCameraFilters();
		showPC();
		resetPC();
	}
	
	function pauseComputer()
	{
		passwordActive = false;
		enteredCode = "";
		
		compPanel.visible = true;
		compPanel.alpha = 1;
		compTitle.visible = false;
		compInput.visible = false;
		compCursor.visible = false;
		compStatus.visible = false;
		compImage.visible = false;
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		FlxTween.cancelTweensOf(compStatic);
		compStatic.visible = false;
		compLoader.visible = false;
		if (hintTextA != null) hintTextA.visible = false;
	}
	
	function buildComputerUI()
	{
		compBg = new FlxBackdrop(Paths.image('bars/grid'));
		compBg.velocity.set(60, 0);
		compBg.scrollFactor.set(0, 0);
		compBg.cameras = [hudCam];
		compBg.visible = false;
		add(compBg);
		
		var hintStr = ClientPrefs.fnafHintCode;
		hintTextA = new FlxText(FlxG.width * 0.5, FlxG.height * 0.65, 0, hintStr, 28);
		hintTextA.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.fromRGB(0, 255, 80), "left");
		hintTextA.alpha = 0.45;
		hintTextA.scrollFactor.set(0, 0);
		hintTextA.cameras = [hudCam];
		hintTextA.visible = false;
		add(hintTextA);
		
		compImage = new FlxSprite().loadGraphic(Paths.image('bars/glow'));
		compImage.setGraphicSize(Std.int(compImage.width * 0.7));
		compImage.updateHitbox();
		compImage.scrollFactor.set(0, 0);
		compImage.cameras = [hudCam];
		compImage.visible = false;
		compImage.alpha = 0;
		add(compImage);
		
		compMusicImg = new FlxSprite().loadGraphic(Paths.image('bars/music'));
		compMusicImg.setGraphicSize(Std.int(compMusicImg.width * 0.7));
		compMusicImg.updateHitbox();
		compMusicImg.scrollFactor.set(0, 0);
		compMusicImg.cameras = [hudCam];
		compMusicImg.visible = false;
		add(compMusicImg);
		
		compPanel = new FlxSprite().loadGraphic(Paths.image('bars/desktop'));
		compPanel.setGraphicSize(FlxG.width, FlxG.height);
		compPanel.updateHitbox();
		compPanel.screenCenter();
		compPanel.scrollFactor.set(0, 0);
		compPanel.cameras = [hudCam];
		compPanel.alpha = 0;
		add(compPanel);
		
		compTitle = hudText(42, "center");
		compInput = hudText(56, "center");
		compCursor = hudText(56, "left");
		compCursor.text = "|";
		compStatus = hudText(30, "center");
		
		compMusicLabel = hudText(26, "center");
		compMusicLabel.visible = false;
		compMusicLabel.alpha = 1;
		
		compStatic = new FlxSprite();
		compStatic.frames = Paths.getSparrowAtlas('bars/static');
		compStatic.animation.addByPrefix('play', 'static', 24, true);
		compStatic.setGraphicSize(FlxG.width, FlxG.height);
		compStatic.updateHitbox();
		compStatic.screenCenter();
		compStatic.scrollFactor.set(0, 0);
		compStatic.cameras = [hudCam];
		compStatic.visible = false;
		add(compStatic);
		
		compLoader = new FlxSprite();
		compLoader.frames = Paths.getSparrowAtlas('bars/load');
		compLoader.animation.addByPrefix('play', 'load', 24, true);
		compLoader.scale.set(0.5, 0.5);
		compLoader.updateHitbox();
		compLoader.scrollFactor.set(0, 0);
		compLoader.cameras = [hudCam];
		compLoader.visible = false;
		add(compLoader);
	}
	
	function hudText(size:Int, align:String):FlxText
	{
		var t = new FlxText(0, 0, 0, "", size);
		t.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, align);
		t.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		t.scrollFactor.set(0, 0);
		t.cameras = [hudCam];
		t.alpha = 0;
		add(t);
		return t;
	}
	
	function setComputerUIVisible(vis:Bool)
	{
		for (s in [compBg, compPanel, compTitle, compInput, compCursor, compStatus])
			s.visible = vis;
		if (hintTextA != null) hintTextA.visible = vis;
	}
	
	function showPC()
	{
		layoutPC();
		setComputerUIVisible(true);
		for (s in [compBg, compPanel, compTitle, compInput, compCursor, compStatus])
			s.alpha = 1;
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		compMusicLabel.text = "";
	}
	
	function resetPC()
	{
		enteredCode = "";
		cursorTimer = 0;
		cursorVisible = true;
		inputCooldown = 0;
		
		compTitle.text = Lang.str('weirdroute7');
		compInput.text = "";
		compCursor.text = "|";
		compCursor.alpha = 1;
		compStatus.text = "";
		compStatus.color = FlxColor.WHITE;
		compStatus.alpha = 1;
		compImage.visible = false;
		compImage.alpha = 0;
		compMusicImg.visible = false;
		compMusicImg.alpha = 1;
		compMusicLabel.visible = false;
		compMusicLabel.alpha = 1;
		compMusicLabel.text = "";
		updateInputLayout();
	}
	
	function layoutPC()
	{
		if (compPanel == null) return;
		
		compPanel.setGraphicSize(FlxG.width, FlxG.height);
		compPanel.updateHitbox();
		compPanel.screenCenter();
		
		var ix = compPanel.x + compPanel.width * 0.175;
		var iy = compPanel.y + compPanel.height * 0.22;
		var iw = compPanel.width * 0.69;
		var ih = compPanel.height * 0.63;
		
		monX = ix;
		monY = iy;
		monW = iw;
		monH = ih;
		
		compTitle.fieldWidth = iw;
		compTitle.x = ix;
		compTitle.y = iy + ih * 0.10;
		
		compStatus.fieldWidth = iw;
		compStatus.x = ix;
		compStatus.y = iy + ih * 0.68;
		
		fieldY = iy + ih * 0.47;
		
		compImage.updateHitbox();
		compImage.x = ix + (iw - compImage.width) * 0.5;
		compImage.y = iy + (ih - compImage.height) * 0.5;
		
		compMusicImg.updateHitbox();
		compMusicImg.x = ix + (iw - compMusicImg.width) * 0.5;
		compMusicImg.y = iy + (ih - compMusicImg.height) * 0.5;
		compMusicLabel.fieldWidth = iw;
		compMusicLabel.x = ix;
		compMusicLabel.y = compMusicImg.y + compMusicImg.height + 50;
		
		updateInputLayout();
		
		compLoader.updateHitbox();
		compLoader.x = ix + (iw - compLoader.width) * 0.5;
		compLoader.y = iy + (ih - compLoader.height) * 0.5;
		
		#if VIDEOS_ALLOWED layoutVideo(); #end
	}
	
	function updateInputLayout()
	{
		if (compInput == null) return;
		compInput.fieldWidth = monW;
		compInput.x = monX;
		compInput.y = fieldY;
		compCursor.visible = false;
	}
	
	function showLoader()
	{
		isLoading = true;
		layoutPC();
		FlxG.sound.play(Paths.sound('click'));
		compLoader.visible = true;
		compLoader.animation.play('play');
	}
	
	function hideLoader()
	{
		isLoading = false;
		compLoader.visible = false;
	}
	
	function appendChar(ch:String)
	{
		if (enteredCode.length >= 16) return;
		enteredCode += ch;
		FlxG.sound.play(Paths.sound('type'));
	}
	
	function handlePasswordInput()
	{
		if (!passwordActive) return;
		
		cursorTimer += FlxG.elapsed;
		if (cursorTimer >= 0.45)
		{
			cursorTimer = 0;
			cursorVisible = !cursorVisible;
		}
		
		if (inputCooldown > 0)
		{
			inputCooldown -= FlxG.elapsed;
			if (inputCooldown < 0) inputCooldown = 0;
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (!passwordReady) return;
			closeComputer();
			return;
		}
		
		if (inputCooldown <= 0 && FlxG.keys.justPressed.BACKSPACE && enteredCode.length > 0)
		{
			FlxG.sound.play(Paths.sound('type'));
			enteredCode = enteredCode.substr(0, enteredCode.length - 1);
			inputCooldown = 0.06;
			cursorTimer = 0;
			cursorVisible = true;
		}
		
		if (inputCooldown <= 0 && FlxG.keys.justPressed.ENTER)
		{
			submitCode();
			inputCooldown = 0.08;
			cursorTimer = 0;
			cursorVisible = true;
		}
		
		if (inputCooldown <= 0)
		{
			var k = FlxG.keys.firstJustPressed();
			if ((k >= 65 && k <= 90) || (k >= 48 && k <= 57))
			{
				appendChar(String.fromCharCode(k));
				inputCooldown = 0.06;
				cursorTimer = 0;
				cursorVisible = true;
			}
		}
		
		compInput.text = " " + enteredCode + (cursorVisible ? "|" : " ");
		updateInputLayout();
	}
	
	function errorMessage(msg:String)
	{
		FlxTween.cancelTweensOf(compStatus);
		compStatus.text = msg;
		compStatus.color = FlxColor.RED;
		compStatus.x = monX;
		var baseX = compStatus.x;
		if (msg == "X")
		{
			FlxTween.tween(compStatus, {x: baseX + 10}, 0.03,
				{
					type: FlxTweenType.PINGPONG,
					onComplete: function(_) {
						compStatus.x = baseX;
					}
				});
			FlxTween.tween(compStatus, {alpha: 0}, 1.0, {ease: FlxEase.quadOut});
		}
		else
		{
			FlxTween.tween(compStatus, {x: baseX + 2}, 0.07,
				{
					type: FlxTweenType.PINGPONG,
					onComplete: function(_) {
						compStatus.x = baseX;
					}
				});
			FlxTween.tween(compStatus, {alpha: 0}, 0.5, {ease: FlxEase.quadOut, startDelay: 2.5});
		}
	}
	
	function submitCode()
	{
		var code = enteredCode.toUpperCase();
		FlxTween.cancelTweensOf(compStatus);
		compStatus.alpha = 1;
		compStatus.color = FlxColor.WHITE;
		compStatus.text = "";
		compImage.visible = false;
		
		switch (code)
		{
			case "DANKBARS":
				PlayState.prepareForSong('dank-bars');
				FlxG.switchState(PlayState.new);
			case "SECRET":
				playAudio("secretsong");
			case "DIRECT":
				playAudio("directwip");
			case "REACTOR":
				playAudio("reactor");
			case "FINALE":
				playAudio("finalewip");
			case "RIVALS":
				playAudio("rivals");
			case "RASPBERRY":
				playAudio("raspberry");
			case "RAID":
				playAudio("raid");
			// images
			case "CHALLENGE":
				showImage("challenge");
			case "SNEEP":
				showImage("sneep");
			case "FUNNI342":
				showImage("funni");
			case "RUBATO":
				showImage("rubato");
			case "DREAMJOB":
				showImage("dreamjob");
			case "TRIPLETROUBLE":
				showImage("trouble");
			case "STORY":
				showImage("Story");
			case "NOOB49":
				showImage("noob49");
			case "TRINKETS":
				showImage("trinkets");
			case "EBK":
				showImage("EBK");
			case "WHITEPARASITE":
				showImage("whiteparasite");
			// text ones
			case "COMMUNITYGAME":
				errorMessage("hi bro whats up");
			case "PENKARU":
				errorMessage("NO EXCLUSIVE CONTENT FOR YOU");
			case "DEFEAT":
				errorMessage(ClientPrefs.scaryDefeat ? "HELLSCAPE" : "Did you mean: #@1$!@#$?");
			case "LIGHTSDOWN":
				errorMessage("Did you mean: LIGHTSOUT?");
			case "LIGHTSOUT":
				errorMessage("Did you mean: LIGHTSOFF?");
			case "LIGHTSOFF":
				errorMessage("Did you mean: LIGHTSDOWN?");
			case "FLIPPY":
				errorMessage("Did you mean: FLIPPYFLOW?");
			case "DK":
				errorMessage("R.I.P");
			
			#if VIDEOS_ALLOWED
			case "BROIMPOSTOR":
				playVideo('broimpostor');
			case "HELLSCAPE":
				if (ClientPrefs.scaryDefeat) errorMessage("FILE NOT FOUND");
				else
				{
					crashAfterVideo = true;
					playVideo('hellscape');
				}
			case "ZARED":
				if (ClientPrefs.scaryZared) errorMessage("X");
				else playFullscreenVideo('zared video');
			#end
			
			default:
				errorMessage("X");
		}
	}
	
	#if VIDEOS_ALLOWED
	// this is just for zared
	function playFullscreenVideo(key:String)
	{
		if (videoPlaying) return;
		videoPlaying = true;
		passwordActive = false;
		
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		setComputerUIVisible(false);
		compBg.visible = false;
		compImage.visible = false;
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		
		var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.scrollFactor.set(0, 0);
		black.cameras = [hudCam];
		add(black);
		
		if (secretVideo != null)
		{
			remove(secretVideo);
			secretVideo.destroy();
			secretVideo = null;
		}
		
		new FlxTimer().start(0.1, function(_) {
			if (secretVideo != null)
			{
				remove(secretVideo);
				secretVideo.destroy();
				secretVideo = null;
			}
			
			secretVideo = new FunkinVideoSprite();
			secretVideo.scrollFactor.set(0, 0);
			secretVideo.cameras = [hudCam];
			add(secretVideo);
			
			secretVideo.onFormat(() -> {
				secretVideo.antialiasing = ClientPrefs.globalAntialiasing;
				secretVideo.setGraphicSize(FlxG.width, FlxG.height);
				secretVideo.updateHitbox();
				secretVideo.screenCenter();
			});
			secretVideo.onEnd(() -> {
				if (key == 'zared video')
				{
					ClientPrefs.scaryZared = true;
					ClientPrefs.flush();
				}
				Sys.exit(0);
			});
			
			var vidPath = Paths.video(key);
			var loadPath:String = null;
			if (vidPath != null && FunkinAssets.exists(vidPath))
			{
				var bytes = FunkinAssets.getBytes(vidPath);
				if (bytes != null)
				{
					var tmp = Sys.getEnv("TEMP");
					if (tmp == null) tmp = ".";
					var dest = tmp + "/fnaf_vid_" + Paths.sanitize(key) + ".mp4";
					sys.io.File.saveBytes(dest, bytes);
					loadPath = dest;
				}
			}
			
			if (loadPath != null && secretVideo.load(loadPath))
			{
				secretVideo.delayAndStart();
			}
			else
			{
				Sys.exit(0);
			}
		});
	}
	
	// set up the video
	function layoutVideo()
	{
		if (secretVideo == null) return;
		var mw = Std.int(monW);
		var mh = Std.int(monH);
		if (mw <= 0 || mh <= 0) return;
		
		secretVideo.setGraphicSize(mw, 0);
		secretVideo.updateHitbox();
		if (secretVideo.height > monH)
		{
			secretVideo.setGraphicSize(0, mh);
			secretVideo.updateHitbox();
		}
		secretVideo.setGraphicSize(Std.int(secretVideo.width * videoScale), Std.int(secretVideo.height * videoScale));
		secretVideo.updateHitbox();
		secretVideo.x = monX + (monW - secretVideo.width) * 0.5;
		secretVideo.y = monY + (monH - secretVideo.height) * 0.5;
	}
	
	// code videos
	function playVideo(key:String)
	{
		if (videoPlaying) return;
		videoPlaying = true;
		if (key == 'hellscape' && FlxG.sound.music != null) FlxG.sound.music.stop();
		layoutPC();
		pauseComputer();
		
		showLoader();
		new FlxTimer().start(1.0, function(_) {
			hideLoader();
			
			if (secretVideo != null)
			{
				remove(secretVideo);
				secretVideo.destroy();
				secretVideo = null;
			}
			
			secretVideo = new FunkinVideoSprite();
			secretVideo.cameras = [hudCam];
			if (compPanel != null) insert(members.indexOf(compPanel), secretVideo);
			else add(secretVideo);
			
			secretVideo.onFormat(() -> {
				secretVideo.antialiasing = ClientPrefs.globalAntialiasing;
				layoutVideo();
			});
			secretVideo.onEnd(() -> {
				if (secretAudio != null)
				{
					secretAudio.stop();
					secretAudio.destroy();
					secretAudio = null;
				}
				if (secretVideo != null)
				{
					remove(secretVideo);
					secretVideo.destroy();
					secretVideo = null;
				}
				if (crashAfterVideo)
				{
					ClientPrefs.scaryDefeat = true;
					ClientPrefs.flush();
					crashAfterVideo = false;
					Sys.exit(0);
				}
				showLoader();
				new FlxTimer().start(1.0, function(_) {
					hideLoader();
					videoPlaying = false;
					returnToComputer();
				});
			});
			
			var vidPath = Paths.video(Paths.sanitize(key));
			var loadPath:String = null;
			if (vidPath != null && FunkinAssets.exists(vidPath))
			{
				var bytes = FunkinAssets.getBytes(vidPath);
				if (bytes != null)
				{
					var tmp = Sys.getEnv("TEMP");
					if (tmp == null) tmp = ".";
					var dest = tmp + "/fnaf_vid_" + Paths.sanitize(key) + ".mp4";
					sys.io.File.saveBytes(dest, bytes);
					loadPath = dest;
				}
			}
			
			var videoOptions = key == 'hellscape' ? [FunkinVideoSprite.muted] : null;
			if (loadPath != null && secretVideo.load(loadPath, videoOptions))
			{
				if (key == 'hellscape')
				{
					var stems = ['hellscape/bass', 'hellscape/drums', 'hellscape/extra', 'hellscape/melodic'];
					var chosen = stems[FlxG.random.int(0, stems.length - 1)];
					secretAudio = FunkinSound.load(Paths.sound(chosen), 1.0, false, null, false, false);
					if (secretAudio != null) secretAudio.play();
				}
				compPanel.visible = true;
				compPanel.alpha = 1;
				secretVideo.delayAndStart();
			}
			else
			{
				videoPlaying = false;
				remove(secretVideo);
				secretVideo.destroy();
				secretVideo = null;
				returnToComputer();
				trace('missing video: ' + key);
			}
		});
	}
	#end
	
	// code audios
	function playAudio(key:String)
	{
		if (audioPlaying) return;
		audioPlaying = true;
		layoutPC();
		pauseComputer();
		
		compMusicImg.visible = false;
		compMusicImg.alpha = 1;
		compMusicLabel.text = key + ".ogg";
		compMusicLabel.visible = false;
		compMusicLabel.alpha = 1;
		
		showLoader();
		new FlxTimer().start(1.0, function(_) {
			hideLoader();
			
			if (secretAudio != null)
			{
				secretAudio.stop();
				secretAudio.destroy();
				secretAudio = null;
			}
			
			secretAudio = FunkinSound.load(Paths.sound(Paths.sanitize(key)), 1.0, false, null, false, false, null, function() {
				if (secretAudio != null)
				{
					secretAudio.destroy();
					secretAudio = null;
				}
				compMusicImg.visible = false;
				compMusicLabel.visible = false;
				showLoader();
				new FlxTimer().start(1.0, function(_) {
					hideLoader();
					audioPlaying = false;
					returnToComputer();
				});
			});
			
			if (secretAudio != null)
			{
				compMusicImg.visible = true;
				compMusicLabel.visible = true;
				secretAudio.play();
			}
			else
			{
				audioPlaying = false;
				compMusicImg.visible = false;
				compMusicLabel.visible = false;
				returnToComputer();
				trace('missing audio: ' + key);
			}
		});
	}
	
	function stopAudioAndReturn()
	{
		if (!audioPlaying) return;
		if (secretAudio != null)
		{
			secretAudio.stop();
			secretAudio.destroy();
			secretAudio = null;
		}
		compMusicImg.visible = false;
		compMusicLabel.visible = false;
		showLoader();
		new FlxTimer().start(1.0, function(_) {
			hideLoader();
			audioPlaying = false;
			returnToComputer();
		});
	}
	
	// code images
	function showImage(imageKey:String)
	{
		imageTransitioning = true;
		imageShowing = false;
		passwordActive = false;
		pauseComputer();
		
		compMusicLabel.text = imageKey + ".png";
		compMusicLabel.visible = false;
		compMusicLabel.alpha = 1;
		
		showLoader();
		new FlxTimer().start(1.0, function(_) {
			hideLoader();
			compImage.loadGraphic(Paths.image('bars/secret/' + imageKey));
			compImage.visible = true;
			compImage.alpha = 1;
			compMusicLabel.visible = true;
			layoutPC();
			imageShowing = true;
			imageTransitioning = false;
		});
	}
	
	function hideImageAndReturn()
	{
		if (!imageShowing) return;
		imageTransitioning = true;
		imageShowing = false;
		compImage.visible = false;
		compMusicLabel.visible = false;
		showLoader();
		new FlxTimer().start(1.0, function(_) {
			hideLoader();
			returnToComputer();
			imageTransitioning = false;
		});
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (hintTextA != null && hintTextA.visible)
		{
			hintTextA.x += 60 * elapsed;
			if (hintTextA.x > FlxG.width) hintTextA.x = -hintTextA.width;
		}
		
		if (imageTransitioning)
		{
			tickVHS();
			return;
		}
		
		if (isLoading)
		{
			tickVHS();
			return;
		}
		
		if (imageShowing)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				hideImageAndReturn();
				return;
			}
			tickVHS();
			return;
		}
		
		if (audioPlaying)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.play(Paths.sound('type'));
				stopAudioAndReturn();
				return;
			}
			tickVHS();
			return;
		}
		
		tickVHS();
		
		if (rtlMode && rtlDisplayText != null)
		{
			rtlDisplayText.alpha = dlgText.alpha;
			if (rtlFullText.length > 0)
			{
				var ftLen = dlgText.text.length;
				if (ftLen > 0)
				{
					if (ftLen > rtlFullText.length) ftLen = rtlFullText.length;
					var startIndex = rtlFullText.length - ftLen;
					if (startIndex < 0) startIndex = 0;
					rtlDisplayText.text = formatArabicDialogueText(rtlFullText.substring(startIndex));
					Lang.arabicTextFix(rtlDisplayText);
				}
				else rtlDisplayText.text = '';
			}
			else rtlDisplayText.text = '';
			rtlDisplayText.updateHitbox();
		}
		
		// dialogue advance
		var keyDown = FlxG.keys.pressed.ENTER || FlxG.keys.pressed.SPACE;
		var keyEdge = keyDown && !advanceKeyHeld;
		var mouseDown = FlxG.mouse.pressed;
		var mouseEdge = mouseDown && !advanceMouseHeld;
		
		if (monitorDialogueActive && (keyEdge || mouseEdge))
		{
			if (!dialogueEnded) dlgText.skip();
			else
			{
				monitorDialogueActive = false;
				FlxTween.tween(dlgOverlay, {alpha: 0}, 0.25,
					{
						ease: FlxEase.quadOut,
						onComplete: function(_) {
							dlgOverlay.visible = false;
						}
					});
				FlxTween.tween(dlgText, {alpha: 0}, 0.2, {ease: FlxEase.quadOut});
				FlxTween.tween(dlgYesBro, {alpha: 0}, 0.2);
				clickCooldown = 1.0;
			}
		}
		
		if (!monitorDialogueActive && dialogueActive && (keyEdge || mouseEdge))
		{
			advanceDialogue();
			clickCooldown = 1.0;
		}
		
		advanceKeyHeld = keyDown;
		advanceMouseHeld = mouseDown;
		
		if (clickCooldown > 0) clickCooldown -= elapsed;
		
		handlePasswordInput();
		if (passwordActive) return;
		
		glow.x = camTarget.x + camTarget.width / 2 - glow.width / 2;
		glow.y = camTarget.y + camTarget.height / 2 - glow.height / 2 - 22.5;
		
		leftscreen.x = camTarget.x + camTarget.width / 2 - leftscreen.width / 2 - 435;
		leftscreen.y = camTarget.y + camTarget.height / 2 - leftscreen.height / 2 + 22;
		
		rightscreen.x = camTarget.x + camTarget.width / 2 - rightscreen.width / 2 + 430;
		rightscreen.y = camTarget.y + camTarget.height / 2 - rightscreen.height / 2 - 76;
		
		if (!cameraUnlocked || camTarget == null || camTarget.alpha <= 0 || monitorDialogueActive) return;
		
		// esc to leave
		if (!exiting && !videoPlaying && !screenZooming && FlxG.keys.justPressed.ESCAPE)
		{
			exiting = true;
			var fade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			fade.scrollFactor.set(0, 0);
			fade.cameras = [hudCam];
			fade.alpha = 0;
			add(fade);
			if (FlxG.sound.music != null) FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.5);
			FlxTween.tween(fade, {alpha: 1}, 0.5,
				{
					ease: FlxEase.quadOut,
					onComplete: function(_) {
						FlxG.sound.music.stop();
						FlxG.sound.music = null;
						
						FlxG.switchState(MainMenuState.new);
					}
				});
			return;
		}
		
		// camera pan
		var mx = FlxG.mouse.x / FlxG.width;
		var my = FlxG.mouse.y / FlxG.height;
		var bx = (FlxG.width - camTarget.width) * 0.5;
		var by = (FlxG.height - camTarget.height) * 0.5;
		camTarget.x += (bx + (mx - 0.5) * 2 * -camRangeX - camTarget.x) * camDrag;
		camTarget.y += (by + (my - 0.5) * 2 * -camRangeY - camTarget.y) * camDrag;
		
		// room clicks
		if (!videoPlaying && !screenZooming && !monitorDialogueActive && clickCooldown <= 0 && FlxG.mouse.justPressed)
		{
			if (glow != null && glow.overlapsPoint(FlxG.mouse.getWorldPosition()))
			{
				openComputer();
				return;
			}
			if (leftscreen != null && leftscreen.overlapsPoint(FlxG.mouse.getWorldPosition()))
			{
				showMonitorMessage(Lang.str('weirdroute5'));
				clickCooldown = 0.5;
				return;
			}
			if (rightscreen != null && rightscreen.overlapsPoint(FlxG.mouse.getWorldPosition()))
			{
				showMonitorMessage(Lang.str('weirdroute6'));
				clickCooldown = 0.5;
				return;
			}
		}
		
		glowHovering = updateHover(glow, glowHovering, 0.75);
		leftscreenHovering = updateHover(leftscreen, leftscreenHovering, 0.3);
		rightscreenHovering = updateHover(rightscreen, rightscreenHovering, 0.3);
	}
	
	function updateHover(spr:FlxSprite, wasHovering:Bool, peak:Float):Bool
	{
		var hovering = spr.overlapsPoint(FlxG.mouse.getWorldPosition());
		if (hovering != wasHovering)
		{
			FlxTween.cancelTweensOf(spr);
			FlxTween.tween(spr, {alpha: hovering ? peak : 0}, hovering ? 0.2 : 0.1, {ease: FlxEase.quadOut});
		}
		return hovering;
	}
	
	static function getHintCodeWeight(code:String):Float
	{
		return switch (code)
		{
			case 'DANKBARS': 1;
			case 'HELLSCAPE': 2;
			case 'ZARED': 3;
			case 'REACTOR' | 'RIVALS' | 'RASPBERRY' | 'DEFEAT' | 'COMMUNITYGAME': 4;
			case 'CHALLENGE' | 'RUBATO' | 'STORY' | 'SECRET': 6;
			default: 7;
		};
	}
	
	static function randomFromArrayWeighted(v:Array<Dynamic>, weights:Array<Float>):Dynamic
	{
		var totalWeight:Float = 0;
		for (weight in weights)
			totalWeight += weight;
		final selected:Float = FlxG.random.float(0, totalWeight);
		var count:Float = 0;
		for (i in 0...v.length - 1)
		{
			count += weights[i];
			if (selected < count) return v[i];
		}
		return v[v.length - 1];
	}
}
