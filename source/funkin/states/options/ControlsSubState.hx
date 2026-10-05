package funkin.states.options;

import flixel.FlxObject;
import flixel.group.FlxContainer;
import flixel.group.FlxSpriteContainer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxRect;

import funkin.objects.*;
import funkin.input.Controls;
import funkin.input.InputFormatter;
import funkin.objects.menu.ScrollBar;

class ControlsSubState extends MusicBeatSubstate
{
	public static inline final NONE:Int = -2;
	
	public var device(default, set):Device;
	
	public var index(default, set):Int = -1;
	
	public var currentGroup(get, set):ControlsGroup;
	
	public var currentOption(get, set):ControlsOption;
	
	public var currentBind(get, set):FlxText;
	
	public var currentBindIndex(get, set):Int;
	
	public var state:BindState = BindState.NONE;
	
	public var scrollBar:ScrollBar;
	public var autoScroll:Bool = true;
	public var currentScrollY:Float = 0;
	
	var optionsList:Array<ControlsOption> = [];
	
	var controlsGroup = new FlxTypedSpriteContainer<ControlsGroup>();
	
	var titleText:FlxText;
	var languageTextYOffset:Float = 0;
	
	var panelX:Float = 480;
	var optionEndY:Float = 0;
	
	final topBound:Float = 150;
	final bottomBound:Float = 630;
	
	var fadeCamera:FunkinCamera; // erm .. awkward
	
	public function new(device:Device)
	{
		super();
		
		scrollBar = new ScrollBar(panelX - 16, topBound, 8, Std.int(bottomBound - topBound), 0xFF2C3F3F, 0xFFFFFFFF);
		scrollBar.camera = scrollBar.track.camera = scrollBar.thumb.camera = FlxG.camera;
		scrollBar.onScroll.add(function(scroll:Float, _) currentScrollY = (scroll * (optionEndY - camera.height)));
		scrollBar.onInteract.add(function() autoScroll = false);
		add(scrollBar);
		
		titleText = new FlxText(panelX, 112, 700, Lang.str('opt_category_controls'));
		titleText.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.y += Math.round((titleText.size - titleText.height) * .5);
		titleText.borderSize = 2;
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.camera = FlxG.camera;
		add(titleText);
		
		(camera = new FunkinCamera(panelX, topBound, 676, Std.int(bottomBound - topBound))).bgColor = 0;
		FlxG.cameras.add(camera, false);
		
		FlxG.cameras.add(fadeCamera = new FunkinCamera(), false);
		fadeCamera.bgColor = 0;
		
		initStateScript('ControlsSubState');
		scriptGroup.set('this', this);
		
		bgColor = 0;
		
		controlsGroup.add(new ControlsGroup("NOTES", [
			{label: "Left", action: NOTE_LEFT},
			{label: "Down", action: NOTE_DOWN},
			{label: "Up", action: NOTE_UP},
			{label: "Right", action: NOTE_RIGHT},
			null,
			{label: "Taunt", action: NOTE_TAUNT},
			null,
		], AnyOption));
		
		controlsGroup.add(new ControlsGroup("UI", [
			{label: "Left", action: UI_LEFT},
			{label: "Down", action: UI_DOWN},
			{label: "Up", action: UI_UP},
			{label: "Right", action: UI_RIGHT},
			null,
			{label: "Reset", action: RESET},
			{label: "Pause", action: PAUSE},
			null,
		], KeysOption));
		
		controlsGroup.add(new ControlsGroup("VOLUME", [
			{label: "Mute", action: "volume_mute"},
			{label: "Up", action: "volume_up"},
			{label: "Down", action: "volume_down"},
			null,
		], KeysOption));
		
		controlsGroup.add(new ControlsGroup("DEBUG", [
			{label: "Key 1", action: "debug_1"},
			{label: "Key 2", action: "debug_2"},
			null,
		], KeysOption));
		
		controlsGroup.add(new ControlsGroup("", [{label: 'Reset to Default Buttons', fun: function(_) resetGamepadBinds()}], GamepadOption));
		controlsGroup.add(new ControlsGroup("", [{label: 'Reset to Default Keys', fun: function(_) resetKeyBinds()}], KeysOption));
		
		this.device = device;
		
		refreshOptionsList();
		
		add(controlsGroup);
		
		index = 0;
		currentBindIndex = 0;
		for (i in 1...optionsList.length)
		{
			optionsList[i].index = 0;
			optionsList[i].index = NONE;
		}
		
		scrollBar.setMetrics(camera.height, optionEndY);
		
		scriptGroup.call('onCreatePost', []);
	}
	
	public function resetGamepadBinds():Void
	{
		ClientPrefs.gamepadBinds = ClientPrefs.defaultGamepadBinds.copy();
		
		for (option in optionsList)
			option.refreshAll(device);
			
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}
	
	public function resetKeyBinds():Void
	{
		ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
		
		for (option in optionsList)
			option.refreshAll(device);
			
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}
	
	function refreshOptionsList()
	{
		var y:Float = 0;
		
		optionsList.resize(0);
		
		for (group in controlsGroup)
		{
			if (group.matchDevice(device))
			{
				group.revive();
				
				for (option in group.options)
				{
					optionsList.push(option);
					option.refreshAll(device);
				}
				
				group.y = (controlsGroup.y + y);
				y += group.height;
				optionEndY = (controlsGroup.y + y);
			}
			else
			{
				group.kill();
			}
		}
		
		if (index >= optionsList.length) index = (optionsList.length - 1);
	}
	
	var leaving:Bool = false;
	var bindingTime:Float = 0;
	var mouseControlActive:Bool = false;
	
	override function update(elapsed:Float)
	{
		inline function handleIndex()
		{
			if (!(controls.UI_UP_P && controls.UI_DOWN_P) && (controls.UI_UP_P || controls.UI_DOWN_P))
			{
				if (controls.UI_UP_P)
				{
					index--;
				}
				else if (controls.UI_DOWN_P)
				{
					index++;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
			if (FlxG.mouse.wheel != 0)
			{
				index -= FlxG.mouse.wheel;
				
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}
		}
		
		switch (state)
		{
			case BindState.NONE: // cause controls.ACCEPT is true on the first frame
				state = SELECT;
				
			case SELECT:
				// check for device changes
				final key = FlxG.keys.firstJustPressed();
				final gamepad = FlxG.gamepads.getFirstActiveGamepad();
				
				device = switch (device)
				{
					case Keys if (gamepad != null): Gamepad(gamepad.id);
					case Gamepad(_) if (key > -1): Keys;
					case Gamepad(id) if (gamepad != null && id != gamepad.id): Gamepad(gamepad.id);
					case d: d;
				}
				
				handleIndex();
				
				if (!(controls.UI_LEFT_P && controls.UI_RIGHT_P) && (controls.UI_LEFT_P || controls.UI_RIGHT_P))
				{
					mouseControlActive = false;
					
					if (controls.UI_LEFT_P) currentBindIndex--;
					else if (controls.UI_RIGHT_P) currentBindIndex++;
					
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if (controls.BACK)
				{
					mouseControlActive = false;
					
					// ClientPrefs.reloadControls();
					close();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
				if (controls.ACCEPT)
				{
					mouseControlActive = false;
					
					selectOption();
				}
				
			case REBIND:
				var inputID:Int = switch device
				{
					case Keys: FlxG.keys.firstJustPressed();
					case Gamepad(id): FlxG.gamepads.getByID(id).firstJustPressedID();
				}
				
				if (inputID > -1)
				{
					currentOption.change(device, inputID);
					FlxG.sound.play(Paths.sound('confirmMenu'));
					state = SELECT;
					
					if (currentBind != null) currentBind.visible = true;
				}
				
				bindingTime += elapsed;
				if (bindingTime > 5)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					state = SELECT;
					bindingTime = 0;
					
					if (currentBind != null) currentBind.visible = true;
				}
		}
		
		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.wheel != 0) mouseControlActive = true;
		if (controls.UI_UP_P || controls.UI_DOWN_P || controls.UI_LEFT_P || controls.UI_RIGHT_P || controls.ACCEPT || controls.BACK) mouseControlActive = false;
		
		if (mouseControlActive && state == SELECT && FlxG.mouse.justMoved)
		{
			for (i => option in optionsList)
			{
				var hoveredBind:Int = -1;
				
				for (j => bindText in option.binds.members)
				{
					if (bindText.visible && FlxG.mouse.overlaps(bindText, camera))
					{
						hoveredBind = j;
						break;
					}
				}
				
				if (hoveredBind != -1 || FlxG.mouse.overlaps(option.label, camera))
				{
					if (index != i) index = i;
					
					if (hoveredBind != -1) currentBindIndex = hoveredBind;
					if (FlxG.mouse.justPressed && state == SELECT) selectOption();
					
					break;
				}
			}
		}
		
		super.update(elapsed);
		
		final target:FlxObject = currentOption;
		
		if (autoScroll)
		{
			final scrollPad:Float = 64;
			
			var targetY = camera.scroll.y;
			
			targetY = Math.min(targetY, target.y - scrollPad);
			targetY = Math.max(targetY, target.y + target.height - camera.height + scrollPad);
			targetY = FlxMath.bound(targetY, 0, optionEndY);
			
			currentScrollY = FlxMath.lerp(currentScrollY, targetY, FlxMath.getElapsedLerp(.16, elapsed));
		}
		
		camera.scroll.y = currentScrollY;
	}
	
	public function selectOption():Void
	{
		if (currentOption.fun != null) currentOption.fun(currentOption);
		
		if (currentBind != null)
		{
			state = REBIND;
			currentBind.visible = false;
		}
	}
	
	inline function updateOptionFlash():Void
	{
		autoScroll = true;
		
		for (i => option in optionsList)
		{
			if (i != index) option.index = NONE;
			option.label.alpha = (i == index) ? 1.0 : 0.6;
		}
		
		for (group in controlsGroup)
			group.label.alpha = (currentGroup == group) ? 1.0 : 0.6;
	}
	
	function set_device(device:Device):Device
	{
		if (this.device != device)
		{
			this.device = device;
			refreshOptionsList();
		}
		
		return device;
	}
	
	function get_currentGroup():Null<ControlsGroup>
	{
		return cast currentOption.container.container;
	}
	
	function set_currentGroup(currentGroup:ControlsGroup):ControlsGroup
	{
		if (currentGroup == null)
		{
			index = 0;
			return controlsGroup.members[0];
		}
		index = optionsList.indexOf(currentGroup.options.members[0]);
		return get_currentGroup();
	}
	
	function get_currentOption():ControlsOption
	{
		return optionsList[index];
	}
	
	function set_currentOption(currentOption:ControlsOption):ControlsOption
	{
		index = optionsList.indexOf(currentOption);
		return currentOption;
	}
	
	function set_index(index:Int):Int
	{
		index = FlxMath.wrap(index, 0, optionsList.length - 1);
		if (state != BindState.NONE) state = SELECT;
		
		if (this.index != index)
		{
			if (optionsList[this.index] != null && state == SELECT)
			{
				final bindIndex = currentBindIndex;
				optionsList[index].index = bindIndex;
			}
			
			this.index = index;
			
			updateOptionFlash();
			
			if (currentBindIndex == NONE) currentBindIndex = 0;
		}
		
		return index;
	}
	
	function get_currentBind():Null<FlxText>
	{
		return currentOption.binds.members[currentBindIndex];
	}
	
	function set_currentBind(currentBind:FlxText):Null<FlxText>
	{
		final index = currentOption.binds.members.indexOf(currentBind);
		if (index != -1) currentBindIndex = index;
		return currentBind;
	}
	
	function get_currentBindIndex():Int
	{
		return currentOption.index;
	}
	
	function set_currentBindIndex(currentBindIndex:Int):Int
	{
		currentOption.index = currentBindIndex;
		
		updateOptionFlash();
		
		return currentBindIndex;
	}
	
	override function destroy()
	{
		// check before to prevent a annoying warning
		if (FlxG.cameras.list.indexOf(fadeCamera) != -1 && fadeCamera != null) FlxG.cameras.remove(fadeCamera);
		if (FlxG.cameras.list.indexOf(camera) != -1 && camera != null) FlxG.cameras.remove(camera);
		super.destroy();
	}
}

class ControlsGroup extends FlxSpriteContainer
{
	public var label:FlxText;
	
	public var options = new FlxTypedSpriteContainer<ControlsOption>();
	
	public var bg:FlxSprite;
	public var hitbox:FlxSprite;
	
	public var groupLastIndex:Int;
	
	public var type:ControlsOptionType;
	
	var lineHeight:Float = 24;
	
	public function new(label:String = '', options:Array<{label:String, ?action:Action, ?fun:ControlsOption->Void}>, ?type:ControlsOptionType = AnyOption)
	{
		super();
		
		this.type = type;
		this.label = new FlxText(0, 0, 200, label);
		this.label.setFormat(Paths.font('vcr'), 20, FlxColor.WHITE /*0xFF62E0CF*/, LEFT, OUTLINE, FlxColor.BLACK);
		this.label.borderSize = 1;
		
		if (label.length > 0) add(this.label);
		
		var startY:Float = (label.length > 0 ? lineHeight : 0);
		
		hitbox = new FlxSprite(0, startY);
		hitbox.setSize(1, options.length * lineHeight + 10);
		hitbox.visible = false;
		add(hitbox);
		
		bg = new FlxSprite(0, startY).makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = .5;
		add(bg);
		
		var maxBgIndex:Int = 0;
		for (i => option in options)
		{
			if (option != null)
			{
				this.options.add(new ControlsOption(5, startY + lineHeight * i + 5, option.label, option.action, option.fun));
				
				maxBgIndex = (i + 1);
			}
		}
		
		bg.setGraphicSize(FlxG.width, maxBgIndex * lineHeight + 10);
		bg.updateHitbox();
		
		add(this.options);
	}
	
	public function matchDevice(device:Device):Bool
	{
		if (type == AnyOption) return true;
		
		return switch (device)
		{
			default: false;
			case Keys: (type == KeysOption);
			case Gamepad(_): (type == GamepadOption);
		}
	}
}

class ControlsOption extends FlxSpriteContainer
{
	public var label:FlxText;
	
	public var action:Action;
	
	public var binds:FlxTypedSpriteContainer<FlxText>;
	
	public var index(default, set):Int = -1;
	
	public var fun:ControlsOption->Void;
	
	public function new(x = .0, y = .0, label:String, ?action:Action, ?fun:ControlsOption->Void)
	{
		super(x, y);
		this.label = new FlxText(0, 0, 500, label);
		this.label.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		this.label.borderSize = 1;
		add(this.label);
		
		binds = new FlxTypedSpriteContainer<FlxText>(0, 0);
		add(binds);
		
		this.action = action;
		this.fun = fun;
		
		index = 0;
		index = ControlsSubState.NONE;
	}
	
	public function refreshAll(device:Null<Device>)
	{
		final binds:Array<Int> = (getBinds(device) ?? [] /* whatever bro*/);
		
		for (i => _ in binds)
		{
			if (this.binds.members[i] == null)
			{
				var text:FlxText = new FlxText(250 + 200 * i, 0, 200);
				text.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				text.borderSize = 1;
				
				this.binds.add(text);
			}
			
			refreshBind(device, i);
		}
		
		if (binds.length < this.binds.length)
		{
			for (i in binds.length...this.binds.length)
				this.binds.members[i].visible = false;
		}
	}
	
	function refreshBind(device:Device, index:Int)
	{
		final inputID:Int = getBinds(device)[index];
		final alpha = binds.members[index].alpha;
		binds.members[index].visible = true;
		binds.members[index].text = switch (device)
		{
			case Keys: InputFormatter.getKeyName(inputID);
			case Gamepad(id): FlxG.gamepads.getByID(id).getInputLabel(inputID).toUpperCase();
		};
		binds.members[index].alpha = alpha;
	}
	
	/**
	 * Changes the current selected option index to the bind
	 * @param device 
	 * @param inputID 
	 */
	public function change(device:Device, inputID:Int)
	{
		final binds:Array<Int> = getBinds(device);
		final altIndex = binds.indexOf(inputID);
		if (altIndex != -1) binds[altIndex] = binds[index];
		binds[index] = inputID;
		refreshBind(device, index);
	}
	
	function set_index(index:Int):Int
	{
		if (index != ControlsSubState.NONE)
		{
			var len = binds.length - 1;
			while (len > 0 && !binds.members[len].visible)
				len--;
			if (len < 0) len = 0;
			
			index = FlxMath.wrap(index, 0, len);
		}
		
		if (this.index != index)
		{
			for (i => bind in binds.members)
			{
				bind.alpha = (i == index ? 1.0 : 0.6);
				bind.color = (i == index ? 0xffffe066 : FlxColor.WHITE);
			}
			this.index = index;
		}
		
		return index;
	}
	
	inline function getBinds(device:Null<Device>):Array<Int>
	{
		if (device == null) return [];
		
		return switch (device)
		{
			default: [];
			case Keys: ClientPrefs.keyBinds.get(action);
			case Gamepad(_): ClientPrefs.gamepadBinds.get(action);
		}
	}
}

enum abstract BindState(Int)
{
	var NONE;
	var SELECT;
	var REBIND;
}

enum abstract ControlsOptionType(String) to String
{
	var AnyOption = 'any';
	var KeysOption = 'keys';
	var GamepadOption = 'gamepad';
}
