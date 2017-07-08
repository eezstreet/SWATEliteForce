// ====================================================================
//  Class:  GUI.GUIDlg
//
//	GUIDlg s are quick popup menus with simple yes/no type questions and
//   a text string
//
//  Written by Dan Kaplan
//  (c) 2003, Irrational Games, Inc.  All Rights Reserved
// ====================================================================

class GUIDlg extends GUIPanel
	Native;

import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;


cpptext
{
	void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
}


var   GUILabel                MyLabel;    // Caption for the popup
var array<GUIButton>        MyButtons;
var         string                  Passback;   // passback to parent page
var         int                     Selection;  // what button was pressed on the dialogue
var(GUIDlg) config float ButtonPercentX "X percentage of space to be used by the buttons";
var(GUIDlg) config float ButtonPercentY "Y percentage of space to be used by the buttons";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

//note that this MUST be called before the first PreDraw of this component
function SetupDlg(string theCaption, string thePassback, int Options, optional float TimeOut)
{
    //since this Dialog is dynamically created, the label should be also
	MyLabel=GUILabel(AddComponent( "GUI.GUILabel" , self.Name$"_CaptionLabel", true));
    Assert( MyLabel != None );

    MyLabel.SetCaption( theCaption );
	MyLabel.TextAlign=TXTA_Center;
	MyLabel.bMultiLine=True;
	MyLabel.bAllowHTMLTextFormatting=true;

    Passback = thePassback;
	if( Options == 0 )
	{
		WinHeight = default.WinHeight/2.0;
		WinTop = default.WinTop + default.WinHeight/4.0;
	}
	else
	{
		WinHeight = default.WinHeight;
		WinTop = default.WinTop;
	}

    if( (Options & QBTN_Ok) != 0 )
        AddButton( QBTN_Ok, Controller.DLG_OK );
    if( (Options & QBTN_Yes) != 0 )
        AddButton( QBTN_Yes, Controller.DLG_Yes );
    if( (Options & QBTN_Continue) != 0 )
        AddButton( QBTN_Continue, Controller.DLG_Continue );
    if( (Options & QBTN_Retry) != 0 )
        AddButton( QBTN_Retry, Controller.DLG_Retry );
    if( (Options & QBTN_Ignore) != 0 )
        AddButton( QBTN_Ignore, Controller.DLG_Ignore );
    if( (Options & QBTN_No) != 0 )
        AddButton( QBTN_No, Controller.DLG_No );
    if( (Options & QBTN_Abort) != 0 )
        AddButton( QBTN_Abort, Controller.DLG_Abort );
    if( (Options & QBTN_Cancel) != 0 )
        AddButton( QBTN_Cancel, Controller.DLG_Cancel );
        
    //focus the last button by default
    //MyButtons[MyButtons.Length-1].Focus();
    
    if( TimeOut > 0 )
        SetTimer( TimeOut );

    OnKeyEvent=InternalOnKeyEvent;

    Selection = QBTN_Cancel | QBTN_No | QBTN_Abort;
    
    SetDirty();
}

function AddButton( int inValue, string inCaption )
{
    local GUIButton theButton;
    theButton = GUIButton(AddComponent("GUI.GUIDlgButton",self.Name$"_"$inCaption, true));
    MyButtons[MyButtons.Length]=theButton;
    theButton.SetCaption( inCaption );
    theButton.Value = inValue;
    theButton.OnClick = InternalOnClick;
    theButton.EnableComponent();
}

function InternalOnClick(GUIComponent Sender)
{
    Selection = GUIButton(Sender).Value;
    GUIPage(MenuOwner).DlgReturned();
}

event Timer()
{
    Selection = QBTN_TimeOut;
    GUIPage(MenuOwner).DlgReturned();
}

event DeActivate()
{
    local int i;
    KillTimer();
    MyLabel=None;
    MyButtons.Remove( 0, MyButtons.Length );
    for( i = Controls.length-1; i >= 0 ; i-- )
    {
        RemoveComponent(Controls[i]);
    }
    //ensure controls array is emptied
    Controls.Remove( 0, Controls.Length );
    Super.DeActivate();
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
//log("dkaplan in guidlg internal on key event" );
    if( State == EInputAction.IST_Press && KeyMatchesBinding( Key, "GUICloseMenu" ) )
    {
        GUIPage(MenuOwner).DlgReturned();
        return true;
    }
    
    return false;
}


defaultproperties
{
    WinTop=0.366667
    WinLeft=0.312500
    WinWidth=0.375000
    WinHeight=0.266667

    RenderWeight=0.999
    ButtonPercentX=0.4
    ButtonPercentY=0.2
	bAcceptsInput=true
	bPersistent=false
    StyleName="STY_DialogPanel"
    bSwallowAllKeyEvents=false
    bDrawStyle=True
}