package funkin.data;

typedef CosmicubeMetadata =
{
	var title:String;
	var ?currency:String;
	
	var ?mod:String;
	var ?fileName:String;
}

typedef ShopItemData =
{
	var ?requirement:Dynamic;
	var ?week:String;
	var ?song:String;
	var ?completionExcluded:Bool;
	
	var type:String;
	var price:Int;
	
	var ?title:String;
	var ?hint:String;
	var ?description:String;
	
	var node:NodeData;
	var ?fileName:String;
	
	var ?color:Dynamic;
	var ?icon:String;
	
	var ?currency:String;
}

enum ShopRequirement
{
	WEEK(week:String, ?accuracy:Float);
	SONG(song:String, ?accuracy:Float, ?rank:String);
	COMPLETION(percent:Float);
	GLOBAL_COMPLETION(percent:Float);
	SCRIPTED;
	NONE;
}

class CosmicubeData
{
	public static var currentMeta(get, never):Null<CosmicubeMetadata>;
	public static var currentCurrency(get, never):String;
	public static var currentMoney(get, set):Int;
	
	public static var cosmicubeList:Array<String> = [];
	public static var cosmicubeMetas:Map<String, CosmicubeMetadata> = [];
	public static var cosmicubeItems:Map<String, Array<ShopItemData>> = [];
	
	public static var fallbackMeta:CosmicubeMetadata =
		{
			title: 'Unknown',
			currency: 'beans',
			fileName: 'idk'
		};
		
	public static function reload(hard:Bool = true):Void
	{
		if (!hard && cosmicubeList.length > 0) return;
		
		cosmicubeList.resize(0);
		cosmicubeMetas.clear();
		cosmicubeItems.clear();
		
		var directories:Array<String> = [Paths.mods(), Paths.getCorePath()];
		
		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods('$mod/'));
			
		// parse items stuff
		for (dir in directories)
		{
			var modFolder:Null<String> = null;
			if (dir.startsWith(Paths.mods()))
			{
				modFolder = dir.substring(Paths.mods().length, dir.length - 1);
			}
			
			var dir:String = '${dir}data/cosmicube/';
			
			if (!FunkinAssets.exists(dir)) continue;
			
			for (file in FileSystem.readDirectory(dir))
			{
				if (!file.endsWith('.json')) continue;
				
				var fileName:String = file.substr(0, file.indexOf('.json'));
				
				var meta:CosmicubeMetadata = haxe.Json.parse(File.getContent('$dir/$file'));
				meta.fileName = fileName;
				meta.mod = modFolder;
				
				cosmicubeList.push(fileName);
				cosmicubeMetas.set(fileName, meta);
				cosmicubeItems.set(fileName, getShopItems('$dir/$fileName/', meta));
			}
		}
	}
	
	static function getShopItems(dir:String, meta:CosmicubeMetadata):Array<ShopItemData>
	{
		final list:Array<ShopItemData> = [];
		
		if (!FunkinAssets.exists(dir) || !FunkinAssets.isDirectory(dir)) return list;
		
		for (file in FileSystem.readDirectory(dir))
		{
			if (!file.endsWith('.json')) continue;
			
			var fileName:String = file.substr(0, file.indexOf('.json'));
			
			var data:ShopItemData = haxe.Json.parse(File.getContent('$dir/$file'));
			data.currency = meta.currency;
			data.fileName = fileName;
			
			list.push(data);
		}
		
		return list;
	}
	
	inline static function get_currentMeta():CosmicubeMetadata
	{
		reload(false);
		
		return cosmicubeMetas.get(ClientPrefs.activeCosmicube);
	}
	
	inline static function get_currentCurrency():String
	{
		return (currentMeta?.currency ?? '');
	}
	
	static function get_currentMoney():Int
	{
		return getMoney(currentCurrency);
	}
	
	static function set_currentMoney(money:Int):Int
	{
		return setMoney(currentCurrency, money);
	}
	
	public static inline function getMoney(currency:Null<String>):Int
	{
		if (currency == null || currency.length == 0) return 0;
		
		if (!ClientPrefs.money.exists(currency)) ClientPrefs.money.set(currency, 0);
		
		return ClientPrefs.money.get(currency);
	}
	
	public static inline function setMoney(currency:Null<String>, money:Int):Int
	{
		if (currency == null || currency.length == 0) return 0;
		
		ClientPrefs.money.set(currency, money);
		
		return money;
	}
}
