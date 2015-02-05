// ====================================================================
//  Class:  SwatGui.SwatPopupMenuBase
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatPopupMenuBase extends SwatGUIPage
     ;

import enum EInputAction from Engine.Interactions;
import enum EInputKey from Engine.Interactions;

//set if this is opened as a popup menu
var(DEBUG) bool bPopup;


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    Super.HandleParameters( Param1, Param2, param3 );
    
    //if param1 == Popup, this is to be opened as a tab popup - buttons disabled
    bPopup = ( Param1 == "Popup" );
}

function PerformClose()
{
    ResumeGame();
}

protected function OpenGameSettings()
{
    Controller.OpenMenu("SwatGui.SwatGameSettingsMenu", "SwatGameSettingsMenu");
}

protected function AbortGame() {}

function ResumeGame() {}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
    if( bPopup && State == EInputAction.IST_Release && KeyMatchesBinding( Key, "ShowInGamePopup" ) )
    {
        PerformClose();
        return true;
    }
    
    //pass all releases through to the game
    if( State == EInputAction.IST_Release )
    {
        return false;
    }

    // capture all mouse movement
    if( Key == EInputKey.IK_MouseX || 
        Key == EInputKey.IK_MouseY )
    {
        return true;
    }

    //allow the superclass to handle key input
    if( Super.HandleKeyEvent( Key, State, delta ) )
    {
        return true;
    }
    
    //capture all other inputs
    return true;
}

defaultproperties
{
    bIsOverlay=False
	bSwallowAllKeyEvents=False
}