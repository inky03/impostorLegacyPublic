import funkin.utils.CameraUtil;
import funkin.utils.MathUtil;
import funkin.data.FinaleState;
import funkin.data.WeekData;

var pibby:ChromaticAberration;

var finale:Bool = (ClientPrefs.finaleState == FinaleState.ACTIVE);
var midpoint:FlxPoint;
var aura:FlxSprite;

var tuffness:Float = 0;

function onLoad():Void {
	if (finale)
		meta = WeekData.weeksLoaded.get('week4Finale');
}

function onCreatePost():Void {
	if (finale) {
		add(aura = new FlxSprite(0, 0, Paths.image('menu/story/finaleAura')));
		aura.setPosition(center.x + (center.width - aura.width) * .5, center.y + (center.height - aura.height) * .5);
		aura.scale.set(2, 2);
		aura.blend = 0;
		
		pibby = CameraUtil.addShader(FlxG.camera, new funkin.game.shaders.ChromaticAbberation(0));
		
		canZoom = false;
	}
	
	midpoint = center.getMidpoint();
}

function onUpdate(elapsed:Float):Void {
	if (finale) {
		tuffness = MathUtil.fpsLerp(tuffness, Math.max(1 - (FlxMath.distanceToPoint(cruiser, midpoint) / 2200), 0), .2);
		
		pibby.amount = (tuffness * FlxG.random.float(1.1, 1.25));
		
		FlxG.camera.zoom = (.45 + Math.pow(tuffness, 2) * .45);
		FlxG.camera.shake(tuffness * .003, .05);
		camUpper.shake(tuffness * .0015, .05);
		
		FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, midpoint.x - FlxG.camera.width * .5, Math.pow(tuffness, 4) * elapsed * 2);
		FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, midpoint.y - FlxG.camera.height * .5, Math.pow(tuffness, 4) * elapsed * 2);
		FlxG.camera.followLerp = (.15 - tuffness * .15);
	}
}

function onSelect():Void {
	if (finale) weekTitle.color = FlxColor.RED;
	
	weekPlaylist.visible = false;
}

function onDeselect():Void {
	if (finale) weekTitle.color = FlxColor.WHITE;
	
	weekPlaylist.visible = true;
}

function onAccept():Void {
	if (finale) {
		lockMovement = true;
		killMembers();
		
		FlxG.sound.music.volume = 0;
		FlxG.sound.play(Paths.sound('kill'), .9);
		FlxTimer.wait(1, () -> StoryMenuState.loadWeek(meta));
	} else {
		lockMovement = true;
		openSubState(new funkin.states.substates.MissCounterSubstate(function(misses:Int) StoryMenuState.loadWeek(meta)));
	}
	
	return Function_Stop;
}