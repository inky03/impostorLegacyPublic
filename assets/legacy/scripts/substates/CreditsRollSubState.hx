import funkin.Mods;

var modManager:ModManager;
var blackAtlas:FunkinSprite;
var music:FlxSound;
var prevBpm:Float = Conductor.bpm;
var title:FlxText;
var portrait:FunkinSprite;
var portraitBorder:FunkinSprite;
var thx:FlxText;
var songCredit:FlxText;
var songCreditGroup:FlxSpriteGroup;
var disc:FlxSprite;
var creditsGroup:FlxSpriteGroup;
var dtCam:FlxCamera;
var didHandleMusicEnd:Bool = false;

var hasDLC:Bool = false;
var credits:Array<CreditInfo> = [
	{image: 'credits/motorfrog', scale: .45, x: 90},
	{name: 'VS IMPOSTOR LEGACY'},
	{icon: 'clowfoe', name: 'Clowfoe'},
	{icon: 'emi3', name: 'emi3'},
	{icon: 'fllics', name: 'Fllics'},
	{icon: 'rareblin', name: 'Rareblin'},
	{icon: 'loggo', name: 'Loggo'},
	{icon: 'doodler', name: 'EthanTheDoodler'},
	{icon: 'gonk', name: 'Gonk'},
	{icon: 'squid', name: 'SquidBoy84'},
	{icon: 'fabs', name: 'Fabs'},
	{icon: 'fluffyhairs', name: 'fluffyhairs'},
	{icon: 'dazzen', name: 'Dazzen'},
	{icon: 'kricedor', name: 'Kricedor'},
	{icon: 'remi', name: 'Remi'},
	{icon: 'thales', name: 'Thales'},
	{icon: 'neato', name: 'Neato'},
	{icon: 'monotone', name: 'MonotoneDoc'},
	{icon: 'punkett', name: 'punkett'},
	{icon: 'pogo', name: 'P0g0'},
	{icon: 'igjh', name: 'IGJHSpritin'},
	{icon: 'saruky', name: 'Saruky'},
	{icon: 'doguy', name: 'Doguy'},
	{icon: 'orbyy', name: 'OrbyyOrbinaut'},
	{icon: 'croc', name: 'Graev'},
	{icon: 'aqua', name: 'Aqua'},
	{icon: 'offbi', name: 'Offbi'},
	{icon: 'ellis', name: 'EllisBros'},
	{icon: 'mayomire', name: 'Mayomire'},
	{icon: 'ghost', name: 'ghxstling'},
	{icon: 'msg', name: 'MSG'},
	{icon: 'axor', name: 'Axor the Axolotl'},
	{icon: 'vruzzen', name: 'Vruzzen'},
	{icon: 'niisan', name: 'Niisan'},
	{icon: 'biddle', name: 'Biddle3'},
	{icon: 'emihead', name: 'emihead'},
	{icon: 'kiwiquest', name: 'kiwiquest'},
	{icon: 'spaggy', name: 'Spaggy'},
	{icon: 'pip', name: 'pip'},
	{icon: 'julie', name: 'Reina'},
	{icon: 'cooper', name: 'amongusfan24'},
	{icon: 'keoni', name: 'Keoni'},
	{icon: 'keegan', name: 'Keegan'},
	{icon: 'gally', name: 'GallyCidPizza'},
	{icon: 'gibz', name: 'Gibz'},
	{icon: 'farfoxx', name: 'Farfoxx'},
	{icon: 'klutch', name: 'KlutchDJ'},
	{icon: 'ziffy', name: 'Ziffyclumper'},
	{icon: 'saster', name: 'Saster'},
	{icon: 'cval', name: 'Cval'},
	{icon: 'rozebud', name: 'Rozebud'},
	{icon: 'jads', name: 'JADS'},
	{icon: 'rivermusic', name: 'Rivermusic'},
	{icon: 'mash', name: 'MashProTato'},
	{icon: 'raitalu', name: 'Raitalu'},
	{icon: 'layologyyy', name: 'Layologyyy'},
	{icon: 'kim', name: 'Kimirittoz'},
	{icon: 'data', name: 'data5'},
	{icon: 'cam', name: 'DuskieWhy'},
	{icon: 'rod', name: 'rodreal'},
	{icon: 'jakehomys', name: 'JakeHomys'},
	{icon: 'steginite', name: 'Steginite'},
	{icon: 'db', name: 'Terdlestuff'},
	{icon: 'sussteve', name: 'sussteve'},
	{icon: 'unknown', name: 'Moonmistt'},
	{icon: 'lunaxis', name: 'Lunaxis'},
	{icon: 'philiplol', name: 'Philiplol'},
	{icon: 'top', name: 'Top 10 Awesome'},
	{icon: 'fungiwizard', name: 'FungiWizard'},
	{name: 'Localization'},
	{icon: 'flags/portuguese', name: 'Apoto'},
	{icon: 'flags/turkish', name: 'BulutMete'},
	{icon: 'flags/turkish', name: 'feresk'},
	{icon: 'flags/japan', name: 'Buruaru'},
	{icon: 'flags/french', name: 'Moon'},
	{icon: 'flags/korea', name: 'Remi'},
	{icon: 'flags/indonesian', name: 'MogusMakus'},
	{icon: 'flags/indonesian', name: 'Xena_IDFK'},
	{icon: 'flags/swedish', name: 'PurpleDerple185'},
	{icon: 'flags/swedish', name: 'Axel K.'},
	{icon: 'flags/hungarian', name: 'Remsty'},
	{icon: 'flags/thai', name: 'Wreckieboi'},
	{icon: 'flags/thai', name: 'Maxplay Games'},
	{icon: 'flags/irish', name: 'bleptical'},
	{icon: 'flags/catalan', name: 'cookie'},
	{icon: 'flags/spain', name: 'Evie'},
	{icon: 'flags/netherland', name: 'Cryfur'},
	{icon: 'flags/ukrainian', name: 'ギ (G)', font: 'jp.ttf'},
	{icon: 'flags/palestinian', name: 'GamerZone'},
	{icon: 'flags/mor', name: 'IlyasDF'},
	{icon: 'flags/egypt', name: 'AsserelrefaeyYT'},
	{icon: 'flags/norway', name: 'Hokago'},
	{icon: 'flags/chile', name: 'Kakow0'},
	{icon: 'flags/uk', name: 'Lethrial'},
	{icon: 'flags/greek', name: 'Noobaki'},
	{icon: 'flags/noogurt', name: 'noogurt'},
	{icon: 'flags/chinese', name: 'DramaCa'},
	{icon: 'flags/chinese', name: 'Yoruseri'},
	{icon: 'flags/polish', name: 'NotQuba'},
	{icon: 'flags/czech', name: 'Poiiscool'},
	{icon: 'flags/italian', name: 'Serby'},
	{icon: 'flags/serbian', name: 'BombasticTom'},
	{icon: 'flags/romanian', name: 'ywllo'},
	{icon: 'flags/danish', name: 'Certain Bubble'},
	{icon: 'flags/german', name: 'IrrationalBunches'},
	{icon: 'flags/kazakhstan', name: 'Kimirittoz'},
	{icon: 'flags/russia', name: 'Тøха'},
	{icon: 'flags/brazil', name: 'SquidBoy84'},
	{icon: 'flags/brazil', name: 'Thales'},
	{icon: 'flags/lithuania', name: 'LeNinethGames'},
	{icon: 'flags/vietnam', name: 'Kyzoro'},
	{name: 'Playtesters'},
	{icon: 'none', name: 'angel'},
	{icon: 'none', name: 'lemlem_mew'},
	{icon: 'none', name: 'Kiiismet'},
	{icon: 'none', name: 'dastardlydeacon'},
	{icon: 'none', name: 'stormz'},
	{icon: 'none', name: 'eden_essence'},
	{icon: 'none', name: 'Ruby'},
	{icon: 'none', name: 'SPG64'},
	{icon: 'none', name: 'Shelby'},
	{icon: 'none', name: 'blindedCambion'},
	{icon: 'none', name: 'Peebles'},
	{icon: 'none', name: 'Spoogynova'},
	{spacing: 60},
	{
		image: 'credits/innersloth',
		scale: .35,
		x: 108,
		spacing: -30
	},
	{size: 43, name: 'Among Us © Innersloth LLC.'}
];

var creditsHeight:Float = 0;
var centerRoll:Bool = true;

function showDoubleTroubleOverlay():Void
{
	if (dtCam == null)
	{
		dtCam = new FlxCamera();
		dtCam.bgColor = FlxColor.BLACK;
		FlxG.cameras.add(dtCam, false);
	}
	
	FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
	ClientPrefs.doubletrouble = true;
	ClientPrefs.flush();
	
	var dtIcon:FlxSprite = new FlxSprite();
	dtIcon.loadGraphic(Paths.image('icons/icon-double-trouble'));
	var iconFrameWidth:Int = Std.int(dtIcon.width * 0.5);
	dtIcon.loadGraphic(Paths.image('icons/icon-double-trouble'), true, iconFrameWidth, Std.int(dtIcon.height));
	dtIcon.animation.add('idle', [0], 0, false);
	dtIcon.animation.play('idle');
	dtIcon.camera = dtCam;
	dtIcon.scrollFactor.set();
	dtIcon.alpha = 0;
	add(dtIcon);
	
	var line0:FlxText = new FlxText(0, 0, FlxG.width, Lang.str('doubletrouble0', 'You can now play Double Trouble.'), 42);
	line0.setFormat(Paths.font('vcr.ttf'), 42, FlxColor.WHITE, 'center');
	line0.borderStyle = FlxTextBorderStyle.OUTLINE;
	line0.borderColor = FlxColor.BLACK;
	line0.borderSize = 2;
	line0.camera = dtCam;
	line0.screenCenter();
	line0.y -= 20;
	line0.alpha = 0;
	add(line0);
	
	dtIcon.screenCenter();
	dtIcon.y = line0.y - dtIcon.height - 26;
	
	var line1:FlxText = new FlxText(0, 0, FlxG.width, Lang.str('doubletrouble1', '(In the Freeplay menu! Under bonus songs!)'), 28);
	line1.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, 'center');
	line1.borderStyle = FlxTextBorderStyle.OUTLINE;
	line1.borderColor = FlxColor.BLACK;
	line1.borderSize = 2;
	line1.camera = dtCam;
	line1.screenCenter();
	line1.y = line0.y + line0.height + 10;
	line1.alpha = 0;
	add(line1);
	
	FlxTween.tween(dtIcon, {alpha: 1}, 0.8, {ease: FlxEase.quadOut});
	FlxTween.tween(line0, {alpha: 1}, 0.8, {ease: FlxEase.quadOut});
	new FlxTimer().start(3, function(_) {
		FlxTween.tween(line1, {alpha: 1}, 0.8, {ease: FlxEase.quadOut});
		
		new FlxTimer().start(10, function(_) {
			FlxTween.tween(dtIcon, {alpha: 0}, 0.45, {ease: FlxEase.quadIn});
			FlxTween.tween(line0, {alpha: 0}, 0.35, {ease: FlxEase.quadIn});
			FlxTween.tween(line1, {alpha: 0}, 0.35,
				{
					ease: FlxEase.quadIn,
					onComplete: function(_) {
						if (onFinish != null) onFinish();
						close();
					}
				});
		});
	});
}

function onLoad():Void
{
	// This will probably be reworked to have custom modded credits in the future.
	// Nigga typing like serious Samuel im crying. But yea
	if (Paths.fileExists('securitydlc/meta.json', null, PathsTestMode.LOOSE))
	{
		hasDLC = true;
		
		var insertPos:Int = credits.length - 3;
		var dlcEntries:Array<Dynamic> = [
			{name: 'DLC'},
			{icon: 'kim', name: 'Kimirittoz'},
			{icon: 'dlc', name: 'Ra_TanG'},
			{icon: 'dlc', name: 'rodreal'},
			{icon: 'dlc', name: 'vonspad'},
			{icon: 'dlc', name: 'Remi'},
			{icon: 'dlc', name: 'itz.maow'},
			{icon: 'dlc', name: 'widecod'},
			{icon: 'dlc', name: 'Kiiismet'},
			{icon: 'dlc', name: 'JakeHomys'},
			{icon: 'dlc', name: 'mikeylm2'},
			{icon: 'dlc', name: 'mango_21'},
			{icon: 'dlc', name: 'Kakow0'},
			{icon: 'dlc', name: 'emi3'},
			{icon: 'dlc', name: 'Fllics'},
			{icon: 'dlc', name: 'seotoo'},
			{icon: 'dlc', name: 'Cryfur'},
			{icon: 'dlc', name: 'Olivashko'},
			{icon: 'dlc', name: 'Dragon Bluey'},
			{icon: 'dlc', name: 'Steginite'},
			{icon: 'dlc', name: 'Crash'},
			{icon: 'dlc', name: 'Bixteus'},
			{icon: 'dlc', name: 'GamerZone'},
			{icon: 'dlc', name: 'DeepFriedBolognese'},
			{icon: 'dlc', name: 'kokosan'},
			{icon: 'dlc', name: 'GallyCidPizza'},
		];
		
		for (i in 0...dlcEntries.length)
			credits.insert(insertPos + i, dlcEntries[i]);
	}
	
	FlxG.sound.music.volume = 0;
	
	creditsGroup = new FlxSpriteGroup(60, FlxG.height);
	loadCredits();
	add(creditsGroup);
	
	blackAtlas = new FunkinSprite().loadAtlas('credits/roll/black');
	blackAtlas.kill();
	add(blackAtlas);
	
	persistentUpdate = true;
	
	modManager = new funkin.game.modchart.ModManager(game);
	modManager.registerMod('rollSize', new SubModifier('rollSize', modManager));
	modManager.registerMod('rollAlpha', new SubModifier('rollAlpha', modManager));
	modManager.registerMod('titleAlpha', new SubModifier('titleAlpha', modManager));
	
	title = add(new FlxText(0, 0, 640, 'test'));
	title.setFormat(Paths.font('impact.ttf'), 56, FlxColor.WHITE, 'center');
	title.scrollFactor.set();
	
	title.x = (FlxG.width - title.width - 48);
	
	portrait = add(new FunkinSprite(0, 0, rollImage('introA')));
	portrait.useRenderTexture = true;
	portrait.scrollFactor.set();
	portrait.screenCenter();
	
	portraitBorder = add(new FunkinSprite(0, 0, Paths.image('credits/rollBorder')));
	portraitBorder.scale.set(1280 / 1920, 1280 / 1920);
	portraitBorder.updateHitbox();
	portraitBorder.scrollFactor.set();
	portraitBorder.screenCenter();
	portraitBorder.setPosition(576, portraitBorder.y - 4);
	portraitBorder.kill();
	
	thx = add(new FlxText(0, 0, FlxG.width, ' \n \n '));
	thx.setFormat(Paths.font('impact.ttf'), 180, FlxColor.WHITE, 'center');
	thx.scrollFactor.set();
	thx.screenCenter();
	thx.active = false;
	
	songCreditGroup = add(new FlxSpriteGroup());
	songCreditGroup.scrollFactor.set();
	songCreditGroup.alpha = 0;
	songCreditGroup.y = FlxG.height - 65;
	songCreditGroup.x = FlxG.width + 40;
	
	disc = new FlxSprite(0, 0, Paths.image('credits/disc'));
	disc.setGraphicSize(50, 50);
	disc.updateHitbox();
	disc.color = 0xFF292929;
	disc.angularVelocity = 250;
	
	songCredit = new FlxText(disc.width + 10, 0, 0, '"Sussus Endus" - punkett, emihead');
	songCredit.setFormat(Paths.font('impact.ttf'), 34, 0xFF292929, 'left');
	songCredit.active = false;
	disc.y = (songCredit.height - disc.height) / 2;
	
	songCreditGroup.add(disc);
	songCreditGroup.add(songCredit);
	
	modManager.queueEase(0, 28 * 4, 'rollSize', 1080, 'linear', 0, 640);
	queueRollImage(0, 'introA');
	queueRollImage(8, 'introB');
	queueRollImage(16, 'introC');
	queueRollImage(24, 'introD');
	
	centerRoll = true;
	portrait.screenCenter();
	
	modManager.queueFuncOnce(24 * 4, function(_) camCredits.fade(FlxColor.WHITE, Conductor.crotchet / 250));
	
	modManager.queueFuncOnce(28 * 4, function(_) {
		camCredits.stopFade();
		thx.text = 'THANKS\n \n ';
		portrait.kill();
	});
	modManager.queueFuncOnce(29 * 4, function(_) thx.text = 'THANKS\nFOR\n ');
	modManager.queueFuncOnce(30 * 4, function(_) thx.text = 'THANKS\nFOR\nPLAY');
	modManager.queueFuncOnce(31 * 4, function(_) thx.text = 'THANKS\nFOR\nPLAYING');
	modManager.queueFuncOnce(32 * 4, function(_) {
		portraitBorder.revive();
		
		FlxTween.tween(thx, {y: -FlxG.height}, Conductor.crotchet / 500, {ease: FlxEase.sineIn});
		
		modManager.setValue('rollSize', 640);
		
		centerRoll = false;
		updateRoll();
		
		portrait.x = title.x;
		portrait.screenCenter(FlxAxes.Y);
		
		title.y = (portrait.y - title.height - 20);
	});
	
	modManager.queueFuncOnce(34 * 4, function(_) thx.kill());
	modManager.queueFuncOnce(34 * 4, function(_) {
		// kablammo
		songCreditGroup.alpha = 1;
		songCreditGroup.x = FlxG.width + 40;
		FlxTween.tween(songCreditGroup, {x: FlxG.width - songCreditGroup.width - 15}, Conductor.crotchet / 700, {ease: FlxEase.quadOut});
	});
	modManager.queueFuncOnce(46 * 4, function(_) FlxTween.tween(songCreditGroup, {x: FlxG.width + 50, alpha: 0}, Conductor.crotchet / 700, {ease: FlxEase.quadIn}));
	queueRollImage(34, 'greenA', '"Mira Mania"');
	queueRollImage(48, 'greenB');
	queueRollImage(64, 'greenC');
	queueRollImage(96, 'tomoA', '"Rosy Rival"');
	queueRollImage(128, 'tomoB');
	queueRollImage(160, 'yellowA', '"Airship Atrocities"');
	
	queueRollImage(192, 'black');
	modManager.queueFuncOnce(192 * 4, function(_) {
		portraitBorder.kill();
		
		portrait.addAnimByPrefix('idle', 'black idle', 24, false);
		portrait.addAnimByPrefix('jumpscare', 'black jumpscare', 24, false);
		portrait.playAnim('idle', true);
		
		modManager.setValue('rollSize', 640 * portrait.frameWidth / 1280);
		portrait.spriteOffset.set(191 * portrait.frameWidth / 1280, 80 * portrait.frameWidth / 1280);
	});
	modManager.queueFuncOnce(210 * 4, function(_) portrait.playAnim('jumpscare', true));
	modManager.queueFuncOnce(224 * 4, function(_) {
		modManager.setValue('rollSize', 640);
		
		portraitBorder.revive();
	});
	
	queueRollImage(224, 'yellowB');
	queueRollImage(256);
	queueRollImage(272, 'henryA', '"Battling the Boyfriend"');
	queueRollImage(304, 'henryB');
	queueRollImage(336, 'tittyA', '"Magmatic Monstrosity"');
	queueRollImage(368, 'tittyB', '"Humane Heartbeat"');
	queueRollImage(400, 'tittyC', '"Deadly Delusion"');
	queueRollImage(432, 'jam', '"Jorsawsee\'s Jams"');
	
	queueRollImage(528, 'outroA');
	queueRollImage(544, 'outroB');
	queueRollImage(560, 'outroC');
	queueRollImage(576, 'outroD');
	queueRollImage(592);
	
	// the scroller
	modManager.queueFuncOnce(464 * 4, function(_) portraitBorder.kill());
	
	queueRollImage(464, 'extra', '');
	
	if (hasDLC)
	{
		final oldMod:Null<String> = Mods.currentModDirectory;
		
		Mods.currentModDirectory = 'securitydlc'; // its geniuse
		
		queueRollImage(496, 'dlc');
		
		Mods.currentModDirectory = oldMod;
	}
		
	modManager.queueFuncOnce(528 * 4, function(_) {
		portrait.screenCenter(FlxAxes.Y);
		portrait.clipRect = null;
		portraitBorder.revive();
	});
	
	modManager.queueFuncOnce(592 * 4, function(_) victory());
	modManager.queueFuncOnce(604 * 4, function(_) camCredits.fade(FlxColor.BLACK, Conductor.crotchet / 1000 * 6));
	
	music = FlxG.sound.play(Paths.music('sussusEndus'), 1);
	Conductor.songPosition = 0;
	Conductor.bpmChangeMap.resize(0);
	Conductor.bpm = 150;
	
	music.time = Conductor.beatToSeconds(0);
	
	if (ClientPrefs.inDevMode) canSkip = true;
}

function victory():Void
{
	title.kill();
	portrait.kill();
	portraitBorder.kill();

	final r:Float = (1280 / 1920 * .9);
	var black:FunkinSprite = new FunkinSprite().loadAtlas('credits/black');
	
	black.scale.set(r, r);
	black.updateHitbox();
	
	black.scrollFactor.set();
	black.addAnimByPrefix('anim', 'black', 24, true);
	black.playAnim('anim');
	black.screenCenter();
	black.x += 15;
	
	var victoryGlow:FlxSprite = new FlxSprite(0, 0, Paths.image('credits/victoryGlow'));
	
	victoryGlow.scrollFactor.set();
	victoryGlow.setGraphicSize(FlxG.width, 280);
	victoryGlow.updateHitbox();
	victoryGlow.screenCenter();
	
	var backRow:FlxSprite = new FlxSprite(0, 0, Paths.image('credits/backRow'));
	
	backRow.scrollFactor.set();
	backRow.scale.set(r, r);
	backRow.updateHitbox();
	backRow.screenCenter();
	
	var shadow:FlxSprite = new FlxSprite(0, 0, Paths.image('credits/shadow'));
	
	shadow.scrollFactor.set();
	shadow.setGraphicSize(1, 720);
	shadow.updateHitbox();
	shadow.screenCenter();
	
	var shadowBlockLeft:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
	
	shadowBlockLeft.scrollFactor.set();
	shadowBlockLeft.setGraphicSize(FlxG.width * .5, 720);
	shadowBlockLeft.updateHitbox();
	
	var shadowBlockRight:FlxSprite = new FlxSprite(FlxG.width * .5).makeGraphic(1, 1, FlxColor.BLACK);
	
	shadowBlockRight.scrollFactor.set();
	shadowBlockRight.setGraphicSize(FlxG.width * .5, 720);
	shadowBlockRight.updateHitbox();
	
	add(victoryGlow);
	add(backRow);
	add(shadow);
	add(shadowBlockLeft);
	add(shadowBlockRight);
	add(black);
	
	var victory:FlxText = new FlxText(0, 40, 600, 'VICTORY');
	victory.setFormat(Paths.font('vcr.ttf'), 112, 0xff80ffff, 'center');
	insert(0, victory);
	victory.text = Lang.str('victory');
	victory.screenCenter(FlxAxes.X);
	victory.scrollFactor.set();
	add(victory);
	
	var thanks:FlxText = new FlxText(0, 600, 900, 'Thank you for playing!');
	thanks.setFormat(Paths.font('vcr.ttf'), 56, 0xff80ffff, 'center');
	insert(0, thanks);
	thanks.text = Lang.str('credits_thanks');
	thanks.screenCenter(FlxAxes.X);
	thanks.scrollFactor.set();
	thanks.alpha = 0;
	add(thanks);
	
	FlxTween.tween(shadow.scale, {x: r}, 3, {ease: FlxEase.quadInOut, startDelay: .5});
	FlxTween.tween(shadowBlockLeft, {x: -640}, 3, {ease: FlxEase.quadInOut, startDelay: .5});
	FlxTween.tween(shadowBlockRight, {x: FlxG.width * .5 + 640}, 3, {ease: FlxEase.quadInOut, startDelay: .5});
	FlxTween.tween(thanks, {y: 560}, 6, {ease: FlxEase.circOut, startDelay: 1});
	FlxTween.tween(thanks, {alpha: .7}, 4, {startDelay: 1});
	FlxTween.tween(victory, {y: 50}, 7, {ease: FlxEase.sineOut});
	
	camCredits.fade(FlxColor.BLACK, 2, true);
}

function loadCredits():Void
{
	for (sprite in creditsGroup)
		sprite.destroy();
		
	creditsGroup.clear();
	
	var y:Float = 0;
	for (credit in credits)
	{
		var creditCluster:FlxSpriteGroup = creditsGroup.add(new FlxSpriteGroup(credit.x, y));
		
		if (credit.image != null)
		{
			var image:FlxSprite = creditCluster.add(new FlxSprite(0, 0, Paths.image(credit.image, null, null, PathsTestMode.LOOSE)));
			
			image.scale.set(credit.scale ?? 1, credit.scale ?? 1);
			image.updateHitbox();
			
			y += (image.height + (credit.spacing ?? 0));
			
			continue;
		}
		
		final isTitle:Bool = (credit.icon == null);
		
		if (isTitle && y > 0)
		{
			creditCluster.y += 60;
			y += 60;
		}
		
		if (credit.name != null)
		{
			var text:FlxText = creditCluster.add(new FlxText(0, 0, 0, credit.name));
			text.setFormat(Paths.font(credit.font ?? 'impact.ttf'), credit.size ?? (isTitle ? 56 : 40), FlxColor.WHITE);
			text.active = false;
		}
		
		var hasIcon:Bool = (credit.icon != null && credit.icon.toLowerCase() != 'none');
		if (hasIcon)
		{
			var isFlagIcon:Bool = (credit.icon.indexOf('flags/') == 0);
			var iconPath:String = 'credits/icons/' + credit.icon;
			if (isFlagIcon) iconPath = 'credits/icons/flags/' + credit.icon.substr(6);
			
			final iconExists:Bool = Paths.fileExists('images/$iconPath.png', null, PathsTestMode.LOOSE);
			var icon:FlxSprite = new FlxSprite(0, 0, Paths.image(iconExists ? iconPath : 'credits/icons/unknown', null, null, PathsTestMode.LOOSE));
			
			icon.visible = iconExists;
			icon.shader = newShader('outline2');
			icon.scale.set(isFlagIcon ? .5 : .5, isFlagIcon ? .5 : .5);
			icon.updateHitbox();
			
			for (member in creditCluster)
				member.x += Math.round(icon.width + 10);
			icon.y = Math.round((creditCluster.height - icon.height) * .5);
			
			creditCluster.add(icon);
			icon.active = false;
		}
		
		y += (credit.spacing ?? (isTitle ? 90 : 70));
	}
	
	creditsHeight = creditsGroup.height;
}

function rollImage(image:String):Null<FlxGraphic>
{
	var rollPath:String = ('credits/roll/' + image);
	var graphic:Null<FlxGraphic> = (Paths.fileExists('images/' + rollPath + '.png') ?
		{/*trace('load roll image ' + image);*/ Paths.image(rollPath);} : null);
	
	return graphic;
}

function queueRollImage(beat:Float, ?image:String, ?titleName:String):Void
{
	var graphic:Null<FlxGraphic> = (image != null ? rollImage(image) : null);
	
	final step:Float = (beat * 4);
	
	modManager.queueEase(step - 6, step, 'rollAlpha', 0, 'linear', 0);
	
	if (titleName != null || image == null) modManager.queueEase(step - 6, step, 'titleAlpha', 0, 'linear', 0);
	
	if (image != null)
	{
		if (titleName != null)
		{
			modManager.queueFuncOnce(step, function(_) title.text = titleName);
			
			modManager.queueEase(step, step + 6, 'titleAlpha', 1, 'linear', 0);
		}
		
		modManager.queueFuncOnce(step, function(_) {
			if (graphic != null)
			{
				portrait.loadGraphic(graphic);
			}
			else
			{
				portrait.loadAtlas('credits/roll/' + image);
			}
			
			updateRoll();
			
			portrait.spriteOffset.set();
			portrait.revive();
		});
		
		modManager.queueEase(step, step + 6, 'rollAlpha', 1, 'linear', 0);
	}
}

function onUpdate(elapsed:Float):Void
{
	if (ClientPrefs.inDevMode)
	{
		if (FlxG.keys.justPressed.RIGHT)
		{
			music.time = Conductor.beatToSeconds(Math.floor(curDecBeat / 16 + 1) * 16);
		}
		else if (FlxG.keys.justPressed.LEFT)
		{
			music.time = Math.max(Conductor.beatToSeconds(Math.ceil(curDecBeat / 16 - 1.25) * 16), 0);
		}
	}
	
	Conductor.songPosition += (elapsed * 1000);
	if (Math.abs(Conductor.songPosition - music.time) > 1000 / 60) Conductor.songPosition = music.time;
}

function onUpdatePost(elapsed:Float):Void
{
	var beat:Float = Conductor.crotchet;
	
	camCredits.scroll.y = FlxMath.remapToRange(Conductor.songPosition, beat * 30, beat * 592, 0, creditsHeight
		+ camCredits.height);
	
	if (hasDLC)
	{
		// look im just lazy im sorry :<
		
		if (Conductor.songPosition >= beat * 464 && Conductor.songPosition < beat * 496)
		{
			portrait.y = FlxMath.remapToRange(Conductor.songPosition, beat * 464, beat * 496, 56, FlxG.height - portrait.height - 48);
		}
		else if (Conductor.songPosition >= beat * 496 && Conductor.songPosition < beat * 528)
		{
			portrait.y = FlxMath.remapToRange(Math.min(Conductor.songPosition, beat * 524), beat * 496, beat * 524, 56, FlxG.height - portrait.height - 48);
		}
	}
	else if (Conductor.songPosition >= beat * 464 && Conductor.songPosition < beat * 528)
	{
		portrait.y = FlxMath.remapToRange(Math.min(Conductor.songPosition, beat * 524), beat * 464, beat * 524, 56, FlxG.height - portrait.height - 48);
	}
	
	if (Conductor.songPosition >= beat * 464 && Conductor.songPosition < beat * 528)
	{
		portrait.clipRect ??= new flixel.math.FlxRect();
		
		var offset:Float = ((48 - portrait.y) / portrait.scale.y);
		portrait.clipRect.set(0, offset, portrait.frameWidth, (FlxG.height - 96) / portrait.scale.y);
	}
	
	modManager.updateTimeline(curDecStep);
	modManager.update(elapsed);
	
	updateRoll();
	
	if (!music.playing && !didHandleMusicEnd)
	{
		didHandleMusicEnd = true;
		if (ClientPrefs.doubletrouble || canSkip)
		{
			if (onFinish != null) onFinish();
			close();
		}
		else
		{
			showDoubleTroubleOverlay();
		}
	}
}

function onDestroy():Void
{
	music.stop();
	
	Conductor.bpm = prevBpm;
	
	if (dtCam != null)
	{
		FlxG.cameras.remove(dtCam, true);
		dtCam = null;
	}
}

function updateRoll():Void
{
	title.alpha = modManager.getValue('titleAlpha', 0);
	
	portrait.alpha = modManager.getValue('rollAlpha', 0);
	portrait.setGraphicSize(modManager.getValue('rollSize', 0));
	
	if (!centerRoll) portrait.updateHitbox();
}
