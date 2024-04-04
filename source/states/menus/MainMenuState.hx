package states.menus;

import flixel.FlxObject;

import flixel.addons.transition.FlxTransitionableState;

import flixel.effects.FlxFlicker;

import flixel.ui.FlxButton;

import objects.menu.MenuItem;

class MainMenuState extends MusicBeatState
{
	public static var funkinVer:String = '0.2.8';

	var magenta:FlxSprite;

	var itemNames:Array<String> = ['story-mode', 'freeplay', 'donate', 'options'];
	var menuItems:FlxTypedGroup<MenuItem>;

	static var curSelected:Int = 0;
	var selected:Bool = false;

	var camFollow:FlxObject;

	override function create()
	{
		changeWindowName('Main Menu');

		#if discord_rpc
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(Paths.image('menuUI/menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(Paths.image('menuUI/menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		if (ChillSettings.get('flashingLights', 'display'))
			add(magenta);

		menuItems = new FlxTypedGroup<MenuItem>();
		add(menuItems);

		for (i in 0...itemNames.length)
		{
			var menuItem:MenuItem = new MenuItem(60 + (i * 160), itemNames[i]);
			menuItem.ID = i;
			menuItems.add(menuItem);
		}

		changeItem();

		FlxG.cameras.reset(new SwagCamera());
		FlxG.camera.follow(camFollow, null, 0.06);

		var verTNDEngine:FlxText = new FlxText(-5, FlxG.height - 18, FlxG.width, "Chillin' Engine Engine v" + Application.current.meta.get('version'), 12);
		verTNDEngine.scrollFactor.set();
		verTNDEngine.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(verTNDEngine);

		var verFunkin:FlxText = new FlxText(5, FlxG.height - 18, 0, "Friday Night Funkin' v" + funkinVer, 12);
		verFunkin.scrollFactor.set();
		verFunkin.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(verFunkin);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (controls.UI_UP_P && !selected)
			changeItem(-1);

		if (controls.UI_DOWN_P && !selected)
			changeItem(1);

		if (controls.ACCEPT && !selected)
		{
			selected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			menuItems.forEach(function(item:MenuItem)
			{
				if (item.ID != curSelected)
					FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				else
					item.press();
			});

			if (ChillSettings.get('flashingLights', 'display'))
				FlxFlicker.flicker(magenta, 1, 0.1, false, false);
		}

		if (controls.BACK && !selected)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new TitleState());
		}

		super.update(elapsed);

		menuItems.forEach(function(item:MenuItem)
		{
			item.screenCenter(X);
		});
	}

	function changeItem(change:Int = 0)
	{
		curSelected += change;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(item:MenuItem)
		{
			if (item.ID == curSelected)
			{
				item.animation.play('selected', true);
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y);
			}
			else
				item.animation.play('idle', true);

			item.updateHitbox();
		});
	}
}