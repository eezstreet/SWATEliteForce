class MirrorCamera extends GenericExternalCamera
    native;

var() private float MirrorOffset "How much the camera is allowed to move in relation to the player's view rotation.  Larger numbers look more realistic, but can clip into geometry";
var() private Shader    ReferenceShader "If set, allows extra effects to be applied to the Mirror scripted texture.  A copy of the reference shader will be made, and the Diffuse material of the new shader will be set to the reflection texture for this mirror.";

var private const transient ScriptedTexture   MirrorTexture;      // Scripted Texture we render into
var private const transient TexScaler         MirrorScaler;       // TexScales that "mirrors" the scripted texture
var transient const Material                  MirrorMaterial;     // Material wrapper for any fancy effects, must wrap the mirror panner in some way
var Mirror                                    OwnerMirror;

native function Initialize();

native static function ScriptedTexture CreateNewScriptedTexture(string InName);

cpptext
{
    UScriptedTexture* CreateScriptedTexture( const TCHAR* BaseName );
}

simulated event PostBeginPlay()
{
    Super.PostBeginPlay(); // Will call our Initialize function, which doesn't settimer...

    RenderTimer = Spawn(class'Timer');
    RenderTimer.TimerDelegate = OnRenderTimer;
    RenderTimer.StartTimer( 1.0/UpdateRate, true, true );
}

simulated event Destroyed()
{
    if (MirrorTexture != None)
    {
        // prevent GC failure due to hanging actor refs
        MirrorTexture.Client = None;
    }

	Super.Destroyed();
}

// Carlos - 
// Note: Our Mirrors don't behave like normal real-world mirrors, because of time/complexity limitations.  This approach
// is the closest that we can get for now.  Basically, the mirror is rendered from a static location, the center of 
// the mirror static mesh.  The camera is pointed along the vector opposite of the vector from the player to the mirror,
// "mirrored" by the normal of the mirror static mesh.
simulated function Rotator GetViewRotation()
{
    local Vector EyeLocation, ToPlayer;
    local Actor ViewActor;
    local Rotator EyeRotation; 
    local Rotator MirrorRot;
    
    // Get the current view rotation and location
    Level.GetLocalPlayerController().PlayerCalcView(ViewActor, EyeLocation, EyeRotation);
    
    // Get the vector from the player to the mirror
    ToPlayer =  Location - EyeLocation; 
    
    // Mirror the vector ToPlayer by the "normal" of the mirror.  Since it isn't trivial to figure out the normal based on the geometry,
    // we'll just use the mirror camera's rotation.  MirrorCameras are by default spawned to point along the normal away from the mirror.
    MirrorRot = Rotator(MirrorVectorByNormal( ToPlayer, Normal(Vector(Rotation)) ));
    
    // Manually set the roll and pitch to the MirrorCamera's rotation so only horizontal movement is updated.
    MirrorRot.Roll = Rotation.Roll;
    MirrorRot.Pitch = Rotation.Pitch;

    // Return the mirror camera
    return MirrorRot; 
}

simulated function Vector GetViewLocation()
{
    return Location; 
}

defaultproperties
{
    bHidden=true
    DrawScale=0.5
    MirrorOffset=20
    FOV=85
}