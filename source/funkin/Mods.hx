package funkin;

import haxe.Json;
import haxe.DynamicAccess;

import lime.graphics.Image;

import openfl.utils.Assets;

import funkin.states.transitions.*;

// modified from modern psych
// much love okay

/**
 * Struct defining a mod
 */
typedef ModMeta =
{
	/**
	 * The displayed name of the mod
	 */
	var name:String;
	
	/**
	 * If true, this mod will be enabled along side the current loaded mod
	 */
	var global:Bool;
	
	/**
	 * The description of the credit
	 */
	var description:String;
	
	/**
	 * Optional custom discord ID
	 */
	var ?discordClientID:String;
	
	/**
	 * Optional custom title for the application
	 */
	var ?windowTitle:String;
	
	/**
	 * Optional path to a icon to be used for the application
	 */
	var ?iconFile:String;
	
	/**
	 * Optional path to a transition state to be used by default
	 */
	var ?defaultTransition:String; // 50 / 50 on this idunno
	
	/**
	 * Optional map of state overrides.
	 * 
	 * Any state added here will be redirected to your custom state
	 * 
	 * Usage:
	 * ```json
	 *     "stateRedirects": 
	 *      {
	 *          "TitleState": "myCustomState"
	 *      }
	 * ```
	 */
	var ?stateRedirects:DynamicAccess<String>;
	
	/**
	 * Optional font that will replace most seen text in the game.
	 */
	var ?defaultFont:String;
}

class Mods
{
	/**
	 * The current primary loaded mod
	 */
	public static var currentModDirectory:Null<String> = '';
	
	/**
	 * The primary loaded mod's config data
	 */
	public static var currentModConfig:Null<ModMeta> = null;
	
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'events',
		'notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'noteskins',
		'lang'
	];
	
	/**
	 * makes `modsList.txt` in the case it doesnt exist
	 */
	static function ensureModsListExists()
	{
		if (!FunkinAssets.exists('modsList.txt'))
		{
			File.saveContent('modsList.txt', '');
		}
	}
	
	public static var globalMods:Array<String> = [];
	
	public static var disabled:Array<String> = [];
	public static var enabled:Array<String> = [];
	public static var all:Array<String> = [];
	
	/**
	 * Refreshes all globally loaded mods
	 * @return 
	 */
	public static inline function pushGlobalMods():Array<String> // prob a better way to do this but idc
	{
		globalMods.resize(0);
		
		for (mod in enabled)
		{
			var pack = getPack(mod);
			if (pack != null && pack.global) globalMods.push(mod);
		}
		
		return globalMods;
	}
	
	public static inline function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path)
					&& !ignoreModFolders.contains(folder.toLowerCase())
					&& !list.contains(folder)) list.push(folder);
			}
		}
		#end
		return list;
	}
	
	public static inline function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null) defaultDirectory = Paths.getCorePath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';
		
		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);
		
		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}
		
		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0) mergedList.push(value);
		}
		return mergedList;
	}
	
	public static inline function directoriesWithFile(_:String, fileToFind:String, mode:Paths.PathsTestMode = NORMAL)
	{
		return Paths.listPath(fileToFind, mode);
	}
	
	public static function getPack(?folder:String):ModMeta
	{
		#if MODS_ALLOWED
		if (folder == null) folder = Mods.currentModDirectory;
		
		var path = Paths.mods(folder + '/meta.json');
		if (FileSystem.exists(path))
		{
			try
			{
				final json = FunkinAssets.getContent(path);
				if (json != null && json.length > 0) return Json.parse(json);
			}
			catch (e) {}
		}
		#end
		return null;
	}
	
	// todo jsut deprecate this function
	public static inline function parseList():{enabled:Array<String>, disabled:Array<String>, all:Array<String>}
	{
		return {enabled: enabled, disabled: disabled, all: all};
	}
	
	public static function updateModList(top:String = '')
	{
		#if MODS_ALLOWED
		ensureModsListExists();
		
		disabled.resize(0);
		enabled.resize(0);
		all.resize(0);
		
		var write:Bool = false;
		
		for (mod in CoolUtil.coolTextFile('modsList.txt'))
		{
			final dat:Array<String> = mod.split('|');
			final folder:String = dat[0], modEnabled:Bool = (dat[1] == '1');
			
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !all.contains(folder))
			{
				if (folder == top)
				{
					all.insert(0, folder);
					(modEnabled ? enabled : disabled).insert(0, folder);
				}
				else
				{
					all.push(folder);
					(modEnabled ? enabled : disabled).push(folder);
				}
			}
		}
		
		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !ignoreModFolders.contains(folder.toLowerCase())
				&& !all.contains(folder))
			{
				write = true;
				
				all.push(folder);
				enabled.push(folder);
			}
		}
		
		// write if list was updated!!!!!
		if (write) writeModList();
		
		pushGlobalMods();
		#end
	}
	
	public static function writeModList():Void
	{
		// Now save file
		var fileStr:String = '';
		for (mod in all)
		{
			if (fileStr.length > 0) fileStr += '\n';
			
			fileStr += '$mod|${enabled.contains(mod) ? '1' : '0'}';
		}
		
		File.saveContent('modsList.txt', fileStr);
	}
	
	public static function loadTopMod()
	{
		currentModDirectory = '';
		
		#if MODS_ALLOWED
		if (enabled != null) Mods.currentModDirectory = enabled[0];
		
		currentModConfig = loadTopModConfig();
		#end
	}
	
	public static function loadTopModConfig():Null<ModMeta>
	{
		var pack = getPack();
		
		WindowUtil.setTitle(pack?.windowTitle ?? 'VS IMPOSTOR LEGACY ' + Main.LEGACY_VERSION);
		
		if (pack == null) return null;
		
		inline function resetIcon()
		{
			final path = Paths.getPath('images/branding/icon/icon64.png', NORMAL);
			
			if (FunkinAssets.exists(path)) FlxG.stage.window.setIcon(Image.fromBytes(FunkinAssets.getBytes(path)));
		}
		
		if (pack.iconFile != null)
		{
			final path = Paths.getPath('images/${pack.iconFile}.png', NORMAL);
			
			if (FunkinAssets.exists(path)) FlxG.stage.window.setIcon(Image.fromBytes(FunkinAssets.getBytes(path)));
			else
			{
				resetIcon();
				Logger.log('Could not find Icon ${pack.iconFile}', ERROR);
			}
		}
		else resetIcon();
		
		if (pack.defaultTransition != null)
		{
			switch (pack.defaultTransition.toLowerCase())
			{
				case 'base', 'swipe':
					MusicBeatState.transitionInState = SwipeTransition;
					MusicBeatState.transitionOutState = SwipeTransition;
				case 'fade':
					MusicBeatState.transitionInState = FadeTransition;
					MusicBeatState.transitionOutState = FadeTransition;
				default:
					ScriptedTransition.setTransition(pack.defaultTransition);
			}
		}
		else
		{
			MusicBeatState.transitionInState = SwipeTransition;
			MusicBeatState.transitionOutState = SwipeTransition;
		}
		
		if (pack.discordClientID != null) funkin.api.DiscordClient.rpcId = pack.discordClientID;
		else funkin.api.DiscordClient.rpcId = DiscordClient.NMV_ID;
		
		Paths.DEFAULT_FONT = pack.defaultFont != null && FunkinAssets.exists(Paths.font(pack.defaultFont)) ? Paths.font(pack.defaultFont) : Paths.font('vcr.ttf');
		
		return pack;
	}
	
	public static function getModIcon(?mod:String):String
	{
		if (mod.length < 1) mod = currentModDirectory;
		
		var retVal = 'branding/icon/fallback';
		var pack = getPack(mod);
		
		if (pack != null && pack.iconFile != null) retVal = pack.iconFile;
		
		return retVal;
	}
	
	public static function getModName(?mod:String):String
	{
		if (mod.length < 1) mod = currentModDirectory;
		
		var retVal = mod;
		var pack = getPack(mod);
		
		if (pack != null && pack.name != null) retVal = pack.name;
		
		return retVal;
	}
	
	public static function getModFont(?mod:String):String
	{
		if (mod.length < 1) mod = currentModDirectory;
		
		var retVal = Paths.font('vcr.ttf');
		var pack = getPack(mod);
		
		if (pack != null && pack.defaultFont != null) retVal = Paths.font(pack.defaultFont);
		
		trace(retVal);
		
		return retVal;
	}
}
