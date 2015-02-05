class SwatGUIPage extends GUI.GUIPage;

import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;

var(DynamicConfig) EditInline EditConst protected   SwatGUIConfig   GC "Config class for the GUI";
var(SwatGUI)       Config               private     Name            CameraPositionLabel "When specified, will move the camera to the location specified by the given camera position when the page is shown.";
var() private config localized string QuitPrompt;

function InitComponent(GUIComponent MyOwner)
{
	GC = SwatGUIController(Controller).GuiConfig;
	Super.InitComponent(MyOwner);

	HelpText = GUILabel(AddComponent("GUI.GUILabel",self.Name$"_SwatHelpText",true));
    
    OnKeyEvent=InternalOnKeyEvent;
}

event Show()
{
    //dont trigger effects on the page while playing MP games
    if( GC.SwatGameState == GAMESTATE_None ||
        ( GC.SwatGameRole != GAMEROLE_MP_Host &&
          GC.SwatGameRole != GAMEROLE_MP_Client ) )
        PlayerOwner().TriggerEffectEvent('UIMenuLoop',,,,,,,,Style.EffectCategory);

    if( ShouldSetSplashCameraPosition() )
        SetSplashCameraPosition();
    Super.Show();
}

function DisplayMainMenu()
{
    if( CurrentDialog != None )
        return;

    Controller.CloseAll();
    Controller.OpenMenu( "SwatGui.SwatMainMenu", "SwatMainMenu" );
}

function Quit()
{
log( "Quit: Confirming" );
    OnDlgReturned=OnQuitDialogReturned;
    OpenDlg( QuitPrompt, QBTN_YesNo, "Quit" );
}

final function OnQuitDialogReturned( int Selection, String passback )
{
    if( Selection == QBTN_Yes )
    {
log( "Quit: Confirmed" );
        PerformQuitToWindows();
    }
}

final function PerformQuitToWindows()
{
    //may need to add saving info routines here
	SwatGUIController(Controller).Quit(); 
}

//may be overridden in subclasses to do alternate behavior
function PerformClose()
{
    Assert( self == Controller.TopPage() );
    Controller.CloseMenu();
}

function GameStart()
{
    //start of game hook
	SwatGUIController(Controller).GameStart(); 
}

function GameAbort()
{
    //end of game hook -- should signal GameEvent OnMissionFailed here ... TODO!
	SwatGUIController(Controller).GameAbort();
}

function GameRestart()
{
    //end of game hook
	SwatGUIController(Controller).GameAbort();
	SwatGUIController(Controller).GameStart(); 
}

protected function bool ShouldSetSplashCameraPosition()
{
    return true;
}

private final function SetSplashCameraPosition()
{
    local CameraPositionMarker Marker;
    if( CameraPositionLabel == '' )
        return;
    Marker = CameraPositionMarker(PlayerOwner().findStaticByLabel(class'CameraPositionMarker',CameraPositionLabel));
    if( Marker != None )
    {
        PlayerOwner().SetViewTarget(PlayerOwner());
        PlayerOwner().SetLocation(Marker.Location);
        PlayerOwner().SetRotation(Marker.Rotation);
    }
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    return HandleKeyEvent( Key, State, delta );
}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
    if( State == EInputAction.IST_Press && KeyMatchesBinding( Key, "GUICloseMenu" ) && Controller.TopPage() == self )
    {
        PerformClose();
        return true;
    }
    
    return false;
}

function OpenPopup( string ClassName, string ObjName )
{
    Controller.OpenMenu( ClassName, ObjName );
}

////////////////////////////////////////////////////////////////////////////////////
// Component Cleanup
////////////////////////////////////////////////////////////////////////////////////
event Free( optional bool bForce ) 			
{
    GC=None;

    Super.Free( bForce );
}


defaultproperties
{
	WinTop=0
	WinLeft=0
	WinWidth=1
	WinHeight=1
	bAcceptsInput=true
	bPersistent=true
	bIsOverlay=false
	StyleName="STY_DefaultMenu"
	QuitPrompt="Quit to Windows?"
	
	//swat gui pages do not trigger normal effect events
	bNeverTriggerEffectEvents=true
}
