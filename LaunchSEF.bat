@echo off
REM Author: eezstreet

REM Basic checking to make sure that the user has installed the mod correctly

REM Check to make sure the user installed the mod correctly.
IF NOT EXIST ../SEF/NUL (
	ECHO It would seem as though you've made a grave error!
	ECHO You copied the *contents* of the SEF folder from the ZIP archive and overwrote your original game's content with SEF, when you needed to copy the folder itself!
	ECHO You'll most likely need to reinstall your game. Make sure that you copy the folder next time, not the contents of the folder. You should have at least three folders: Content, ContentExpansion, and SEF, in your SWAT 4 directory.
	PAUSE
	EXIT
)

REM Check to make sure the user has the vanilla game
IF NOT EXIST ../Content/NUL (
	ECHO Couldn't find SWAT 4 data. Make sure that you have placed this folder inside of your SWAT 4 directory. These are most commonly found in:
	ECHO - C:/Program Files/SWAT 4
	ECHO - C:/Program Files (x86^^^)/SWAT 4
	ECHO - C:/GOG Games/SWAT 4
	PAUSE
	EXIT
)

REM Check to make sure the user has the expansion
IF NOT EXIST ../ContentExpansion/NUL (
	ECHO Couldn't find The Stetchkov Syndicate expansion data. Make sure that you have it installed. The GOG.com version (Gold Edition^^^) has both the expansion and base game.
	PAUSE
	EXIT
)

REM Check to make sure the user didn't install a patch
IF NOT EXIST System/Startup.ini (
	ECHO Couldn't find System/Startup.ini. This usually happens if you installed a patch of SWAT: Elite Force (v6.2, for instance^^^) but didn't install the base version (v6.0^^^). Please refer to README.md (openable with Notepad^^^) for instructions on how to install the mod.
	PAUSE
	EXIT
)

REM Tell the user that we are running the mod
ECHO Launching SWAT: Elite Force

REM Run Swat4.exe from inside SEFMod\System, so that the
REM game uses the mod's initialisation files and settings

CD .\System\

..\..\ContentExpansion\System\Swat4X.exe
REM Tell the user that the game has exited

ECHO SWAT: Elite Force has exited