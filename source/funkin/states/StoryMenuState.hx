package funkin.states;

import funkin.data.*;
import funkin.data.Song;
import funkin.data.NodeData;
import funkin.data.WeekData;
import funkin.objects.menu.*;
import funkin.objects.menu.BaseNode;

import flixel.util.FlxStringUtil;

import funkin.objects.HealthIcon;

import flixel.group.FlxSpriteGroup;

class StoryMenuState extends AmongUIState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	
	public static var currentNode:String = 'root';
	
	public var nodes:Map<String, StoryNode> = [];
	
	public var cruiser:StoryCruiser;
	public var maze:StoryNode;
	
	public var frame:FlxSprite;
	public var weekInfoGroup:FlxSpriteGroup;
	
	public var weekScore:FlxText;
	public var weekTitle:FlxText;
	public var weekNumber:FlxText;
	public var weekPlaylist:FlxText;
	public var weekLeftIcon:HealthIcon;
	public var weekRightIcon:HealthIcon;
	
	public var lerpScore:Float = 0;
	public var intendedScore:Float = 0;
	
	public var canZoom:Bool = true;
	
	var highscore_string:String;
	
	public override function create():Void
	{
		super.create();
		
		Mods.currentModDirectory = null;
		
		PlayState.isStoryMode = true;
		PlayState.chartingMode = false;
		
		FunkinAssets.cache.clearStoredMemory();
		// FunkinAssets.cache.clearUnusedMemory();
		
		maze = new StoryNode('root');
		cruiser = new StoryCruiser();
		
		DiscordClient.changePresence("Story Menu");
		
		PlayState.missLimit = false;
		FlxG.mouse.visible = true;
		
		persistentUpdate = true;
		
		initStory();
		initStateScript();
		
		highscore_string = Lang.str('highscore');
		
		frame = new FlxSprite().loadGraphic(Paths.image('menu/story/border'));
		add(frame);
		
		backButton.setPosition(85, 65);
		add(backButton).revive();
		
		weekInfoGroup = new FlxSpriteGroup();
		weekInfoGroup.zIndex = 1;
		add(weekInfoGroup);
		
		frame.camera = weekInfoGroup.camera = camUpper;
		
		weekScore = new FlxText(80, 200, 640, 'HIGH SCORE: N/A');
		weekScore.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		weekScore.borderSize = 2;
		
		weekNumber = new FlxText(0, 40, FlxG.width, '');
		weekNumber.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 111, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		weekNumber.borderSize = 2.6;
		
		weekTitle = new FlxText(0, weekNumber.y + 115, FlxG.width, '');
		weekTitle.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		weekTitle.borderSize = 2.2;
		
		weekPlaylist = new FlxText(FlxG.width * 0.75 - 64, 0, 300);
		weekPlaylist.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		weekPlaylist.borderSize = 1.8;
		
		weekLeftIcon = new HealthIcon('impostor', true);
		weekLeftIcon.flipX = true;
		weekLeftIcon.y = 55;
		
		weekRightIcon = new HealthIcon('impostor', true);
		weekRightIcon.flipX = true;
		weekRightIcon.y = 55;
		
		for (obj in [weekScore, weekNumber, weekTitle, weekPlaylist, weekLeftIcon, weekRightIcon])
			weekInfoGroup.add(obj);
			
		add(maze);
		add(cruiser);
		
		var bottomControls = new funkin.objects.menu.AmongControls([
			['arrow', 'select'], // select
			['enter', 'conf'], // conf
			['esc', 'back'] // back
		], true);
		bottomControls.cameras = [camUpper];
		bottomControls.zIndex = 10;
		add(bottomControls);
		
		
		for (node in nodes) node.curScript?.executeFunc('onCreatePost', [], node);
		
		if (!nodes.exists(currentNode)) currentNode = 'root';
		var node = nodes.get(currentNode);
		
		goTo(node);
		cruiser.snapToNode();
		
		FlxG.camera.x = 70;
		FlxG.camera.width -= 140;
		FlxG.camera.y = 250;
		FlxG.camera.height = 410;
		
		FlxG.camera.zoom = .42;
		FlxG.camera.follow(cruiser, TOPDOWN, .15);
		FlxG.camera.snapToTarget();
		
		scriptGroup.call('onCreatePost', []);
	}
	
	public function initStory():Void
	{
		var queuedNodeData:Map<String, Array<StoryNode>> = [];
		var tempNodes:Map<String, StoryNode> = ['root' => maze];
		
		WeekData.reloadWeekFiles(false);
		for (weekID in WeekData.weeksList)
		{
			if (weekID == 'root' || tempNodes.exists(weekID)) continue;
			
			var week:WeekData = WeekData.weeksLoaded.get(weekID);
			var node:NodeData = week.node;
			
			if (node != null)
			{
				Mods.currentModDirectory = week.folder;
				
				var parent:String = (node.parent ?? 'root');
				var newNode:StoryNode = new StoryNode(weekID, week);
				tempNodes.set(weekID, newNode);
				
				if (parent == weekID) continue;
				
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
				
				if (queuedNodeData.exists(weekID))
				{ // ...or queue it to be attached when it Actually exists
					for (node in queuedNodeData.get(weekID))
						newNode.attachNode(node, node.attachDirection);
						
					queuedNodeData.remove(weekID);
				}
			}
		}
		
		for (id => node in tempNodes)
		{ // Kill all orphans.
			if (!node.isAttachedTo(maze))
			{
				node.destroy();
				continue;
			}
			else
			{
				nodes.set(id, node);
			}
			
			node.onClick = onClickNode.bind();
		}
		
		Mods.currentModDirectory = null;
	}
	
	public function lockAnim(node:StoryNode):Void
	{
		FlxG.sound.play(Paths.sound('locked'), .7);
		
		if (ClientPrefs.flashing)
		{
			FlxG.camera.shake(.005 / FlxG.camera.zoom, .25);
			camUpper.shake(.005, .25);
		}
		
		node.lockAnim();
	}
	
	public function onClickNode(node:StoryNode):Void
	{
		if (lockMovement) return;
		
		var hitTest = FlxG.mouse.getScreenPosition(camUpper);
		hitTest.put();
		
		if (hitTest.y < FlxG.camera.y || hitTest.y >= (FlxG.camera.y + FlxG.camera.height)
			|| hitTest.x < 70 || hitTest.x >= (FlxG.width - 70)) return;
			
		if (node.unlocked)
		{
			goTo(node);
		}
		else
		{
			lockAnim(node);
		}
	}
	
	public function accept():Void
	{
		var node:StoryNode = cast cruiser.followingNode;
		
		if (ScriptConstants.stopping(node.curScript?.executeFunc('onAccept', [], node))) return;
		
		if (node?.meta != null)
		{
			FlxG.sound.play(Paths.sound('panelAppear'), .5);
			lockMovement = true;
			loadWeek(node.meta);
		}
	}
	
	public static function loadWeek(week:WeekData):Void
	{
		if (week == null) return;
		
		var playlist:Array<String> = [for (song in week.songs) song[0]];
		
		PlayState.storyMeta.curWeek = WeekData.weeksList.indexOf(week.fileName);
		PlayState.storyMeta.currency = week.currency;
		PlayState.storyMeta.playlist = playlist;
		PlayState.storyMeta.misses = 0;
		PlayState.storyMeta.score = 0;
		
		PlayState.SONG = Chart.fromSong(PlayState.storyMeta.playlist[0], PlayState.storyMeta.difficulty);
		
		FlxG.switchState(PlayState.new);
	}
	
	var wasPressingCruiser:Bool = false;
	
	public override function update(elapsed:Float):Void
	{
		if (!lockMovement)
		{
			if (FlxG.sound.music != null && FlxG.sound.music.volume < .7) FlxG.sound.music.volume += (.5 * elapsed);
			
			if (controls.UI_LEFT_P) moveCruiser(WEST);
			if (controls.UI_RIGHT_P) moveCruiser(EAST);
			if (controls.UI_DOWN_P) moveCruiser(SOUTH);
			if (controls.UI_UP_P) moveCruiser(NORTH);
			if (controls.ACCEPT) accept();
			
			if (FlxG.mouse.justPressed)
			{
				wasPressingCruiser = FlxG.mouse.overlaps(cruiser);
			}
			else if (FlxG.mouse.justReleased && wasPressingCruiser && FlxG.mouse.overlaps(cruiser))
			{
				accept();
			}
			
			var wDeadzone:Float = Math.min((800 - (FlxG.width + 800) * (1 - FlxG.camera.zoom)), (FlxG.camera.width - cruiser.width) * .5);
			var hDeadzone:Float = Math.min(950 - (FlxG.height + 800) * (1 - FlxG.camera.zoom), (FlxG.camera.height - cruiser.height) * .5);
			FlxG.camera.deadzone.set(wDeadzone, hDeadzone, FlxG.camera.width - wDeadzone * 2, FlxG.camera.height - hDeadzone * 2);
			
			if (canZoom && FlxG.mouse.wheel != 0) FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom + FlxG.mouse.wheel * FlxG.camera.zoom / 10, .25, .45);
		}
		
		final cruiserScaleMult:Float = (!lockMovement && FlxG.mouse.overlaps(cruiser) ? (FlxG.mouse.pressed && wasPressingCruiser ? .9 : 1.1) : 1);
		cruiser.scale.x = cruiser.scale.y = MathUtil.fpsLerp(cruiser.scale.x, cruiserScaleMult, .35);
		
		lerpScore = FlxMath.lerp(lerpScore, intendedScore, Math.min(elapsed * 30, 1));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
		
		if (weekScore.visible) weekScore.text = ('${highscore_string}: ' + FlxStringUtil.formatMoney(Math.round(lerpScore), false));
		
		super.update(elapsed);
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		
		lockMovement = false;
	}
	
	public function moveCruiser(direction:NodeDirection):Void
	{
		if (cruiser.followingNode != null)
		{
			var nextNode:StoryNode = cast cruiser.followingNode.getNode(direction);
			
			if (nextNode != null && nextNode.unlocked) goTo(nextNode);
		}
		else
		{
			cruiser.followingNode = nodes.get('root');
		}
	}
	
	public function goTo(node:StoryNode):Void
	{
		if (cruiser.followingNode == node) return;
		
		var lastNode:StoryNode = nodes.get(currentNode);
		if (lastNode != null)
		{
			lastNode.selected = false;
			
			cruiser.face(switch (lastNode)
			{
				default: EAST;
				case(node.nodeY < _.nodeY => true): NORTH;
				case(node.nodeX < _.nodeX => true): WEST;
				case(node.nodeY > _.nodeY => true): SOUTH;
			});
			
			lastNode.curScript?.executeFunc('onDeselect', [node]);
		}
		else
		{
			cruiser.face(node.attachDirection);
		}
		
		Mods.currentModDirectory = node.meta?.folder;
		
		cruiser.followingNode = node;
		node.selected = true;
		
		currentNode = node.id;
		updateInfo();
		
		node.curScript?.executeFunc('onSelect', [], node);
		
		if (node != lastNode) FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	public function updateInfo():Void
	{
		if (weekInfoGroup == null) return;
		
		var node:StoryNode = cast cruiser.followingNode;
		
		var week:WeekData = node?.meta;
		var isRootNode:Bool = (node != null && node.id == 'root');
		
		weekTitle.alpha = weekNumber.alpha = 1;
		
		if (week != null && !isRootNode)
		{
			var icon:String = 'face';
			var playlistText:String = '';
			for (i => song in week.songs)
			{
				if (i > 0)
				{
					playlistText += '\n';
				}
				else
				{
					icon = song[1];
				}
				playlistText += StringTools.trim(song[0]);
			}
			
			weekScore.visible = weekNumber.visible = weekTitle.visible = weekPlaylist.visible = true;
			
			weekTitle.text = week.storyName;
			weekNumber.text = week.weekName;
			
			weekPlaylist.size = Std.int(Math.min(128 / week.songs.length, 50));
			weekPlaylist.text = playlistText;
			weekPlaylist.y = Math.round(147 - weekPlaylist.height * .5);
			
			weekLeftIcon.changeIcon(icon);
			weekLeftIcon.screenCenter(X);
			weekLeftIcon.visible = true;
			weekRightIcon.changeIcon(icon);
			weekRightIcon.screenCenter(X);
			weekRightIcon.visible = true;
			weekRightIcon.animation.curAnim.curFrame = 1;
			
			weekLeftIcon.x -= Math.round(weekNumber.textField.textWidth * .5 + 80);
			weekRightIcon.x += Math.round(weekNumber.textField.textWidth * .5 + 80);
			
			intendedScore = ProgressionUtil.getWeekScore(week.fileName);
		}
		else
		{
			weekNumber.text = Lang.str('storymode', 'STORY MODE');
			
			weekScore.visible = weekTitle.visible = weekPlaylist.visible = weekLeftIcon.visible = weekRightIcon.visible = false;
			weekNumber.visible = true;
			
			intendedScore = 0;
		}
	}
}
