import funkin.objects.CharacterGroup;
import funkin.FunkinAssets;

public var mom:Character;

public var bindMomNotes:Bool = true;

public var momGroup;

var layerThings:Array = [];

var oldIcon;

function onLoad()
{
	momGroup ??= new CharacterGroup(0, 0);
}

public function addMomChar(char, positions, inserts, ?playable, ?scales)
{
	playable ??= false;

	scales ??= [1, 1];

	if (layerThings == null)
	{
		layerThings.push(inserts[0]);
		layerThings.push(inserts[1]);
	}

	stage.insert(stage.members.indexOf(inserts[0]) + inserts[1], momGroup);

	mom = new Character(positions[0], positions[1], char, playable);
	mom.scale.set(scales[0], scales[1]);
	mom.updateHitbox();
	momGroup.addChar(mom);
	momGroup.parent = mom;
	startMomCharacterScript(mom.curCharacter, mom);

	if (playHUD.iconP1.characterName == oldIcon)
	{
		playHUD.iconP1.changeIcon(mom.healthIcon);
	}

	if (playHUD.iconP2.characterName == oldIcon)
	{
		playHUD.iconP2.changeIcon(mom.healthIcon);
	}

	oldIcon = mom.healthIcon;
}

public function changeMomChar(char, positions, ?playable, ?scales)
{
	playable ??= false;

	scales ??= [1, 1];

	if (mom != null)
	{
		mom.destroy();
		mom = null;
	}

	addMomChar(char, positions, [layerThings[0], layerThings[1]], playable, scales);
}

function onCountdownTick(tick:Int):Void
{
	if (mom == null || tick == 4) return;
	
	mom.onBeatHit(tick);
}

function onBeatHit():Void
{
	if (mom != null) mom.onBeatHit(curBeat);
}

function opponentNoteHitPre(note:Note):Void
{
	if (mom == null || !bindMomNotes) return;
	
	if (note.noteType == 'Opponent 2 Sing')
	{
		note.owner = mom;
	}
	else if (note.noteType == 'Both Opponents Sing')
	{
		characterSing(mom, note);
	}
}

function startMomCharacterScript(name:String, char:Character):Void
{
	var hscriptPath = FunkinScript.getPath('data/characters/$name', PathsTestMode.LOOSE);

	if (!FunkinAssets.exists(hscriptPath, 'TEXT')) hscriptPath = FunkinScript.getPath('characters/$name', PathsTestMode.LOOSE);

	if (FunkinAssets.exists(hscriptPath, 'TEXT'))
	{
		var script = initFunkinScript(hscriptPath, false, false);

		script?.set('parent', char);

		if (script?.exists('onLoad')) script.call('onLoad');
	}
}