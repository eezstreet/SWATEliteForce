// ====================================================================
//  Class:  SwatGui.SwatMapPanel
//  Parent: SwatGUIPanel
//
//  Displays the map of the current mission
// ====================================================================

class SwatMapPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline Config GUIImage MyLocationImage;
var(SWATGui) private EditInline Config GUIImage MyBackgroundImage;

var() private float MapWatchedDelayTime;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	MyBackgroundImage.bAcceptsInput = true;
	MyBackgroundImage.OnMenuStateChanged=OnLocationImagedStateChanged;
}

function InternalOnShow()
{
    if( GC.CurrentMission == None )
        return;

    log("[ckline]: SwatMapPanel --> GC.CurrentMission = "
            $(GC.CurrentMission)
            $"; floorplans="
            $(GC.CurrentMission.Floorplans)
            $"; LocationInfoText="
            $(GC.CurrentMission.LocationInfoText[0])$"...");

    MyLocationImage.Image = GC.CurrentMission.Floorplans;
    
    if( SwatMPPage(Controller.TopPage()) != None )
        SwatMPPage(Controller.TopPage()).BringServerInfoToFront();
    MyLocationImage.Reposition( 'UnWatched' );
}

function OnLocationImagedStateChanged(GUIComponent Sender, eMenuState NewState)
{
    local SwatMPPage MPPage;
log( self$"::OnLocationImagedStateChanged( "$Sender$", "$NewState$" ) " );
    MPPage = SwatMPPage(Controller.TopPage());

    if( NewState == MSAT_Watched )
    {
        SetTimer( MapWatchedDelayTime );
    }
    else
    {
        KillTimer();
        
        if( MPPage != None )
            MPPage.BringServerInfoToFront();
        MyLocationImage.Reposition( 'UnWatched' );
    }
}

event Timer()
{
    local SwatMPPage MPPage;
    MPPage = SwatMPPage(Controller.TopPage());
    if( MPPage != None )
        MPPage.SendServerInfoToBack();
    MyLocationImage.Reposition( 'Watched' );
}

defaultproperties
{
    OnShow=InternalOnShow
    MapWatchedDelayTime=0.5
}