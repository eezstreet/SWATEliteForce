// ====================================================================
//  Class:  SwatGui.SwatGameSettingsMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatGameSettingsMenu extends SwatGUIPage
     ;

import enum eSwatGameState from SwatGame.SwatGUIConfig;

var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUITabControl		MyTabControl;

var() config localized string MainMenuString;
var() config localized string BackString;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnActivate()
{
    MyMainMenuButton.OnClick=InternalOnClick;

    if( GC.SwatGameState == eSwatGameState.GAMESTATE_None )
        MyMainMenuButton.SetCaption( MainMenuString );
    else
        MyMainMenuButton.SetCaption( BackString );

    Controller.SetCaptureScriptExec(true);
}

function InternalOnDeActivate()
{
    Controller.SetCaptureScriptExec(false);
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyMainMenuButton:
            Controller.CloseMenu(); 
            break;
	}
}

defaultproperties
{
    OnActivate=InternalOnActivate
    OnDeActivate=InternalOnDeActivate
    MainMenuString="MAIN MENU"
    BackString="BACK"

	StyleName="STY_SettingsMenu"
}