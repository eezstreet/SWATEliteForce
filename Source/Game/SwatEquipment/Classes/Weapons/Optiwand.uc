
class Optiwand extends Engine.OptiwandBase implements Engine.IControllableViewport;

// =============================================================================
// Optiwand
//
// The Optiwand is a handheld equipment that an officer can use to look around corners
// and under doors.  It's made up of two main parts, a camera placed at the end of a
// flexible tip, and an lcd screen that displays what the camera sees.  Implementation
// of the optiwand uses a rendertotexture scripted texture to render the view from the
// camera tip's location.
//
// =============================================================================

import enum EFocusInterface from SwatGame.SwatGamePlayerController;

var private config ScriptedTexture LCDScreen;          // Scripted texture that we draw into
var private config float           RefreshRate;        // Refreshrate for the scriptedtexture
var private config Texture         ReticleTexture;     // Texture used for the reticle when controlling
var private config Material        BlankScreen;        // Material to use when the viewport isn't active
var private config Material        LCDShader;          // Shader applied to the first person mesh when active
var private config Material        GunShader;          // Material used on the optiwand itself
var private config const int       SizeX;              // Size of the texture along the X axis
var private config const int       SizeY;              // Size of the texture along the Y axis
var private config const int       FOV;                // FOV for our viewport
var private config const float     LensTurnAlpha;      // The Alpha used for Slerping
var private config const float     LensTurnSpeed;      // The Speed of the camera.
var private config const float     LensFinishSpeed;    // How fast the camera moves to its initial rotation when the optiwand is finished being used
var private config const int       ClampYawAngle;      // How much the lens is allowed to turn on yaw
var private config const int       ClampPitchAngle;    // ...On pitch
var private config name            BoneName;

var private Vector                 MouseAccel;         // Mouseacceleration when controlling through the optiwand
var private Rotator                DesiredViewRotation;// Desired rotation for the camera lens
var private Rotator                BoneRotation;       // Actual rotation of the camera lens bone
var private Vector                 LastViewLocation;   // Used for contorlling
var private float                  TimerFreq;          // How often in seconds to update the screen
var private bool                   bMirroring;			// This is deceptively named..
var private SwatDoor               MirroringDoor;
var private bool                   CompletedUsing;     // If we've finished the current DoUsing latent code
var private float                  LastDeltaTime;
var private bool					bInUse;				// Are we using it right now?

const kOptiwandLength = 90.0;

simulated function float GetWeight() {
  return Weight;
}

simulated function float GetBulk() {
  return Bulk;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    Disable('Tick');
}

// Helper function, this should really be in Object or something
simulated function int DegreesToUnreal( INT inDegrees )
{
    return (65536*inDegrees)/360;
}

simulated function EquippedHook()
{
    Super.EquippedHook();

	// Clear out the initial rotation of the lens bone
    FirstPersonModel.SetBoneDirection( BoneName, rot(0,0,0),,1,0 );
}

simulated function OnGivenToOwner()
{
    mplog( self$"---Optiwand::OnGivenToOwner().");
    //mplog( "...Owner="$Owner );
    if ( Pawn(Owner) != None && Pawn(Owner).Controller == Level.GetLocalPlayerController() )
    {
        mplog(Self$" assigning gunshader and blankshader.");
        LCDScreen.Client = Self;
        LCDScreen.SetSize(SizeX, SizeY);
        //mplog( "...FirstPersonModel="$FirstPersonModel );
        assert( FirstPersonModel != None );

        FirstPersonModel.Skins[0] = GunShader;
        FirstPersonModel.Skins[1] = BlankScreen;
		//FirstPersonModel.Skins[1] = LCDShader;

        TimerFreq = 1.0/RefreshRate;
    }
}

simulated event Destroyed()
{
    if (LCDScreen != None && LCDScreen.Client == Self)
    {
        // prevent GC failure due to hanging actor refs
        LCDScreen.Client = None;
    }

	Super.Destroyed();
}

// =============================================================================


// =============================================================================
// IControllableViewport Interface:
// =============================================================================
simulated function SetInput(int dMouseX, int dMouseY)
{
    MouseAccel.X = dMouseX;
    MouseAccel.Y = dMouseY;
}

simulated function bool   CanIssueCommands()
{
    return false;
}

simulated function OnBeginControlling()
{
    assertWithDescription( FirstPersonModel!=None, Self$", does not have a firstpersonmodel!!" );
	
	bInUse = true;
}

simulated function OnEndControlling()
{
    assertWithDescription( FirstPersonModel!=None, Self$", does not have a firstpersonmodel!!" );

	// Use the blank screen texture now
    //FirstPersonModel.Skins[1] = BlankScreen;
    FirstPersonModel.SetBoneDirection( BoneName, rot(0,0,0),,0,1 );
	bInUse = false;
}


simulated function name   GetControllingStateName()
{
    return 'ControllingOptiwandViewport';
}

simulated function bool ShouldControlViewport()
{
    return PlayerController(Pawn(Owner).Controller).bFire  != 0;
}

simulated function ResolveInitialLocationAndRotation( out Vector CameraLocation, out Rotator PlayerViewRot )
{
    local name DoorBoneName;
    local Vector X, Y, Z;

    // In Multiplayer, the server needs to have some correct location to determine what actors are
    // relevent to the optiwand camera.  Since there's no firstperson model, we'll have to use
    // a point offset from the player's location by the length of the optiwand.
    if ( Level.NetMode != NM_Standalone && FirstPersonModel == None )
    {
        GetAxes( Owner.Rotation, X, Y, Z );
        CameraLocation = Owner.Location + X * kOptiwandLength + Z * 20;
    }
    // In standalone use the bones available to us...
    else
    {
        // Mirroring under a door uses a point on the other side of the door and not the camera lens bone location
        if ( bMirroring )
        {
            if ( MirroringDoor.ActorIsToMyLeft( Owner ) )
                DoorBoneName = 'OptiwandRIGHT';
            else
                DoorBoneName = 'OptiwandLEFT';
            CameraLocation = MirroringDoor.GetBoneCoords( DoorBoneName, true ).Origin;
            PlayerViewRot = Owner.Rotation;
        }
        else
        {
            if ( FirstPersonModel != None )
                CameraLocation = FirstPersonModel.GetBoneCoords(BoneName, true).Origin;
            else
                CameraLocation = Owner.Location;
            PlayerViewRot = Pawn(Owner).GetViewRotation();
        }
    }

}

simulated function  ViewportCalcView(out Vector CameraLocation, out Rotator CameraRotation)
{
    local Rotator PlayerViewRot;
    local Quat OldQuat, NewQuat;
    local Object.Range YawRange, PitchRange;

    // Most of the time this is all we need to take care of
	FirstPersonModel.SetBoneDirection(BoneName, Pawn(Owner).GetViewRotation(),,, 1);
    ResolveInitialLocationAndRotation( CameraLocation, PlayerViewRot );

    // Only handle this stuff when we're actually moving the mouse.
    if ( VSize(MouseAccel) != 0 )
    {
        DesiredViewRotation.Yaw += MouseAccel.X * LensTurnSpeed * LastDeltaTime;
        DesiredViewRotation.Pitch += MouseAccel.Y * LensTurnSpeed * LastDeltaTime;

        YawRange.Min = PlayerViewRot.Yaw - DegreesToUnreal(ClampYawAngle);
        YawRange.Max = PlayerViewRot.Yaw + DegreesToUnreal(ClampYawAngle);
        PitchRange.Min = PlayerViewRot.Pitch - DegreesToUnreal(ClampPitchAngle);
        PitchRange.Max = PlayerViewRot.Pitch + DegreesToUnreal(ClampPitchAngle);

        DesiredViewRotation.Yaw = Clamp( DesiredViewRotation.Yaw, YawRange.Min, YawRange.Max );
        DesiredViewRotation.Pitch= Clamp( DesiredViewRotation.Pitch, PitchRange.Min, PitchRange.Max );
    }

    // When FirstPersonModel is none, this function is being called for visibility calcluations on the server, don't slerp
    if ( FirstPersonModel == None )
    {
        CameraRotation = DesiredViewRotation;
    }
    else
    {
        // Slerp the lens bone, and use the slerp'd bone rotation as the camera rotation so wysiwyg
        OldQuat = QuatFromRotator(FirstPersonModel.GetBoneRotation(BoneName, 1));
        NewQuat = QuatFromRotator(DesiredViewRotation);
        BoneRotation = QuatToRotator(QuatSlerp(OldQuat, NewQuat, LensTurnAlpha));
        FirstPersonModel.SetBoneDirection( BoneName, BoneRotation,,,1 );
        CameraRotation = BoneRotation;
    }
}

// Unimplemented IControllableViewport functions
simulated function HandleFire();
simulated function HandleAltFire();
simulated function HandleReload();
simulated function IControllableThroughViewport GetCurrentControllable();

// =============================================================================
simulated function bool ShouldUseWhileLowReady()
{
    return CanUseNow();
}

simulated function bool ShouldLowReadyOnOfficers()
{
    return false;
}

simulated function bool ShouldLowReadyOnArrestable()
{
    return false;
}

simulated function bool CanUseNow()
{
    local SwatGamePlayerController PC;
    local FireInterface FireInterface;
    local Vector X, Y, Z;

    // There is a really funky exploit that happens in first person view and are close to a wall, where if you move the camera really
    // quick towards a wall, you can sometimes press fire and use the optiwand BEFORE the low ready interface updates and realizes that
    // there's an obstruction in front of you.  In multiplayer this can be REALLY BAD (TM), cuz it allows you to look through walls and doors.
    // The only way to catch it is to do this fast trace...
    if ( FirstPersonModel != None && MirroringDoor == None )
    {
        GetAxes( Owner.Rotation, X, Y, Z );
        if ( !FastTrace( Owner.Location + X * kOptiwandLength, Owner.Location ) )
        {
            log("fast trace blocked!");
            return false;
        }
    }

    //Normally, the Optiwand can't be used while in low-ready.
    //However, Players may use the Optiwand while in low-ready
    //  if they are currently looking at an optiwand spot on a door.
    if ( SwatPawn(Owner) != None && !SwatPawn(Owner).IsLowReady() )
        return true;

    PC = SwatGamePlayerController(Pawn(Owner).Controller);
    if (PC == None) return false;  //not a Player (in MP, only the Server should test this for Players)

    FireInterface = FireInterface(PC.GetFocusInterface(Focus_Fire));
    if (FireInterface == None) return false;   //fail-safe... a SwatGamePlayerController should always have a FireInterface if they're trying to use an item

    return FireInterface.HasContext('OptiwandOnDoor');
}

simulated function InterruptUsing()
{
    local Name EndAnim;

    if ( !CompletedUsing )
    {
        OnUsingFinished();
        if ( bMirroring )
            EndAnim = 'OptiwandDoorUseEnd';
        else
            EndAnim = 'OptiwandUseEnd';
		// Stop playing any sounds from looping...
        SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopMySchemas(Pawn(Owner).GetHands());
        Pawn(Owner).GetHands().PlayAnim(EndAnim);
        Disable('Tick');
    }
}


simulated latent protected function OnUsingBegan()
{
}

simulated function PreUse()
{
    Super.PreUse();
    CompletedUsing = false;
}

// Play the using animation
simulated latent protected function DoUsingHook()
{
    local Hands Hands;
    local Pawn PawnOwner;
    local SwatGamePlayerController PC;
    local SwatPlayer PlayerOwner;
    local Quat OldQuat, NewQuat;
    local Rotator ViewRot;
    local Name UseAnim, EndAnim;

    assertWithDescription( FirstPersonModel!=None, Self$", does not have a firstpersonmodel!!" );
    assertWithDescription( Owner.IsA( 'SwatPawn' ), Self$" has an owner - "$Owner$" that is NOT a swatpawn!" );

    mplog( Self$" DoUsingHook() Latent function 1" );
    // The optiwand just plays its use animations on the hands
    PawnOwner = Pawn(Owner);
    PlayerOwner = SwatPlayer(Owner);
    PC = SwatGamePlayerController(PlayerOwner.Controller);

    if ( PC != None )
    {
        MirroringDoor = PC.GetDoorInWay();
        bMirroring = MirroringDoor != None;
    }

    Hands = PawnOwner.GetHands();

    mplog( Self$" DoUsingHook() Latent function 2" );
    if ( !CanUseNow() )
    {
        // We completed using in the sense that nothing interrupted the using of this optiwand...
        CompletedUsing = true;
        return;
    }

    Enable('Tick');
    mplog( Self$" DoUsingHook() Latent function 3" );
    if ( PlayerOwner != None )
    {
        // Setup using for players, make sure the hands play the correct animation, and that the initial rotation is set correctly...
        if ( bMirroring )
        {
            UseAnim = 'OptiwandDoorUse';
            EndAnim = 'OptiwandDoorUseEnd';

            DesiredViewRotation = Pawn(Owner).Rotation;
        }
        else
        {
            UseAnim = 'OptiwandUse';
            EndAnim = 'OptiwandUseEnd';

            DesiredViewRotation = Pawn(Owner).GetViewRotation();
        }
    }
    FirstPersonModel.SetBoneDirection(BoneName, DesiredViewRotation,,, 1);

    mplog( Self$" DoUsingHook() Latent function 4" );
    // Hands
    if (Hands != None)
    {
        Hands.PlayAnim(UseAnim);
        Hands.FinishAnim();
    }

    mplog( Self$" DoUsingHook() Latent function 5" );
    // Make sure the screen only starts rendering when going after we've played the animation to bring the optiwand screen up
    if ( PlayerOwner != None )
    {
        LCDScreen.Revision++;
        // Use the scripted texture now...
        FirstPersonModel.Skins[1] = LCDShader;
    }

    mplog( Self$" DoUsingHook() Latent function 6" );
    while( ShouldControlViewport() )
    {
        Sleep(TimerFreq);
        LCDScreen.Revision++;
    }

    /*if ( PlayerOwner != None )
    {
        // Use the blank screen texture now
        FirstPersonModel.Skins[1] = BlankScreen;
    }*/

    mplog( Self$" DoUsingHook() Latent function 7" );
    ViewRot = Pawn(Owner).GetViewRotation();
    // Slerp the lens back to facing forward
    while(VSize(vector(BoneRotation)-vector(ViewRot)) > 0.1)
    {
        Sleep(0);
        OldQuat = QuatFromRotator(FirstPersonModel.GetBoneRotation(BoneName, 1));
        NewQuat = QuatFromRotator(Pawn(Owner).GetViewRotation());
        BoneRotation = QuatToRotator(QuatSlerp(OldQuat, NewQuat, LensFinishSpeed));
        FirstPersonModel.SetBoneDirection( BoneName, BoneRotation,,1,1 );
    }

    mplog( Self$" DoUsingHook() Latent function 8" );
    if (Hands != None)
    {
        Hands.PlayAnim(EndAnim);
        Hands.FinishAnim();
    }

    bMirroring = false;
    MirroringDoor = None;
    CompletedUsing = true;
    Disable('Tick');
}


// Render a portal to the lcdscreen from the desired viewport loc and rot
simulated event RenderTexture(ScriptedTexture inTexture)
{
    local vector DrawLoc;
    local Rotator DrawRot;

    local Color White;

    White.R = 255; White.G = 0; White.B = 0;

    ViewportCalcView(DrawLoc, DrawRot);
    LCDScreen.DrawPortal(0, 0, SizeX, SizeY, Level.GetLocalPlayerController(), DrawLoc, DrawRot, FOV);
    //LCDScreen.DrawTile(SizeX/2, SizeY/2,  32, 32, 0, 0, 32, 32, ReticleTexture, White);
}

simulated function Tick(float DeltaTime)
{
    LastDeltaTime = DeltaTime;
}

defaultproperties
{
    Slot=Slot_Optiwand
    LCDScreen=ScriptedTexture'scripted_tex.lcd_scripted_tex'
    LCDShader=Shader'scripted_tex.lcd_shader'
    GunShader=Shader'SWAT1stPersonTex.Optiwand1stPersonShader'
    DrawType=DT_Mesh
    RefreshRate=100
    SizeX=2048
    SizeY=2048
    BoneName=lens
    FOV=60
    ReticleTexture=Material'HUD.ToolReticle'
    BlankScreen=Material'Hotel.hot_blueroll_panner'
    LensTurnSpeed=0.3
    ClampYawAngle=60
    ClampPitchAngle=45
    LensFinishSpeed=0.1
}
