// ====================================================================
//  Class:  SwatGui.SwatTimeDisplay
//  Parent: GUITimeDisplay
//
//  Label displaying important game messages.
// ====================================================================

class SwatTimeDisplay extends GUI.GUITimeDisplay
     ;

import enum eTimeType from SwatGui.SwatGUIController;

var(SwatGui) private config eTimeType TimeType "Type of timer this is";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    SwatGuiController(Controller).SetTimeDisplay( self, TimeType );
}

function DoNothing()
{
    //placeholder to recieve the TimerExpired delegate after it has been triggered
}

