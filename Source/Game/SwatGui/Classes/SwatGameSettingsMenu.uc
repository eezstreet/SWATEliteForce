// ====================================================================
//  Class:  SwatGui.SwatGameSettingsMenu
//  Parent: SwatGUIPage
//
//  Menu for adjusting settings.
// ====================================================================

class SwatGameSettingsMenu extends SwatGUIPage
     ;

import enum eSwatGameState from SwatGame.SwatGUIConfig;

var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUITabControl		MyTabControl;

var() config localized string MainMenuString;
var() config localized string BackString;

// SEF
event Show()
{
    UpdateAspectRatio();
    Super.Show();
}

// SEF: Maintain 4:3 aspect ratio for this menu. -Kevin
function UpdateAspectRatio()
{
    local float screenAspectRatio;
    local float desiredAspectRatio;
    local float horizontalScale;

    Controller.GetGuiResolution();
    screenAspectRatio = float(Controller.ResolutionX) / float(Controller.ResolutionY);
    desiredAspectRatio = 1024.0 / 768.0;
    horizontalScale = desiredAspectRatio / screenAspectRatio;
    if (horizontalScale > 1) horizontalScale = 1;

    WinWidth = horizontalScale;
    WinLeft = 0; // Because the render preview is on the right.
}

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