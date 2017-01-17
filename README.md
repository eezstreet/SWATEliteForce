# INTRODUCTION #

SWAT 4 is a fantastic game. It took all of the shortcomings of SWAT 3 - mainly the poor GUI and lack of realism and made it into a nicely packaged product.

Unfortunately it's very apparent that this game was rushed. There's tons of bugs, especially in multiplayer, and a cursory glance at the files reveals loads of missing content that never made the final cut of the game.
I spoke to one of the programmers - Terrance Cohen - through email, about the game. They received a great deal of input from SWAT and police alike to make the most realistic game that they could but ultimately had to cut quite a bit of their original vision down to make the game more appealing towards...well, gamers.
I think I could do better.
There are very many glaring inaccuracies with the game. For starters, the game doesn't penalize you for killing hostages with the snipers, which I think is silly. Suspects have a much greater variety of behaviors and are made to be more realistic. There's some rather baffling logic here. You can't equip your officers with gas masks and the ammo pouch doesn't display what actually happens with your weapons.

Enter SWAT Elite Force.
I originally wanted to try and market this mod as a police officer trainer, but I stopped getting interest in the project after encountering some bugs. I picked the game up again and started playing on |ESF| and remembered this mod. So, I started work on it again and took a much harder look at the engine, trying to figure out how everything works, and resumed work on it. I think I've got it to the point where people would really like it.

I wish I could do more with the game. I'm not an artist by any means, so a lot of the other things that I wish I could do (TASER rounds for shotguns, fixing a lot of the bad bump maps and flat shaded textures) aren't in the pipes. I do plan on dabbling with maps at some point, so there may be a custom campaign. I may include some community maps as part of the new campaign.

# HOW TO INSTALL #
Copy the folder containing this folder (SEFMod) into your SWAT 4 directory (the one containing Content and ContentExpansion).
By default this folder is located in C:/Program Files (x86)/SWAT 4 or C:/Program Files (x86)/Sierra/SWAT 4

To run the game, use the "Launch SEFMod.bat" file. To run SWATEd, use the "Launch SwatEd.bat" file.
You can make a shortcut to these .bat files for more convenience.

# VERSION HISTORY #

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
  * The ammo bag tactical aid has been removed. Instead you can now customize the amount of ammo you want to bring, to fine-tune your weight and bulk.
  * Weapons have been given more realistic rates of fire and muzzle velocities. In terms of gameplay, higher muzzle velocity = more potential for penetration. Most weapons got reduced muzzle velocity, except for the P90, TEC-9 and UMP.
  * Bullets can now ricochet off of hard surfaces, such as concrete, stone, bricks, etc. Ricochets occur from FMJ and buckshot rounds. (This feature will be improved as more research is done)
  * All secondary weapons are available in primary weapon slots.
- New set of commands in singleplayer: LEADER THROW. These commands allow you to use a grenade instead of your AI companions.
  * For hold commands, when the INITIATE command is done, officers will blow/open the door, and will only enter after you use a grenade. Therefore, you only need one grenade for a double entry.
  * These commands work for both thrown grenades and the grenade launcher, and they're "one-command-fits all" (OPEN, LEADER & CLEAR accepts flashbangs, CS gas and sting grenades without needing to pick in the menu)
- Suspect AI got a slight nerf to be more realistic
- The console has been improved.
- Completely redid all of the campaign progression/unlocks.
- Texture packs can now be used in online games.
- You can now lock doors using the toolkit.

#### MINOR FEATURES / FULL CHANGES ####
- Added Meat Barn Restaurant extra mission
- Applied weight and bulk to every piece of equipment.
- Removed all CD key checks from the game. (They were bugged, and this game can't be purchased legally anymore.)
- Removed checksum for all Unreal packages - so now you can play online with custom models, textures, etc. [In theory]
- Multiplayer Setup: Server name field raised to 128 characters (up from 20)
- The console will no longer close after entering a command. (Close with ESC key instead)
- The console will show a log of commands entered as well as output.
- Added a new console command: "history" (toggles the console log)
- New penalty: Tased a fellow officer
- Moved a few strings from SwatProcedures.ini to SwatProcedures.int so they can be localized correctly
- Five new commands: LEADER THROW & CLEAR; OPEN, LEADER & CLEAR; OPEN, LEADER & MAKE ENTRY; BREACH, LEADER & CLEAR; BREACH, LEADER & MAKE ENTRY. These commands let you throw the grenade instead of the AI doing it.
- When an AI is issued a BREACH command, and they are out of breaching equipment, they will now only pick the lock when the door is locked, instead of always picking the lock.
- The toolkit interface no longer shows up for doors that cannot be locked (e.g, all of the doors on St. Micheal's Medical Center)
- The toolkit can now be used to lock doors.
- Redid all of the campaign progression/unlocks
- Removed the VIP Colt M1911 (for now)
- Added "Take Screenshot" option to controls menu
- Civilians are now not ridiculously noncompliant like they were before
- Greatly increased the effectiveness of Stinger grenades against Hostage and Suspect morale. They're as good as Tasers now.
- Greatly increased the area of effect for Stinger grenades.
- Doubled the duration of effect for CS gas but greatly reduced its morale modifier
- Slightly increased the effectiveness of Tasers against Suspect morale
- Slightly increased the effectiveness of bullets against Hostage morale
- Slightly reduced the effectiveness of C2 against Hostage morale
- Removed a slight (< 1 second) delay from AI being affected by Stinger and Flashbangs. (it still exists for CS gas)
- Reduced duration of effect of Pepperball gun by 50%
- FMJ and buckshot can now ricochet off of hard surfaces
- Suspects will now have a slight delay before firing upon SWAT officers. Depending on how skilled the suspect is, it can range between 0.3 and 0.9 seconds.
- Incapacitation health increased from 20 to 30, so incapacitation is more likely
- Suspects are more likely to play a gethit animation (so they shrug off bullets less often)
- Suspects are slightly less accurate
- All pistols are selectable in primary weapon slots.
- Ammo Bandolier item removed
- Officers get (by default) 3 primary magazines and 5 secondary magazines. The only exception is Jackson, who gets 25 shotgun shells.
- You can no longer edit your equipment in Multiplayer while you are ready. Unready yourself first.
- You can no longer ready in Multiplayer while your equipment is over weight or bulk.
- If your equipment is over weight in multiplayer, it will be replaced with the default loadout.
- Fixed TSS bug: Known locked/wedged doors weren't being taken into account when a suspect evaluates if it should flee.
- Fixed TSS bug: FunTime Amusements not having any loading screen text
- Fixed TSS bug: Glitchy arrests with No Armor
- Fixed TSS bug: Optiwand glitchy in multiplayer when near doors (unverified)
- Fixed TSS bug: Pregame not showing HTML styling of server name
- Fixed TSS bug: Glock not selectable in Custom Mission Maker
- Fixed TSS bug: Fairfax accomplice could have two of the same weapon
- Fixed TSS bug: Taser recoil applying to every player on the map
- Fixed TSS bug: Old Granite Hotel missing some flashing lights
- Fixed SEF bug: Join Game button on menu not appearing
- Fixed SEF bug: Officers picking locks on unlocked doors when ordered to breach and out of C2
- Fixed SEF bug: Riot Helmet not protecting against pepper spray like it's supposed to.
- Fixed SEF bug: Sniper rifle not accurate

#### NITTY GRITTY/TYPOS AND STATS ####
* NOTE: some very (microscopically) tiny changes to stats aren't mentioned. For instance, the Nova Pump had its muzzle velocity raised by 2 units - not noteworthy at all and hardly noticeable.
* HUGE thanks to Jose21Crisis for crunching a lot of these numbers for me.

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

Typos
- "Tripped Trap (-10)" -> "Triggered Trap (-10)"
- "Fleeing Suspect (-5)" -> "Suspect Escaped (-5)"
- "Learn to play SWAT: Elite Forces" -> "Learn to play SWAT: Elite Force"
- "Pepper-ball" -> "Pepper-ball Launcher"
- "Less Lethal Shotgun" -> "Less-than-Lethal Shotgun"
- "NIGHT VISION" -> "Night Vision"

Hostages
- Halfway House Staff: Max Morale (0.7 -> 0.35)
- Halfway House Residents (not Lionel MacArthur): Max Morale (1.5 -> 1.1)
- Halfway House Residents (not Lionel MacArthur): Min Morale (0.5 -> 0.6)
- Sellers Street Band: Max Morale (0.95 -> 1.2)
- Sellers Street Band: Min Morale (0.3 -> 0.5)
- Sellers Street Male Patrons: Max Morale (1.2 -> 0.5)
- Sellers Street Female Patrons: Max Morale (1.2 -> 0.6)
- Rita Winston: Max Morale (1.5 -> 1.2)
- Department of Agriculture Staff: Max Morale (0.9 -> 0.6)
- Drug Lab Workers: Max Morale (0.6 -> 1.1)
- Subway Homeless: Max Morale (0.2 -> 0.4)
- Subway Businesswoman: Max Morale (0.8 -> 0.2)
- Warehouse Civilians: Max Morale (1.2 -> 0.9)
- Wolcott Homeless: Min Morale (0.5 -> 0.3)
- Wolcott Homeless: Max Morale (1.33 -> 1.1)
- Louis Baccus: Min Morale (0.7 -> 0.5)
- Northside Gamblers: Min Morale (0.8 -> 0.3)
- Convenience Store Workers: Max Morale (0.4 -> 0.1)
- Theodore Sturgeon: Max Morale (1.1 -> 0.8)
- Hologen Students: Min Morale (0.5 -> 0.25)
- Hologen Students: Max Morale (1.1 -> 1.0)
- Food Wall Patron: Max Morale (1.1 -> 0.8)
- Food Wall Staff: Max Morale (1.1 -> 1.0)
- DuPlessi Security: Max Morale (0.15 -> 0.8)
- Warren Rooney: Max Morale (1.35 -> 1.0)
- Red Library Staff: Max Morale (1.15 -> 0.6)
- Gladys Fairfax: Min Morale (0.75 -> 0.3)
- Gladys Fairfax: Max Morale (1.2 -> 1.0)
- Taronne Civilian: Min Morale (0.8 -> 0.0)
- Female Taronne Civilians max morale (1.33) now matches Male civilians (1.2)

Suspects
- Javier Arias: Max Morale (0.8 -> 1.0)
- Halfway House Robbers: Max Morale (0.7 -> 0.5)
- Andrew Norman: Max Morale (0.9 -> 1.0)
- CASM: Min Morale (0.6 -> 0.3)
- CASM: Max Morale (0.8 -> 0.9)
- Angry Farmers: Min Morale (0.7 -> 0.5)
- Angry Farmers: Max Morale (0.9/1.1 -> 0.7/0.8)
- Drug Lab Workers: Max Morale (0.9 -> 1.0)
- Only the drug lab workers who wear a gas mask can die from the taser now
- Kiril Stetchkov: Max Morale (2.0 -> 1.5)
- Kiril Stetchkov: Taser Death Chance (0.35 -> 0.5)
- Alex Jimenez: Max Morale (0.6 -> 0.8)
- Lawrence Fairfax: Max Morale (0.75 -> 1.0)
- Fairfax Accomplice: Max Morale (0.75 -> 0.6)
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

#### FILES MODIFIED ####
Content/Classes/SwatEffects.u
Content/Classes/SwatProtectiveEquipment.u
Content/Classes/SwatProtectiveEquipment2.u
Content/Classes/SwatAmmo.u
Content/Classes/SwatAmmo2.u
Content/HavokData/SP-MeatBarn.mopp
Content/Maps/SP-Hotel.s4m
Content/Maps/SP-MeatBarn.s4m
Content/Maps/SP-Training.s4m
Content/Sounds/Sierra1/s1_lostcontact_extm01_1.ogg
Content/Sounds/Sierra1/s1_lostcontact_extm01_2.ogg
Content/Sounds/Sierra1/s1_lostcontact_extm01_3.ogg
Content/Sounds/Sierra1/s1_spottedcontact_extm01_1.ogg
Content/Sounds/Sierra1/s1_spottedcontact_extm01_2.ogg
Content/Sounds/Sierra1/s1_spottedcontact_extm01_3.ogg
Content/Textures/gui_tex3.utx
System/AI.ini
System/Core.dll
System/CustomScenarioCreator.ini
System/DefSwatGuiState.ini
System/DynamicLoadout.ini
System/EnemyArchetypes.ini
System/HostageArchetypes.ini
System/PlayerInterface_Command_SP.ini
System/PlayerInterface_Fire.ini
System/Startup.ini
System/StaticLoadout.ini
System/SwatEquipment.ini
System/SwatEquipment.int
System/SwatGame.int
System/SwatGui.ini
System/SwatGuiState.ini
System/SwatMissions.ini
System/SwatProcedures.int
System/transient.int
Generated code

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
Files modified:
Content/Textures/gui_tex2.utx
System/CommandInterfaceMenus_SP.ini
System/CommandInterfaceMenus_MP.ini
System/PlayerInterface_Command_SP.ini
System/PlayerInterface_Command_MP.ini
System/SwatGui.ini
System/startup.ini
System/transient.int
Generated code

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
Files modified:
Content/Maps/SP-DrugLab.s4m
Content/Maps/SP-Tenement.s4m
System/SpeechCommandGrammar.xml
System/CommandInterfaceMenus_SP.ini
System/PlayerInterface_Command_SP.ini
System/PlayerInterface_Use.ini
System/SoundEffects.ini
System/StaticLoadout.ini
System/SwatGui.ini
System/SwatGuiState.ini
Generated code

### v1 ###
- First release

# CHANGES, SUMMARIZED #

As mentioned before, there were many inaccuracies with the game. I went for those first, before addressing some of my other grievances with the game: mainly the cut content and clunky expansion pack content.
Some of the changes are as follows.
	* The Stetchkov Syndicate and base game missions are compressed into one campaign. As in The Stetchkov Syndicate, some equipment will need to be unlocked.
		** It always bothered me having to switch between the two games, so I have put them together. In the future, there will be a 'Custom Missions' campaign which have some user-created missions.
	* Suspects employ a greater variety of tactics. "Insane" suspects will shoot without hesitation at hostages. "Polite" ones on the other hand, won't make this a priority.
		** There's still some room for improvement, but I found it incredibly unrealistic that Food Wall employees would shoot at their patrons, for example.
	* Traps. This is a huge cut feature from the game. Some doors may be trapped with bombs or alarms, and you'll need to adjust your approach to deal with it.
		** This is a small thing but it has huge ramifications. Since some doors will be trapped, you will need to take alternate routes instead of using the same strategy every time. Lots of replayability and rooted in real life scenarios.
	* New secondary objective: collect drug evidence. Static drug bags have been replaced with new ones that can be collected.
		** The bags count towards the "Secure All Evidence" procedure.
	* More equipment options. This includes a few cut equipment items, such as riot helmets. You can equip your AI-controlled officers with armor of your choosing now, and they can drop more lightsticks.
		** It seems odd to me that the player could use suspect equipment in CO-OP but not in the singleplayer campaign. Also weird: you can't equip gas masks yet you're immune to gas but not flashbangs. Really odd.
	* More realistic reactions, from both suspects and civilians. Times have changed from 2004 - the public has a deeper sense of mistrust for police officers. This mod reflects that. Oh, and civilians won't scream like madmen at inappropriate times.
		** Civilians would scream if they are in the same room as a suspect. This didn't make sense on a lot of maps, such as Children of Taronne Tenement or the other High Risk Warrant missions.
	* Equipment is also much more realistic. Flashbangs are now very dangerous pieces of equipment, and TASERs can make the elderly or drug-addled go into cardiac arrest. Be careful of that.
		** It's completely unrealistic for TASERs to work 100% of the time on a civilian without injuring them. TASERs have been known to cause deaths. You will be held to a realistic standard in my mod.
	* Commands can be issued using your voice. To enable this feature, tick 'Use Speech Recognition' in the Audio Options.
		** Functions exactly the same as in the Speech Recognition Improvement mod by MulleDK9. Not all commands from that mod are present however.
	* Commands are easier to give with a new Graphic Command Interface with lots of submenus instead of a single long list. You can now issue BREACH commands on unlocked doors as well. MOVE and OPEN commands are now both available at the same time, so you can issue door commands through other doorways.
		** There's also some new commands, such as CHECK FOR TRAPS.
	* Harsher penalties. Incapacitated hostages and suspects now need to be reported to TOC; deadly force is more scrutinized and can be incurred by more means (AI controlled officers using C2 and snipers are two good examples)
		** The game seems to take some wild liberties as to what qualifies as a passing mission. You could shoot all of the suspects illegally (in some cases without getting any penalty) on Food Wall on Hard and still beat it. You would be FIRED if you did this in real life.
		** A person being incapacitated is a big deal, and an ambulance would need to be ordered. Failing to disclose this could put their lives in jeopardy, so it makes sense for this to be a penalty. It did this for officers though (?) which I found odd.
	* The game reveals much more information to you. A warning will display when you have made a penalty, and a message will show when you have completed an objective.
		** Major gripe. I hate having to pause the menu to see if I've found all the civilians. Likewise, not finding out until the end of the game that a kill (which you might have forgotten about) was illegal is extremely frustrating.
  * Multiplayer playability. For starters, annoying DRM preventing you from hosting a server has been removed. You can also use different texture packs (GEM, etc) while playing online. Tons of bugs regarding multiplayer stability have been addressed.
	* Many many many many bugfixes.

# KNOWN ISSUES #
  * Yes, the game is HARD AS NAILS. It's supposed to be. It's a police simulator and meant to train SWAT operators.
  * No new missions in Additional Missions campaign. It's still a WIP.
	* TOC won't reply when an AI-controlled officer reports something. There's lots of code that needs to be altered to make this work.
	* The game sometimes freezes during loading. Hit ENTER a few times and it will clear itself up. The internal script garbage collector crashes for reasons unknown but it's completely harmless.
  * Seems to crash in specific circumstances on doors, such as trying to blow a door that's currently being closed. Not sure if it's an original game bug.
  * Officers sometimes ignore orders, you might have to issue a command two or three times. Problem of the original game.
  * Throws an assertion when an officer ordered to restrain a civilian is ordered to disarm a bomb. Nothing I've changed would've caused it, so again, probably an issue with the original game. Also harmless.

# FULL LIST OF CHANGES #

## GAMEPLAY ##
### Missions ###
	- The Stetchkov Syndicate missions have been merged with the original SWAT 4 missions to have one linear campaign.
		* They are sprinkled in, not shoved afterwards.
		* The original missions have some order differences, such as Fairfax Residence coming before Food Wall.
	- Like The Stetchkov Syndicate introduced, each mission has equipment that is unlocked.
		* See the section titled "Changes to specific missions" for more details on what has been changed
	- When creating a new campaign, you have a choice of either using the new altered campaign or "additional missions" which were created by the community.
		* Currently incomplete (there are no maps yet, but the framework for it is built)
	- Some missions now contain traps! An (almost fully) working feature that was cut from the game for some reason.
		* Traps can be disarmed using the Toolkit, or by an AI controlled officer with the Disable command.
		* AI Controlled Officers can detect the presence of traps on a door with a new CHECK FOR TRAPS command.
	- Some missions now contain extra drug evidence! You will need to collect these to get a perfect score.
		* Drug evidence can be collected by AI controlled officers with a "Secure Evidence" command.
	- "Press ESC and debrief to exit the game" now shows on ALL missions, not just Food Wall, Fairfax Residence and Qwik Fuel.
	- When a mission objective is complete, it will notify in white text at the top of the screen.
### Score ###
	- Stiffened penalties and added new ones:
		* AI-Controlled officers using C2 can now trigger "Incapacitated a Hostage", "Killed a Hostage", "Unauthorized Use of Force" and "Unauthorized Use of Deadly Force" penalties
		* Snipers can now trigger "Incapacitated a Hostage", "Killed a Hostage", "Unauthorized Use of Force" and "Unauthorized Use of Deadly Force" penalties
		* Not reporting a downed hostage or suspect will trigger a new penalty: "Failure to report downed civilian" or "Failure to report downed suspect"
	- Removed the "Failure to prevent destruction of evidence" penalty on Funtime Amusements
	- In singleplayer, penalties are displayed in the chat as they happen.
	- Changed values of penalties:
		* "Unauthorized use of deadly force": -10 -> -20
		* "Incapacitated a hostage": -5 -> -25
		* "Killed a hostage": -15 -> -50
		* "Incapacitated a fellow officer" -15 -> -25
		* "Injured a fellow officer": -5 -> -10
		* All other penalties remain the same.
### Singleplayer ###
	- Added missing dialogue for "Open and Make Entry" command
	- If one member of a team remains (ie, Jackson is the only one alive on Blue), Lead will say their name instead of their team (so, "Jackson - Mirror Under the door)
	- Fixed a bug where AI-controlled officers could only drop one lightstick
	- Players can suffer effects of CS gas if not properly protected
		* Likewise, the player will not be harmed by flashbangs if they have a helmet
		* (Previously, the player was immune to CS gas but not flashbangs, despite having the complete opposite equipment for this)
	- AI-controlled officers will automatically report any suspects or civilians that they restrain.
	- New Features removed, Training mission brought back.
### Multiplayer ###
  - Texture packs (such as SWAT 4: GEM) can now be used online without causing problems.
### Suspects ###
	- Modified morale alters:
		"Weapon Drop" morale modifier increased substantially.
		"Flashbang" morale modifier increased
		"Gassed" morale modifier increased
		"Stung" morale modifier increased
		"Tased" morale modifier decreased
		"C2 Stun" morale modifier decreased
		"Shot" morale modifier substantially increased
		"Killed Officer" morale modifier increased
		"Nearby enemy killed" morale modifier increased for higher-skilled suspects
	- Suspects will maintain suppressive fire for twice as long when they are barricaded
	- Compliant suspects will wait longer before deciding to pick up their weapon
	- (Non-Insane/Non-Polite) suspects take twice as long before shooting hostages
	- Added a new quality: Polite. Any suspect archetype with this quality won't attempt to shoot hostages.
		** NOTE: Does not apply to Quick Mission Maker
	- Added a new quality: Insane. Any suspect archetype with this quality will shoot hostages *much* faster (basically instantly) and ignores distance checks.
		** NOTE: Does not apply to Quick Mission Maker
	- Using your Shout button on a restrained suspect will taunt them. Examples include "You have the right to remain silent," etc. Doesn't do anything, it's just an easter egg. Warning: The suspect may have some unkind words for you in return.
### Civilans ###
	- Greatly increased morale of all civilians, making them harder to give up
	- Added a new quality: Fearless. Any civilian archetype with this quality won't scream when in the same room as a suspect - only if they are threatened or there is a gunshot.
		** NOTE: Does not apply to Quick Mission Maker
	- Using your Shout button on a restrained civilian will soothe them. Examples include "It's okay, we'll get you out of here," etc. Doesn't do anything, it's just an easter egg.

## GUI ##
* New splash screen
* New Main Menu logo
* Removed all trace of Gamespy (no logo at start, no logo in Host Game, no logo in Join Game, etc..)
* Removed bugged DRM (Invalid CD-Key when hosting a game)
### Equipment Menu (SP): ###
	- Weapons now have a detailed information panel with statistics like their manufacturer, etc
	- Can now select body armor for AI-controlled officers and yourself
	- You can also select more choices for helmets, including riot helmets, terrorist helmets and gas masks
	- Cleaned up the appearance of the top tabs
	- Breaching tab on right is relabeled "BREACH AND PROTECTION" for clarity
	- Corrected typo for label on Secondary tab
		"Select secondary weapon and equipment" --> "Select secondary weapon and ammunition"
### Graphic Command Interface (SP) ###
	- Performed a drastic redesign of the menu to promote both speed and functionality
		* "Open and ..." commands have been moved to a submenu: "OPEN >>>"
		* STACK UP has been renamed to TRY LOCK
		* New command: CHECK FOR TRAPS - officers will try the lock and will report if the door is trapped. Clunky, but it works.
		* TRY LOCK, CHECK FOR TRAPS, Optiwand commands have been moved to a submenu: "INVESTIGATE >>>"
		* Due to this design, when viewing a door through another doorway, you can issue both Move and Open commands with no ambiguity.
	- Allowed the player to issue Breaching commands even when doors aren't locked
		* These are available via OPEN >> submenu
	- The GCI is now dynamic in that drop-down menus (such as "OPEN >>>") can only appear in certain contexts (OPEN will only show on doors)
	- Deploy Lightstick has been moved out of the Deploy menu (Drop Lightstick command) so they can be dropped faster
### Graphic Command Interface (MP) ###
	- OUT OF THE WAY changed to be the default for the General menu
### Career Menu ###
	- Removed "-EXP-" tag before all TSS missions in the menu
### Settings Menu ###
	- Fixed a bug where the music would get glitched
	- 'Display Subtitles' moved to Audio Options
	- 'Use Speech Recognition' option added to Audio Options
	- 'Disable Initial Dispatch' option added to Audio Options
	- Support for ~5x as many resolutions (4 -> 22)


## EQUIPMENT ##
All weapons have been changed to have correct muzzle velocities.
* Grenade Launcher:
	- Given real world name (HK69 Grenade Launcher)
	- Greatly increased damage dealt from direct impact
	- May now be equipped as a secondary weapon
* AK47 Machinegun:
	- Fixed inaccurate description
	- Fixed name (AK-47 Assault Rifle)
	- Now selectable in Singleplayer
	- 1 less magazine
* GB36s:
	- Corrected wrong name (is now H&K G36K)
	- Updated description
	- 1 extra magazine
* 5.56mm Light Machine Gun
	- Corrected wrong name (is now M249 SAW Light Machine Gun)
	- Now selectable in Singleplayer
* 5.7x28mm Submachine Gun
	- Corrected wrong name (is now FN P90 Personal Defense Weapon)
	- Completely redid the description (as it's totally wrong)
* Gal Sub-machinegun
	- Corrected wrong name (is now Silenced IMI Uzi)
	- Updated description
	- Now selectable in Singleplayer
	- May now be equipped as a secondary weapon
* 9mm SMG
	- Corrected wrong names (H&K MP5A2 SMG and H&K MP5A2 SSD)
	- Added automatic firing mode
	- Updated description
	- Fixed incorrect magazine size for FMJ (holds 30 rounds, not 25)
* .45 SMG
	- Corrected wrong name (H&K UMP SMG)
	- Updated description
* 9mm Handgun
	- Corrected wrong name (Glock 17)
	- 2 extra magazines
* Mark 19 Semi-Automatic Pistol
	- Corrected wrong name (Desert Eagle .50AE)
		NOTE: The name is technically correct (as a Desert Eagle Mark XIX is designed to fire .50 AE rounds), but I felt the need to change it
	- Fixed typo in description
	- Slightly reduced recoil
* 9mm Machine Pistol
	- Corrected wrong name (TEC-DC9 Machine Pistol)
	- Completely redid the description
	- Now selectable in Singleplayer
	- May now be equipped as a Primary Weapon
	- 2 extra magazines
* TASER Stun Gun:
	- Cut TASER stun gun probe spread by 50%
	- Changed the name (TASER M26C Stun Gun)
	- Doubled the range (The M26C and its sister weapon have cartridge variations that can fire up to 35 feet)
	- Has a chance to incapacitate or even KILL hostages if not used correctly. Avoid use on the elderly, drug-users and people with health conditions.
	- Fixed typo in description
		"The Taser stun gun works on the principal" -> "The Taser stun gun works on the principle"
* Cobra Stun Gun:
	- Changed the name (TASER C2 Series Stun Gun)
	- Changed the description
	- Reduced the range (The C2 series can only fire up to 15 feet)
		This is good for balance too!
	- Like the TASER stun gun, the Cobra stun gun has a chance to incapacitate or kill hostages.
		The double fire mode doesn't increase the chance of cardiac arrest, but it does increase lethality. Use caution.
* Colt Python:
	- Now selectable in Singleplayer
	- 3 extra magazines
* VIP Colt M1911:
	- Now selectable in Singleplayer
* Sting Grenade:
	- Doubled the range and vastly increased damage to be more realistic
	- All equipment that reduces the effect of sting grenades in MP also works in singleplayer
	- Can detonate pipe bombs, oxygen tanks, and gas cans
* Flashbang:
	- Increased the damage and radius to be more realistic
	- Can detonate pipe bombs, oxygen tanks, and gas cans
* Added two new head armor items:
	- Riot Helmet: Offers slightly less protection than the Helmet, but also reduces Pepper Spray and Gas durations
	- ProArmor Helmet: Offers highest possible protection, but confers no other bonuses.
* Helmet:
	- Renamed to Tactical Helmet
	- Provides protection against flashbangs in singleplayer
* C2:
	- Increased the damage radius, stun angle and stun radius. It is now more risky to use C2.
* Pepperball Gun:
	- May now be equipped as a Secondary Weapon
* M4Super90:
  - Now fires in a spread that isn't dictated by crosshair accuracy
	- May now be equipped as a Secondary Weapon
	- Added new ammo type: 000 Buck
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
	- Corrected magazine size (5 -> 7)
		SWAT 4 uses the magazine size from a civilian version of the shotgun. The Law Enforcement and Military models have 7 round magazines.
* Nova Pump:
  - Now fires in a spread that isn't dictated by crosshair accuracy
	- Corrected invalid magazine size (8 -> 7)
	- Added new ammo type: 000 Buck
	- Renamed "12 Gauge Slug" -> "Sabot Slug"
* Ammo Pouch:
	- Fixed misleading description (it gives ammo for all guns, not just the primary)
	- No longer affects the Less Lethal Shotgun

## MISSION CHANGES ##
WARNING: This section contains spoilers
Missions are listed in order that they occur
Morale has been modified across the board.
If an equipment is not listed as unlocked by a mission, it is unlocked by default.

* Fairfax Residence
	- CAUTION! May contain traps! (Evidence shows that they were cut from the original game on this mission)
	- Restored a cut conversation between Lead and TOC that triggers when tripping a trap
	- Restored a cut conversation between Lead and TOC that triggers when arresting the accomplice
	- Gladys Fairfax is Fearless
	- Gladys Fairfax has a chance to die from the taser
	- Melinda Kline has a very small chance to die from the taser
	- Corrected typo in mission briefing location info ("Information is specualtive regarding the basement." -> "Information is speculative regarding the basement.")
	- Does not unlock any equipment
* Food Wall Restaurant
	- The armed waiter is Polite
	- All patrons are Fearless
	- Corrected typo in mission briefing timeline ("Alex Jimenez is observed entering Food Wall Restauraunt" -> "Alex Jimenez is observed entering Food Wall Restaurant")
	- Unlocks the Nova Pump shotgun
* Qwik Fuel Convenience Store
	- Possible drugs that need collecting
	- The suspects on this mission may be carrying drug evidence.
	- Alice Jenkins is Insane and has a moderate chance (50%) to die from a taser
	- The other suspects have a decent chance (35%) to die from a taser
	- Made loading screen text consistent with other missions ("3721 Pitkin Avenue, Qwik Fuel" -> "3721 Pitkin Ave., Qwik Fuel")
	- Unlocks the Less Lethal shotgun
* FunTime Amusements
	- A penalty is no longer issued when suspects flush drugs
	- Drug flushers are Polite
	- Corrected missing loading screen text ("1401 Gower St., FunTime Amusement Arcade")
	- Corrected a typo in briefing description
	- Unlocks the Gas Mask
* Victory Imports Auto Garage
	- Made loading screen text consistent with other missions ("487 29th Avenue, Victory Imports" -> "487 29th Ave., Victory Imports")
	- Unlocks the Ammo Pouch
* Our Sisters of Mercy Hostel
	- Both entryway doors now correctly have MAKE ENTRY commands on them.
	- Locked a bunch of doors
	- The residents (elderly) have a very high chance of dying from a taser
	- Removed objective: Rescue Lionel McArthur
	- Made loading screen text consistent with other missions ("Our Sisters of Mercy Halfway House, 796 Newbury St." -> "796 Newbury St., Our Sisters of Mercy")
	- Unlocks the TASER C2 Series
* Old Granite Hotel
	- Fixed wrong snipers. Sierra 1 was where Sierra 2 is supposed to be, and vice versa.
	- Unlocks the Colt Python
* A-Bomb Nightclub
	- Possible drugs that need collecting
	- Unlocks the Riot Helmet
* Northside Vending and Amusements
	- CAUTION! May contain traps. (Evidence shows that they were cut from the original game on this mission)
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
	- Unlocks the HK69 Grenade Launcher
* DuPlessi Wholesale Diamonds
	- No changes
	- Unlocks the ProTec Helmet
* Children of Taronne Tenement
	- CAUTION! May contain traps. (Evidence shows that they were cut from the original game on this mission)
	- All civilians are Fearless
	- Andrew Taronne is Polite
	- All civilians have a very small chance to die from the taser
	- All suspects (except Andrew Taronne) have a very small chance to die from the taser
	- Made loading screen text consistent with other missions ("2189 Carrols Road, Taronne Tenement" -> "2189 Carrols Rd., Taronne Tenement")
	- Unlocks Night Vision Goggles
* Department of Agriculture
	- Made loading screen text consistent with other missions ("Government Plaza, Offices of the Department of Agriculture, 2112 Geddy Avenue" -> "2112 Geddy Ave., The Department of Agriculture")
	- Unlocks the AK-47 Assault Rifle
* St. Micheal's Medical Center
	- The Terrorists are Insane
	- Hyun-Jun Park's Security Detail are Polite and will -never- attack
	- Corrected various inconsistences in the mission strings (It's referred to as "Memorial Hospital" in the location info, and simply "St. Micheal's" in the loading screen, but "St. Micheal's Medical Center" in the voiceover)
	- Unlocks the Silenced IMI Uzi
* The Wolcott Projects
	- The homeless are Fearless
	- The homeless have a very small chance to die from the taser
	- The loading screen and dispatch are inconsistent. Dispatch says "1210 Canopy Road" while the loading screen and mission text say "Blakestone Avenue". Corrected the text to use the Canopy Road address instead.
	- Does not unlock any new equipment
* Stetchkov Drug Lab
	- CAUTION! May contain traps!
	- All of the static drug bags were removed. They have been replaced with drug evidence that can be collected.
	- All of the external doors now correctly have MAKE ENTRY commands on them.
	- Locked a bunch of doors
	- The civilians are Fearless
	- The civilians have a very small chance to die from the taser
	- The suspects are Polite
	- Made loading screen text consistent with other missions ("Stetchkov Drug Lab, 653 Tovanen St." -> "653 Tovanen St., Stetchkov Drug Lab")
	- Unlocks the TEC-DC9 Machine Pistol
* Fresnal St. Station
	- The elderly have a chance to die from the taser
	- Fixed typos in briefing timeline ("First Units Arive" -> "First Units Arrive"; "First units arive and perimeter established" -> "First units arrive and perimeter established")
	- Unlocks the Desert Eagle .50AE
* Stetchkov Warehouse
	- CAUTION! May contain traps!
	- All of the external doors now correctly have MAKE ENTRY commands on them.
	- Locked a door
	- The civilians are Fearless
	- The suspects are Polite
	- Made loading screen text consistent with other missions ("The Stetchkov Warehouse, 2770 Harrington Rd." -> "2770 Harrington Rd., The Stetchkov Warehouse")
	- Unlocks the M249 SAW Light Machine Gun
* Mt. Threshold Research Center
	- The suspects are Insane
	- Does not unlock equipment

# CREDITS #
Irrational Games and Sierra for the game.
MulleDK9 for information regarding the Speech Recognition feature.
Jose21Crisis helped a lot with weapon-related math and contributed much to the design.
Anything else was my own work.

# LICENSE #
This software is licensed under the GNU General Public License v2. You can read it in more detail in LICENSE.md.
