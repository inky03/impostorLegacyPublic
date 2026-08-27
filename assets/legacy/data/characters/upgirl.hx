// Character scripts are basically the same as stage scripts so lol

using StringTools;

function onCreatePost()
{
	onSectionHit(0);
}

function onSectionHit()
{
	var suffix:String = (mustHitSection ? '' : '-left');
	if (gf.curCharacter == 'upgirl')
	{
		if (gf.idleSuffix != suffix) // making sure shes not already looking in the direction we want
		{
			if (gf.getAnimName().startsWith('dance'))
				gf.playAnim('turn$suffix', true);
			
			gf.idleSuffix = suffix;
			gf.recalculateDanceIdle();
			gf.danced = false; // fuck my gay life
		}
	}
}
