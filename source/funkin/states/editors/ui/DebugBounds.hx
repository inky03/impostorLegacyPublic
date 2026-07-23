package funkin.states.editors.ui;

class DebugBounds extends flixel.FlxObject
{
	public var target:Null<FlxSprite> = null;
	public var negativeSize:Bool = false;
	
	public var alpha:Float = 1;
	public var bgAlpha:Float = 0.0000001;
	public var color:FlxColor = FlxColor.WHITE;
	
	public var thickness:Int = 3;
	
	final top:FlxSprite;
	final left:FlxSprite;
	final right:FlxSprite;
	final bottom:FlxSprite;
	
	public final middle:FlxSprite;
	
	public function new(?target:FlxSprite, color:FlxColor = FlxColor.WHITE)
	{
		super();
		
		this.target = target;
		this.color = color;
		
		active = moves = false;
		
		top = new FlxSprite().makeGraphic(1, 1);
		left = new FlxSprite(top.graphic);
		right = new FlxSprite(top.graphic);
		bottom = new FlxSprite(top.graphic);
		middle = new FlxSprite(top.graphic);
		
		top.active = left.active = right.active = bottom.active = middle.active = false;
	}
	
	public override function getHitbox(?rect)
	{
		rect ??= flixel.math.FlxRect.get();
		
		return rect.set(x + Math.min(width, 0), y + Math.min(height, 0), Math.abs(width), Math.abs(height));
	}
	
	function updateBounds():Bool
	{
		final cameras = (target?.getCameras() ?? getCameras());
		final targetBounds = (target?.getGraphicBounds() ?? getHitbox());
		
		if (targetBounds.width <= 0 || targetBounds.height <= 0) return false;
		
		final thickness:Float = (thickness / cameras[0].zoom);
		
		// set the cameras
		middle.cameras = top.cameras = left.cameras = right.cameras = bottom.cameras = cameras;
		
		// set the sizes
		top.setGraphicSize(targetBounds.width + (thickness * 2), thickness);
		top.updateHitbox();
		
		left.setGraphicSize(thickness, targetBounds.height + thickness);
		left.updateHitbox();
		
		right.setGraphicSize(thickness, targetBounds.height + thickness);
		right.updateHitbox();
		
		bottom.setGraphicSize(targetBounds.width, thickness);
		bottom.updateHitbox();
		
		middle.setGraphicSize(targetBounds.width, targetBounds.height);
		middle.updateHitbox();
		
		// position em
		top.x = targetBounds.x - thickness;
		top.y = targetBounds.y - thickness;
		
		left.x = targetBounds.x - thickness;
		left.y = targetBounds.y;
		
		bottom.x = targetBounds.x;
		bottom.y = targetBounds.bottom;
		
		right.x = targetBounds.right;
		right.y = targetBounds.y;
		
		middle.x = targetBounds.x;
		middle.y = targetBounds.y;
		
		middle.alpha = ((top.alpha = right.alpha = left.alpha = bottom.alpha = alpha) * bgAlpha);
		
		middle.color = top.color = right.color = left.color = bottom.color = color;
		
		targetBounds.put();
		
		return true;
	}
	
	override function draw()
	{
		if (!visible || !updateBounds()) return;
		
		middle.draw();
		top.draw();
		left.draw();
		right.draw();
		bottom.draw();
	}
	
	override function destroy()
	{
		FlxDestroyUtil.destroy(top);
		FlxDestroyUtil.destroy(left);
		FlxDestroyUtil.destroy(right);
		FlxDestroyUtil.destroy(bottom);
		FlxDestroyUtil.destroy(middle);
		
		super.destroy();
	}
	
	override function setSize(width:Float, height:Float):Void
	{
		if (negativeSize) return super.setSize(width, height);
		
		this.width = Math.max(1, width);
		this.height = Math.max(1, height);
	}
}
