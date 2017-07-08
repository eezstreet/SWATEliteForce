class GenericExternalCamera extends Actor 
    HideCategories(Advanced, Collision, Events, Force, Karma, LightColor, Lighting, Movement, Object, Sound)
    placeable
    native;

enum EOptimizeOption
{
    OPTIMIZE_None,
    OPTIMIZE_Radius,
    OPTIMIZE_Zone,
    OPTIMIZE_VisibleZones
};

var() ScriptedTexture CameraTexture    "ScriptedTexture that this class renders into.  The ScriptedTexture can be combined with other materials for special effects.";
var() int             ResolutionX      "The X Resolution of the desired rendered texture.  Lower resolutions are faster but more pixelated.";
var() int             ResolutionY      "The Y Resolution of the desired rendered texture.  Lower resolutions are faster but more pixelated.";
var() int             OptimizedRadius  "Used only if OptimizeFor is set to OPTIMIZE_Radius";
var() int             UpdateRate       "How many times per second to update the texture";
var() int             FOV              "The desired field of view for the rendered viewport";
var() EOptimizeOption OptimizeFor      "How to optimize this camera.  Note: OPTIMIZE_VisibleZones does nothing currently";
var bool bTimerHasElapsed;

var Timer RenderTimer;

simulated function PostBeginPlay()
{
   Super.PostBeginPlay();
   Initialize();
}

simulated function Initialize()
{
    CameraTexture.Client = Self;
    CameraTexture.bNotifyClientBeforeRendering = true;
    CameraTexture.SetSize(ResolutionX, ResolutionY);
    // Make sure it updates at least once so we don't see garbage...
    CameraTexture.Revision++;
    
    RenderTimer = Spawn(class'Timer');
    RenderTimer.TimerDelegate = OnRenderTimer;
    RenderTimer.StartTimer( 1.0/UpdateRate, true, true );

}

simulated event Destroyed()
{
    if (CameraTexture != None)
    {
        // prevent GC failure due to hanging actor refs
        CameraTexture.Client = None;
    }

    RenderTimer.Destroy();

	Super.Destroyed();
}

simulated event PreScriptedTextureRendered(ScriptedTexture Tex)
{
    if ( bTimerHasElapsed )
    {
        Tex.Revision++;
        bTimerHasElapsed = false;
    }    
}

simulated event RenderTexture(ScriptedTexture inTexture)
{
    inTexture.DrawPortal(0, 0, ResolutionX, ResolutionY, Level.GetLocalPlayerController(), GetViewLocation(), GetViewRotation(), FOV,,true);
}

simulated function Rotator GetViewRotation()
{
    return Rotation;
}

simulated function Vector GetViewLocation()
{
    return Location;
}

simulated function OnRenderTimer()
{
    switch(OptimizeFor)
    {
        case OPTIMIZE_Radius:
            if ( VSize( Level.GetLocalPlayerController().Pawn.Location - Location ) > OptimizedRadius )     
                return;
            break;
        case OPTIMIZE_Zone:
            if ( Level.GetLocalPlayerController().Pawn.Region.Zone != Region.Zone )
                return;
            break;
    }

    bTimerHasElapsed=true;
}

defaultproperties
{
    ResolutionX=256
    ResolutionY=256
    UpdateRate=60
    FOV=90
    OptimizedRadius=1024
    bDirectional=true
    bHidden=true
    RemoteRole=ROLE_None
    bNoDelete=true
    Texture=Texture'Engine_res.subactionfov'
}