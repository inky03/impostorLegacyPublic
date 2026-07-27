function requirementIsComplete():Bool return ProgressionUtil.hasAppData('UpdogTeam');
function isSuperSecret():Bool return !requirementIsComplete();
