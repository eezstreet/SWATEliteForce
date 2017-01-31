@echo off

echo Producing Packages.md5

cd .\System
..\..\ContentExpansion\System\ucc.exe mastermd5 -c *.u

echo Produced entries:

cd .\System
..\..\ContentExpansion\System\ucc.exe mastermd5 -s

PAUSE