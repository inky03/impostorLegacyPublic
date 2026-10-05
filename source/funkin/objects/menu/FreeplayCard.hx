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
	
	public var card:FlxSprite;
	public var name:FlxText;
	public var icon:HealthIcon;
	public var lock:FlxSprite;
	public var bean:FlxSprite;
	public var priceText:FlxText;
	public var rank:FlxText;
	public var credit:FlxText;
	public var songName:String = 'PLAY';
	public var note:FlxSprite;
	public var songLock:Bool = false;
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
	
	inline function preCreate()
	{
		card = new FlxSprite();
		name = new FlxText(0, 0, 500);
		name.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		icon = new HealthIcon();
		
		lock = new FlxSprite();
		bean = new FlxSprite();
		priceText = new FlxText(0, 0, 500, '', 28);
		priceText.setFormat(Paths.font("ariblk.ttf", false), 28, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		rank = new FlxText();
		rank.setFormat(Paths.font('AmaticSC-Bold.ttf', false), 64, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		note = new FlxSprite();
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
	
	public function initCard(song:SongInformation, locked:Bool = false)
	{
		FlxTween.cancelTweensOf(card);
		FlxTween.cancelTweensOf(name);
		FlxTween.cancelTweensOf(lock);
		
		meta = song;
		
		songName = song.songName;
		songLock = locked;
		price = song.cost;
		shuffleLetters = songName.split('');
		
		shuffleTimer?.cancel();
		card.color = icon.color = name.color = lock.color = FlxColor.WHITE;
		
		bean.loadGraphic(Paths.image('currency/${song.currency}'));
		card.loadGraphic(Paths.image('menu/freeplay/card'));
		
		bean.setGraphicSize(0, 40);
		bean.updateHitbox();
		
		name.setPosition(card.x + 110, card.y - 5);
		name.text = songName;
		
		icon.changeIcon(song.icon);
		icon.setGraphicSize(Std.int(icon.frameWidth * 0.6));
		
		if (locked)
		{
			#if !hl
			doShuffle();
			shuffleTimer = new FlxTimer().start(FlxG.random.float(0.1, 0.2), function(tmr:FlxTimer) {
				doShuffle();
			}, 0);
			#else
			name.text = '???';
			#end
			
			final lockFile = song.lock != 'special' ? 'lock' : 'lockGold';
			lock.frames = Paths.getSparrowAtlas(ext + lockFile);
			
			lock.animation.addByPrefix('lock', 'lock0', 24, true);
			lock.animation.addByPrefix('unlock', 'lock open', 24, false);
			lock.animation.play('lock');
			lock.active = true;
			
			lock.setPosition(card.x + 25, card.y + 9);
			
			icon.color = FlxColor.BLACK;
			card.color = 0xFF4A4A4A;
			
			rank.text = '';
			
			if (song.cost > 0)
			{
				priceText.text = Std.string(song.cost);
				
				bean.setPosition(card.x + 405, card.y - 20);
				priceText.setPosition(card.x + 440, card.y - 20);
			}
		}
		else
		{
			var accuracy:Float = Highscore.getRating(songName.toLowerCase(), 1) * 100;
			var misses:Int = Highscore.getMisses(songName.toLowerCase(), 1);
			var accStats:Rank = getRank(accuracy, misses);
			
			rank.text = accStats.text;
			rank.color = accStats.color;
			
			rank.setPosition(card.x + 450, card.y + (card.height / 2) - rank.height / 2); // FUCK IM GAY AND I LOVE SUCKING COCK.
		}
		
		rank.visible = !locked;
		
		priceText.visible = locked && song.cost > 0;
		bean.visible = locked && song.cost > 0;
		lock.visible = locked;
		
		note.setPosition(card.x + 110, card.y + 75);
		note.loadGraphic(Paths.image(ext + 'musicNote'));
		
		note.visible = !locked;
		
		credit.setPosition(card.x + 130, card.y + 72);
		credit.text = song.credit;
		
		credit.visible = !locked;
		icon.setPosition(card.x - 13, card.y - 23);

		var scriptPath:String = FunkinScript.getPath('scripts/freeplayCards/${Paths.sanitize(song.songName)}');
		
		if (FunkinAssets.exists(scriptPath)) {
			curScript = FunkinScript.fromFile(scriptPath, false);
			
			if (curScript.__garbage)
			{
				curScript = null;
			}
			else
			{
				curScript.set('price', price);
				curScript.addParent(this);
				
				curScript.tryExecute();
				curScript.executeFunc('onLoad', [], this);
			}
		}
	}
	
	public function unlockCard()
	{
		bean.visible = false;
		lock.visible = false;
		priceText.visible = false;
		card.color = 0xFFFFFFFF;
		icon.color = 0xFFFFFFFF;
		credit.visible = true;
		note.visible = true;
		rank.visible = true;
		name.text = songName;
		if (shuffleTimer != null) shuffleTimer.cancel();
		curScript?.executeFunc('onUnlock', [], this);
	}
	
	function getRank(acc:Float, misses:Int = 0):Rank
	{
		var rankText:String = Highscore.getLetterRank(acc, misses);
		return switch (rankText)
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
	
	function doShuffle()
	{
		if (!songLock) return;
		if (alpha <= 0.3) return;
		FlxG.random.shuffle(shuffleLetters);
		name.text = shuffleLetters.join('');
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		curScript?.executeFunc('onUpdate', [elapsed], this);
		curScript?.executeFunc('onUpdatePost', [elapsed], this);
		// refreshPriceTxt(); // maybe dont make this on update // make it manually called after the effect, someone else can do that if they think its better
	}
	
	public inline function refreshPriceTxt()
	{
		if (priceText.visible && FlxG.state is funkin.states.FreeplayState)
		{
			@:privateAccess
			final beans = (cast FlxG.state : funkin.states.FreeplayState).localBeans;
			priceText.color = beans < price ? 0xFFFF6767 : FlxColor.WHITE;
		}

		curScript?.executeFunc('onRefreshPriceText', [], this);
	}
	
	public override function destroy():Void
	{
		curScript?.executeFunc('onDestroy', [], this);
		curScript?.destroy();
		
		super.destroy();
	}
}
