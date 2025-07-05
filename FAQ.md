# FREQUENTLY ASKED QUESTIONS (FAQ)

Contents:

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
First, you will need to ensure that your operating system supports Speech Recognition. What you'll need is the Microsoft Speech Recognition API, which Microsoft no longer provides. There is a public download of it available [here.](https://www.dropbox.com/s/a3y68suledr90n5/MSSpeech_SR_en-US_TELE.msi?dl=0)
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