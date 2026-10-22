import StringTools;
var baseX:Float = boyfriend.scale.x;
var baseY:Float = boyfriend.scale.y;
var scaleTween:FlxTween;
var dragging:Bool = false;
var dragOffsetX:Float = 0;
var dragOffsetY:Float = 0;
var velX:Float = 0;
var velY:Float = 0;
var lastMX:Float = 0;
var lastMY:Float = 0;
var baseYstage:Float = 0;

function noteMiss()
{
    if (FlxG.random.bool(50))
    {
        PlayState.instance.triggerEventNote("Alt Idle Animation", "boyfriend", "-alt");
    }
    else
    {
        PlayState.instance.triggerEventNote("Alt Idle Animation", "boyfriend", "");
    }
}
function onCreatePost()
{
    boyfriend.origin.set(boyfriend.frameWidth / 2, boyfriend.frameHeight);

    baseYstage = boyfriend.y;
    idleheight = boyfriend.height;
}

function onUpdate(elapsed:Float)
{
    if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(boyfriend))
    { 
		boyfriend.animation.play('ou', true);
        boyfriend.specialAnim = true;

        var baseX:Float = boyfriend.scale.x;
        var baseY:Float = boyfriend.scale.y;
        
        if (scaleTween != null) scaleTween.cancel();

        boyfriend.scale.set(baseX * 1.5, baseY * 0.75);

        scaleTween = FlxTween.tween(boyfriend.scale, {x: baseX, y: baseY}, 1, {
            ease: FlxEase.elasticOut
        });

        dragging = true;

        dragOffsetX = boyfriend.x - FlxG.mouse.x;
        dragOffsetY = boyfriend.y - FlxG.mouse.y;
        dragging = true;

        lastMX = FlxG.mouse.x;
        lastMY = FlxG.mouse.y;
    }

    if (FlxG.mouse.justReleased)
    {
        dragging = false;
    }

    if (dragging)
    {
        boyfriend.x = FlxG.mouse.x + dragOffsetX;
        boyfriend.y = FlxG.mouse.y + dragOffsetY;
        velX = (FlxG.mouse.x - lastMX) / elapsed;
        velY = (FlxG.mouse.y - lastMY) / elapsed;
        lastMX = FlxG.mouse.x;
        lastMY = FlxG.mouse.y;

        if (!FlxG.mouse.pressed)
        {
            dragging = false;
        }
    }
    else
    {
        var floorY:Float = baseYstage;

        velY += 3200 * elapsed;
        boyfriend.x += velX * elapsed;
        boyfriend.y += velY * elapsed;
        var leftWall:Float = -600;
        var rightWall:Float = 4000;

        if (boyfriend.x < leftWall)
        {
            FlxG.sound.play(Paths.sound('effects/boing', null, PathsTestMode.LOOSE));
            boyfriend.x = leftWall;
            velX *= -0.8;
        }
        if (boyfriend.x > rightWall)
        {
            FlxG.sound.play(Paths.sound('effects/boing', null, PathsTestMode.LOOSE));
            boyfriend.x = rightWall;
            velX *= -0.8;
        }

        velX *= 1;
        velY *= 1;
        if (boyfriend.y > floorY)
        {
            
            boyfriend.y = floorY;
            velY *= -0.75;
            velX *= 0.95;
        }
    }
}