@echo off

REM Tell the user that we are running the editor
echo Launching SwatEd

REM Run SwatEd.exe from inside MyMod\System, so that the
REM editor uses the mod's initialisation files and settings

cd .\System\
..\..\ContentExpansion\System\SwatEd.exe -nogamma

REM Tell the user that the editor has exited
