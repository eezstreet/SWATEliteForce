@echo off

echo Producing Packages.md5

cd .\System
..\..\ContentExpansion\System\ucc.exe mastermd5 -c *.u -c SEF/Content/*.ukx -c SEF/Content/Maps/*.s4m -c SEF/Content/*.utx

echo Produced entries:

cd .\System
..\..\ContentExpansion\System\ucc.exe mastermd5 -s

PAUSE