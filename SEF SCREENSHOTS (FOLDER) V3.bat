@echo off
title SEF Screenshots folder script V3
  rem \SEF (folder)
cd /d "%~dp0"
  rem goal file
set  "__search=System\*.bmp"
  
set "__destinationFolder=Screenshots"
  rem Powershellscript status
set "__injekt='File written: '+$dst"  

echo Script by MaxWiese and Erzesel (2020)
echo Just run it every time you want to have all your screenshots in the "Screenshots" folder in the SEF folder.
echo All screenshots are converted to .png format to make it easier to share the screenshots, for example on Discord.


md "%__destinationFolder%" 2>nul
if not exist "%__search%" goto :notFound


rem Powershellscript convert BMP to PNG -> "Screenshots" 
 
powershell  $file=Get-Item '%__search%'; Add-Type -AssemblyName System.Drawing;$file^|ForEach{$DF='%__destinationFolder%';$dst='{0}\{1}-{2}.png' -f $DF,$_.CreationTime.toString('HH_mm_MM/dd/yy_f_'),$_.BaseName;$I = new-object System.Drawing.Bitmap $_.Fullname;$I.Save($dst,[Drawing.Imaging.ImageFormat]::PNG);%__injekt%};



     rem Delete original screenshots files (.bmp)
	 del  /q "%__search%"
     echo Original screenshots files (.bmp) removed and replaced with .png.
 


:notFound
if not exist "System" (
    echo "%~f0" ...
    echo ..."%cd%" ...
) else (
    echo Cannot find images in the "%cd%\System" !
)
