// ====================================================================
//  Class:  GUI.GUIPage
//
//	GUIPages are the base for a full page menu.  They contain the
//	Control stack for the page.
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIPage extends GUIMultiComponent
        HideCategories(Menu,Object)
	Native;

cpptext
{
		UBOOL NativeKeyEvent(BYTE& iKey, BYTE& State, FLOAT Delta );
		void UpdateTimers(float DeltaTime);
		UBOOL MousePressed(UBOOL IsRepeat);					// The Mouse was pressed
		UBOOL MouseReleased();								// The Mouse was released
        UBOOL PerformHitTest(INT MouseX, INT MouseY);
        UGUIComponent* UnderCursor(FLOAT MouseX, FLOAT MouseY);
        
        UBOOL XControllerEvent(int Id, eXControllerCodes iCode);

}

// Variables
var(GUIPage) Editinline Editconst const	array<GUIComponent>		Timers "List of components with Active Timers if last on the stack.";
																			
var(GUIPage) config                      bool                    bIsOverlay "If true, underlaying components should remain active";
var(GUIPage) config                      bool                    bIsHUD "If true, underlaying systems should remain active for input (gui should not swallow invalid input)";

var(GUIPage) Editinline Editconst GUILabel HelpText "The label that displays the hint for the watched component on this page";
var(GUIPage) Editinline Editconst GUIDlg CurrentDialog "The current dialog";


// Delegates
Delegate bool OnKeyEventFirstCrack(out byte Key, out byte State, float delta)
{
	return false;
}


delegate OnDlgReturned( int returnButton, optional string Passback );
delegate OnPopupReturned( GUIListElem returnObj, optional string Passback );

//hook for subclasses that need to always perform post-Activation/post-HnadleParameter actions
event PostActivate() {}

event Activate()
{
	EnableComponent();
	Super.Activate();
	Focus();
}

event DeActivate()
{
	DisableComponent();
	Super.DeActivate();
	if (!bPersistent)       // keep access to the controller if we are not up
	    Free();
}


event Show()
{
    if( !bNeverTriggerEffectEvents && Style != None )
        PlayerOwner().TriggerEffectEvent('UIMenuLoop',,,,,,,,Style.EffectCategory);
    Super.Show();
    if( HelpText != None )
        HelpText.Hide();
}

event Hide()
{
    if( !bNeverTriggerEffectEvents && Style != None )
        PlayerOwner().UnTriggerEffectEvent('UIMenuLoop',Style.EffectCategory);
    Super.Hide();
}

final function CleanupDialogs()
{
    local int i;
    
    if( CurrentDialog != None )
    {
        DlgReturned();
    }
    
    for( i = 0; i < Controls.Length; i++ )
    {
        if( GUIDlg(Controls[i]) != None )
            RemoveComponent( Controls[i] );
    }
}

//=================================================
// InitComponent is responsible for initializing all components on the page.

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
	MapControls();		// Figure out links
}

event ChangeHint(string NewHint)
{
    if( HelpText == None )
        return;
        
    HelpText.SetCaption( NewHint );
    HelpText.SetVisibility( !Controller.bDontDisplayHelpText && NewHint != "" );
}

event HandleParameters(string Param1, string Param2, optional int param3);	// Should be subclassed

event NotifyLevelChange();

event Free( optional bool bForce ) 			// This control is no longer needed
{
	local int i;
    for (i=0;i<Timers.Length;i++)
    	Timers[i]=None;
    Timers.Remove( 0, Timers.Length );
    
    HelpText=None;
    CurrentDialog=None;

    Super.Free( bForce );
}

final function OpenDlg( String Caption, optional int TheButtons, optional string Passback, optional int TimeOut )
{
    if( CurrentDialog != None )
        return;
        
    CurrentDialog = GUIDlg(AddComponent( "GUI.GUIDlg", self.Name$"_"$Passback, true ));
    CurrentDialog.SetupDlg( Caption, Passback, TheButtons, TimeOut );
    
    CurrentDialog.Show();
    CurrentDialog.Activate();
}

final function DlgReturned()
{
    local string Passback;
    local int Selection;
    
    //NOTE: the dialog must be cleaned up BEFORE it sends the delegate to protect
    //       against re-opening the dialog in the same tick
    
    Selection = CurrentDialog.Selection;
    Passback = CurrentDialog.Passback;

    CurrentDialog.DeActivate();
    CurrentDialog.Hide();
    
    //remove the dialog after it has been closed and processed
    RemoveComponent( CurrentDialog );
    
    CurrentDialog=None;
    
    OnDlgReturned( Selection, Passback ); //call the delegate
}

#if IG_SWAT_PROGRESS_BAR
function OnProgress(string Str1, string Str2)
{
}
#endif

defaultproperties
{
	bAcceptsInput=true
	bPersistent=true
    bTabStop=false
    bIsOverlay=true
	WinTop=0.0
	WinLeft=0.0
	WinWidth=1.0
	WinHeight=1.0
	bSwallowAllKeyEvents=True
    PropagateState=false
}
