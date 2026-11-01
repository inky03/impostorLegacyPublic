package funkin.data;

import funkin.data.ClientPrefs;
import funkin.states.StoryMenuState;
import funkin.utils.ProgressionUtil;

typedef AwardEntry =
{
	var ?mod:String;
	var id:String;
	var icon:String;
	var title:String;
	var hint:String;
	var desc:String;
	var hidden:Bool;
	var songs:Array<String>;
	var weeks:Array<String>;
};

class GameFlags
{
	static var cachedAwards:Array<AwardEntry> = [];
	
	public static var modAwards:Map<String, Array<AwardEntry>> = [];
	
	/**
		game flags menu
		used for saving information that could probably be moved to
		funkin/data/clientprefs.hx for optimization
	**/
	public static function hasAchievement(id:String)
	{
		return ClientPrefs.achievements.contains(id);
	}
	
	public static function giveAchievement(id:String):Bool
	{
		if (hasAchievement(id)) return false;
		
		ClientPrefs.achievements.push(id);
		ClientPrefs.flush();
		trace('Unlocked achievement: $id');
		return true;
	}
	
	public static function getAchievementIcon(id:String):String
	{
		for (award in getAwards())
		{
			if (award.id == id) return award.icon;
		}
		
		return id;
	}
	
	static function reloadAwards():Void
	{
		cachedAwards.resize(0);
		modAwards.clear();
		
		for (path in Paths.listPath('data/awards.json', LOOSE)) {
			final awardsData:Null<{awards: Array<Dynamic>}> = FunkinAssets.parseJson(FunkinAssets.getContent(path));
			
			if (awardsData == null) continue;
			
			final mod:String = Paths.getModFolder(path);
			final awards:Array<AwardEntry> = [for (i => award in awardsData.awards) {
				final awardID:String = (award.id ?? award.img ?? Paths.sanitize(Std.string(award.name ?? 'award_$i').toLowerCase()));
				
				{
					mod: mod,
					id: awardID,
					icon: (award.img ?? awardID),
					title: (award.name ?? awardID),
					hint: (award.hint ?? ''),
					desc: (award.desc ?? ''),
					hidden: (award.hidden == true),
					songs: [for (s in parseCSV(cast (award.songs ?? award.song))) Paths.sanitize(s)],
					weeks: [for (s in parseCSV(cast (award.weeks ?? award.week))) Paths.sanitize(s)]
				}
			}];
			
			for (award in awards) cachedAwards.push(award);
			modAwards.set(mod, awards);
		}
	}
	
	public static function getAwards(hard:Bool = false):Array<AwardEntry>
	{
		if (hard || cachedAwards.length == 0) reloadAwards();
		
		return cachedAwards;
	}
	
	public static function unlockAwardsFromJson(?currentSong:String = null, ?extraCompletedWeeks:Array<String> = null):Array<String>
	{
		final unlocked:Array<String> = [];
		final songId = currentSong != null ? Paths.sanitize(currentSong.toLowerCase()) : '';
		
		for (award in getAwards())
		{
			if (hasAchievement(award.id)) continue;
			
			final hasSongRule = award.songs.length > 0;
			final hasWeekRule = award.weeks.length > 0;
			if (!hasSongRule && !hasWeekRule) continue;
			
			var songsMet:Bool = true;
			if (hasSongRule)
			{
				for (song in award.songs)
				{
					if (songId == song) continue;
					if (Highscore.getScore(song, 1) <= 0)
					{
						songsMet = false;
						break;
					}
				}
			}
			
			var weeksMet:Bool = true;
			if (hasWeekRule)
			{
				for (week in award.weeks)
				{
					if (StoryMenuState.weekCompleted.exists(week) && StoryMenuState.weekCompleted.get(week)) continue;
					
					if (extraCompletedWeeks != null && extraCompletedWeeks.contains(week)) continue;
					
					weeksMet = false;
					break;
				}
			}
			
			if (songsMet && weeksMet && giveAchievement(award.id)) unlocked.push(award.id);
		}
		
		return unlocked;
	}
	
	static function parseCSV(?raw:String):Array<String>
	{
		if (raw == null) return [];
		
		return [for (entry in raw.split(','))
		{
			final trimmed:String = entry.trim();
			
			if (trimmed.length > 0) trimmed;
		}];
	}
	
	public static function hasFlag(id:String)
	{
		return ClientPrefs.tidbits.contains(id);
	}
	
	public static function giveFlag(id:String)
	{
		if (hasFlag(id)) return;
		
		ClientPrefs.tidbits.push(id);
		ClientPrefs.flush();
		trace('Added flag: $id');
	}
}
