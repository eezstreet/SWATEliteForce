// ====================================================================
//  Class:  SwatGui.SwatImportantMessageDisplay
//  Parent: GUILabel
//
//  Label displaying important game messages.
// ====================================================================

class SwatImportantMessageDisplay extends GUI.GUILabel
     ;

import enum eIMDType from SwatGui.SwatGUIController;

var(SwatGui) private config eIMDType IMDType "Type of IMD this is";
var(SwatGui) config float ImportantMessageDisplayTime "How long the messages should remain on screen (0 = stay on screen)";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    SwatGuiController(Controller).SetIMD( self, IMDType );
}

//pass an optional second param to explicitly set the display time
function MessageRecieved( String MsgText, optional float DisplayTime )
{
    Caption = MsgText;
    Show();
    
    if( DisplayTime == 0 )
        DisplayTime = ImportantMessageDisplayTime;
    if( DisplayTime > 0.0 )
        SetTimer( ImportantMessageDisplayTime );
}

function ClearDisplay()
{
    Caption = "";
    Hide();
}

event Timer()
{
    ClearDisplay();
}

