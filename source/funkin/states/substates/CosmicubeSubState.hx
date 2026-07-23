package funkin.states.substates;

import funkin.data.NodeData;
import funkin.data.CosmicubeData;
import funkin.data.GameFlags;
import funkin.objects.menu.BaseNode;
import funkin.objects.menu.CosmicubeNode;
import funkin.objects.menu.AwardPopup;
import funkin.states.substates.CosmeticsSubstate;
import funkin.utils.ProgressionUtil;

import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;

using StringTools;

class CosmicubeSubState extends MusicBeatSubstate
{
	var overlayCamera:FlxCamera;
	var cubeCamera:FlxCamera;
	// move to pluginpostlaunch
	var awardCamera:FlxCamera;
	
	var popUpQueued:Int = 0;
	var canPlayAwardSound:Bool = true;
	
	public var cosmicube:String = 'impostor';
	public var meta:CosmicubeMetadata;
	
	public var nodes:Map<String, CosmicubeNode> = [];
	public var lastSelectedNode:CosmicubeNode = null;
	public var selectedNode:CosmicubeNode = null;
	
	public var cosmicubeTitle:FlxText;
	
	public var currencyIcon:FlxSprite;
	public var currencyText:FlxText;
	
	public var starsBG:FlxBackdrop;
	public var starsFG:FlxBackdrop;
	
	public var maze:CosmicubeNode;
	public var pane:FlxSpriteGroup;
	
	public var bg:FlxSprite;
	public var black:FlxSprite;
	public var menuBackButton:FlxSprite;
	public var equipButton:FlxSprite;
	public var equipIcon:FlxSprite;
	public var equipText:FlxText;
	public var charTitle:FlxText;
	public var charKind:FlxText;
	public var charDesc:FlxText;
	public var charHint:FlxText;
	
	public var lockMovement:Bool = false;
	
	var dragDist:Float = 0;
	var dragged:Bool = false;
	var dragging:Bool = false;
	var dragPos:FlxPoint = FlxPoint.get();
	var mousePos:FlxPoint = FlxPoint.get();
	
	public function new(id:String):Void
	{
		super();
		
		cosmicube = id;
	}
	
	public override function create():Void
	{
		super.create();
		CosmicubeData.reload(false);
		CosmeticsSubstate.preloadForFreeplay();
		
		DiscordClient.changePresence("Cosmicube Menu");
		
		this.meta = (CosmicubeData.cosmicubeMetas.get(cosmicube) ?? CosmicubeData.fallbackMeta);
		
		Mods.currentModDirectory = (meta.mod == null || meta.mod.length == 0 ? null : meta.mod);
		
		(overlayCamera = new FlxCamera()).bgColor = 0;
		FlxG.cameras.add(overlayCamera, false);
		
		(cubeCamera = new FlxCamera(50, 110, 860, 560)).bgColor = FlxColor.BLACK;
		FlxG.cameras.add(cubeCamera, false);
		
		(awardCamera = new FlxCamera()).bgColor = 0;
		FlxG.cameras.add(awardCamera, false);
		
		add(black = new flixel.system.FlxBGSprite());
		black.alpha = .72;
		black.color = FlxColor.BLACK;
		black.camera = overlayCamera;
		
		starsBG = new FlxBackdrop(Paths.image('menu/common/starBG'));
		starsBG.camera = cubeCamera;
		starsBG.scrollFactor.set();
		starsBG.velocity.x = -4.5;
		add(starsBG);
		
		starsFG = new FlxBackdrop(Paths.image('menu/common/starFG'));
		starsFG.camera = cubeCamera;
		starsFG.scrollFactor.set();
		starsFG.velocity.x = -9;
		add(starsFG);
		
		maze = new CosmicubeNode('root');
		maze.camera = cubeCamera;
		
		initCosmicube(cosmicube);
		initStateScript();
		
		pane = new FlxSpriteGroup();
		pane.camera = overlayCamera;
		
		bg = new FlxSprite(Paths.image('menu/cosmicube/pane'));
		bg.setPosition(Math.round(FlxG.width - bg.width) * .5, Math.round(FlxG.height - bg.height) * .5);
		pane.add(bg);
		
		pane.add(menuBackButton = new FlxSprite(bg.x + bg.width - 6, bg.y + 3).loadGraphic(Paths.image('menu/common/menuBack')));
		menuBackButton.x -= menuBackButton.width;
		
		pane.add(currencyIcon = new FlxSprite(45, bg.y + 32, Paths.image('currency/${meta.currency}')));
		currencyIcon.setGraphicSize(0, 35);
		currencyIcon.updateHitbox();
		currencyIcon.y -= Math.round(currencyIcon.height * .5);
		
		pane.add(currencyText = new FlxText(95, bg.y + 32, 150, '1234'));
		currencyText.setFormat(Paths.font('liberbold.ttf'), 22, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		currencyText.borderSize = 1;
		currencyText.y -= Math.round(currencyText.height * .5);
		
		pane.add(cosmicubeTitle = new FlxText(0, bg.y + 32, FlxG.width, meta.title));
		cosmicubeTitle.setFormat(Paths.font('AmaticSC-Bold.ttf'), 50, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cosmicubeTitle.borderSize = 2;
		cosmicubeTitle.screenCenter(X);
		cosmicubeTitle.y -= Math.round(cosmicubeTitle.height * .5);
		
		pane.add(equipButton = new FlxSprite(970 + 270 * .5, 570));
		equipButton.frames = Paths.getSparrowAtlas('menu/cosmicube/button');
		equipButton.antialiasing = ClientPrefs.globalAntialiasing;
		equipButton.animation.addByPrefix('locked', 'locked');
		equipButton.animation.addByPrefix('equip', 'equipped');
		equipButton.animation.addByPrefix('equipped', 'grey');
		equipButton.animation.addByPrefix('buy', 'buy');
		equipButton.animation.play('buy');
		equipButton.scale.set(.6, .6);
		equipButton.updateHitbox();
		equipButton.x -= (equipButton.width * .5);
		
		pane.add(equipIcon = new FlxSprite());
		
		pane.add(equipText = new FlxText(equipButton.x, 0, equipButton.width, 'BUY'));
		equipText.setFormat(Paths.font('liberbold.ttf'), 35, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		equipText.setPosition(equipButton.x, equipButton.y + (equipButton.height - equipText.height) * .5);
		equipText.borderSize = 2;
		
		pane.add(charTitle = new FlxText(970, 120, 270, 'this is a test'));
		charTitle.setFormat(Paths.font('liberbold.ttf'), 34, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		charTitle.borderSize = 2;
		@:privateAccess charTitle._defaultFormat.leading = -10;
		
		pane.add(charKind = new FlxText(970, 120, 270, 'this is a test'));
		charKind.setFormat(Paths.font('liberbold.ttf'), 18, FlxColor.BLACK, CENTER);
		
		pane.add(charDesc = new FlxText(970, 306, 270, 'this is a test'));
		charDesc.setFormat(Paths.font('liberbold.ttf'), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		charDesc.borderSize = 1.2;
		
		pane.add(charHint = new FlxText(970, 470, 270, 'this is a test'));
		charHint.setFormat(Paths.font('liber.ttf'), 20, 0xff333333, CENTER);
		
		add(pane);
		add(maze);
		
		updateInfo();
		
		cubeCamera.scroll.set(Math.round(maze.x - cubeCamera.width * .5), Math.round(maze.y - cubeCamera.height * .5));
		
		pane.y = 120;
		cubeCamera.y += 120;
		
		overlayCamera.alpha = cubeCamera.alpha = awardCamera.alpha = 0;
		FlxTween.tween(pane, {y: 0}, .35, {ease: FlxEase.circOut});
		FlxTween.tween(overlayCamera, {alpha: 1}, .35, {ease: FlxEase.circOut});
		FlxTween.tween(cubeCamera, {alpha: 1, y: cubeCamera.y - 120}, .35, {ease: FlxEase.circOut});
		FlxTween.tween(awardCamera, {alpha: 1}, .35, {ease: FlxEase.circOut});
		
		scriptGroup.call('onCreatePost', []);
	}
	
	public function closeTween():Void
	{
		lockMovement = true;
		
		FlxG.sound.play(Paths.sound('cancelMenu'), .5);
		
		FlxTween.cancelTweensOf(pane);
		FlxTween.cancelTweensOf(black);
		FlxTween.cancelTweensOf(cubeCamera);
		FlxTween.cancelTweensOf(overlayCamera);
		FlxTween.cancelTweensOf(awardCamera);
		
		FlxTween.tween(pane, {y: pane.y + 120}, .25, {ease: FlxEase.sineIn});
		FlxTween.tween(overlayCamera, {alpha: 0}, .25, {ease: FlxEase.sineIn});
		FlxTween.tween(cubeCamera, {alpha: 0, y: cubeCamera.y + 120}, .25, {ease: FlxEase.sineIn, onComplete: function(_) close()});
		FlxTween.tween(awardCamera, {alpha: 0}, .25, {ease: FlxEase.sineIn});
	}
	
	public function initCosmicube(id:String):Void
	{
		var queuedNodeData:Map<String, Array<CosmicubeNode>> = [];
		var tempNodes:Map<String, CosmicubeNode> = ['root' => maze];
		
		var shopItems:Array<ShopItemData> = (CosmicubeData.cosmicubeItems.get(id) ?? []);
		
		// create nodes stuff
		for (item in shopItems)
		{
			var itemID:String = item.fileName;
			if (itemID == 'root' || tempNodes.exists(itemID)) continue;
			
			var node:NodeData = item.node;
			var parent:String = (node.parent ?? 'root');
			var newNode:CosmicubeNode = new CosmicubeNode(itemID, item);
			tempNodes.set(itemID, newNode);
			
			if (parent == itemID) continue;
			
			newNode.attachDirection = BaseNode.getNodeDirectionFromString(node.direction);
			
			if (tempNodes.exists(parent))
			{ // attach node if parent already exists...
				tempNodes.get(parent).attachNode(newNode, newNode.attachDirection);
			}
			else if (queuedNodeData.exists(parent))
			{
				queuedNodeData.get(parent).push(newNode);
			}
			else
			{
				queuedNodeData.set(parent, [newNode]);
			}
			
			if (queuedNodeData.exists(itemID))
			{ // ...or queue it to be attached when it Actually exists
				for (node in queuedNodeData.get(itemID))
					newNode.attachNode(node, node.attachDirection);
					
				queuedNodeData.remove(itemID);
			}
		}
		
		for (id => node in tempNodes)
		{ // Kill all orphans.
			if (!node.isAttachedTo(maze))
			{
				node.destroy();
			}
			else
			{
				nodes.set(id, node);
			}
		}
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		FlxG.mouse.getViewPosition(cubeCamera, mousePos);
		
		if (!lockMovement)
		{
			if (controls.UI_LEFT_P) move(WEST);
			if (controls.UI_RIGHT_P) move(EAST);
			if (controls.UI_DOWN_P) move(SOUTH);
			if (controls.UI_UP_P) move(NORTH);
			
			if (controls.BACK)
			{
				if (selectedNode == null)
				{
					closeTween();
				}
				else
				{
					selectNode(null);
				}
			}
			
			if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(menuBackButton, overlayCamera))
			{
				closeTween();
			}
			
			var cubeFocus:Bool = (FlxG.mouse.x >= cubeCamera.x && FlxG.mouse.y >= cubeCamera.y
				&& FlxG.mouse.x < (cubeCamera.x + cubeCamera.width) && FlxG.mouse.y < (cubeCamera.y + cubeCamera.height));
				
			if (dragging || cubeFocus)
			{
				if (FlxG.mouse.justPressed) dragging = true;
				
				if (dragging)
				{
					final deltaX:Float = (mousePos.x - dragPos.x), deltaY:Float = (mousePos.y - dragPos.y);
					
					cubeCamera.scroll.x -= deltaX;
					cubeCamera.scroll.y -= deltaY;
					
					if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5)
					{
						if (selectedNode != null) selectNode(null);
						
						dragged = true;
					}
				}
				
				if (FlxG.mouse.justReleased && !dragged)
				{
					var node:CosmicubeNode = getClickedNode(maze);
					
					if (selectedNode != node) selectNode(node);
				}
				
				if (!FlxG.mouse.pressed) dragging = dragged = false;
				
				if (FlxG.mouse.wheel != 0 && selectedNode == null)
				{
					var nextZoom = FlxMath.bound(cubeCamera.zoom + FlxG.mouse.wheel * cubeCamera.zoom / 10, .2, 1.75);
					
					cubeCamera.scroll.x += ((mousePos.x - cubeCamera.width * .5) * (1 - cubeCamera.zoom / nextZoom));
					cubeCamera.scroll.y += ((mousePos.y - cubeCamera.height * .5) * (1 - cubeCamera.zoom / nextZoom));
					
					cubeCamera.zoom = nextZoom;
					
					FlxG.mouse.getScreenPosition(cubeCamera, mousePos);
				}
				
				dragPos.set(mousePos.x, mousePos.y);
			}
			
			if (selectedNode != null && (controls.ACCEPT || (FlxG.mouse.justReleased && equipButton.alive && FlxG.mouse.overlaps(equipButton, overlayCamera))))
			{
				equipNode(selectedNode);
			}
		}
		
		if (selectedNode != null)
		{
			final lerpVal:Float = .1;
			
			cubeCamera.scroll.set(MathUtil.fpsLerp(cubeCamera.scroll.x, Math.round(selectedNode.x - cubeCamera.width * .5), lerpVal),
				MathUtil.fpsLerp(cubeCamera.scroll.y, Math.round(selectedNode.y - cubeCamera.height * .5), lerpVal));
				
			cubeCamera.zoom = MathUtil.fpsLerp(cubeCamera.zoom, 1, lerpVal);
		}
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		updateInfo();
	}
	
	public override function destroy():Void
	{
		ClientPrefs.flush();
		
		FlxG.cameras.remove(overlayCamera, true);
		FlxG.cameras.remove(cubeCamera, true);
		FlxG.cameras.remove(awardCamera, true);
		
		super.destroy();
		
		dragPos.put();
	}
	
	public function move(direction:NodeDirection):Void
	{
		if (selectedNode != null)
		{
			var nextNode:CosmicubeNode = cast selectedNode.getNode(direction);
			if (nextNode == null || !nextNode.alive) return;
			
			selectedNode = nextNode;
		}
		else
		{
			selectedNode = (lastSelectedNode ?? nodes.get('root'));
		}
		
		selectNode(selectedNode);
	}
	
	public function selectNode(node:CosmicubeNode):Void
	{
		FlxG.sound.play(Paths.sound(node == null ? 'panelDisappear' : 'cosmicubePop'), .9);
		
		if (lastSelectedNode != null)
		{
			lastSelectedNode.selected = false;
			lastSelectedNode.refresh();
		}
		
		if (node != null)
		{
			lastSelectedNode = node;
			
			node.selected = true;
			node.refresh();
		}
		
		selectedNode = node;
		updateInfo();
	}
	
	public function equipNode(node:CosmicubeNode):Void
	{
		if (node.meta == null) return;
		
		var pulseColor:FlxColor = FlxColor.WHITE;
		var reload:Bool = false;
		
		if (node.unlocked)
		{
			var equipped:Bool = isEquipped(node);
			
			FlxG.sound.play(Paths.sound(node.type == 'pet' ? 'equipPet' : 'equip'));
			
			ClientPrefs.equipment.set(node.type, equipped ? null : node.id);
			
			reload = true;
			pulseColor = 0xffffa143;
		}
		else if (node.canBeBought() && CosmicubeData.getMoney(node.meta.currency) >= node.price)
		{
			CosmicubeData.setMoney(node.meta.currency, CosmicubeData.getMoney(node.meta.currency) - node.price);
			
			ClientPrefs.cosmicubeUnlocks.push(node.id);
			FlxG.sound.play(Paths.sound('shopBuy'));
			node.unlocked = true;
			checkCosmiCollectorAward();
			checkTheHundredAward();
			
			reload = true;
			pulseColor = 0xff30ff86;
		}
		else
		{
			FlxG.sound.play(Paths.sound('locked'));
			cubeCamera.shake(.005, .35);
			
			pulseColor = 0xffff4444;
		}
		
		FlxTween.cancelTweensOf(equipText);
		FlxTween.cancelTweensOf(equipButton);
		FlxTween.color(equipText, .6, pulseColor, FlxColor.WHITE, {ease: FlxEase.sineOut});
		FlxTween.color(equipButton, .6, pulseColor, FlxColor.WHITE, {ease: FlxEase.sineOut});
		
		if (reload)
		{
			node.forEachNode(function(node) { // only refresh what we Have to
				var node:CosmicubeNode = cast node;
				node.refresh();
				
				return node.canProgress();
			});
			updateInfo();
		}
	}
	
	function checkCosmiCollectorAward():Void
	{
		if (GameFlags.hasAchievement('cosmi_collector')) return;
		
		if (Lambda.count(ProgressionUtil.allImpostorItems, i -> !ClientPrefs.cosmicubeUnlocks.contains(i)) > 0) return;
		
		if (GameFlags.giveAchievement('cosmi_collector'))
		{
			popUpAchievement('cosmi_collector');
		}
	}
	
	function checkTheHundredAward():Void
	{
		if (GameFlags.hasAchievement('the_hundred')) return;
		
		if (ProgressionUtil.checkHundredAchievement() && GameFlags.giveAchievement('the_hundred'))
		{
			popUpAchievement('the_hundred');
		}
	}
	
	// lazy but its  above cam
	function popUpAchievement(id:String):AwardPopup
	{
		var popUp:AwardPopup = new AwardPopup(id, canPlayAwardSound);
		popUp.camera = awardCamera;
		add(popUp);
		
		canPlayAwardSound = false;
		
		popUpQueued++;
		popUp.onFinish = function() {
			popUpQueued--;
			if (popUpQueued <= 0)
			{
				popUpQueued = 0;
				canPlayAwardSound = true;
			}
		};
		
		return popUp;
	}
	
	public function getClickedNode(parent:CosmicubeNode):CosmicubeNode
	{
		var clickedNode:CosmicubeNode = null;
		
		if (parent.parent == null && FlxG.mouse.overlaps(parent.bg, cubeCamera)) return parent;
		
		for (n in parent.attachedNodes)
		{
			if (n == null) continue;
			var node:CosmicubeNode = cast n;
			if (node.bg == null || !node.bg.visible || !node.bg.active) continue;
			
			if (FlxG.mouse.overlaps(node.bg, cubeCamera)) return node;
			
			clickedNode ??= getClickedNode(node);
		}
		
		return clickedNode;
	}
	
	public inline function isEquipped(node:CosmicubeNode):Bool
	{
		return (ClientPrefs.equipment.get(node.type) == node.id);
	}
	
	public function updateInfo():Void
	{
		currencyText.text = FlxStringUtil.formatMoney(CosmicubeData.getMoney(meta.currency), false);
		
		equipIcon.kill();
		charKind.kill();
		charDesc.kill();
		
		if (selectedNode?.meta == null)
		{
			charHint.kill();
			charTitle.kill();
			equipText.kill();
			equipButton.kill();
			return;
		}
		
		charHint.revive();
		charTitle.revive();
		equipText.revive();
		equipButton.revive();
		
		charTitle.text = (selectedNode.unlocked ? Lang.str('${selectedNode.id}_name', selectedNode.meta.title ?? selectedNode.id) : '???');
		Lang.arabicTextFix(charTitle);
		
		if (selectedNode.unlocked)
		{
			charKind.revive();
			charKind.y = (charTitle.y + charTitle.height);
			charKind.text = Lang.str('shop_${selectedNode.type}');
			Lang.arabicTextFix(charKind);
		}
		
		if (selectedNode.unlocked)
		{
			charDesc.revive();
			
			charDesc.text = Lang.str('${selectedNode.id}_desc', selectedNode.meta.description ?? '');
		}
		else
		{
			charDesc.text = '???';
		}
		Lang.arabicTextFix(charDesc);
		
		var descTopY:Float = (charKind.alive ? charKind.y + charKind.height + 8 : charTitle.y + charTitle.height + 8);
		charDesc.y = Math.max(descTopY, 282 - charDesc.height);
		charHint.text = Lang.str('${selectedNode.id}_hint', selectedNode.meta.hint ?? '');
		Lang.arabicTextFix(charHint);
		
		equipText.x = equipButton.x;
		equipText.fieldWidth = equipButton.width;
		
		if (selectedNode.canBeBought())
		{
			if (selectedNode.unlocked)
			{
				var equipped:Bool = isEquipped(selectedNode);
				
				equipText.text = (equipped ? Lang.str('shop_equipped') : Lang.str('shop_equip'));
				equipButton.animation.play(equipped ? 'equipped' : 'equip');
			}
			else
			{
				equipIcon.loadGraphic(Paths.image('currency/${selectedNode.meta.currency}'));
				equipIcon.setGraphicSize(0, 40);
				equipIcon.updateHitbox();
				equipIcon.setPosition(equipButton.x + 24, equipButton.y + (equipButton.height - equipIcon.height) * .5);
				equipIcon.revive();
				
				equipText.x = (equipButton.x + 30);
				equipText.fieldWidth = (equipButton.width - 30);
				equipText.text = FlxStringUtil.formatMoney(selectedNode.price, false);
				equipButton.animation.play('buy');
			}
		}
		else
		{
			equipText.text = Lang.str('shop_locked');
			equipButton.animation.play('locked');
		}
		
		if (charKind.alive)
		{
			charKind.y = (charTitle.y + charTitle.height);
		}
		
		fitEquipShit();
		fitHintShit();
	}
	
	function fitEquipShit():Void
	{
		equipText.wordWrap = false;
		equipText.size = 35;
		
		while (equipText.size > 16 && equipText.textField.textWidth > equipText.fieldWidth - 8)
		{
			equipText.size -= 1;
		}
		
		equipText.y = equipButton.y + (equipButton.height - equipText.height) * .5;
	}
	
	function fitHintShit():Void
	{
		charHint.size = 20;
		
		var buttonTop:Float = equipButton.y - 6;
		while (charHint.size > 14 && charHint.y + charHint.height > buttonTop)
		{
			charHint.size -= 1;
		}
	}
}
