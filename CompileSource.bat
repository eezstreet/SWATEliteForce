@echo off

REM Tell the user that we are compiling the mod

echo Compiling source code for MyMod
REM Run UCC.exe from inside MyMod\System, so that the
REM compiler uses the mod's initialisation files and settings
REM and stores the compiled output in the MyMod\System
REM directory

cd .\System\
..\..\ContentExpansion\System\UCC.exe make -nobind

REM Tell the user that the game has exited, and wait for a keypress
cd ..
echo Finished compiling MyMod
PAUSE