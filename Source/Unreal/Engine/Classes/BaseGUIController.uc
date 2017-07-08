// ====================================================================
//  Class:  Engine.BaseGUIController
//
//  This is just a stub class that should be subclassed to support menus.
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================

class BaseGUIController extends Interaction
		Native;
		
cpptext
{
		virtual void InitializeController();
}

var	Material	DefaultPens[3]; 	// Contain to hold some default pens for drawing purposes 					
var	bool		bIsConsole;			// If True, we are running on a console

// If this is true, then GUIPages will NOT receive
// PreDraw()/Draw()/ClientDraw() calls. This allows you to disable rendering
// of the GUI while keeping correct GUI state. It is intended to be used by
// CheatManagers, for example to hide all GUI pages so that screenshots can be
// taken. 
// 
// It's called bHackDoNotRenderGUIPages so that people don't use it as a
// fundamental part of GUI state management.
var bool bHackDoNotRenderGUIPages;

struct native PlayerIDSpoke
{
	var int PlayerID;
	var float SpeakTime;
};

var array<PlayerIDSpoke> VOIPSpeakingPlayerIDs;	// list of PlayerIDs currently speaking via VOIP

// Delegates
Delegate OnAdminReply(string Reply);	// Called By PlayerController

#if IG_GUI_LAYOUT //dkaplan- Notification of Level Changes
event PreLevelChange();
event PostLevelChange();
#endif

#if IG_SWAT //notify the GUIController of server connection messages
event SetProgress(string Message1, string Message2);
#endif

// ================================================
// OpenMenu - Opens a new menu and places it on top of the stack

#if IG_GUI_LAYOUT //dkaplan-extra optional param for passing ints (used by gui dialogues)
event bool OpenMenu(string NewMenuName, optional string MenuNameOverride, optional string Param1, optional string Param2, optional int param3 )
#else
event bool OpenMenu(string NewMenuName, optional string Param1, optional string Param2)
#endif
{
	return false;
}

// ================================================
// Create a bunch of menus at start up

event AutoLoadMenus();	// Subclass me

// ================================================
// Replaces a menu in the stack.  returns true if success

#if IG_GUI_LAYOUT //dkaplan-extra optional param for passing ints (used by gui dialogues)
event bool ReplaceMenu(string NewMenuName, optional string MenuNameOverride, optional string Param1, optional string Param2, optional int param3 )
#else
event bool ReplaceMenu(string NewMenuName, optional string Param1, optional string Param2)
#endif
{
	return false;
}

#if IG_GUI_LAYOUT //dkaplan-removed annoying unused param
event bool CloseMenu()	// Close the top menu.  returns true if success.
#else
event bool CloseMenu()	// Close the top menu.  returns true if success.
#endif
{
	return true;
}
#if IG_GUI_LAYOUT //dkaplan-removed annoying unused param
event CloseAll();
#else
event CloseAll();
#endif

#if IG_SHARED // dbeswick: added remove of menu by name
function RemoveMenu(string MenuName);
#endif

function SetControllerStatus(bool On)
{
	bActive = On;
	bVisible = On;
	bRequiresTick=On;

	// Add code to pause/unpause/hide/etc the game here.

}

event InitializeController();	// Should be subclassed.

#if !IG_GUI_LAYOUT //dkaplan- big bad hacks do nothing... bye bye
event bool NeedsMenuResolution(); // Big Hack that should be subclassed
event SetRequiredGameResolution(string GameRes);
#endif

// ================================================
// VOIP HUD support

event AddPlayerIDSpoke(int PlayerID, float SpeakTime)
{
    local PlayerIDSpoke PIDS;
 
    PIDS.PlayerID = PlayerID;
	PIDS.SpeakTime = SpeakTime;

    VOIPSpeakingPlayerIDs[VOIPSpeakingPlayerIDs.Length] = PIDS;
}

defaultproperties
{
	bHackDoNotRenderGUIPages=false;
	bNativeEvents=True
	bActive=False
	bRequiresTick=False
	bVisible=False
	DefaultPens(0)=Texture'Engine_res.MenuWhite'
	DefaultPens(1)=Texture'Engine_res.MenuBlack'
	DefaultPens(2)=Texture'Engine_res.MenuGray'
}
