// ====================================================================
//  Class:  SwatGui.SwatGUIPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatGUIPanel extends GUI.GUIPanel
     ;

var(DynamicConfig) EditInline EditConst protected   SwatGUIConfig   GC "Config class for the GUI";
var(SwatGUI)       Config               private     Name            CameraPositionLabel "When specified, will move the camera to the location specified by the given camera position when the panel is shown.";
var(SwatGUIPanel)  Config                           bool            bAutoAspectRatio "Does this panel automatically use a 4:3 aspect ratio?";

function InitComponent(GUIComponent MyOwner)
{
	GC = SwatGUIController(Controller).GuiConfig;
	Super.InitComponent(MyOwner);
}

event Show()
{
    SetSplashCameraPosition();
    if (bAutoAspectRatio) UpdateAspectRatio();
    Super.Show();
}

// SEF: Maintain 4:3 aspect ratio for this panel. -Kevin
private function UpdateAspectRatio()
{
    local float screenAspectRatio;
    local float desiredAspectRatio;
    local float horizontalScale;

    Controller.GetGuiResolution();
    screenAspectRatio = float(Controller.ResolutionX) / float(Controller.ResolutionY);
    // Setting desired aspect ratio to 1024 / 768 makes the UI slightly too wide.
    // This is the correct value (measured by the aspect ratio of GUI images on loadout screen).
    desiredAspectRatio = 915.0 / 768.0;
    horizontalScale = desiredAspectRatio / screenAspectRatio;
    if (horizontalScale > 1) horizontalScale = 1;

    WinWidth = horizontalScale;
    WinLeft = (1 - horizontalScale) / 2.0;
}

private final function SetSplashCameraPosition()
{
    local CameraPositionMarker Marker;
    if( GC.SwatGameState != GAMESTATE_None || 
        CameraPositionLabel == '' )
        return;
    Marker = CameraPositionMarker(PlayerOwner().findStaticByLabel(class'CameraPositionMarker',CameraPositionLabel));
    if( Marker != None )
    {
        PlayerOwner().SetLocation(Marker.Location);
        PlayerOwner().SetRotation(Marker.Rotation);
    }
}

defaultproperties
{
	WinTop=0
	WinLeft=0
	WinWidth=1
	WinHeight=1
	bAcceptsInput=true
    bAutoAspectRatio=true
}