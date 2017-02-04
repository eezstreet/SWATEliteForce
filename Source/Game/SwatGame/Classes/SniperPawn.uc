
class SniperPawn extends SwatPawn
    implements IControllableThroughViewport
    config(SwatPawn);

// =============================================================================
// SniperPawn
//
// The SniperPawn is a SwatPawn that is a member of the SWAT team and uses a SniperRifle. 
// The player can control him through a viewport, and snipe enemies from his vantage point.
// Designers place these in the level and be off and running.  
//
// =============================================================================

var() private int      YawClampAngle "How many degrees this sniper is allowed to rotate on Yaw.";
var() private int      PitchClampAngle "How many degrees this sniper is allowed to rotate on Pitch.";
var        string      SniperName "Set this to either \"Sierra 1\" or \"Sierra 2\" based on which sniper team this pawn represents.";

var private config Material SniperOverlay;              // Texture overlay used for the scope 
var private config class<FiredWeapon> SniperRifleClass; // Class of the sniperrifle weapon
var private FiredWeapon SniperRifle;                    // Instance of this Sniper's SniperRifle
    
var private float        CurrentFOV;                    // The actual current FOV which lerps to the different FOVLevels
var() private config array<float> FOVLevels;              // The different FOV levels that pressing the right mouse button will cycle through
var() private config array<float> NoiseAmplitudeByFOVLevel;
var private int          FOVIndex;                      // The index of the current FOV level

var private Rotator      RotationOffset;

var private config float ReloadSoundTime;
var private Timer ReloadSoundTimer;
var private config float ReloadTime;
var private Timer        ReloadTimer;
var private bool         bReloading;
var private Rotator      InitialRotation;

var private PerlinNoise PerlinNoiseYaw;
var private PerlinNoise PerlinNoisePitch;

var private float       LastDeltaTime;

// Configurable constants
var private config const float kSniperBaseFrequency;
var private config const float kSniperMovementAddedFrequency;
var private config const float kSniperBaseAmplitude;
var private config const float kSniperMovementAmplitude;
var private config const float kSniperMovementZeroedSpeed;
var private config const float kSniperHorizontalNoiseDamping;

var private float ScaledMovementAmplitude;
var private float AddedMovementFrequency;

function PostBeginPlay()
{
    Super.PostBeginPlay();

	// Snipers are disabled in multiplayer!
    /*if ( Level.NetMode != NM_Standalone )
    {
        Destroy();
        return;
    }*/

    // Create my SniperRifle
    SniperRifle = Spawn(SniperRifleClass, Self);
    SniperRifle.OnGivenToOwner();
    SniperRifle.Equip();
    //log("SniperOverlay is: "$SniperOverlay);

    InitialRotation = Rotation;

    PerlinNoiseYaw = new class'Engine.PerlinNoise';
    PerlinNoisePitch = new class'Engine.PerlinNoise';

}

function OnReloadSoundTimer()
{
    SniperRifle.TriggerEffectEvent( 'Reloaded' );

    // optimization: destroy the timer that called this callback
    // so it's not hanging around waiting for another shot to be 
    // fired; we'll create a new one in HandleFire if the user 
    // fires again
	//log("Destroying ReloadSoundTimer "$ReloadSoundTimer);
    ReloadSoundTimer.Destroy();
    ReloadSoundTimer = None;

    if (ReloadTimer == None)
    {
		//log("Spawning ReloadTimer "$ReloadTimer);
        ReloadTimer = Spawn(class'Timer');
        ReloadTimer.TimerDelegate = OnReloadTimer;
    }
    ReloadTimer.StartTimer( ReloadTime );
}

function OnReloadTimer()
{
    bReloading = false;

    // optimization: destroy the timer that called this callback
    // so it's not hanging around waiting for another shot to be 
    // fired; we'll create a new one in HandleFire if the user 
    // fires again
	//log("Destroying ReloadTimer "$ReloadTimer);
    ReloadTimer.Destroy();
    ReloadTimer = None;
}

//======================================================================
// IControllableThroughViewport Interface
//======================================================================
function Actor GetViewportOwner()
{
    return Self;
}

function string  GetViewportType()
{
    return string(name);
}

function string  GetViewportName()
{
    return SniperName;
}

// Called to allow the viewport to modify mouse acceleration
simulated function            OnMouseAccelerated( out Vector MouseAccel )
{
    ScaledMovementAmplitude = kSniperMovementAmplitude;
    AddedMovementFrequency = kSniperMovementAddedFrequency ;
}

// Called whenever the mouse is moving (and this controllable is being controlled)
function            AdjustMouseAcceleration( out Vector MouseAccel )
{
    MouseAccel.X += PerlinNoiseYaw.Noise1( Level.TimeSeconds * (kSniperBaseFrequency + AddedMovementFrequency) ) * GetScaledNoiseAmplitude() * kSniperHorizontalNoiseDamping;
    MouseAccel.Y += PerlinNoisePitch.Noise1( Level.TimeSeconds * (kSniperBaseFrequency + AddedMovementFrequency) ) * GetScaledNoiseAmplitude();

    ScaledMovementAmplitude = fMax( ScaledMovementAmplitude - (LastDeltaTime * kSniperMovementZeroedSpeed), 0.0 );
    AddedMovementFrequency = fMax( AddedMovementFrequency - (LastDeltaTime * kSniperMovementZeroedSpeed), 0.0 );
    //log("ScaledMovementAmplitude: "$ScaledMovementAmplitude);
}

function float GetScaledNoiseAmplitude()
{
    return ((NoiseAmplitudeByFOVLevel[FOVIndex] + ScaledMovementAmplitude)  // Combined amplitude of the base amplitude plus any movement penalty
            * 1024                                                             // Scaled by 1024 to give a reasonable scale of about 3 degrees for every amplitude unit
            * LastDeltaTime);                                               // Scaled by delta time to smooth things out a bit
}

// Possibly offset from the controlled direction
function OffsetViewportRotation( out Rotator ViewportRotation )
{
    return;
 }

function string  GetViewportDescription()
{
    return "x" $ (FovIndex+1);                             
}

simulated function bool   CanIssueCommands()
{
    return false;
}

function Vector  GetViewportLocation()
{
    return Location;
}
function Rotator GetViewportDirection()
{
    return Rotation;
}

function  SetRotationToViewport(Rotator inNewRotation)
{
    SetRotation(inNewRotation);
}

function float   GetViewportPitchClamp()
{
    return PitchClampAngle;
}

function float   GetViewportYawClamp()
{
    return YawClampAngle;
}

function Material GetViewportOverlay()
{
    return SniperOverlay;
}

function bool   ShouldDrawViewport()
{
    return !bDeleteMe;
}

// Snipers have their reticle in their overlay!
function bool   ShouldDrawReticle()
{
    return false;
}

function float   GetFOV()
{
    CurrentFOV = lerp( 0.3, CurrentFOV, FOVLevels[FOVIndex]);
    return CurrentFOV;
}

function HandleReload()
{
    // Note: we have to call ReloadedHook() here because the Reload code in FiredWeapon is heavily reliant on having an animation played to reload, the sniper rifle and sniper pawn
    // however have no mesh associated, and no animations.  Technically this is only possible because ReloadedHook isn't declared as protected, though it probably should be, but I won't say anything if you don't *wink*. 
    if ( SniperRifle.CanReload() )
        SniperRifle.ReloadedHook();
}

function HandleFire()
{
    if ( !SniperRifle.NeedsReload() && !bReloading )
    {
        SniperRifle.TriggerEffectEvent('Fired');
        SniperRifle.Use();

        if (ReloadSoundTimer == None)
        {
	        //log("Spawning ReloadSoundTimer "$ReloadSoundTimer);
            ReloadSoundTimer = Spawn(class'Timer');
            ReloadSoundTimer.TimerDelegate = OnReloadSoundTimer;
        }
        // When the sound timer goes off, it triggers another timer
        // to start the reload
        ReloadSoundTimer.StartTimer( ReloadSoundTime );

        bReloading = true;
        // RotationOffset.Pitch = -DEGREES_TO_TWOBYTE * 10;
    }
    else if ( !bReloading )
    {
		// No more ammo!
        SniperRifle.TriggerEffectEvent('EmptyFired');
    }
}

function HandleAltFire()
{
    FOVIndex = (FOVIndex + 1) % FOVLevels.Length;
    SniperRifle.TriggerEffectEvent('ZoomModeChanged');
}

// Return the original rotation...
function Rotator    GetOriginalDirection()
{
    return InitialRotation;
}

// For controlling...
function float      GetViewportPitchSpeed()
{
    return 0.5;
}

// For controlling...
function float      GetViewportYawSpeed()
{
    return 0.5;
}

function            OnBeginControlling()
{
    PerlinNoiseYaw.Reinitialize();
    PerlinNoisePitch.Reinitialize();
    SetRotation(InitialRotation);
}

function            OnEndControlling();

//======================================================================

function Tick(float DeltaTime)
{
    LastDeltaTime = DeltaTime;
}

defaultproperties
{
    Physics=PHYS_None
    bStasis=false
    bHidden=true
    bCollideActors              = false
    bCollideWorld               = false
    bBlockPlayers               = false
	bBlockActors                = false
    bRotateToDesired            = false
    bPhysicsAnimUpdate          = false
    bCollisionAvoidanceEnabled  = false
    bActorShadows=false
    FOVLevels(0)=90
    FOVLevels(1)=70
    FOVLevels(2)=45
    FOVLevels(3)=25
    NoiseAmplitudeByFOVLevel(0)=2.5
    NoiseAmplitudeByFOVLevel(1)=3.0
    NoiseAmplitudeByFOVLevel(2)=3.3
    NoiseAmplitudeByFOVLevel(3)=3.7
    YawClampAngle=45
    PitchClampAngle=45
    SniperName="Sierra 1"
    ReloadTime=1
    ReloadSoundTime=1
// frequency of the noise that gets applied when the sniper view isn't moved
    kSniperBaseFrequency=0.75
// this frequency gets added to the base frequency above whenever the viewport is moved 
    kSniperMovementAddedFrequency=0.0
// Base amplitude for the noise that gets applied when the sniper view isn't moved
// Each unit is about 3 times the current zoom mode degrees.
    kSniperBaseAmplitude=2.5
// This amplitude gets added when the sniper is being moved, same units as above
    kSniperMovementAmplitude=3.0
// How much amplitude and frequency is lost per second...
    kSniperMovementZeroedSpeed=1
    kSniperHorizontalNoiseDamping=0.5
}
