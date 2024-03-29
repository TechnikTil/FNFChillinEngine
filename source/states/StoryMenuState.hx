package states;

import flixel.addons.transition.FlxTransitionableState;

import objects.MenuCharacter;
import objects.MenuItem;

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;
	var daWeeks:Array<Week> = [];
	var curWeekClass:Week;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	override function create()
	{
		changeWindowName('Story Menu');

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: ", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: ';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		trace("Line 70");

		#if discord_rpc
		DiscordClient.changePresence("In the Menus", null);
		#end

		daWeeks = Week.weeks;
		curWeekClass = daWeeks[curWeek];

		for (i in 0...daWeeks.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, daWeeks[i].name);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);

			if (daWeeks[i].locked)
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x).loadGraphic(Paths.image('storyMenu/ui/lock'));
				lock.ID = i;
				grpLocks.add(lock);
			}
		}

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, curWeekClass.characters[char]);
			weekCharacterThing.y += 70;
			switch (weekCharacterThing.character)
			{
				case 'dad':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();

				case 'bf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
					weekCharacterThing.x -= 80;
				case 'gf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();
				case 'pico':
					weekCharacterThing.flipX = true;
				case 'parents-christmas':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
			}

			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		trace("Line 124");

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = Paths.getSparrowAtlas('storyMenu/ui/arrowLeft');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y).loadGraphic(Paths.image('storyMenu/difficulties/' + curWeekClass.difficulties[curDifficulty].formatToPath()));
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 380, leftArrow.y);
		rightArrow.frames = Paths.getSparrowAtlas('storyMenu/ui/arrowRight');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		trace("Line 165");

		super.create();
	}

	override function update(elapsed:Float)
	{
		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.5);

		scoreText.text = "WEEK SCORE:" + Math.round(lerpScore);

		txtWeekTitle.text = curWeekClass.motto.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		difficultySelectors.visible = !curWeekClass.locked;

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UI_UP_P)
				{
					changeWeek(-1);
					changeDifficulty();
				}

				if (controls.UI_DOWN_P)
				{
					changeWeek(1);
					changeDifficulty();
				}

				if (controls.UI_RIGHT)
				{
					rightArrow.animation.play('press');
					rightArrow.offset.y = -5;
				}
				else
				{
					rightArrow.animation.play('idle');
					rightArrow.offset.y = 0;
				}

				if (controls.UI_LEFT)
				{
					leftArrow.animation.play('press');
					leftArrow.offset.y = -5;
				}
				else
				{
					leftArrow.animation.play('idle');
					leftArrow.offset.y = 0;
				}

				if (controls.UI_RIGHT_P)
					changeDifficulty(1);
				if (controls.UI_LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!curWeekClass.locked) 
		{
			if (!stopspamming)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play(/*curWeekClass.characters[1] + */'confirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = curWeekClass.songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			PlayState.storyDifficulty = curWeekClass.difficulties[curDifficulty];

			var whatToLoad:String = PlayState.storyDifficulty.formatToPath();
			PlayState.SONG = Song.loadFromJson(whatToLoad, PlayState.storyPlaylist[0].formatToPath());
			PlayState.storyWeek = curWeekClass;
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = curWeekClass.difficulties.length - 1;
		if (curDifficulty >= curWeekClass.difficulties.length)
			curDifficulty = 0;

		sprDifficulty.offset.x = 0;

		switch (curWeekClass.difficulties[curDifficulty].formatToPath())
		{
			case 'easy': sprDifficulty.offset.x = 20;
			case 'normal': sprDifficulty.offset.x = 70;
			case 'hard': sprDifficulty.offset.x = 20;
			// TO-DO: when returned, add your own offset
		}

		sprDifficulty.loadGraphic(Paths.image('storyMenu/difficulties/' + curWeekClass.difficulties[curDifficulty].formatToPath()));
		sprDifficulty.alpha = 0;
		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);

		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(curWeekClass.name, curWeekClass.difficulties[curDifficulty]);
	}

	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= daWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = daWeeks.length - 1;

		curWeekClass = daWeeks[curWeek];

		if (!curWeekClass.difficulties.contains(curWeekClass.difficulties[curDifficulty]))
			changeDifficulty();

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && !curWeekClass.locked)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		txtTracklist.text = "Tracks:\n";

		for(i in 0...3)
		{
			grpWeekCharacters.members[i].charChange(curWeekClass.characters[i]);

			if (grpWeekCharacters.members[0].animation.curAnim.name != null)
			{
				switch (grpWeekCharacters.members[0].animation.curAnim.name)
				{
					case 'parents-christmas':
						grpWeekCharacters.members[0].offset.set(200, 200);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 0.9);

					case 'senpai':
						grpWeekCharacters.members[0].offset.set(130, 0);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 1.4);
						grpWeekCharacters.members[0].antialiasing = false;

					case 'mom':
						grpWeekCharacters.members[0].offset.set(100, 200);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 0.99);

					case 'dad':
						grpWeekCharacters.members[0].offset.set(120, 200);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 0.5);

					case 'tankman':
						grpWeekCharacters.members[0].offset.set(60, -20);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 0.99);

					case 'bf':
						grpWeekCharacters.members[0].flipX = true;
						grpWeekCharacters.members[0].offset.set(100, 100);
						grpWeekCharacters.members[0].setGraphicSize(grpWeekCharacters.members[0].width * 0.99);
					case 'pico':
						grpWeekCharacters.members[0].flipX = true;

				}
				grpWeekCharacters.members[0].updateHitbox();
			}
		}

		var stringThing:Array<String> = curWeekClass.songs;

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		intendedScore = Highscore.getWeekScore(curWeekClass.name, curWeekClass.difficulties[curDifficulty]);
	}
}
