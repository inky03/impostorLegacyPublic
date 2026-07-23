package funkin.scripting;

import flixel.FlxState;

import funkin.states.*;
import funkin.states.substates.*;

/**
 * Class Containing contants to be used in script to state interaction
 */
class ScriptConstants
{
	/**
	 * If returned in a script function, it's normal behavior will stop
	 */
	public static final STOP_FUNC:ScriptDispatch = Stop;
	
	/**
	 * If returned in a script function, it's normal behavior will continue
	 * 
	 * This is the regular return in a `ScriptGroup`
	 */
	public static final CONTINUE_FUNC:ScriptDispatch = Continue;
	
	/**
	 * Used in `ScriptGroup`. Stops the propagation of the function to any remaining scripts.
	 */
	public static final HALT_FUNC:ScriptDispatch = Halt;
	
	/**
	 * Used in `ScriptGroup`. Stops the normal behavior of the function and it's propagation to any remaining scripts.
	 */
	public static final CANCEL_FUNC:ScriptDispatch = Cancel;
	
	/**
	 * Gets the current state
	 * 
	 * if is in playstate and is in the gameover, the gameover will be returned
	 */
	public static inline function getInstance():FlxState
	{
		return PlayState.instance == null ? FlxG.state : PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
	
	// this is annoying .
	#if (target.static)
	static inline function isDispatch(v:Null<Any>):Bool return (v is ScriptDispatch);
	#end
	
	public static inline function stopping(v:Null<Any>):Bool
	{
		#if (target.static) if (!isDispatch(v)) return false; else #end
		
		return (v == Stop || v == Cancel);
	}
	
	public static inline function halting(v:Null<Any>):Bool
	{
		#if (target.static) if (!isDispatch(v)) return false; else #end
		
		return (v == Halt || v == Cancel);
	}
}

// heh
private enum ScriptDispatch {
	Cancel;
	Halt;
	Stop;
	Continue;
}
