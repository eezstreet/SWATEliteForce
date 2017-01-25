// ====================================================================
//  Class:  SwatGui.SwatMissionLoadingMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMissionLoadingMenu extends SwatGUIPage
     ;

var(SWATGui) private EditInline Config GUILabel         LoadingText;
var(SWATGui) private EditInline Config GUIImage         LoadingImage;

var(SWATGui) private            config array<Material>  DefaultImages;
var(SWATGui) private localized  config array<String>    DefaultCaptions;

#if IG_SWAT_PROGRESS_BAR
var(SWATGui) private EditInline config GUILabel MissionLoadingStatusText;
var(SWATGui) private EditInline config GUIProgressBar MissionLoadingProgressBar;

var() private config localized string LoadSplashString;
var() private config localized string WaitForConnectionString;
var() private config localized string LoadMapString;
var() private config localized string DownloadString;
#endif

event Show()
{
    local int i;

    Super.Show();

    if(GC.CurrentMission != None && GC.CurrentMission.LoadingImage != None &&
      (GC.SwatGameRole == GAMEROLE_SP_Campaign || (GC.SwatGameRole == GAMEROLE_SP_Other && GC.CurrentMission.MapName == "SP-Training")))
    {
        LoadingText.SetCaption( GC.CurrentMission.LoadingText );
        LoadingImage.Image = GC.CurrentMission.LoadingImage;
    }
    else if( DefaultImages.Length > 0 )
    {
        i = Rand( DefaultImages.Length );

        LoadingText.SetCaption( DefaultCaptions[i] );
        LoadingImage.Image = DefaultImages[i];
    }
    else
    {
        LoadingText.Hide();
        LoadingImage.Hide();
    }
}

function PerformClose() {} //we dont want to allow the user to do anything here

#if IG_SWAT_PROGRESS_BAR
function OnProgress(string PercentComplete, string ExtraInfo)
{
	log("  SwatMissionLoadingMenu ONPROGRESS Received: ["$PercentComplete$"] ["$ExtraInfo$"]");
	MissionLoadingProgressBar.Value = float(PercentComplete);

    if( ExtraInfo == "LoadSplash" )
        MissionLoadingStatusText.SetCaption( LoadSplashString );
    else if( ExtraInfo == "WaitForConnection" )
        MissionLoadingStatusText.SetCaption( WaitForConnectionString );
    else if( ExtraInfo == "LoadMap" )
        MissionLoadingStatusText.SetCaption( LoadMapString );
    else if( ExtraInfo == "Download" )
        MissionLoadingStatusText.SetCaption( DownloadString );

	if (Controller != None)
		Controller.PaintProgress();
}
#endif

defaultproperties
{
    bNeverTriggerEffectEvents=true

    LoadSplashString="Loading..."
    WaitForConnectionString="Connecting..."
    LoadMapString="Loading..."
    DownloadString="Downloading..."
}
