package funkin.objects.menu;

import funkin.data.CosmicubeData;
import funkin.data.CharacterData;
import funkin.objects.HealthIcon;
import funkin.objects.menu.BaseNode;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CosmicubeNode extends BaseNode
{
	public var unlocked:Bool = false;
	
	public var requirement:ShopRequirement = NONE;
	public var type:String = 'playerSkin';
	public var price:Int = 0;
	
	public var bg:FlxSprite;
	public var white:FlxSprite;
	public var overlay:FlxSprite;
	public var priceTag:FlxText;
	
	public var icon:HealthIcon;
	public var portrait:FlxSprite;
	
	public var meta:ShopItemData;
	public var info:CharacterInfo = null;
	
	public function new(x:Float = 0, y:Float = 0, id:String = '', ?data:ShopItemData)
	{
		super(x, y, id);
		this.meta = data;
		this.nodeDistance = 250;
		this.connectorClass = CosmicubeNodeConnector;
		
		bg = new FlxSprite();
		bg.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		bg.animation.addByPrefix('main', 'back');
		
		white = new FlxSprite();
		white.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		white.animation.addByPrefix('main', 'emptysquare');
		
		overlay = new FlxSprite();
		overlay.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		overlay.animation.addByPrefix('main', 'overlay');
		
		priceTag = new FlxText(0, 0, bg.width, 'IDK', 36);
		priceTag.setFormat(Paths.font('ariblk.ttf'), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		priceTag.borderSize = 3;
		
		setup();
		
		for (obj in [bg, white, portrait, icon, overlay, priceTag])
		{
			if (obj == null) continue;
			
			obj.animation.play('main');
			obj.antialiasing = ClientPrefs.globalAntialiasing;
			obj.y -= Math.round(obj.height * .5);
			obj.x -= Math.round(obj.width * .5);
			add(obj);
		}
	}
	
	public function setup():Void
	{
		if (meta != null)
		{
			type = meta.type;
			
			unlocked = ClientPrefs.cosmicubeUnlocks.contains(id);
			
			priceTag.y = 58;
			priceTag.text = Std.string(price = meta.price);
			
			requirement =
				{
					if (meta.requirement == null || (meta.requirement is Float))
					{
						if (meta.week != null)
						{
							WEEK(meta.week, meta.requirement);
						}
						else if (meta.song != null)
						{
							SONG(meta.song, meta.requirement, null);
						}
						else
						{
							NONE;
						}
					}
					else if (meta.requirement is String)
					{
						var requirementString:String = cast meta.requirement;
						var loweredRequirement:String = requirementString.toLowerCase().trim();
						var percentRequirement = parseCompletionPercent(requirementString);
						if (percentRequirement != null)
						{
							COMPLETION(percentRequirement);
						}
						else
						{
							switch (loweredRequirement)
							{
								case 'scripted':
									SCRIPTED;
									
								case 'updog', 'updogsave', 'updog_save':
									UPDOG_SAVE;
									
								default:
									if (meta.song != null)
									{
										SONG(meta.song, null, requirementString.toUpperCase().trim());
									}
									else
									{
										NONE;
									}
							}
						}
					}
					else if (meta.requirement is Dynamic)
					{
						var requirementData:Dynamic = meta.requirement;
						var requirementType:String = ((cast Reflect.field(requirementData, 'type') : String) ?? '').toLowerCase().trim();
						
						switch (requirementType)
						{
							case 'completion':
								var requirementPercent:Dynamic = Reflect.field(requirementData, 'percent');
								var requirementScope:String = ((cast Reflect.field(requirementData, 'scope') : String) ?? '').toLowerCase().trim();
								var percentValue:Null<Float> = null;
								
								if (requirementPercent is Float || requirementPercent is Int)
								{
									percentValue = requirementPercent;
								}
								else if (requirementPercent is String)
								{
									percentValue = parseCompletionPercent(requirementPercent);
									if (percentValue == null)
									{
										var parsed = Std.parseFloat(cast requirementPercent);
										if (!Math.isNaN(parsed)) percentValue = parsed;
									}
								}
								// if its not global its for the current cube
								if (percentValue != null)
								{
									if (requirementScope == 'global')
									{
										GLOBAL_COMPLETION(percentValue);
									}
									else
									{
										COMPLETION(percentValue);
									}
								}
								else
								{
									NONE;
								}
								
							case 'songrank', 'rank':
								var requirementSong:Null<String> = cast Reflect.field(requirementData, 'song');
								var requirementRank:Null<String> = cast Reflect.field(requirementData, 'rank');
								if (((requirementSong ?? '').trim().length == 0)) requirementSong = meta.song;
								
								if ((requirementSong ?? '').trim().length > 0 && (requirementRank ?? '').trim().length > 0)
								{
									SONG(requirementSong, null, requirementRank.toUpperCase().trim());
								}
								else
								{
									NONE;
								}
								
							case 'updog', 'updogsave', 'updog_save':
								UPDOG_SAVE;
								
							case 'scripted':
								SCRIPTED;
								
							default:
								NONE;
						}
					}
					else if (meta.requirement == 'scripted')
					{
						SCRIPTED;
					}
					else
					{
						NONE;
					}
				}
				
			bg.color = FlxColor.RED;
			
			if (Paths.fileExists('data/characters/$id.json')) info = CharacterParser.fetchInfo(id);
			
			var color:Dynamic = meta.color;
			color ??= info?.healthbar_colour;
			color ??= info?.healthbar_colors;
			
			var nodeIcon:Dynamic = (meta.icon ?? info?.healthicon);
			
			if (color != null)
			{
				if (color is Array)
				{
					bg.color = FlxColor.fromRGB(color[0], color[1], color[2]);
				}
				else if (color is Int)
				{
					bg.color = cast color;
				}
			}
			
			if (icon != null)
			{
				icon = new HealthIcon(nodeIcon);
				icon.setPosition(-60, -60);
			}
			
			overlay.color = bg.color;
			
			portrait = new FlxSprite().loadGraphic(Paths.image('menu/cosmicube/items/$id'));
			portrait.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			unlocked = true;
			bg.visible = false;
			overlay.visible = false;
		}
		
		refresh();
	}
	
	public function requirementIsComplete():Bool
	{
		if (ClientPrefs.forceUnlockReq) return true;
		
		return switch (requirement)
		{
			case WEEK(week, rating):
				if (rating != null)
				{
					(ProgressionUtil.getWeekAccuracy(week) >= rating);
				}
				else
				{
					ProgressionUtil.weekIsClear(week);
				}
				
			case SONG(song, rating, rank):
				if (rank != null && rank.trim().length > 0)
				{
					ProgressionUtil.songMeetsRank(song, rank);
				}
				else if (rating != null)
				{
					(ProgressionUtil.getSongAccuracy(song) >= rating);
				}
				else
				{
					ProgressionUtil.songIsClear(song);
				}
				
			case COMPLETION(percent):
				ProgressionUtil.calculateCubeCompletion(ClientPrefs.activeCosmicube ?? 'impostor').percent >= percent;
				
			case GLOBAL_COMPLETION(percent):
				ProgressionUtil.calculateCompletion().percent >= percent;
				
			case UPDOG_SAVE:
				hasUpdogSaveData();
				
			case SCRIPTED:
				// ill do that later
				true;
				
			default:
				true;
		}
	}
	
	function parseCompletionPercent(value:String):Null<Float>
	{
		if (value == null) return null;
		
		var trimmed = value.trim();
		if (!trimmed.endsWith('%')) return null;
		
		var parsed = Std.parseFloat(trimmed.substr(0, trimmed.length - 1).trim());
		if (Math.isNaN(parsed)) return null;
		return parsed;
	}
	
	inline function hasUpdogSaveData():Bool
	{
		final appDataPath = Sys.getEnv("AppData");
		if (appDataPath == null || appDataPath.length == 0) return false;
		return FileSystem.isDirectory('$appDataPath/UpdogTeam');
	}
	
	public inline function canProgress():Bool
	{
		return (parent == null ? true : cast(parent, CosmicubeNode).unlocked);
	}
	
	public inline function canBeBought():Bool
	{
		return (requirementIsComplete() && canProgress());
	}
	
	public inline function isSuperSecret():Bool
	{
		return (requirement == UPDOG_SAVE && !requirementIsComplete());
	}
	
	public function refresh():Void
	{
		if (isSuperSecret())
		{
			kill();
			connector?.kill();
			
			return;
		}
		else
		{
			alive = true;
			
			for (member in members)
			{
				if (!(member is BaseNode))
					member.revive();
			}
			connector?.revive();
		}
		
		var available:Bool = canBeBought();
		var revealed:Bool = (available && canProgress());
		
		white.color = (unlocked ? (selected ? 0xffff80 : FlxColor.WHITE) : (selected ? (available ? 0xff20204a : 0xff4a2020) : 0xff4a4a4a));
		
		priceTag.visible = (revealed && !unlocked);
		
		if (portrait != null) portrait.color = (revealed ? FlxColor.WHITE : FlxColor.BLACK);
		if (icon != null)
		{
			icon.visible = revealed;
			icon.active = revealed;
			icon.color = FlxColor.WHITE;
		}
		
		if (connector != null) connector.color = (unlocked ? FlxColor.WHITE : (available ? 0xff06c864 : 0xff4a4a4a));
	}
	
	public override function onAttach(parent:BaseNode):Void
	{
		refresh();
	}
}

class CosmicubeNodeConnector extends BaseNodeConnector
{
	public function new(node:CosmicubeNode, direction:NodeDirection)
	{
		super(node, direction);
	}
	
	public override function makeConnector():CosmicubeNodeConnector
	{
		var directionRad:Float = direction / 180 * Math.PI;
		var dist:Float = parent.nodeDistance * .5;
		
		var connector:FlxSprite = new FlxSprite(Math.cos(directionRad) * dist, Math.sin(directionRad) * -dist,).loadGraphic(Paths.image('menu/cosmicube/connector'));
		
		connector.setGraphicSize(parent.nodeDistance - (cast parent : CosmicubeNode).bg.width + 10, connector.height);
		connector.offset.set(connector.width * .5, connector.height * .5);
		connector.antialiasing = ClientPrefs.globalAntialiasing;
		connector.angle = direction;
		add(connector);
		
		return this;
	}
}
