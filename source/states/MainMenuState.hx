package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;

#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end

import backend.UnlockManager;

class MainMenuState extends MusicBeatState {
    // Menu options - just Songs and Options
    var menuItems:Array<String> = ['songs', 'options'];
    var curSelected:Int = 0;
    
    // Visual elements
    var bgGray:FlxSprite;
    var bgGreen:FlxSprite;
    var diagonalOverlay:FlxSprite;
    
    var menuTexts:FlxTypedGroup<FlxSprite>;
    var particles:FlxTypedGroup<DotParticle>;
    
    var characterSprite:FlxSprite;
    var songsCharPath:String = 'mainmenu/character_songs';
    var optionsCharPath:String = 'mainmenu/character_options';
    
    // Constants
    static inline var PARTICLE_COUNT:Int = 30;
    static inline var GRAY_COLOR:FlxColor = 0xFF4A4A4A;
    static inline var GREEN_COLOR:FlxColor = 0xFF2ECC71;
    
    var selectedSomething:Bool = false;

    override function create() {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("VS Anthony REBOOTED", "In Main Menu");
        #end
        
        // Stop any existing music and play menu music
        if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
        }
        
        // Create backgrounds
        createBackgrounds();
        
        // Create floating particles
        createParticles();
        
        // Create menu text items
        createMenuItems();
        
        // Create character sprite
        createCharacter();
        
        // Initial selection highlight
        changeSelection(0);
        
        super.create();
    }
    
    function createBackgrounds() {
        // Full green background (right side, but we draw it full then overlay)
        bgGreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, GREEN_COLOR);
        add(bgGreen);
        
        // Diagonal gray overlay (left side)
        // We'll create this as a polygon shape using a sprite with draw calls
        diagonalOverlay = new FlxSprite();
        diagonalOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
        
        // Draw diagonal shape: triangle from (0,0) to (0, height) to (width * 0.6, 0)
        // Using pixel manipulation for the diagonal
        var gfx = diagonalOverlay.pixels;
        for (y in 0...FlxG.height) {
            // Calculate x cutoff for this row (diagonal line)
            // Line goes from (width * 0.55, 0) to (width * 0.35, height)
            var startX:Float = FlxG.width * 0.55;
            var endX:Float = FlxG.width * 0.35;
            var cutoffX:Int = Std.int(startX + (endX - startX) * (y / FlxG.height));
            
            for (x in 0...cutoffX) {
                gfx.setPixel32(x, y, GRAY_COLOR);
            }
        }
        add(diagonalOverlay);
    }
    
    function createParticles() {
        particles = new FlxTypedGroup<DotParticle>();
        
        for (i in 0...PARTICLE_COUNT) {
            var particle = new DotParticle();
            // Spawn on the green (right) side
            particle.x = FlxG.width * 0.4 + FlxG.random.float(0, FlxG.width * 0.6);
            particle.y = FlxG.random.float(0, FlxG.height);
            particles.add(particle);
        }
        
        add(particles);
    }
    
    function createMenuItems() {
        menuTexts = new FlxTypedGroup<FlxSprite>();
        
        // Songs button - positioned upper left area
        var songsSprite = new FlxSprite(50, 80);
        songsSprite.loadGraphic(Paths.image('mainmenu/songs_text'));
        songsSprite.ID = 0;
        menuTexts.add(songsSprite);
        
        // Options button - positioned lower left area  
        var optionsSprite = new FlxSprite(50, 320);
        optionsSprite.loadGraphic(Paths.image('mainmenu/options_text'));
        optionsSprite.ID = 1;
        menuTexts.add(optionsSprite);
        
        add(menuTexts);
    }
    
    function createCharacter() {
        characterSprite = new FlxSprite(FlxG.width * 0.55, 50);
        characterSprite.loadGraphic(Paths.image(songsCharPath));
        characterSprite.antialiasing = ClientPrefs.data.antialiasing;
        // Scale/position as needed
        characterSprite.setGraphicSize(Std.int(characterSprite.width * 0.8));
        characterSprite.updateHitbox();
        add(characterSprite);
    }
    
    function updateCharacter() {
        var targetPath = curSelected == 0 ? songsCharPath : optionsCharPath;
        characterSprite.loadGraphic(Paths.image(targetPath));
        characterSprite.setGraphicSize(Std.int(characterSprite.width * 0.8));
        characterSprite.updateHitbox();
    }

    override function update(elapsed:Float) {
        if (!selectedSomething) {
            // Navigation
            if (controls.UI_UP_P) {
                changeSelection(-1);
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }
            if (controls.UI_DOWN_P) {
                changeSelection(1);
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }
            
            // Selection
            if (controls.ACCEPT) {
                selectItem();
            }
            
            // Secret code input handling
            UnlockManager.handleSecretInput(FlxG.keys);
        }
        
        // Update particle positions
        particles.forEachAlive(function(p:DotParticle) {
            p.updateMovement(elapsed);
        });
        
        super.update(elapsed);
    }
    
    function changeSelection(change:Int = 0) {
        curSelected += change;
        
        if (curSelected >= menuItems.length)
            curSelected = 0;
        if (curSelected < 0)
            curSelected = menuItems.length - 1;
        
        // Update visual selection
        menuTexts.forEach(function(spr:FlxSprite) {
            if (spr.ID == curSelected) {
                spr.alpha = 1.0;
                // Scale up selected item
                FlxTween.tween(spr.scale, {x: 1.1, y: 1.1}, 0.1, {ease: FlxEase.quadOut});
            } else {
                spr.alpha = 0.6;
                FlxTween.tween(spr.scale, {x: 1.0, y: 1.0}, 0.1, {ease: FlxEase.quadOut});
            }
        });
        
        // Update character based on selection
        updateCharacter();
    }
    
    function selectItem() {
        selectedSomething = true;
        FlxG.sound.play(Paths.sound('confirmMenu'));
        
        // Flash effect on selected item
        menuTexts.forEach(function(spr:FlxSprite) {
            if (spr.ID == curSelected) {
                FlxTween.tween(spr, {alpha: 0}, 0.4, {
                    ease: FlxEase.quadOut,
                    type: PINGPONG
                });
            } else {
                FlxTween.tween(spr, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
            }
        });
        
        new FlxTimer().start(0.5, function(_) {
            switch (menuItems[curSelected]) {
                case 'songs':
                    MusicBeatState.switchState(new SongCategoryState());
                case 'options':
                    MusicBeatState.switchState(new states.options.OptionsState());
            }
        });
    }
}

// Floating dot particle class
class DotParticle extends FlxSprite {
    var velocityX:Float;
    var velocityY:Float;
    var baseAlpha:Float;
    
    public function new() {
        super();
        
        // Create a small yellow circle
        makeGraphic(12, 12, 0xFFE8D44D);
        // Make it round by setting up the graphic
        
        // Random movement direction (up-left or up-right)
        var goingRight = FlxG.random.bool();
        velocityX = FlxG.random.float(20, 60) * (goingRight ? 1 : -1);
        velocityY = -FlxG.random.float(30, 80); // Always moving up
        
        // Random starting alpha
        baseAlpha = FlxG.random.float(0.4, 1.0);
        alpha = baseAlpha;
        
        // Random size variation
        var sizeScale = FlxG.random.float(0.5, 1.5);
        scale.set(sizeScale, sizeScale);
    }
    
    public function updateMovement(elapsed:Float) {
        x += velocityX * elapsed;
        y += velocityY * elapsed;
        
        // Wrap around when going off screen
        if (y < -20) {
            y = FlxG.height + 20;
            x = FlxG.width * 0.4 + FlxG.random.float(0, FlxG.width * 0.6);
            
            // Randomize direction again
            var goingRight = FlxG.random.bool();
            velocityX = FlxG.random.float(20, 60) * (goingRight ? 1 : -1);
        }
        
        // Wrap horizontally too
        if (x < FlxG.width * 0.35) {
            x = FlxG.width - 20;
        }
        if (x > FlxG.width + 20) {
            x = FlxG.width * 0.4;
        }
        
        // Subtle alpha pulsing
        alpha = baseAlpha + Math.sin(FlxG.game.ticks * 0.003 + x * 0.01) * 0.2;
    }
}
