// ====================================================================
//  Class:  SwatGui.SwatMissionAbortMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMissionAbortMenu extends SwatGUIPage
     ;

var private config localized string EndTheMissionConfirmation;

function InternalOnActivate()
{
    OnDlgReturned=InternalOnDlgReturned;
    OpenDlg( EndTheMissionConfirmation, QBTN_YesNo, "MissionAbort" );
}

function InternalOnDlgReturned( int returnButton, optional string Passback )
{
    switch( Passback )
    {
        case "MissionAbort":
            if( returnButton == QBTN_Yes )
                GameAbort();
            else
                Controller.CloseMenu();
            break;
    }
}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
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
    OnActivate=InternalOnActivate
    StyleName="STY_MissionAbortMenu"
    bIsOverlay=False
	bSwallowAllKeyEvents=False
	
	EndTheMissionConfirmation="Are you sure you wish to end the mission?"
}
