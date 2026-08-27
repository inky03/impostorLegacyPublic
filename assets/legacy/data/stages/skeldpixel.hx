import funkin.states.substates.PauseSubState;

var tablet:FunkinSprite;
var medbay:FunkinSprite;

var hologramShader:FunkinRuntimeShader;
var screenShader:FunkinRuntimeShader;
var petScreenShader:FunkinRuntimeShader;

function onLoad()
{
	FlxG.camera.pixelPerfectRender = true;
	
	var bg:BGSprite = new BGSprite('stages/skeld/tomongus/pixel/stars', -200, 0, 1, 1);
	bg.antialiasing = false;
	bg.setGraphicSize(Std.int(bg.width * 6));
	bg.updateHitbox();
	add(bg);
	
	var fg:BGSprite = new BGSprite('stages/skeld/tomongus/pixel/fg', -200, 0, 1, 1);
	fg.antialiasing = false;
	fg.setGraphicSize(Std.int(fg.width * 6));
	fg.updateHitbox();
	add(fg);
	
	medbay = new FunkinSprite(802, 300).loadAtlas('characters/freeplay/medbay');
	medbay.addAnimByPrefix('idle', 'medbay', 24, false);
	medbay.playAnim('idle');
	medbay.antialiasing = false;
	medbay.setGraphicSize(Std.int(medbay.width * 6));
	medbay.updateHitbox();
	medbay.zIndex = 8;
	
	tablet = new FunkinSprite(178, 336).loadAtlas('characters/freeplay/tablet');
	tablet.addAnimByPrefix('idle', 'anim', 12, true);
	tablet.playAnim('idle');
	tablet.antialiasing = false;
	tablet.setGraphicSize(Std.int(tablet.width * 6));
	tablet.updateHitbox();
	tablet.zIndex = 2;
}

function onBeatHit()
{
	if (curBeat % 2 == 0) medbay.playAnim('idle', true);
}

function onCountdownTick(tick:Int):Void
{
	if (tick % 2 == 0) medbay.playAnim('idle', true);
}

function onCreatePost()
{
	camSpecialThing([500, 475], [800, 475]);
	hasCovers = 0;
	
	if (boyfriend.getFlag('isPixel') != true)
	{
		hologramShader = newShader('stages/hologram');
		hologramShader.setFloat('phase', 0);
		
		add(medbay);
	}
	
	if (gf.getFlag('isPixel') != true)
	{
		screenShader = newShader('stages/screen');
		petScreenShader = newShader('stages/screen');
		
		add(tablet);
	}
	
	repositionPlayerHologram();
	repositionSpeakerHologram();
	
	for (character in [boyfriend, dad, gf])
	{
		character.setPosition(Math.round(character.x), Math.round(character.y));
		
		if (character.legacyOffset)
		{
			character.origin.set(Math.round(character.origin.x), Math.round(character.origin.y)); // fuck you ! fuck you ! fuck y
			character.offset.set(Math.round(character.offset.x / 6) * 6, Math.round(character.offset.y / 6) * 6);
		}
	}
	
	PauseSubState.songName = 'tomongusPause';
}

public function repositionPlayerHologram():Void
{
	if (boyfriend.getFlag('isPixel') != true)
	{
		var idleOffset = (boyfriend.animOffsets.get('idle') ?? boyfriend.animOffsets.get('danceLeft') ?? [0, 0]).copy();
		pixelateOffsets(boyfriend, idleOffset, .75);
		
		boyfriend.shader = hologramShader;
		boyfriend.scalableOffsets = false;
		boyfriend.scale.set(boyfriend.scale.x * .75, boyfriend.scale.y * .75);
		boyfriend.updateHitbox();
		boyfriend.setPosition(Math.round((boyfriend.x - idleOffset[0] - 60) * 6) / 6 - 1,
			Math.round((boyfriend.y + boyfriend.height * .125 /*my unparalleled genius*/ - idleOffset[1] - 100) * 6) / 6 - 1);
		boyfriend.useRenderTexture = true;
		
		boyfriend.playAnim(boyfriend.getAnimName(), true);
		
		hologramShader.setFloat('block', 6 / boyfriend.scale.x);
	}
}

public function repositionSpeakerHologram():Void
{
	if (gf.getFlag('isPixel') != true)
	{
		final gfRatio:Float = Math.min(290 / gf.frameWidth, 240 / gf.frameHeight);
		
		var idleOffset = (gf.animOffsets.get('idle') ?? gf.animOffsets.get('danceLeft') ?? [0, 0]).copy();
		pixelateOffsets(gf, idleOffset, gfRatio);
		
		screenShader.setFloat('block', 6 / gfRatio);
		
		gf.shader = screenShader;
		gf.useRenderTexture = true;
		gf.scale.set(gfRatio, gfRatio);
		gf.legacyOffset = false;
		gf.updateHitbox();
		gf.setPosition(
			Math.round((tablet.x + (tablet.width - 120 - gf.width) * .5) / 6) * 6,
			Math.round((tablet.y + (tablet.height - 12 - gf.height) * .5) / 6) * 6
		);
		
		gf.playAnim(gf.getAnimName(), true);
		
		if (PlayState.prevCamFollow == null) // ok
		{
			camFollow.setPosition(
				gf.getGraphicMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
				gf.getGraphicMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
			);
			FlxG.camera.snapToTarget();
		}
		
		if (pet.getFlag('isPixel') != true)
		{
			var idleOffset = (pet.animOffsets.get('idle') ?? pet.animOffsets.get('danceLeft') ?? [0, 0]).copy();
			pixelateOffsets(pet, idleOffset, pet.scale.y * gfRatio);
			
			petScreenShader.setFloat('block', 6 / pet.scale.y / gfRatio);
			
			pet.shader = petScreenShader;
			pet.useRenderTexture = true;
			pet.antialiasing = false;
			pet.scale.set(pet.scale.x * gfRatio, pet.scale.y * gfRatio);
			pet.updateHitbox();
			pet.setPosition(
				Math.round(Math.min(gf.x + gf.width - 20, tablet.x + tablet.width - 460 - pet.width) / 6) * 6,
				Math.round((gf.y + gf.height - pet.height + 4) / 6) * 6
			);
			pet.zIndex = gf.zIndex + 3;
		}
	}
	else
	{
		pet.kill();
	}
}

function pixelateOffsets(character:Character, idleOffset:Array<Float>, targetScale:Float)
{
	for (offset in character.animOffsets)
	{
		offset[0] -= idleOffset[0];
		offset[1] -= idleOffset[1];
		
		offset[0] = (Math.round(offset[0] / (character.scalableOffsets ? character.scale.x : 1) * targetScale * 6) / 6);
		offset[1] = (Math.round(offset[1] / (character.scalableOffsets ? character.scale.y : 1) * targetScale * 6) / 6);
	}
}

function onUpdate(elapsed:Float)
{
	if (hologramShader != null)
	{
		hologramShader.data.phase.value[0] += elapsed;
		hologramShader.setFloat('rand', FlxG.random.float(-1, 1));
	}
}
