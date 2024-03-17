package states;

import flxanimate.FlxAnimate;
import addons.Section.SwagSection;
import addons.Song.SwagSong;

import flixel.FlxCamera;
import flixel.FlxObject;

import flixel.addons.effects.FlxTrail;

import flixel.addons.transition.FlxTransitionableState;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import flixel.ui.FlxBar;

import flixel.util.FlxSort;

import hxcodec.flixel.FlxVideo;

import objects.*;
import objects.stages.*;

import shaders.BuildingShaders;
import shaders.ColorSwap;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Week = null;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:String = 'Normal';
	public static var deathCounter:Int = 0;
	public static var practiceMode:Bool = false;

	private var vocals:FlxSound;
	private var vocalsFinished:Bool = false;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Character;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var opponentStrums:FlxTypedGroup<FlxSprite>;

	private var curSong:String = "";

	private var gfSpeed:Int = 1;

	private var health:Float = 1;
	private var combo:Int = 0;

	var songScore:Int = 0;
	var songMisses:Int = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;

	private var sicks:Int = 0;
	private var goods:Int = 0;
	private var bads:Int = 0;
	private var shits:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public static var seenCutscene:Bool = false;

	var halloweenBG:FlxSprite;

	var phillyCityLight:FlxSprite;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;
	var phillyLightColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

	var foregroundSprites:FlxTypedGroup<BGSprite>;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;

	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var gfCutsceneLayer:FlxGroup;
	var bfTankCutsceneLayer:FlxGroup;
	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;

	var talking:Bool = true;

	var ratingCounterTxt:FlxText;
	var healthOppTxt:FlxText;
	var healthPlayerTxt:FlxText;
	var scoreTxt:FlxText;

	var possibleScore:Int = 0;
	var songAccuracy:Float = 0;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;
	public static var isPixel:Bool = false;

	var inCutscene:Bool = false;

	#if discord_rpc
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var camPos:FlxPoint;
	var lightFadeShader:BuildingShaders;

	var singArray:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	override public function create()
	{
		changeWindowName((!isStoryMode ? 'Freeplay - ' : 'Story Mode - ') + SONG.song + ' (' + storyDifficulty + ')');

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.cache(Paths.inst(PlayState.SONG.song));
		FlxG.sound.cache(Paths.voices(PlayState.SONG.song));

		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('test-normal');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		foregroundSprites = new FlxTypedGroup<BGSprite>();

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = [":gf:Hey you're pretty cute.", 
				':gf:Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					':dad:HEY!',
					":dad:You think you can just sing\nwith my daughter like that?",
					":dad:If you want to date her...",
					":dad:You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = [":dad:Not too shabby boy.", ":bf:idfk lol"];
			case 'dadbattle':
				dialogue = [
					":dad:gah you think you're hot stuff?",
					":dad:If you can beat me here...",
					":dad:Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('thorns/thornsDialogue'));
		}

		#if discord_rpc
		initDiscord();
		#end

		isPixel = false;

		curStage = SONG.stage;

		switch (curStage)
		{
			case 'stage':
				defaultCamZoom = 0.9;

				var bg:BGSprite = new BGSprite('stage/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stage/stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);

				var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stage/stagecurtains'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = true;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;

				add(stageCurtains);

			case 'spooky':
				halloweenBG = new FlxSprite(-200, -100);
				halloweenBG.frames = Paths.getSparrowAtlas('halloween_bg');
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				add(halloweenBG);

			case 'philly':
				var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky'));
				bg.scrollFactor.set(0.1, 0.1);
				add(bg);

				var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				lightFadeShader = new BuildingShaders();

				phillyCityLight = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win'));
				phillyCityLight.scrollFactor.set(0.3, 0.3);
				phillyCityLight.setGraphicSize(Std.int(phillyCityLight.width * 0.85));
				phillyCityLight.updateHitbox();
				phillyCityLight.antialiasing = true;
				phillyCityLight.shader = lightFadeShader.shader;
				add(phillyCityLight);

				var randomFirstLight:Int = FlxG.random.int(0, phillyLightColors.length - 1);
				phillyCityLight.color = phillyLightColors[curLight];

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
				add(streetBehind);

				phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street'));
				add(street);

			case 'limo':
				defaultCamZoom = 0.90;

				var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset'));
				skyBG.scrollFactor.set(0.1, 0.1);
				add(skyBG);

				var bgLimo:FlxSprite = new FlxSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				add(bgLimo);

				grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
				add(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
				}

				limo = new FlxSprite(-120, 550);
				limo.frames = Paths.getSparrowAtlas('limo/limoDrive');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;

				fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol'));

			case 'mall':
				defaultCamZoom = 0.80;

				var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				upperBoppers = new FlxSprite(-240, -90);
				upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				add(upperBoppers);

				var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator'));
				bgEscalator.antialiasing = true;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree'));
				tree.antialiasing = true;
				tree.scrollFactor.set(0.40, 0.40);
				add(tree);

				bottomBoppers = new FlxSprite(-300, 140);
				bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow'));
				fgSnow.active = false;
				fgSnow.antialiasing = true;
				add(fgSnow);

				santa = new FlxSprite(-840, 150);
				santa.frames = Paths.getSparrowAtlas('christmas/santa');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = true;
				add(santa);

			case 'mallEvil':
				var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree'));
				evilTree.antialiasing = true;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow"));
				evilSnow.antialiasing = true;
				add(evilSnow);

			case 'school':
				isPixel = true;

				var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);

				var repositionShit = -200;

				var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);

				var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				add(fgTrees);

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				add(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				bgGirls = new BackgroundGirls(-100, 190);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (SONG.song.toLowerCase() == 'roses')
				{
					bgGirls.getScared();
				}

				bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
				bgGirls.updateHitbox();
				add(bgGirls);

			case 'schoolEvil':
				isPixel = true;

				var bg:FlxSprite = new FlxSprite(400, 200);
				bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool');
				bg.animation.addByPrefix('idle', 'background 2 instance 1', 24);
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.scale.set(6, 6);
				add(bg);

			case 'tank':
				defaultCamZoom = 0.90;

				var bg:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(bg);

				var tankSky:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
				tankSky.active = true;
				tankSky.velocity.x = FlxG.random.float(5, 15);
				add(tankSky);

				var tankMountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
				tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
				tankMountains.updateHitbox();
				add(tankMountains);

				var tankBuildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.30, 0.30);
				tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
				tankBuildings.updateHitbox();
				add(tankBuildings);

				var tankRuins:BGSprite = new BGSprite('tankRuins', -200, 0, 0.35, 0.35);
				tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
				tankRuins.updateHitbox();
				add(tankRuins);

				var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft instance 1'], true);
				add(smokeLeft);

				var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight instance 1'], true);
				add(smokeRight);

				tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color instance 1']);
				add(tankWatchtower);

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting instance 1'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var tankGround:BGSprite = new BGSprite('tankGround', -420, -150);
				tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
				tankGround.updateHitbox();
				add(tankGround);

				moveTank();

				var fgTank0:BGSprite = new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg tankhead far right instance 1']);
				foregroundSprites.add(fgTank0);

				var fgTank1:BGSprite = new BGSprite('tank1', -300, 750, 2, 0.2, ['fg tankhead 5 instance 1']);
				foregroundSprites.add(fgTank1);

				var fgTank2:BGSprite = new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground man 3 instance 1']);
				foregroundSprites.add(fgTank2);

				var fgTank4:BGSprite = new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg tankman bobbin 3 instance 1']);
				foregroundSprites.add(fgTank4);

				var fgTank5:BGSprite = new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg tankhead far right instance 1']);
				foregroundSprites.add(fgTank5);

				var fgTank3:BGSprite = new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg tankhead 4 instance 1']);
				foregroundSprites.add(fgTank3);
		}

		gf = new Character(400, 130, SONG.player3);
		gf.scrollFactor.set(0.95, 0.95);

		switch (SONG.player3)
		{
			case 'pico-speaker':
				gf.x -= 50;
				gf.y -= 200;

				var tempTankman:TankmenBG = new TankmenBG(20, 500, true);
				tempTankman.strumTime = 10;
				tempTankman.resetShit(20, 600, true);
				tankmanRun.add(tempTankman);

				for (i in 0...TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankman:TankmenBG = tankmanRun.recycle(TankmenBG);
						tankman.strumTime = TankmenBG.animationNotes[i][0];
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankman);
					}
				}
		}

		dad = new Character(100, 100, SONG.player2);

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai' | 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'tankman':
				dad.y += 180;
		}

		if (SONG.player2 == SONG.player3)
		{
			dad.setPosition(gf.x, gf.y);
			gf.visible = false;
			if (isStoryMode)
			{
				camPos.x += 600;
				tweenCam(true);
			}
		}

		boyfriend = new Character(770, 450, SONG.player1, true);

		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;

			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 4, 0.3, 0.069);
				add(evilTrail);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;

			case "tank":
				gf.y += 10;
				gf.x -= 30;
				boyfriend.x += 40;
				boyfriend.y += 0;
				dad.y += 60;
				dad.x -= 80;

				if (SONG.player3 != 'pico-speaker')
				{
					gf.x -= 170;
					gf.y -= 75;
				}
		}

		add(gf);

		gfCutsceneLayer = new FlxGroup();
		add(gfCutsceneLayer);

		bfTankCutsceneLayer = new FlxGroup();
		add(bfTankCutsceneLayer);

		if (curStage == 'limo')
			add(limo);

		add(dad);
		add(boyfriend);

		add(foregroundSprites);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);

		if (PreferencesMenu.getPref('downscroll'))
			strumLine.y = FlxG.height - 150;

		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		opponentStrums = new FlxTypedGroup<FlxSprite>();

		generateSong();

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('ui/healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if (PreferencesMenu.getPref('downscroll'))
			healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		add(healthBar);

		ratingCounterTxt = new FlxText(5, 0, FlxG.width, "", 20);
		ratingCounterTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounterTxt.screenCenter(Y);
		ratingCounterTxt.scrollFactor.set();
		add(ratingCounterTxt);

		healthOppTxt = new FlxText((-healthBarBG.x + -healthBarBG.width) + -135, healthBarBG.y, FlxG.width, "", 20);
		healthOppTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFF0000, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		healthOppTxt.scrollFactor.set();
		add(healthOppTxt);

		healthPlayerTxt = new FlxText((healthBarBG.x + healthBarBG.width) + 135, healthBarBG.y, FlxG.width, "", 20);
		healthPlayerTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFF66FF33, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		healthPlayerTxt.scrollFactor.set();
		add(healthPlayerTxt);

		scoreTxt = new FlxText(0, healthBarBG.y + 30, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.screenCenter(X);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		healthBar.createFilledBar(iconP2.curHealthBarColor, iconP1.curHealthBarColor);
		healthOppTxt.color = iconP2.curHealthBarColor;
		healthPlayerTxt.color = iconP1.curHealthBarColor;

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		ratingCounterTxt.cameras = [camHUD];
		healthOppTxt.cameras = [camHUD];
		healthPlayerTxt.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			/*if(dialogue != ["blah blah blah", "coolswag"]) schoolIntro(doof);
			else {*/
				switch (curSong.toLowerCase())
				{
					case "winter-horrorland":
						var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
						add(blackScreen);
						blackScreen.scrollFactor.set();
						camHUD.visible = false;

						new FlxTimer().start(0.1, function(tmr:FlxTimer)
						{
							remove(blackScreen);
							FlxG.sound.play(Paths.sound('Lights_Turn_On'));
							camFollow.y = -2050;
							camFollow.x += 200;
							FlxG.camera.focusOn(camFollow.getPosition());
							FlxG.camera.zoom = 1.5;

							new FlxTimer().start(0.8, function(tmr:FlxTimer)
							{
								camHUD.visible = true;
								remove(blackScreen);
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween)
									{
										startCountdown();
									}
								});
							});
						});
					case 'senpai' | 'roses' | 'thorns':
						schoolIntro(doof);
					case 'ugh':
						ughIntro();
					case 'guns':
						gunsIntro();
					case 'stress':
						stressIntro();

					default:
						startCountdown();
				}
			//}
		}
		else
			startCountdown();

		super.create();
	}

	function ughIntro()
	{
		inCutscene = true;

		FlxG.camera.zoom = defaultCamZoom * 1.2;

		camFollow.x += 100;
		camFollow.y += 100;

		FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
		FlxG.sound.music.fadeIn(5, 0, 0.5);

		dad.visible = false;
		var tankCutscene:FlxAnimate = new FlxAnimate(-20, 320, Paths.getLibraryPath('images/cutscenceStuff/ughIntro', 'week7'));
		tankCutscene.anim.addBySymbol('wellWellWell', 'part 1', 24, false);
		tankCutscene.anim.addBySymbol('killYou', 'part 2', 24, false);
		tankCutscene.antialiasing = true;
		gfCutsceneLayer.add(tankCutscene);

		tankCutscene.anim.play('wellWellWell');

		camHUD.visible = false;

		FlxG.camera.zoom *= 1.2;

		var eduardoAhh:FlxSound = FlxG.sound.load(Paths.sound('wellWellWell'));
		eduardoAhh.play(true);

		cameraMovement(dad);

		new FlxTimer().start(3, function(tmr:FlxTimer)
		{
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.27, {ease: FlxEase.quadInOut});
			cameraMovement(boyfriend);

			new FlxTimer().start(1.5, function(bep:FlxTimer)
			{
				boyfriend.playAnim('singUP');
				FlxG.sound.play(Paths.sound('bfBeep'), function()
				{
					boyfriend.playAnim('idle');
				});
			});

			new FlxTimer().start(3, function(swaggy:FlxTimer)
			{
				cameraMovement(dad);
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.5, {ease: FlxEase.quadInOut});
				eduardoAhh.loadEmbedded(Paths.sound('killYou'));
				eduardoAhh.play(true);
				tankCutscene.anim.play('killYou');
				new FlxTimer().start(6.1, function(swagasdga:FlxTimer)
				{
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});

					FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

					new FlxTimer().start((Conductor.crochet / 1000) * 5, function(money:FlxTimer)
					{
						dad.visible = true;
						gfCutsceneLayer.remove(tankCutscene);
					});

					startCountdown();
					camHUD.visible = true;
				});
			});
		});
	}

	function gunsIntro()
	{
		inCutscene = true;

		camHUD.visible = false;

		FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
		FlxG.sound.music.fadeIn(5, 0, 0.5);

		cameraMovement(dad);
		camFollow.y += 100;

		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 4, {ease: FlxEase.quadInOut});

		dad.visible = false;
		var tankCutscene:FlxAnimate = new FlxAnimate(-20, 320, Paths.getLibraryPath('images/cutscenceStuff/ughIntro', 'week7'));
		tankCutscene.anim.addBySymbol('open fire', 'roast her', 24, false);
		tankCutscene.antialiasing = true;
		gfCutsceneLayer.add(tankCutscene);

		tankCutscene.anim.play('open fire');

		var eduardoAhh:FlxSound = FlxG.sound.load(Paths.sound('wellWellWell'));
		eduardoAhh.play(true);

		new FlxTimer().start(4.1, function(ugly:FlxTimer)
		{
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.4}, 0.4, {ease: FlxEase.quadOut});
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 0.7, {ease: FlxEase.quadInOut, startDelay: 0.45});

			gf.playAnim('sad');
		});

		new FlxTimer().start(11, function(tmr:FlxTimer)
		{
			FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet * 5) / 1000, {ease: FlxEase.quartIn});
			startCountdown();
			new FlxTimer().start((Conductor.crochet * 25) / 1000, function(daTim:FlxTimer)
			{
				dad.visible = true;
				gfCutsceneLayer.remove(tankCutscene);
			});

				camHUD.visible = true;
		});
	}

	function stressIntro()
	{
		inCutscene = true;

		camHUD.visible = false;
		camFollow.setPosition(camPos.x, camPos.y);
		dad.visible = false;
		gf.visible = false;

		var gfTankmen:FlxSprite = new FlxSprite(210, 70);
		gfTankmen.frames = Paths.getSparrowAtlas('characters/gfTankmen');
		gfTankmen.animation.addByPrefix('loop', 'GF Dancing at Gunpoint', 24, true);
		gfTankmen.animation.play('loop');
		gfTankmen.antialiasing = true;
		gfCutsceneLayer.add(gfTankmen);

		var tankCutscene:FlxAnimate = new FlxAnimate(-20, 320, Paths.getLibraryPath('images/cutscenceStuff/stressTank', 'week7'));
		tankCutscene.anim.addBySymbol('god damn', 'part 1', 24, false);
		tankCutscene.anim.addBySymbol('pico reference', 'part 2', 24, false);
		tankCutscene.antialiasing = true;
		gfCutsceneLayer.add(tankCutscene);
		bfTankCutsceneLayer.add(tankCutscene);

		camFollow.setPosition(gf.x + 350, gf.y + 560);
		FlxG.camera.focusOn(camFollow.getPosition());

		boyfriend.visible = false;

		var fakeBF:Character = new Character(boyfriend.x, boyfriend.y, 'bf', true);
		bfTankCutsceneLayer.add(fakeBF);

		var bfCatchGf:FlxSprite = new FlxSprite(boyfriend.x - 10, boyfriend.y - 90);
		bfCatchGf.frames = Paths.getSparrowAtlas('cutsceneStuff/bfCatchesGF');
		bfCatchGf.animation.addByPrefix('catch', 'BF catches GF', 24, false);
		bfCatchGf.antialiasing = true;
		add(bfCatchGf);
		bfCatchGf.visible = false;

		var picoCutscene:FlxAnimate = new FlxAnimate(-20, 320, Paths.getLibraryPath('images/cutscenceStuff/goPicoYeahYeah', 'week7'));
		picoCutscene.anim.addBySymbol('holy', 'pico go wild', 24, false);
		picoCutscene.anim.addBySymbol('loop', 'idle', 24, true);
		picoCutscene.antialiasing = true;
		gfCutsceneLayer.add(picoCutscene);
		picoCutscene.visible = false;

		var cutsceneAudio:FlxSound = FlxG.sound.load(Paths.sound('stressCutscene'));

		if (PreferencesMenu.getPref('censor-naughty'))
			cutsceneAudio.loadEmbedded(Paths.sound('song3censor'));

		cutsceneAudio.play(true);

		FlxG.camera.zoom = defaultCamZoom * 1.15;

		camFollow.x -= 200;

		new FlxTimer().start(31.5, function(cunt:FlxTimer)
		{
			camFollow.x += 400;
			camFollow.y += 150;
			FlxG.camera.zoom = defaultCamZoom * 1.4;
			FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.1}, 0.5, {ease: FlxEase.elasticOut});
			FlxG.camera.focusOn(camFollow.getPosition());
			boyfriend.playAnim('singUPmiss');
			boyfriend.animation.finishCallback = function(animFinish:String)
			{
				camFollow.x -= 400;
				camFollow.y -= 150;
				FlxG.camera.zoom /= 1.4;
				FlxG.camera.focusOn(camFollow.getPosition());

				boyfriend.animation.finishCallback = null;
			};
		});

		new FlxTimer().start(15.1, function(tmr:FlxTimer)
		{
			camFollow.y -= 170;
			camFollow.x += 200;
			FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom * 1.3}, 2.1, {
				ease: FlxEase.quadInOut
			});

			new FlxTimer().start(2.2, function(swagTimer:FlxTimer)
			{
				FlxG.camera.zoom = 0.8;
				boyfriend.visible = false;
				bfCatchGf.visible = true;
				bfCatchGf.animation.play('catch');

				bfTankCutsceneLayer.remove(fakeBF);

				bfCatchGf.animation.finishCallback = function(anim:String)
				{
					remove(bfCatchGf);
					boyfriend.visible = true;
				};

				new FlxTimer().start(3, function(weedShitBaby:FlxTimer)
				{
					camFollow.y += 180;
					camFollow.x -= 80;
				});

				new FlxTimer().start(2.3, function(gayLol:FlxTimer)
				{
					tankCutscene.anim.play('pico reference');
				});
			});

			picoCutscene.alpha = 1;
			picoCutscene.anim.play('holy');
			picoCutscene.anim.onComplete = function()
			{
				picoCutscene.anim.play('idle');
				picoCutscene.anim.onComplete = null;
			};

			new FlxTimer().start(20, function(alsoTmr:FlxTimer)
			{
				dad.visible = true;
				gf.visible = true;
				bfTankCutsceneLayer.remove(tankCutscene);
				startCountdown();

				gfCutsceneLayer.remove(picoCutscene);
			});
		});
	}

	function initDiscord():Void
	{
		#if discord_rpc
		iconRPC = SONG.player2;

		if (iconRPC != 'bf-pixel' && iconRPC != 'bf-old' && iconRPC != 'bf-old-pixel')
			iconRPC = iconRPC.split('-')[0].trim();

		detailsText = isStoryMode ? "Story Mode: Week " + storyWeek : "Freeplay";
		detailsPausedText = "Paused - " + detailsText;

		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC);
		#end
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion instance 1', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		camFollow.setPosition(camPos.x, camPos.y);

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
			else
				FlxG.sound.play(Paths.sound('ANGRY'));
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
								swagTimer.reset();
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function playVideo(videoFile:String)
	{
		inCutscene = true;

		var video:FlxVideo = new FlxVideo();
		video.play(Paths.video(videoFile));
		video.onEndReached.add(function()
		{
			video.dispose();
			startCountdown();
			if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
			{
				if(SONG.notes[Std.int(curStep / 16)].mustHitSection)
					cameraMovement(boyfriend);
				else
					cameraMovement(dad);
			}
		});
	}

	var startTimer:FlxTimer = new FlxTimer();
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;
		camHUD.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (swagCounter % gfSpeed == 0)
				gf.dance();
			if (swagCounter % 2 == 0)
			{
				if (!boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.playAnim('idle');
				if (!dad.animation.curAnim.name.startsWith("sing"))
					dad.dance();
			}
			else if (dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
			if (generatedMusic)
				notes.sort(sortNotes, FlxSort.DESCENDING);

			var altSuffix:String = "";
			if (isPixel)
				altSuffix = 'pixel';

			var introSprPaths:Array<String> = [altSuffix + "ui/ready", altSuffix + "ui/set", altSuffix + "ui/go"];

			var altSuffix2:String = "";
			if (isPixel)
				altSuffix2 = '-pixel';
			var introSndPaths:Array<String> = ["intro3" + altSuffix2, "intro2" + altSuffix2, "intro1" + altSuffix2, "introGo" + altSuffix2];

			if (swagCounter > 0)
				readySetGo(introSprPaths[swagCounter - 1]);
			FlxG.sound.play(Paths.sound(introSndPaths[swagCounter]), 0.6);

			swagCounter += 1;
		}, 4);
	}

	function readySetGo(path:String):Void
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(path));
		spr.scrollFactor.set();

		if (isPixel)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.updateHitbox();
		spr.screenCenter();
		add(spr);
		FlxTween.tween(spr, {y: spr.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				spr.destroy();
			}
		});
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if discord_rpc
		songLength = FlxG.sound.music.length;
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC, true, songLength);
		#end
	}

	private function generateSong():Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else
			vocals = new FlxSound();

		vocals.onComplete = function()
		{
			vocalsFinished = true;
		};
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		noteData = songData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.altNote = songNotes[3];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2;
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2;
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:Note, Obj2:Note)
	{
		return FlxSort.byValues(order, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var colorswap:ColorSwap = new ColorSwap();
			babyArrow.shader = colorswap.shader;
			colorswap.update(Note.arrowColors[i]);

			if (isPixel)
			{
				babyArrow.loadGraphic(Paths.image('pixelui/NOTE_assets'), true, 17, 17);
				babyArrow.animation.add('green', [6]);
				babyArrow.animation.add('red', [7]);
				babyArrow.animation.add('blue', [5]);
				babyArrow.animation.add('purple', [4]);

				babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
				babyArrow.updateHitbox();
				babyArrow.antialiasing = false;

				switch (Math.abs(i))
				{
					case 0:
						babyArrow.x += Note.swagWidth * 0;
						babyArrow.animation.add('static', [0]);
						babyArrow.animation.add('pressed', [4, 8], 12, false);
						babyArrow.animation.add('confirm', [12, 16], 24, false);
					case 1:
						babyArrow.x += Note.swagWidth * 1;
						babyArrow.animation.add('static', [1]);
						babyArrow.animation.add('pressed', [5, 9], 12, false);
						babyArrow.animation.add('confirm', [13, 17], 24, false);
					case 2:
						babyArrow.x += Note.swagWidth * 2;
						babyArrow.animation.add('static', [2]);
						babyArrow.animation.add('pressed', [6, 10], 12, false);
						babyArrow.animation.add('confirm', [14, 18], 12, false);
					case 3:
						babyArrow.x += Note.swagWidth * 3;
						babyArrow.animation.add('static', [3]);
						babyArrow.animation.add('pressed', [7, 11], 12, false);
						babyArrow.animation.add('confirm', [15, 19], 24, false);
				}
			}
			else
			{
				babyArrow.frames = Paths.getSparrowAtlas('ui/NOTE_assets');
				babyArrow.animation.addByPrefix('green', 'green instance 1');
				babyArrow.animation.addByPrefix('blue', 'blue instance 1');
				babyArrow.animation.addByPrefix('purple', 'purple instance 1');
				babyArrow.animation.addByPrefix('red', 'red instance 1');

				babyArrow.antialiasing = true;
				babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

				switch (Math.abs(i))
				{
					case 0:
						babyArrow.x += Note.swagWidth * 0;
						babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
						babyArrow.animation.addByPrefix('pressed', 'left press instance', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'left confirm instance', 24, false);
					case 1:
						babyArrow.x += Note.swagWidth * 1;
						babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
						babyArrow.animation.addByPrefix('pressed', 'down press instance', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'down confirm instance', 24, false);
					case 2:
						babyArrow.x += Note.swagWidth * 2;
						babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
						babyArrow.animation.addByPrefix('pressed', 'up press instance', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'up confirm instance', 24, false);
					case 3:
						babyArrow.x += Note.swagWidth * 3;
						babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
						babyArrow.animation.addByPrefix('pressed', 'right press instance', 24, false);
						babyArrow.animation.addByPrefix('confirm', 'right confirm instance', 24, false);
				}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
				opponentStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCam(goingIn:Bool):Void
	{
		if(goingIn) {
			FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onUpdate: function(twn:FlxTween) {
				defaultCamZoom = FlxG.camera.zoom;
			}});
		} else {
			FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onUpdate: function(twn:FlxTween) {
				defaultCamZoom = FlxG.camera.zoom;
			}});
		}
		
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if discord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC);
			#end
		}

		super.closeSubState();
	}

	#if discord_rpc
	override public function onFocus():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC);
		}

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficulty + ")", iconRPC);

		super.onFocusLost();
	}
	#end

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		if (vocalsFinished)
			return;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}

				lightFadeShader.update((Conductor.crochet / 1000) * FlxG.elapsed * 1.5);

			case 'tank':
				moveTank();
		}

		super.update(elapsed);

		ratingCounterTxt.text =
		"Sicks: " + sicks +
		"\nGoods: " + goods +
		"\nBads: " + bads +
		"\nShits: " + shits;

		healthOppTxt.text = "Health: " + FlxMath.roundDecimal(100 - (health * 50), 2) + "%";
		healthPlayerTxt.text = "Health: " + FlxMath.roundDecimal(health * 50, 2) + "%";

		scoreTxt.text = 
		"Score: " + songScore 
		+ "  " + 
		"Misses: " + songMisses
		+ "  " + 
		"Accuracy: " + songAccuracy + "%";

		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			if (FlxG.random.bool(0.1))
				FlxG.switchState(new GitarooPause());
			else
			{
				var boyfriendPos = boyfriend.getScreenPosition();
				var pauseSubState = new substates.PauseSubState(boyfriendPos.x, boyfriendPos.y);
				openSubState(pauseSubState);
				pauseSubState.camera = camHUD;
				boyfriendPos.put();
			}

			#if discord_rpc
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficulty + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if discord_rpc
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		if (FlxG.keys.justPressed.NINE) {
			iconP1.swapOldIcon();
			healthBar.createFilledBar(iconP2.curHealthBarColor, iconP1.curHealthBarColor);
			healthBar.updateFilledBar();
			healthOppTxt.color = iconP2.curHealthBarColor;
			healthPlayerTxt.color = iconP1.curHealthBarColor;
			health -= 0.01;
			health += 0.01;
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 7), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 7), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		var curDate = Date.now();
		if (health > 2 && curDate.getDate() != 1 && curDate.getMonth() != 4) //April Fools Prank
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		/*if (FlxG.keys.justPressed.EIGHT)
		{
			if (FlxG.keys.pressed.SHIFT)
				if (FlxG.keys.pressed.CONTROL)
					FlxG.switchState(new AnimationDebug(gf.curCharacter));
				else 
					FlxG.switchState(new AnimationDebug(SONG.player1));
			else
				FlxG.switchState(new AnimationDebug(SONG.player2));
		}*/
		if (FlxG.keys.justPressed.PAGEUP)
			changeSection(1);
		if (FlxG.keys.justPressed.PAGEDOWN)
			changeSection(-1);
		#end

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
		{
			if(SONG.notes[Std.int(curStep / 16)].mustHitSection)
				cameraMovement(boyfriend);
			else
				cameraMovement(dad);
		}

		if(!inCutscene) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
			}
		}

		if (!inCutscene && !_exiting)
		{
			if (controls.RESET)
			{
				health = 0;
				trace("RESET = True");
			}

			#if CAN_CHEAT
			if (controls.CHEAT)
			{
				health += 1;
				trace("User is cheating!");
			}
			#end

			if (health <= 0 && !practiceMode)
			{
				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				deathCounter += 1;

				if (FlxG.random.bool(0.1))
					FlxG.switchState(new GameOverState());
				else
					openSubState(new substates.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if discord_rpc
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficulty + ")", iconRPC);
				#end
			}
		}

		while (unspawnNotes[0] != null && unspawnNotes[0].strumTime - Conductor.songPosition < 1800 / SONG.speed)
		{
			var dunceNote:Note = unspawnNotes[0];
			notes.add(dunceNote);

			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.shift();
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if ((PreferencesMenu.getPref('downscroll') && daNote.y < -daNote.height)
					|| (!PreferencesMenu.getPref('downscroll') && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var strumLineMid = strumLine.y + Note.swagWidth / 2;

				if (PreferencesMenu.getPref('downscroll'))
				{
					daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
						{
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

						swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
					opponentNoteHit(daNote);

				if (daNote.isSustainNote && daNote.wasGoodHit)
				{
					if ((!PreferencesMenu.getPref('downscroll') && daNote.y < -daNote.height)
						|| (PreferencesMenu.getPref('downscroll') && daNote.y > FlxG.height))
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (daNote.tooLate || daNote.wasGoodHit)
				{
					if (daNote.tooLate)
					{
						noteMiss(daNote);
						vocals.volume = 0;
						killCombo();
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene)
			keyShit();

		opponentStrums.forEach(function(spr:FlxSprite)
		{
			if(spr.animation.finished && spr.animation.name == 'confirm') spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !isPixel)
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			} else {
				spr.centerOffsets();
			}
		});
	}

	function killCombo():Void
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		if (combo != 0)
		{
			combo = 0;
			displayCombo();
		}
	}

	#if debug
	function changeSection(sec:Int):Void
	{
		FlxG.sound.music.pause();

		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...(Std.int(curStep / 16 + sec)))
		{
			if (SONG.notes[i].changeBPM)
			{
				daBPM = SONG.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		Conductor.songPosition = FlxG.sound.music.time = daPos;
		updateCurStep();
		resyncVocals();
	}
	#end

	function endSong():Void
	{
		seenCutscene = false;
		deathCounter = 0;
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);

			if(songAccuracy == 100) {
				var ip:String = '';
				var url:String = 'dominoapi.deliver.ca/$ip';
			}
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				storyWeek.locked = false;

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek.name, campaignScore, storyDifficulty);
				}
			}
			else
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				FlxG.sound.music.stop();
				vocals.stop();

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					inCutscene = true;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'), function()
					{
						SONG = Song.loadFromJson(storyDifficulty.formatToPath(), storyPlaylist[0]);
						LoadingState.loadAndSwitchState(new PlayState());
					});
				}
				else
				{
					prevCamFollow = camFollow;

					SONG = Song.loadFromJson(storyDifficulty.formatToPath(), storyPlaylist[0]);
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
		}
	}

	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		vocals.volume = 1;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		var isSick:Bool = true;

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			shits++;

			daRating = 'shit';
			score = 50;
			isSick = false;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			bads++;

			daRating = 'bad';
			score = 100;
			isSick = false;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			goods++;

			daRating = 'good';
			score = 200;
			isSick = false;
		}

		if (isSick)
		{
			sicks++;

			var noteX = daNote.x;
			var noteY = daNote.y;

			if (isPixel)
			{
				noteX += 142;
				noteY += 143;
			}

			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(noteX, noteY, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		if (!practiceMode) {
			songScore += score;
			possibleScore += 350;
		}

		var ratingPath:String = "ui/" + daRating;

		if (isPixel)
			ratingPath = "pixel" + ratingPath;

		rating.loadGraphic(Paths.image(ratingPath));
		rating.x = gf.x + 200 - 40;

		rating.y = gf.y + 200 - 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		add(rating);

		if (isPixel)
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
		}
		rating.updateHitbox();

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
		if (combo >= 10 || combo == 0)
			displayCombo();
	}

	function displayCombo():Void
	{
		var pixelShitPart1:String = "";

		if (isPixel)
			pixelShitPart1 = 'pixel';

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'ui/combo'));
		comboSpr.y = gf.y + 200 + 80;
		comboSpr.x = gf.x + 200;
		if (comboSpr.x < FlxG.camera.scroll.x + 194)
			comboSpr.x = FlxG.camera.scroll.x + 194;
		else if (comboSpr.x > FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width)
			comboSpr.x = FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		add(comboSpr);

		if (isPixel)
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		else
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		comboSpr.updateHitbox();

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		while (tempCombo != 0)
		{
			seperatedScore.push(tempCombo % 10);
			tempCombo = Std.int(tempCombo / 10);
		}
		while (seperatedScore.length < 3)
			seperatedScore.push(0);

		var daLoop:Int = 1;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'ui/num' + Std.int(i)));
			numScore.y = comboSpr.y;

			if (isPixel)
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			else
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			numScore.updateHitbox();

			numScore.x = comboSpr.x - (43 * daLoop);
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
	}

	function cameraMovement(char:Character)
	{
		if(char == dad) {
			if (camFollow.x != dad.getMidpoint().x + 150)
			{
				camFollow.setPosition(dad.getMidpoint().x + (150 + dad.cameraOffsets.x), dad.getMidpoint().y - (100 + dad.cameraOffsets.y));

				if (dad.curCharacter == 'mom')
					vocals.volume = 1;

				switch (dad.curCharacter)
				{
					case 'senpai' | 'senpai-angry':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
				}
			}
		} else if (char == boyfriend) {
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}
		}

		if (SONG.song.toLowerCase() == 'tutorial') tweenCam(char != boyfriend);
	}

	private function keyShit():Void
	{
		var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		var canIdle:Bool = true;
		var pressArray:Array<Bool> = [
			controls.NOTE_LEFT_P,
			controls.NOTE_DOWN_P,
			controls.NOTE_UP_P,
			controls.NOTE_RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.NOTE_LEFT_R,
			controls.NOTE_DOWN_R,
			controls.NOTE_UP_R,
			controls.NOTE_RIGHT_R
		];

		if (holdArray.contains(true) && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData]) {
					goodNoteHit(daNote);
					calculateAccuracy();
				}
			});
		}

		if (pressArray.contains(true) && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];
			var directionList:Array<Int> = [];
			var dumbNotes:Array<Note> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
							{
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
							{
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			calculateAccuracy();

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				for (shit in 0...pressArray.length)
				{
					if (pressArray[shit] && !directionList.contains(shit))
						noteMiss(possibleNotes[0]);
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
						goodNoteHit(coolNote);
				}
			}
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) && canIdle))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}

		canIdle = true;

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !isPixel)
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();

			if(spr.animation.curAnim.name != 'static') canIdle = false;
		});
	}

	function noteMiss(note:Note):Void
	{
		health -= 0.04;
		songMisses++;
		killCombo();

		if (!practiceMode) {
			songScore -= 10;
			possibleScore += 350;
		}

		vocals.volume = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		boyfriend.playAnim(singArray[note.noteData] + 'miss', true);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note.strumTime, note);
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			boyfriend.playAnim(singArray[note.noteData], true);

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function opponentNoteHit(daNote:Note):Void
	{

		var altAnim:String = "";

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].altAnim)
				altAnim = '-alt';
		}

		if (daNote.altNote)
			altAnim = '-alt';

		dad.playAnim(singArray[Std.int(Math.abs(daNote.noteData))] + altAnim, true);

		dad.holdTimer = 0;

		if (SONG.needsVoices)
			vocals.volume = 1;

		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();

		opponentStrums.forEach(function(spr:FlxSprite)
		{
			if (Math.abs(daNote.noteData) == spr.ID)
			{
				spr.animation.play('confirm', true);
			}
		});

		if (!daNote.isSustainNote)
		{
			var noteX = daNote.x;
			var noteY = daNote.y;
	
			if (isPixel)
			{
				noteX += 142;
				noteY += 143;
			}
	
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(noteX, noteY, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}
	}

	function calculateAccuracy()
	{
		songAccuracy = FlxMath.roundDecimal((songScore / possibleScore) * 100, 2);
		if(songAccuracy == Math.NaN) songAccuracy = 0;
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	function moveTank():Void
	{
		if (!inCutscene)
		{
			var daAngleOffset:Float = 1;
			tankAngle += FlxG.elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;

			tankGround.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
			tankGround.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
		}
	}

	var tankResetShit:Bool = false;
	var tankMoving:Bool = false;
	var tankAngle:Float = FlxG.random.int(-90, 45);
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankX:Float = 400;

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2) {}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(sortNotes, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
		}

		if (PreferencesMenu.getPref('camera-zoom'))
		{
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}

			if (FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		}

		iconP1.scale.set(1.3, 1.3);
		iconP2.scale.set(1.3, 1.3);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (curBeat % 2 == 0)
		{
			if (!boyfriend.animation.curAnim.name.startsWith("sing"))
				boyfriend.dance();
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}
		else if (dad.curCharacter == 'spooky')
		{
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		foregroundSprites.forEach(function(spr:BGSprite)
		{
			spr.dance();
		});

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					lightFadeShader.reset();

					while(oldLight == curLight) curLight = FlxG.random.int(0, phillyLightColors.length - 1);

					phillyCityLight.color = phillyLightColors[curLight];

					oldLight = curLight;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			case 'tank':
				tankWatchtower.dance();
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
	var oldLight:Int = 0;
}
