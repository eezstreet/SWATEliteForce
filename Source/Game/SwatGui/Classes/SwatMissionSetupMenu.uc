// ====================================================================
//  Class:  SwatGui.SwatMissionSetupMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMissionSetupMenu extends SwatGUIPage
     ;

import enum eSwatGameRole from SwatGame.SwatGuiConfig;

var(SWATGui) private EditInline Config GUIButton    MyQuitButton;
var(SWATGui) private EditInline Config GUIButton    MyStartButton;
var(SWATGui) private EditInline Config GUIButton    MyBackButton;
var(SWATGui) private EditInline Config GUIButton    MyMainMenuButton;
var(SWATGui) private EditInline Config GUITabControl	MyTabControl;

var() private config localized string CampaignString;
var() private config localized string CustomString;

var() bool bOpeningSubMenu;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyStartButton.OnClick=InternalOnClick;
    MyBackButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;

    if( GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom )
    {
        MyBackButton.SetCaption(CustomString );
    }
    else
    {
        MyBackButton.SetCaption(CampaignString );
    }
}

function InternalOnActivate()
{
    if( !bOpeningSubMenu )
        GC.ClearCurrentMission();
        
    bOpeningSubMenu = false;
}

function OpenPopup( string ClassName, string ObjName )
{
    bOpeningSubMenu = true;
    Super.OpenPopup( ClassName, ObjName );
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
	    case MyQuitButton:
            Quit(); 
            break;
		case MyStartButton:
            GameStart();
            break;
		case MyBackButton:
            Controller.CloseMenu(); 
            break;
		case MyMainMenuButton:
            DisplayMainMenu();
            break;
	}
}

defaultproperties
{
    OnShow=InternalOnShow
    OnActivate=InternalOnActivate
    
    CampaignString="CAMPAIGN"
    CustomString="CUSTOM"
}