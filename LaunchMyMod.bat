@echo off

REM Tell the user that we are running the mod

echo Launching MyMod

REM Run Swat4.exe from inside MyMod\System, so that the
REM game uses the mod's initialisation files and settings

cd .\System\

..\..\ContentExpansion\System\Swat4X.exe
REM Tell the user that the game has exited

echo MyMod has exited