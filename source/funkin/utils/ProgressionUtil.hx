package funkin.utils;

import funkin.data.WeekData;
import funkin.data.CosmicubeData;
import funkin.data.GameFlags;
import funkin.data.ClientPrefs;
import funkin.backend.Difficulty;

using Lambda;
using StringTools;

typedef Completion =
{
	total:Int,
	completed:Int,
	percent:Float
}

class ProgressionUtil
{ // Psych engine song formatting is shit
	static final COMPLETION_COSMICUBE:String = 'impostor';
	
	public static var allSongs(get, never):Array<String>;
	public static var allItems(get, never):Array<String>;
	
	public static var allImpostorSongs(get, never):Array<String>;
	public static var allImpostorItems(get, never):Array<String>;
	
	public static function weekIsLocked(name:String):Bool
	{
		var week:WeekData = WeekData.weeksLoaded.get(name);
		return (!StoryMenuState.weekCompleted.exists(name) && !week.startUnlocked
			&& week.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(week.weekBefore) || !StoryMenuState.weekCompleted.get(week.weekBefore)));
	}
	
	public static function weekIsClear(name:String):Bool
	{
		return StoryMenuState.weekCompleted.exists(name);
	}
	
	public static function getWeekScore(week:String, ?difficulty:Dynamic):Int
	{
		var weekFormatted:String = Paths.sanitize(week);
		
		if (difficulty == null)
		{
			return (Highscore.weekScores.get(search(Highscore.weekScores, weekFormatted)) ?? 0);
		}
		else if (difficulty is Int)
		{
			return (Highscore.weekScores.get(Highscore.formatSong(week, difficulty)) ?? 0);
		}
		else if (difficulty is String)
		{
			return (Highscore.weekScores.get(weekFormatted + Difficulty.getDifficultySuffix(difficulty)) ?? 0);
		}
		
		return 0;
	}
	
	public static function getWeekAccuracy(week:String, ?difficulty:Dynamic):Float
	{
		var data:WeekData = WeekData.weeksLoaded.get(week);
		
		if (data != null && StoryMenuState.weekCompleted.exists(week))
		{
			var percents:Float = 0;
			
			for (song in data.songs)
				percents += getSongAccuracy(song[0], difficulty);
				
			return (percents / data.songs.length);
		}
		
		return 0;
	}
	
	public static function songIsClear(song:String, ?difficulty:Dynamic):Bool
	{
		final songFormatted:String = Paths.sanitize(song);
		
		if (difficulty == null)
		{
			return (Highscore.songCompleted.get(search(Highscore.songCompleted, songFormatted)) ?? false);
		}
		else if (difficulty is Int)
		{
			return (Highscore.songCompleted.get(Highscore.formatSong(song, difficulty)) ?? false);
		}
		else if (difficulty is String)
		{
			return (Highscore.songCompleted.get(songFormatted + Difficulty.getDifficultySuffix(difficulty)) ?? false);
		}
		
		return false;
	}
	
	public static function getSongScore(song:String, ?difficulty:Dynamic):Int
	{
		final songFormatted:String = Paths.sanitize(song);
		
		if (difficulty == null)
		{
			return (Highscore.songScores.get(search(Highscore.songScores, songFormatted)) ?? 0);
		}
		else if (difficulty is Int)
		{
			return (Highscore.songScores.get(Highscore.formatSong(song, difficulty)) ?? 0);
		}
		else if (difficulty is String)
		{
			return (Highscore.songScores.get(songFormatted + Difficulty.getDifficultySuffix(difficulty)) ?? 0);
		}
		
		return 0;
	}
	
	public static function getSongAccuracy(song:String, ?difficulty:Dynamic):Float
	{
		final songFormatted:String = Paths.sanitize(song);
		
		if (difficulty == null)
		{
			return ((Highscore.songRating.get(search(Highscore.songRating, songFormatted)) ?? 0) * 100);
		}
		else if (difficulty is Int)
		{
			return ((Highscore.songRating.get(Highscore.formatSong(song, difficulty)) ?? 0) * 100);
		}
		else if (difficulty is String)
		{
			return ((Highscore.songRating.get(songFormatted + Difficulty.getDifficultySuffix(difficulty)) ?? 0) * 100);
		}
		
		return 0;
	}
	
	public static function getSongMisses(song:String, ?difficulty:Dynamic):Int
	{
		final songFormatted:String = Paths.sanitize(song);
		
		if (difficulty == null)
		{
			return (Highscore.songMisses.get(search(Highscore.songMisses, songFormatted)) ?? 0);
		}
		else if (difficulty is Int)
		{
			return (Highscore.songMisses.get(Highscore.formatSong(song, difficulty)) ?? 0);
		}
		else if (difficulty is String)
		{
			return (Highscore.songMisses.get(songFormatted + Difficulty.getDifficultySuffix(difficulty)) ?? 0);
		}
		
		return 0;
	}
	
	public static function getSongRank(song:String, ?difficulty:Dynamic):String
	{
		var accuracy:Float = getSongAccuracy(song, difficulty);
		var misses:Int = getSongMisses(song, difficulty);
		return Highscore.getLetterRank(accuracy, misses);
	}
	
	public static function songMeetsRank(song:String, rank:String, ?difficulty:Dynamic):Bool
	{
		if (rank == null || rank.trim().length == 0) return songIsClear(song, difficulty);
		
		var currentRank:String = getSongRank(song, difficulty);
		return rankValue(currentRank) >= rankValue(rank);
	}
	
	static function rankValue(rank:String):Int
	{
		if (rank == null) return 0;
		return Highscore.rankValue(rank.trim().toUpperCase());
	}
	
	static function search(map:Map<String, Dynamic>, name:String):String
	{
		for (id in map.keys())
		{
			if (id == name) return id;
			
			if (id.substring(0, id.lastIndexOf('-')) == name) return id;
		}
		
		return name;
	}
	
	public static function calculateCompletion():Completion
	{
		final TOTAL_SONGS = allSongs.length;
		final cubeItems = getItemList(COMPLETION_COSMICUBE);
		final TOTAL_COSMICUBE_ITEMS = cubeItems.length;
		final allAwards = GameFlags.getAwards();
		final TOTAL_AWARDS = allAwards.length;
		final totalItems = (TOTAL_SONGS + TOTAL_COSMICUBE_ITEMS + TOTAL_AWARDS);
		
		var completedSongs:Int = allSongs.count((song) -> songIsClear(song));
		var unlockedItems = cubeItems.count((item) -> ClientPrefs.cosmicubeUnlocks.contains(item));
		var unlockedAwards = allAwards.count((award) -> GameFlags.hasAchievement(award.id));
		
		var completed = completedSongs + unlockedItems + unlockedAwards;
		var percent = (totalItems <= 0 ? 100 : (completed / totalItems * 100));
		
		return {completed: completed, total: totalItems, percent: percent};
	}
	
	public static function calculateCubeCompletion(cubeId:String):Completion
	{
		final cubeItems = getItemList(cubeId);
		final totalItems = cubeItems.length;
		var unlockedItems = cubeItems.count((item) -> ClientPrefs.cosmicubeUnlocks.contains(item));
		var percent = (totalItems <= 0 ? 100 : (unlockedItems / totalItems * 100));
		return {completed: unlockedItems, total: totalItems, percent: percent};
	}
	
	static function get_allSongs():Array<String>
	{
		static var list:Array<String> = [];
		
		return getSongList(null, list);
	}
	
	static function get_allItems():Array<String>
	{
		static var list:Array<String> = [];
		
		return getItemList(null, list);
	}
	
	static function get_allImpostorSongs():Array<String>
	{
		static var list:Array<String> = [];
		
		return getSongList('', list);
	}
	
	static function get_allImpostorItems():Array<String>
	{
		static var list:Array<String> = [];
		
		return getItemList(list);
	}
	
	public static function getSongList(?mod:String, ?array:Array<String>, ?filter:WeekData -> Bool):Array<String>
	{
		filter ??= countsTowardCompletion;
		
		var array:Array<String> = (array ?? []);
		array.resize(0);
		
		if (WeekData.weeksList.length == 0) WeekData.reloadWeekFiles();
		
		for (week in WeekData.weeksList)
		{
			var weekData:WeekData = WeekData.weeksLoaded.get(week);
			
			if (weekData == null || (mod != null && weekData.folder != mod)) continue; // im scared
			
			if (!filter(weekData)) continue;
			
			for (song in weekData.songs)
				array.push(song[0]);
		}
		
		return array;
	}
	
	public static function getItemList(cubeId:String = 'impostor', ?array:Array<String>, ?filter:ShopItemData -> Bool):Array<String>
	{
		CosmicubeData.reload(false);
		
		filter ??= countsTowardCompletion;
		
		var array:Array<String> = (array ?? []);
		array.resize(0);
		
		for (id => cube in CosmicubeData.cosmicubeItems)
		{
			if (cubeId.length > 0 && id != cubeId) continue;
			
			for (item in cube)
			{
				if (!filter(item)) continue;
				
				array.push(item.fileName);
			}
		}
		
		return array;
	}
	
	public static function getShinies():Int
	{
		CosmicubeData.reload(false);
		
		var songs = allImpostorSongs;
		var cubeItems = CosmicubeData.cosmicubeItems.get('impostor').filter(i -> !i.completionExcluded);
		var skins = cubeItems.filter(i -> i.type == 'playerSkin' || i.type == 'speakerSkin');
		var pets = cubeItems.filter(i -> i.type == 'pet');
		var awards = GameFlags.getAwards();
		
		var count:Int = 0;
		if (songs.length > 0 && songs.filter(s -> !songIsClear(s)).length == 0) count++;
		if (skins.length > 0 && skins.filter(i -> !ClientPrefs.cosmicubeUnlocks.contains(i.fileName)).length == 0) count++;
		if (pets.length > 0 && pets.filter(i -> !ClientPrefs.cosmicubeUnlocks.contains(i.fileName)).length == 0) count++;
		if (awards.length > 0 && awards.filter(a -> !GameFlags.hasAchievement(a.id)).length == 0) count++;
		if (ClientPrefs.finaleState == COMPLETE) count++;
		
		return count;
	}
	
	public static inline function isCompletionExcluded(item:Dynamic):Bool
	{
		return (item?.completionExcluded == true);
	}
	
	public static inline function countsTowardCompletion(item:Dynamic):Bool
	{
		return !isCompletionExcluded(item);
	}
	
	public static function checkHundredAchievement():Bool
	{
		return (
			ProgressionUtil.allImpostorSongs.count(s -> !ProgressionUtil.songIsClear(s)) == 0 &&
			ProgressionUtil.allImpostorItems.count(i -> !ClientPrefs.cosmicubeUnlocks.contains(i)) == 0 &&
			GameFlags.getAwards().filter(a -> (a.id != 'the_hundred' && !GameFlags.hasAchievement(a.id))).length == 0
		);
	}
	
	public static function checkPAchievement():Bool
	{
		return (ProgressionUtil.allImpostorSongs.count(s -> ProgressionUtil.songMeetsRank(s, 'P')) >= 1);
	}
	
	public static function checkSRanksAchievement():Bool
	{
		return (ProgressionUtil.allImpostorSongs.count(s -> ProgressionUtil.songMeetsRank(s, 'S')) >= 5);
	}
	
	public static function hasAppData(folder:String = 'UpdogTeam'):Bool
	{
		final appDataPath = Sys.getEnv('AppData');
		if (appDataPath == null || appDataPath.length == 0) return false;
		
		return FileSystem.isDirectory('$appDataPath/$folder');
	}
}
