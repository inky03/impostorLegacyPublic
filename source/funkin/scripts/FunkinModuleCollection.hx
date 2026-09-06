package funkin.scripts;

import insanity.tools.Tools;

import funkin.backend.Logger;
import funkin.scripts.FunkinModule;

using Lambda;

typedef PackageInfo =
{
	var subPackages:Array<PackageInfo>;
	var modules:Array<ModuleInfo>;
	var path:Array<String>;
}

typedef ModuleInfo =
{
	var path:String;
	var name:String;
}

typedef FunkinModuleResult =
{
	var removed:Int;
	var added:Int;
	var changed:Int;
	var total:Int;
}

class FunkinModuleCollection extends insanity.Environment
{
	public static var instance:FunkinModuleCollection = new FunkinModuleCollection();
	
	public static function refresh(hard:Bool = false):FunkinModuleResult
	{
		var low:PackageInfo = { subPackages: [], modules: [], path: [] };
		var tracked:Array<String> = [];
		
		var removed:Int = 0, added:Int = 0, changed:Int = 0, total:Int = 0;
		
		function readModules(dir:String, pack:PackageInfo):PackageInfo
		{
			for (file in FileSystem.readDirectory(dir))
			{
				var path:String = '$dir/$file';
				
				if (FileSystem.isDirectory(path))
				{
					var newPath:Array<String> = pack.path.copy(); newPath.push(file);
					
					pack.subPackages.push(readModules(path, { subPackages: [], modules: [], path: newPath }));
				}
				else if (FunkinScript.isHxFile(file))
				{
					var name:String = file.withoutExtension();
					
					var foundModule:ModuleInfo = pack.modules.find(function(info:ModuleInfo) return (info.name == name));
					
					if (name == 'import' || (~/^[A-Z_]?[a-zA-Z0-9_]+/).match(name))
					{
						if (foundModule != null) // allows module shadowing and stuff
						{
							foundModule.path = path;
						}
						else
						{
							pack.modules.push({ path: path, name: name });
						}
					}
					else
					{
						Logger.log('Invalid module identifier: $name', WARN);
					}
				}
			}
			
			return pack;
		}
		
		for (folder in Paths.listPath('source', LOOSE) /* ill SEE if to keep this or change the path */)
			readModules(folder, low);
		
		function loadModules(pack:PackageInfo, ?subModules:Array<insanity.Module>):Void
		{
			subModules ??= [];
			
			for (mod in pack.modules)
			{
				var string:String = File.getContent(mod.path);
				
				var module:insanity.Module;
				
				if (mod.name == 'import')
				{
					module = new FunkinImportModule(string, mod.path);
				}
				else
				{
					var path:String = Tools.pathToString(mod.name, pack.path);
					
					if (!tracked.contains(path))
						tracked.push(path);
					
					if (instance.modules.exists(path))
					{
						if (!hard && cast(instance.modules.get(path), IFunkinModule).hash == haxe.crypto.Sha256.encode(string))
							continue;
						
						changed ++;
					}
					else
					{
						added ++;
					}
					
					module = new FunkinModule(string, mod.name, pack.path, mod.path);
					module.subModules = cast subModules;
					
					instance.modules.set(module.path, module);
				}
				
				subModules.push(module);
			}
			
			for (pack in pack.subPackages)
				loadModules(pack, subModules.copy());
		}
		
		loadModules(low);
		
		for (mod => _ in instance.modules)
		{
			if (!tracked.contains(mod))
			{
				instance.modules.remove(mod);
				removed ++;
			}
		}
		
		instance.rebuildTypes();
		instance.start();
		
		return {removed: removed, added: added, changed: changed, total: instance.modules.count()};
	}
}
