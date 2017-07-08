# Microsoft Developer Studio Project File - Name="GP" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=GP - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "GP.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "GP.mak" CFG="GP - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "GP - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "GP - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""$/Gamespy/Formation/Mr_Pants/GP", YPGAAAAA"
# PROP Scc_LocalPath "."
CPP=snCl.exe
RSC=rc.exe

!IF  "$(CFG)" == "GP - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# ADD CPP /nologo /MT /W3 /GX /Zi /Ot /Og /Oi /Ob1 /D "WIN32" /D "NDEBUG" /D "_MBCS" /D "_LIB" /YX /FD /c
# SUBTRACT CPP /Ox /Oa /Ow /Os
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=snBsc.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=snLib.exe
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ELSEIF  "$(CFG)" == "GP - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /ZI /Od /D "_WIN32" /D "WIN32" /D "_DEBUG" /D "_MBCS" /D "_LIB" /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=snBsc.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=snLib.exe
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo

!ENDIF 

# Begin Target

# Name "GP - Win32 Release"
# Name "GP - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\gp.c
# End Source File
# Begin Source File

SOURCE=.\gpi.c
# End Source File
# Begin Source File

SOURCE=.\gpiBuddy.c
# End Source File
# Begin Source File

SOURCE=.\gpiBuffer.c
# End Source File
# Begin Source File

SOURCE=.\gpiCallback.c
# End Source File
# Begin Source File

SOURCE=.\gpiConnect.c
# End Source File
# Begin Source File

SOURCE=.\gpiInfo.c
# End Source File
# Begin Source File

SOURCE=.\gpiOperation.c
# End Source File
# Begin Source File

SOURCE=.\gpiPeer.c
# End Source File
# Begin Source File

SOURCE=.\gpiProfile.c
# End Source File
# Begin Source File

SOURCE=.\gpiSearch.c
# End Source File
# Begin Source File

SOURCE=.\gpiTransfer.c
# End Source File
# Begin Source File

SOURCE=.\gpiUnique.c
# End Source File
# Begin Source File

SOURCE=.\gpiUtility.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\available.h
# End Source File
# Begin Source File

SOURCE=..\darray.h
# End Source File
# Begin Source File

SOURCE=.\gp.h
# End Source File
# Begin Source File

SOURCE=.\gpi.h
# End Source File
# Begin Source File

SOURCE=.\gpiBuddy.h
# End Source File
# Begin Source File

SOURCE=.\gpiBuffer.h
# End Source File
# Begin Source File

SOURCE=.\gpiCallback.h
# End Source File
# Begin Source File

SOURCE=.\gpiConnect.h
# End Source File
# Begin Source File

SOURCE=.\gpiInfo.h
# End Source File
# Begin Source File

SOURCE=.\gpiOperation.h
# End Source File
# Begin Source File

SOURCE=.\gpiPeer.h
# End Source File
# Begin Source File

SOURCE=.\gpiProfile.h
# End Source File
# Begin Source File

SOURCE=.\gpiSearch.h
# End Source File
# Begin Source File

SOURCE=.\gpiTransfer.h
# End Source File
# Begin Source File

SOURCE=.\gpiUnique.h
# End Source File
# Begin Source File

SOURCE=.\gpiUtility.h
# End Source File
# Begin Source File

SOURCE=..\hashtable.h
# End Source File
# Begin Source File

SOURCE=..\md5.h
# End Source File
# Begin Source File

SOURCE=..\nonport.h
# End Source File
# Begin Source File

SOURCE=..\stringutil.h
# End Source File
# End Group
# Begin Group "common"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\darray.c
# End Source File
# Begin Source File

SOURCE=..\common\gsAvailable.c
# End Source File
# Begin Source File

SOURCE=..\common\gsAvailable.h
# End Source File
# Begin Source File

SOURCE=..\common\gsCommon.h
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatform.c
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatform.h
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformSocket.c
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformSocket.h
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformThread.c
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformThread.h
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformUtil.c
# End Source File
# Begin Source File

SOURCE=..\common\gsPlatformUtil.h
# End Source File
# Begin Source File

SOURCE=..\hashtable.c
# End Source File
# Begin Source File

SOURCE=..\md5c.c
# End Source File
# End Group
# Begin Source File

SOURCE=.\changelog.txt
# End Source File
# End Target
# End Project
