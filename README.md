# INTRODUCTION #

SWAT 4 is a fantastic, if horrendously bugged product. I've spent countless hours playing the game, mostly in CO-OP on servers new and old, and there always seemed to be a glimmer of potential that has never been truly realized by games that followed it.

The best way to explain SWAT: Elite Force in short is a complete overhaul of the original game. The broken AI is fixed, cut content has been restored, and every weapon is precisely calibrated to its real world counterpart. The main campaign, a combination of the vanilla game and The Stetchkov Syndicate, has a carefully crafted unlock system that you can play through with a friend to complete. If that isn't what you'd prefer, there's also an All Missions campaign which allows you to play through any mission, including custom ones on the hard drive, with any equipment in the game, including some which is multiplayer sepcific. Even after you've completed the campaign, there's various flavors of permadeath to tackle...if you think you're Elite enough...

The gameplay itself has been drastically changed. You can now aim down the sights, and there are now traps to disarm. Doors can have their lock checked with the melee key. Suspects can employ a wide variety of personality types, from your usual, sideways-shooting crook to insane domestic terrorists which murder civilians at whim to heavily armored thugs with light machine guns. Your team is much, much smarter too, and with the restored Speech Recognition feature, you can even order them around with an attached microphone. You'll need the extra speed too, because incapacitated civilians that spawn around the map will die if you aren't quick enough, which will impact your score. The command system has been vastly improved with a new LEADER THROW set of commands that let you be the one to throw the grenade, and SEARCH AND SECURE, which orders your officers to restrain all compliant hostages/suspects and secure all evidence in range. After restraining a suspect or hostage, your team will also report it to TOC.

The equipment system is incredibly robust. There's over 40 pieces of new equipment, some of which was cut from the original game. You'll need to manage your team's weight and bulk. Too much equipment, and an officer will become too overencumbered. By carrying less weight, you and your officers will move faster, and by carrying less bulk, you and your officers will interact with things faster. In singleplayer, you can also pick your team's helmet and body armor, which protect you similar to how they did in multiplayer. The breaching tab has been removed - instead, there are now six tactical slots and the breaching equipment is available as other equipment. There's twice as many ammo options as in the original game, and the choices matter, since new factors like drag (how much momentum the bullet loses over distance) and ricochet potential (how likely a bullet is to bounce off a surface) vary. Grenades and wedges come in 3-packs, at the cost of consuming more weight and bulk. Less lethal equipment is truly less lethal, since tasers may incapacitate or even kill the elderly, those in poor health, or drug users, and beanbags, stingers and flashbangs can be hazardous at close range.

The game is much more approachable as well, with a cleaned up user interface which functions well on modern widescreen resolutions. There's also an FOV slider and a mouse smoothing checkbox, preventing you from having to tinker with game files to accomplish the same thing. Perhaps most importantly, the game actually warns you when you've encountered a penalty.

Initially, I envisioned SWAT: Elite Force as a tactical simulator that could be used to train police officers in a similar vein to Canadian Forces: Direct Action. After peeking at the games files however, I uncovered a wealth of unused content and decided to contact the original developers about the game. Over time, the game became a much larger, insane overhaul. It's been called the best way to play the game by most people, and I'm proud of that. Perhaps you'll find it to be the same.

--eezstreet



# TABLE OF CONTENTS #

1. How to Install
2. Building from Source
 - Contributing to the mod
3. Changes, Summarized
4. Frequently Asked Questions (FAQ)
5. Mod Compatibility
6. Known Issues
7. Other Minor Changes
  - TSS Bugs Fixed
  - AI
  - Gameplay
  - GUI
  - Equipment
  - Quick Mission Maker
  - Mission Changes
8. How to play in Multiplayer
9. Credits
10. License


# HOW TO INSTALL #

Copy the folder containing this folder (SEF) into your SWAT 4 directory (the one containing Content and ContentExpansion).
For the CD copy of the game, this folder is located in C:/Program Files (x86)/SWAT 4 or C:/Program Files (x86)/Sierra/SWAT 4
For the GOG version of the game, it's usually located in C:/GOG Games/SWAT 4

!!! CAUTION !!!
Do not extract the SEF folder *into* your Content or ContentExpansion folders (and therefore overwrite things), otherwise the mod will not work correctly.

To run the game, use the "Launch SEFMod.bat" file. To run SWATEd, use the "Launch SwatEd.bat" file.
You can make a shortcut to these .bat files for more convenience.

The mod can be removed by deleting the SEF folder from your hard drive.

NOTE: You may run into an issue with the game not saving your settings, or throwing an assertion failure at times in the Settings menu. This is mostly a problem with Windows Vista and up; try giving the folder write permissions or "Total Control". Alternatively you can make your SWAT4x.exe run in administrator mode.

# BUILDING FROM SOURCE #

**ATTENTION!** You *cannot* run the game without having the content. You can find the content for the mod [here](https://1drv.ms/u/s!AnIKDNAshMwbnVml6hksfsABRhyq?e=NaCciJ).

If you are instead trying to build the source code, it is fairly straightforward.

 * Clone the source code into your SWAT 4 folder. Your folder structure ought to look very similar to the installed mod, with SWATEliteForce within your SWAT 4 folder.
 * Download the assets from the link above. Unzip the contents into your SWATEliteForce/Content folder. *Do not commit these files if you are using Git.*
 * From here, you can compile the source code with the CompileSource.bat and run the game with the LaunchSEF.bat. The source code will compile to .u files in the System folder.
 * Edit the source code within /Source/ and any ini files within /System/.

The mod's code is primarily written in UnrealScript. You can find a good resource about UnrealScript [here](wiki.beyondunreal.com). (Note, if you can't access this page, try using the Wayback Machine to access it.)

## Contributing to the mod

The best and most direct way to contribute to the mod's programming is by issuing a pull request. Generally, pull requests are best done by forking the mod's code, committing and pushing to your fork, and then issuing a pull request from your repository. It is not the best idea to use GitHub directly for editing, since if you need to make many edits, it will spam email inboxes.

When it comes to code cleanliness, the code standards appear to have been different between the base Unreal engine, vanilla SWAT 4 and vanilla TSS. Specifically:

 * The base Unreal engine does not support the use of the `#ifdef` keyword; this would appear to be a modified version of the engine which supports it.
 * The Stetchkov Syndicate uses spaces instead of tabs for indentation.

That being said, I would like to adhere to these standards as much as possible:

 * Use tabs instead of spaces for indentation. Use spaces instead of tabs when aligning comments across multiple lines.
 * Braces should always be used for `replication`, `while`, `if`/`else`/`else if` (except in replication blocks, where it is illegal), `for`, `defaultproperties`, `state` and any other blocks.
 * Braces should be on their own line. For example:

```java
if(something) { // bad

if(something)
{ // good
```

 * Class names (and `Object`) should start with a capital letter. (UnrealScript is not case sensitive)
 * Class properties should start with a capital letter. Local variables can start with either a lowercase or capital letter. Boolean variables should always start with a lowercase "b"
 * Primitive types (`string`, `int`, etc) should start with a lowercase letter.
 * Reserved words (`local`, `replication`, `if`, etc) should start with a lowercase letter.
 * Functions should start with a capital letter and be written as a verb. `Name` is a bad name for a function, but `GetName()` and `SetName()` are good.
 * Do not use `#ifdef` as support for it is spotty on some text editors which have UnrealScript support.
 * Use `const` whenever possible.
 * Only use `out` variables when it is not possible to use a return value.
 * Use `simulated` on functions that are executed both on the client and server.
 * Don't write both getter and setter functions for private variables unless there is a side effect involved in doing either. Instead, use a public variable. For example:

```java
var public bool bMyVariable;
var private bool bMyBadlyUsedVariable;

function bool GetMyBadlyUsedVariable()
{
	return bMyBadlyUsedVariable;
}

function SetMyBadlyUsedVariable(bool bNewValue)
{
	bMyBadlyUsedVariable = bNewValue;
}
```

Assets have to be sent to myself personally to integrate into the mod.

# CHANGES, SUMMARIZED #

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
 * Weapons can be aimed down the sights, for better accuracy, using the zoom key.
 * All of your equipment factors into two meters: WEIGHT and BULK. Weight dictates your speed and is a measure of how heavy your equipment is. Bulk affects interaction speed (C2 placing/wedging door/toolkit use, but NOT restraining) and measures how big your equipment is. You can pack No Weapon/No Equipment in some slots to reduce weight and bulk.
 * You can now share some equipment with other players by pressing the melee key. You can also order your AI officers to give you a piece of equipment as well. Currently this only works for tactical tab items and lightsticks.
 * Bullets of certain types (FMJ, buckshot, etc) can now ricochet off of hard surfaces such as concrete, dirt, and water. Use caution.
 * Bullets are now subject to drag; they lose damage over distance.
 * Less lethal equipment is now actually LESS LETHAL. Some equipment (tasers, beanbag shotgun) can incapacitate or kill if used incorrectly.
 * All equipment has been modified to use real values.
 * Recoil is now affected by arm injuries.
 * Lightsticks can be thrown or dropped on the ground, just like grenades can. Everyone gets double the lightsticks!

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


# FREQUENTLY ASKED QUESTIONS (FAQ) #

## CONTENTS ##

 * **How do I install the mod?**
 * **How do I use the speech recognition?**
 * **What's the difference between "MARK WITH LIGHTSTICK" and "DROP LIGHTSTICK"?**
 * **How can I check for traps in multiplayer?**
 * **How can I play in Multiplayer? Are there any servers?**
 * **How can I report a bug?**
 * **Why can't I play in Barricaded Suspects, VIP Escort, Smash and Grab, or Rapid Deployment?**
 * **Are you going to add AI officers in CAREER CO-OP?**
 * **Does this mod work with other mods?**
 * **I played in singleplayer, but there's no briefings. Why?**
 * **I want to change the entry in All Missions, but you removed the Briefing tab?**
 * **I played in singleplayer, but there's very few missions (1 or 2). Why?**
 * **Are there more missions for Extra Missions coming out?**
 * **I can't find X piece of equipment! Did you remove it?**
 * **Breaching doors with the shotgun doesn't work!**
 * **Beanbags don't work!**
 * **Traps aren't showing up!**
 * **How do I disarm a trap?**
 * **Are you going to add ballistic shields?**
 * **Are you going to add leaning while moving?**
 * **Disabling Ironsights Zoom is not working!**
 * **What happened to Instant Action?**
 * **The Play Quick Mission button was removed on the main menu. How do I play them?**
 * **I cannot progress in the campaign!**

## HOW DO I INSTALL THE MOD?
Please read the How to Install section of this README. :)

## HOW DO I USE THE SPEECH RECOGNITION?
First, you will need to ensure that your operating system supports Speech Recognition. What you'll need is the Microsoft Speech Recognition API, which is available here: https://www.microsoft.com/en-us/download/details.aspx?id=27224
If your system meets the requirements, the 'Use Speech Recognition' checkbox will be available.
You can also bind a key to toggle the functionality ingame, which is good when you're speaking for a Let's Play, for example.
A list of trigger words is provided, starting with Patch 5.1. See SpeechCommands.md for more information.

**IF SPEECH RECOGNITION DOES NOT WORK (CHECKBOX GREYED OUT):**

- What language is your operating system? *By default, the game will only work with an English (United States) version of Windows.*
In order to support more languages, you will need to edit your SEF/System/SpeechCommandGrammar.xml. Near the top of the file will be a line that reads like this:
```
<GRAMMAR LANGID="409">
```
You will want to modify this line so that it uses a number which corresponds to your operating system (NOT THE GAME!).
The list of languages can be found here: https://msdn.microsoft.com/en-us/library/office/hh361638
So for instance, if you have a Swedish operating system, you will want to change it so the line looks like this:
```
<GRAMMAR LANGID="41D">
```

- Did you install the API? (see the above link)

- Still not working? Try installing the Speech Recognition Improvement mod, and see if that mod works.


**IF SPEECH RECOGNITION DOES NOT WORK (COMMAND NOT RECOGNIZED, OR MICROPHONE NOT WORKING)**

- Check to make sure that you did not disable the speech recognition with the keybind. (The key is not bound to anything by default)

- Check to make sure that the microphone works in Windows.

- Check to make sure that the microphone works in the game (try using the built-in VOIP feature and see if your friends can hear you in a multiplayer game)

- Make sure there is no background noise, like a television. The game may misinterpret it as being your voice.

- Make sure you are speaking clearly.
If you are using the language fix from the above, you will want to speak with a bad accent as much as possible. Really roll those Rs if you're using a Spanish OS.
If you aren't, try to talk like you're a newscaster or like you're having a conversation with someone on the phone and they aren't understanding you.
Also note that some things sound similar. For example, "Cuff her" sounds a lot like "cover".

- Make sure you are saying the correct thing.
See the SpeechCommands.md if you are having trouble saying a particular command.

## WHAT'S THE DIFFERENCE BETWEEN "MARK WITH LIGHTSTICK" AND "DROP LIGHTSTICK"?
MARK WITH LIGHTSTICK orders the nearest officer to go to the location and drop a lightstick. DROP LIGHTSTICK orders the nearest officer to drop a lightstick at their feet.

## HOW CAN I CHECK FOR TRAPS IN MULTIPLAYER?
Use the Optiwand, and aim up at the doorknob.

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
Please refer to the "Mod Compatibility" section of the README.

## I PLAYED IN SINGLEPLAYER, BUT THERE'S NO BRIEFINGS. WHY? ##
There are no briefings in an All Missions campaign. Play with either a SWAT 4 + TSS or Extra Missions campaign.
The reason there is no briefing is because the All Missions campaign pulls *all* missions from your hard drive, including custom maps.
These custom maps cannot have briefing or entry information added to them very easily. Loading up the briefing will cause a crash on those missions.

## I WANT TO CHANGE THE ENTRY IN ALL MISSIONS, BUT YOU REMOVED THE BRIEFING TAB? ##
The entry options are available on the Mission Selection screen, underneath the difficulty selection.

## I PLAYED IN SINGLEPLAYER, BUT THERE'S VERY FEW MISSIONS (1 OR 2). WHY?
You most likely selected the Extra Missions path when you started the career. There's three options: Extra Missions (missions added by the mod), SWAT 4 + TSS (the original game's missions), and All Missions (all missions from your hard drive, with no equipment progression).

## ARE THERE MORE MISSIONS FOR EXTRA MISSIONS COMING OUT?
Yes.

## I CAN'T FIND X PIECE OF EQUIPMENT! DID YOU REMOVE IT?
Only the ammo pouch was removed from the base game. If you cannot find a piece of equipment, make sure you have unlocked it in the campaign!
Note that some equipment (M16, Uzi, AKM, etc) is only available in multiplayer.

## BREACHING DOORS WITH THE SHOTGUN DOESN'T WORK!
Whether or not a shotgun breaches the door successfully is random and depends upon a few things:

 - The material of the door (wooden doors are easier to breach than metal ones)
 - The ammo type you are using (larger pellets = more likely to breach)
 - Which shotgun you are using (the M870 Breaching *always* breaches the door on the first shot)

Generally it takes about 2-3 shots on a wooden door and 3-4 shots on a metal door to breach it successfully.

## BEANBAGS DON'T WORK!
Beanbags can be negated by body armor. Try aiming for unarmored parts of the body.

## TRAPS AREN'T SHOWING UP! ##
...or another variation of this: "I played through the first mission, and the README says that there's supposed to be traps on it, but I never saw any traps!"
The traps are randomly generated on the mission. On almost every map that they can show up, it's possible for them to not show up at all.
On the Fairfax Residence mission, there's a 50% chance (100% on Elite) that a trap will spawn - and there's four total doors it can spawn on. 
So it's possible to trigger the trap almost immediately, but also possible to never encounter it, depending on the route you take and the randomization.

## HOW DO I DISARM A TRAP?
You can't disarm a trap if it's on the other side of a door. You can either blow it up (if it's electronic) with C2 or you can go around and remove it with the toolkit. Or just take the penalty.

## ARE YOU GOING TO ADD BALLISTIC SHIELDS?
Possibly, at some point. I would need someone to produce the art assets for it, as I'm not an artist.

## ARE YOU GOING TO ADD LEANING WHILE MOVING?
Moving and leaning requires hundreds of animations to be added to the game, due to the way the animation system in the game works. Unless someone can come forward and make all of those animations for me, then no.

## DISABLING IRONSIGHTS ZOOM IS NOT WORKING!
If you are ingame and you check "Disable Ironsights Zoom" then it won't work until you change your weapon, because of how the code works. Just change to a different piece of equipment and change back.

## WHAT HAPPENED TO INSTANT ACTION? ##
Instant Action was removed because nobody used it. Furthermore, it causes issues with Permadeath campaigns, among other things.

## THE PLAY QUICK MISSION BUTTON WAS REMOVED ON THE MAIN MENU. HOW DO I PLAY THEM? ##
You now need to create a career for them, in the Career menu. This is because Quick Missions support a ton of new features, like progression, unlocks, etc. They also work with Permadeath modes.

## I CANNOT PROGRESS IN THE CAMPAIGN! ##
This is a common bug that is encountered. Sometimes you will play a mission, even scoring a 100/100 on it, and the next mission won't unlock. Sometimes even if you replay it over and over again, even on Easy, it won't progress. This seems to happen a lot on the first mission for some reason.
I have no idea why this happens, or what the explanation is for it. It has happened to me and others in the vanilla game, both with and without the expansion.
To solve it, you can just unlock the next mission and the campaign will progress normally after this.

To unlock the next mission, find your SEF/System/Campaign.ini file. (Sometimes it is not here, it is ContentExpansion/System/Campaign.ini)
Edit this file in Notepad, and find your career in here. It should be fairly obvious, and look something like this:
```ini
[Campaign_Officer_Default]
StringName=Officer Default
CampaignPath=0
availableIndex=0
HACK_HasPlayedCreditsOnCampaignCompletion=False
```
All you need to do here is take the line that reads `availableIndex=<SOME NUMBER>` and increase that number by 1.
So for example, if I am stuck on the first level, I need to increase that 0 to a 1.
You can increase this all the way to 20 and unlock all of the missions, if you feel like cheating.

# MOD COMPATIBILITY #

SWAT: Elite Force is compatible with skins and custom maps out of the box, without modifications. It is not compatible with total conversions or new weapon mods. It has some compatibility issues with admin mods.
To make this process more painless, I've gone ahead and listed each of the mods on Moddb and elsewhere, and provided the compatibility status.

**Fully Compatible; no special installation steps:**
 * SWAT 4 ENB / Reshade
 * SWAT 4 Music Overhaul
 * ANY map pack mod. (DO NOT install the Mega Map Pack campaign mod in its installer, it is not needed with this mod)
 * ANY custom officer skin mod.


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


**Already present; this mod is either incorporated into or is a base for another mod:**
 * BFHL character models mod (the author provides a compatible version)
 * HugeOfficerVarieties


**Not compatible; SEF does not work with these mods at all and cannot possibly function with:**
 * SWAT 4 Remake Mod
 * SWAT 4 1.2 Mod
 * Code 11
 * 11-99 Enhancement Mod
 * HSM Enhancements
 * Sheriff's Special Forces (SSF)
 * SAS Mod (SEF includes many of its weapons)
 * Speech Recognition Improvement (SEF includes many of its features)


# KNOWN ISSUES #

Please read the FAQ before looking here! It's entirely possible that what you are seeing is intentional behavior.
  * Officers sometimes ignore orders, you might have to issue a command two or three times. Problem of the original game.
  * Officers sometimes ignore orders and say something like "I'm busy." This is a problem of the original game; they sometimes can see suspects where the player can't.
  * Sometimes when you are loading up the game, you can get no sound at all. This is an issue introduced by the Stetchkov Syndicate expansion pack. Sometimes it can be solved by simply restarting the game and not running the game in windowed mode. Sometimes, if you have two detected audio devices (one for output, and one for both input and output), make sure that the one that is responsible for both input and output is DISABLED. The game is bugged and will sometimes pick the wrong audio device.
  * "gui_tex package version mismatch" when joining a server: Make sure you are running under International language. Sometimes it defaults itself to English or some other language. Search for `Language=eng` or `Language=grm` in SEF/System/Swat4x.ini and make sure it's set to `Language=int`


# OTHER MINOR CHANGES #

## TSS BUGS FIXED ##
 * Typos, wrong captions, etc fixed throughout.
 * AI-Controlled Officers will fire their weapons/non lethal equipment much more smartly and won't kill hostages or waste taser/pepper spray ammo needlessly.
 * AI-Controlled Officers wouldn't fire their weapon if the suspect was very close.
 * AI-Controlled Officers wouldn't give a verbal response to the COVER command.
 * AI-Controlled Officers, when ordered to breach a room with a breaching shotgun, would shoot the lock, there would be a pause, and the lock would appear broken. The pause is removed.
 * It was possible to access equipment in singleplayer when it wasn't unlocked by creating a custom loadout; it will now tell you that the equipment is not unlocked when doing so.
 * "Press ESC and debrief to exit the game" now shows on ALL missions, not just Food Wall, Fairfax Residence and Qwik Fuel missions.
 * Punching a restrained suspect no longer makes them stand up.
 * Punching while changing weapons or while arresting will no longer turn your weapon invisible.
 * Punching while firing pepper spray, reloading weapons, or firing weapons is no longer allowed for obvious reasons.
 * There is no longer a cooldown between swapping sniper viewports after "Press Page Up to view sniper view" triggers.
 * Wild-Gunner AIs had the wrong weapon equipped (M4A1 instead of M249 SAW)
 * Wild-Gunner AIs will no longer sweep back and forth while compliant.
 * M249 SAW, P90 and TEC-9 made the wrong sound effect when fired in Full-Auto from other player's perspectives
 * M249 SAW and P90 had ugly/weird first person positioning.
 * Colt Accurized Rifle and Grenade Launcher had no animations for the AI-controlled officers when they were holding them.
 * P90 was using wrong animations when held by AI-controlled officers
 * TEC-9 did not have any reload sound effects
 * TEC-9 did not use a flashlight despite the model having one
 * Night vision goggles no longer alert AI to your presence
 * Explosion effects from gas cans DO alert AI to your presence now
 * Office workers on Department of Agriculture and terrorists from Mt. Threshold Research Center had stupidly high max morale.
 * Suspects weren't taking into account whether a door was locked or wedged when fleeing, which would lead to cases where they would try to open the door in an endless loop while running away.
 * Arresting people with No Armor equipped was glitchy
 * The Multiplayer ESC menu didn't show colors on the server name.
 * Taser recoil applied to every player on the map, not just the person who shot it.
 * Lightstick-related commands weren't greyed out if there weren't any officers with lightsticks
 * Weapons couldn't be picked up while aiming through incapacitated/dead suspects/civilians
 * Lightsticks couldn't be dropped if the officer was wearing heavy armor (they would appear at the world origin)
 * Server browser showed duplicate servers
 * Server browser player sorting didn't work correctly
 * Ordering your team to disable something while they were restraining people (or collecting evidence) would cause them to stop restraining targets (or collecting evidence), and vice versa.
 * In CO-OP, suspect skins were visible despite only SWAT skins being available for use. All skins are available for use now.
 * You could reload the same magazine back into the weapon, if it was the highest-containing, but not full magazine.
 * Spoken lines by TOC on the expansion missions would cut off if the player used the shout button
 * Wedges did not appear in players' holsters.
 * If a suspect unlocked a door, it is still "known" as a locked door.
 * The enemy "CallForHelp" speech was rarely/if at all triggering.
 * The enemy "AnnouncedSpottedOfficerSurprised" speech now plays.
 * Applying a loadout to the whole team in a Quick Mission which has locked equipment allowed the player to bypass the locked equipment entirely.
 * Enemies could spawn in an unreachable spot on The Wolcott Projects (QMM only), making it impossible to collect the evidence.
 * The gunshot sound effects on Northside Vending and Amusements from the laundromat would not play correctly on the expansion (but would in the vanilla game).
 * The gunshot sound effects on A-Bomb Nightclub from the stage would not play correctly on the expansion (but would in the vanilla game).
 * On Fresnal St. Station, hostages that spawned on the train platform would scream endlessly after a suspect escaped.
 * On Fresnal St. Station, there is a mirror point that can have orders issued to it, but it is inaccessible.
 * FunTime Amusements was missing loading screen text.
 * The accomplice on Fairfax Residence could spawn with two Colt Pythons.
 * The Host Game and Server Setup menus did not display color codes properly on the map list, map name, and map author.
 * Highground did not work correctly due to a bug on many maps. Now you can place Highground volumes and they will function properly.
 * Victory Imports did not have working Highground due to the bug listed above.
 * Highground audio on Food Wall was wrong ("He went back into the house", this was meant for Fairfax Residence)
 * Highground audio on Fairfax Residence was wrong ("Side 3 Level 2")
 * Some custom SWAT 4 (non-expansion) co-op missions used an objective set called "COOPClearTest". TSS removed this objective set and broke those missions. I have restored it. (Thanks to SS for the tip.)
 * Re-enabled Auto Downloads feature.
 * The player could control the officer viewport while reloading, switching weapons, or using an item. This allowed for an exploit where players could move while placing C2, arresting people, or picking a lock.

## AI ##
  * Tons and tons of cut dialogue restored.
  * Lots of minor little animation glitches on SWAT officers fixed.
  * In general: SWAT AI is both smarter and better stat-wise. Suspects are statistically worse, but make up for this in intelligence and cunning strategies.
  * Suspects no longer have an instant lock-on aim. Rather, there is a small delay between when they spot you and when they will fire.
  * Likewise, suspects do not always fire with perfect accuracy. Sometimes, low skill gang members can fire their gun sideways (a cut animation) for even worse accuracy.
  * Suspects will escape after giving up (even if there is no gun present -- if there is one, they will pick it up and attack), but not when watched, and will try to barricade themselves in a room.
  * Suspects can hear gunshots from across the map (unless they are silenced) and can choose to investigate or barricade their position randomly.
  * Suspects may take on a variety of personalities, such as Insane and Polite. Insane suspects shoot hostages with little restraint, while Polite ones do not shoot at all at them.
  * Suspects and civilians may randomly wander around on a few maps, instead of using fixed patrols.
  * Suspects will close doors after firing at them.
  * Suspects may shoot the player when running away from them.
  * Suspects can shoot through thin pieces of cover, if their weapon (and ammo) is capable of it.
  * Suspects may choose to shoot through their accomplices, if they are low skilled or Insane.
  * Suspects can wear heavy armor like SWAT can.
  * Suspects drop their weapons much faster. Most of the time.
  * Suspects react faster to grenades.
  * Suspects fire upon hostages twice as quickly.
  * Suspects will choose to fire either in full auto or in burst, depending on their skill level.
  * Suspects firing from cover may choose to pause or regroup between their shots, instead of constantly aiming at their target.
  * Civilians may be Fearless. When they are Fearless, they do not scream when in the presence of a suspect.
  * SWAT are much more dangerous and less hesitant to shoot at suspects.
  * SWAT do not form "death funnels" in doors and instead will try to continue moving.
  * SWAT will attempt to seek out cover when engaging suspects (only after clearing a room or when issued a COVER command)
  * SWAT can properly use the grenade launcher now.
  * SWAT AI will ignore uncompliant civilians or cuffed civilians/suspects while there are active threats.
  * SWAT will no longer try to shoot through civilians or players when attacking their target.
  * SWAT will reload their weapons when ordered to fall in.
  * SWAT do not become distracted by suspects/civilians when they are following you or going to a specific destination (with MOVE TO). They will shout at them (and/or attack), but continue moving.
  * SWAT will shoot beanbags and pepperballs at fleeing suspects (when following a FALL IN or MOVE TO command) intelligently, keeping in mind not to spam beanbags and kill people. SWAT can now use pepperballs and beanbags as proper weapons in general.
  * SWAT will listen to and respond to sounds even when they have an enemy, so they have better situational awareness.
  * SWAT clears rooms quicker and drops a lightstick after clearing.
  * SWAT now turns at the same rate that suspects do (which is faster) and have higher field of vision.
  * SWAT no longer moves out of the way if they are deploying a wedge and they are bumped by the door. Note, if they are moving into position to deploy the wedge, they will still get out of the way.

## GAMEPLAY ##
  * Maps may now alter themselves based on difficulty level, for instance adding more suspects or traps in Elite difficulty. Only a few maps use this feature currently.
  * Doors can randomly be locked or opened.
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
  * Grenades and wedges now go back to your last used weapon after using one, instead of switching back to that item.

## GUI ##
  * Training mission returns! New Features from the Expansion are gone.
  * "Disable Initial Dispatch" option in Audio Settings lets you skip the initial dispatches.
  * "Mouse Smoothing" checkbox in Control Settings enables (default) or disables mouse smoothing.
  * "Field of Vision" slider in Video Settings lets you change the field of vision.
  * Mod version, wiki and Discord links are shown in the main menu.
  * Server browser has a button to download the server browser patch.
  * Loadout Menu (SP) has a button to apply current tab to Element, Team, or specific officer
  * Loadout Menu (SP) has a button to apply current loadout to Element, Team, or specific officer
  * The debriefing menu now has an entrance selection box, so you don't have to go back to the main menu to change the entrance.
  * Maps in the Voting screen are now sorted alphabetically.
  * Host Game no longer precaches all of the maps at once; it goes to the menu and loads the maps while in the menu.
  * Added Advanced Information tab to Equipment Panel. It now shows a weapon's manufacturer, manufacturer country, date manufactured, caliber, magazine size, maximum ammo carried, muzzle velocity and firing modes. It also shows advanced information for protective equipment.
  * Weapons are now selected by dropdown menus, for faster selection
  * New splash screen
  * More advanced console. It will now show output of commands, and a console log. You need to press ESC to close the console now.
  * All "RESERVED" keys are now able to be edited. The category has been renamed to "NUMBER ROW".
  * An additional key config category, "MULTIPLAYER", has been added.
  * Lots of new controls (including 'Take Screenshot' and 'Toggle Speech Interface') have been added to the key config menu.
  * New main menu logo
  * All evidence of Gamespy scrubbed
  * Removed "Check for Patch" button on the join game menu
  * Cleaned up appearance throughout
  * You can now Un-Ready yourself in CO-OP games.
  * In CO-OP, clicking the Equipment button automatically Un-Readies yourself.
  * Support in the menu for 5x as many resolutions, including many widescreen resolutions
  * The menu will now show labels on stuff in widescreen resolution
  * You no longer need a CD-key to publish a game to the Internet server browser.


## EQUIPMENT ##
All weapons have been changed to have correct muzzle velocities.
* Grenade Launcher:
	- Given real world name (HK69)
	- The AI can now use it correctly when ordered a command which uses gas/flashbang/stinger.
	- Greatly increased damage dealt from direct impact. But now it scales linearly over distance; so a point blank shot does much more damage. After some distance, grenades stop doing damage.
	- Damage is now required to trigger the direct impact stun effect.
	- May now be equipped as a secondary weapon
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
* Colt M4A1 Carbine:
	- New ammo types: AP, JSP
	- Uses Brettzie's model.
	- Four variants in total (M4A1, Suppressed M4A1, M4A1 w/ Aimpoint, Suppressed M4A1 w/ Aimpoint)
* AK47 Machinegun:
	- Now has a flashlight
	- New ammo types: AP, JSP
	- Fixed inaccurate description
	- Fixed name (AKM)
	- Only available in Multiplayer and All Missions
* GB36s:
	- Given real world name (is now G36K)
	- New ammo types: AP, JSP
	- Updated description
	- Retextured
	- Now has a silenced counterpart
* 5.56mm Light Machine Gun
	- Given real world name (is now M249 SAW)
	- New ammo type: JSP
	- Burst fire removed
	- Corrected wrong looking first person
	- Only available in Multiplayer and All Missions
* 5.7x28mm Submachine Gun
	- Given real world name (is now P90)
	- Completely redid the description
	- New ammo types: AP, JSP
	- Burst fire removed
	- Corrected wrong looking first person
	- Has a suppressed counterpart
	- Unlockable weapon
* Gal Sub-machinegun
	- Now has a flashlight
	- New ammo types: AP, JSP
	- Corrected wrong name (is now Silenced Uzi)
	- Updated description
	- May now be equipped as a secondary weapon
	- Only available in Multiplayer and All Missions
* 9mm SMG
	- New ammo types: AP, JSP
	- Corrected wrong names (MP5A4 and Silenced MP5A4)
	- Added automatic firing mode
	- Updated description
	- Retextured
	- Fixed incorrect magazine size for FMJ (holds 30 rounds, not 25)
* .45 SMG
	- Given real world name (UMP)
	- New ammo types: AP, JSP
	- Updated description
	- 2-round burst mode added
	- Retextured
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
	- Now has a silenced counterpart
* M1911 Handgun
	- New ammo types: AP, JSP
	- May now be equipped as a Primary Weapon
* 9mm Handgun
	- Given real world name (Glock 17)
	- New ammo types: AP, JSP
	- May now be equipped as a Primary Weapon
* Mark 19 Semi-Automatic Pistol
	- Given real world name (Desert Eagle)
	- Remodeled entirely, with correctly functioning animations
	- Fixed typo in description
	- New ammo type: JSP
	- May now be equipped as a Primary Weapon
	- Only available in Multiplayer and All Missions
* 9mm Machine Pistol
	- Given real world name (TEC-DC9)
	- Completely redid the description
	- Now has a flashlight
	- May now be equipped as a Primary Weapon
	- Fixed broken reload sound
	- Only available in Multiplayer and All Missions
* TASER Stun Gun:
	- Cut TASER stun gun probe spread by 50%
	- Changed the name (TASER M26C Stun Gun)
	- Doubled the range (The M26C and its sister weapon have cartridge variations that can fire up to 35 feet)
	- Has a chance to incapacitate or even KILL hostages if not used correctly. Avoid use on the elderly, drug-users and people with health conditions.
	- Fixed typo in description
	- May now be equipped as a Primary Weapon
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
* Cobra Stun Gun:
	- Changed the name (TASER C2 Series Stun Gun)
	- Changed the description
	- Reduced the range (The C2 series can only fire up to 15 feet)
	- Like the TASER stun gun, the Cobra stun gun has a chance to incapacitate or kill hostages.
	- May now be equipped as a Primary Weapon
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
* Colt Python:
	- New ammo types: AP, JSP
	- May now be equipped as a Primary Weapon
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
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
* Gas Mask:
	- Renamed to Respirator
	- View obstruction effect removed
	- In the SWAT 4 + TSS campaign, this item must be unlocked.
* Lightstick:
	- Is colored based on team
	- Doubled in quantity
	- Can be thrown like grenades now
	- Can fade out (cut feature from TSS)
* C2:
	- Now available as a Tactical item
	- Increased the damage radius, stun angle and stun radius. It is riskier to use C2.
* Pepperball Gun:
	- May now be equipped as a Secondary Weapon
	- Less effective in general now
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
* Less Lethal Shotgun:
	- Now called the Less Lethal Nova
	- Can incapacitate or kill subjects at point blank range
	- In the SWAT 4 + TSS campaign, this weapon must be unlocked.
* M4Super90:
	- Now fires in a spread that isn't dictated by crosshair accuracy
	- May now be equipped as a Secondary Weapon
	- Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck, Frangible Breaching
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
	- Corrected magazine size (5 -> 7). SWAT 4 uses the magazine size from a civilian version of the shotgun. The Law Enforcement and Military models have 7 round magazines.
	- Can breach doors; chance to breach is dependent on ammo type
* Nova Pump:
	- Now fires in a spread that isn't dictated by crosshair accuracy
	- Corrected invalid magazine size (8 -> 7)
	- Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck, Frangible Breaching
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
	- Can breach doors; chance to breach is dependent on ammo type
* Added three new head armor items:
	- Riot Helmet: Offers slightly less protection than the Helmet, but also cuts Pepper Spray and Gas durations in half
	- ProArmor Helmet: Offers highest possible protection, but confers no other bonuses.
	- S10 Helmet: Offers protection from CS gas and pepper spray, as well as ballistic protection. However, it is bulky and restricts the field of view.
* Added two new body armor items:
	- Heavy Kevlar Body Armor: Being rated Level IIIA, it provides higher protection capabilities than the standard Level II Kevlar Armor, at the cost of a slight increase in weight.
	- Heavy Ceramic Body Armor: A plate carrier featuring NIJ Level IV rated plates, it is the ultimate in ballistic protection. It's main disadvantage is the massive weight of the plates, which slow down the user.
* Added new weapons from the SAS mod, most have a suppressed version as well:
	- ARWEN 37: Dedicated grenade launcher with flashlight and 5-round magazine.
	- SG552 Commando: Versatile assault rifle
	- HK33: Heavy-duty assault rifle. Includes a scoped version.
	- M16: The original assault rifle. Only available in Multiplayer and All Missions campaigns
	- MP5SSD6: A silenced-only version of the MP5 with a better suppressor.
	- MP5K: A more tactical machine pistol
	- Browning Hi-Power: Higher-powered 9mm pistol
	- P226: A well-rounded 9mm pistol
	- Remington M870 Shotgun: Shortened shotgun that can be equipped as primary or secondary weapon
* Added new equipment from the SWAT4 1.2 mod:
	- SCAR-H: Heavy assault rifle. Includes an Aimpoint, Suppressed Aimpoint, and Suppressed variants.
	- AKs-74u: Lightweight AK carbine. Only available in Multiplayer and All Missions campaigns
	- MP5K PDW: Tiny submachine gun. Includes a suppressed variant.
* Added new weapons (exclusive to this mod):
	- Less Lethal M870: Beanbag shotgun available as a secondary.
	- M870 Breaching: Technically the breaching shotgun from the original game, now as an actual weapon.
	- M1Super90 Shotgun: Cut shotgun from the original game. Lower magazine size than the M4Super90 but faster firing rate and more manageable recoil.
	- Glock 18: Spitfire machine pistol, available as a secondary.
	- Glock 19: Ultra lightweight 9mm pistol.
        - Colt Model 635 9mm SMG: SMG based on the M4A1. Includes a suppressed variant.
* Added 3-Packs (tactical) of the following. They are equivalent in weight and bulk to five items, to incentivize taking single items over packs:
	- Grenades
	- Wedges
* Ammo Pouch:
	- Removed.

## QUICK MISSION MAKER ##
The Quick Mission Maker missions are now accessed in the Career menu. Meaning, you need to create a new career for each pack you want to play through.
Quick Mission Maker packs are stored in `SEF/Content/Scenarios`. You can download new packs off the internet or share your custom-made ones.

 - You can now rearrange the order of the missions within a Quick Mission Maker pack.
 - You can now choose to have missions unlocked one-at-a-time for a Quick Mission Maker pack, or have them all unlocked at the start. (Enable Progression)
 - You can now assign an unlocks system within a Quick Mission Maker pack. (If unlocks are not available for the pack, the New Equipment tab will be disabled)
 - You can now use custom maps in a Quick Mission Maker pack. Custom maps force you to use a custom briefing, and all "Use Campaign Settings" options are disabled, as well as the briefing audio.
 - You can now disable equipment in a pack. For instance, you can have a pack of missions which only has non-lethal weapons.
 - You can now disable the mission briefing audio in a Quick Mission.
 - You can now write custom briefing text for Quick Missions.
 - You can now allow the Singleplayer map scripts to function in QMM missions (note, may cause instability)
 - You can now allow traps to spawn in QMM missions.
 - The hostages and suspects that spawn on a level can be more finely controlled through an "Advanced Mode" that allows editing details such as individual character morale, weapons used, and even what voice they have.
 - Notes entry field size increased from 500 to 4000.
 - NOTES tab renamed to TEXT.
 - Effectively removed the per-map limits on civilian and suspect counts. You can now have up to 999 suspects or civilians on a map.
 - You can now choose to disable the Timeline, Suspects, and Hostages tabs on the briefing.
 - The level loading screenshot and text will display if you have "Use Campaign Objectives" marked.
 - The INVALID stamp over the briefing will no longer display if you have "Use Campaign Objectives" marked.
 - The INVALID stamp over the timeline will no longer display if you have "Use Campaign Objectives" marked.
 - The INVALID stamp over the Civilians and Suspects portion will no longer display if you have "Use Campaign Settings" for Hostages or Suspects, respectively, checked.

## MISSION CHANGES ##
WARNING: This section contains spoilers
Missions are listed in order that they occur
Morale has been modified across the board.
Equipment has been revised and altered to be more in line with what the briefing describers.
If an equipment is not listed as unlocked by a mission, it is unlocked by default.

* Training Mission (Riverside Training Facility)
	- The training mission is now usable again in the main menu, and is good for testing weapons as well as learning the game.
	- All of the onscreen instructions have been updated to reflect the changes in the mod, and in The Stetchkov Syndicate expansion.
	- Removed weapon pickups at the beginning.
	- Made the cabinets at the beginning interactable. You can now use them to swap for a new weapon.

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
	- Restored a cut 911 call that was mistakenly disabled in the vanilla game.
	- All of the static drug bags were removed. They have been replaced with drug evidence which can be collected.
	- Andrew Norman is Insane and has a very small chance to die from the taser
	- Made loading screen text consistent with other missions ("The Sellers Street Auditorium, 1801 Sellers St" -> "1801 Sellers St., The Sellers Street Auditorium")
	- Unlocks the UMP 45 and the MP5SSD6
* DuPlessi Wholesale Diamonds
	- No changes
	- Unlocks the HK69 Grenade Launcher
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
	- Unlocks the Taser C2 Series Stun Gun and the S10 Helmet
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

# HOW TO PLAY IN MULTIPLAYER #

## Using GameRanger (preferred) ##
BOTH PLAYERS will need to do the following:
Download and install GameRanger. It can be found at http://gameranger.com
Next, GameRanger will automatically detect SWAT 4 and SWAT 4: The Stetchkov Syndicate, if all is OK.
You may need to manually detect these, if GameRanger doesn't do it for you.
You will need to rename the LaunchSEF.exe in SEF/Extras to SWAT4X.exe so Gameranger will recognize it. (It's named LaunchSEF.exe so that it isn't automatically detected!)
Then, you will need to modify the Stetchkov Syndicate game in Gameranger so it points to the Swat4X.exe file in SEF/Extras/Swat4X.exe.

THE HOST will need to do the following:
Create a game room, as a SWAT 4: The Stetchkov Syndicate game. (TIP: if this is going to be a publicly joinable game, be sure to mention it's using the SEF mod and specify the version!)
When enough players have joined, press the Start Game button. This will launch the game. From here, go to the Host Game menu and start up a server.
Important Note: Do not launch as a dedicated server while using GameRanger.
The other players will automatically connect to your game while you are loading the map.

THE CLIENT will need to do the following:
Join a public game, or your friend's game. That's all you really need to do.

### TROUBLESHOOTING ###
**NOTE: If you have the mod installed incorrectly, LaunchSEF.exe won't work!**

Make sure you have the Microsoft Visual Studio 2017 Redistributable. It is required to run LaunchSEF.exe and other applications. Download it here:

* **64-bit Windows:** https://go.microsoft.com/fwlink/?LinkId=746572
* **32-bit Windows:** https://go.microsoft.com/fwlink/?LinkId=746571

If GameRanger "aborts" when it launches, you may have some application (antivirus?) interfering with LaunchSEF.exe. If this happens, copy all .exe and .dll files from `ContentExpansion/System` into `SEF/System` and point GameRanger to the Swat4X.exe that is in `SEF/System`. This is kind of an ultra last resort option however!

## Traditional Method (TCP/IP) ##
SWAT: Elite Force v4 was the first version of this mod to allow for multiplayer play. v5 introduced Campaign CO-OP and allowed for publishing of games to Swat4Stats without a CD-key (removing DRM that GOG didn't).

### If you want to join a game: ###

If the game you want is not hosted via LAN, then you will need the SWAT4Stats server browser plugin. It's available at http://swat4stats.com - make sure you get the TSS version.

After it is installed, your server list will show all of the servers, including the ones that are on different mods. Just join the one you want. There are a number of 24/7 SEF servers out there.

If the game you want is hosted via LAN, or you cannot find the server in the list, you will need the host's external IP address (have the host look this up on http://myexternalip.com). You can then join the game from the Join Game menu using the IP address.

### If you want to host a game ###

First, you will need to open some ports on your router: 10480 - 10483, TCP/UDP. If you aren't sure how to do this, the following article explains it well: https://www.howtogeek.com/66214/how-to-forward-ports-on-your-router/

**OPTIONAL:** If you want your game to be publicly visible on the master server list (on swat4stats), you will need to install the Swat4Stats server browser plugin, available at http://swat4stats.com - You'll also want to set your game to be "Internet" and not "LAN" for this to work.

If you aren't playing an Internet/Swat4Stats enabled game, you will need your external IP address for other players to connect. You can look this up on http://myexternalip.com
Lastly, you need to determine what type of game you want to play. Regular CO-OP is handled through the Host Game menu ingame, but Campaign CO-OP is done through the Career menu - select a campaign and hit Career CO-OP. The "Equipment" panel will change to a "Settings" panel where you can configure a password, etc just like in Host Game.

Once you have selected your map settings and have started the server at least once, you can quickly launch a server (without going ingame) by using the Dedicated Server.bat file. You can then join the server from the Join Server menu.

## Admin System ##
Server hosts should NOT use MarkMod, SES Mod, Gez Mod, or Snitch for admin features. Those mods can introduce glitches, bugs, or crashes or break some of the features of SWAT: Elite Force. Instead, SEF includes its own admin mod which aims to combine a lot of the best features of those mods. If you are pining for a particular feature of one of those, let me know and I will work on adding it!

Administrator permissions are doled out through the use of "roles." Everyone by default is assigned to the Guest role; it is not recommended that you give the Guest role very many powers, if any at all. A player can only have one role at a time. Each role should have a unique password associated with it. To log in to a role, click on the "Admin Login" button and enter the password associated with the desired role.

Admin Roles should be assigned through the Host Game menu, when setting up the server settings.

Additionally, SEF also has an MOTD system. The only way (currently) to configure this is through the use of editing INI files. Open SEF/System/Swat4XDedicatedServer.ini. In the section titled `[SwatGame.SwatAdmin]` (at the bottom), add your MOTD lines by the following:

```ini
AutoActions=(Delay=NumSeconds,ExecuteText="Command")
```

Replace `NumSeconds` with the number of seconds (decimal number) before the command will be executed, and `"Command"` with the command text. The command text can be "print " followed by a message to print a string to chat, or "ac " followed by an admin command to execute that command.

As a trivial example, this will print three lines of text every 10 minutes:

```ini
AutoActions=(Delay=600.0,ExecuteText="[c=FFFFFF]Welcome to my server![\\c]")
AutoActions=(Delay=0.5,ExecuteText="[c=FFFFFF]I hope you have fun![\\c]]")
AutoActions=(Delay=0.5,ExecuteText="[c=FFFFFF]Please be nice to others![\\c]")
```

WebAdmin defaults to port 6000. You can access it in a web browser by going to: http://<external ip>:6000/
On the host machine, this can be reached from http://127.0.0.1:6000/

For some tools, you might want to get JSON metadata off of the server. There are two specialized addresses to pull data from. You can see an example of how the data is formatted by going to the listed addresses in your browser.
Note that all enumerations start from zero. They are updated as of v7.

 * Player data can be pulled from `<webadmin address>/json/players`. The Status field can be one of the following from this enumeration:

```cpp
enum COOPStatus
{
    STATUS_NotReady,
    STATUS_Ready,
    STATUS_Healthy,
    STATUS_Injured,
    STATUS_Incapacitated,
};
```

 * A full readout of the server's webadmin logs can be pulled from `<webadmin address>/json/log`. The Message Type field can be one of the following from this enumeration:

```cpp
enum WebAdminMessageType
{
	MessageType_Chat,
	MessageType_PlayerJoin,
	MessageType_AdminJoin,
	MessageType_AdminLeave,
	MessageType_Penalty,
	MessageType_SwitchTeams,
	MessageType_NameChange,
	MessageType_Voting,
	MessageType_Kill,
	MessageType_TeamKill,
	MessageType_Arrest,
	MessageType_Round,
	MessageType_WebAdminError,
};
```

Note that `MessageType_SwitchTeams` is also used for administrator actions, and messages sent by AutoActions are *not* included as part of these logs.
As a security precaution, note that *anyone* can access these URLs and get a message log. So you should probably not be discussing sensitive information on the server.

# CREDITS/THANK-YOUS #
* Irrational Games and Sierra for the game.
* BeyondUnreal for providing Unreal Engine 1/2/3 documentation
* Beppe_goodoldrebel for the Colt 9mm SMG models
* Immortal Fishy for many ironsight offset corrections.
* Sebastien NovA for his modified SwatEd.exe
* FrancisSwat for being gracious in giving us the SAS mod assets.
* Hellfire Entertainment for being gracious in giving us the SWAT4 1.2 mod assets.
* KevinL for a tip about Voting Screen.
* Ryo Ohki for a tip about P90 and SAW animations
* Dc247 for typo corrections in this document
* MulleDK19 for help with the Speech Recognition feature
* Yasuntei for spotting a typo
* Audio for help hosting NA servers
* Gez for producing the Gez admin mod, which I referenced a lot.
* RUNEPATRIARCH for finding some unused audio


A big massive thank-you to SS for hosting the official EU servers and providing a lot of support with the mod, including finding bugs and providing fixes for them.
Countless issues have been fixed because of him.

**Briefing Voice-Over:** LethalFeline (go check out his YouTube channel!)

**Dispatch Voice-Over:** Kita Nash (go check out her YouTube channel!)

**Adam Moretti Voice-Over:** GrimithM (go check out his YouTube channel!)

## ELITE SUPPORTERS ##
These people have generously donated money to Elite Force via Patreon. If you are interested in helping out, you can find our Patreon page here: https://www.patreon.com/user?u=4885526

* TheTCREngineer
* Jake Robinson/sandman332
* Evan Derickson
* Mad Max
* Jordan Harrison

## PUBLICITY ##
* GOG.com ran a very nice overview of our mod, you should check it out!
* PC Power Play also ran a nice overview of the mod
* GamingPastime did an excellent review of v5.3.

## WHO WE ARE: ELITE SQUAD ##
* eezstreet: Team Lead, Programming, Map Editing
* Jose21Crisis: Programming, Weapons Analysis
* Rangar: Music (Composition), Textures
* TheTCREngineer: Models
* sandman332: Programming

## RETIRED ELITE SQUAD ##
* mezzokoko: Programming
* kevinfoley: Programming, Model Editing

*... if there is anyone I missed, feel free to send me a message on Moddb, and this will be corrected. --eezstreet*

# LICENSE #
This software is licensed under the GNU General Public License v2. You can read it in more detail in the LICENSE file. The source code is freely available at https://github.com/eezstreet/SWATEliteForce
