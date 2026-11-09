package funkin.objects.menu;

import flixel.group.FlxSpriteGroup;

import funkin.states.FreeplayState;
import funkin.scripts.FunkinScript;

typedef Rank =
{
	var text:String;
	var color:FlxColor;
}

class FreeplayCard extends FlxSpriteGroup
{
	public var curScript:FunkinScript;
	
	var ext:String = 'menu/freeplay/';
	
	public var card:FunkinSprite;
	public var name:FlxText;
	public var icon:HealthIcon;
	public var lock:FunkinSprite;
	public var bean:FunkinSprite;
	public var priceText:FlxText;
	public var rank:FlxText;
	public var credit:FlxText;
	public var songName:String = 'PLAY';
	public var note:FunkinSprite;
	public var unlocked:Bool = false;
	public var accString:String = 'F';
	
	public var meta:SongInformation;
	
	var shuffleLetters:Array<String>;
	
	var shuffleTimer:FlxTimer = null;
	
	var price:Int = 0;
	
	public function new()
	{
		super();
		
		directAlpha = true;
		
		preCreate();
	}
	
	inline function preCreate():Void
	{
		card = new FunkinSprite();
		name = new FlxText(0, 0, 500);
		name.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		icon = new HealthIcon();
		
		lock = new FunkinSprite();
		bean = new FunkinSprite();
		priceText = new FlxText(0, 0, 500, '', 28);
		priceText.setFormat(Paths.font("ariblk.ttf", false), 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		rank = new FlxText();
		rank.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		note = new FunkinSprite();
		credit = new FlxText(0, 0, 500);
		credit.setFormat(Paths.font('vcr.ttf', false), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		add(card);
		add(name);
		add(icon);
		
		add(lock);
		add(bean);
		add(priceText);
		add(rank);
		
		add(note);
		add(credit);
	}
	
	public function initCard(song:SongInformation):Void
	{
		final prevMod:Null<String> = Mods.currentModDirectory;
		Mods.currentModDirectory = song.mod;
		
		FlxTween.cancelTweensOf(card);
		FlxTween.cancelTweensOf(name);
		FlxTween.cancelTweensOf(lock);
		shuffleTimer?.cancel();
		
		meta = song;
		price = song.cost;
		songName = song.songName;
		
		var scriptPath:String = FunkinScript.getPath('scripts/freeplayCards/${Paths.sanitize(song.songName)}');
		
		if (FunkinAssets.exists(scriptPath)) {
			curScript = FunkinScript.fromFile(scriptPath, false);
			
			if (curScript.__garbage)
			{
				curScript = null;
			}
			else
			{
				curScript.addParent(this);
				
				curScript.tryExecute();
			}
		}
		
		unlocked = requirementIsComplete();
		
		card.color = icon.color = name.color = lock.color = FlxColor.WHITE;
		
		if (!unlocked)
		{
			if (isSuperSecret())
			{
				Mods.currentModDirectory = prevMod;
				
				return kill();
			}
			
			lockCard();
		}
		
		lock.loadAtlas(ext + (meta.lock == 'special' ? 'lockGold' : 'lock'));
		
		final accuracy:Float = Highscore.getRating(songName.toLowerCase(), 1) * 100;
		final misses:Int = Highscore.getMisses(songName.toLowerCase(), 1);
		final accStats:Rank = getRank(accuracy, misses);
		
		rank.text = accStats.text;
		rank.color = accStats.color;
		
		bean.loadGraphic(Paths.image('currency/${song.currency}'));
		card.loadGraphic(Paths.image('menu/freeplay/card'));
		
		bean.setGraphicSize(0, 40);
		bean.updateHitbox();
		
		name.setPosition(card.x + 110, card.y - 5);
		name.text = songName;
		
		icon.changeIcon(song.icon);
		icon.setGraphicSize(Std.int(icon.frameWidth * 0.6));
		icon.setPosition(card.x - 13, card.y - 23);
		
		priceText.setPosition(card.x + 440, card.y - 20);
		bean.setPosition(card.x + 405, card.y - 20);
		lock.setPosition(card.x + 25, card.y + 9);
		rank.setPosition(card.x + 450, card.y + (card.height / 2) - rank.height / 2); // FUCK IM GAY AND I LOVE SUCKING COCK.
		
		note.loadGraphic(Paths.image(ext + 'musicNote'));
		note.setPosition(card.x + 110, card.y + 75);
		
		credit.setPosition(card.x + 130, card.y + 72);
		credit.text = song.credit;
		
		refresh();
		
		if (curScript != null) curScript.executeFunc('onLoad', [], this);
		
		Mods.currentModDirectory = prevMod;
	}
	
	function refresh():Void
	{
		priceText.kill();
		bean.kill();
		
		if (unlocked)
		{
			lock.kill();
			rank.revive();
			note.revive();
			credit.revive();
		}
		else
		{
			if (meta.cost > 0)
			{
				priceText.revive();
				bean.revive();
			}
			
			lock.revive();
			rank.kill();
			note.kill();
			credit.kill();
		}
	}
	
	public function lockCard():Void
	{
		unlocked = false;
		shuffleLetters = meta.songName.split('');
		
		#if (!hl)
		doShuffle();
		shuffleTimer = new FlxTimer().start(FlxG.random.float(0.1, 0.2), (_) -> doShuffle(), 0);
		#else
		name.text = '???';
		#end
		
		lock.addAnimByPrefix('lock', 'lock0', 24, true);
		lock.addAnimByPrefix('unlock', 'lock open', 24, false);
		lock.playAnim('lock', true);
		
		icon.color = FlxColor.BLACK;
		card.color = 0xFF4A4A4A;
		
		if (meta.cost > 0) priceText.text = Std.string(meta.cost);
		
		refresh();
	}
	
	public function unlockCard():Void
	{
		unlocked = true;
		card.color = icon.color = FlxColor.WHITE;
		name.text = songName;
		
		refresh();
		
		shuffleTimer?.cancel();
		
		curScript?.executeFunc('onUnlock', [], this);
	}
	
	public static function getRank(acc:Float, misses:Int = 0):Rank
	{
		return switch (Highscore.getLetterRank(acc, misses))
		{
			case 'P' if (acc == 100 && misses == 0): {text: 'P', color: 0xFFEDA3F7};
			case 'P': {text: 'P', color: 0xFF00FF00};
			case 'S': {text: 'S', color: 0xFFFFFF00};
			case 'A': {text: 'A', color: 0xFFFFFFFF};
			case 'B': {text: 'B', color: 0xFFFFFFFF};
			case 'C': {text: 'C', color: 0xFFFFFFFF};
			case 'D': {text: 'D', color: 0xFFFFFFFF};
			case 'F' if (acc > 0 || misses > 0): {text: 'F', color: 0xFFFF0000};
			default: {text: '', color: 0xFFFF0000};
		};
	}
	
	function doShuffle():Void
	{
		if (unlocked || alpha <= 0.3) return;
		
		FlxG.random.shuffle(shuffleLetters);
		name.text = shuffleLetters.join('');
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		curScript?.executeFunc('onUpdate', [elapsed], this);
		curScript?.executeFunc('onUpdatePost', [elapsed], this);
	}
	
	public function requirementIsComplete():Bool
	{
		if (ClientPrefs.unlockedSongs.contains(meta.songName) || ProgressionUtil.songIsClear(meta.songName) || ClientPrefs.forceUnlock) return true;
		
		var result:Dynamic = curScript?.executeFunc('requirementIsComplete', [], this);
		
		if (result != null) return (result is Bool && result == true);
		
		switch (meta.lock)
		{
			case 'special' | 'story':
				for (song in meta.requiredSongs)
				{
					if (!ProgressionUtil.songIsClear(song)) return false;
				}
				
			case 'shop':
				return false;
		}
		
		return true;
	}
	
	public inline function isSuperSecret():Bool
	{
		var result:Dynamic = curScript?.executeFunc('isSuperSecret', [], this);
		
		if (result != null) return (result is Bool && result == true);
		
		return false;
	}
	
	public inline function refreshPriceTxt():Void
	{
		if (priceText.visible && FlxG.state is funkin.states.FreeplayState)
		{
			@:privateAccess
			final beans = (cast FlxG.state : funkin.states.FreeplayState).localBeans;
			priceText.color = beans < price ? 0xFFFF6767 : FlxColor.WHITE;
		}

		curScript?.executeFunc('onRefreshPriceText', [], this);
	}
	
	public function unload():Void
	{
		curScript?.executeFunc('onDestroy', [], this);
		curScript?.destroy();
		curScript = null;
	}
	
	public override function destroy():Void
	{
		unload();
		super.destroy();
	}
}
