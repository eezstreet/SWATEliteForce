#### v6.4
 - Added the option to go without helmet/armor/tactical items, for keeping weight and bulk low. (You must still pack both weapons)
 - Nerfed flashbang damage and damage radius (stun properties unaffected)
 - DuPlessi's civilians now bleed out on a 15-25 minute timer, instead of a 10-15 minute timer.
 - Empathy morale modifiers are now based on line of sight and don't affect everyone in the same room at once.
 - Lightsticks are now colored based on team. (Lead in Singleplayer uses green lightsticks)
 - AI-controlled officers no longer stare at/watch restrained targets.
 - Added a new tab to the Host Game menu: Voting. From this tab, you can enable/disable voting, as well as enable/disable specific kinds of voting, such as Ban and Map votes. There are also other settings, like how long a vote takes, etc.
 - Added a new tab to the Host Game menu: Equipment. From this tab, you can disable specific equipment and pick a designated "less lethal" loadout. Disabled equipment will not show in the Loadout menu.
 - The chat log and admin logs have been merged together.
 - Added the option to have either multiple logs per day, or one large chatlog.
 - Added the option to configure the chatlog name (in SwatGuiState.ini)
 - The log now removes colored/bold/italic/underline tags, for better readability.
 - Greatly improved the speed (and in multiplayer, reduced the bandwidth) of opening the equipment page and switching tabs.
 - Location data in the chat can now be turned off (for the server) in SwatGuiState.ini
 - Voting settings are now stored in SwatGuiState.ini (instead of Swat4x/Swat4xDedicatedServer.ini)
 - Tweaked the collision of lightsticks a little bit
 - Restored a cut TSS feature where lightsticks would lose their glow and become "faded" in appearance.
 - Ingame admin logins now persist across level changes
 - Player mute status now persists across level changes
 - Added a new type of voting: Start Map
 - New admin permission: Force player to Spectator
 - New admin permission: Go to Spectator
 - New admin permission: Force Less Lethal loadout
 - WebAdmin: Now has an option to select players or map actions, in addition to performing them via command.
 - WebAdmin: Now displays tags ([b], etc) correctly.
 - WebAdmin: Now has messages colored in a similar way to how they are ingame.
 - WebAdmin: Now shows the friendly name of the weapon that killed/incapacitated someone, instead of the class name (ie, "HK33" instead of "SwatEquipment.HK33MG")
 - WebAdmin: When entering a command wrong, it lists the usage of the command instead of silently failing.
 - WebAdmin: Added commands /forcespec, /switch, /nextmap, /startgame, and /abortgame, /forcell.
 - WebAdmin: Minor look/feel changes
 - Fixed SEF bug: When a player dies, it lists the killer instead of the person who died as "fallen"
 - Fixed SEF bug: When a target is incapacitated with a taser or a C2 explosion, it states "None.None" as the damage type.
 - Fixed SEF bug: When a target is incapacitated or killed with beanbags, direct grenade impacts, or triple baton rounds, the damage type was blank.
 - Fixed SEF bug: When a player triggers a trap, the penalty message does not show their name.
 - Fixed SEF bug: Bulk amount could go negative on the display
 - Fixed SEF bug: The admin panel player list would reset which player was selected constantly
 - Fixed SEF bug: Sometimes your equipment would change back to being an AKM/Browning Hi-Power in Multiplayer.
 - Fixed SEF bug: Wedges weighed less than they were supposed to.
 - Fixed SEF bug: Heavies would not show their skin properly in multiplayer games.
 - Fixed SEF bug: Server crash on GetRoomName
 - Fixed SEF bug: Typo in the X2 Stun Gun description
 - Fixed SEF bug: Heavy Armor health amount was stuck at 100% in multiplayer
 - Fixed SEF bug: Some stuff was not greyed out in the Admin panel when a player viewed the "Server Setup" tab like it should have been
 - Fixed TSS bug: In CO-OP, suspect skins were visible but not usable (now, all skins can be used in co-op)

#### v6.3
 - Added a new weapon: Suppressed P90
 - The Uzi, TEC-9 and AKM have flashlights now. (The TEC-9 always did, and does not have a modified model)
 - Tweaked the position of the P90 flashlight
 - Added a new option in multiplayer: Show kill messages. When this checkbox is ticked, arrests, kills, incapacitations, and player deaths are shown.
 - Penalty messages in multiplayer now show up as chat messages, and don't hide the chat when shown. (The penalty message in Singleplayer remains the same)
 - Added a new ingame Admin panel. From this panel, you can now kick, ban, go to the next map, etc. All players can use it, but only actions which can be carried out by their current role will be selectable.
 - Added a new WebAdmin panel. The WebAdmin can currently only be used to chat with players and check the server status.
 - Added a new Chat Log feature. When enabled (in Admin section of Host Game menu), all of the chat will be saved to a file: SEF/System/chatlog_YYYY_MM_DD.txt, where YYYY is the year, MM is the month, and DD is the day.
 - Added a new Admin Log feature. When enabled, all administrator actions will be saved to a file named SEF/System/adminlog_YYYY_MM_DD.txt.
 - New Admin privilege: Lock/Unlock teams.
 - New Admin privilege: Lock/Unlock a player's team.
 - New Admin privilege: Force all players to red/blue
 - New Admin privilege: Force a player to red/blue
 - New Admin privilege: Mute a player
 - New Admin privilege: Promote a player to leader
 - New Admin privilege: Kill a player
 - Campaign unlocks are now handled in SwatCareerPath.ini instead of SwatGuiState.ini so patches will not destroy server admin information
 - Adjusted a lot of the training mission text to better integrate TSS and SEF features.
 - The LaunchSEF.bat script will now check to make sure that the mod is installed correctly before launching. If it is not, it will give a detailed explanation as to how to fix the problem.

#### v6.2
This is a quick fix patch to address some bugs.

 - Slight optimizations and tweaks
 - Fixed SEF bug: Crash in multiplayer when using certain loadouts
 - Fixed SEF bug: Weird leg movement speed in multiplayer when using certain loadouts
 - Fixed TSS bug: Can sometimes reload the same magazine back into the weapon, in certain conditions
 - Fixed TSS bug: The password dialog box (on Admin Login) didn't support all characters


#### v6.1

 - The accuracy system has been overhauled entirely. Weapons are easier to aim in general now.
 - Added an admin system to the game, featuring customizable roles and an MOTD system. For more information, check out the "Admin System" section of "HOW TO PLAY IN MULTIPLAYER."
 - A new mechanic has been added: Empathy Modifiers. Whenever you stun a target with a less-lethal piece of equipment (taser, pepper spray, beanbags, stinger grenades, punching, ... but not CS gas, flashbangs or pepperball gun), there is a chance that nearby civilians will feel the same morale modification. This will make it much less tedious to pepper spray all civilians in a room on maps like Mt. Threshold Research Center or A-Bomb Nightclub, where there are many uncompliant civilians.
 - Bulk now affects your weapon switching and reloading speed. Having less bulk means that you will reload your weapons faster and switch between equipment faster.
 - Added a new button, 'Pick Random Map', to the All Missions mission selection screen. Clicking the button will pick a random map to play. (You can click it over and over again until you find a map that you would like.)
 - Added a Map Filter combobox to the Host Game menu. You can filter maps in the list by their source (All Maps, Custom Maps or Stock Maps)
 - When hosting a game, you can now enable/disable the timer at the beginning or end of a map.
 - Redid the lighting on Brewer County Courthouse
 - A LOT of cut speech was restored, including: "arrested" lines by the player and AI officers, lines when the player goes rogue, AI responses to commands, AI responses to dead suspects, civilian lines when shot at, and a lot of the FunTime drug dealer lines
 - Named speakers from the TSS missions will now be labeled as such in their subtitles. For example, Andrew Norman will appear as "Andrew Norman" instead of "Male Suspect" (*). Band Members from Sellers Street Auditorium are labeled as such, and aren't "Male Civilian"
 - More blood will appear when shooting something
 - Suspects are now considered threats when they move towards a hostage for the purpose of threatening them.
 - Reduced suspect and civilian field of view (120 -> 80)
 - Increased officer field of view (120 -> 180)
 - Officers now turn faster, at the same speed suspects do.
 - Officers will no longer report that they are busy when issued an order.
 - Officers react faster to suspects.
 - Officers will no longer take cover if they are very close to a suspect
 - Officers use the same take-cover time as highly-skilled suspects do
 - Officers will clear rooms quicker
 - Officers will listen to (and respond to) sounds even when they have a current enemy
 - Suspects drop their weapons when cowering
 - Suspects are no longer a threat when cowering
 - Reduced the amount of sway on the sniper scope
 - Added a little blurb of text on the Campaign menu to better explain what each career path does
 - Fixed P90 flashlight
 - Fixed M4Super90 iron sights position
 - Fixed ambient sounds and scripted conversations on Meat Barn Restaurant
 - Fixed multiplayer spawn points on Brewer County Courthouse
 - Fixed SEF bug: Wild Gunner delay not working (fixed for real this time)
 - Fixed SEF bug: Breaching ammo would never breach the door. (It now has a 50% chance to breach a metal door, and 75% chance to breach a wooden door, unless a Breaching Shotgun is used)
 - Fixed SEF bug: Some Sovereign Citizen lines did not play correctly
 - Fixed SEF bug: Magazine count display on equipment panels only showed 2 digits (so pepperball only displayed as "20")
 - Fixed SEF bug: A suspect or civilian who was cuffed and then reported, then incapacitated or killed, would count as "failed to report downed suspect" even though they were already reported.
 - Fixed SEF bug: Using the "say" command in the dedicated server or MarkMods WebAdmin panel would crash the server
 - Fixed SEF bug: Deleting a campaign wouldn't wipe its stats or permadeath status, so creating another one of the same name would result in bugs
 - Fixed SEF bug: M4A1 Suppressed in third person had a glowing silencer
 - Fixed SEF bug: HK33 had wrong model in third person
 - Fixed SEF bug: MP5SSD6 had fingers covering the iron sights
 - Fixed SEF bug: Creating a QMM with no civilians lead to a maximum score of 90/100 due to a bug in the way All Civilians Unharmed score was calculated
 - Fixed TSS bug: Spoken lines by TOC on TSS missions would cut off if the player used the shout button
 - Fixed TSS bug: Some incorrect subtitles
 - Fixed TSS bug: Using the Bulgarian Drug Worker as a suspect in QMM will no longer cause sound bugs


### v6 ###

#### MAJOR FEATURES ####

- First person improvements!
  * By hitting the zoom key, you will transition into (fully 3D) Iron Sights! While in Iron Sights, you suffer less recoil and firing your weapon affects your accuracy less. The visual representation of iron sights can be disabled in favor of the old behavior in the Game Options menu, if you prefer.
  * Lightsticks are thrown like grenades now. Chuck them across the room, or just drop them at your feet!
  * Tactical equipment (grenades, lightsticks, C2, pepper spray, wedges) now show how many you have in reserve on the HUD.
- Equipment changes!
  * The breaching tab has been removed and a sixth tactical slot has been added.
  * C2 is now considered a tactical piece of equipment, and the breaching shotgun is a weapon. The breaching shotgun will breach a door 100% of the time, unlike other shotguns where this chance is random.
  * New silenced versions of base game weapons: Suppressed M4A1, Suppressed UMP and Suppressed G36C. More weight and bulk, but won't tip off suspects in adjacent rooms when fired.
  * Added a cut weapon from the game: The M1Super90.
  * 3-packs of Wedges, Flashbangs, CS Gas and Stingers have been added. They have 3 tactical items, with the equivalent weight and bulk of five of those items.
  * All shotguns now have Frangible Breaching Ammo, which doesn't ricochet or overpenetrate a door.
  * The gas mask is now called the Respirator and no longer restricts field of view. A new gas mask, the S10 Helmet, has been added!
- Command interface overhaul!
  * New commands: SEARCH AND SECURE, SECURE ALL, RESTRAIN ALL, and DISABLE ALL.
     * SECURE ALL, RESTRAIN ALL, and DISABLE ALL will secure all evidence, restrain all compliant hostages/suspects, or disable all devices in a radius around the player, OR everything in the same room (whichever is farther, if the mission is NOT complete). SEARCH AND SECURE combines all three of these commands.
  * The lightstick commands got moved back to the DEPLOY submenu, and all of the DEPLOY commands were reorganized based on how frequently they are used.
  * The Classic Command Interface (CCI) has had all of its commands reorganized to play better.
- More AI improvements!
  * High skilled suspects are much more dangerous.
  * Enemies have figured out how to equip heavy armor! Your AP rounds will be very important.
- Menu improvements!
  * You can now apply a single tab (or a whole loadout) to another officer, another team, or element. It's much easier now to keep a consistent loadout amongst your men.
  * You can now select which entrance to use in an All Missions campaign.
  * You can now vote (in multiplayer) to end the current map, or to go to the next map. You can also vote in Career CO-OP mode.
  * The Join Game menu now won't show duplicate servers, the player sorting is better, and there is a link to download the server browser plugin.
  * The main menu now has a link to Discord and the Wiki and shows the mod version.

### ALL CHANGES ###
- Added Brewer County Courthouse mission, with new, fully voiced enemy types, new music, scripted sequences, and more.
- Added ironsights to most weapons; several weapons have had their first person weapon model tweaked to have right-side faces and other improvements.
- Added broad-secure commands (SEARCH AND SECURE, SECURE ALL, RESTRAIN ALL, DISABLE ALL)
- Added first person weapon inertia (weapon sways with movement). Disabled by default, enable through Game Controls in Settings.
- Added Suppressed M4A1
- Added Suppressed G36C
- Added Suppressed UMP
- Added M1Super90
- Added S10 Helmet
- Added M870 Breaching. It will always breach a door 100% of the time.
- Added Wedge 3-Pack, CS Gas 3-Pack, Flashbang 3-Pack, and Stinger 3-Pack.
- Lightsticks are now treated the same as grenades, instead of being an instant-use item.
- C2 is now considered a tactical item.
- Breaching tab removed; sixth tactical slot added.
- Added frangible breaching ammo for all shotguns. Frangible breaching ammo is guaranteed to never overpenetrate a door and is better against unarmored targets than the comparable Sabot Slug.
- AI will now drop lightsticks as they clear rooms.
- Improved textures for MP5, UMP, M870, M870 Less Lethal, MP5SSD6 and G36K
- The Gas Mask has been renamed Respirator and no longer restricts your field of view.
- Tactical items (grenades, wedges, lightsticks, C2) now show the number of items left when equipped.
- You can now select which entry point to use on an All Missions Campaign by selecting it in the Mission Selection menu.
- Rewrote the voting code from scratch. No longer allowed to vote for gametype; can vote to end current map or to go to next map.
- Can vote in Career CO-OP if "Enable Voting" is checked in the map settings panel. (Voting specific maps and voting for next map are not allowed in this mode)
- The breaching shotgun fire interface will now show for all shotguns, not just the breaching shotgun.
- The pick lock fire interface will now show if you have a shotgun equipped.
- Drastically improved the layout of commands in the Classic Command Interface (CCI)
- Added the ability to assign the currently selected tab to an officer, team, or Element.
- You can now assign the current loadout to an officer, team, or Element.
- Pepper spray now shows the number of reserve cans when equipped (press the Pepper Spray hotkey to swap canisters once one is depleted)
- Reorganized DEPLOY command sub-menu
- Suspects will fire upon hostages twice as quickly.
- St. Micheal's Medical Center will spawn more suspects in Multiplayer modes and also spawns heavy enemies.
- Custom Maps which use St. Micheal's Medical Center or Mt. Threshold Research Center suspects will no longer have those suspects be insane, in order to prevent custom maps from becoming too difficult to play
- High skill suspects are more likely to react to a thrown grenade now.
- High skill suspects have much better accuracy.
- High skill suspects will fire more rounds in a full-auto burst.
- High skill suspects are less likely to flinch when affected by shots.
- Suspects firing from cover may pause or regroup between shots.
- Wild Gunners are now affected by the firing delay that SEF introduced.
- Reduced the volume (slightly) of the M16 Third Person fire effect, and the dispatch audio for Meat Barn.
- Removed the physics timer from lightsticks; they will now always retain their physics instead of losing them after 10 seconds.
- Suspects will wait much less time between firing shots.
- Altered the first person model of the HK33 so it can be aimed correctly with the iron sights.
- Using grenades (not lightsticks) will now return the player to the last weapon they used, instead of the primary weapon always.
- Wedges now return the player to their weapon after they are used.
- Mod version is now shown in the main menu
- Added a Discord and Wiki button to the main menu
- Removed the CHECK FOR PATCH button in the server browser; added a DOWNLOAD PLUGIN button.
- Removed map filter from server browser filter menu (was causing lag)
- C2 now triggers dynamic music (like grenades and the AI shooting does)
- In CO-OP, instead of the Ready button disabling the Equipment panel, hitting the Equipment button will automatically Un-Ready yourself.
- SWAT 4 + TSS now selected as the default campaign path (instead of Extra Missions)
- Added a console command to change the position of the weapon in first person.
- Externalized the position of the weapon in first person and in iron sights.
- LaunchSEF.exe now works correctly on Windows XP.
- Cut Content Restored: M1Super90 Defense shotgun added
- Cut Content Restored: Enemies will now use the unused "ReportedBarricading" lines.
- Fixed SEF bug: AI-controlled officers would try and take cover when an enemy was at point-blank range, instead of firing at them.
- Fixed SEF bug: Wedges not depleting weight when used
- Fixed SEF bug: AI-controlled officers were more focused on falling in than engaging suspects at times.
- Fixed SEF bug: Beanbag shotguns tended to not work correctly.
- Fixed SEF bug: New shotgun ammo types (0 buck, 1 buck, 4 buck) didn't have correct drag values.
- Fixed SEF bug: Suspects would shoot at you while fleeing even if they couldn't hit you.
- Fixed SEF bug: Reynolds couldn't have Optiwand equipped if it wasn't in his fifth tactical slot.
- Fixed SEF bug: Picking an All Missions Campaign and then going to the Play Quick Mission menu resulted in the UI thinking that you were playing your campaign again.
- Fixed SEF bug: Picking Career CO-OP and then going to the Play Quick Mission menu resulted in the UI thinking that you were playing Career CO-OP again.
- Fixed SEF bug: Lots of equipment was missing from selection in Quick Missions.
- Fixed SEF bug: Quick Missions which had locked loadouts still let you pick which weapon to use.
- Fixed TSS bug: Can't order Secure Evidence/Restrain at the same time as a disable command.
- Fixed TSS bug: Duplicate servers in the server browser
- Fixed TSS bug: Weird player count sorting in the server browser
- Fixed TSS bug: Lightsticks don't drop if the player is wearing heavy armor
- Fixed TSS bug: If a suspect unlocks a door, it will still be "known" as a locked door.
- Fixed TSS bug: Pathing error with Jackson on Fairfax Residence, videotape room
- Fixed TSS bug: The enemy "CallForHelp" speech was rarely/if at all triggering.
- Fixed TSS bug: The enemy "AnnouncedSpottedOfficerSurprised" speech now plays.
- Fixed TSS bug: Applying a loadout to the whole team while in a Quick Mission which has locked loadouts no longer works; it will prevent it from applying to locked officers.
- Fixed TSS bug: Enemies could (rarely) spawn in an unreachable spot in The Wolcott Projects
- Fixed TSS bug: Hostages that spawn on the train platform (in Fresnal St. Station) could scream endlessly after a suspect escaped.
- Fixed TSS bug: Unreachable mirror point near the train platform in Fresnal St. Station (removed)

### v5.3 ###
Special thanks to kevinfoley, who made a lot of changes here. His contributions are marked with [kf]

- Rewrote SpeechCommands grammar file from scratch (see SpeechCommands.md for changes) (kevinfoley helped with this)
- Added missing speech commands from v5 (for specifying breaching method)
- Minor optimizations regarding the optiwand
- Snipers now report when they've lost sight of entry team on all maps, not just Qwik Fuel (they only do this once)
- Another possible fix for the RotateAroundActor crash
- Improved the quality of shadows on the highest Shadow Quality setting. [kf]
- Flashlights have a smaller cone but longer range [kf]
- On the highest Shadow Quality setting, more things (such as AI-controlled officers, guns, etc) will cast shadows [kf]
- In All Missions campaigns, it will display the author of the map and a short description (if available) in the Mission Selection menu
- Chat messages now display the room name of where they were spoken from (except when spectating or in pregame)
- In the Classic Command Interface (CCI), a lot more commands will return you to the main screen, including PICK LOCK and MAKE ENTRY commands.
- In the Classic Command Interface (CCI), issuing a command will *immediately* return you to the main screen (if it does this to begin with) instead of waiting for Lead to finish talking.
- Cut content restored: Blood spray texture that was not used [kf]
- Fixed SEF bug: Sniper rifle not firing in multiplayer
- Fixed SEF bug: Sniper rifle viewport not controllable on listen servers
- Fixed SEF bug: Breaking a door with the breaching shotgun (in a dedicated server/multiplayer) would sometimes not disable the antiportal
- Fixed SEF bug: Officers were reporting that they lost their contact way too often [kf]
- Fixed SEF bug: Missions not sorted alphabetically sometimes in an All Missions campaign
- Fixed SEF bug: Restart Mission button not working correctly in an All Missions campaign
- Fixed SEF bug: Officer in a T-pose after returning to main menu after completing a mission in an All Missions campaign
- Fixed SEF bug: High-scores not saving in All Missions campaign
- Fixed SEF bug: The drag (bullet damage loss over distance) property was being calculated wrong and adding drag to bullets twice when they passed through objects.
- Fixed SEF bug: Some commands missing from the main command menu in Multiplayer
- Fixed SEF bug: Some commands being greyed out in the main command menu in Multiplayer
- Fixed TSS bugs: The AI target sensor got rewritten from scratch, fixing the following TSS bugs:
	- SWAT AI unable to hit things at very close distances
	- SWAT AI not taking range into account when firing pepper spray, taser, etc
	- SWAT AI could sometimes shoot hostages/suspects who were in the way of their target
- Fixed TSS bug: Doors broken with shotgun by AI would have a delay before they appeared broken to the player - this is fixed. [kf]
- Fixed TSS bug: Officers don't reply when ordered to cover an area, they just do it
- Fixed TSS bug: Wrong caption on QUICK OPTIONS/ADVANCED OPTIONS tabs in the Host Game menu

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