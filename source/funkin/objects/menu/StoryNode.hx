package funkin.objects.menu;

import funkin.data.WeekData;
import funkin.scripts.FunkinScript;
import funkin.states.StoryMenuState;
import funkin.objects.menu.BaseNode;

class StoryNode extends BaseNode {
	public var curScript:FunkinScript;
	
	public var unlocked(default, set):Bool;
	public var meta:WeekData;
	
	public var center:FlxSprite;
	
	public var hoverDots:flixel.group.FlxSpriteGroup;
	public var hoverDotDistance:Float = 0;
	public var hoverDotRotation:Float = 0;
	var wasHovering:Bool = false;
	
	public var onClick:StoryNode -> Void = null;
	
	public function new(x:Float = 0, y:Float = 0, id:String = '', ?meta:WeekData) {
		super(x, y, id);
		this.meta = meta;
		this.connectorClass = StoryNodeConnector;
		
		hoverDots = new flixel.group.FlxSpriteGroup();
		add(hoverDots);
		
		center = new FlxSprite().loadGraphic(Paths.image('menu/story/node'));
		center.antialiasing = ClientPrefs.globalAntialiasing;
		center.y -= (center.height * .5);
		center.x -= (center.width * .5);
		add(center);
		
		for (i in 0 ... 8) {
			var dot:FlxSprite = new FlxSprite(Paths.image('menu/story/hoverDot'));
			dot.origin.y = dot.height;
			
			hoverDots.add(dot);
		}
		
		var scriptPath:String = FunkinScript.getPath('scripts/storyNodes/$id');
		
		if (FunkinAssets.exists(scriptPath)) {
			curScript = FunkinScript.fromFile(scriptPath, false);
			
			if (curScript.__garbage)
			{
				curScript = null;
			}
			else
			{
				curScript.set('StoryMenuState', StoryMenuState);
				curScript.addParent(this);
				
				curScript.tryExecute();
				curScript.executeFunc('onLoad', [], this);
			}
		}
		
		unlocked = isUnlocked();
	}
	
	public override function update(elapsed:Float):Void {
		super.update(elapsed);
		
		curScript?.executeFunc('onUpdate', [elapsed], this);
		
		updateHover(elapsed);
		
		curScript?.executeFunc('onUpdatePost', [elapsed], this);
	}
	
	public function updateHover(elapsed:Float):Void {
		final scaleMult:Float = (.5 / FlxG.camera.zoom);
		final mouseDist:Float = Math.sqrt(Math.pow(FlxG.mouse.x - center.x - center.width * .5, 2) + Math.pow(FlxG.mouse.y - center.y - center.height * .5, 2));
		final isHovering:Bool = (!selected && mouseDist < 90 * scaleMult);
		
		if (FlxG.mouse.justPressed)
			wasHovering = isHovering;
		
		if (isHovering) {
			hoverDotDistance = MathUtil.fpsLerp(hoverDotDistance, FlxG.mouse.pressed && wasHovering ? 56 : 72, .35);
			
			if (FlxG.mouse.justReleased && wasHovering && onClick != null)
				onClick(this);
		} else {
			hoverDotDistance = MathUtil.fpsLerp(hoverDotDistance, 0, .35);
		}
		
		if (hoverDotDistance <= (22 / scaleMult)) {
			if (hoverDots.alive) hoverDots.kill();
			return;
		} else if (!hoverDots.alive) {
			hoverDots.revive();
		}
		
		hoverDotRotation += (elapsed * 15);
		if (hoverDotRotation >= 360) hoverDotRotation %= 360;
		
		for (i => dot in hoverDots.members) {
			final rotation:Float = (hoverDotRotation + (i / hoverDots.length) * 360);
			final rotationRad:Float = (rotation * Math.PI / 180);
			
			dot.angle = rotation;
			
			dot.x = (center.x + center.width * .5 - (dot.width * .5) + (Math.sin(rotationRad) * hoverDotDistance * scaleMult));
			dot.y = (center.y + center.height * .5 - dot.height - (Math.cos(rotationRad) * hoverDotDistance * scaleMult));
			
			var scal:Float = (FlxMath.remapToRange(hoverDotDistance, 20, 72, .9, 1.1) * scaleMult);
			dot.scale.set(scal, scal);
		}
	}
	
	public function lockAnim():Void
	{
		hoverDotDistance = (120 * (.6 / FlxG.camera.zoom));
		
		FlxTween.cancelTweensOf(center);
		FlxTween.cancelTweensOf(hoverDots);
		FlxTween.color(center, .6, 0xffff4444, FlxColor.WHITE, {ease: FlxEase.sineOut});
		FlxTween.color(hoverDots, .6, 0xffa00000, 0xfffe3443, {ease: FlxEase.sineOut});
	}
	
	public override function onAttach(parent:BaseNode):Void {
		unlocked = unlocked;
	}
	
	public override function destroy():Void {
		curScript?.executeFunc('onDestroy', [], this);
		curScript?.destroy();
		
		super.destroy();
	}
	
	public function isUnlocked():Bool {
		var scriptResult:Dynamic = curScript?.executeFunc('isUnlocked', [], this);
		
		if (scriptResult == false || scriptResult == true) return scriptResult;
		
		return (meta != null ? (ClientPrefs.forceUnlock || !ProgressionUtil.weekIsLocked(meta.fileName)) : true);
	}
	
	function set_unlocked(now:Bool):Bool {
		if (connector != null)
			connector.alpha = (now ? 1 : .5);
		
		if (hoverDots != null)
			for (dot in hoverDots) dot.color = (now ? 0xff27cfed : 0xfffe3443);
		
		return unlocked = now;
	}
}

class StoryNodeConnector extends BaseNodeConnector {
	var LINES:Int = 3;
	
	public function new(node:StoryNode, direction:NodeDirection) {
		super(node, direction);
	}
	
	public override function makeConnector():StoryNodeConnector {
		var connectorGraphic = Paths.image('menu/story/path');
		
		var directionRad:Float = direction / 180 * Math.PI;
		var endDist:Float = (cast parent:StoryNode).center.width + connectorGraphic.width * .5;
		
		for (i in 0 ... LINES) {
			var dist:Float = FlxMath.lerp(endDist, parent.nodeDistance - endDist, i / (LINES - 1));
			
			var connector:FlxSprite = new FlxSprite(
				dist * Math.cos(directionRad),
				-dist * Math.sin(directionRad),
			).loadGraphic(connectorGraphic);
			
			connector.offset.set(connector.width * .5, connector.height * .5);
			connector.antialiasing = ClientPrefs.globalAntialiasing;
			connector.angle = direction;
			
			add(connector);
		}
		
		return this;
	}
}