@echo off

REM Create INC folders if they don't exist, because git doesn't handle them well

if not exist .\Source\Game\AICommon\Inc\ mkdir .\Source\Game\AICommon\Inc
if not exist .\Source\Game\Gameplay\Inc\ mkdir .\Source\Game\Gameplay\Inc
if not exist .\Source\Game\RWOSupport\Inc\ mkdir .\Source\Game\RWOSupport\Inc
if not exist .\Source\Game\Scripting\Inc\ mkdir .\Source\Game\Scripting\Inc
if not exist .\Source\Game\SwatAIAwareness\Inc\ mkdir .\Source\Game\SwatAIAwareness\Inc
if not exist .\Source\Game\SwatAICommon\Inc\ mkdir .\Source\Game\SwatAICommon\Inc
if not exist .\Source\Game\SwatEquipment\Inc\ mkdir .\Source\Game\SwatEquipment\Inc
if not exist .\Source\Game\SwatGame\Inc\ mkdir .\Source\Game\SwatGame\Inc
if not exist .\Source\Game\SwatGui\Inc\ mkdir .\Source\Game\SwatGui\Inc
if not exist .\Source\Game\SwatObjectives\Inc\ mkdir .\Source\Game\SwatObjectives\Inc
if not exist .\Source\Game\SwatProcedures\Inc\ mkdir .\Source\Game\SwatProcedures\Inc
if not exist .\Source\Game\Tyrion\Inc\ mkdir .\Source\Game\Tyrion\Inc
if not exist .\Source\Game\Voting\Inc\ mkdir .\Source\Game\Voting\Inc

if not exist .\Source\Unreal\Core\Inc\ mkdir .\Source\Unreal\Core\Inc
if not exist .\Source\Unreal\Editor\Inc\ mkdir .\Source\Unreal\Editor\Inc
if not exist .\Source\Unreal\Engine\Inc\ mkdir .\Source\Unreal\Engine\Inc
if not exist .\Source\Unreal\GUI\Inc\ mkdir .\Source\Unreal\GUI\Inc
if not exist .\Source\Unreal\IGAutomatedTestSystem\Inc\ mkdir .\Source\Unreal\IGAutomatedTestSystem\Inc
if not exist .\Source\Unreal\IGEffectsSystem\Inc\ mkdir .\Source\Unreal\IGEffectsSystem\Inc
if not exist .\Source\Unreal\IGSoundEffectsSubsystem\Inc\ mkdir .\Source\Unreal\IGSoundEffectsSubsystem\Inc
if not exist .\Source\Unreal\IGVisualEffectsSubsystem\Inc\ mkdir .\Source\Unreal\IGVisualEffectsSubsystem\Inc
if not exist .\Source\Unreal\IpDrv\Inc\ mkdir .\Source\Unreal\IpDrv\Inc
if not exist .\Source\Unreal\SwatEd\Inc\ mkdir .\Source\Unreal\SwatEd\Inc
if not exist .\Source\Unreal\UWindow\Inc\ mkdir .\Source\Unreal\UWindow\Inc


REM Tell the user that we are compiling the mod

echo Compiling source code for SEF
REM Run UCC.exe from inside SEFMod\System, so that the
REM compiler uses the mod's initialisation files and settings
REM and stores the compiled output in the MyMod\System
REM directory

cd .\System\
..\..\ContentExpansion\System\UCC.exe make -nobind

REM Tell the user that the game has exited, and wait for a keypress
cd ..
echo Finished compiling SEF
PAUSE