package funkin.utils;

import flixel.system.FlxAssets.FlxShader;

import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;

@:access(flixel.FlxCamera)
@:access(flixel.system.frontEnds.CameraFrontEnd)
@:nullSafety
class CameraUtil
{
	/**
		returns the last camera in FlxG.cameras.list
		equivalent to `FlxG.cameras.list[FlxG.cameras.list.length - 1]`
	**/
	public static var lastCamera(get, never):flixel.FlxCamera;
	
	static function get_lastCamera():flixel.FlxCamera return FlxG.cameras.list[FlxG.cameras.list.length - 1];
	
	/**
		convenient function to making a camera and adding it to the stack as well
		* @param	add	whether it should be automatically added to the stack
		* @return	The new Camera
	**/
	public static inline function quickCreateCam(add:Bool = true):FlxCamera
	{
		var cam = new FlxCamera();
		cam.bgColor = 0x0;
		
		if (add) FlxG.cameras.add(cam, false);
		
		return cam;
	}
	
	public static function addShader(camera:FlxCamera, filter:Dynamic, pos:Int = -1):Dynamic
	{
		if (!ClientPrefs.shaders) return filter;
		
		if (filter == null) return null;
		
		camera.filters ??= [];
		
		var filterToPush:ShaderFilter;
		if (filter is Shader)
		{
			var shd:Shader = cast filter;
			
			var foundShader:Null<Shader> = findShader(camera, shd);
			
			if (foundShader == null) filterToPush = new ShaderFilter(shd) else return foundShader;
		}
		else if (filter is ShaderFilter)
		{
			filterToPush = cast filter;
			
			if (camera.filters.contains(filterToPush)) return filterToPush.shader;
		}
		else // check if its one of those funkin shader creatures
		{
			if (filter.shader == null) return null;
			
			addShader(camera, filter.shader, pos);
			
			return filter;
		}
		
		camera.filters.insert(pos, filterToPush);
		
		return filterToPush.shader;
	}
	
	public static function findShader(camera:FlxCamera, shd:Shader):Null<Shader>
	{
		if (camera.filters == null) return null;
		
		for (filter in camera.filters)
		{
			if (!(filter is ShaderFilter)) continue;
			
			var filt:ShaderFilter = cast filter;
			
			if (filt.shader == shd)
				return filt.shader;
		}
		
		return null;
	}
}