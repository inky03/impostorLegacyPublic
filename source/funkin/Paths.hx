package funkin;

import haxe.io.Path;
import haxe.Json;

import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

enum PathsTestMode
{
	/**
	 * Check for assets in content/, current mod and global mods
	 */
	NORMAL;
	
	/**
	 * Only check for assets in content/ and current mod
	 */
	STRICT;
	
	/**
	 * Check for assets in all mods
	 */
	LOOSE;
	
	/**
	 * Don't check for mods
	 */
	NONE;
}

/**
 * Primary class used to simplify retrieving and finding assets.
 */
class Paths
{
	#if ASSET_REDIRECT
	public static inline final trail = #if macos '../../../../../../../' #else '../../../../' #end;
	#end
	
	/**
	 * Primary asset directory
	 */
	public static inline final CORE_DIRECTORY = #if ASSET_REDIRECT trail + 'assets/legacy' #else 'assets' #end;
	
	/**
	 * Mod directory
	 */
	public static inline final MODS_DIRECTORY = #if ASSET_REDIRECT trail + 'content' #else 'content' #end;
	
	/**
	 * Default font used by the game for most things.
	 * 
	 * Can be changed
	 */
	public static var DEFAULT_FONT:String = font('vcr.ttf', false);
	
	@:allow(funkin.backend.FunkinCache)
	static var tempAtlasFramesCache:Map<String, FlxAtlasFrames> = []; // maybe instead of this make a txt cache ?
	
	/**
	 * Primary function used for pathing.
	 * @param file The Path to the file. extension included.
	 * @param parentFolder Parent folder to the file
	 * @param mode Mode to use when trying to look for the path
	 * @return The path to the file.
	 */
	public static function getPath(file:String, ?parentFolder:String, mode:PathsTestMode = NONE):String
	{
		if (parentFolder != null) file = '$parentFolder/$file';
		
		#if MODS_ALLOWED
		if (mode != NONE)
		{
			final modPath:String = modFolders(file, mode);
			
			if (FileSystem.exists(modPath)) return modPath;
		}
		#end
		
		#if ASSET_REDIRECT
		final embedPath = '${trail}assets/embeds/$file';
		if (FunkinAssets.exists(embedPath)) return embedPath;
		#end
		
		return getCorePath(file);
	}
	
	/**
	 * Inserts the primary asset path to the given file path
	 */
	public static inline function getCorePath(file:String = ''):String
	{
		return '$CORE_DIRECTORY/$file';
	}
	
	/**
	 * Searches for a .txt file within the `data` directory.
	 */
	public static inline function txt(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('data/$key.txt', parentFolder, mode);
	}
	
	/**
	 * Searches for a .xml file within the `data` directory.
	 */
	public static inline function xml(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('data/$key.xml', parentFolder, mode);
	}
	
	/**
	 * Searches for a .json file within the `songs` directory.
	 */
	public static inline function json(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('songs/$key.json', parentFolder, mode);
	}
	
	public static inline function noteskin(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		var path = getPath('data/noteskins/$key.json', parentFolder, mode);
		if (!FunkinAssets.exists(path, TEXT)) path = getPath('noteskins/$key.json', parentFolder, mode);
		
		return path;
	}
	
	/**
	 * Searches for a .frag file within the `shaders` directory.
	 */
	public static inline function fragment(key:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('shaders/$key.frag', null, mode);
	}
	
	/**
	 * Searches for a .vert file within the `shaders` directory.
	 */
	public static inline function vertex(key:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('shaders/$key.vert', null, mode);
	}
	
	/**
	 * Searches for a video file wihin the `videos` directory.
	 * 
	 * Automatically will attempt to append .mp4 and .mov extensions.
	 */
	public static function video(key:String, mode:PathsTestMode = NORMAL):String
	{
		return findFileWithExts('videos/$key', ['mp4', 'mov'], null, mode);
	}
	
	public static function textureAtlas(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		return getPath('images/$key', parentFolder, mode);
	}
	
	/**
	 * Searches for a file within the `sounds` directory and caches a `Sound` instance.
	 * 
	 * Automatically will attempt to append .ogg and .wav extensions.
	 */
	public static function sound(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):Sound
	{
		final key = findFileWithExts('sounds/$key', ['ogg', 'wav'], parentFolder, mode);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function soundRandom(key:String, min:Int = 0, max:Int = 0, ?parentFolder:String, mode:PathsTestMode = NORMAL):Sound
	{
		return sound(key + FlxG.random.int(min, max), parentFolder, mode);
	}
	
	/**
	 * Searches for a file within the `music` directory and caches a `Sound` instance.
	 * 
	 * Automatically will attempt to append .ogg and .wav extensions.
	 */
	public static inline function music(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):Sound
	{
		final key = findFileWithExts('music/$key', ['ogg', 'wav'], parentFolder, mode);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function trackSwap(song:String, ?postFix:String, mode:PathsTestMode = NORMAL):Null<Sound> // not sure if this should be here
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Track';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, mode))) songKey = '$name/audio/Track';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, mode);
		
		trace(songKey);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey);
		
		return FunkinAssets.getSoundUnsafe(songKey);
	}
	
	public static inline function voices(song:String, ?postFix:String, mode:PathsTestMode = NORMAL):Null<Sound>
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Voices';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, mode))) songKey = '$name/audio/Voices';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, mode);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey);
		
		return FunkinAssets.getSoundUnsafe(songKey);
	}
	
	public static inline function inst(song:String, ?postFix:String, mode:PathsTestMode = NORMAL):Sound
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Inst';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, mode))) songKey = '$name/audio/Inst';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, mode);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey) ?? FunkinAssets.getSound(songKey);
		
		return FunkinAssets.getSound(songKey);
	}
	
	/**
	 * Searches for a file within the `images` directory and caches a `FlxGraphic` instance.
	 */
	public static inline function image(key:String, ?parentFolder:String, allowGPU:Bool = true, mode:PathsTestMode = NORMAL):FlxGraphic
	{
		return FunkinAssets.getGraphic(getPath('images/$key.png', parentFolder, mode), true, allowGPU);
	}
	
	/**
	 * Searches for a font file wihin the `fonts` directory.
	 * 
	 * Automatically will attempt to append .ttf and .otf extensions.
	 */
	public static inline function font(key:String, overridable:Bool = true, mode:PathsTestMode = NORMAL):String
	{
		key = overridable ? Lang.getFont(key) : key;
		
		final path:String = findFileWithExts('fonts/$key', ['ttf', 'otf'], null, mode);
		
		return (!FileSystem.exists(path) && Assets.exists(path, FONT) ? Assets.getFont(path).fontName : path);
	}
	
	public static function findFileWithExts(key:String, exts:Array<String>, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		for (ext in exts)
		{
			final joined = getPath('$key.$ext', parentFolder, mode);
			if (FunkinAssets.exists(joined)) return joined;
		}
		
		return getPath(key, parentFolder, mode); // assuming u mightve added a ext already
	}
	
	/**
	 * Attemps to get the text from a file. 
	 * 
	 * Will return a empty string if the file could not be found.
	 */
	public static function getTextFromFile(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):String
	{
		key = getPath(key, parentFolder, mode);
		
		return FunkinAssets.exists(key) ? FunkinAssets.getContent(key) : '';
	}
	
	/**
	 * Convenience function to check if a file exists. handles getPath for you
	 */
	public static inline function fileExists(key:String, ?parentFolder:String, mode:PathsTestMode = NORMAL):Bool
	{
		return FunkinAssets.exists(getPath(key, parentFolder, mode));
	}
	
	/**
	 * Attempts to snipe the mod folder a file belongs to
	 * @param path The path to find mod folder from
	 * @param exclude Optional, ignore a folder name. ex. "scripts"
	 * @return The name of the mod folder. Empty if unable to find
	 */
	public static function getModFolder(path:String, ?exclude:String):String
	{
		final contentIndex:Int = path.indexOf('content/');
		if (contentIndex == -1) return '';
		
		var folder:String = (path.substr(contentIndex + 'content/'.length));
		folder = folder.substring(0, folder.indexOf('/'));
		
		return (folder == exclude ? '' : folder);
	}
	
	public static inline function getMultiAtlas(keys:Array<String>, ?parentFolder:String, allowGPU:Bool = true, mode:PathsTestMode = NORMAL):FlxAtlasFrames // from psych
	{
		if (keys.length == 0) return null;
		
		final firstKey:Null<String> = keys.shift()?.trim();
		
		var frames = getAtlasFrames(firstKey, parentFolder, allowGPU, mode);
		
		if (keys.length != 0)
		{
			final originalCollection = frames;
			frames = new FlxAtlasFrames(originalCollection.parent);
			frames.addAtlas(originalCollection, true);
			for (i in keys)
			{
				final newFrames = getAtlasFrames(i.trim(), parentFolder, allowGPU, mode);
				if (newFrames != null)
				{
					frames.addAtlas(newFrames, false);
				}
			}
		}
		return frames;
	}
	
	/**
	 * Retrieves atlas frames from either `Sparrow` or `Packer` 
	 * 
	 * `Sparrow` has priority.
	 */
	public static inline function getAtlasFrames(key:String, ?parentFolder:String, allowGPU:Bool = true, mode:PathsTestMode = NORMAL):FlxAtlasFrames
	{
		final directPath = getPath('images/$key.png', parentFolder, mode).withoutExtension();
		
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null) return tempFrames;
		
		final xmlPath = getPath('images/$key.xml', parentFolder, mode);
		final txtPath = getPath('images/$key.txt', parentFolder, mode);
		
		final graphic = image(key, parentFolder, allowGPU, mode);
		
		// sparrow
		if (FunkinAssets.exists(xmlPath))
		{
			// until flixel does null safety
			@:nullSafety(Off)
			{
				final frames = FlxAtlasFrames.fromSparrow(graphic, FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
				if (frames != null) tempAtlasFramesCache.set(directPath, frames);
				return frames;
			}
		}
		
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSpriteSheetPacker(graphic, FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	public static inline function getSparrowAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, mode:PathsTestMode = NORMAL):FlxAtlasFrames
	{
		final directPath = getPath('images/$key.png', parentFolder, mode).withoutExtension();
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null)
		{
			return tempFrames;
		}
		
		final xmlPath = getPath('images/$key.xml', parentFolder, mode);
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSparrow(image(key, parentFolder, allowGPU, mode), FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	public static inline function getPackerAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, mode:PathsTestMode = NORMAL)
	{
		final directPath = getPath('images/$key.png', parentFolder, mode).withoutExtension();
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null)
		{
			return tempFrames;
		}
		
		final txtPath = getPath('images/$key.txt', parentFolder, mode);
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSpriteSheetPacker(image(key, parentFolder, allowGPU, mode), FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	/**
	 * Removes all non alpha numeric chars and replaces spaces with `-` to lower in a given String.
	 * 
	 * Example: My Song Path! == my-song-path
	 */
	public static inline function sanitize(path:String):String
	{
		return ~/[^- a-zA-Z0-9..\/]+\//g.replace(path, '').replace(' ', '-').trim().toLowerCase();
	}
	
	/**
	 * Lists all files found within a given directory
	 */
	public static inline function listAllFilesInDirectory(directory:String, mode:PathsTestMode = NORMAL)
	{
		// todo maybe make this recursive ?
		var files:Array<String> = [];
		
		for (folder in listPath(directory, mode))
		{
			for (file in FunkinAssets.readDirectory(folder)) files.push(Path.join([folder, file]));
		}
		
		return files;
	}
	
	/**
	 * Lists all instances of a file within assets and content folders
	 * 
	 * Moved from `Mods.directoriesWithFile`
	 */
	public static inline function listPath(file:String, mode:PathsTestMode = NORMAL):Array<String>
	{
		var folders:Array<String> = [];
		
		#if MODS_ALLOWED
		if (Paths.overrideMode != null) mode = Paths.overrideMode;
		
		if (mode != NONE)
		{
			for (mod in Mods.enabled)
			{
				if (Mods.globalMods.contains(mod))
				{
					if (mode == STRICT) continue;
				}
				else if (mode != LOOSE && mod != Mods.currentModDirectory)
				{
					continue;
				}
				
				final path:String = mods('$mod/$file');
				if (FunkinAssets.exists(path) && !folders.contains(path)) folders.push(path);
			}
		}
		#end
		
		if (FunkinAssets.exists(getCorePath(file))) folders.push(getCorePath(file));
		
		return folders;
	}
	
	#if MODS_ALLOWED
	/**
	 * Inserts the mod asset path to the given file path
	 */
	public static inline function mods(key:String = ''):String
	{
		return '$MODS_DIRECTORY/' + key;
	}
	
	/**
	 * Searches the primary loaded mod path and general mod path for a given file
	 */
	public static function modFolders(key:String, mode:PathsTestMode = NORMAL):String
	{
		if (FunkinAssets.exists(mods(key))) return mods(key);
		
		if (overrideMode != null) mode = overrideMode;
		
		for (mod in Mods.enabled)
		{
			if (Mods.globalMods.contains(mod))
			{
				if (mode == STRICT) continue;
			}
			else if (mode != LOOSE && mod != Mods.currentModDirectory)
			{
				continue;
			}
			
			
			final fileToCheck:String = mods('$mod/$key');
			if (FunkinAssets.exists(fileToCheck)) return fileToCheck;
		}
		
		return mods(key);
	}
	#end
	
	public static var overrideMode:Null<PathsTestMode> = null;
}
