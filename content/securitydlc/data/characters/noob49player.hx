function onCreatePost()
{
	var petScale:FlxPoint = new flixel.math.FlxBasePoint(pet.scale.x, pet.scale.y);
	
	if (hasPet) pet.loadPet('greypet');
	
	if (stage.curStage == 'skeldpixel')
	{
		// i guess bro
		parent.x -= 63;
		parent.y -= 46;
		
		pet.scale.set(1, 1);
		repositionSpeakerHologram();
	}

	if (curSong == 'Identity Crisis')
	{
		copyPet.loadPet('greypet');
	}
	if (curSong == 'Delusion' || curSong == 'Blackout' || curSong == 'Neurotic')
	{
		changeCharacter('noob49dark', 0);
		iconP1.changeIcon('noob49alone');
		
		if (FlxG.random.bool()) // 50%/50% easter egg
		{
			changeCharacter('minigreyopscary', 1);
			dad.x = 900;
			dad.y = 680;
		}
		
		pet.kill();
	}
	if (curSong == 'Danger' && hasPet)
	{
		petBoard.visible = true;
	}
	if (curSong == 'Triple Threat' || curSong == 'Turbulence' || gf?.curCharacter == "triplespeaker")
	{
		pet.kill();
	}
	if (curSong == 'Pinkwave' || curSong == 'Heartbeat')
	{
		greymira.alpha = 0.001;
	}
	if (curSong == 'Sauces Moogus')
	{
		gray.alpha = 0.001;
	}
	
	if (!pet.alive) iconP1.changeIcon('noob49alone');
}
