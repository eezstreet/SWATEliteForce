# ALL CHANGES

This file attempts to document all of the changes made in the mod, although it may be out of date.

## TSS BUGS FIXED
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
 * Players could not melee with handcuffs after pressing zoom (despite zoom doing nothing)
 * Players on the red team using the default skin looked like suspects
 * You no longer take limb damage when in God Mode (cheat)

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
  * Custom player skins can now override the first person hands texture.

## GUI ##
  * Training mission returns! New Features menu from the Expansion is gone.
  * "Disable Initial Dispatch" option in Audio Settings lets you skip the initial dispatches.
  * "Mouse Smoothing" checkbox in Control Settings enables (default) or disables mouse smoothing.
  * "Field of Vision" slider in Video Settings lets you change the field of vision. There's also one to control the first person weapon model's field of vision.
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
  * Restored the vanilla SWAT 4 music (the TSS music is just reused from missions..)


## EQUIPMENT ##
All weapons have been changed to have correct muzzle velocities.
* Grenade Launcher:
  - Given real world name (HK69)
  - The AI can now use it correctly when ordered a command which uses gas/flashbang/stinger.
  - Greatly increased damage dealt from direct impact. But now it scales linearly over distance; so a point blank shot does much more damage. After some distance, grenades stop doing damage.
  - Damage is now required to trigger the direct impact stun effect.
  - May now be equipped as a secondary weapon
* Colt M4A1 Carbine:
  - New ammo types: AP, JSP
  - Four variants in total (M4A1, Suppressed M4A1, M4A1 w/ Aimpoint, Suppressed M4A1 w/ Aimpoint)
  - Retextured and remodeled
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
  - Retextured, remodeled
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
  - Corrected wrong looking first person; remodeled and retextured
  - Has a suppressed counterpart
* Gal Sub-machinegun
  - Now has a flashlight
  - New ammo types: AP, JSP
  - Corrected wrong name (is now Silenced Uzi)
  - Updated description
  - Retextured and remodeled
  - May now be equipped as a secondary weapon
  - Only available in Multiplayer and All Missions
* 9mm SMG
  - New ammo types: AP, JSP
  - Given real world name (MP5A4)
  - Added automatic firing mode
  - Updated description
  - Retextured and remodeled
  - Fixed incorrect magazine size for FMJ (holds 30 rounds, not 25)
* .45 SMG
  - Given real world name (UMP)
  - New ammo types: AP, JSP
  - Updated description
  - 2-round burst mode added
  - Retextured and remodeled
  - Now has a silenced counterpart
* M1911 Handgun
  - New ammo types: AP, JSP
  - May now be equipped as a Primary Weapon
* 9mm Handgun
  - Given real world name (Glock 17)
  - New ammo types: AP, JSP
  - May now be equipped as a Primary Weapon
  - Retextured and remodeled
  - Corrected bad hand position
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
* Cobra Stun Gun:
  - Changed the name (TASER C2 Series Stun Gun)
  - Changed the description
  - Reduced the range (The C2 series can only fire up to 15 feet)
  - Like the TASER stun gun, the Cobra stun gun has a chance to incapacitate or kill hostages.
  - May now be equipped as a Primary Weapon
* Colt Python:
  - New ammo types: AP, JSP
  - May now be equipped as a Primary Weapon
  - May now be used in singleplayer
  - Touched up the model
* Sting Grenade:
  - Doubled the radius of effect and vastly increased damage to be more realistic
  - All equipment that reduces the effect of sting grenades in MP also works in singleplayer
  - Can detonate pipe bombs, oxygen tanks, and gas cans
  - Can be passed to teammates
  - Lists the amount you have left on the HUD
* Flashbang:
  - Increased the damage and radius to be more realistic
  - Can detonate pipe bombs, oxygen tanks, and gas cans
  - Can be passed to teammates
  - Lists the amount you have left on the HUD
* CS Gas:
  - Increased area of effect
  - Reduced morale modification
  - Can affect the player in singleplayer.
  - Can be passed to teammates
  - Lists the amount you have left on the HUD
* Helmet:
  - Renamed to Tactical Helmet
  - Provides protection against flashbangs in singleplayer
* Gas Mask:
  - Renamed to Respirator
  - View obstruction effect removed
  - Provides protection against CS gas in singleplayer
  - Can be passed to teammates
* Lightstick:
  - Is colored based on team
  - Doubled in quantity
  - Can be thrown like grenades now. They are held in the hand. (The original behavior is preserved via a separate hotkey.)
  - Can fade out (cut feature from TSS)
  - Can be passed to teammates
  - Lists the amount you have left on the HUD
* C2:
  - Now available as a Tactical item (Breaching tab has been removed and replaced with a sixth tactical slot)
  - Increased the damage radius, stun angle and stun radius. It is riskier to use C2.
  - Can be passed to teammates
  - Lists the amount you have left on the HUD
* Pepperball Gun:
  - May now be equipped as a Secondary Weapon
  - Less effective in general now
* Less Lethal Shotgun:
  - Now called the Less Lethal Nova
  - Can incapacitate or kill subjects at point blank range
  - Cleaned up the model and texture (fixed smoothing groups, more accurate pump shape, slight barrel taper, added right side of the model)
* M4Super90:
  - Now fires in a spread that isn't dictated by crosshair accuracy
  - May now be equipped as a Secondary Weapon
  - Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck, Frangible Breaching
  - Renamed "12 Gauge Slug" -> "Sabot Slug"
  - Corrected magazine size (5 -> 7). SWAT 4 uses the magazine size from a civilian version of the shotgun. The Law Enforcement and Military models have 7 round magazines.
  - Can breach doors; chance to breach is dependent on ammo type
  - Touched up model
* Pepper Spray:
  - Can be passed to teammates.
  - Now correctly lists the number of extra cans you have available on the HUD
* Nova Pump:
  - Now fires in a spread that isn't dictated by crosshair accuracy
  - Corrected invalid magazine size (8 -> 7)
  - Added new ammo types: 000 Buck, 0 buck, 1 buck, 4 buck, Frangible Breaching
  - Renamed "12 Gauge Slug" -> "Sabot Slug"
  - Can breach doors; chance to breach is dependent on ammo type
  - Cleaned up model and texture (fixed smoothing groups, more accurate pump shape, slight barrel taper, added right side of the model)
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
  - MP5SSD5: A silenced-only version of the MP5 with a better suppressor.
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
**WARNING:** This section contains spoilers.

Missions are listed in order that they occur. Morale has been modified across the board.
Equipment has been revised and altered to be more in line with what the briefing describes.
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
  - Fixed the highground volume on the roof not triggering properly
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
  - Fixed a bug with the expansion where some scripted gunshot sound effects don't trigger
  - Unlocks the Riot Helmet

* Northside Vending and Amusements
  - CAUTION! May contain traps.
  - Restored a cut conversation between Lead and TOC upon tripping a trap
  - Restored a cut conversation where Red Two would muse about how much money the laundromat was making
  - Some doors were opened that are now closed. Likewise, some doors that were closed by default are now open.
  - Fixed a bug where the front door had MAKE ENTRY commands on the wrong side (unless you want to MAKE ENTRY into an alleyway..?)
  - Fixed a bug with the expansion where some scripted gunshot sound effects don't trigger
  - The laundromat door now has MAKE ENTRY commands assigned to it (since you are entering the laundromat, after all)
  - Louis Baccus is Fearless
  - All suspects are Polite
  - Made loading screen text consistent with other missions ("1092 Westfield Road, Northside Vending" -> "1092 Westfield Rd., Northside Vending and Amusements")
  - Unlocks the FN P90 PDW

* Red Library Offices
  - Made loading screen text consistent with other missions ("732 Gridley Street, Red Library Inc." -> "732 Gridley St., Red Library Inc.")
  - Suspects can now spawn with similar gear as what can be seen in the loading screen.
  - Unlocks the Colt Accurized Rifle

* Seller's Street Auditorium
  - Restored a cut 911 call that was mistakenly disabled in the vanilla game.
  - All of the static drug bags were removed. They have been replaced with drug evidence which can be collected.
  - Andrew Norman is Insane and has a very small chance to die from the taser
  - Made loading screen text consistent with other missions ("The Sellers Street Auditorium, 1801 Sellers St" -> "1801 Sellers St., The Sellers Street Auditorium")
  - Unlocks the UMP 45 and the MP5SSD5

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
  - Restored cut conversation between Lead and TOC where TOC says how many bombs are present
  - Made loading screen text consistent with other missions ("Government Plaza, Offices of the Department of Agriculture, 2112 Geddy Avenue" -> "2112 Geddy Ave., The Department of Agriculture")
  - Unlocks the SG552 Commando and the Suppressed SG552 Commando

* St. Micheal's Medical Center
  - The Terrorists are Insane
  - Hyun-Jun Park's Security Detail are Polite and will *never* attack
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
  - The suspects can ***all*** wander around the map randomly, making this mission particularly messy.
  - The civilians are Fearless
  - The civilians have a very small chance to die from the taser
  - The suspects are Polite
  - Made loading screen text consistent with other missions ("Stetchkov Drug Lab, 653 Tovanen St." -> "653 Tovanen St., Stetchkov Drug Lab")
  - Unlocks the Taser C2 Series Stun Gun and the S10 Helmet

* Fresnal St. Station
  - Cut content restored: Conversation where Lead tells TOC they found Officer Wilkins
  - The elderly have a chance to die from the taser
  - Fixed a long-annoying issue where civilians would not recognize that suspects fled off the map and keep screaming
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
  - Fixed an issue where suspects on this map had over 9x the amount of morale they were supposed to.
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