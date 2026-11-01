package funkin.objects.note;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.Character;
import funkin.game.Rating;
import funkin.data.*;

typedef NoteSignal = FlxTypedSignal<(Note, PlayField) -> Void>;

class PlayField extends FlxTypedContainer<StrumNote>
{
	public var _skin:NoteSkin;
	
	public var owner(get, set):Character;
	public var singers:Array<Null<Character>> = [];
	public var quants(default, set):Bool = ClientPrefs.quants;
	
	public var hasChangedSkin:Bool = false;
	
	private function set_quants(value:Bool)
	{
		quants = value;
		
		for (i in members)
		{
			if (i != null)
			{
				i.isQuant = quants;
				i.reloadNote();
			}
		}
		
		return value;
	}
	
	function set_owner(value:Character)
	{
		singers.remove(owner);
		singers.unshift(value);
		
		return value;
	}
	
	function get_owner():Character
	{
		return singers[0];
	}
	
	public var onNoteHit:NoteSignal = new NoteSignal();
	public var onNoteMiss:NoteSignal = new NoteSignal();
	public var onGhostTap:FlxTypedSignal<(Int, PlayField) -> Void> = new FlxTypedSignal();
	public var onMissPress:FlxTypedSignal<(Int, PlayField) -> Void> = new FlxTypedSignal();
	
	public var playAnims:Bool = true;
	public var noteSplashes:Bool = false;
	public var autoPlayed:Bool = false;
	public var isPlayer:Bool = false;
	public var playerControls:Bool = false;
	public var inControl(default, set):Bool = true; // incase you want to lock up the playfield
	
	public var trackNoteSplashes:Bool = true;
	public var trackSustainSplashes:Bool = true; // splash angle follows sustain angle
	
	public var notes:Array<Note> = [];
	public var keyCount(default, set):Int = 0;
	
	public var underlay:LaneUnderlay;
	
	public var swagWidth(get, never):Float;
	
	public var showRatings:Bool = false;
	
	public function get_swagWidth()
	{
		return Note.swagWidth;
	}
	
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var baseAlpha:Float = 1;
	public var offsetReceptors:Bool = false;
	public var player:Int = 0;
	public var alpha(default, set):Float = 1;
	
	public var holdDropLeniency:Float = (1 / 3);
	public var antiMashMax:Float = 50;
	
	public var antiMash:Float = 0;
	
	public function set_alpha(value:Float)
	{
		value = FlxMath.bound(value, 0, 1);
		for (strum in members)
		{
			strum.alphaMult = value;
		}
		return alpha = value;
	}
	
	public function set_keyCount(value:Int)
	{
		keyCount = value;
		if (members.length > 0) generateReceptors();
		return keyCount;
	}
	
	public function set_inControl(value:Bool)
	{
		if (!value)
		{
			for (strum in members)
			{
				strum.playAnim("static");
				strum.resetAnim = 0;
			}
		}
		return inControl = value;
	}
	
	public var splashLayer:FlxTypedContainer<FlxTypedContainer<Dynamic>>;
	
	/**
	 * The container that all notesplashes are held in
	 */
	public var grpNoteSplashes:FlxTypedContainer<NoteSplash>;
	
	/**
		The container that all sustain notesplashes are held in
	**/
	public var grpSusSplashes:FlxTypedContainer<SustainSplash>;
	
	public function new(x:Float, y:Float, keyCount:Int = 4, ?who:Character, isPlayer:Bool = false, cpu:Bool = false, ?playerControls:Bool, player:Int = 0, skin:String = 'default')
	{
		super();
		if (playerControls == null) playerControls = isPlayer;
		
		this.autoPlayed = cpu;
		
		this.owner = who;
		this.isPlayer = isPlayer;
		this.playerControls = playerControls;
		this.player = player;
		
		this.baseX = x;
		this.baseY = y;
		this.keyCount = keyCount;
		
		underlay = new LaneUnderlay(this);
		underlay.baseAlpha = ClientPrefs.laneUnderlayAlpha;
		
		this._skin = new NoteSkin(skin, keyCount, player);
		NoteUtil.noteskins.push(this._skin);
		
		splashLayer = new FlxTypedContainer();
		
		grpNoteSplashes = new FlxTypedContainer<NoteSplash>();
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0, player);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		grpSusSplashes = new FlxTypedContainer<SustainSplash>();
		
		var sus = new SustainSplash(0, 0, 0, 0);
		grpSusSplashes.add(sus);
		sus.alpha = 0.0;
		
		splashLayer.add(grpSusSplashes);
		splashLayer.add(grpNoteSplashes);
		
		this.onNoteHit.add(noteHit);
		this.onNoteMiss.add(noteMiss);
		this.onGhostTap.add(ghostTap);
		this.onMissPress.add(noteMissPress);
	}
	
	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		antiMash = MathUtil.decayLerp(antiMash, 0, 5 / (antiMash / antiMashMax + 1), elapsed);
	}
	
	public function clearReceptors()
	{
		while (members.length > 0)
		{
			var note:StrumNote = members.pop();
			note.kill();
			note.destroy();
		}
	}
	
	public function generateReceptors()
	{
		clearReceptors();
		for (data in 0...keyCount)
		{
			var babyArrow:StrumNote = new StrumNote(player, baseX, baseY, data, this);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alphaMult = alpha;
			add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}
	
	public function fadeIn(skip:Bool = false)
	{
		for (data in 0...members.length)
		{
			var babyArrow:StrumNote = members[data];
			if (skip) babyArrow.alpha = baseAlpha;
			else
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: baseAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * data)});
			}
		}
	}
	
	public function getNotes(dir:Int, ?get:Note->Bool):Array<Note>
	{
		var collected:Array<Note> = [];
		for (note in notes)
		{
			if (note.alive && note.noteData == dir && !note.wasGoodHit && !note.tooLate && note.canBeHit)
			{
				if (get == null || get(note)) collected.push(note);
			}
		}
		return collected;
	}
	
	public function getTapNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> !note.isSustainNote);
	
	public function getHoldNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> note.isSustainNote);
	
	/**
	 * Removes a note from this
	 * @param note 
	 */
	public inline function removeNote(note:Note)
	{
		notes.remove(note);
		
		note.scale.copyFrom(note.baseScale);
		note.updateHitbox();
		
		if (note.playField == this) note.playField = null;
	}
	
	public inline function addNote(note:Note)
	{
		notes.push(note);
		
		note.player = player;
		
		// hotswapping catch all
		note.skin = _skin;
		note.texture = _skin.noteTexture;
		note.rgbEnabled = _skin.inEngineColoring;
		note.rgbShader.enabled = note.rgbEnabled;
		
		if (hasChangedSkin) note.updateColors();
		
		note.baseScale.copyFrom(note.scale);
		note.updateHitbox();
		
		if (note.playField != this || note.playField == null) note.playField = this;
		
		note.strum = members[note.noteData];
	}
	
	public function forEachAliveNote(func:Note->Void)
	{
		for (note in notes)
			if (note != null && note.exists && note.alive) func(note);
	}
	
	public inline function disposeNote(note:Note):Void
	{
		note.kill();
		
		removeNote(note);
	}
	
	public static function noteHit(note:Note, field:PlayField):Void
	{
		var scriptFunc:String = '';
		if (field.playerControls) scriptFunc = 'goodNoteHit';
		else scriptFunc = field.ID == 1 ? 'opponentNoteHit' : 'extraNoteHit';
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		PlayState.instance.scripts.call('${scriptFunc}Pre', scriptArgs);
		
		final strum:StrumNote = note.strum;
		
		if (strum != null)
		{
			strum.copyNoteColor(note);
			strum.playAnim('confirm', true);
			
			if (field.autoPlayed)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.isSustainEnd) time += 0.15;
				time /= PlayState.instance.playbackRate;
				
				strum.resetAnim = time;
			}
		}
		
		if (!note.isSustainNote)
		{
			for (sustain in note.tail) // makes the hold note active when you press the base note
			{
				if (sustain.parent != note) continue; // ignore notes that have already been recycled
				
				sustain.blockHit = false;
			}
		}
		else if (strum != null)
		{
			strum.coyoteTime = field.holdDropLeniency;
		}
		
		if (field.playerControls)
		{
			if (note.wasGoodHit || field.autoPlayed && (note.ignoreNote || note.hitCausesMiss || note.canMiss)) return;
			
			if (!note.isSustainNote) note.ratingData = (Rating.judgeNote(note, Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset) / PlayState.instance.playbackRate));
			
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			
			if (note.hitCausesMiss)
			{
				field.onNoteMiss.dispatch(note, field);
				
				note.wasGoodHit = true;
				
				if (!note.isSustainNote) field.disposeNote(note);
				
				return;
			}
			
			final susMult:Float = (note.isSustainNote ? 1 / PlayState.instance.holdSubdivisions : 1);
			
			PlayState.instance.health += (note.hitHealth * PlayState.instance.healthGain * susMult * (note.ratingData?.healthMod ?? 1));
			PlayState.instance.missCombo = 0;
		}
		
		var chars:Array<Null<Character>> = note.gfNote ? [PlayState.instance.gf] : field.singers;
		if (note.owner != null) chars = (note.singers != null && note.singers.length > 0 ? note.singers : [note.owner]);
		
		for (char in chars)
			if (char != null) characterSing(char, note, field.playerControls);
			
		note.wasGoodHit = true;
		
		if (field.noteSplashes && (!field.playerControls || note.ratingData?.noteSplash)) field.spawnSplash(note);
		field.spawnSusSplash(note, field.playerControls);
		
		final globalScript = PlayState.instance.callNoteTypeScript(note.noteType, 'hit', scriptArgs);
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, scriptFunc, scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call(scriptFunc, scriptArgs, false, [note.noteType]);
		
		if (!note.isSustainNote) field.disposeNote(note);
	}
	
	public static function noteMiss(note:Note, field:PlayField):Void
	{
		final susMult:Float = (note.isSustainNote ? 1 / PlayState.instance.holdSubdivisions : 1);
		
		if (field.playerControls)
		{
			final missMult:Float = (note.missHealth * PlayState.instance.healthLoss);
			
			if (!note.isSustainNote)
			{
				var combo = (++ PlayState.instance.missCombo);
				PlayState.instance.health -= (missMult * (combo + 1) / 2);
			}
			else
			{
				PlayState.instance.health -= (missMult * susMult);
			}
		}
		
		for (owner in field.singers)
		{
			var char:Character = owner;
			if (note.gfNote) char = PlayState.instance.gf;
			
			if (char != null && !note.noMissAnimation)
			{
				if (char.animTimer <= 0)
				{
					var daAlt = '';
					if (note.noteType == 'Alt Animation') daAlt = '-alt';
					
					var animToPlay:String = field._skin.singAnimations[Std.int(Math.abs(note.noteData))] + 'miss' + daAlt;
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
				}
			}
		}
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, 'noteMiss', scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call('noteMiss', scriptArgs, false, [note.noteType]);
		
		// hold note missing stuff, makes the hold unhittable (and kills it, might make it just transparent if i can fix some stuff)
		if (!note.hitCausesMiss && !note.canMiss)
		{
			note.tailState.missed = true;
			
			for (sustain in note.tail)
			{
				if (sustain.parent != note.parent) continue; // ignore notes that have already been recycled
				
				sustain.tooLate = true;
				sustain.blockHit = true;
				sustain.ignoreNote = true;
				sustain.copyAlpha = false;
				sustain.alpha = 0.3;
			}
		}
	}
	
	public static function ghostTap(key:Int, field:PlayField):Void
	{
		field.antiMash = Math.min(field.antiMash + field.notes.length * 5, field.antiMashMax);
	}
	
	public static function noteMissPress(key:Int, field:PlayField):Void
	{
		for (char in field.singers)
		{
			if (char == null) continue;
			
			if (char.animTimer <= 0)
			{
				char.playAnim(field._skin.singAnimations[Std.int(Math.abs(key))] + 'miss', true);
				char.holdTimer = 0;
			}
		}
	}
	
	@:access(funkin.states.PlayState)
	public static function characterSing(char:Character, note:Note, hold:Bool = false)
	{
		if (note.noAnimation) return;
		
		final animToPlay = note.skin.singAnimations[Std.int(Math.abs(note.noteData))] + note.animSuffix;
		
		char.holdTimer = 0;
		
		if (hold && !note.playField?.autoPlayed)
		{
			PlayState.instance?.holders.push(char);
			
			char.holding = true;
		}
		
		switch (note.noteType)
		{
			case 'Hey!' if (char.animation.exists('hey')):
				char.playAnimForDuration('hey', 0.6);
				char.specialAnim = true;
				return;
		}
		
		// ghost stuff
		
		if (!char.vSliceSustains || !note.isSustainNote)
		{
			if (note.noteType == "Ghost Note")
			{
				char.playGhostAnim(note.noteData, animToPlay, true);
			}
			else
			{
				final ghostAnim:String = char.getAnimName();
				
				if (!note.isSustainNote && Math.abs(char.lastHitTime - note.strumTime) < 3 && ClientPrefs.jumpGhosts
					&& PlayState.instance?.scripts.call('onGhostAnim', [ghostAnim, note]) != ScriptConstants.STOP_FUNC)
				{
					char.playGhostAnim(note.noteData, ghostAnim, true);
				}
				
				char.playAnim(animToPlay, true);
				
				if (!note.isSustainNote || note.prevNote?.isSustainNote) char.lastHitTime = note.strumTime;
			}
		}
	}
	
	public function spawnSplash(note:Note):NoteSplash
	{
		if (ClientPrefs.noteSplashes
			&& note != null
			&& !note.hitCausesMiss
			&& !note.isSustainNote
			&& !note.noteSplashDisabled
			&& noteSplashes
			&& _skin?.splashesEnabled ?? true)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				final skin:String = _skin.splashTexture;
				
				var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				splash.setupNoteSplash(strum, note, skin, note.rgbShader, this);
				grpNoteSplashes.add(splash);
				
				PlayState.instance.scripts.call('onSpawnNoteSplash', [splash, note]);
				
				return note.noteSplash = splash;
			}
		}
		
		return null;
	}
	
	public function spawnSusSplash(note:Note, isPlayer:Bool = false):SustainSplash
	{
		if (_skin?.sustainSplashes && note.tailState.splash == null && note.tail.length > 0)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				var splash:SustainSplash = grpSusSplashes.recycle(SustainSplash);
				splash.setupSplash(strum, note, isPlayer, note.rgbShader, this);
				grpSusSplashes.add(splash);
				
				PlayState.instance.scripts.call('onSpawnSustainSplash', [splash, note]);
				
				return note.tailState.splash = note.sustainSplash = splash;
			}
		}
		
		return null;
	}
	
	public inline function canInput():Bool
	{
		return (playerControls && inControl && !autoPlayed && (owner == null || !owner.stunned));
	}
	
	public function changeSkin(newSkin:NoteSkin)
	{
		_skin = newSkin;
		NoteUtil.noteskins[player] = newSkin;
		
		// that way it checks the colors and re-assigns
		this.hasChangedSkin = true;
		
		forEachAlive((strum) -> {
			strum.skin = _skin;
			strum.texture = _skin.noteTexture;
			strum.useRGBShader = _skin.inEngineColoring;
			strum.rgbGraphics.enabled = strum.useRGBShader;
			strum.reloadNote();
			
			strum.playAnim('static');
			strum.resetAnim = 0;
		});
		
		forEachAliveNote((note) -> {
			note.skin = _skin;
			note.texture = _skin.noteTexture;
			note.rgbEnabled = _skin.inEngineColoring;
			note.rgbGraphics.enabled = note.rgbEnabled;
			note.loadNoteAnims();
			
			note.reloadNote('', note.texture, '');
			
			note.scale.set(_skin.noteScale, _skin.noteScale);
			note.baseScale.copyFrom(note.scale);
			
			note.rgbGraphics = NoteUtil.getCurColors(note.noteData, note.quant, note.player);
		});
		
		grpNoteSplashes.forEachAlive((splash) -> {
			splash.scale.set(_skin.splashScale, _skin.splashScale);
			splash.baseScale.copyFrom(splash.scale);
			
			splash.rgbGraphics.enabled = _skin.inEngineColoring;
		});
		grpSusSplashes.forEachAlive((splash) -> {
			splash.scale.set(_skin.susSplashScale, _skin.susSplashScale);
			splash.baseScale.copyFrom(splash.scale);
			
			splash.rgbGraphics.enabled = _skin.inEngineColoring;
		});
	}
	
	// just because
	override public function toString():String
	{
		var str = 'keys: $keyCount, pos: [x: $baseX, y: $baseY], skin: ${_skin.name}';
		
		if (owner != null && singers.length > 0)
		{
			str += ', owner: ${owner?.curCharacter ?? 'dad'}, singers: ${[for (i in singers) (i?.curCharacter ?? 'null')]}';
		}
		
		return '($str)';
	}
	
	override function destroy()
	{
		onNoteHit.removeAll();
		onNoteHit.destroy();
		
		onNoteMiss.removeAll();
		onNoteMiss.destroy();
		
		onMissPress.removeAll();
		onMissPress.destroy();
		
		underlay.destroy();
		super.destroy();
	}
}
