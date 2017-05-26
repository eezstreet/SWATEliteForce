# INTRODUCTION #

SWAT 4 is a fantastic game. It took all of the shortcomings of SWAT 3 - mainly the poor GUI and lack of realism and made it into a nicely packaged product.

Unfortunately it's very apparent that this game was rushed. There's tons of bugs, especially in multiplayer, and a cursory glance at the files reveals loads of missing content that never made the final cut of the game.
I spoke to one of the programmers - Terrance Cohen - through email, about the game. They received a great deal of input from SWAT and police alike to make the most realistic game that they could but ultimately had to cut quite a bit of their original vision down to make the game more appealing towards...well, gamers.
I think I could do better.
There are very many glaring inaccuracies with the game. For starters, the game doesn't penalize you for killing hostages with the snipers, which I think is silly. Suspects have a much greater variety of behaviors and are made to be more realistic. There's some rather baffling logic here. You can't equip your officers with gas masks and the ammo pouch doesn't display what actually happens with your weapons.

Enter SWAT Elite Force.
I originally wanted to try and market this mod as a police officer trainer, but I stopped getting interest in the project after encountering some bugs. I picked the game up again and started playing on |ESF| and remembered this mod. So, I started work on it again and took a much harder look at the engine, trying to figure out how everything works, and resumed work on it. I think I've got it to the point where people would really like it.

I wish I could do more with the game. I'm not an artist by any means, so a lot of the other things that I wish I could do (TASER rounds for shotguns, fixing a lot of the bad bump maps and flat shaded textures) aren't in the pipes. I do plan on dabbling with maps at some point, so there may be a custom campaign. I may include some community maps as part of the new campaign.

Since Version 3, the mod has gained a large following. I've since been able to enlist the help of others to work on the mod, and it's become a team effort in improving the game.

# TABLE OF CONTENTS #
1. How to Install
2. Changes, Summarized
3. Frequently Asked Questions (FAQ)
4. Known Issues
5. Other Minor Changes
  - Gameplay
  - GUI
  - Equipment
  - Mission Changes
6. How to play in Multiplayer
7. Version History
8. Credits
9. License

# HOW TO INSTALL #
Copy the folder containing this folder (SEF) into your SWAT 4 directory (the one containing Content and ContentExpansion).
By default, this folder is located in C:/Program Files (x86)/SWAT 4 or C:/Program Files (x86)/Sierra/SWAT 4

!!! CAUTION !!!
Do not extract the SEF folder *into* your Content or ContentExpansion folders (and therefore overwrite things), otherwise the mod will not work correctly.

To run the game, use the "Launch SEFMod.bat" file. To run SWATEd, use the "Launch SwatEd.bat" file.
You can make a shortcut to these .bat files for more convenience.

The mod can be removed by deleting the SEF folder from your hard drive.

NOTE: You may run into an issue with the game not saving your settings, or throwing an assertion failure at times in the Settings menu. This is mostly a problem with Windows Vista and up; try giving the folder write permissions or "Total Control". Alternatively you can make your SWAT4x.exe run in administrator mode.

# CHANGES, SUMMARIZED #
	* The Stetchkov Syndicate and base game missions are compressed into one campaign. As in The Stetchkov Syndicate, some equipment will need to be unlocked.
	* New campaign options! Now you will have a good reason to create more than one campaign...
		** A new EXTRA MISSIONS campaign. These are curated missions which have voice acting, full maps, and scripting, and they are designed to feel like part of the original game.
		** Now you can create an ALL MISSIONS campaign. This pulls all of the installed maps from your hard drive and makes them into a campaign, albeit without briefings. Great for use with an installed custom map pack, such as the Mega Map Pack!
		** ..and of course, the original SWAT 4 + TSS missions are a third campaign option.
		** PERMADEATH. There are two Permadeath options, for the extra challenge. AI Permadeath makes slain SWAT officers never come back, and Player Permadeath ends your campaign once you die.
		** CAMPAIGN CO-OP. This feature allows you to play any (non All Missions, non Permadeath) campaign in multiplayer. Help your friends complete their campaigns!
	* Important QOL (quality-of-life) and playability features that are essential to playing the game.
		** There is an FOV slider and Mouse Smoothing disable checkbox. Also, widescreen resolutions are available in the menu and are (mostly) free of bugs.
	* Suspects employ a greater variety of tactics. "Insane" suspects will shoot without hesitation at hostages. "Polite" ones on the other hand, won't make this a priority.
		** Suspects will also try to shoot at you as they're fleeing.
		** Suspects now employ a "random patrol", "wander" strategy and don't stick to their assigned rooms as often.
	* Smarter Officer AI!
		** Upon restraining a target, SWAT officers will now report it to TOC automatically!
		** SWAT officers are much more efficient at clearing rooms and don't form "death funnels" at doors as often
		** SWAT officers can now take cover like suspects do (including leaning around corners)
	* Traps. This is a huge cut feature from the game. Some doors may be trapped with bombs or alarms, and you'll need to adjust your approach to deal with it.
		** This is a small thing but it has huge ramifications. Since some doors will be trapped, you will need to take alternate routes instead of using the same strategy every time.
	* New secondary objective: collect drug evidence. Static drug bags have been replaced with new ones that can be collected.
		** The bags count towards the "Secure All Evidence" procedure.
	* More equipment options. This includes a few cut equipment items, such as riot helmets.
		** AI-controlled officers can carry more lightsticks.
		** The player can carry armor and all helmet options in singleplayer.
		** The player can select how many magazines they would like to bring in the mission.
		** There is a new Advanced Information Panel in the loadout menu that lets you view information such as manufacturer, magazine size, etc.
		** Heavy armor now shows a health percentage on the HUD. Heavy armor at 100% health can stop almost any bullet in the game, but as it takes damage, it loses the ability to protect you. It can only be shattered by bullets and sabot slugs, not buckshot or other rounds.
		** All secondary weapons equippable as primaries, and some primaries equippable as secondaries.
	* Equipment is also much more realistic.
		** All of your equipment factors into two meters: WEIGHT and BULK. Weight dictates your speed and is a measure of how heavy your equipment is. Bulk affects interaction speed (C2 placing/wedging door/toolkit use, but NOT restraining) and measures how big your equipment is.
		** Bullets of certain types (FMJ, buckshot, etc) can now ricochet off of hard surfaces such as concrete, dirt, and water. Use caution.
		** Bullets are now subject to drag; they lose damage over distance.
		** Less lethal equipment is now actually LESS LETHAL. Some equipment (tasers, beanbag shotgun) can incapacitate or kill if used incorrectly.
		** All equipment has been modified to use real values.
		** For more information, see the EQUIPMENT section.
	* Doors behave more realistically
		** Any shotgun can be used to breach any door.
		** A door may not be breached on the first shot of a shotgun. This depends on the material of the door. The Breaching Shotgun can breach any door in one shot.
		** When doors are breached with shotguns, they do not swing open like when breached with C2. You have to shoot the knob and then open the door.
		** Broken doors can now be closed and/or wedged.
	* Commands can be issued using your voice. To enable this feature, tick 'Use Speech Recognition' in the Audio Options.
		** Functions exactly the same as in the Speech Recognition Improvement mod by MulleDK9. Not all commands from that mod are present however.
		** See the SpeechCommands.txt file for more information on how to issue orders using the Speech Command Interface.
	* Commands are easier to give with a new Graphic Command Interface with lots of submenus instead of a single long list.
		** You can now issue BREACH commands on unlocked doors.
		** You can now pick which style of BREACH you would like - either C2 & CLEAR or SHOTGUN & CLEAR
		** New CHECK FOR TRAPS command allows your AI companions to check doors for those all-important traps.
		** LEADER THROW commands: Now you can be the one to throw the grenade!
		** Lightsticks are broken into two commands: DROP LIGHTSTICK (where you order the nearest AI officer to drop a lightstick at their feet) and MARK WITH LIGHTSTICK (where you order an AI to drop a lightstick at what you're aiming at)
	* Harsher penalties.
		** Hostages that are incapacitated at the start can now become DOAs if not reported in time. This has an impact on your score.
		** Hostages and suspects that become incapacitated or killed now need to be reported to TOC
		** AI controlled officers can now trigger Unauthorized Use of Force when they use C2.
		** Snipers can now trigger Unauthorized Use of Force and Unauthorized Use of Deadly Force.
		** The game seems to take some wild liberties as to what qualifies as a passing mission. You could shoot all of the suspects illegally (in some cases without getting any penalty) on Food Wall on Hard and still beat it. You would be FIRED if you did this in real life.
		** A person being incapacitated is a big deal, and an ambulance would need to be ordered. Failing to disclose this could put their lives in jeopardy, so it makes sense for this to be a penalty. It did this for officers though (?) which I found odd.
		** The game reveals much more information to you. A warning will display when you have made a penalty, and a message will show when you have completed an objective.
	* Multiplayer improvements!
		** Snipers are now available in multiplayer.
		** New options available for server hosts for voting; see Default.ini for more information


# FREQUENTLY ASKED QUESTIONS (FAQ) #

 * How do I install the mod?
 * How do I use the speech recognition?
 * What's the difference between "MARK WITH LIGHTSTICK" and "DROP LIGHTSTICK"?
 * How can I check for traps in multiplayer?
 * How can I play in Multiplayer? Are there any servers?
 * How can I report a bug?
 * Why can't I play in Barricaded Suspects, VIP Escort, Smash and Grab, or Rapid Deployment?
 * Are you going to add AI officers in CAREER CO-OP?
 * Does this mod work with other mods?
 * Are there more missions for Extra Missions coming out?

## HOW DO I INSTALL THE MOD?
Please read the How to Install section of this README. :)

## HOW DO I USE THE SPEECH RECOGNITION?
First, you will need to ensure that your operating system supports Speech Recognition. What you'll need is the Microsoft Speech Recognition API, which is available here: https://www.microsoft.com/en-us/download/details.aspx?id=27224
If your system meets the requirements, the 'Use Speech Recognition' checkbox will be available.
You can also bind a key to toggle the functionality ingame, which is good when you're speaking for a Let's Play, for example.
A list of trigger words is provided, starting with Patch 5.1. See SpeechCommands.md for more information.

## WHAT'S THE DIFFERENCE BETWEEN "MARK WITH LIGHTSTICK" AND "DROP LIGHTSTICK"?
MARK WITH LIGHTSTICK orders the nearest officer to go to the location and drop a lightstick. DROP LIGHTSTICK orders the nearest officer to drop a lightstick at their feet.

## HOW CAN I CHECK FOR TRAPS IN MULTIPLAYER?
Use the Optiwand, and aim up at the doorknob. The AI in singleplayer don't use the optiwand because they're super duper pros at it, and pulling out the optiwand is slower.

## HOW CAN I PLAY IN MULTIPLAYER? ARE THERE ANY SERVERS?
Please read the How to Play in Multiplayer section of this README. :)

## HOW CAN I REPORT A BUG?
The best, and preferred method is to post it directly on our GitHub issues page: https://github.com/eezstreet/SWATEliteForce/issues
However, since doing so requires a GitHub account, it's not the most desirable option. You can also post on the Moddb page, which doesn't require an account.
Additionally, you can check us out on Discord, and chat with the developers: https://discord.gg/RfujTnF

## WHY CAN'T I PLAY IN BARRICADED SUSPECTS, VIP ESCORT, SMASH AND GRAB, OR RAPID DEPLOYMENT?
This mod uses very realistic values for the weapons, and ultimately it doesn't play well in PvP modes for those reasons.
Personally I would recommend playing these PvP modes on the original SWAT 4, non-TSS, since the PvP balance is as good as it can get.

## ARE YOU GOING TO ADD AI OFFICERS IN CAREER CO-OP?
Possibly.

## DOES THIS MOD WORK WITH OTHER MODS?
Here's a good list of mods that will generally work out of the box, without any kind of issues:
- Any kind of custom map, including the Mega Map Pack
- Any kind of added custom skin
- Any kind of texture mod, like SWAT 4: GEM

Here's a good list of mods that will work, with tinkering:
- The Mega Map Campaign Mod. This will work if you don't include the changes to the System folder. The maps themselves will work in an All Missions campaign without further modding.
- SWAT 4: Remake. The weapons can be merged into SEF, but this requires some modding knowledge. They have a guide somewhere about merging the two mods.
- Any kind of custom weapon model mod, like Brettskie's M4 mod. Again, this will require some modding knowledge but it's possible to merge them.

Here's a good list of mods that won't work, even with tinkering:
- Any kind of code mod (11-99 enhancement mod, SSF, ...)
- SAS mod; the weapons from that mod are included with SEF though.
- Speech Recognition Improvement; the Speech Recognition feature is available but not all of the commands from that mod are present.

## ARE THERE MORE MISSIONS FOR EXTRA MISSIONS COMING OUT?
Yes! There are two more confirmed missions in Extra Missions: Brewer County Courthouse and Enverstar Power Plant. On top of that, we are gathering suggestions for custom maps.


# KNOWN ISSUES #
  * Yes, the game is HARD AS NAILS. It's supposed to be. It's a police simulator and meant to train SWAT operators.
  * If you're missing equipment in Singleplayer, note that you need to unlock it first.
  * Not working when you launch the .bat? The whole SEF folder is supposed to be copied to your SWAT 4 folder. Please review the HOW TO INSTALL section.
  * You cannot select Barricaded Suspects, VIP Escort or Rapid Deployment. Intentional! This mod is only meant for CO-OP play and we don't balance the equipment to suit those modes.
  * TOC won't reply when an AI-controlled officer reports something. There's lots of code that needs to be altered to make this work.
  * Seems to crash in specific circumstances on doors, such as trying to blow a door that's currently being closed. Not sure if it's an original game bug.
  * Sometimes crashes with a RotateActorAction, for reasons that aren't known.
  * Officers sometimes won't shoot suspects if they're very close to them. It's a problem in the original game as well.
  * Officers sometimes ignore orders, you might have to issue a command two or three times. Problem of the original game.
  * Officers sometimes ignore orders and say something like "I'm busy." This is a problem of the original game; they sometimes can see suspects where the player can't.
  * Throws an assertion when an officer ordered to restrain a civilian is ordered to disarm a bomb. Nothing I've changed would've caused it, so again, probably an issue with the original game. Also harmless.
  * MULTIPLAYER: "gui_tex package version mismatch" --> Make sure you are running under International language. Sometimes it defaults itself to English or some other language. Search for `Language=eng` or `Language=grm` in SEF/System/Swat4x.ini and make sure it's set to `Language=int`

# OTHER MINOR CHANGES #

## GAMEPLAY ##
  * Maps may now alter themselves based on difficulty level, for instance adding more suspects or traps in Elite difficulty. Only a few maps use this feature currently.
  * "Press ESC and debrief to exit the game" now shows on ALL missions, not just Food Wall, Fairfax Residence and Qwik Fuel.
  * In multiplayer, you can now unready yourself.
  * Fixed an exploit that allowed player to access early campaign unlocks by saving a loadout and then reloading it in another campaign.
  * You can now lock doors using the toolkit. Suspects cannot flee as easily through locked doors (they need to unlock them first)
  * The toolkit interface no longer shows up for doors that cannot be locked
  * Tasing your fellow officer and tripping traps now incurs a penalty
  * Tweaked limb damage slightly. JHP does more "expansion" damage to account for drag.
  * Incapacitation occurs at 30 health instead of 20.
  * Using your Shout button on a restrained suspect will taunt them. Examples include "You have the right to remain silent," etc. Doesn't do anything, it's just an easter egg. Warning: The suspect may have some unkind words for you in return.
  * Likewise, this works on restrained civilians as well. "It'll be okay," etc.
  * Suspects now have a slight delay when firing upon the player.
  * (Non-Insane/Non-Polite) suspects take twice as long before shooting hostages
  * Added a new quality: Polite. Any suspect archetype with this quality won't attempt to shoot hostages.
  * Added a new quality: Insane. Any suspect archetype with this quality will shoot hostages *much* faster (basically instantly) and ignores distance checks.

### Score ###

#### BONUSES ####
- Mission Completed: Awarded when all of the mission objectives are completed. 
 * Points: 40
- Suspects Arrested: Bonus based on the number of suspects secured. 
 * Points: (Number of suspects arrested)/(Total Number of suspects) x 20.
- Suspects Incapacitated: Bonus based on the number of suspects incapacitated and secured. 
 * Points: (Number of suspects arrested)/(Total Number of suspects) x 13 (65% of 20).
- Suspects Neutralized: Bonus based on the number of suspects neutralized. 
 * Points: (Number of suspects arrested)/(Total Number of suspects) x 4 (20% of 20).
- All Civilians Unharmed: Bonus based on the number of civilians that have been uninjured, and not DOA.
 * Points: (Number of civilians unharmed)/(Total number of civilians) x 10
- No Officers Downed: Bonus based on the number of incapacitated officers. 
 * Points: 10 - ((Number of downed officers)/(Total Number of officers) x 10).
- Player Uninjured: Bonus based on the number of players that sustained no injuries during a mission. 
 * Points: 5 - ((Number of injured players)/(Total Number of players) x 5).
- Report Status to TOC: Bonus based on the number of reports to TOC. 
 * Points: (Number of reports made)/(Total Number of reportable characters) x 10.
- All Evidence Secured: Bonus based on the number of evidence collected. 
 * Points: (Number of evidence collected)/(Total Number of evidence) x 5.

#### PENALTIES: ####
- Unauthorized use of Force: Given when the team incapacitates a suspect, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -5 per suspect.
- Unauthorized use of Deadly Force: Given when the team kills a suspect, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -20 per suspect.
- Incapacitated a Hostage: Given when the team incapacitates a hostage, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -20 per hostage.
- Killed a Hostage: Given when the team kills a hostage, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. The death of a hostage results in failure of the mission. 
 * Points: -50 per hostage.
- Injured a fellow officer: Given when an officer wounds another officer, be it by gunfire or sniper fire. 
 * Points: -10 per officer.
- Incapacitated a fellow officer: Given when an officer incapacitates another officer, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. Other officers may turn on the incapacitator. 
 * Points: -25 per officer.
- Tased a fellow officer: Given when an officer uses a taser another officer. 
 * Points: -5 per infraction.
- Triggered a Trap: Given when an officer opens a door with an alarm or booby trap attached to it. 
 * Points: -10 per trap.
- Failed to apprehend fleeing suspect: Given when a suspect escapes the perimeter of the mission area. 
 * Points: -5 per suspect.
- Failed to report a downed officer: Given when a downed officer is not reported to TOC: 
 * Points: -5 per downed officer
- Failed to report a downed suspect: Given when a downed suspect is not reported to TOC: 
 * Points: -5 per downed suspect
- Failed to report a downed hostage: Given when a downed or DOA hostage is not reported to TOC: 
 * Points: -5 per downed hostage

## GUI ##
  * Training mission returns! New Features from the Expansion are gone.
  * "Disable Initial Dispatch" option in Audio Settings lets you skip the initial dispatches.
  * "Mouse Smoothing" checkbox in Control Settings enables (default) or disables mouse smoothing.
  * "Field of Vision" slider in Video Settings lets you change the field of vision.
  * Maps in the Voting screen are now sorted alphabetically.
  * Host Game no longer precaches all of the maps at once; it goes to the menu and loads the maps while in the menu.
  * Added Advanced Information tab to Equipment Panel. It now shows a weapon's manufacturer, manufacturer country, date manufactured, caliber, magazine size, maximum ammo carried, muzzle velocity and firing modes. It also shows advanced information for protective equipment.
  * Weapons are now selected by dropdown menus, for faster selection
  * New splash screen
  * More advanced console. It will now show output of commands, and a console log. You need to press ESC to close the console now.
  * Added 'Take Screenshot' and 'Toggle Speech Interface' key to Controls menu.
  * Fixed an exploit that allowed the player to get unlocks early by saving a loadout with unlocked equipment and loading it later
  * New main menu logo
  * All evidence of Gamespy scrubbed
  * Cleaned up appearance throughout
  * You can now Un-Ready yourself in CO-OP games. You can only edit your equipment when you are not ready.
  * OUT OF THE WAY now the default for General MP menu.
  * Support in the menu for 5x as many resolutions, including many widescreen resolutions
  * You no longer need a CD-key to publish a game to the Internet server browser.


## EQUIPMENT ##
All weapons have been changed to have correct muzzle velocities.
* Grenade Launcher:
	- Given real world name (HK69)
	- Greatly increased damage dealt from direct impact
	- May now be equipped as a secondary weapon
* AK47 Machinegun:
	- New ammo types: AP, JSP
	- Fixed inaccurate description
	- Fixed name (AKM)
* GB36s:
	- New ammo types: AP, JSP
	- Corrected wrong name (is now G36C)
	- Updated description
* 5.56mm Light Machine Gun
	- New ammo type: JSP
	- Corrected wrong name (is now M249 SAW)
	- Burst fire removed
	- Corrected wrong looking first person
* 5.7x28mm Submachine Gun
	- New ammo types: AP, JSP
	- Corrected wrong name (is now P90)
	- Completely redid the description
	- Burst fire removed
	- Corrected wrong looking first person
* Gal Sub-machinegun
	- New ammo types: AP, JSP
	- Corrected wrong name (is now Silenced Uzi)
	- Updated description
	- May now be equipped as a secondary weapon
* 9mm SMG
	- New ammo types: AP, JSP
	- Corrected wrong names (MP5A2 and Silenced MP5A2)
	- Added automatic firing mode
	- Updated description
	- Fixed incorrect magazine size for FMJ (holds 30 rounds, not 25)
* .45 SMG
	- New ammo types: AP, JSP
	- Given real world name (UMP)
	- Updated description
	- 2-round burst mode added
* M1911 Handgun
	- New ammo types: AP, JSP
	- May now be equipped as a Primary Weapon
* 9mm Handgun
	- New ammo types: AP, JSP
	- Corrected wrong name (Glock 17)
	- May now be equipped as a Primary Weapon
* Mark 19 Semi-Automatic Pistol
	- New ammo type: JSP
	- Corrected wrong name (Desert Eagle)
	- Fixed typo in description
	- May now be equipped as a Primary Weapon
* 9mm Machine Pistol
	- Corrected wrong name (TEC-DC9)
	- Completely redid the description
	- May now be equipped as a Primary Weapon
	- Fixed broken reload sound
* TASER Stun Gun:
	- Cut TASER stun gun probe spread by 50%
	- Changed the name (TASER M26C Stun Gun)
	- Doubled the range (The M26C and its sister weapon have cartridge variations that can fire up to 35 feet)
	- Has a chance to incapacitate or even KILL hostages if not used correctly. Avoid use on the elderly, drug-users and people with health conditions.
	- Fixed typo in description
	- May now be equipped as a Primary Weapon
* Cobra Stun Gun:
	- Changed the name (TASER C2 Series Stun Gun)
	- Changed the description
	- Reduced the range (The C2 series can only fire up to 15 feet)
		This is good for balance too!
	- Like the TASER stun gun, the Cobra stun gun has a chance to incapacitate or kill hostages.
		The double fire mode doesn't increase the chance of cardiac arrest, but it does increase lethality. Use caution.
	- May now be equipped as a Primary Weapon
* Colt Python:
	- New ammo types: AP, JSP
	- Unlockable in Singleplayer
	- May now be equipped as a Primary Weapon
* Sting Grenade:
	- Doubled the range and vastly increased damage to be more realistic
	- All equipment that reduces the effect of sting grenades in MP also works in singleplayer
	- Can detonate pipe bombs, oxygen tanks, and gas cans
* Flashbang:
	- Increased the damage and radius to be more realistic
	- Can detonate pipe bombs, oxygen tanks, and gas cans
* CS Gas:
	- Increased area of effect
	- Reduced morale modification
	- Can affect the player in singleplayer.
* Helmet:
	- Renamed to Tactical Helmet
	- Provides protection against flashbangs in singleplayer
* C2:
	- Increased the damage radius, stun angle and stun radius. It is riskier to use C2.
* Pepperball Gun:
	- May now be equipped as a Secondary Weapon
	- Less effective in general now
* Less Lethal Shotgun:
	- Now called the Less Lethal Nova
	- Can incapacitate or kill subjects at point blank range
* M4Super90:
	- Now fires in a spread that isn't dictated by crosshair accuracy
	- May now be equipped as a Secondary Weapon
	- Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
	- Corrected magazine size (5 -> 7). SWAT 4 uses the magazine size from a civilian version of the shotgun. The Law Enforcement and Military models have 7 round magazines.
* Nova Pump:
	- Now fires in a spread that isn't dictated by crosshair accuracy
	- Corrected invalid magazine size (8 -> 7)
	- Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
* Added two new head armor items:
	- Riot Helmet: Offers slightly less protection than the Helmet, but also reduces Pepper Spray and Gas durations
	- ProArmor Helmet: Offers highest possible protection, but confers no other bonuses.
* Added new weapons (from SAS mod):
	- ARWEN 37: Dedicated grenade launcher with flashlight and 5-round magazine.
	- SG552 Commando: Versatile assault rifle (including a silenced version)
	- HK33: Heavy-duty assault rifle (including a marksman version)
	- M16: The original assault rifle. Only available in Multiplayer (including a silenced version)
	- MP5SSD6: A silenced-only version of the MP5 with a better suppressor.
	- MP5K: A more tactical machine pistol
	- Browning Hi-Power: Higher-powered 9mm pistol (including a silenced version)
	- P226: A well-rounded 9mm pistol
	- Remington M870 Shotgun: Shortened shotgun that can be equipped as primary or secondary weapon
* Added new weapons (exclusive to this mod):
	- Less Lethal M870: Beanbag shotgun available as a secondary.
* Ammo Pouch:
	- Removed.

## MISSION CHANGES ##
WARNING: This section contains spoilers
Missions are listed in order that they occur
Morale has been modified across the board.
If an equipment is not listed as unlocked by a mission, it is unlocked by default.

* Fairfax Residence
	- CAUTION! May contain traps! (Evidence shows that they were cut from the original game on this mission)
	- ELITE Difficulty: Always spawns a trap and the accomplice.
	- Restored a cut conversation between Lead and TOC that triggers when tripping a trap
	- Restored a cut conversation between Lead and TOC that triggers when arresting the accomplice
	- Restored a cut conversation between Jackson and Fields 
	- Gladys Fairfax is Fearless
	- Gladys Fairfax has a chance to die from the taser
	- Melinda Kline has a very small chance to die from the taser
	- Corrected typo in mission briefing location info ("Information is specualtive regarding the basement." -> "Information is speculative regarding the basement.")
	- Does not unlock any equipment
* Food Wall Restaurant
	- The armed waiter is Polite
	- All patrons are Fearless
	- Corrected typo in mission briefing timeline ("Alex Jimenez is observed entering Food Wall Restauraunt" -> "Alex Jimenez is observed entering Food Wall Restaurant")
	- Unlocks the TASER stun gun (X26)
* Qwik Fuel Convenience Store
	- There are sometimes drugs on the map that need to be found (hint: look in bathrooms)
	- The suspects on this mission may be carrying drug evidence.
	- Alice Jenkins is Insane and has a moderate chance (50%) to die from a taser
	- The other suspects have a decent chance (35%) to die from a taser
	- Made loading screen text consistent with other missions ("3721 Pitkin Avenue, Qwik Fuel" -> "3721 Pitkin Ave., Qwik Fuel")
	- Unlocks the Remington M870 Shotgun
* FunTime Amusements
	- A penalty is no longer issued when suspects flush drugs
	- Drug flushers are Polite
	- Corrected missing loading screen text ("1401 Gower St., FunTime Amusement Arcade")
	- Corrected a typo in briefing description
	- Fixed loading screen text not being present
	- Unlocks the Gas Mask
* Victory Imports Auto Garage
	- Made loading screen text consistent with other missions ("487 29th Avenue, Victory Imports" -> "487 29th Ave., Victory Imports")
	- Unlocks the Less Lethal Nova and the Less Lethal M870
* Our Sisters of Mercy Hostel
	- Restored a cut conversation between Lead and TOC that triggers upon rescuing some of the civilians.
	- Restored a cut conversation between Lead and TOC that triggers upon eliminating certain suspects.
	- Both entryway doors now correctly have MAKE ENTRY commands on them.
	- Locked a bunch of doors
	- The residents (elderly) have a very high chance of dying from a taser
	- Removed objective: Rescue Lionel McArthur
	- Fixed a bug with the suspects where they were holding the wrong weapon (code calls for M249 SAW, actual model displayed is M4 Carbine, and behavior makes sense in this context)
	- Made loading screen text consistent with other missions ("Our Sisters of Mercy Halfway House, 796 Newbury St." -> "796 Newbury St., Our Sisters of Mercy")
	- Unlocks the Pepperball Gun and the Suppressed Browning Hi-Power
* A-Bomb Nightclub
	- There are sometimes drugs on the map that need to be found (hint: look in bathrooms)
	- The alley entry door now correctly has MAKE ENTRY commands on it.
	- Unlocks the Riot Helmet
* Northside Vending and Amusements
	- CAUTION! May contain traps.
	- Restored a cut conversation between Lead and TOC upon tripping a trap
	- Restored a cut conversation where Red Two would muse about how much money the laundromat was making
	- Some doors were opened that are now closed. Likewise, some doors that were closed by default are now open.
	- Fixed a bug where the front door had MAKE ENTRY commands on the wrong side (unless you want to MAKE ENTRY into an alleyway..?)
	- The laundromat door now has MAKE ENTRY commands assigned to it (since you are entering the laundromat, after all)
	- Louis Baccus is Fearless
	- All suspects are Polite
	- Made loading screen text consistent with other missions ("1092 Westfield Road, Northside Vending" -> "1092 Westfield Rd., Northside Vending and Amusements")
	- Unlocks the FN P90 PDW
* Red Library Offices
	- Made loading screen text consistent with other missions ("732 Gridley Street, Red Library Inc." -> "732 Gridley St., Red Library Inc.")
	- Unlocks the Colt Accurized Rifle
* Seller's Street Auditorium
	- All of the static drug bags were removed. They have been replaced with drug evidence which can be collected.
	- Andrew Norman is Insane and has a very small chance to die from the taser
	- Made loading screen text consistent with other missions ("The Sellers Street Auditorium, 1801 Sellers St" -> "1801 Sellers St., The Sellers Street Auditorium")
	- Unlocks the UMP 45 and the MP5SSD6
* DuPlessi Wholesale Diamonds
	- No changes
	- Unlocks the Grenade Launcher
* Children of Taronne Tenement
	- CAUTION! May contain traps.
	- All civilians are Fearless
	- Andrew Taronne is Polite
	- All civilians have a very small chance to die from the taser
	- All suspects (except Andrew Taronne) have a very small chance to die from the taser
	- Made loading screen text consistent with other missions ("2189 Carrols Road, Taronne Tenement" -> "2189 Carrols Rd., Taronne Tenement")
	- Unlocks Night Vision Goggles
* Department of Agriculture
	- Restored cut conversation between Lead and TOC where TOC says how many bombs are present (kind of important, don't you think?)
	- Made loading screen text consistent with other missions ("Government Plaza, Offices of the Department of Agriculture, 2112 Geddy Avenue" -> "2112 Geddy Ave., The Department of Agriculture")
	- Unlocks the SG552 Commando and the Suppressed SG552 Commando
* St. Micheal's Medical Center
	- The Terrorists are Insane
	- Hyun-Jun Park's Security Detail are Polite and will -never- attack
	- Corrected various inconsistencies in the mission strings (It's referred to as "Memorial Hospital" in the location info, and simply "St. Micheal's" in the loading screen, but "St. Micheal's Medical Center" in the voiceover)
	- Unlocks the P226 and the Suppressed P226 pistols
* The Wolcott Projects
	- The homeless are Fearless
	- The homeless have a very small chance to die from the taser
	- The loading screen and dispatch are inconsistent. Dispatch says "1210 Canopy Road" while the loading screen and mission text say "Blakestone Avenue". Corrected the text to use the Canopy Road address instead.
	- Unlocks the ProArmor Helmet
* Stetchkov Drug Lab
	- CAUTION! May contain traps!
	- Cut content restored: Conversation where Fields makes a sarcastic remark about this stuff "making your balls shrink"
	- Cut content restored: Conversation where the team talks about the smell of the place
	- All of the static drug bags were removed. They have been replaced with drug evidence that can be collected.
	- All of the external doors now correctly have MAKE ENTRY commands on them.
	- Locked a bunch of doors
	- The civilians are Fearless
	- The civilians have a very small chance to die from the taser
	- The suspects are Polite
	- Made loading screen text consistent with other missions ("Stetchkov Drug Lab, 653 Tovanen St." -> "653 Tovanen St., Stetchkov Drug Lab")
	- Unlocks the Taser C2 Series Stun Gun
* Fresnal St. Station
	- Cut content restored: Conversation where Lead tells TOC they found Officer Wilkins
	- The elderly have a chance to die from the taser
	- Fixed typos in briefing timeline ("First Units Arive" -> "First Units Arrive"; "First units arive and perimeter established" -> "First units arrive and perimeter established")
	- Unlocks the HK33 and the Scoped HK33 rifles
* Stetchkov Warehouse
	- CAUTION! May contain traps!
	- All of the external doors now correctly have MAKE ENTRY commands on them.
	- Locked a door
	- The civilians are Fearless
	- The suspects are Polite
	- Made loading screen text consistent with other missions ("The Stetchkov Warehouse, 2770 Harrington Rd." -> "2770 Harrington Rd., The Stetchkov Warehouse")
	- Unlocks the ARWEN37 grenade launcher and the Colt Python pistol
* Old Granite Hotel
	- Cut content restored: Conversation where Jackson says "The bomb squad missed all the fun."
	- Cut content restored: Lines for when the player disables bombs.
	- Fixed wrong snipers. Sierra 1 was where Sierra 2 is supposed to be, and vice versa.
	- Unlocks the MP5K Machine Pistol
* Mt. Threshold Research Center
	- The suspects are Insane
	- Fixed a massive oversight (?) where the developers gave the suspects on this mission 9x more morale than they're supposed to.
	- Does not unlock equipment. Use all of your acquired technology!

# HOW TO PLAY IN MULTIPLAYER #

## Using GameRanger (preferred) ##
BOTH PLAYERS will need to do the following:
Download and install GameRanger. It can be found at http://gameranger.com
Next, GameRanger will automatically detect SWAT 4 and SWAT 4: The Stetchkov Syndicate, if all is OK.
You may need to manually detect these, if GameRanger doesn't do it for you.
Then, you will need to modify the Stetchkov Syndicate game in Gameranger so it points to the LaunchSEF.exe file in SEF/Extras/LaunchSEF.exe.

THE HOST will need to do the following:
Create a game room, as a SWAT 4: The Stetchkov Syndicate game. (TIP: if this is going to be a publicly joinable game, be sure to mention it's using the SEF mod and specify the version!)
When enough players have joined, press the Start Game button. This will launch the game. From here, go to the Host Game menu and start up a server.
Important Note: Do not launch as a dedicated server while using GameRanger.
The other players will automatically connect to your game while you are loading the map.

THE CLIENT will need to do the following:
Join a public game, or your friend's game. That's all you really need to do.


## Traditional Method (TCP/IP) ##
SWAT: Elite Force v4 was the first version of this mod to allow for multiplayer play. v5 introduced Campaign CO-OP and allowed for publishing of games to Swat4Stats without a CD-key (removing DRM that GOG didn't).

If you want to join a game:
If the game you want is not hosted via LAN, then you will need the SWAT4Stats server browser plugin. It's available at http://swat4stats.com - make sure you get the TSS version. 
After it is installed, your server list will show all of the servers, including the ones that are on different mods. Just join the one you want. There are a number of 24/7 SEF servers out there.
If the game you want is hosted via LAN, or you cannot find the server in the list, you will need the host's external IP address (have the host look this up on http://myexternalip.com). You can then join the game from the Join Game menu using the IP address.

If you want to host a game:
First, you will need to open some ports on your router: 10480 - 10483, TCP/UDP. If you aren't sure how to do this, the following article explains it well: https://www.howtogeek.com/66214/how-to-forward-ports-on-your-router/
OPTIONAL: If you want your game to be publicly visible on the master server list (on swat4stats), you will need to install the Swat4Stats server browser plugin, available at http://swat4stats.com - You'll also want to set your game to be "Internet" and not "LAN" for this to work.
If you aren't playing an Internet/Swat4Stats enabled game, you will need your external IP address for other players to connect. You can look this up on http://myexternalip.com
Lastly, you need to determine what type of game you want to play. Regular CO-OP is handled through the Host Game menu ingame, but Campaign CO-OP is done through the Career menu - select a campaign and hit Career CO-OP. The "Equipment" panel will change to a "Settings" panel where you can configure a password, etc just like in Host Game.
Once you have selected your map settings and have started the server at least once, you can quickly launch a server (without going ingame) by using the Dedicated Server.bat file. You can then join the server from the Join Server menu.

# VERSION HISTORY #

### v5.3 ###
Special thanks to kevinfoley, who made a lot of changes here. His contributions are marked with [kf]

- Rewrote SpeechCommands grammar file from scratch (see SpeechCommands.md for changes) (kevinfoley helped with this)
- Added missing speech commands from v5 (for specifying breaching method)
- Minor optimizations regarding the optiwand
- Snipers now report when they've lost sight of entry team on all maps, not just Qwik Fuel (they only do this once)
- Another possible fix for the RotateAroundActor crash
- Improved the quality of shadows on the highest Shadow Quality setting. [kf]
- On the highest Shadow Quality setting, more things (such as AI-controlled officers, guns, etc) will cast shadows [kf]
- Cut content restored: Blood spray texture that was not used [kf]
- Fixed SEF bug: Sniper rifle not firing in multiplayer
- Fixed SEF bug: Breaking a door with the breaching shotgun (in a dedicated server/multiplayer) would sometimes not disable the antiportal
- Fixed SEF bug: Officers were reporting that they lost their contact way too often [kf]
- Fixed SEF bug: Missions not sorted alphabetically sometimes in an All Missions campaign
- Fixed TSS bug: Doors broken with shotgun by AI would have a delay before they appeared broken to the player - this is fixed. [kf]
- Fixed TSS bug: Officers don't reply when ordered to cover an area, they just do it

### v5.2 ###
- Fixed a very frequent crash in multiplayer that was introduced in 5.1
- Corrected glitches in the grenade animations which appeared at high FOVs
- Tweaked the speed of the surrender animation so it plays slower (thanks to kevinfoley for this change)


### v5.1 ###

#### MAIN CHANGES
- Some additional improvements to speech commands (thanks to kevinfoley for these changes):
  * You can now report things to TOC using your voice!
  * Improved the speech commands with CS gas
  * A new SpeechCommands.md file has been provided which lists all the things you can say to trigger voice commands.
- Adjusted the weapon accuracies (see Weapon Changes for more information)
- Reduced the drag of beanbag ammo by 25% so it can hit more distant targets
- AI will now wait before entering a room after a gas grenade goes off. The amount of time depends on what equipment your officers have equipped. (thanks to kevinfoley for this change)
- Halved the melee range (170 -> 85)
- Reduced the damage done by torso shots against all targets
- Increased the damage done by 9mm AP and .223 ammunition
- Suspects have a chance to drop their weapon immediately upon surrendering, making it less likely to shoot them accidentally
- Added a "grace period" to compliance. If a suspect becomes compliant and you accidentally shoot them within a moment of their surrender, no penalty is ensued.
- Restored cut dialogue: Officers will report when they've lost sight of a suspect.
- Fixed SEF bug: Investigating enemies were considered threats (for the purposes of penalties and officer AI)
- Fixed SEF bug: Fleeing suspects who were attacking were *not* considered threats (for the purposes of penalties and officer AI)
- Fixed SEF bug: Rare glitch where SWAT AI could shoot hostages intentionally
- Fixed SEF bug: The AI could "miss" and not break a door with the breaching shotgun. They will now fire up to two times, and if they miss both times, the door will break on its own.
- Fixed SEF bug: Colt Accurized Rifle, HK69, HK33, M16A1, AKM, G36C and Commando Rifle had wrong animations for AI-controlled officers
- Fixed SEF bug: M16A1 had 30 round magazine for JSP and JHP ammo and 20 round magazine for others (now it's 20 rounds for all)
- Fixed SEF bug: Manager on Meat Barn had a ridiculously high amount of morale (3.0)
- Fixed TSS/SEF bug: Suspects could be "juked" by running in a circle around them and/or spamming crouch, which would foil their AI and prevent them from firing. This was more pronounced in SEF since enemies take longer to fire their weapon.
- Fixed TSS bug: Punching a restrained suspect would make them stand up.
- Fixed TSS bug: Punching while changing weapons (or when finishing an arrest) would cause weird bugs, including turning your weapon invisible and going into a T-pose
- Fixed TSS bug: Compliant/arrested "Wild Gunner" AIs (the kind with M249 SAWs) would be sweeping back and forth still, which looked odd (they still do this while they are stunned, but it'll require some reorganization of the code to fix this properly)

#### WEAPON CHANGES
All weapons have been adjusted again, to reflect more realistically their weight. The general changes for the weapons are:
-Pistols: Increased recovery speed.
-SMGs: Increased recovery speed, with some exceptions:
	-Suppressed UZI: Reduced recovery speed.
	-MP5SD6: Reduced recovery speed.
	-Suppressed MP5K: Adjusted accuracy, recoil and recovery stats.
	-Suppressed MP5A4: Reduced recovery speed.
	-UMP: Reduced recovery speed.
-Rifles: Increased recovery speed, with some exceptions.
	-M16A1 and Suppressed M16A1: Reduced recovery speed.
	-HK33A2: Reduced recovery speed.
	-Scoped HK33A2: Reduced recovery speed. Increased zoom.
	-Suppressed Accurized: Reduced recovery speed.
-Shotguns: Reduced recovery speed, with some exceptions.
	-Remington M870, Less Lethal and Breaching Variants: Increased recovery speed.
-Grenade Launchers:
	-HK69: Reduced recovery speed.
	-ARWEN 37: Increased recovery speed.
-Other weapons:
	-M249 SAW: Reduced recovery speed.
	-Pepperball Launcher: Increased recovery speed.
	-Taser X26P and X2: Increased recovery speed.

### v5 ###

#### MAJOR FEATURES ####
- Campaign Co-op!
  * You can now play any campaign in multiplayer. Beating missions in campaign co-op advances your singleplayer career. You will need to unlock equipment, just like in singleplayer, and there is a score requirement to win.
  * Simply select a previously created campaign from the menu and hit the CAREER CO-OP button to begin.
  * Some campaigns cannot be played in co-op (see below for restrictions)
- Permadeath!
  * AI Permadeath option will kill your AI officers permanently when they die.
  * Player permadeath option will instantly end your campaign permanently when you die.
  * Campaigns with permadeath options enabled cannot be played in Campaign co-op.
- All Missions campaign!
  * There is a new campaign path, titled All Missions. This includes every map you have on your hard drive, including customs, so you can play them in singleplayer.
  * All Missions campaigns cannot be played in Campaign co-op.
- AI improvements!
  * Officers can now take cover while engaging suspects, and may lean or crouch while doing so.
  * Suspects and civilians can now wander all over the map (this depends on the map mostly)
  * A lot of cut speech got restored.
- Equipment changes!
  * The SAS mod has generously allowed us to use some of their weapons in the mod. See the SAS weapons section for more details.
  * New rifle/pistol ammo types: JSP (jacketed soft point) and AP (armor penetrating).
  * New shotgun ammo types: 0 buck, 1 buck, 4 buck
  * The weapon handling (accuracy) received significant changes
- Breaching improvements
  * All shotguns can now breach through doors. The Breaching Shotgun can break through any door with one shot, but other shotguns (particularly when dealing with metal doors) may take two or three shots to break open. (AI-controlled officers cannot breach with anything other than a Breaching Shotgun)
  * Broken doors can now be closed and/or wedged.
  * C2 can now blow up alarm traps on the other side of a door, preventing them from going off.
  * You can now tell the officers which breaching method you want them to use on a door (C2 & CLEAR vs SHOTGUN & CLEAR)
- DOA conversions
  * Hostages who start out as incapacitated may become a DOA after 10-15 minutes. 
  * Allowing hostages to become DOA may reduce your score.
  * This is an incentive to complete the mission quickly.

#### MINOR/ALL CHANGES ####
- Publishing Multiplayer games to Internet no longer requires a CD-key.
- Added campaign co-op
- Added SAS weapons
- Added Less Lethal Remington M870 (Less Lethal version of an SAS weapon)
- Added JSP, AP, 0 buck, 1 buck, 4 buck ammo types
- Added player permadeath option
- Added officer permadeath option
- Added custom voice acting (by GrimithM) to Adam Moretti so he actually speaks now
- Civilians who are incapacitated at the start of the level can now become DOA after 10-15 minutes. Allowing a hostage to become DOA will have a negative effect on your score.
- Officers may now take cover and crouch
- Doors breached with the shotgun are not "swung open." Only C2 can "blast a door open."
- Broken doors can now be closed and wedged
- Shotguns (except ones that fire beanbags) no longer show the Pick Lock or Deploy C2 fire interfaces - firing will try to blast open the door instead.
- C2 can now break door alarms
- The equipment menu has been changed to use dropdown boxes for the weapon and ammo types. It has a category system to pick weapons easier.
- Added advanced information panel to Armor equipment tab - it shows armor rating and what special protection the armor provides.
- Added campaign statistics information to Campaign Selection menu
- Completely redid the New Equipment menu to look better and handle two unlocks at the same time
- Suspects can now employ a "wandering" behavior that allows them to pick patrol points randomly.
- Snipers can now be used in multiplayer. All players can view the sniper viewport but only Leaders can control them.
- Suspect equipment is only available in Multiplayer and All Missions campaigns now
- Issuing a FALL IN command will now have the officers reload their weapons automatically
- Added new voting configuration options for server hosts: TiesWin, CallCastVote, MinVoters, and NonVotersAreNo. You can edit them in Swat4x.ini/Swat4xDedicatedServer.ini. See Default.ini for more information.
- Taunt feature now differentiates between belligerent and passive hostages
- At the end of a multiplayer game, the next map is listed just above the Ready button
- Mission Completed accounts for 40 points in the score, instead of 45.
- No civilians injured bonus removed, replaced with All Civilians Uninjured which awards points based on the number of civilians that were rescued unharmed. This counts towards 10 points instead of 5.
- The MP viewport binds now function identical to the singleplayer ones, instead of all the viewport binds doing the same thing.
- You can now see the viewports of the other team in CO-OP.
- Clarified some text in the Training mission
- Added an icon to the Riot Helmet
- Added an icon to the ProArmor Helmet
- Adjusted the positions of some drug evidence in Sellers Street Auditorium so that it doesn't fall through the floor as easily.
- Armed, Insane suspects are now considered threats *at all times* after having been shouted at, even if they are running - they could be running to shoot hostages
- The language now defaults to International (int) instead of English (eng) to prevent issues with gui_tex version mismatch in multiplayer.
- Cut dialogue restored: Suspects will now mourn the death of their fellow suspects
- Cut dialogue restored: Suspects will now apologize when shooting each other
- Cut dialogue restored: Hostages will now freak out when other hostages die
- Cut dialogue restored: Officers will now correctly report when they do not have grenade launcher ammo
- Cut dialogue restored: Officers will now report when they are using grenades
- Cut dialogue restored: Officers will now report when they are using pepper spray, less lethal shotgun, or grenade launcher
- Fixed SEF bug: SWAT officers using full auto; suspects not using full auto
- Fixed SEF bug: Handcuffs not playing sound properly and popping back up during use
- Fixed SEF bug: Civilians can trigger traps
- Fixed SEF bug: Manager on Meat Barn having glasses on backwards (special thanks to sandman332 for this fix)
- Fixed SEF bug: Bullets that lose all of their momentum due to drag cause bleeding/impact effects
- Fixed SEF bug: Less Lethal Shotgun, Grenade Launcher causing penalties when it's not supposed to
- Fixed SEF bug: Log being spammed with messages about trap penalties
- Fixed SEF bug: Log being spammed with "Fast trace blocked!"
- Fixed SEF bug: AI-controlled officers not shouting for compliance correctly in some situations
- Fixed SEF bug: CS gas turning black in some situations
- Fixed SEF bug: Officers not spawning with any equipment in the Training mission
- Fixed SEF bug: Briefcase on Mt. Threshold Research Center sometimes falling through the floor
- Fixed SEF bug: Adam Moretti (Meat Barn enemy) appears as "Simon Gowan" in the subtitles
- Fixed SEF bug: Suspects or civilians who had become incapacitated, reported, and then died later counted towards the "Failed to report downed Civilian/Suspect" penalty.
- Fixed TSS bug: M249 SAW, P90 and TEC-9 making the same sound effect as the MP5 when heard in third person.
- Fixed TSS bug: Night vision goggles alerting AIs. The idle hum sound effect can alert AIs from around corners etc
- Fixed TSS bug: Explosion effects (from gas cans, nitrogen cans etc) not alerting AIs
- Fixed TSS bug: Office workers on Department of Agriculture having broken morale levels (special thanks to sandman332 for this fix)
- Fixed TSS bug: P90 having bad first person position
- Fixed TSS bug: M249 SAW having bad first person position
- Fixed TSS bug: Colt Accurized Rifle doesn't have lowready animations in third person
- Fixed TSS bug: Grenade Launcher doesn't have lowready animations in first person
- Fixed TSS bug: Officers weren't animating correctly with the Colt Accurized Rifle or the P90
- Fixed TSS bug: AKM ammo types simply listed as "FMJ" or "JHP" instead of listing the caliber

#### SAS WEAPONS ####
The following weapons have been added from the SAS mod. All of them have a tactical flashlight.

- Browning Hi-Power
  * Pistol. Medium capacity 9mm pistol with decent stopping power.
  * Has a silenced variant.
- P226
  * Pistol. High capacity 9mm pistol with low stopping power.
  * Has a silenced variant.
- MP5K
  * Machine Pistol/SMG. 9mm, low accuracy and high recoil, but low weight and bulk. Comparable to the TEC-9.
  * Has a silenced variant.
- MP5SD6
  * SMG. 9mm, integrally suppressed. Quieter but weaker compared to the Suppressed MP5
- ARWEN 37 Grenade Launcher
  * Grenade Launcher. 5 round magazine, but it can only be equipped as a primary and it has high weight/bulk.
- M16A1
  * Assault Rifle. Better at range than the M4, but heavier.
  * Has a silenced variant.
  * Only available in Multiplayer CO-OP.
- HK33
  * Assault Rifle. Better at range than the G36C, but heavier.
  * Has a scoped variant.
- SG552 Commando
  * Carbine. Lightweight; comparable to the G36C.
  * Has a silenced variant.
- Remington 870
  * Lightweight, pump action shotgun. Wider spread than other shotguns.

### v4.1 ###
This is a hotfix patch to address some common issues that have been raised.
- The taunt feature has been improved significantly. You now have to be aiming at the target in order to taunt at them.
- The FOV slider no longer freezes the game, and resolution options should now save correctly. (Review the updated installation instructions if it does not work.) Navigating away from the Video Options menu will bring up a "Please Wait..." dialogue as it saves settings.
- Widescreen improvements; the GUI has been tweaked so that certain widescreen resolutions (mostly 16:9 ones) won't have disappearing elements in the GUI. Ultrawide is still unsupported at the moment and there might be a few issues I missed.
- Sellers St. Auditorium no longer displays the Colt Carbine text for New Equipment; it displays the UMP text correctly instead.
- Fixed an issue that caused magazine counts to "reset" themselves when switching away from a shotgun
- Speech Command Interface improvements:
  * Now distinguishes between "Mark with Lightstick" and "Drop Lightstick" properly
  * Added missing commands: SECURE EVIDENCE, RESTRAIN and all of the LEADER THROW commands.
  * Added a new keybind to the Key Config menu: Toggle Speech Commands. This button turns off/on the speech command interface; which is good for streamers.
  * You can now shout for compliance at civilians, suspects, etc using your voice. Try "Police!", "Put your hands up!", "Drop your weapons!" or for roleplay purposes, "Police! Search warrant!"
  * Commands involving "stinger" now use "sting" since this was often confused by the engine for "taser"
  * Various other misc improvements
- Fixed chat in multiplayer pregame having the wrong number of lines (thanks to KevinL and Sokol for this fix)
- Updated wedge description to explain the difference between using a wedge and locking a door.

### v4 ###

#### MAJOR FEATURES ####
- Introducing, Extra Missions! These are a second, Irrational-quality campaign of missions for you to explore.
  * You will need to create a second campaign (in the menu) and select Extra Missions from the dropdown box (SWAT4 + TSS are selected by default)
  * The first one, Meat Barn Restaurant, is an altered version of the multiplayer-exclusive Meat Barn Restaurant. Major changes were made to the layout to make it easier in Singleplayer and CO-OP.
- New system: Weight/Bulk. Instead of speed and use time being dictated by armor equipped, it's now based on two variables: Weight and Bulk.
  * There are two bars on the loadout screen to help visualize how much weight/bulk you have, along with the real values.
  * WEIGHT will slow you down. It is measured in kilograms, as a measure of how heavy things are.
  * BULK will make things take longer to use. It is a percentage ingame, with real measurements behind it - it is a measure of surface area of your gear.
  * Generally weight and bulk go in tandem, but there are some differences. The Desert Eagle is heavier than the Python, but the Python is more bulky.
- Weapons have been totally altered, both internally (how they function) and externally (how they play).
  * All weapons have reworked accuracy, recoil and handling characteristics using realistic weights and lenght for each. Light, shorter weapons like pistols and SMGs now suffer less penalties for movement and injuries, whereas long, heavier weapons like assault rifles and shotguns are more accurate and powerful.
  * The ammo bag tactical aid has been removed. Instead you can now customize the amount of ammo you want to bring, to fine-tune your weight and bulk.
  * Weapons have been given more realistic rates of fire and muzzle velocities. In terms of gameplay, higher muzzle velocity = more potential for penetration. Most weapons got reduced muzzle velocity, except for the P90, TEC-9 and UMP.
  * Bullets can now ricochet off of hard surfaces, such as concrete, stone, bricks, etc. Ricochets occur from FMJ and buckshot rounds. (This feature will be improved as more research is done)
  * All secondary weapons are available in primary weapon slots.
  * Heavy Armor now acts differently. It completely protects against conventional weapons, but may become damaged over time. At 0% health, it will only be as effective as Light Armor.
  * The Less Lethal shotgun is much more dangerous. Don't fire it at point blank range; give the beanbags some travel time, and don't aim for the head...
- New set of commands in singleplayer: LEADER THROW. These commands allow you to use a grenade instead of your AI companions.
  * For hold commands, when the INITIATE command is done, officers will blow/open the door, and will only enter after you use a grenade. Therefore, you only need one grenade for a double entry.
  * These commands work for both thrown grenades and the grenade launcher, and they're "one-command-fits all" (OPEN, LEADER & CLEAR accepts flashbangs, CS gas and sting grenades without needing to pick in the menu)
- Many changes to both the officer and suspect AI to make them both better.
- The console has been improved.
- Completely redid all of the campaign progression/unlocks.
- You can now lock doors using the toolkit.

#### MINOR FEATURES / FULL CHANGES ####
- Added Meat Barn Restaurant extra mission
- Fixed CO-OP and tested. It works now, honest! Although it will see some improvements.
- AI improvements: SWAT officers no longer stare down noncompliant civilians for days
- AI improvements: SWAT officers will no longer form "death funnels" as easily in doors - they will engage with suspects while moving through doors.
- AI improvements: Suspects are more likely to play a Get-Hit animation when they are injured and are less accurate in general
- AI improvements: Suspects will no longer shoot instantaneously at SWAT officers. There is a small delay, dependent on skill level.
- AI improvements: Suspects will now shoot at SWAT officers while on the move. The chance is dependent on the skill level of the suspect.
- Fixed TSS bug/AI Improvements: Known locked/wedged doors weren't being taken into account when a suspect evaluates if it should flee.
- Fixed TSS bug: Can save loadouts to work around the campaign unlocks (It will bring up a dialog box informing you that the loadout you want uses invalid equipment)
- Fixed TSS bug: Glitchy arrests with No Armor
- Fixed TSS bug: Optiwand glitchy in multiplayer when near doors (unverified)
- Fixed TSS bug: Pregame not showing HTML styling of server name
- Fixed TSS bug: Glock not selectable in Custom Mission Maker
- Fixed TSS bug: Taser recoil applying to every player on the map
- Fixed TSS bug: Server name field in Multiplayer Setup not matching the actual number of characters that could be used
- Fixed TSS bug: When using Deploy C2 command, AI will pick the lock if they are out of C2
- Fixed TSS bug: TEC-9 not having any reload sound effects
- Fixed TSS bug: Hologen suspects having ridiculously high morale at times
- Fixed SEF bug: Join Game button on menu not appearing
- Fixed SEF bug: Officers picking locks on unlocked doors when ordered to breach and out of C2
- Fixed SEF bug: Riot Helmet not protecting against pepper spray like it's supposed to.
- Fixed SEF bug: Sniper rifle not accurate
- Fixed SEF bug: Wrong resolution in options menu (1600x1050 -> 1680x1050)
- Fixed SEF bug: Wrong window title ("MyMod" -> "SWAT: Elite Force")
- Fixed SEF bug: Invisible traps in CO-OP
- Fixed SEF bug: Invisible drug bags in CO-OP
- Five new commands: LEADER THROW & CLEAR; OPEN, LEADER & CLEAR; OPEN, LEADER & MAKE ENTRY; BREACH, LEADER & CLEAR; BREACH, LEADER & MAKE ENTRY. These commands let you throw the grenade instead of the AI doing it.
- Equipment is now affected by Weight and Bulk. Weight, which represents how heavy your equipment is, slows your character down, and Bulk, which represents how large your equipment is, slows down your actions.
- The toolkit can now be used to lock doors.
- Added an FOV slider (Video Options) and a Mouse Smoothing checkbox (Controls Settings)
- The toolkit interface no longer shows up for doors that cannot be locked (e.g, all of the doors on St. Micheal's Medical Center)
- FMJ and buckshot can now ricochet off of hard surfaces
- Bullets are now affected by drag; they will lose momentum (and therefore lethality) over long distances. JHP is more susceptible to drag than FMJ rounds.
- Heavy Armor now has "health". It will protect against rifle rounds almost perfectly but will lose that ability with successive shots.
- JHP does slightly more bullet-expansion ("internal damage") damage to account for drag.
- Restored cut content: AI-controlled officers will now report when they spot a civilian
- Restored cut content: Suspects will now yell loudly as they shoot at doors
- Redid all of the campaign progression/unlocks
- Added "Take Screenshot" option to controls menu
- Minor changes to the compliance system (see the detailed section below for a full list of changes)
- Civilians are now not ridiculously noncompliant like they were before
- Incapacitation health increased from 20 to 30, so incapacitation is more likely
- All pistols are selectable in primary weapon slots.
- CO-OP damage modifier reduced (2.0x -> 1.5x, same as Elite difficulty) and Easy damage modifier increased (0.5x -> 1.0x, same as Normal difficulty)
- Ammo Bandolier item removed
- VIP Colt M1911 removed
- Officers get (by default) 3 primary magazines and 5 secondary magazines. The only exception is Jackson, who gets 25 shotgun shells.
- You can no longer edit your equipment in Multiplayer while you are ready. Unready yourself first.
- You can no longer ready in Multiplayer while your equipment is over weight or bulk.
- If your equipment is over weight in multiplayer, it will be replaced with the default loadout.
- Mapmakers now have the ability for Rosters (bombs/enemies/hostages/etc) to be based on difficulty level.
- The scoring system has been changed. There is no longer a bonus for no suspects incapacitated or killed. Elite difficulty now requires 90 instead of 95 score to complete.
- Moved a few strings from SwatProcedures.ini to SwatProcedures.int so they can be localized correctly
- The Host Game menu no longer loads all of the maps in one go. Instead, the menu will load quickly, and parse all of the maps while in the menu. It will stutter for a bit while it loads all the maps; this is normal.
- The Host Game menu now STRICTLY enforces CO-OP mode. Lots of options relating to Barricaded Suspects/VIP Escort/Smash and Grab have been removed.
- Console upgrades: The console will no longer close after entering a command (use the ESC key)
- Console upgrades: The console will show a log of commands used and show the output of commands
- Console upgrades: New console command "history"

## COMPLIANCE CHANGES ##
The compliance system has been changed slightly. Civilians are not nearly as noncompliant as before, but all of the changes required their own section.

- Greatly increased the effectiveness of Stinger grenades against Hostage and Suspect morale. They're as good as Tasers now.
- Greatly increased the area of effect for Stinger grenades.
- Doubled the duration of effect for CS gas but greatly reduced its morale modifier
- Slightly increased the effectiveness of Tasers against Suspect morale
- Slightly increased the effectiveness of bullets against Hostage morale
- Slightly reduced the effectiveness of C2 against Hostage morale
- Removed a slight (< 1 second) delay from AI being affected by Stinger and Flashbangs. (it still exists for CS gas)
- Reduced duration of effect of Pepperball gun by 50%

## SCORING SYSTEM ##
The scoring system has been altered:

#### BONUSES ####
- Mission Completed: Awarded when all of the mission objectives are completed. 
 * Points: 45
- Suspects Arrested: Bonus based on the amount of suspects secured. 
 * Points: (Number of suspects arrested)/(Total Number of suspects) x 20.
- Suspects Incapacitated: Bonus based on the amount of suspects incapacitated and secured. 
 * Points: (Number of suspects incapacitated)/(Total Number of suspects) x 13 (65% of 20).
- Suspects Neutralized: Bonus based on the amount of suspects neutralized. 
 * Points: (Number of suspects neutralized)/(Total Number of suspects) x 4 (20% of 20).
- No Civilians Injured: Awarded when no civilians suffer injuries, be it gunfire, less-lethal weapons or aids. 
 * Points: 5
- No Officers Downed: Bonus based on the amount of incapacitated officers. 
 * Points: 10 - ((Number of downed officers)/(Total Number of officers) x 10).
- Player Uninjured: Bonus based on the amount of players that sustained no injuries during a mission. 
 * Points: 5 - ((Number of injured players)/(Total Number of players) x 5).
- Report Status to TOC: Bonus based on the amount of reports to TOC. 
 * Points: (Number of reports made)/(Total Number of reportable characters) x 10.
- All Evidence Secured: Bonus based on the amount of evidence collected. 
 * Points: (Number of evidence collected)/(Total Number of evidence) x 5.

#### PENALTIES: ####
- Unauthorized use of Force: Given when the team incapacitates a suspect, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -5 per suspect.
- Unauthorized use of Deadly Force: Given when the team kills a suspect, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -20 per suspect.
- Incapacitated a Hostage: Given when the team incapacitates a hostage, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. 
 * Points: -20 per hostage.
- Killed a Hostage: Given when the team kills a hostage, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. The death of a hostage results in failure of the mission. 
 * Points: -50 per hostage.
- Injured a fellow officer: Given when an officer wounds another officer, be it by gunfire or sniper fire. 
 * Points: -10 per officer.
- Incapacitated a fellow officer: Given when an officer incapacitates another officer, be it by gunfire, sniper fire, less-lethal weapons or aids or breaching charges. Other officers may turn on the incapacitator. 
 * Points: -25 per officer.
- Tased a fellow officer: Given when an officer uses a taser another officer. 
 * Points: -5 per infraction.
- Triggered a Trap: Given when an officer opens a door with an alarm or booby trap attached to it. 
 * Points: -10 per trap.
- Failed to apprehend fleeing suspect: Given when a suspect escapes the perimeter of the mission area. 
 * Points: -5 per suspect.
- Failed to report a downed officer: Given when a downed officer is not reported to TOC: 
 * Points: -5 per downed officer
- Failed to report a downed suspect: Given when a downed suspect is not reported to TOC: 
 * Points: -5 per downed suspect
- Failed to report a downed hostage: Given when a downed hostage is not reported to TOC: 
 * Points: -5 per downed hostage

## PER-MAP CHANGES ##

!!!! WARNING !!!! From here down, there are possible spoilers if you have not played the TSS and SWAT 4 campaigns.

* Fairfax Residence
  - Lawrence Fairfax: Max Morale (0.75 -> 1.0)
  - Fairfax Accomplice: Max Morale (0.75 -> 0.6)
  - Gladys Fairfax: Min Morale (0.75 -> 0.3)
  - Gladys Fairfax: Max Morale (1.2 -> 1.0)
  * Cut content restored: Conversation where Fields is disgusted by the residence
  * Fixed SEF Bug: Cut conversation between TOC and Lead not working correctly with regards to the accomplice
  * Fixed SEF Bug: Cut conversation between TOC and Lead not working correctly with regards to a trap being tripped.
  * Fixed TSS bug: Accomplice carrying two Colt Pythons
  * The accomplice now spawns 100% of the time in Elite difficulty
  * The trap now spawns 100% of the time in Elite difficulty

* FunTime Amusements
  - Javier Arias: Max Morale (0.8 -> 1.0)
  * Fixed TSS bug: Missing loading screen text

* Our Sisters of Mercy Hostel
  - Halfway House Staff: Max Morale (0.7 -> 0.35)
  - Halfway House Residents (not Lionel MacArthur): Max Morale (1.5 -> 1.1)
  - Halfway House Residents (not Lionel MacArthur): Min Morale (0.5 -> 0.6)
  - Halfway House Robbers: Max Morale (0.7 -> 0.5)
  * Cut content restored: Conversation where Lead informs TOC about heavily armed, panicking suspects
  * Cut content restored: Conversation where Lead informs TOC about resistant civilians
  * Fixed TSS bug: SwatWildGunner holding the wrong gun model (he's classified as wielding an M249 SAW, but the model was pointing to the M4 Carbine)

* Northside Vending and Amusements
  * Cut content restored: Conversation between Lead and TOC when an alarm has been triggered
  - Louis Baccus: Min Morale (0.7 -> 0.5)
  - Northside Gamblers: Min Morale (0.8 -> 0.3)

* A-Bomb Nightclub
  * Fixed TSS bug: Alley door does not have MAKE ENTRY commands on it

* Sellers St. Auditorium
  - Andrew Norman: Max Morale (0.9 -> 1.0)
  - CASM: Min Morale (0.6 -> 0.3)
  - CASM: Max Morale (0.8 -> 0.9)
  - Sellers Street Band: Max Morale (0.95 -> 1.2)
  - Sellers Street Band: Min Morale (0.3 -> 0.5)
  - Sellers Street Male Patrons: Max Morale (1.2 -> 0.5)
  - Sellers Street Female Patrons: Max Morale (1.2 -> 0.6)

* Department of Agriculture
  * Cut content restored: Conversation between TOC and Lead about how many bombs are present
  - Rita Winston: Max Morale (1.5 -> 1.2)
  - Department of Agriculture Staff: Max Morale (0.9 -> 0.6)
  - Angry Farmers: Min Morale (0.7 -> 0.5)
  - Angry Farmers: Max Morale (0.9/1.1 -> 0.7/0.8)

* Drug Lab
  - Drug Lab Workers (Civ): Max Morale (0.9 -> 1.0)
  - Drug Lab Workers (Hostile): Max Morale (0.6 -> 1.1)
  - Only the drug lab workers who wear a gas mask can die from the taser now
  * Cut content restored: Conversation where Fields makes a sarcastic remark
  * Cut content restored: Conversation where the team converses about the smell of the establishment

* Fresnal St. Station
  - Subway Homeless: Max Morale (0.2 -> 0.4)
  - Subway Businesswoman: Max Morale (0.8 -> 0.2)
  * Cut content restored: Lead telling TOC that Officer Wilkins is safe

* Old Granite Hotel
  * Cut content restored: Lead saying when he's disabled bombs
  * Cut content restored: Jackson remarking that the bomb squad is "missing on all the fun" when all the bombs are disabled.
  * Fixed TSS bug: Snipers in wrong positions (for real this time)
  * Fixed TSS bug: Missing lights on floor 6

#### NITTY GRITTY/TYPOS AND STATS ####
* NOTE: some very (microscopically) tiny changes to stats aren't mentioned. For instance, the Nova Pump had its muzzle velocity raised by 2 units - not noteworthy at all and hardly noticeable.
* HUGE thanks to Jose21Crisis for crunching a lot of these numbers for me.
* NOTE: This section may not be completely accurate as some of the stats were changed in developments

Weapon Stats
- Colt Accurized Rifle: Muzzle Velocity (61261 -> 47838)
- M4Super90: Muzzle Velocity (21384 -> 20386)
- Colt M4A1 Carbine: Muzzle Velocity (58344 -> 44609)
- Colt M4A1 Carbine: Firing Speed (1.5 -> 1.333)
- Colt M4A1 Carbine: Single Fire Speed (1.00 -> 2.00)
- AK-47 Assault Rifle: Muzzle Velocity (47404 -> 36080)
- AK-47 Assault Rifle: Single Fire Speed (1.00 -> 2.00)
- AK-47 Assault Rifle: Auto Fire Speed (1.00 -> 1.666667)
- H&K G36C: Muzzle Velocity (56355 -> 40370)
- H&K G36C: Single Fire Speed (1.0 -> 2.0)
- M249 SAW: Muzzle Velocity (48037 -> 46173)
- M249 SAW: Firing Speed (1.75 -> 2.44445)
- M249 SAW: Single Fire Speed (1.00 -> 1.8333333)
- FN P90 PDW: Muzzle Velocity (25185 -> 36131)
- FN P90 PDW: Firing Speed (1.75 -> 1.25)
- FN P90 PDW: Single Fire Speed (1.0 -> 0.833333)
- IMI Uzi: Muzzle Velocity (19508 -> 17106)
- IMI Uzi: Firing Speed (1.25 -> 0.6777)
- IMI Uzi: Single Fire Speed (1.00 -> 2.00)
- H&K MP5A4: Muzzle Velocity (26520 -> 20185)
- H&K MP5A4SD: Muzzle Velocity (18895 -> 14381)
- H&K MP5: Both versions firing speed (1.3300 -> 1.1111)
- H&K MP5: Both versions single fire speed (1.00 -> 2.00)
- H&K UMP45: Muzzle Velocity (12693 -> 13120)
- H&K UMP45: Firing Speed (0.55 -> 1.00)
- H&K UMP45: Single Fire Speed (1.00 -> 2.00)
- Glock 9mm: Muzzle Velocity (18170 -> 16148)
- Glock 9mm: Single Fire Speed (1.00 -> 2.00)
- Colt M1911: Single Fire Speed (1.00 -> 2.00)
- Desert Eagle: Muzzle Velocity (24675 -> 19983)
- Desert Eagle: Firing Speed (1.0 -> 2.0)
- TEC-DC9: Muzzle Velocity (16170 -> 18166)
- TEC-DC9: Firing Speed (1.75 -> 2.00)
- TEC-DC9: Single Fire Speed (1.00 -> 2.00)
- M9 (suspect weapon): Muzzle Velocity (18924 -> 17863)
- MAC-10 (suspect weapon): Muzzle Velocity (14123 -> 15391)
- G3KA4 (suspect weapon): Muzzle Velocity (42893 -> 40370)
- AK74 (suspect weapon): Muzzle Velocity (37093 -> 45416)
- Colt Python: Fire Speed (1.00 -> 1.03)
- Nova Pump: Fire Speed (1.00 -> 1.166667)

Other Hostages Not Listed
- Warehouse Civilians: Max Morale (1.2 -> 0.9)
- Wolcott Homeless: Min Morale (0.5 -> 0.3)
- Wolcott Homeless: Max Morale (1.33 -> 1.1)
- Convenience Store Workers: Max Morale (0.4 -> 0.1)
- Theodore Sturgeon: Max Morale (1.1 -> 0.8)
- Hologen Students: Min Morale (0.5 -> 0.25)
- Hologen Students: Max Morale (1.1 -> 1.0)
- Food Wall Patron: Max Morale (1.1 -> 0.8)
- Food Wall Staff: Max Morale (1.1 -> 1.0)
- DuPlessi Security: Max Morale (0.15 -> 0.8)
- Warren Rooney: Max Morale (1.35 -> 1.0)
- Red Library Staff: Max Morale (1.15 -> 0.6)
- Taronne Civilian: Min Morale (0.8 -> 0.0)
- Female Taronne Civilians max morale (1.33) now matches Male civilians (1.2)

Other Suspects Not Listed
- Kiril Stetchkov: Max Morale (2.0 -> 1.5)
- Kiril Stetchkov: Taser Death Chance (0.35 -> 0.5)
- Alex Jimenez: Max Morale (0.6 -> 0.8)
- Taronne Cultists: Max Morale (0.9 -> 1.1)
- Andrew Taronne: Max Morale (0.95 -> 1.1)
- Andrew Taronne: Min Morale (0.7 -> 0.4)
- Hologen Terrorists: Max Morale (9.0 -> 1.2) [good lord]

#### PROGRESSION ####
The progression has been modified. There is now a piece of equipment unlocked on every mission.
- Fairfax Residence (---)
- Food Wall (yellow Taser)
- Qwik Fuel (M4Super90)
- FunTime Amusements (Gas Mask)
- Victory Imports (Less Lethal Shotgun)
- Sisters of Mercy (Pepperball Gun)
- A-Bomb Nightclub (Riot Helmet)
- Northside Vending (P90)
- Red Library (Colt Accurized Rifle)
- Sellers Street Auditorium (UMP 45)
- DuPlessis Diamonds (HK69 Grenade Launcher)
- Children of Taronne Tenement (Night Vision Goggles)
- Department of Agriculture (Colt Python)
- St. Micheal's Medical Center (Uzi)
- The Wolcott Projects (TEC-DC9)
- Stetchkov Drug Lab (expansion Taser)
- Fresnal St. Station (ProTec Helmet)
- Stechkov Warehouse (Desert Eagle)
- Old Granite Hotel (AK-47)
- Mt. Threshold Research Center (M249 SAW)

### v3 ###
MAJOR FEATURES
- Multiplayer fixed. You can now play in CO-OP again.
- MOVE menu disabled, all MOVE commands moved to OPEN submenu (there seems to be some hardcoded trickery going on...)
- Fixed bad shotgun aiming mechanics. Instead of shotguns firing in a spread determined by crosshair, shotguns fire in a fixed spread that chooses a point determined by crosshair.
- Main Menu changed: new logo, and New Features replaced with Training
MINOR FEATURES / FULL CHANGES
- Multiplayer GCI: Positive responses moved to a submenu: POSITIVE >> and negative responses moved to NEGATIVE >> submenu
- Multiplayer GCI: BREACH commands removed, OPEN commands can be used on locked doors
- Fixed accidental bug introduced in previous version with MP loadout menu
- MIRROR UNDER DOOR renamed to MIRROR/SCAN DOOR (for multiplayer reasons)
- OUT OF THE WAY changed to be the default for General
- Multiplayer Pregame/Postgame: "Ready" button will no longer grey out when ready; instead it will change to "Unready" and clicking it will make you not ready.
- Multiplayer Pregame: Removed Gamespy button
- Multiplayer Pregame: The "Server Setup" button is only visible if you are the host of the game
- Multiplayer Host: Removed the "Powered by Gamespy" image
- Multiplayer Server Select: Removed the "Profile" button
- Multiplayer Server Select: Removed the "Powered by Gamespy" image
- Removed New Features, replaced with Training.
- Missions will inform you to try playing Training before indulging in the campaign.
- Instant Action will play Training if the campaign hasn't started.
- Modified main menu logo
- Added missing texture: gui_tex2.audio_Processing (related to speech recognition)
- Included startup.ini because I am bad

### v2 ###
- New Feature: Speech Recognition. Enable it in Audio Options
- New Feature: Disable initial dispatch. Enable it in Audio Options
- You can now pick up guns through restrained suspects, and all hostages (except live, unrestrained ones)
- AI-controlled officers will now automatically report suspects/hostages that they restrain
- Support for many more resolutions (4 -> 22)
- Fixed a bug that caused the Heavy Armor to have texture issues due to StaticLoadout.ini missing
- Fixed a bug that caused the AI-controlled officers to not deploy pepperball gun if it was their secondary weapon
- Fixed a bug that caused the AI-controlled officers to not deploy grenade launcher if it was their secondary weapon
- Fixed a bug where grenades in the DEPLOY >> submenu would not be greyed out if officers didn't have them (vanilla bug?)
- Fixed a bug where DROP LIGHTSTICK would not be greyed out if there was no officer with a lightstick
- MIRROR UNDER DOOR and CHECK FOR TRAPS now obeys the stack-up positioning and stacks up the squad on the door.
- Fixed: Children of Taronne has traps bolted onto incorrect bones
- Fixed: Children of Taronne has a trap on the wrong side
- Fixed: Missing drug rosters on Stetchkov Drug Lab
- 'Show Subtitles' moved to Audio Options

### v1 ###
- First release

# CREDITS/THANK-YOUS #
Irrational Games and Sierra for the game.
KevinL for a tip about Voting Screen.
sandman332 for a tip about audio
kevinfoley for some help with Speech Recognition
BeyondUnreal for keeping their old school Unreal Engine 1/2/3 documentation alive
Sebasien NovA for his modified SwatEd.exe
Ryo Ohki for a tip about P90 and SAW animations
Dc247 for typo corrections in this document

Briefing Voice-Over: LethalFeline (go check out his YouTube channel!)
Dispatch Voice-Over: Kita Nash (go check out her YouTube channel!)
Adam Moretti Voice-Over: GrimithM (go check out his YouTube channel!)

ELITE SUPPORTERS
These people have generously donated money to Elite Force via Patreon. If you are interested in helping out, you can find our Patreon page here: https://www.patreon.com/user?u=4885526
TheTCREngineer
Jake Robinson/sandman332
Evan Derickson


PUBLICITY
GOG.com (Ran a very nice overview of our mod, you should check it out!)
PC Power Play (Also ran a nice overview of the mod)
StrawberryClock (Streamer)
Rangar (Streamer)

TESTING
Oglogoth
cjslax6
Vylka

WE ARE: ELITE SQUAD
eezstreet: Team Lead, Programming, Map Editing
Jose21Crisis: Programming, Weapons Analysis
mezzokoko: Programming
Rangar: Music (Composition), Textures
TheTCREngineer: Models


.. if there is anyone I missed, feel free to send me a message and this will be corrected.

# LICENSE #
This software is licensed under the GNU General Public License v2. You can read it in more detail in LICENSE
