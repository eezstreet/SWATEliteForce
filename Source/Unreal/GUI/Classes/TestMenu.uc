// ====================================================================
//  Class:  Gui.TestMenu
//  Parent: GUIPage
//
//  Menu to load map from entry screen.
// ====================================================================
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined. [DKaplan]
#endif
/*===========================================================================*/

class TestMenu extends GUIPage;

// easy refrences to specific Controls
var(TestGui) private config EditInline GuiButton		    MyStartButton;
var(TestGui) private config EditInline GuiButton		    MyBackButton;
var(TestGui) private config EditInline GuiButton		    MyMainMenuButton;
var(TestGui) private config EditInline GuiButton		    MyQuitButton;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyStartButton.OnClick=MyButtonClick;
    MyBackButton.OnClick=MyButtonClick;
    MyMainMenuButton.OnClick=MyButtonClick;
    MyQuitButton.OnClick=MyButtonClick;
}

function InternalOnDlgReturned( int Selection, String passback )
{
    switch (passback)
    {
        case "PlayerReady":
            if( Selection == QBTN_Yes )
                Controller.CloseMenu();
            break;
        case "Quit":
            if( Selection == QBTN_Yes )
                Controller.ConsoleCommand( "Quit" );
            break;
    }
}

function MyButtOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyStartButton:
            OpenDlg( "Do you wish to close the menu?", QBTN_YesNoCancel, "PlayerReady" );
            break;
		case MyBackButton:
            break;
		case MyMainMenuButton:
            break;
		case MyQuitButton:
            OpenDlg( "Do you wish to quit?", QBTN_YesNo, "Quit" );
            break;
	}
}

defaultproperties
{
	WinTop=0
	WinLeft=0
	WinWidth=1
	WinHeight=1
	bAcceptsInput=true
	OnDlgReturned=InternalOnDlgReturned
	bPersistent=true
}
