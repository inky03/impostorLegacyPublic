import funkin.states.substates.AttackCharSelectSubstate;

function onAccept() {
    openSubState(new AttackCharSelectSubstate());
    FlxG.state.persistentUpdate = false;
    return Function_Stop;
}