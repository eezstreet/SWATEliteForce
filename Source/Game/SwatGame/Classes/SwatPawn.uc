///////////////////////////////////////////////////////////////////////////////

class SwatPawn extends Engine.Pawn
    implements  SwatAICommon.ISwatPawn,
                Engine.ICanToggleWeaponFlashlight,
                ICanBeArrested
	dependson(AnimationSetManager)
    abstract
    native
    config(SwatPawn);

///////////////////////////////////////////////////////////////////////////////

import enum EAnimationSet from AnimationSetManager;
import enum AimPenaltyType from FiredWeapon;
import enum WeaponAimAnimationType from SwatWeapon;
import enum WeaponLowReadyAnimationType from SwatWeapon;

///////////////////////////////////////////////////////////////////////////////
//
// Constants

// aim constants
const kAimHighLimitDegrees    = 70.0f;
const kAimLowLimitDegrees     = 62.0f;
const kAimLeftLimitDegrees    = 54.0f;
const kAimRightLimitDegrees   = 77.0f;

///////////////////////////////////////////////////////////////////////////////
//
// Enums

enum EAnimFlag
{
    kAF_TurnInPlace,
    kAF_Move,
    kAF_Aim,
    kAF_Equipment,
    kAF_Special,
};

///////////////////

// How quickly the animation will rotate the model to achieve the desired aim

enum EAnimRotationUrgency
{
    kARU_Normal,
    kARU_Fast,
    kARU_VeryFast,
    kARU_Instant,
};

///////////////////

// How quickly the blend on the weapon will be made

enum EAnimAimRotationUrgency
{
    kAARU_Normal,
    kAARU_Fast
};

///////////////////////////////////////////////////////////////////////////////

// Animation related variables

// The currently composited animation set for this pawn
var protected AnimationSet AnimSet;

// Bone names
var protected config name AnimBoneBase;
var protected config name AnimBoneSpineLow;
var protected config name AnimBoneRightShoulder;
var protected config name AnimBoneHead;
var protected config name AnimBoneJaw;

var protected config name NormalAimLocationBone;
var protected config name LeanAimLocationBone;

var protected config name NormalFireLocationBone;
var protected config name LeanFireLocationBone;

// Socket names
var protected config name AnimSocketGripRhand;
var protected config name AnimSocketGripBack;
var protected config name AnimSocketGripHolster;
var protected config name AnimSocketGripBelt1;
var protected config name AnimSocketGripBelt2;
var protected config name AnimSocketHolster;
var protected config name AnimSocketPouch;
var protected config name AnimSocketHeadGear;

var protected config array<string> MaleAnimGroups;
var protected config array<string> FemaleAnimGroups;

// percentage of health left required to play intense Injury speech
var private config float PercentageHealthForIntenseInjury;

// Animation state variables

// Flags allowing subclasses to specify what animation engine behaviors should
// be enabled.

var private int                     AnimFlags[EAnimFlag.EnumCount];

// @HACK: Allows us to not start dropping the alpha of these channels until 1
// frame after an animation on these channels finish, allowing script to do
// a latent-wait-till-finish then play a new anim, to chain a bunch of
// animations together without the alpha getting dropped by the native anim
// update code.
var private bool                    bWasSpecialChannelAnimatingLastFrame;
var private bool                    bWasEquipmentChannelAnimatingLastFrame;

var private float                   AnimSpecialAlphaOverride;
var private bool                    bIsAnimSpecialAlphaOverrideEnabled;
var private float                   AnimEquipmentAlphaOverride;
var private bool                    bIsAnimEquipmentAlphaOverrideEnabled;
var private float                   AnimBaseYaw;
var private float                   AnimBaseTurnToYaw;
var private bool                    bIsAnimBaseTurnToYawValid;
var private EAnimRotationUrgency    AnimRotationUrgency;
var private EAnimAimRotationUrgency AnimAimRotationUrgency;
var private bool					bIsTurning;

var private float                   AverageSpeedSamples[5];
var private int                     AverageSpeedSampleIndex;
var private int                     LastSpeedSampleTick;

// Similar to the Pawn's BlendChangeTime, but specific to the aiming transitions.
var private float AimBlendChangeTime;

// Inertial aim data
var private float InertialAimAcceleration;
var private float InertialAimDeceleration;
var private float InertialAimMaxVelocity;
var private float InertialAimPositionPitch;
var private float InertialAimPositionYaw;
var private float InertialAimVelocityPitch;
var private float InertialAimVelocityYaw;

// Mouth movement data
var private bool bIsMouthMoving;
var private PerlinNoise MouthMovementPerlinNoise;

///////////////////

enum EAnimAimType
{
    kAAT_None,
    kAAT_Rotation,
    kAAT_Point,
    kAAT_Actor,
};

var protected EAnimAimType AnimAimType;
var protected rotator      AnimAimRotator;
var protected vector       AnimAimPoint;
var protected Actor        AnimAimActor;

///////////////////

// Enum used natively, and in a subclass
enum ELeanTransitionState
{
    kLST_LeanLeft,
    kLST_LeanRight,
    kLST_UnleanLeft,
    kLST_UnleanRight,
};

var private ELeanState              AnimLeanState;

var private bool                    bAnimDrawDebugLines;

// Door Knowledge
//
// Script-declared TMaps are always transient even if not declared so, hence
// we need to serialize this native to ensure references are counted properly
// during Garbage Collection
var private const transient Map<Name, PawnDoorKnowledge> DoorKnowledgeMap;

// Flashlight state
var private bool FlashlightShouldBeOn; // Does the pawn want its flashlights on or off?
var private bool NightvisionShouldBeOn;

// Low ready state variables
var protected bool                  bIsLowReady;
var protected name                  ReasonForLowReady;

var protected bool                  bShouldBeAtLowReady;            // used for network replication
var protected name                  ReasonForShouldBeAtLowReady;    // used for network replication

// Stairs
var private bool					bIsOnStairs;		// if we're currently on a blocking volume where bIsStairs is true
var private bool					bGoingUpStairs;
var private vector					LastLocation;		// where we were last tick

// Variables for being affected by nonlethals.
var protected bool bIsFlashbanged;
var protected bool bIsGassed;
var protected bool bIsPepperSprayed;
var protected bool bIsStung;
var protected bool bIsStunnedByC2;
var protected bool bIsTased;

var bool bIsWearingNightvision;


// Compliance
var private config float			MaxComplianceIssueDistance;


// Being Arrested
var private bool					bArrested;					// if we are arrested
var private bool					BeingArrested;				// if we are being arrested
var private Pawn					ArrestedBy;					// who arrested us
var protected config float			QualifyTimeForArrest;

// Fire Modes
var bool                            bWantsToContinueAutoFiring;  //if auto-firing, should contine.  NOTE: This does *not* indicate whether the Pawn is currently firing at all.

// shadows
var (Shadow) float ShadowLightDistance "Specifies how far the shadow-casting light source is from the pawn";
var (Shadow) float ShadowExtraDrawScale "This allows us to contol the scale of the shadow texture when it is rendered onto the world";
var (Shadow) float MaxShadowTraceDistance "Distance from the pawn after shadows do not project onto surfaces";
var (Shadow) float ShadowCullDistance "Shadows will completely disappear when the pawn is further than this distance away from the viewer";

// Lean positional and rotational offset on the camera
var private Vector  LeanPositionOffset;
var private Rotator LeanRotationOffset;
var private float   LastLeanOffsetsUpdateTime;

// Tweakable parameters for conmtrolling the extent and feel of the camera lean
var config private float LeanVerticalDistance;
var config private float LeanRollDegrees;
var config private float LeanBezierPt1X;
var config private float LeanBezierPt1Y;
var config private float LeanBezierPt2X;
var config private float LeanBezierPt2Y;

// MCJ: see me if you have questions about this.
// The optiwand needs to cache the controller here, since we need to
// shut down the optiwand after Controller has been set back to None.
var Controller CachedPlayerControllerForOptiwand;

// Crombie: we need to extend the render bounding box so that ragdolls don't disappear at
// certain angles when we die
var const float RenderBoundingBoxExpansionSize;
const kDeathRenderBoundingBoxExpansionSize = 100.0;

// Keeps track of the aim rotator from the last tick. We only RPC it to the
// server when it changes.
var private Rotator LastAimRotator;

// dbeswick: havok character interaction
var config float HavokObjectInteractionFactor;

///////////////////////////////////////////////////////////////////////////////

replication
{
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (((RemoteRole == ROLE_AutonomousProxy) && bNetInitial)
						|| ((RemoteRole == ROLE_SimulatedProxy) && (bNetInitial || bUpdateSimulatedPosition) && ((Base == None) || Base.bWorldGeometry))
						|| ((RemoteRole == ROLE_DumbProxy) && ((Base == None) || Base.bWorldGeometry))) )
        AnimAimRotator;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (Role == ROLE_AutonomousProxy) )
		ServerSetAimRotation;

    // replicated functions sent to server by owning client
    reliable if( Role < ROLE_Authority )
        ServerToggleDesiredFlashlightState, ServerSetLowReadyStatus;

    reliable if ( Role == ROLE_Authority )
        AnimFlags, FlashlightShouldBeOn, NightvisionShouldBeOn, bShouldBeAtLowReady, ReasonForShouldBeAtLowReady, bArrested, BeingArrested;

    reliable if ( Role == ROLE_Authority && RemoteRole != ROLE_AutonomousProxy )
        bIsFlashbanged, bIsGassed, bIsPepperSprayed, bIsStung, bIsStunnedByC2, bIsTased, bIsWearingNightvision;
}

///////////////////////////////////////////////////////////////////////////////

simulated event PostBeginPlay()
{
    local int ShadowDetail;
	local string ShadowDetailString;

    log( self$"---SwatPawn::PostBeginPlay()." );

    Super.PostBeginPlay();

    //New for the "High" shadow quality setting. -K.F.
    ShadowDetailString = Level.GetLocalPlayerController().ConsoleCommand( "SHADOWDETAIL GET" );
    ShadowDetail = int(ShadowDetailString);
	// bAcceptsShadowProjectors cannot be set using any kind of conditional logic.
	// You can't do "if (ShadowDetail >= 3) bAcceptsShadowProjectors = true;"
	// You can't do "if (ShadowDetailString == "3") bAcceptsShadowProjectors = true;"
	// You can't do "bAcceptsShadowProjectors = (ShadowDetail > 3)"
	// Any such approach will set the value, but the value will not be *applied*.
	// Don't believe me? Try it. Anyway, it is safe to always set this to true, since
	// it will only have an effect when ShadowProjector's bProjectActor property is true
	//   -K.F.
	bAcceptsShadowProjectors = true;

    if (bActorShadows && Level.NetMode != NM_DedicatedServer)
    {
        Shadow = Spawn(class'ShadowProjector',self,'',Location);
        Shadow.ShadowActor = self;
        Shadow.bBlobShadow = false;
        Shadow.LightDirection = Normal(vect(1,1,3));
        Shadow.LightDistance = ShadowLightDistance;
        Shadow.ShadowExtraDrawScale = ShadowExtraDrawScale;
        Shadow.MaxTraceDistance = MaxShadowTraceDistance;
        Shadow.RootMotion = true;
        Shadow.CullDistance = ShadowCullDistance;
        Shadow.Resolution = 256;
        Shadow.InitShadow();

        if (ShadowDetail >= 3) //3 = "High"
        {
            Shadow.Resolution = 512;
            //Level.GetLocalPlayerController().ConsoleMessage("High quality shadows enabled!");
        }
    }

    // Initialize the perlin noise object for mouth movement
    InitAnimationForCurrentMesh();
    InitMouthMovementPerlinNoise();
}

simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    // Initialize the skeleton's yaw to the aim direction yaw
    AnimBaseYaw = AnimAimRotator.Yaw;
}

simulated event Destroyed()
{
 	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPawn::Destroyed(). controller="$Controller );

    Super.Destroyed();
    if ( Level.NetMode != NM_Client )
    {
        SwatGameInfo(Level.Game).GameEvents.PawnDestroyed.Triggered(self);
    }
}

///////////////////////////////////////

// This should be called anytime a new mesh is linked to this pawn
simulated function InitAnimationForCurrentMesh()
{
    log( self$"---SwatPawn::InitAnimationForCurrentMesh()." );

    log( "...AnimSet="$AnimSet );
    if (AnimSet == None)
    {
        log( "...creating new AnimationSet." );
        AnimSet  = new class'AnimationSet';
    }

    AnimLoadPackageGroups();
    InitNativeAnimationSystemForPawn();
	ChangeAnimation();
}

private native function InitNativeAnimationSystemForPawn();

///////////////////////////////////////

// returns the male animation groups by default
// overridden in SwatAICharacter to allow for female animation groups.
// NOTE: this will probably need to be done differently in the future, but
// for now it allows the animators to have the females in game and using
// the female animations [crombie]
simulated function array<string> GetAnimPackageGroups()
{
    log( self$"---SwatPawn::GetAnimPackageGroups()." );
	return MaleAnimGroups;
}

// loads the anim groups based on an array of strings defined in a config file
// currently just loads the male anim groups, see above function for comment
// don't change without testing with AIs (especially females!)
simulated function AnimLoadPackageGroups()
{
    log( self$"---SwatPawn::AnimLoadPackageGroups()." );
    LoadAnimationSets(GetAnimPackageGroups());
}

simulated static function StaticGetAnimPackageGroups( out array<String> AnimationSetNames, bool LoadFemalePackageGroups )
{
    local int i;
log( "SwatPawn::StaticGetAnimPackageGroups( "$LoadFemalePackageGroups$" )" );
    for (i=0; i<default.MaleAnimGroups.length; ++i)
    {
        AnimationSetNames[AnimationSetNames.Length] = default.MaleAnimGroups[i];
    }

    if( LoadFemalePackageGroups )
    {
        for (i=0; i<default.FemaleAnimGroups.length; ++i)
        {
            AnimationSetNames[AnimationSetNames.Length] = default.FemaleAnimGroups[i];
        }
    }
}

///////////////////////////////////////

// Convenience function. Retrieves the appropriate set's name bank, and calls
// DoAnimSwapToSet.
simulated function AnimSwapInSet(EAnimationSet set)
{
    local AnimationSetManager AnimationSetManager;
    local AnimationSet setObject;

    //log( "ASwatPawn["$name$"]::AnimSwapInSet(script), set = "$GetEnum(enum'EAnimationSet', set));

    // Verify that the animation system has been initialized
    if (AnimSet != None)
    {
        AnimationSetManager = SwatRepo(Level.GetRepo()).GetAnimationSetManager();
        if (AnimationSetManager != None)
        {
            setObject = AnimationSetManager.GetAnimationSet(set);
            assert(setObject != None);

            // Perform the animation channel swapping
            AnimSwapInSet_Native(setObject);
        }
    }
}

private native function AnimSwapInSet_Native(AnimationSet set);

simulated function bool ShouldUseCuffedAnims()
{
    return IsArrested() || IsBeingArrestedNow();
}

///////////////////////////////////////
//
// Movement animation set swapping

simulated function EAnimationSet GetCompliantAnimSet()						{ return kAnimationSetCompliant; }
simulated function EAnimationSet GetRestrainedAnimSet()						{ return kAnimationSetRestrained; }
simulated function EAnimationSet GetStandingWalkAnimSet()					{ return kAnimationSetStealthStanding; }
simulated function EAnimationSet GetStandingWalkUpStairsAnimSet()			{ return kAnimationSetStealthStandingUpStairs; }
simulated function EAnimationSet GetStandingWalkDownStairsAnimSet()			{ return kAnimationSetStealthStandingDownStairs; }
simulated function EAnimationSet GetStandingRunAnimSet()					{ return kAnimationSetDynamicStanding; }
simulated function EAnimationSet GetStandingRunUpStairsAnimSet()			{ return kAnimationSetDynamicStandingUpStairs; }
simulated function EAnimationSet GetStandingRunDownStairsAnimSet()			{ return kAnimationSetDynamicStandingDownStairs; }
simulated function EAnimationSet GetCrouchingAnimSet()						{ return kAnimationSetCrouching; }
simulated function EAnimationSet GetStandingInjuredAnimSet()				{ return kAnimationSetInjuredStanding; }
simulated function EAnimationSet GetStandingInjuredUpStairsAnimSet()		{ return kAnimationSetStealthStandingUpStairs; }
simulated function EAnimationSet GetStandingInjuredDownStairsAnimSet()		{ return kAnimationSetStealthStandingDownStairs; }
simulated function EAnimationSet GetCrouchingInjuredAnimSet()				{ return kAnimationSetInjuredCrouching; }

simulated native event bool IsLowerBodyInjured();

// don't override, override the accessors above.
simulated function EAnimationSet GetMovementAnimSet()
{
    if (IsArrested())
    {
        return GetRestrainedAnimSet();
    }
    else if (IsCompliant())
    {
        return GetCompliantAnimSet();
    }
    else if ( IsLowerBodyInjured() || CanBeArrestedNow() )
    {
        if (bIsCrouched)
        {
            return GetCrouchingInjuredAnimSet();
        }
        else
        {
			if (bIsOnStairs)
			{
				if (bGoingUpStairs)
				{
					return GetStandingInjuredUpStairsAnimSet();
				}
				else
				{
					return GetStandingInjuredDownStairsAnimSet();
				}
			}
			else
			{
	            return GetStandingInjuredAnimSet();
			}
		}
    }
    else
    {
        if (bIsCrouched)
        {
            return GetCrouchingAnimSet();
        }
        else if (ShouldPlayWalkingAnimations())
        {
			if (bIsOnStairs)
			{
				if (bGoingUpStairs)
				{
					return GetStandingWalkUpStairsAnimSet();
				}
				else
				{
					return GetStandingWalkDownStairsAnimSet();
				}
			}
			else
			{
				return GetStandingWalkAnimSet();
			}
        }
        else
        {
			if (bIsOnStairs)
			{
				if (bGoingUpStairs)
				{
					return GetStandingRunUpStairsAnimSet();
				}
				else
				{
					return GetStandingRunDownStairsAnimSet();
				}
			}
			else
			{
				return GetStandingRunAnimSet();
			}
        }
    }
}

simulated protected function SetThirdPersonMovementAnims()
{
    //log( self$"---SwatPawn::SetThirdPersonMovementAnims(). " );

    // swap in the correct animation set for the piece of equipment
    AnimSwapInSet(GetMovementAnimSet());
}

///////////////////////////////////////
//
// Equipment animation set swapping

// Allow subclasses (AIs) to override their aim pose animation sets
simulated function EAnimationSet GetHandgunAimPoseSet()                 { if (!bIsCrouched) return kAnimationSetHandgun;        else return kAnimationSetHandgunCrouched; }
simulated function EAnimationSet GetSubMachineGunAimPoseSet()           { if (!bIsCrouched) return kAnimationSetSubMachineGun;  else return kAnimationSetSubMachineGunCrouched; }
simulated function EAnimationSet GetMachineGunAimPoseSet()              { if (!bIsCrouched) return kAnimationSetMachineGun;     else return kAnimationSetMachineGunCrouched; }
simulated function EAnimationSet GetShotgunAimPoseSet()                 { if (!bIsCrouched) return kAnimationSetShotgun;        else return kAnimationSetShotgunCrouched; }
simulated function EAnimationSet GetThrownWeaponAimPoseSet()            { if (!bIsCrouched) return kAnimationSetThrownWeapon;   else return kAnimationSetThrownWeaponCrouched; }
simulated function EAnimationSet GetTacticalAidAimPoseSet()             { if (!bIsCrouched) return kAnimationSetTacticalAid;    else return kAnimationSetTacticalAidCrouched; }
simulated function EAnimationSet GetTacticalAidUseAimPoseSet()          { return kAnimationSetTacticalAidUse; }
simulated function EAnimationSet GetPepperSprayAimPoseSet()             { if (!bIsCrouched) return kAnimationSetPepperSpray;    else return kAnimationSetPepperSprayCrouched; }
simulated function EAnimationSet GetM4AimPoseSet()                      { if (!bIsCrouched) return kAnimationSetM4;             else return kAnimationSetM4Crouched; }
simulated function EAnimationSet GetUMPAimPoseSet()                     { if (!bIsCrouched) return kAnimationSetUMP;            else return kAnimationSetUMPCrouched; }
simulated function EAnimationSet GetP90AimPoseSet()                     { if (!bIsCrouched) return kAnimationSetP90;            else return kAnimationSetP90Crouched; }
simulated function EAnimationSet GetOptiwandAimPoseSet()                { if (!bIsCrouched) return kAnimationSetOptiwand;       else return kAnimationSetOptiwandCrouched; }
simulated function EAnimationSet GetPaintballAimPoseSet()               { if (!bIsCrouched) return kAnimationSetPaintball;      else return kAnimationSetPaintballCrouched; }
simulated function EAnimationSet GetCuffedAimPoseSet()                  { return kAnimationSetCuffed; }

// Returns the animation set based on the Pawns current equipment
simulated function EAnimationSet GetEquipmentAimSet()
{
    local HandheldEquipment Equipment;
    local SwatWeapon Weapon;

    if (ShouldUseCuffedAnims())
    {
        return GetCuffedAimPoseSet();
    }

    Equipment = GetActiveItem();
    Weapon = SwatWeapon(Equipment);
    if (GetActiveItem() != None)
    {
        if(Weapon != None)
        {
          switch(Weapon.GetAimAnimation())
          {
            case WeaponAnimAim_Handgun:
              return GetHandgunAimPoseSet();
            case WeaponAnimAim_SubmachineGun:
              return GetSubMachineGunAimPoseSet();
            case WeaponAnimAim_MachineGun:
              return GetMachineGunAimPoseSet();
            case WeaponAnimAim_Shotgun:
              return GetShotgunAimPoseSet();
            case WeaponAnimAim_Grenade:
              return GetThrownWeaponAimPoseSet();
            case WeaponAnimAim_TacticalAid:
              return GetTacticalAidAimPoseSet();
            case WeaponAnimAim_TacticalAidUse:
              return GetTacticalAidUseAimPoseSet();
            case WeaponAnimAim_PepperSpray:
              return GetPepperSprayAimPoseSet();
            case WeaponAnimAim_M4:
              return GetM4AimPoseSet();
            case WeaponAnimAim_UMP:
              return GetUMPAimPoseSet();
            case WeaponAnimAim_P90:
              return GetP90AimPoseSet();
            case WeaponAnimAim_Optiwand:
              return GetOptiwandAimPoseSet();
            case WeaponAnimAim_Paintball:
              return GetPaintballAimPoseSet();
            case WeaponAnimAim_Cuffed:
              return GetCuffedAimPoseSet();
          }
        }
        else if (Equipment.IsA('ThrownWeapon'))
        {
            return GetThrownWeaponAimPoseSet();
        }
        else if (Equipment.IsA('ITacticalAid'))
        {
            // Special case aim pose for the pepperspray
            if (Equipment.IsA('PepperSpray'))
            {
                return GetPepperSprayAimPoseSet();
            }
            else
            {
                if (Equipment.IsBeingUsed())
                {
                    return GetTacticalAidUseAimPoseSet();
                }
                else
                {
                    return GetTacticalAidAimPoseSet();
                }
            }
        }
        else if (Equipment.IsA('Optiwand'))
        {
            return GetOptiwandAimPoseSet();
        }
        else if (Equipment.IsA('IAmCuffed'))
        {
            return GetCuffedAimPoseSet();
        }
    }

    // If we haven't returned anything by this point, use the null aim set
    return kAnimationSetNull;
}

native function AnimStopAimChannels();

simulated protected function SetThirdPersonEquipmentAnims()
{
    local EAnimationSet animationSet;
    animationSet = GetEquipmentAimSet();
    if (animationSet != kAnimationSetNull)
    {
        // swap in the correct animation set for the piece of equipment
        AnimSwapInSet(animationSet);
    }
    else
    {
        AnimStopAimChannels();
    }
}

///////////////////////////////////////
//
// Low-ready animation set swapping

// Allow subclasses (AIs) to override their aim pose animation sets
simulated function EAnimationSet GetHandgunLowReadyAimPoseSet()         { if (!bIsCrouched) return kAnimationSetHandgunLowReady;        else return kAnimationSetHandgunLowReadyCrouched; }
simulated function EAnimationSet GetSubMachineGunLowReadyAimPoseSet()   { if (!bIsCrouched) return kAnimationSetSubMachineGunLowReady;  else return kAnimationSetSubMachineGunLowReadyCrouched; }
simulated function EAnimationSet GetMachineGunLowReadyAimPoseSet()      { if (!bIsCrouched) return kAnimationSetMachineGunLowReady;     else return kAnimationSetMachineGunLowReadyCrouched; }
simulated function EAnimationSet GetShotgunLowReadyAimPoseSet()         { if (!bIsCrouched) return kAnimationSetShotgunLowReady;        else return kAnimationSetShotgunLowReadyCrouched; }
simulated function EAnimationSet GetThrownWeaponLowReadyAimPoseSet()    { if (!bIsCrouched) return kAnimationSetThrownWeaponLowReady;   else return kAnimationSetThrownWeaponLowReadyCrouched; }
simulated function EAnimationSet GetTacticalAidLowReadyAimPoseSet()     { if (!bIsCrouched) return kAnimationSetTacticalAidLowReady;    else return kAnimationSetTacticalAidLowReadyCrouched; }
simulated function EAnimationSet GetPepperSprayLowReadyAimPoseSet()     { if (!bIsCrouched) return kAnimationSetPepperSprayLowReady;    else return kAnimationSetPepperSprayLowReadyCrouched; }
simulated function EAnimationSet GetM4LowReadyAimPoseSet()              { if (!bIsCrouched) return kAnimationSetM4LowReady;             else return kAnimationSetM4LowReadyCrouched; }
simulated function EAnimationSet GetUMPLowReadyAimPoseSet()             { if (!bIsCrouched) return kAnimationSetUMPLowReady;            else return kAnimationSetUMPLowReadyCrouched; }
simulated function EAnimationSet GetP90LowReadyAimPoseSet()             { if (!bIsCrouched) return kAnimationSetP90LowReady;            else return kAnimationSetP90LowReadyCrouched; }
simulated function EAnimationSet GetOptiwandLowReadyAimPoseSet()        { if (!bIsCrouched) return kAnimationSetOptiwandLowReady;       else return kAnimationSetOptiwandLowReadyCrouched; }
simulated function EAnimationSet GetPaintballLowReadyAimPoseSet()       { if (!bIsCrouched) return kAnimationSetPaintballLowReady;      else return kAnimationSetPaintballLowReadyCrouched; }

// Returns the animation set based on the Pawns current equipment
simulated function EAnimationSet GetLowReadySet()
{
    local HandheldEquipment Equipment;
    local SwatWeapon Weapon;

    assert(bIsLowReady == true);

    // No low-ready while cuffed
    if (ShouldUseCuffedAnims())
    {
        return kAnimationSetNull;
    }

    Equipment = GetActiveItem();
    Weapon = SwatWeapon(Equipment);
    if (GetActiveItem() != None)
    {
        if(Weapon != None)
        {
          switch(Weapon.GetLowReadyAnimation())
          {
            case WeaponAnimLowReady_Handgun:
              return GetHandgunLowReadyAimPoseSet();
            case WeaponAnimLowReady_SubmachineGun:
              return GetSubMachineGunLowReadyAimPoseSet();
            case WeaponAnimLowReady_MachineGun:
              return GetMachineGunLowReadyAimPoseSet();
            case WeaponAnimLowReady_Shotgun:
              return GetShotgunLowReadyAimPoseSet();
            case WeaponAnimLowReady_Grenade:
              return GetThrownWeaponLowReadyAimPoseSet();
            case WeaponAnimLowReady_TacticalAid:
              return GetTacticalAidLowReadyAimPoseSet();
            case WeaponAnimLowReady_PepperSpray:
              return GetPepperSprayLowReadyAimPoseSet();
            case WeaponAnimLowReady_M4:
              return GetM4LowReadyAimPoseSet();
            case WeaponAnimLowReady_UMP:
              return GetUMPLowReadyAimPoseSet();
            case WeaponAnimLowReady_P90:
              return GetP90LowReadyAimPoseSet();
            case WeaponAnimLowReady_Optiwand:
              return GetOptiwandLowReadyAimPoseSet();
            case WeaponAnimLowReady_Paintball:
              return GetPaintballLowReadyAimPoseSet();
          }
        }
        else if (Equipment.IsA('ThrownWeapon'))
        {
            return GetThrownWeaponLowReadyAimPoseSet();
        }
        else if (Equipment.IsA('ITacticalAid'))
        {
            // Special case aim pose for the pepperspray
            if (Equipment.IsA('PepperSpray'))
            {
                return GetPepperSprayLowReadyAimPoseSet();
            }
            else if (!Equipment.IsBeingUsed())
            {
                return GetTacticalAidLowReadyAimPoseSet();
            }
        }
        else if (Equipment.IsA('Optiwand'))
        {
            return GetOptiwandLowReadyAimPoseSet();
        }
    }

    // If we haven't returned anything by this point, use the null aim set
    return kAnimationSetNull;
}

simulated protected function SetThirdPersonLowReadyAnims()
{
    local EAnimationSet animationSet;
    if (bIsLowReady)
    {
        animationSet = GetLowReadySet();
        if (animationSet != kAnimationSetNull)
        {
            // swap in the correct low-ready animation set for the piece of equipment
            AnimSwapInSet(animationSet);
        }
    }
}

///////////////////////////////////////
//
// Non-lethal effects animation set swapping

// Allow subclasses (AIs) to override their effected animation sets
simulated function EAnimationSet GetFlashbangedAnimSet()    { if (!ShouldUseCuffedAnims()) return kAnimationSetFlashbanged;   else return kAnimationSetFlashbangedCuffed; }
simulated function EAnimationSet GetGassedAnimSet()         { if (!ShouldUseCuffedAnims()) return kAnimationSetGassed;        else return kAnimationSetGassedCuffed; }
simulated function EAnimationSet GetPepperSprayedAnimSet()  { if (!ShouldUseCuffedAnims()) return kAnimationSetPepperSprayed; else return kAnimationSetPepperSprayedCuffed; }
simulated function EAnimationSet GetStungAnimSet()          { if (!ShouldUseCuffedAnims()) return kAnimationSetStung;         else return kAnimationSetStungCuffed; }
simulated function EAnimationSet GetTasedAnimSet()          { if (!ShouldUseCuffedAnims()) return kAnimationSetTased;         else return kAnimationSetTasedCuffed; }

// Returns the animation for the tactical aid that is currently affecting this pawn
simulated function EAnimationSet GetAffectedByTacticalAidAnimSet()
{
    if (IsFlashbanged())
    {
        return GetFlashbangedAnimSet();
    }
    else if (IsGassed())
    {
        return GetGassedAnimSet();
    }
    else if (IsPepperSprayed())
    {
        return GetPepperSprayedAnimSet();
    }
    else if (IsStung())
    {
        return GetStungAnimSet();
    }
	else if (IsStunnedByC2())
	{
        // @NOTE: the stunned by c2 behavior uses the flashbanged animations
		return GetFlashbangedAnimSet();
	}
    else if (IsTased())
    {
        return GetTasedAnimSet();
    }

    return kAnimationSetNull;
}

simulated protected function SetThirdPersonNonlethalReactionAnims()
{
    local EAnimationSet AffectedByTacticalAidAnimSet;
    AffectedByTacticalAidAnimSet = GetAffectedByTacticalAidAnimSet();
    if (AffectedByTacticalAidAnimSet != kAnimationSetNull)
    {
        AnimSwapInSet(AffectedByTacticalAidAnimSet);
    }
}

///////////////////////////////////////
//
// Mouth moving animation set swapping

simulated protected function EAnimationSet GetMouthMovementSet()
{
    return kAnimationSetMouthOpen;
}

simulated private function SetThirdPersonMouthMovementAnims()
{
    AnimSwapInSet(GetMouthMovementSet());
}

///////////////////////////////////////
//
// Lean animation set swapping

native protected function SetThirdPersonLeanAnims();

///////////////////////////////////////
//
// The glue that ties the various animation swapping functions together in the
// proper order.

simulated event ChangeAnimation()
{
    Super.ChangeAnimation();

    if (bPhysicsAnimUpdate)
    {
        SetThirdPersonMovementAnims();

        // @NOTE: Special case, only swap in equipement-specific and additional
        // animations iff the pawn isnt affected by a non-lethal.
        if (!IsNonlethaled())
        {
            SetThirdPersonEquipmentAnims();
            SetThirdPersonLowReadyAnims();
            SetAdditionalAnimSets();
        }

        SetThirdPersonNonlethalReactionAnims();
        SetThirdPersonMouthMovementAnims();

        // @NOTE: Special case, if hand-cuffed or getting hand-cuffed, the pawn should not be playing
        // lean animations.
        if (ShouldUseCuffedAnims() == false)
        {
            SetThirdPersonLeanAnims();
        }
    }
}

// allow subclasses to override
simulated protected function SetAdditionalAnimSets();

///////////////////////////////////////

simulated function StartMouthMovement()
{
    bIsMouthMoving = true;
}

simulated function StopMouthMovement()
{
    bIsMouthMoving = false;
}

simulated private function InitMouthMovementPerlinNoise()
{
    MouthMovementPerlinNoise = new class'Engine.PerlinNoise';
    MouthMovementPerlinNoise.Reinitialize();
}

///////////////////////////////////////

simulated event OnLeanStateChange()
{
    Super.OnLeanStateChange();

    if (LeanState != kLeanStateNone)
    {
        bIsAnimBaseTurnToYawValid = true;
        AnimBaseTurnToYaw = LeanLockedYaw;
    }

    SetThirdPersonLeanAnims();
}

///////////////////////////////////////

simulated function bool IsTurning()
{
	return bIsTurning;
}

///////////////////////////////////////

// Notifications called by OnEquipKeyFrame to let us know that the Active Item has been equipped
simulated function OnActiveItemEquipped()
{
    if (GetActiveItem() != None)
    {
        ChangeAnimation();
    }

    if ( HasEquippedFirstItemYet )
    TriggerEffectEvent('Equipped', GetActiveItem());

    dispatchMessage(new class'MessageItemEquipped'(label, GetActiveItem().class.name));

    if (IsControlledByLocalHuman())
        UpdateHUDFireMode();
}

simulated function OnEquippingFinished()
{
    Super.OnEquippingFinished();
    //mplog( self$"---SwatPawn::OnEquippingFinished()." );
    HasEquippedFirstItemYet = true;
}

simulated function OnActiveItemUnEquipped()
{
    TriggerEffectEvent('UnEquipped', GetActiveItem());

    if (IsControlledByLocalHuman())
        UpdateHUDFireMode();
}

///////////////////////////////////////

simulated event OnNonlethalEffectChanged()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::OnNonlethalEffectChanged()." );

    if ( Level.GetLocalPlayerController().Pawn != Self )
    {
        ChangeAnimation();
    }
}

///////////////////////////////////////

simulated event OnbIsTasedChanged()
{
    OnNonlethalEffectChanged();
}

///////////////////////////////////////

simulated event OnArrestedStatusChanged()
{
 	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPawn::OnArrestedStatusChanged()." );

    if ( Level.GetLocalPlayerController().Pawn != Self )
    {
        ChangeAnimation();
    }
}

///////////////////////////////////////

simulated function AimToRotation(rotator DesiredRotation);
simulated function vector GetViewDirection();
simulated function vector GetViewPoint();

///////////////////////////////////////

// called by client, executes on server
function ServerSetAimRotation( Rotator Rotator )
{
//log( self$"::ServerSetAimRotation( "$Rotator$" )" );
    if( IsBeingArrestedNow() )
        return;

	AnimAimRotator = Rotator;
    AnimAimType    = kAAT_Rotation;
}

///////////////////////////////////////

simulated function Rotator GetAimRotation()
{
    return AnimAimRotator;
}

///////////////////////////////////////

// Override from Pawn.uc
simulated function rotator AdjustAim(Ammunition FiredAmmunition, vector projStart, int aimerror)
{
    // MCJ: The AdjustAim in Pawn does the wrong thing on a network client,
    // because most of the pawns don't have controllers.
    if ( Level.NetMode == NM_Client )
    {
        return AnimAimRotator;
    }
    else
    {
        return Super.AdjustAim( FiredAmmunition, projStart, aimerror );
    }
}

///////////////////////////////////////

simulated function AnimSetAimRotation(Rotator Rotator)
{
//log( self$"::AnimSetAimRotation( "$Rotator$" )" );
    // Single-player, standalone game
    AnimAimRotator = Rotator;
    AnimAimType    = kAAT_Rotation;
    if (Level.NetMode != NM_Standalone)
    {
        // Only send RPC our aim rotation to the server when it changes from
        // the most recent tick. Since the RPC is unreliable, sometimes the
        // server might not have our exact rotation, but it will eventually
        // get the corrected value once the player begins rotating again. This
        // will only occur if the RPC right before the mouse coming to a stop
        // is the one that doesn't make it, and it's doubtful that the aim
        // error would be large under those circumstances. Regardless, if we
        // get bugs that people are having trouble shooting accurately in
        // network games, removing this if-statement (and just always calling
        // ServerSetAimRotation()) should be the first thing to try.
        if ( Rotator != LastAimRotator )
        {
            ServerSetAimRotation(Rotator);
            LastAimRotator = Rotator;
        }
    }
}

///////////////////////////////////////

simulated function AnimSetAimPoint(Vector Point)
{
    AnimAimPoint = Point;
    AnimAimType  = kAAT_Point;
}

///////////////////////////////////////

simulated function AnimSetAimActor(Actor Actor)
{
    AnimAimActor = Actor;
    AnimAimType  = kAAT_Actor;
}

///////////////////////////////////////

simulated function AnimAimUnset()
{
    AnimAimType = kAAT_None;
}

///////////////////////////////////////

simulated function bool AnimIsAimSet()
{
    return (AnimAimType != kAAT_None);
}

///////////////////////////////////////

// Returns a rotator describing the current aim rotation of the pawn,
// regardless of whether the aim target is set as a rotation, point, or actor.

native function Rotator AnimGetAimRotation();

///////////////////////////////////////

// Queries animation engine for whether or not the pawn is aimed at the desired
// rotation/point/actor (it can take time for a pawn to re-orient after given
// a new aim parameter).

native function bool AnimIsAimedAtDesired();

///////////////////////////////////////

// Queries animation engine for whether or not the pawn can aim at a desired
// rotation/point/actor

native function bool AnimCanAimAtDesiredPoint(vector Point);
native function bool AnimCanAimAtDesiredActor(Actor Actor);
native function bool AnimCanAimAtDesiredRotation(Rotator Rotation);

///////////////////////////////////////

simulated function bool IsLowReady()
{
    return bIsLowReady;
}

///////////////////////////////////////

simulated function SetLowReady(bool bEnable, optional name Reason)
{
//    log( self$"---SwatPawn::SetLowReady(). bEnable="$bEnable$", Reason="$Reason );

    // If the pawn never uses low-ready, for bEnable to false
    if (!CanPawnUseLowReady())
    {
        bEnable = false;
        Reason  = '';
    }

    if ( IsControlledByLocalHuman() )
    {
        ServerSetLowReadyStatus( bEnable, Reason );
    }

    if (bIsLowReady != bEnable || ReasonForLowReady != Reason)
    {
        bIsLowReady = bEnable;
        ReasonForLowReady = Reason;
        ChangeAnimation();
    }
}

///////////////////////////////////////

simulated protected function bool CanPawnUseLowReady() { return false; }

///////////////////////////////////////

// Executes only on server.
function ServerSetLowReadyStatus( bool bEnable, name Reason )
{
    //mplog( self$"---SwatPawn::ServerSetLowReadyStatus(). bEnable="$bEnable );
    bShouldBeAtLowReady = bEnable;
    ReasonForShouldBeAtLowReady = Reason;

    if ( !IsControlledByLocalHuman() )
        SetLowReady( bEnable, Reason );
}


// This is called on network clients when the low ready status changes due to
// the status variable changing due to replication.
simulated event OnLowReadyStatusChanged()
{
    //mplog( self$"---SwatPawn::OnLowReadyStatusChanged(). Status="$bShouldBeAtLowReady$", Reason="$ReasonForShouldBeAtLowReady );
    SetLowReady( bShouldBeAtLowReady, ReasonForShouldBeAtLowReady );
}

///////////////////////////////////////

native function int AnimGetSpecialChannel();
native function int AnimGetEquipmentChannel();
native function int AnimGetQuickHitChannel();

///////////////////////////////////////

// Returns channel to wait on with FinishAnim

simulated function int AnimPlaySpecial(Name AnimName, optional float TweenTime,
                                       optional name Bone, optional float Rate)
{
    local int channel;
    channel = AnimGetSpecialChannel();
    AnimSetTweenAndBoneForChannel(channel, TweenTime, Bone);
    if (Rate == 0)
        Rate = 1.0;
    PlayAnim(AnimName, Rate, TweenTime, channel);
    return channel;
}

simulated function int AnimPlayEquipment(EAnimPlayType AnimPlayType, Name AnimName,
                                         optional float TweenTime, optional name Bone, optional float Rate)
{
    local int channel;

//	log(Name $ " AnimPlayEquipment called - ActiveItem " $ GetActiveItem() $ " AnimName: " $ AnimName);

    channel = AnimGetEquipmentChannel();
    AnimSetTweenAndBoneForChannel(channel, TweenTime, Bone);
    if (Rate == 0)
        Rate = 1.0;
    if (AnimPlayType == kAPT_Normal)
        PlayAnim(AnimName, Rate, TweenTime, channel);
    else
        PlayAnimAdditive(AnimName, Rate, TweenTime, channel);
    return channel;
}

simulated function int AnimLoopSpecial(Name AnimName, optional float TweenTime, optional name Bone, optional float Rate)
{
    local int channel;
    channel = AnimGetSpecialChannel();
    AnimSetTweenAndBoneForChannel(channel, TweenTime, Bone);
    if (Rate > 0)
        LoopAnim(AnimName, Rate, TweenTime, channel);
    else
        LoopAnim(AnimName, , TweenTime, channel);
    return channel;
}

simulated function int AnimLoopEquipment(EAnimPlayType AnimPlayType, Name AnimName, optional float TweenTime,
										 optional name Bone, optional float Rate)
{
    local int channel;

    channel = AnimGetEquipmentChannel();
    AnimSetTweenAndBoneForChannel(channel, TweenTime, Bone);
    if (Rate == 0)
        Rate = 1.0;
    if (AnimPlayType == kAPT_Normal)
        LoopAnim(AnimName, Rate, TweenTime, channel);
    else
        LoopAnimAdditive(AnimName, , TweenTime, channel);
    return channel;
}

simulated function int AnimPlayQuickHit(Name AnimName, optional float TweenTime,
                                        optional name Bone, optional float Rate)
{
    local int channel;
    channel = AnimGetQuickHitChannel();
    AnimSetTweenAndBoneForChannel(channel, TweenTime, Bone);
    if (Rate == 0)
        Rate = 1.0;
    PlayAnimAdditive(AnimName, Rate, TweenTime, channel);
    return channel;
}

///////////////////////////////////////

// The client can use EnableAnimSpecialAlphaOverride to turn on and specify a
// specific alpha that the special channel should be played at. This alpha is
// maintained until a call to DisableAnimSpecialAlphaOverride is made.
// By default, the animation system will ramp the channel's alpha up to 1 when
// an animation is playing, and down to 0 otherwise.

simulated function EnableAnimSpecialAlphaOverride(float alpha)
{
    bIsAnimSpecialAlphaOverrideEnabled = true;
    AnimSpecialAlphaOverride = alpha;
}

simulated function DisableAnimSpecialAlphaOverride()
{
    bIsAnimSpecialAlphaOverrideEnabled = false;
}

// Works exactly like EnableAnimSpecialAlphaOverride and
// DisableAnimSpecialAlphaOverride, except for the equipment channel.
simulated function EnableAnimEquipmentAlphaOverride(float alpha)
{
    bIsAnimEquipmentAlphaOverrideEnabled = true;
    AnimEquipmentAlphaOverride = alpha;
}

simulated function DisableAnimEquipmentAlphaOverride()
{
    bIsAnimEquipmentAlphaOverrideEnabled = false;
}

///////////////////////////////////////

native function AnimStopSpecial();
native function AnimStopEquipment();
native function AnimStopQuickHit();

///////////////////////////////////////

simulated latent function AnimFinishSpecial()
{
    FinishAnim(AnimGetSpecialChannel());
}

simulated latent function AnimFinishEquipment()
{
    FinishAnim(AnimGetEquipmentChannel());
}

///////////////////////////////////////

// Private helper function

simulated private function AnimSetTweenAndBoneForChannel(int channel, float TweenTime, name Bone)
{
    local float previousChannelAlpha;
    previousChannelAlpha = AnimGetChannelAlpha(channel);

    if (Bone == '')
        Bone = AnimBoneBase;

    AnimBlendParams(
        channel,
        previousChannelAlpha,
        ,               //InTime - not specified
        ,               //OutTime - not specified
        Bone);
}

///////////////////////////////////////

simulated function name GetUpperBodyBone()
{
	return AnimBoneSpineLow;
}

///////////////////////////////////////

simulated function AnimSetRotationUrgency(EAnimRotationUrgency Urgency)
{
    AnimRotationUrgency = Urgency;
}

simulated function AnimSetAnimAimRotationUrgency(EAnimAimRotationUrgency Urgency)
{
    AnimAimRotationUrgency = Urgency;
}
///////////////////////////////////////

native function AnimSetIdle(name NewIdleAnimation, float TweenTime);

///////////////////////////////////////

simulated function AnimSetFlag(EAnimFlag flag, bool bEnable)
{
    AnimFlags[flag] = int(bEnable);
}

///////////////////////////////////////

simulated function bool AnimGetFlag(EAnimFlag flag)
{
    assert(flag <= kAF_Special);
    return bool(AnimFlags[flag]);
}

///////////////////////////////////////

native function bool AnimAreChannelsAtZeroAlpha(int StartChannel, int LastChannel);

// starting at the first channel after the lean animations, up until the mouth anim. channel,
// returns true if all of the channels alpha's are zero, false otherwise
native function bool AnimAreAimingChannelsMuted();

///////////////////////////////////////

simulated function float GetAnimBaseYaw()
{
	return AnimBaseYaw;
}

native function AnimSnapBaseToAim();

simulated function bool AnimIsBaseAtAim()
{
	return ! bIsAnimBaseTurnToYawValid;
}

native function AnimSnapRotationToBase();

native function vector AnimGetAimOrigin();

///////////////////////////////////////

simulated function ToggleAnimDrawDebugLines()
{
    bAnimDrawDebugLines = !bAnimDrawDebugLines;
}

native function SetRenderBoundingBoxExpansionSize(float NewRenderBoundingBoxExpansionSize);

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum )
{
    //log( "........ in SwatPawn::Died()." );
    Super.Died(Killer, damageType, HitLocation, HitMomentum);

	TriggerPawnDied(Killer, damageType);

	// update the size of the predicted rendering box (so we don't disappear at certain angles)
	SetRenderBoundingBoxExpansionSize(kDeathRenderBoundingBoxExpansionSize);

    //if the SwatPawn was auto firing, then it should stop, now that it has died
    bWantsToContinueAutoFiring = false;

	if (Killer != None && Killer.Pawn != None)
		dispatchMessage(new class'MessagePawnNeutralized'(Killer.Pawn.Label, Label));
	else
		dispatchMessage(new class'MessagePawnNeutralized'('', Label));
}

simulated protected function TriggerPawnDied(Controller Killer, class<DamageType> damageType)
{
    if ( Level.NetMode != NM_Client )
    {
        SwatGameInfo(Level.Game).GameEvents.PawnDied.Triggered(self, Killer.Pawn, false, damageType);
    }
}

simulated function bool IsIntenseInjury()
{
	return ((float(Health) / float(Default.Health)) <= PercentageHealthForIntenseInjury);
}

// overridden from Pawn.uc
simulated event SetWalking(bool bNewIsWalking)
{
    if (bNewIsWalking != bIsWalking)
    {
        bIsWalking = bNewIsWalking;
        ChangeAnimation();
    }
}

simulated singular event BaseChange()
{
	local BlockingVolume BaseBlockingVolume;

	super.BaseChange();

	BaseBlockingVolume = BlockingVolume(Base);

	// if we're on stairs
	if ((BaseBlockingVolume != None) && BaseBlockingVolume.bIsStairs)
	{
		bIsOnStairs = true;

		// make sure the movement animations are reset
		ChangeAnimation();
	}
	else
	{
		bIsOnStairs = false;

		// make sure the movement animations are reset
		ChangeAnimation();
	}
}

// tests to see if the pawn is at a walking speed (or below)
function bool IsAtRunningSpeed()
{
    local AnimationSetManager AnimationSetManager;
	local AnimationSet setObject;

//	log("Anim set swapped to " $ set $ " for " $ Name);

    AnimationSetManager = SwatRepo(Level.GetRepo()).GetAnimationSetManager();
    assert(AnimationSetManager != None);
	setObject = AnimationSetManager.GetAnimationSet(kAnimationSetDynamicStanding);
	return VSize2D(Velocity) >= setObject.AnimSpeedForward;
}


///////////////////////////////////////////////////////////////////////////////
//
// Door Belief support

native event PawnDoorKnowledge GetDoorKnowledge(Door inDoor);

// subclasses may override
protected event InitializeDoorKnowledge(Door inDoor, PawnDoorKnowledge DoorKnowledge);

native function bool DoesBelieveDoorLocked(Door inDoor);

native function bool DoesBelieveDoorWedged(Door inDoor);

function SetDoorLockedBelief(Door inDoor, bool bBelievesDoorLocked)
{
	assert(inDoor != None);

	GetDoorKnowledge(inDoor).SetBelievesDoorLocked(bBelievesDoorLocked);
}

function bool GetDoorBelief(Door inDoor)
{
	local PawnDoorKnowledge Knowledge;

	Knowledge = GetDoorKnowledge(inDoor);
	return Knowledge.BeliefKnown();
}

function SetDoorWedgedBelief(Door inDoor, bool bBelievesDoorWedged)
{
	assert(inDoor != None);

	GetDoorKnowledge(inDoor).SetBelievesDoorWedged(bBelievesDoorWedged);
}

// Called only on the server or in standalone games.
function SetIsFlashbanged( bool Value )
{
    if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPawn::SetIsFlashbanged(). Value="$Value );

    bIsFlashbanged = Value;
}

function SetIsGassed( bool Value )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::SetIsGassed(). Value="$Value );

    bIsGassed = Value;
}

function SetIsPepperSprayed( bool Value )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::SetIsPepperSprayed(). Value="$Value );

    bIsPepperSprayed = Value;
}

function SetIsStung( bool Value )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::SetIsStung(). Value="$Value );

    bIsStung = Value;
}

function SetIsStunnedByC2( bool Value )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::SetIsStunnedByC2(). Value="$Value );

    bIsStunnedByC2 = Value;
}

function SetIsTased( bool Value )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::SetIsTased(). Value="$Value );

    bIsTased = Value;
}

simulated function bool IsFlashbanged()     { return bIsFlashbanged; }
simulated function bool IsGassed()          { return bIsGassed; }
simulated function bool IsPepperSprayed()   { return bIsPepperSprayed; }
simulated function bool IsStung()           { return bIsStung; }
simulated function bool IsStunnedByC2()		{ return bIsStunnedByC2; }
simulated function bool IsTased()           { return bIsTased; }

simulated function bool IsNonlethaled()
{
    return IsFlashbanged() || IsGassed() || IsPepperSprayed() || IsStung() || IsTased();
}

function ResetNonlethalEffects();


///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Flashlight support.
// It's best to have some flashlight state in the pawn so that we can easily
// persist flashlight on/off state between weapon switches
//

// From ICanHoldEquipment interface...
simulated final event bool GetDesiredFlashlightState()
{
    return FlashlightShouldBeOn;
}

simulated function float GetDelayBeforeFlashlightShutoff()
{
    if (isIncapacitated() || isDead())
        return 10; // so flashlights turn off a while after the pawn dies
    else
        return 0;
}

// Switches the desired flashlight state on/off (default state is OFF).
simulated function ToggleDesiredFlashlightState()
{
    ServerToggleDesiredFlashlightState();
}

// Executes only on the server (and in standalone).
function ServerToggleDesiredFlashlightState()
{
	local IVisionEnhancement CurrentVision;

	// If we are wearing nightvision...
	CurrentVision = IVisionEnhancement(GetSkeletalRegionProtection(REGION_Head));
	if (CurrentVision != None)
	{
		SetDesiredNightvisionState(!NightvisionShouldBeOn);
	}
	else
	{
		SetDesiredFlashlightState(!GetDesiredFlashlightState());
	}
}

simulated event FlashlightShouldBeOnChanged()
{
    //mplog( self$"---SwatPawn::FlashlightShouldBeOnChanged(). FlashlightShouldBeOn="$FlashlightShouldBeOn );

    UpdateFlashlight();
}

simulated event NightvisionShouldBeOnChanged()
{
    //mplog( self$"---SwatPawn::FlashlightShouldBeOnChanged(). FlashlightShouldBeOn="$FlashlightShouldBeOn );

    UpdateNightvision();
}

// Makes sure the active item is a FiredWeapon and if so asks it to update its
// flashlight state to match the desired state.
simulated final protected function SetDesiredFlashlightState(bool DesireFlashlightOn)
{
    local FiredWeapon CurrentWeapon;

	if (FlashlightShouldBeOn == DesireFlashlightOn)
		return;
	
	// We should only toggle the desired flashlight state if the current
	// weapon actually has a flashlight. That way you won't unexpectly have
	// your flashlight turned on when you switch to the MP5 from the (flashlight-less)
	// Taser if you accidentally had pushed the flashlight toggle button with
	// the taser equipped.
	CurrentWeapon = FiredWeapon(GetActiveItem());
	if (None != CurrentWeapon && CurrentWeapon.HasFlashlight())
	{
		FlashlightShouldBeOn = DesireFlashlightOn;
		UpdateFlashlight();
	}
	
}

simulated final protected function SetDesiredNightvisionState(bool DesireOn)
{
	if (NightvisionShouldBeOn != DesireOn)
	{
	    NightvisionShouldBeOn = DesireOn;
        UpdateNightvision();
	}
}

simulated function UpdateNightvision()
{
	local IVisionEnhancement CurrentVision;

	// If we are wearing nightvision...
	CurrentVision = IVisionEnhancement(GetSkeletalRegionProtection(REGION_Head));
	if (CurrentVision != None)
	{
		if (NightvisionShouldBeOn)
		{
			CurrentVision.Activate();
		}
		else
		{
			CurrentVision.Deactivate();
		}

		// update GUI overlays
		SetProtection(REGION_Head, GetSkeletalRegionProtection(REGION_Head));
	}
}

simulated function UpdateFlashlight()
{
    local FiredWeapon CurrentWeapon;

    CurrentWeapon = FiredWeapon(GetActiveItem());
    if (None != CurrentWeapon)
    {
		// Ask the weapon to make its flashlight state matches the desired
		// state. We also do this after a weapon is equipped.
		CurrentWeapon.OnHolderDesiredFlashlightStateChanged();
    }
}


///////////////////////////////////////////////////////////////////////////////
//
// Controller / BehindView change handling
//

// This function is called whenever something happens that potentially changes
// the perspective from which the player is viewing the pawn. For example,
// switching from a 1st to a 3rd person perspective, or changing controllers.
simulated function OnPlayerViewChanged()
{
    if (GetActiveItem() != None)
    {
		//Log("!!!! OnPlayerViewChanged called for "$self$" (controller is "$Controller$")");
		GetActiveItem().OnPlayerViewChanged();
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Compliance

simulated function bool CanIssueComplianceTo(Pawn otherPawn)
{
	assert(otherPawn != None);

	// if the other pawn is a swat ai character, within the correct distance,
	// and there is line of sight to the character
	if (otherPawn.IsA('SwatAICharacter') &&
		(VSize(otherPawn.Location - Location) <= MaxComplianceIssueDistance) &&
		LineOfSightTo(otherPawn) &&
//    otherPawn.PlayerCanSeeMe() &&
        SwatCharacterResource(otherPawn.characterAI).CommonSensorAction.GetComplySensor() != None)
	{
		return true;
	}

	// nope, can't issue compliance
	return false;
}

simulated function bool HasFiredWeaponEquipped()
{
	return ((GetActiveItem() != None) && GetActiveItem().IsA('FiredWeapon'));
}

simulated function IssueComplianceTo(Pawn TargetPawn)
{
	assert(TargetPawn != None);
	assert(TargetPawn.IsA('SwatAICharacter'));
	assert(SwatCharacterResource(TargetPawn.characterAI).CommonSensorAction.GetComplySensor() != None);

	SwatCharacterResource(TargetPawn.characterAI).CommonSensorAction.GetComplySensor().NotifyComply(self);
}

function RefundLightstick() {}

// returns true if we should issue a taunt to the subject
// returns false otherwise
// out bool says if it's a suspect
simulated function bool ShouldIssueTaunt(vector CameraLocation, vector CameraRotation, float TraceDistance, out int bIsSuspect, out int bIsAggressiveHostage, out Actor TargetActor)
{
  local Actor TraceActor;
  local Actor CandidateActor;
  local vector TraceStart, TraceEnd;
  local vector HitLocation, HitNormal;
  local Material HitMaterial;

  TraceStart = CameraLocation;
  TraceEnd = TraceStart + (CameraRotation * TraceDistance);

  bIsSuspect = 0; // This should be filled out first
  bIsAggressiveHostage = 0; // This should be filled out first


  foreach TraceActors(
    class'Actor',
    TraceActor,
    HitLocation,
    HitNormal,
    HitMaterial,
    TraceEnd,
    TraceStart
    )
    {
      // If we find a SwatEnemy or SwatHostage, stop the trace immediately
      if(TraceActor.IsA('SwatEnemy') || TraceActor.IsA('SwatHostage')) {
        CandidateActor = TraceActor;
        break;
      }
    }

    if(CandidateActor == None) {
      // There's nothing there
      return false;
    }

    if(CandidateActor.IsA('SwatEnemy') && !CandidateActor.IsA('SwatUndercover'))
	{
      bIsSuspect = 1;
    }
	else
	{
      bIsSuspect = 0;
    }

    if(CandidateActor.IsA('SwatHostage') && (ISwatAI(CandidateActor).IsAggressive()))
	{
      bIsAggressiveHostage = 1;
    }
	else
	{
      bIsAggressiveHostage = 0;
    }

    TargetActor = CandidateActor;
    if(SwatPawn(CandidateActor).bArrested) {
      return true; // They're already handcuffed
    }
    return false; // They...aren't.
}

// returns true if any character that we are yelling at had a weapon equipped
// returns false otherwise
simulated function bool IssueCompliance()
{
	local Pawn Iter;
	local bool ACharacterHasAWeaponEquipped;

	for(Iter = Level.pawnList; Iter != None; Iter = Iter.nextPawn)
	{
		if (class'Pawn'.static.checkConscious(Iter))
		{
			if (CanIssueComplianceTo(Iter))
			{
				IssueComplianceTo(Iter);

				if (SwatPawn(Iter).HasFiredWeaponEquipped())
				{
					ACharacterHasAWeaponEquipped = true;
					break;
				}
			}
		}
	}

	return ACharacterHasAWeaponEquipped;
}

///////////////////////////////////////////////////////////////////////////////
// Being Arrested

// ICanBeArrested implementation

//returns true if I can be arrested now according to my current state
simulated function bool CanBeArrestedNow()
{
    //subclasses that can be arrested should implement

    return false;
}

//returns true if I am in the process of being arrested
simulated function bool IsBeingArrestedNow()
{
    return BeingArrested;
}

//a suspect will always get OnArrestingBegan() before being arrested
simulated function OnArrestBegan(Pawn Arrester)
{
    BeingArrested = true;
}

//if the arrester completes the qualification process,
//  then the ICanBeArrested gets OnArrested()

// FINAL - so we can be sure that bArrested is always set to true
// to override, override OnArrestedSwatPawn.  Thanks.
simulated function OnArrested(Pawn Arrester)
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPawn::OnArrested(). Arrester="$Arrester );

	// this is here to handle the split second in time in SP when the officer finishes equipping his cuffs
	// vs. the time when the AI finishes equipping the IAmCuffed; in SP, the AI becomes arrested when
	// he finishes equipping his IAmCuffed
	if (! bArrested)
	{

		ArrestedBy = Arrester;
		bArrested  = true;
	    BeingArrested = false;

	    dispatchMessage(new class'MessagePawnArrested'(Arrester.Label, Label));
	    dispatchMessage(new class'MessagePawnNeutralized'(Arrester.Label, Label));

	    OnArrestedSwatPawn(Arrester);

		if(Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
		{
			SwatGameInfo(Level.Game).BroadcastArrested(Arrester, self);
		}
	}
}

simulated function OnArrestedSwatPawn(Pawn Arrester)
{
}

simulated function OnUnarrestedSwatPawn( Pawn Unarrester )
{
    bArrested = false;
}

//if the arrester is interrupted during the qualification process,
//  then the ICanBeArrested gets OnArrestInterrupted()
simulated function OnArrestInterrupted(Pawn Arrester)
{
    BeingArrested = false;
}

//return the time it takes for a Player to "qualify" to arrest me
simulated function float GetQualifyTimeForArrest(Pawn Arrester)
{
    return QualifyTimeForArrest;
}

//returns whether we've been arrested
simulated native function bool IsArrested();

// returns who arrested us
simulated function Pawn GetArrester()
{
	return ArrestedBy;
}

//This is _only_ meaningful while auto-firing.
//It does not indicate whether currently auto firing.
//Access FiredWeapon(ActiveItem).CurrentFireMode for that.
simulated function bool WantsToContinueAutoFiring()
{
    return bWantsToContinueAutoFiring && !IsNonlethaled();
}

simulated function OnAutoFireStarted()
{
    bWantsToContinueAutoFiring = true;
}

simulated function OnFireModeChanged()
{
    if (IsControlledByLocalHuman())
        UpdateHUDFireMode();
}

simulated function OnMeshChanged()
{
    InitAnimationForCurrentMesh();
}

simulated function UpdateHUDFireMode()
{
    local SwatGamePlayerController PC;

    PC = SwatGamePlayerController(Controller);

    if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
        SwatGamePlayerController(Controller).GetHUDPage().UpdateFireMode();
}

function PostTakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
						Vector momentum, class<DamageType> damageType)
{
    local HandheldEquipment ActiveItem;

    Super.PostTakeDamage(Damage, instigatedBy, hitLocation, Momentum, DamageType);

    log("PostTakeDamage on "$self$" - Damage ="$Damage$", DamageType="$damageType);

    if (Damage > 0)
    {
        if ( Level.NetMode != NM_Client )
            SwatGameInfo(Level.Game).GameEvents.PawnDamaged.Triggered(self, instigatedBy);

        //apply an accuracy penalty for taking damage
        ActiveItem = GetActiveItem();
        if (ActiveItem != None && ActiveItem.IsA('FiredWeapon'))
            FiredWeapon(ActiveItem).AddAimError(AimPenalty_TakeDamage);
    }
}

///////////////////////////////////////////////////////////////////////////////

//handles triggering the GameEvent when a piece of weapon evidence is secured
function OnEvidenceSecured(IEvidence Evidence)
{
    SwatGameInfo(Level.Game).GameEvents.EvidenceSecured.Triggered(Evidence);
    BroadcastEffectEvent('SecuredEvidence');
}

///////////////////////////////////////////////////////////////////////////////

// Override in base classes
event int GetTeamNumber();

///////////////////////////////////////////////////////////////////////////////

function UnPossessed()
{
    //cache off the name of this player
    MenuName = PlayerReplicationInfo.PlayerName;
    Super.UnPossessed();
}

///////////////////////////////////////////////////////////////////////////////

// In MP this will broadcast the stop all effect event call to every client, including the server.
// In standalone, behaves exactly the same way as a StopAllEffectEvents call.
simulated function BroadcastStopAllSounds()
{
    local Controller Itr;

    if ( Level.NetMode != NM_Standalone )
    {
        Itr = Level.ControllerList;
        while ( Itr != None ) // Walk the controller list
        {
            if ( Itr.IsA( 'SwatGamePlayerController' ) )
                SwatGamePlayerController(Itr).ClientBroadcastStopAllSounds( Self, UniqueID() );

            Itr = Itr.NextController;
        }
    }
    else
    {
        StopAllSounds();
    }
}

//stop all effect events on the given actor
simulated event StopAllSounds()
{
    SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopMySchemas(self);
}

///////////////////////////////////////////////////////////////////////////////

simulated function Name GetPlayerTag()
{
    return '';
}

///////////////////////////////////////////////////////////////////////////////

function OnIncapacitated(Actor Incapacitator, class<DamageType> damageType)
{
	return;
}

function OnKilled(Actor Killer, class<DamageType> damageType)
{
	return;
}

///////////////////////////////////////////////////////////////////////////////

// dbeswick: tone down havok character-object interactions
event bool HavokCharacterCollision(HavokCharacterObjectInteractionEvent data, out HavokCharacterObjectInteractionResult res)
{
	local HavokActor H;
	local float ImpulseMag;
	local Vector ImpulseDir;

	H = HavokActor(data.Body);
	if (H != None)
	{
		ImpulseMag = VSize(res.ObjectImpulse);
		ImpulseDir = res.ObjectImpulse / ImpulseMag;
		res.ObjectImpulse = ImpulseDir * H.ClampImpulse(ImpulseMag * HavokObjectInteractionFactor);
	}

	return true;
}

/////////////////
// Meant to be defined by subclasses
simulated function float GetTotalWeight() { return 0.0; }
simulated function float GetTotalBulk() { return 0.0; }
simulated function float GetMaximumWeight() { return 0.0; }
simulated function float GetMaximumBulk() { return 0.0; }
simulated function bool HasA(name Class) { return false; }
simulated function GivenEquipmentFromPawn(class<HandheldEquipment> Equipment) {}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    Skins[0] = Texture'SWATofficerTex.swat_bdu_camo'
    Skins[3] = Texture'SWATofficerTex.swat_vest_Pblank'
    Skins[1] = texture'SWATofficerTex.SWATelementLead'
    Skins[2] = texture'SWATofficerTex.ElementLead'

    Mesh                        = SkeletalMesh'SWATMaleAnimation2.SwatOfficer'
    BaseEyeHeight               =  40.0
    CollisionRadius             =  24.0
    CollisionHeight             =  68.0
    CollisionSoftRadiusOffset   =  8.0
    CrouchRadius                =  24.0
    bCanCrouch                  = true

    bCanWalkOffLedges           = true
    bCanJump                    = false
    bJumpCapable                = false

    bCollideActors              = true
    bCollideWorld               = true
    bBlockPlayers               = true
	bBlockActors                = true
    bRotateToDesired            = true

    bPhysicsAnimUpdate          = true

    bDisturbFluidSurface        = true

    AnimRotationUrgency         = kARU_Normal
    AnimAimRotationUrgency      = kAARU_Normal

    // It'd be lovely to use enums in defaultproperties
    AnimFlags(0)                = 1
    AnimFlags(1)                = 1
    AnimFlags(2)                = 1
    AnimFlags(3)                = 1
    AnimFlags(4)                = 1

    // By default, this value is the same as BlendChangeTime
    AimBlendChangeTime      =  0.5
    // Default inertial aiming values
    InertialAimAcceleration = 20.0
    InertialAimDeceleration = -5.0
    InertialAimMaxVelocity  = 10.0

    // Does this pawn cast dynamic shadows? Does nothing if PawnsCastShadows is false.
    bActorShadows=true;

    // Flashlights off by default
    FlashlightShouldBeOn=false
    NightvisionShouldBeOn=false

    // Shadows
    ShadowLightDistance			= 200
    ShadowExtraDrawScale        = 0.625
    MaxShadowTraceDistance		= 350
    ShadowCullDistance          = 750

    // To speed up rendering, don't let pawn shadows be cast on pawns
    bAcceptsShadowProjectors=false
    bUseCollisionBoneBoundingBox=true

	bHavokCharacterCollisions=true

    bTriggerEffectEventsBeforeGameStarts=true

	HavokObjectInteractionFactor = 0.1
}

///////////////////////////////////////////////////////////////////////////////
