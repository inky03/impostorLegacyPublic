package funkin.scripts;

class ScriptedFlxBasic extends flixel.FlxBasic implements insanity.IScripted {}
class ScriptedFlxObject extends flixel.FlxObject implements insanity.IScripted {}
class ScriptedFlxSprite extends flixel.FlxSprite implements insanity.IScripted {}
class ScriptedFlxText extends flixel.text.FlxText implements insanity.IScripted {}

class ScriptedFlxGroup extends flixel.group.FlxGroup implements insanity.IScripted {}
class ScriptedFlxSpriteGroup extends flixel.group.FlxSpriteGroup implements insanity.IScripted {}

class ScriptedFlxState extends flixel.FlxState implements insanity.IScripted {}
class ScriptedFlxSubState extends flixel.FlxSubState implements insanity.IScripted {}

// class ScriptedFlxEmitter extends flixel.effects.particles.FlxEmitter implements insanity.IScripted {}OK this one isnt working. more work to do i guess yay!
class ScriptedFlxParticle extends flixel.effects.particles.FlxParticle implements insanity.IScripted {}
