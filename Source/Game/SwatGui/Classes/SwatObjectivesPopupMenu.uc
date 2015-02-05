// ====================================================================
//  Class:  SwatGui.SwatObjectivesPopupMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatObjectivesPopupMenu extends SwatPopupMenuBase
     ;

var(SWATGui) private EditInline Config SwatObjectivesPanel  MyObjectivesPanel;
var(SWATGui) private EditInline Config SwatLeadershipPanel	MyLeadershipPanel;
var(SWATGui) private EditInline Config SwatMapPanel 		MyMapPanel;
var(SWATGui) private EditInline Config SwatOfficerStatusPanel 	MyOfficerStatusPanel;

var(SWATGui) protected EditInline Config GUIButton		    MyResumeGameButton;
var(SWATGui) protected EditInline Config GUIButton		    MyAbortGameButton;
var(SWATGui) protected EditInline Config GUIButton		    MyGameSettingsButton;

var() private config localized string ContinueString;
var() private config localized string ResumeString;
var() private config localized string AbortString;
var() private config localized string DebriefString;
var() private config localized string AbortQueryString;
var() private bool bOpeningSubPage;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyResumeGameButton.OnClick=InternalOnClick;
    MyAbortGameButton.OnClick=InternalOnClick;
    MyGameSettingsButton.OnClick=InternalOnClick;
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    Super.HandleParameters( Param1, Param2, param3 );

    MyResumeGameButton.SetVisibility(!bPopup);
    MyResumeGameButton.SetActive(!bPopup);
    MyAbortGameButton.SetVisibility(!bPopup);
    MyAbortGameButton.SetActive(!bPopup);
    MyGameSettingsButton.SetVisibility(!bPopup);
    MyGameSettingsButton.SetActive(!bPopup);
}

function InternalOnActivate()
{
    MyResumeGameButton.SetEnabled( !GC.CurrentMission.IsMissionTerminal() );
    
    if( GC.CurrentMission.IsMissionCompleted() || GC.CurrentMission.IsMissionFailed() )
    {
        //MyRestartGameButton.Hide();
        //MyRestartGameButton.DeActivate();
        MyResumeGameButton.SetCaption( ContinueString );
        MyAbortGameButton.SetCaption( DebriefString );
    }
    else
    {
        MyResumeGameButton.SetCaption( ResumeString );
        MyAbortGameButton.SetCaption( AbortString );
    }
 
    bOpeningSubPage=false;   
    PlayerOwner().SetPause(true);
}

function InternalOnDeActivate()
{
    if( !bOpeningSubPage )
    {
        PlayerOwner().UnTriggerEffectEvent('UIMenuLoop',Style.EffectCategory);
        PlayerOwner().SetPause(false);
    }
}

protected function AbortGame()
{
    if( GC.CurrentMission.IsMissionCompleted() || GC.CurrentMission.IsMissionFailed() )
    {
        GameAbort();
    }
    else
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( AbortQueryString, QBTN_YesNo, "Abort" );
    }
}

function ResumeGame()
{
	Controller.CloseMenu();
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyResumeGameButton:
			ResumeGame();
			break;
		case MyAbortGameButton:
            AbortGame(); 
            break;
		case MyGameSettingsButton:
        	bOpeningSubPage=true;
            OpenGameSettings();
			break;
	}
}

function InternalOnDlgReturned( int Selection, String passback )
{
    switch (passback)
    {
        case "Abort":
            if( Selection == QBTN_Yes )
            {
    			GameAbort(); 
            }
            break;
	}
}

defaultproperties
{
	OnActivate=InternalOnActivate
	OnDeActivate=InternalOnDeActivate
    
    ContinueString="CONTINUE"
    DebriefString="DEBRIEF"
    ResumeString="RESUME"
    AbortString="ABORT"
    AbortQueryString="Are you sure you wish to end the mission?"
}