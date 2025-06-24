# SWAT: Elite Force

*The ultimate way to play SWAT 4.*

Unique in that it provides a realistic Rules of Engagement system and an authentic tactical experience, SWAT 4 has gone on to inspire later games such as *Cruelty Squad*, *Ready or Not*, *Rainbow Six: Siege* and *Doorkickers*. Although overshadowed by Irrational's next big release - *Bioshock* - SWAT 4 has remained popular within its niche over the years due to its immersive cooperative multiplayer and compelling environmental storytelling.

## BECOME ELITE

**SWAT: Elite Force** fixes many of the game's original bugs and consolidates the vanilla and expansion campaigns into one coherent experience, while restoring cut content and adding many important modernization and Quality of Life features. The additions and changes are designed to augment the vanilla game's experience without feeling out of place. The mod is entirely open-source and has been spun off into many other community mods, and is often considered the de-facto *way to play the game*. 

## NEW GAMEPLAY

**SWAT: Elite Force** offers the following changes to the gameplay:

 * A consolidated base game + The Stetchkov Syndicate campaign, presented in a coherent manner with a smooth progression of equipment unlocks.
 * Over **30 pieces of new equipment** and **twice as many ammo types** as the original game. Equipment is grouped into categories (Assault Rifles, Submachine Guns, ...) in the menu to make them easier to select.
 * **More realistic equipment and interactions.** Tasers can be lethal to the elderly. Bullets ricochet off of hard surfaces. Ceramic armor breaks over time with each hit. You can now throw lightsticks at a distance or hand your teammates a grenade to use. You can check to see if a door is locked without opening it. These are just a few of the many, *many* changes made to make the game more immersive and realistic.
 * A **weight and bulk** system that allows you to pick your gear more carefully. You can now choose the number of magazines or shells to bring with you - too much gear, and you'll move and interact with the environment more slowly.
 * **New game modes:** Campaign CO-OP, Permadeath, and AI Permadeath.
 * Immersive **Speech command interface**, cut from the original game. Using your voice, you can now issue commands to your AI-controlled teammates.
 * Traps and other side objectives.
 * A new **Extra Missions** campaign with two new missions.
 * Many extra levers and buttons to use in the Quick Mission Maker, including the ability to assign unlockable equipment and progression, or disable pieces of equipment.

## THE MODERN WAY TO PLAY

**SWAT: Elite Force** provides the following modernization and Quality of Life features, which have cemented its place in online cooperative gaming circles:

 * Widescreen support, including ultrawide and 16:10 and 16:9 resolution support
 * Hundreds, if not thousands of bugfixes
 * Huge improvements to civilian, SWAT and suspect AI
 * An FOV slider, mouse smoothing disable checkbox and numerous other added options
 * The ability to aim down the sights, with many of the original weapons remodeled to support this.
 * Broader support for custom maps, including their availability in the Quick Mission Maker and an 'All Missions' campaign.

# DOCUMENTATION OVERVIEW

 * ALLCHANGES.md (lists all changes made by the mod)
 * CHANGELOG.md (the full changelog of the mod)
 * CONTRIBUTING.md (documents best contribution practices)
 * CREDITS.md (all of the credits for the mod)
 * FAQ.md (read this if you have questions!, *after* you have read this!)
 * LICENSE.md (the GNU General Public License, the license for this mod)
 * MULTIPLAYER.md (everything about multiplayer)
 * README.md (you are here)
 * SpeechCommands.md (documents how to customize the Speech Command Interface)


# HOW TO INSTALL

**NOTE:** If you are using the GOG version of the game, the GOG storefront has the most up-to-date version of the mod available for easy download. This URL contains the source code and should not be used for general installation.

Copy the folder containing this folder (SEF) into your SWAT 4 directory (the one containing Content and ContentExpansion). For the CD copy of the game, this folder is located in C:/Program Files (x86)/SWAT 4 or C:/Program Files (x86)/Sierra/SWAT 4
For the GOG version of the game, it's usually located in C:/GOG Games/SWAT 4.

**CAUTION:** Do not extract the SEF folder *into* your Content or ContentExpansion folders (and therefore overwrite things), otherwise the mod will not work correctly.

To run the game, use the "Launch SEFMod.bat" file. To run SWATEd, use the "Launch SwatEd.bat" file.
You can make a shortcut to these .bat files for more convenience.

The mod can be removed by deleting the SEF folder from your hard drive.

**NOTE:** You may run into an issue with the game not saving your settings, or throwing an assertion failure at times in the Settings menu. This is mostly a problem with Windows Vista and up; try giving the folder write permissions or "Total Control". Alternatively you can make your SWAT4x.exe run in administrator mode.

# BUILDING FROM SOURCE

**ATTENTION!** You *cannot* run the game without having the content. You can find the content for the mod [here](https://1drv.ms/u/s!AnIKDNAshMwbnVml6hksfsABRhyq?e=NaCciJ).

If you are instead trying to build the source code, it is fairly straightforward.

 * Clone the source code into your SWAT 4 folder. Your folder structure ought to look very similar to the installed mod, with SWATEliteForce within your SWAT 4 folder.
 * Download the assets from the link above. Unzip the contents into your SWATEliteForce/Content folder. *Do not commit these files if you are using Git.*
 * From here, you can compile the source code with the CompileSource.bat and run the game with the LaunchSEF.bat. The source code will compile to .u files in the System folder.
 * Edit the source code within /Source/ and any ini files within /System/.

The mod's code is primarily written in UnrealScript. You can find a good resource about UnrealScript [here](wiki.beyondunreal.com). (Note, if you can't access this page, try using the Wayback Machine to access it.)

# CHANGES, SUMMARIZED

The Stetchkov Syndicate and base game missions are compressed into one campaign. As in The Stetchkov Syndicate, some equipment will need to be unlocked.

**New campaign options! Now you will have a good reason to create more than one campaign...**
 * A new EXTRA MISSIONS campaign. These are curated missions which have voice acting, full maps, and scripting, and they are designed to feel like part of the original game.
 * Now you can create an ALL MISSIONS campaign. This pulls all of the installed maps from your hard drive and makes them into a campaign, albeit without briefings. Great for use with an installed custom map pack, such as the Mega Map Pack!
 * ..and of course, the original SWAT 4 + TSS missions are a third campaign option.
 * PERMADEATH. There are two Permadeath options, for the extra challenge. AI Permadeath makes slain SWAT officers never come back, and Player Permadeath ends your campaign once you die.
 * HARDCORE MODE. Unlocked when the SWAT 4 + TSS campaign has been completed at least once. If a mission is failed once, your campaign is over. You cannot exit a mission prematurely or restart, so keep that in mind!
 * CAMPAIGN CO-OP. This feature allows you to play any (non All Missions, non Permadeath, non Hardcore) campaign in multiplayer. Help your friends complete their campaigns!

**Suspects employ a greater variety of tactics. "Insane" suspects will shoot without hesitation at hostages. "Polite" ones on the other hand, won't make this a priority. Civilians behave more realistically.**
 * Suspects will also try to shoot at you as they're fleeing.
 * Suspects will try to escape, if they are compliant and the player is not watching.
 * Suspects may now employ a "random patrol", "wander" strategy and don't stick to their assigned rooms as often.
 * Suspects have new equipment and may equip heavy armor.
 * Civilians may give up easier if they spot a suspect or a civilian being pepper sprayed, hit with beanbags, etc.
 * Suspects who have no visible weapons will be treated like civilians to SWAT (including in mirror results)

**Smarter Officer AI!**
 * Upon restraining a target, SWAT officers will now report it to TOC automatically!
 * SWAT officers are much more efficient at clearing rooms and don't form "death funnels" at doors as often
 * SWAT officers will smartly avoid looking in the same direction as their teammates while moving if possible to mitigate threat exposure.
 * SWAT officers don't become distracted by civilians and suspects while moving. They will continue following you or going towards their destination (even possibly attacking)
 * SWAT officers will automatically fire beanbags or pepperballs at fleeing suspects, and will keep them equipped as a primary weapon.
 * SWAT officers can now take cover like suspects do (including leaning around corners)
 * SWAT officers won't shoot through civilians to hit their target and are better at aiming with less lethal items in general.
 * SWAT officers can now use grenade launchers, and will use them if a GAS AND CLEAR, OPEN BANG AND CLEAR, etc action is commanded.
 * SWAT officers will drop a lightstick after clearing a room.
 * SWAT officers can now be affected by CS gas, flashbangs, tasers, pepper spray, etc.
 * SWAT officers will use pathfinding distance (instead of Euclidean distance) to determine the closest officer for things such as closing doors, etc, so it correctly picks the closest one.

**Traps. This is a huge cut feature from the game. Some doors may be trapped with bombs or alarms, and you'll need to adjust your approach to deal with it.**
 * This is a small thing but it has huge ramifications. Since some doors will be trapped, you will need to take alternate routes instead of using the same strategy every time.
 * Traps can be disarmed from the other side with the Toolkit.
 * You can order your squad to disarm traps and check for traps with the optiwand.

**New secondary objectives.**
 * Some maps have drug bags which may need to be collected to get a perfect score.
 * Incapacitated civilians may bleed out and die if they aren't reported to TOC in time, which impacts your score slightly.

**More equipment options.**
 * Over 40 new pieces of equipment have been added, including shotguns, assault rifles, submachine guns, tactical gear, and armor.
 * Several existing pieces of equipment have been improved visually.
 * The player can carry armor and all helmet options in singleplayer.
 * The breaching tab is removed and replaced with a sixth tactical slot.
 * The player can select how many magazines they would like to bring in the mission.
 * Heavy armor now shows a health percentage on the HUD. Heavy armor at 100% health can stop almost any bullet in the game, but as it takes damage, it loses the ability to protect you. It can only be shattered by bullets and sabot slugs, not buckshot or other rounds.
 * 3-packs have been added for wedges and grenades.
 * All secondary weapons equippable as primaries, and some primaries now equippable as secondaries.

**Equipment is also much more realistic.**
 * Many of the existing weapon meshes have been replaced with improved ones.
 * Weapons can be aimed down the sights, for better accuracy, using the zoom key.
 * All of your equipment factors into two meters: WEIGHT and BULK. Weight dictates your speed and is a measure of how heavy your equipment is. Bulk affects interaction speed (C2 placing/wedging door/toolkit use, but NOT restraining) and measures how big your equipment is. You can pack No Weapon/No Equipment in some slots to reduce weight and bulk.
 * You can now share some equipment with other players by pressing the melee key. You can also order your AI officers to give you a piece of equipment as well. Currently this only works for tactical tab items and lightsticks.
 * Bullets of certain types (FMJ, buckshot, etc) can now ricochet off of hard surfaces such as concrete, dirt, and water. Use caution.
 * Bullets are now subject to drag; they lose damage over distance.
 * Less lethal equipment is now actually LESS LETHAL. Some equipment (tasers, beanbag shotgun) can incapacitate or kill if used incorrectly.
 * All equipment has been modified to use real values.
 * Recoil is now affected by arm injuries.
 * Lightsticks can be thrown or dropped on the ground, just like grenades can. Everyone gets double the lightsticks!
 * A round is kept in the chamber when reloading all magazine-based weapons, except the Python. If you see your magazine going 1 above the maximum count, it isn't a bug, it's realism baby!

**Doors behave more realistically**
 * You can check the lock of a door without opening it by pressing the melee key.
 * Any shotgun can be used to breach any door.
 * A door may not be breached on the first shot of a shotgun. This depends on the material of the door. The M870 Breaching can breach any door in one shot.
 * When doors are breached with shotguns, they do not swing open like when breached with C2. You have to shoot the knob and then open the door.
 * Broken doors can now be closed and/or wedged.

**Commands can be issued using your voice. To enable this feature, tick 'Use Speech Recognition' in the Audio Options.**
 * See the SpeechCommands.md file for more information on how to issue orders using the Speech Command Interface.

**Commands are easier to give with a new Graphic Command Interface with lots of submenus instead of a single long list.**
 * You can now issue BREACH commands on unlocked doors.
 * You can now pick which style of BREACH you would like - either C2 & CLEAR or SHOTGUN & CLEAR
 * New CHECK FOR TRAPS command allows your AI companions to check doors for those all-important traps.
 * LEADER THROW commands: Now you can be the one to throw the grenade!
 * Lightsticks are broken into two commands: DROP LIGHTSTICK (where you order the nearest AI officer to drop a lightstick at their feet) and MARK WITH LIGHTSTICK (where you order an AI to drop a lightstick at what you're aiming at)
 * New RESTRAIN ALL, SECURE ALL, DISABLE ALL and SEARCH AND SECURE commands order officers to secure all targets near the player.

**Harsher penalties for tougher gameplay.**
 * Hostages and suspects that become incapacitated or killed now need to be reported to TOC, otherwise there is a penalty.
 * AI controlled officers can now trigger Unauthorized Use of Force when they use C2.
 * Snipers can now trigger Unauthorized Use of Force and Unauthorized Use of Deadly Force.
  * The game seems to take some wild liberties as to what qualifies as a passing mission. You could shoot all of the suspects illegally (in some cases without getting any penalty) on Food Wall on Hard and still beat it. You would be FIRED if you did this in real life.
  * A person being incapacitated is a big deal, and an ambulance would need to be ordered. Failing to disclose this could put their lives in jeopardy, so it makes sense for this to be a penalty. It did this for officers though (?) which I found odd.

**Important QOL (quality-of-life) and playability features that are essential to playing the game.**
 * There is an FOV slider and Mouse Smoothing disable checkbox. Also, widescreen resolutions are available in the menu and are (mostly) free of bugs.
 * Option to disable the initial dispatch briefings.
 * The game will tell you when you incur a penalty or complete an objective.
 * Wedges, grenades, lightsticks and C2 all show how many pieces you have left, while you have them equipped.
 * You can now assign loadout tabs (or whole loadouts) to one officer, a team, or the whole element.

**Overhauled Quick Mission Maker.**
 * All of the Quick Mission Maker scenarios are accessed from the Career menu instead of the Play Quick Mission menu. You need to create a new career for each one.
 * You can now use custom maps in the Quick Mission Maker.
 * You can now write your own briefings, as well as disable the civilians, suspects, and timeline tabs of the briefing.
 * You can now create a progression system, where missions are completed one-at-a-time.
 * You can now attach unlocks to each mission in a Quick Mission Maker pack.
 * You can now disable equipment in a Quick Mission Maker pack.
 * You can now rearrange the missions in a Quick Mission Maker pack. (Yes, this was something you couldn't do before...)

**Multiplayer improvements!**
 * Includes a fully-functional admin mod, with WebAdmin capabilities.
 * Snipers are now available in multiplayer.
 * New kinds of voting: Next Map, Start Map, and End Current Map. You can now choose to disable certain kinds of votes, instead of disabling all voting. There are other special options added regarding voting.
 * The chat now reports which room a person is when they send a chat message
 * You can enable or disable friendly fire in CO-OP.
 * You can now un-ready yourself in the pre-game lobby.


# MOD COMPATIBILITY

SWAT: Elite Force is compatible with skins and custom maps out of the box, without modifications. It is not compatible with total conversions or new weapon mods. It has some compatibility issues with admin mods.
To make this process more painless, I've gone ahead and listed each of the mods on Moddb and elsewhere, and provided the compatibility status.

**Fully Compatible; no special installation steps:**
 * SWAT 4 ENB / Reshade
 * SWAT 4 Music Overhaul
 * ANY map pack mod. (DO NOT install the Mega Map Pack campaign mod in its installer, it is not needed with this mod)
 * ANY custom officer skin mod.
 * BFHL character models mod (the author provides a compatible version)


**Partially Compatible; some assembly required or there are bugs:**
 * SWAT 4 Graphical Enrichment Mod (GEM). (Not usable in multiplayer)
 * SWAT 4 Retextured Mod. (Not usable in multiplayer)
 * Snitch Mod. (It can crash on occasion)
 * LEVEL 13. (Only the maps are supported.)
 * GSK Character Models (see above)


**Not applicable; SEF includes the features of these mods and/or improves upon them:**
 * Brettzie's M4A1
 * SWAT 4 Widescreen Mod
 * Gez Admin Mod
 * Markmods Admin Mod
 * Mega Map Mod
 * HugeOfficerVarieties

**Not compatible; SEF does not work with these mods at all and cannot possibly function with:**
 * *Any mod based on SEF*
 * SWAT 4 Remake Mod
 * SWAT 4 1.2 Mod
 * Code 11
 * 11-99 Enhancement Mod
 * HSM Enhancements
 * Sheriff's Special Forces (SSF)
 * SAS Mod (SEF includes many of its weapons)
 * Speech Recognition Improvement (SEF includes many of its features)


# KNOWN ISSUES

Please read the FAQ.md before looking here! It's entirely possible that what you are seeing is intentional behavior.

  * Officers sometimes ignore orders, you might have to issue a command two or three times. Problem of the original game.
  * Officers sometimes ignore orders and say something like "I'm busy." This is a problem of the original game; they sometimes can see suspects where the player can't.
  * Sometimes when you are loading up the game, you can get no sound at all. This is an issue introduced by the Stetchkov Syndicate expansion pack. Sometimes it can be solved by simply restarting the game and not running the game in windowed mode. Sometimes, if you have two detected audio devices (one for output, and one for both input and output), make sure that the one that is responsible for both input and output is DISABLED. The game is bugged and will sometimes pick the wrong audio device.
  * "gui_tex package version mismatch" when joining a server: Make sure you are running under International language. Sometimes it defaults itself to English or some other language. Search for `Language=eng` or `Language=grm` in SEF/System/Swat4x.ini and make sure it's set to `Language=int`

# LICENSE
This software is licensed under the GNU General Public License v2. The source code is freely available at https://github.com/eezstreet/SWATEliteForce
