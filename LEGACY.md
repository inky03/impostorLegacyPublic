# INFORMATION
TWITTER ACCOUNT: @VSIMPOSTOR
WEBSITE: https://vsimpostor.com/

# SUPPORTED LANGUAGES (as of 1.1.1)
- English (United States)
- English (United Kingdom)
- French
- German
- Greek
- Czech
- Hungarian
- Indonesian
- Irish
- Italian
- Japanese
- Korean
- Spanish (LATAM)
- Spanish (ES)
- Norwegian
- Polish
- Portuguese (Portugal)
- Brazilian Portuguese
- Romanian
- Turkish
- Russian
- Serbian
- Swedish
- Chinese (Traditional)
- Chinese (Simplified)
- Ukrainian
- Arabic
- Danish
- Dutch
- Thai
- Vietnamese
- Lithuanian

# CHANGELOG
Current version: **1.1.1b**

## 1.1.2 (? 2026)

### Additions
- You can now skip time in the Pause menu, while Charting Mode is active.
- Updated some libraries.
	- Bumped Lime, OpenFL and Flixel versions.
		- Seamless camera rotation with `scrollAngle` is now supported.

### Bugfixes
- Fixed BPM and Section Beats UI behaving incorrectly in the Chart Editor.
- Roomcode Pico sprite has a correct gameover sprite.
- RHM's Z-value is fixed in the greenhouse stage.
- Polus Boyfriend's windy variant now has correct looped poses.
- Maroon's poses are now looped.
- Fixed inconsistency with Identity Crisis doppelgänger notes. (GitHub pull)
- Grey given a correct healthbar color.
- A bunch of offsets were fixed.
- Pink's Pretender death animation was re-exported to fix effects.
- Black's Defeat sprite was re-exported to fix effects.
- White's halo effect was fixed.
- Fixed some variables not working correctly in Hscript.
- Pets are correctly scaled in Pip Towers stage.
- Playable Green's scared animation is fixed.
- Dark BF's down pose plays correctly.

### Changes
- HUD no longer cuts off in Ejected, Turbulence and Danger.
- The "VICTORY" text in Victory is now translatable and in higher quality.
- Copy Pet in Identity Crisis is now in grayscale instead of an off colored filter.
- Parasite Maroon's healthbar color changed for effect.
- Defeat stage tweaked.
- Few sprites were turned into atlases.
- Variants used more in characters.
- The Ejected cutscene is changed if using skins.
- Meltdown uses a correct icon in the Freeplay menu.
- FINALE stage was simplified for Low Quality mode.
- Who given optional captions.
- Girlfriend's sprite in Danger was updated for consistency.

## 1.1.1b (june 21 2026)
  
### Bugfixes
- Fixed dialogue and song credits not working in mods.
- Lights Down correctly changes the current character if skins are equipped.
- Clipping in Voting Time background fixed.

### For modders
- All events now have descriptions about how they work.

## 1.1.1 (june 21 2026)

### Additions
- **2 new languages have been added:**
	- Lithuanian
	- Vietnamese
- Added Change Noteskin event.
- Tabs at the top of the Freeplay Menu now scroll.
- Added `"defeat"`, `"retro"`, `"dark"` (for Lights Down) and `"monotone"` (for Identity Crisis) skin variants.
- Added a `canTaunt` variable to characters.
- Girlfriend can now react in D'low.
- Added Mira GF easter egg to Grey stage.
- Added more credits.
- Pets and character groups now have signals for changing / preloading.
- (For modders) Small improvements have been made to scripting.
	- Added a `modFolder` variable.
	- Added a `parent` variable to state and substate scripts.
	- Plugin scripts can now share public variables.
	- Defines are now supported.

### Changes
- Updated Voting Time background to be higher quality.
	- Added a new celebrity cameo.
- Updated Charles' sprite in Greatest Plan.
	- Lingering lag doesn't happen anymore.
	- Charles now has afterimages.
- Can no longer taunt during the tragedy in D'low.
- Text in Identity Crisis is now better synced.
- Updated Lights Down lighting for skins.
- Rebalanced coloring for skins in Defeat and Reactor.
- Identity Crisis now supports flags and variants for characters and pets.
- Pet animations don't loop by default anymore.
- Increased sing lengths for characters.
- Updated behavior for playback rate.
- Halved BPM for Reactor.
- Updated `Paths` functions.
- Updated Dev Mode cheat menu.
- You can now hold Shift + 3 to slow time down in Dev mode.

### Bugfixes
- Fixed a crash when leaving the Character Editor.
- Fixed icon position delay.
- Fixed FC status desync.
- Attempted to fix a bug in Turbulence after the song ends.
- Added a failsafe for Double Trouble not showing up in Freeplay.
- Fixed some errors with some charts:
	- Ashes (removed a stray note)
	- Delusion (some parts in Grey's side incorrectly charted)
	- Reactor (added a missing note)
- Some skins in Identity Crisis should be properly centered now.
- Negative beans amounts aren't shown when completing a song anymore.
- Black's Double Kill sprites are smoother again.
- Fixed Afterimages option no longer appearing.
- Fixed miscellaneous bugs with skins and pets.
- Fixed an error where plugin scripts wouldn't execute.
- Fixed incorrect currency icon and sound after completing a song when using mods.
- Fixed an animation bug with Boyfriend's sprites in Ejected and Danger.
- Fixed a bug with Boyfriend in Reinforcements.
- Fixed a coloring error in the Toppat Chopper.
- Fixed Double Kill overlay transparency.
- Fixed Tuesday GF position and bop time.
- Fixed Legacy events not showing up on the Chart Editor.
- Fixed Auto Pause option not applying after relaunching the game.
- Fixed a BPM issue with the Adjust Delay menu when opened from the Pause menu.
- Fixed a bug with Identity Crisis pets being tilted after Green's parts.
- Fixed an incorrect game over sprite in Who.
- Red Mungus' strumline no longer appears with Opponent Notes disabled.
- Girlfriend can no longer appear in Top 10.
- Henry's idle plays correctly in Greatest Plan.
- Fixed incorrectly sized Character Editor UI box.
- Parasite Black's glint is now correctly displayed.
- Playable Yellow's colors fixed.
- Generic Gameover offsets fixed.

## 1.1.0 (june 10 2026)

> [!IMPORTANT]  
> The mod's assets are now located in the `assets` folder instead of `content/legacy`!! Reinstalling the mod completely is advised!!

It's like, hd now

### Additions
- Added Middlescroll option.
- Added Uncapped Framerate option.
- Added Discord Rich Presence option.
- Added additional settings for Lane Underlay.
- Added VSync option.
- Added Video subtitles.
	- You can toggle this option in the Language options category.
- Updated taunting behavior.
	- You can now set a keybind for taunting in keyboard and controller. (space by default, as usual)
	- Any playable character with a "hey" animation can now taunt.
- Bumped Lime, OpenFL and Flixel versions to Funkin Crew's forks.
	- New blend modes are supported, albeit not implemented in some devices (use with caution).
- Bumped Hscript Iris to dev version.
	- Fixed operators.
	- `using` is supported more properly.
	- String interpolation is now supported.
	- Key and value iterators are now supported.
- Some cutscenes have been updated.
- Updated Double Trouble stage.
- Updated Reactor stage.
	- Added some transitions in Story Mode.
	- A visual error with the reactor core has been fixed.
- A button has been added in Freeplay to reset your highscore.
- The game will now attempt to back up your save data automatically.
- Finale health bar colors are now assigned automatically for custom skins.
- Background crewmates in Sussus Toogus now have idle bopping animations.
- Jelqer given a portrait for Voting Time and Victory.
- Button hints are now shown at the bottom when using a controller.
- Added support for PlayStation 5 controllers.
- Current mod directory is now set properly in Freeplay and Story Mode.
	- You can now use custom graphic assets in these menus just by replacing them in your mod folder.
    - Ex: Changing the Freeplay cards for songs for a custom week, changing the Story Mode node and pathway for your custom week.
	- May fix potential compatibility issues.
- Pets behavior has been expanded.
	- Pets can now run a script file.
	- Pets can now use the character JSON format.
		- Allows pets to be given swaying animations (like Girlfriend), looping animations or flags (see below).
- For modding convenience, characters, pets, songs and stages can now be given flags.
	- Useful for special behaviors with cosmetics in stages.
	- See the [Modding Guide](https://docs.google.com/document/d/1Q4RhAwkRDHiD6EqlygcZ5ll76XTfUtQdY_kyE-udTGg) to understand how to use flags.
- Holding 3 during a song while in Dev mode allows for time bending abilities.
- Tomatungus has been released.
- Grey gets a new sprite in Pretender.
- More playable characters have taunt animations now.
- Playable Maroon now has a lava variation.
- Playable Grey now has a scary variation (different lighting).
- Ejected and Danger stages now have a couple of unique pet variants.
- Options and Locker menus now have a scrollbar.
- Top 10 actually looks good now.
- Added `Function_Cancel` to Hscript (like `Function_Stop` and `Function_Halt` combined).

### Changes
- **Alarms and other additional strobe/flashing effects are now toned down when Photosensitivity is enabled.**
- Some sprites have been overhauled or updated.
- General memory and performance improvements.
- Some charts have been changed:
    - Reactor (Recharted)
    - Identity Crisis (Recharted)
    - Lemon Lime (Recharted)
    - Stargazer (Recharted)
    - Delusion (Major pattern adjustments)
    - Sussus Moogus (Timing fixes & minor pattern adjustments)
    - Sussus Toogus (Added a singular note and fixed two others)
    - Sabotage (Small pattern adjustments)
    - Sussus Toogus (Scroll speed & minor note re-arrangements)
    - Ejected (Minor pattern adjustments throughout all of BF side)
    - Danger (Minor adjustments to note timings & BF side pattern adjustments)
    - Double Kill (Adjustments to note timings & patterns)
    - Ashes (Major pattern adjustments)
    - Magmatic (Pattern adjustments)
    - Blackout (Minor pattern restructure & nerfed intro) (Removed doubled camera events)
    - Neurotic (Pattern adjustments & removed unneccesary sustains) (Removed doubled camera events)
    - Heartbeat (Minor pattern adjustments)
    - O2 (Pattern adjustments)
    - Chlorophyll (Minor pattern adjustments)
    - Reinforcements (Minor pattern adjustments)
    - Greatest Plan (Pattern & Timing adjustments)
    - Double Trouble (Chart updated)
- Lots of languages updated.
- Hold notes now have more accurate lengths.
- Charter credits added for songs that were missing them.
- Performance improvements for the Chart Editor.
- Lane Underlay options have been moved from Gameplay to Visuals & UI.
- Pause Menu now properly shows the correct portraits in the following songs:
    - Pretender
    - Victory
    - Greatest Plan
    - Reinforcements
- Visuals for the Options menu have been cleaned up.
- Stages have been relocated to data/stages for the base mod.
- Hscript log system has been updated to not flood the screen (NightmareVision feat).
- You can now hold in some menus (ex. Freeplay) for quick scrolling.
- Ejected's parallax clouds now scroll more noticeably.
- Main Menu now keeps your last selected choice on return.
- Changed the spacing of control hints at the bottom of the screen.
- Removed cutout in note hold splash.
- The song playlist in Story Mode is now hidden in Void Week to match the original mod.
- All four strumlines are now visible in Monotone Attack and Voting Time.
- Clowfoe's appearance in Sussus Toogus updated.
- Turbulence portrait updated.
- Removed access to broken/unused editors in the Master Editor Menu.
- Updated music syncing (hopefully this fixes some bugs).
- Removed character afterimages playing during the dark section of Lights Down.
- Polus BF sprite now no longer has artificial wind when in other stages.
- Yellow's body in Oversight is hidden when using Playable Yellow.
- Adjusted Ghost Jorsawsee's positioning in Victory.
- Playable Mini Grey's hey pose updated.
- A lot of rimlight shaders were updated for stages.
- Using a Sus BF skin in pixel Tomongus songs now changes BF to the pixel Sus BF skin.
- Pretender and Double Kill stage lighting updated.
- Victory and Voting Time freeplay icons were updated.
- Jerma sprites were updated to the hotfix version.
- Insane Streamer reverted back to the V4 version and returned its jumpscare animation.
- Playable Pink sprite was updated.
- Playable Maroon sprite was updated.
- Baller Boyfriend sprite was updated.
  - His animations are now correctly looped instead of being really long.
- Updated Girlfriend sprite in Ejected.
- Tomongus Tuesday GF is sexier now.
- Skins can now be equipped in Tomongus week.
- Girlfriend skins can now be equipped in Ejected.
- Pets in Ejected and Identity Crisis have a nicer tween.
- Modified ROOMCODE events.
- Lobby Nene given more expressions.

### Bugfixes
- Fixed a crash on startup with the error "There is no asset library with an ID of default" 
- Fixed a crash on startup related to corrupted controls save data.
	- This also changes the save location, so your keybinds have been reset!! (your scores are safe)
- Fixed a memory leak that would occur when exiting Freeplay, Story Mode, Cosmicube, and Awards menus.
- Fixed a softlock in state transitions.
- Fixed some major gameplay bugs.
- Fixed bugs with Ghost Tapping disabled.
	- Fixed rescuing a hold note causing a miss.
	- Fixed tapping causing no damage.
- Fixed 100% achievement being given out early.
- Fixed Main Menu Shinies not matching the 100% completion award (again!).
- Boyfriend is now better positioned in Voting Time.
- Fixed Girlfriend skins being disabled in Danger. Also fixed a tangent.
- Fixed a mod conflict related to song completion.
- Fixed an issue where disconnecting an audio device made the game unplayable until reopening (bumped Lime version to FunkinCrew).
- Fixed an issue with glitched textures related to video playback (bumped Hxvlc version to 2.2.6).
- Fixed Freeplay lock animation.
- Fixed an execution order error in Story Mode node scripts.
- Readded missing checkboxes for skins and pets in the Chart Editor.
- Fixed timings and missing notes in:
	- Crewicide
	- Monotone Attack
	- Double Trouble
	- Ashes
	- Mando
- Henry Week cutscene should now correctly redirect to the Henry week.
- Fixed some issues with the copy pet in Identity Crisis.
- Fixed an offsetting bug in a Double Kill easter egg.
- Fixed visual flicker in options menu when selecting a different tab with mouse.
- Fixed Main Menu Shinies not matching the 100% completion award (again).
- Fixed "Afterimages" checkbox in the Character Editor.
- Offsets for Danger props and Upgirl fixed.
- Fixed a typo in "extraNoteHit" function.
- Fixed Ghost BF's ability to alter characters in songs he's not supposed to.
- Fixed a bug with misplaced icons in the Chart Editor.
- FINALE stage correctly scaled.
- Boiling Point stage no longer has clipping.
- Polus BF's jacket doesn't flicker in a pose anymore.
- Polus Problems stage clipping fixed.
- Fixed Lane Underlay in O2 being more opaque.
- Fixed returns in Hscript causing a function's behavior to stop in certain cases.
- Dank Bars icons are no longer anti-aliased.

## 1.0.3b (april 27 2026)

oh my god dude

### Bugfixes
- Evil Looksie will now only appear in Developer mode.
- Fixed Identity Crisis's Pause Menu portrait.
- VHS shader has been fixed for some GPUs (again).

## 1.0.3 (april 27 2026)

the third vvs impostor. a third one. yes bro. thrice oh so nice.

### Additions
- Added Generic Pico Gameover.
- Added back Black and Tomongus pause themes.
- Added back Jorsawsee Week's pause theme.
- Added "Exit Charting Mode" to the Pause Menu.
- Added a Developer Mode watermark.
- Added Evil Looksie.

### Changes
- Updated Application Title to display the version of the mod.
- Updated Rank requirements, they should be way kinder.
- Higher ranks are now saved regardless of score, this previously prevented players from getting a higher rank.
- Updated a couple of languages.
- The clouds in Charles's sprite now scroll.
- Double Trouble now supports skins on song restart.
- Pixel hold covers updated.
- Finale health drain has been re-balanced.

### Bugfixes
- Attempted to fix a crash and a weird display bug in Ejected's cutscene.
- Missing a hold note no longer counts as two misses.
- Fixed Main Menu Shinies not matching the 100% completion award.
- Pixel Tomongus's icons are no longer anti-aliased.
- Song audio now pauses properly when pausing at the same time the song starts.
- Skipping the Motorfrog intro before it loads no longer crashes the game.
- Stick BF's down miss animation plays properly now.
- VHS shader has been fixed for some GPUs and should also now be disabled when shaders are turned off.
- Camera in the Defeat stage should now work properly outside of Defeat. (Modding fix)
- Fixed South Korea flag visual in the credits.
- Fixed a certain ambience sound persisting into the Main Menu.
- #!!?#!?'s idle now loops as intended.

## 1.0.2 (april 26 2026)

Whew.

### Changes 
- Application icon updated.
- Updated a couple of languages.
- Double Trouble supports pets for now.

### Bugfixes
- Fixed stacked notes in:
  - Greatest Plan
  - Reinforcements
  - Monotone Attack
  - Crewicide
  - Chipping
- Fixed bug related to saving keybinds.
- Fixed crash related to shaders on Boiling Point.
- Fixed specific shader compile errors for some GPUs.
- Victory's character transitions no longer cover up notes.
- Double Kill now uses a shader when using skins and pets on it's ending.
- Fixed a bug where Boyfriend could vent whenever he felt like it.
- Fixed a bug in Lights Down with Shaders disabled.
- Fixed Cosmicube requirements for Triple Trouble weeks.
- Fixed Identity Crisis' line after the intro not playing as intended.
- Charting Mode is now disabled when entering Freeplay or Story Mode menus.

## 1.0.1 (april 25 2026)

Patch we made 10 minutes after release LOL

### Bugfixes
- Fixed post-Week 1 crash.
- Fixed visual bug in Lights Down's outro.
- Fixed a skip.

## 1.0.0 (april 25 2026)

Below is a list of big/notable changes made from v4.1.0 to Legacy 1.0.

### General Changes
- Changed the intro from "IMPOSTORM" to "MOTORFROG".
- Switched from Psych Engine 0.4.2 to Nightmare Vision.
- Added LIME GREEN JADSPOSTOR Week to replace Loggo's Halloween.
  - Added Lemon Lime, Chlorophyll, Inflorescence, and Stargazer.
- Removed Loggo's Halloween.
  - Removed Christmas and Spookpostor.
  - Loggo's Halloween DX is available to download on the website.
- Removed Alpha Week. (Alpha Moogus, Actin Sus)
  - VS. Impostor V5 is available to download on the website.
- Added a Locker menu to switch between skins/pets.
- A lot of character sprites converted into atlases to save up file sizes and memory.
- Numbers (mainly currency counts) that go higher than 999 now have comma separators for readability.
- Charter credits added to the song popups.
- Added modding support.
  - To install mods, open the /content/ directory in your build and export your installed mod folder into it.
  - Modding it allows for adding custom cosmicubes/characters/songs etc.
- Credits (Sussus Endus) overhauled with new portraits, fixed missing credits, remade icons and new members added.
- Generic Game Over updated.
- Renamed "Combo Breaks" to "Misses".
- Added dialogue tracks for songs that didn't have any before.
- Cutscenes can now be skipped.
- Changed Girlfriend's dialogue tablet color to Coral.
- Countless charts polished and updated.
- Added keyboard and mouse support to every menu.
- Added Looksie.

### Main Menu
- Main Menu overhauled.
- Added stars (or as Clowfoe calls it, Shinies) to track your completion.

### Story Menu
- Story Menu UI updated.
- Added mouse support.
- Story Menu's pre-Finale visuals updated.

### Freeplay Menu
- Song Credits to credit the composer(s) of each song.
- Added Freeplay Section categories.
- Added Ranks given based off of accuracy and misses.
- Gave accuracy a percentage symbol.

### Options Menu
- Options Menu overhauled.
- Renamed "Flashing Lights" to "Photosensitive".
- Added following settings:
  - Language - Self explanatory, see "Languages" section for a list of languages.
  - Colored UI - Colors Score Text based on the opponent's icon color, like V4.
  - HUD Rank Display - Shows Rank based on accuracy.
  - Afterimages - Ghost Double notes, like V4.

### Cosmicube Menu / Skins / Pets
- Cosmicube Menu overhauled with support for multiple cosmicubes.
- Added flavor text to every item alongside hints.
- Made following skins purchasable:
  - Sus BF skin
  - Tuesday GF skin
- Updated the following skins and pets:
  - Crew BF skin
  - Stick GF skin
  - Playable Black, Red, Green skins
  - Mini Crewmate pet
  - Snowball pet
- Added the following skins:
  - Fall Guy
  - Baller BF skin
  - Playable Yellow..?
  - Playable White
  - Playable Maroon
  - Playable Mini Grey
  - Playable Pink
  - Crew GF skin
  - Alt. MIRA GF skin
  - UPDOG GF skin
  - UPDOG BF skin
- Added the following pets:
  - Headslug
  - Snowmate
  - Charles Chopper
  - Squig
  - Hampton
  - Magmate
  - The Nug
  - Fishmonger
  - Lil' Mungus
  - Thermonuclear Bomb
  - Fribbit (Created by MikeyGuy, winner of the MARCH 2026 PET CONTEST.)
- Adjusted positions and offsets of multiple skins.
- Added Pet and Skin support to most songs without them, which are listed in their respective week categories.
- Added easter eggs and interactions with select skins and pets.

### Pause Menu
- Pause Menu overhauled.
- Options is now accessible from the pause menu.

Below is a list of changes made to weeks / songs.

### Polus Problems
- Replaced snow graphic with snow particles.
- Fixed Red's sabotage animation.

### Mira Mania
- Green's portrait updated.
- Sussus Toogus recharted.
- Added population to Sussus Toogus.
- Green will now wave at Powers.
- Lights Down slight name change ("Lights-Down" > "Lights Down")
- Lights Down now has Photosensitive option support which reduces the amount of lights out effects.
- Fixed bug where Lights Down's score text would be invisible when Colored UI is enabled.
- Lights Down's ending events timing adjusted.
- Lights Down stage tweaked.
- Changed a single bopper in reactor.
- Ejected now has Photosensitive option support which slows down the rate of buildings and hides clouds.
- Ejected now ends the intro video prematurely if the song's intro ends before the video.
- Ejected given BF skin and pet support.
- Green Parasite sprite polished.

### Airship Atrocities
- Mando song remade by Emihead and recharted.
- Gumpy now properly liquidifies for no reason in dialogue.
- D'low slight name change ("Dlow" > "D'low")
- D'low camera bops are now toggleable via Photosensitive option.
- D'low shocked BF visuals updated and now apply to more skins.
- Fixed bugs associated with the teleporter in Story Mode.
- Oversight song remade by Emihead and recharted.
- Oversight's yellow dead body re-added back to the stage.
- White's Oversight sprites now feature alt UP and DOWN poses.
- Fixed Oversight's "Double White" glitch.
- Danger given skin and pet support.
- Danger recharted.
- Danger Black sprite updated.
- Danger song mixing updated.
- Added a portrait for Double Kill.
- Double Kill recharted.
- Double Kill events updated.

### ??? Week
- Defeat misses submenu overhauled.
- Defeat instrumental and voices track mixing updated.
- Fixed retro Defeat Black's colored text being the unintended color.
- Added retro Defeat game over.
- Defeat stage updated.
- Black Parasite sprite is in higher quality.
- Finale cutscene after Identity Crisis updated.
- Finale given health drain from opponent's notes.

### Magmatic Monstrosity
- Replaced snow graphic with snow particles.
- Maroon's Hey animation extended.
- Boiling Point shaders are now toggleable.
- Boiling Point particles hidden on Low Quality.
- Boiling Point ending added.
- Parasite Maroon sprite polished
- Boiling Point stage given parallax and a moving platform.
- Boiling Point now melts and dehydrates your pets.

### Deadly Delusion
- The Chromatic Abberation effect is now used in other songs and can now be toggled.
- Stage visuals updated.
- Black background sprite updated.
- Blackout mixing updated.
- Added events to Blackout and Neurotic.

### Humane Heartbeat
- Pinkwave cutscene given Photosensitive support.
- Brought back unused background elements.
- Fixed Grey's cone consistency.
- Pretender Pink icon brought back.
- Pretender background positions fixed.
- Added a portrait for Pretender.

### Jorsawsee's Jams
- Updated the backgrounds of the following songs:
  - O2
  - Voting Time
  - Turbulence
  - Victory
- Jelqer is now their intended Rose color.
- Red Mungus parasite design updated along with its sprite and portrait.
- Ghost Jorsawsee sprite updated to match their O2 design and animation style.
- ROOMCODE Pico sprite updated.
- Added Nene to ROOMCODE.

### Rosy Rival
- Renamed to Rosy Rival.
- "Sussy!" rating updated.
- Tomongus Tuesday recharted to be in 3/4.

### Battling the Boyfriend
- Fixed a bug related to Greatest Plan and BF skins.
- Added missing Reginald portrait to Armed.
- Added Reginald's icon to Armed.

### Freeplay Songs
- Identity Crisis visuals updated.
- Couple pets in Sauces Moogus have a special property.
- Updated the following portraits:
  - Who,
  - Esculent,
  - Ow,
  - Monotone Attack
- Who sprites polished and given extra animations.
- Esculent sprites polished.
- Crewicide stack notes removed.
- Drippypop sprite and icon updated.
- Pip given miss animations.
- Chippin ending given more camera events.
- Fixed Chipping's events.
- Chipping now starts with Pip being evil for consistency.
- Fabs, Clowfoe and Monotone sprites updated.
- Top 10 is still in the mod.
- Added a vent.