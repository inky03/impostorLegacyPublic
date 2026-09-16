import funkin.states.substates.MissCounterSubstate;
import funkin.states.FreeplayState;

function onAccept() {
    openSubState(new MissCounterSubstate(function(misses:Int) FreeplayState.loadSong(meta[0])));
    FlxG.state.persistentUpdate = false;
    return Function_Stop;
}
