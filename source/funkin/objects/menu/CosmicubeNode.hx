package funkin.objects.menu;

import funkin.data.CosmicubeData;
import funkin.data.CharacterData;
import funkin.objects.HealthIcon;
import funkin.objects.menu.BaseNode;
import funkin.scripts.FunkinScript;
import flixel.math.FlxRect;

class CosmicubeNode extends BaseNode
{
	public var curScript:FunkinScript;
	
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
	
	var initialized:Bool = false;
	var drawRange:Float = 70;
	var _hitTest:FlxRect;
	
	public function new(x:Float = 0, y:Float = 0, id:String = '', ?data:ShopItemData)
	{
		super(x, y, id);
		this.meta = data;
		this.nodeDistance = 250;
		this.connectorClass = CosmicubeNodeConnector;
		
		_hitTest = FlxRect.get();
		
		bg = new FlxSprite();
		bg.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		bg.animation.addByPrefix('main', 'back');
		
		white = new FlxSprite();
		white.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		white.animation.addByPrefix('main', 'emptysquare');
		
		overlay = new FlxSprite();
		overlay.frames = Paths.getSparrowAtlas('menu/cosmicube/node');
		overlay.animation.addByPrefix('main', 'overlay');
		
		priceTag = new FlxText(0, 0, bg.width, '', 36);
		priceTag.setFormat(Paths.font('ariblk.ttf'), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		priceTag.borderSize = 3;
		
		setup();
		
		for (obj in [bg, white, overlay, priceTag])
		{
			if (obj == null) continue;
			
			obj.animation.play('main');
			obj.antialiasing = ClientPrefs.globalAntialiasing;
			obj.y -= Math.round(obj.height * .5);
			obj.x -= Math.round(obj.width * .5);
			add(obj);
		}
		
		bg.active = white.active = overlay.active = false;
		
		var scriptPath:String = FunkinScript.getPath('scripts/cosmicubeNodes/$id');
		
		if (FunkinAssets.exists(scriptPath)) {
			curScript = FunkinScript.fromFile(scriptPath, false);
			
			if (curScript.__garbage)
			{
				curScript = null;
			}
			else
			{
				curScript.set('CosmicubeData', CosmicubeData);
				curScript.addParent(this);
				
				curScript.tryExecute();
				curScript.executeFunc('onLoad', [], this);
			}
		}
	}
	
	public function setup():Void
	{
		if (meta != null)
		{
			type = meta.type;
			
			unlocked = ClientPrefs.cosmicubeUnlocks.contains(id);
			
			priceTag.y = 58;
			price = meta.price;
			
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
		}
		else
		{
			unlocked = true;
			bg.visible = false;
			overlay.visible = false;
		}
	}
	
	public function requirementIsComplete():Bool
	{
		if (ClientPrefs.forceUnlockReq) return true;
		
		var result:Dynamic = curScript?.executeFunc('requirementIsComplete', [], this);
		
		if (result != null) return (result is Bool && result == true);
		
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
				
			case SCRIPTED:
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
		var result:Dynamic = curScript?.executeFunc('isSuperSecret', [], this);
		
		if (result != null) return (result is Bool && result == true);
		
		return false;
	}
	
	public function refresh(canInit:Bool = false):Void
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
		
		if (canInit && !initialized) initNode();
		
		if (portrait != null) portrait.color = (revealed ? FlxColor.WHITE : FlxColor.BLACK);
		
		if (icon != null)
		{
			icon.visible = revealed;
			icon.active = revealed;
			icon.color = FlxColor.WHITE;
		}
		
		if (connector != null) connector.color = (unlocked ? FlxColor.WHITE : (available ? 0xff06c864 : 0xff4a4a4a));
		
		if (initialized || canInit) curScript?.executeFunc('onRefresh', [], this);
		
		if (canInit) initialized = true;
	}
	
	@:access(funkin.objects.HealthIcon)
	function initNode():Void
	{
		if (meta == null) return;
		
		if (Paths.fileExists('data/characters/$id.json')) info = CharacterParser.fetchInfo(id);
		
		var color:Dynamic = meta.color;
		color ??= info?.healthbar_colour;
		color ??= info?.healthbar_colors;
		
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
		
		overlay.color = bg.color;
		
		priceTag.text = Std.string(price);
		
		portrait = new FlxSprite();
		portrait.loadGraphic(Paths.image('menu/cosmicube/items/$id'));
		portrait.y -= Math.round(portrait.height * .5);
		portrait.x -= Math.round(portrait.width * .5);
		portrait.active = false;
		
		insert(members.indexOf(overlay), portrait);
		
		var nodeIcon:Dynamic = (meta.icon ?? info?.healthicon);
		
		if (nodeIcon != null)
		{
			icon ??= new HealthIcon();
			icon.updateOffset = false;
			icon.changeIcon(nodeIcon);
			icon.scale.set(.75, .75);
			icon.updateHitbox();
			icon.active = false;
			
			icon.setPosition(-70 - Math.round(icon.width * .5), -70 - Math.round(icon.height * .5));
			
			add(icon);
		}
	}
	
	public override function onAttach(parent:BaseNode):Void
	{
		refresh();
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		curScript?.executeFunc('onUpdate', [elapsed], this);
		curScript?.executeFunc('onUpdatePost', [elapsed], this); // sure why not
	}
	
	@:access(flixel.FlxCamera)
	public override function draw():Void
	{
		if (initialized) return super.draw();
		
		for (camera in getCamerasLegacy())
		{
			if (!camera.visible || !camera.exists || !camera.containsRect(_hitTest.set(
				bg.x - drawRange - camera.scroll.x * scrollFactor.x,
				bg.y - drawRange - camera.scroll.y * scrollFactor.y,
				bg.width + drawRange * 2,
				bg.height + drawRange * 2
			))) continue;
			
			refresh(true);
		}
	}
	
	public override function destroy():Void
	{
		_hitTest.put();
		
		curScript?.executeFunc('onDestroy', [], this);
		curScript?.destroy();
		
		super.destroy();
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
