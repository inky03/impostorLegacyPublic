using StringTools;

public var bfLegs:Character;
var legs:Character;
var bfAnchorPoint:Array<Float> = [0, 0];
var legPosY = [7, 7, 4, 4, -5, -5, -7, -7, -3, -3, 7, 7, 4, 4, -5, -5, -7, -7, -3, -3];

function onLoad():Void
{
	bfLegs = legs = new Character(0, 0, parent.curCharacter, true);
	boyfriendGroup.insert(0, legs);
	
	legs.animation.pause();
	setLegsAnim('legs');
}

function onCreatePost():Void
{
	bfAnchorPoint[0] = legs.x = parent.x;
	bfAnchorPoint[1] = legs.y = parent.y;
	parent.flipX = parent.baseFlipX = false;
}

function onUpdatePost(elapsed):Void
{
	if (!parent.getAnimName().contains('miss') && legs.getAnimName() == 'legs-miss') setLegsAnim('legs');
	
	legs.animCurFrame = Math.floor(FlxMath.mod(curDecBeat, 2) / 2 * legs.animation.curAnim.numFrames);
	if (parent.animation.curAnim.looped)
	{
		parent.animation.curAnim.pause();
		parent.animCurFrame = Math.min(legs.animCurFrame, parent.animation.curAnim.numFrames - 1);
	}
	
	parent.y = (bfAnchorPoint[1] + legPosY[legs.animCurFrame]);
	legs.setPosition(bfAnchorPoint[0], bfAnchorPoint[1]);
}

// This changes the legs from the normal version to the miss version and makes sure it starts on the same animation frame where it left off
function noteMiss(daNote:Note):Void
{
	setLegsAnim('legs');
	
	new FlxTimer().start(1 / 24, function() setLegsAnim('legs-miss'));
}

function setLegsAnim(anim:String):Void
{
	var lastFrame:Int = legs.animCurFrame;
	legs.playAnim(anim, true);
	legs.animCurFrame = lastFrame;
}
