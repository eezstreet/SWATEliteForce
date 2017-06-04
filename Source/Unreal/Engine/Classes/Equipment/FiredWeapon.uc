class FiredWeapon extends Weapon
    abstract
    native;

var(Ammo) config array<String> PlayerAmmoOption  "Specifies ammo to be made available in the GUI when this is selected";

struct native EnemyAmmo
{
    var() config string           AmmoClass;
    var() config int              Chance;

    //set at runtime by SelectAmmoClass()
    var() class<Ammunition>       LoadedAmmoClass;
};
var(Ammo) config array<EnemyAmmo>     EnemyUsesAmmo;
var class<Ammunition>           AmmoClass;
var Ammunition                  Ammo;
var bool						bHasAmmoBandolier;

var(Firing) config vector               ThirdPersonFireOffset         "The offset from our pivot to the muzzle tip";
var(Firing) config float                MuzzleVelocity                "The velocity that this FiredWeapon imparts to a fired bullet";
var(Firing) config bool					bCanShootThroughGlass		   "Can this weapon shoot through glass (this is just letting the AIs know so they don't try)";
var(AI) config bool					bAimAtHead						"Should this weapon be aimed at the head (for AIs)";

var private float               NextFireTime;                  // the time when we can be used again (compare against Level.TimeSeconds)

var private ActionStatus        ReloadingStatus;

var(Reloading) config float                ReloadAnimationRate;

var int							DeathFired;						// used to stop players expelling entire clips on death

//accuracy
enum AimPenaltyType
{
    AimPenalty_Equip,
    AimPenalty_StandToWalk,
    AimPenalty_WalkToRun,
    AimPenalty_TakeDamage,
    AimPenalty_Fire
};
var protected float AimError;                       //in degrees, the maximum angular offset that may be applied to a "perfectly accurate" aim rotation to model the effects of weapon accuracy.
                                                    //for example, an AimError of 18 represents a cone over 10% of a sphere: offsetting a rotation by 18 degrees in any direction produces a
                                                    //  rotation anywhere within 36 degrees, or 10% of a full sphere.

var private float PendingAimErrorPenalty;           //penalties that have been received but not yet applied
var(Aim) config float MaxAimError                       "AimError is never allowed to be above this value";
var(Aim) config float SmallAimErrorRecoveryRate         "AimError recovered per second until base AimError is achieved, when AimError is > AimErrorBreakingPoint";
var(Aim) config float LargeAimErrorRecoveryRate         "AimError recovered per second until base AimError is achieved, when AimError is <= AimErrorBreakingPoint";
var(Aim) config float AimErrorBreakingPoint             "At what multiple of BaseAimError does recovery transition from LargeAimErrorRecoveryRate to SmallAimErrorRecoveryRate";
var float LookAimErrorQuantizationFactor;           //the "grid spacing" of the LookAimError... so that looking around doesn't make the reticle feel "jittery"

// These values are penalties applied to AimError (ie. values added to AimError) when certain events occur during the game:
var(Aim) config float LookAimErrorPenaltyFactor         "A penalty applied to AimError when the player looks around.  the total penalty applied is the amount of movement per second times this factor, ie. the greater the movement, the greater the movement adversely affects accuracy.";
var(Aim) config float MaxLookAimErrorPenalty;
var(Aim) config float InjuredAimErrorPenalty;
var(Aim) config float MaxInjuredAimErrorPenalty;
var(Aim) config float DamagedAimErrorPenalty;
var(Aim) config float EquippedAimErrorPenalty;
var(Aim) config float FiredAimErrorPenalty;
var(Aim) config float WalkToRunAimErrorPenalty;
var(Aim) config float StandToWalkAimErrorPenalty;

// These values represent a Pawn's base accuracy under given conditions, ie. the best accuracy that the Pawn can have in these conditions:
var(Aim) config float StandingAimError;
var(Aim) config float WalkingAimError;
var(Aim) config float RunningAimError;
var(Aim) config float CrouchingAimError;

//recoil causes a back-and-forward movement of the camera after firing, to represent the recoiling forces of a person recovering from firing a weapon
var(Recoil) config float RecoilBackDuration                "The time over which this FiredWeapon will cause the camera to move back";
var(Recoil) config float RecoilForeDuration                "The time over which this FiredWeapon will cause the camera to move forward";
var(Recoil) config float RecoilMagnitude                   "How far this FiredWeapon will cause the camera to pitch back.  The camera will pitch forward the same amount unless another recoil is applied before a previous recoil is fully complete.";
var(Recoil) config float AutoFireRecoilMagnitudeIncrement  "Each contiguous auto-fire shot accumulates another AutoFireRecoilMagnitudeIncrement. So auto-fire shot n's recoil value = RecoilMagnitude + n * AutoFireRecoilMagnitudeIncrement";

var config bool DebugPerfectAim        "If true, when the weapon is fired the game will act as if you have perfect aim (i.e., ignore any current aim error)";
var config bool DebugDrawTraceFire     "If true, when the weapon is fired the game will draw line(s) representing the path of the bullet(s) after AimError has been applied";
var config bool DebugDrawAccuracyCone  "If true, when the weapon is fired the game will draw the cone representing the AimError-adusted area through which the bullet might travel";

// flashlights
var(Flashlight) private config bool HasAttachedFlashlight           "If true, this weapon will enable flashlight on/off toggling and create a light source at located at the socket specified in the FlashlightSocketName property";
var(Flashlight) private config vector  FlashlightPosition_1stPerson "Positional offset from the EquippedSocket on this weapon's FirstPersonModel to the point from which the flashlight emanates";
var(Flashlight) private config rotator FlashlightRotation_1stPerson "Same idea as FlashlightPosition_1stPerson, but rotational offset";
var(Flashlight) private config vector  FlashlightPosition_3rdPerson "Positional offset from the EquippedSocket on this weapon's ThirdPersonModel to the point from which the flashlight emanates";
var(Flashlight) private config rotator FlashlightRotation_3rdPerson "Same idea as FlashlightPosition_3rdPerson, but rotational offset";
const FLASHLIGHT_TEXTURE_INDEX = 1;                      // Material index for the flashlight "glow" texture

// State used for determining if a 3rd person flashlight projection is
// visible, to keep lights from leaking through thin walls.
var private bool   FlashlightProjection_IsInitializing;                 // We do some special logic if we perform a projection visibility test when a flashlight is turned on.

const kFlashlightProjection_NumTestsPerSecond = 10;                     // We do a fixed number of tests per second, so framerate is not a factor.
const kFlashlightProjection_FailureTimeout    =  1.0;                   // How long we wait to turn off the light after our last successful test, in seconds.
const kFlashlightProjection_ConeAnglePercent  =  0.75;                  // Since the flashlight projection test traces start a bit closer to the pawn than the flashlight source location, we narrow our cone a bit to compensate. This is the percentage of the flashlight's cone that we use.

var private name   FlashlightProjection_StartBoneName;                  // The bone name on the pawn from which we start the flashlight projection test traces. We do this so that the start location is closer to the pawn's body, and less susceptible to clipping through walls.
var private float  FlashlightProjection_LastTestTime;                   // To facilitate a fixed number of tests per second.
var private bool   FlashlightProjection_LastTestResult;                 // If we don't perform a test this tick, we use the last result.
var private vector FlashlightProjection_LastTestSuccessfulHitLocation;  // Stores the last trace test end point that our camera was able to see. Once we find one, keep using it for future tests until it fails. This vector is considered invalid if FlashlightProjection_LastTestResult == false.
var private float  FlashlightProjection_LastSuccessfulTestTime;         // Stores the last time we had a successful test. After kFlashlightProjection_FailureTimeout seconds, the flashlight's light will be turned off.

const kFlashlightProjection_BrightnessAlphaLerpTime = 0.2;              // In seconds, the rate at which FlashlightProjection_CurrentBrightnessAlpha can lerp from 0 to 1.
var private float  FlashlightProjection_CurrentBrightnessAlpha;         // From 0 to 1. This value is lerped toward 0 or 1, depending on if the flashlight projection is visible, at the rate of.

// Enabling this enables run-time code to help prevent flashlights from leaking through bsp walls.
#define ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING 1

//------- Flashlight lighting parameters ----------
var(Flashlight) private config class<Light> FlashlightSpotLightClass   "Type of Spotlight to spawn for this weapon's flashlight";
var(Flashlight) private config class<Light> FlashlightPointLightClass  "Type of Pointlight to spawn for this weapon's flashlight";
var(Flashlight) private config class<Light> FlashlightCoronaLightClass "Type of CoronaLight to spawn for this weapon's flashlight";
var(Flashlight) private config float PointLightDistanceFraction     "Where to place the pointlight along the line to the nearest object (0 = at flashlight, 1=at object intersection)";
var(Flashlight) private config float PointLightRadiusScale          "How much to scale the pointlight radius with distance from the nearest object";
var(Flashlight) private config float PointLightDistanceFadeRate     "How fast will the pointlight incorporate new distance values";
var private Light  FlashlightDynamicLight;                 // The actual light spawned for this weapon's flashlight
var private Actor  FlashlightReferenceActor;             // Reference point for the flashlight's position; this is where the flashlight appears to originate from (where the corona appears, and where traces are done from when using a moving pointlight on low end cards to approximate a spotlight)
var(Debug) config  bool   DebugDrawFlashlightDir               "If true, draw the trace lines and sprites for the flashlight lights";
var(Flashlight) config  int    FlashlightUseFancyLights              "for flashlights: -1 = uninitialized, 1 = spotlights, 0 = point lights";
var(Flashlight) config  float  MinFlashlightBrightness               "The brightness at the max distance of the flashlight";
var(Flashlight) config  float  MinFlashlightRadius                   "The brightness at the max distance of the flashlight";
var(Flashlight) config  float  FlashlightFirstPersonDistance         "Distance to pointlight in non-fancy mode, 1st person";
var(Flashlight) config  float  MaxFlashlightDistance                 "The brightness at the max distance of the flashlight";
var(Flashlight) config  float  ThirdPersonFlashlightRadiusPenalty    "The radius penalty on flishlights for 3rd person flashlights so that they do not take away from the limited lighting resources of static meshes.";
var private bool   bHighEndGraphicsBoard;                // determines which type of lights are used in the flashlights
var private float  BaseFlashlightBrightness;             // The base level brightness that will be scaled with distance
var private float  BaseFlashlightRadius;                 // radius specified in the flashlight's light source

//FireModes indicate whether a FiredWeapon is set to automatically fire subsequent shots if the owning Pawn wants to continue firing
//(in the case of a Player, the player indicates that s/he wants to continue firing by holding down the fire button.  AIs
//  indicate programatically if they want to continue firing.)
enum FireMode
{
    FireMode_Single,
    FireMode_SingleTaser,	// used on Stingray
	FireMode_DoubleTaser,	// used on Stingray
    FireMode_Burst,
    FireMode_Auto
};
var(Firing) private config array<FireMode> AvailableFireMode       "Named in singular for simplicity of config file";
var FireMode CurrentFireMode;                               //set with SetCurrentFireMode()
var int FireModeIndex;                                      //the currently selected index into the FiredWeapon's AvailableFireMode
var(Firing) private config int BurstShotCount                      "The number of shots that will be fired when CurrentFireMode is FireMode_Burst";
var private int BurstShotsRemaining;                        //while firing in FireMode_Burst, how many shots remain to be shot in the current burst
var(Firing) config float BurstRateFactor                           "The rate at which burst and auto-fire animations are played";

var private int AutoFireShotIndex;                          //while firing in FireMode_Auto, how many shots have been started since the FiredWeapon began auto-firing

var private bool PerfectAimNextShot;                        //for special purposes, we want to be able to take a shot with perfect aim, ie. Officers with shotguns

var(Damage) private config float OverrideArmDamageModifier;

var(AI) config bool OfficerWontEquipAsPrimary					"If true Officer will use secondary weapon unless ordered otherwise";

#define DONT_REQUIRE_PENETRATION_FOR_BLOOD_PROJECTORS 1

simulated function PreBeginPlay()
{
    Super.PreBeginPlay();

    AssertWithDescription(MuzzleVelocity > 0,
        "[tcohen] MuzzleVelocity for the FiredWeapon "$class.name
        $" is not set.  Please set it in Content/System/SwatEquipment.ini.");

    if (AvailableFireMode.length > 0)
    {
        FireModeIndex = 0;
        SetCurrentFireMode(AvailableFireMode[FireModeIndex]);
    }

    UpdateAimError(0);

    Disable('Tick');
}

simulated event PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    //mplog( self$"---FiredWeapon::PostNetBeginPlay(). Ammo="$Ammo );

    Disable('Tick');
}

simulated event Destroyed()
{
	// Destroy the flashlight now so we don't have to wait for the engine to
	// destroy orphaned actors later.
	if (IsFlashlightInitialized())
		DestroyFlashlight(ICanToggleWeaponFlashlight(Owner).GetDelayBeforeFlashlightShutoff());

    if (Ammo != None)
    {
        Ammo.Destroy();
        Ammo = None;
    }

    Super.Destroyed();
}

//HandheldEquipment override
//
//returns true if the FiredWeapon is busy doing something that is FiredWeapon specific.
//a FiredWeapon is not idle if it is busy Reloading.
simulated protected function bool IsHandheldEquipmentIdleHook()
{
    //log( "In FiredWeapon::IsHandheldEquipmentIdleHook(). ReloadingStatus="$ReloadingStatus$", IsFiredWeaponIdleHook()="$IsFiredWeaponIdleHook() );
    return      ReloadingStatus == ActionStatus_Idle
            &&  IsFiredWeaponIdleHook();
}
//subclasses should override if they implement any actions
simulated protected function bool IsFiredWeaponIdleHook() { return true; }

simulated function bool IsBeingReloaded()
{
	return ReloadingStatus != ActionStatus_Idle;
}

//
// Ammo Interface
//
// These functions forward calls to the FiredWeapon's Ammunition.
// Please see comments in Engine/Classes/Equipment/Ammunition.uc.

simulated function bool CanReload()
{
    if (bDeleteMe)
        return false;
	assertWithDescription(Ammo != None,
        "[tcohen] FiredWeapon::CanReload() "$name$"'s Ammo is None.  Terry should fix this.");
    return Ammo.CanReload();
}

simulated function bool IsEmpty()
{
    if (Ammo == None)
    {
        if (bDeleteMe)
            return false;
        assertWithDescription(false,
            "[tcohen] FiredWeapon::IsEmpty() "$name$"'s Ammo is None.  Terry should fix this.");
    }
    return Ammo.IsEmpty();
}

simulated function bool IsFull()
{
    if (Ammo == None)
    {
        if (bDeleteMe)
            return false;
	    assertWithDescription(false,
            "[tcohen] FiredWeapon::IsFull() "$name$"'s Ammo is None.  Terry should fix this.");
    }
    return Ammo.IsFull();
}

simulated function bool NeedsReload()
{
    if (Ammo == None)
    {
        if (bDeleteMe)
            return false;
        assertWithDescription(false,
            "[tcohen] FiredWeapon::NeedsReload() "$name$"'s Ammo is None.  Terry should fix this.");
    }
    return Ammo.NeedsReload();
}

simulated function bool ShouldReload()
{
    if (Ammo == None)
    {
        if (bDeleteMe)
            return false;
        assertWithDescription(false,
            "[tcohen] FiredWeapon::ShouldReload() "$name$"'s Ammo is None.  J21C should fix this.");
    }
    return Ammo.ShouldReload();
}
simulated function float GetChoke();

//this is the base FiredWeapon's implementation of firing a single shot.
//note that some FiredWeapon subclasses override this and implement firing
//  a single shot in a completely different way.
//first, it calls GetPerfectFireStart() to calculate the location and
//  rotation of the start of a trace representing a perfectly accurate shot.
//then it applies aim error due to the weapon's current accuracy.
//after applying the effects of accuracy, it calls BallisticFire() to
//  determine the result of firing that shot.
//finally, if the local player fired the weapon, then TraceFire()
//  applies Recoil to the player due to firing the weapon.
simulated function TraceFire()
{
    local vector PerfectStartLocation, StartLocation;
    local rotator PerfectStartDirection, StartDirection, CurrentDirection;
	  local vector StartTrace, EndTrace;
    local PlayerController LocalPlayerController;
    local int Shot;

    GetPerfectFireStart(PerfectStartLocation, PerfectStartDirection);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (DebugDrawAccuracyCone)
        DrawAccuracyCone(PerfectStartLocation, PerfectStartDirection);
#endif

    StartLocation = PerfectStartLocation;
    StartDirection = PerfectStartDirection;
    ApplyAimError(StartDirection);
    StartTrace = StartLocation;
    for(Shot = 0; Shot < Ammo.ShotsPerRound; ++Shot) {
      ApplyRandomOffsetToRotation(StartDirection, GetChoke() * DEGREES_TO_RADIANS, CurrentDirection);
      EndTrace = StartLocation + vector(CurrentDirection) * Range;
      BallisticFire(StartTrace, EndTrace);
    }

    PerfectAimNextShot = false;

    //TMC TODO 9/17/2003 move this into LocalFire() after Mike meets the milestone... then we don't need to do this redundant test.
    LocalPlayerController = Level.GetLocalPlayerController();
    if (Pawn(Owner).Controller == LocalPlayerController)    //I'm the one firing
    {
        if (CurrentFireMode == FireMode_Auto)
            LocalPlayerController.AddRecoil(RecoilBackDuration, RecoilForeDuration, RecoilMagnitude, AutoFireRecoilMagnitudeIncrement, AutoFireShotIndex);
        else
            LocalPlayerController.AddRecoil(RecoilBackDuration, RecoilForeDuration, RecoilMagnitude);
    }
}

// Used by the AI - whether firing this weapon will hit its intended target
// (and not, for example, an actor or levelinfo that is in between our target)
simulated function bool WillHitIntendedTarget(Actor Target)
{
  local vector PerfectFireStartLocation, HitLocation, StartTrace, EndTrace, ExitLocation, PreviousExitLocation;
  local vector HitNormal, ExitNormal;
  local float Distance;
  local rotator PerfectFireStartDirection;
  local Actor Victim;
  local Material HitMaterial, ExitMaterial;
  local ESkeletalRegion HitRegion;
  local float Momentum;

  GetPerfectFireStart(PerfectFireStartLocation, PerfectFireStartDirection);

  StartTrace = PerfectFireStartLocation;
  EndTrace = Target.Location;
  EndTrace.Z += (Pawn(Owner).BaseEyeHeight / 2);

  Distance = VSize(EndTrace - StartTrace);

  if(Distance >= Range)
  {
    return false; // We can't hit it because it is too far away.
  }

  Momentum = MuzzleVelocity * Ammo.Mass;
  PreviousExitLocation = StartTrace;

  foreach TraceActors(
      class'Actor',
      Victim,
      HitLocation,
      HitNormal,
      HitMaterial,
      EndTrace,
      StartTrace,
      /*optional extent*/,
      true, //bSkeletalBoxTest
      HitRegion,
      true,   //bGetMaterial
      true,   //bFindExitLocation
      ExitLocation,
      ExitNormal,
      ExitMaterial )
  {
    Momentum -= Ammo.GetDrag() * VSize(HitLocation - PreviousExitLocation);

    if(Victim == Owner || Victim == Self || Victim.DrawType == DT_None  || Victim.bHidden)
    {
      continue; // Not something we need to worry about
    }
    else if(!Victim.IsA('SwatPawn') && Ammo.RoundsNeverPenetrate)
    {
      // Our bullet type doesn't penetrate surfaces and we hit a surface...
      return false;
    }
    else if(!Victim.IsA('SwatPawn') && !Ammo.RoundsNeverPenetrate)
    {
      // Our bullet type *might* penetrate surfaces and we hit a surface...
      Momentum -= Victim.GetMomentumToPenetrate(HitLocation, HitNormal, HitMaterial);
    }
    else if(Victim.IsA('LevelInfo'))
    {
      return false; // Hit BSP geometry, we can't penetrate that ..!
    }

    if(Momentum <= 0)
    {
      // The bullet lost all of its momentum
      return false;
    }

    if(Victim != Target)
    {
      if(Owner.IsA('SwatEnemy'))
      {
        // Suspects don't care, as long as they aren't hitting a buddy
        // FIXME: make this based on Polite? skill level?
        if(!Victim.IsA('SwatEnemy'))
        {
          return true;
        }
      }
      return false;
    }
    else
    {
      return true;
    }

  }
  return false;
}

//call once to give the weapon perfect accuracy the next time it fires.
//(automatically cleared after firing)
//AIs use this in special cases where they need to have perfect accuracy.
simulated function SetPerfectAimNextShot()
{
    PerfectAimNextShot = true;
}

//turn a perfectly accurate shot direction into a less-accurate shot
//  based on the current AimError.
simulated function ApplyAimError(out rotator FireDirection)
{
    local rotator OriginalFireDirection;
    local rotator NewFireDirection;

    OriginalFireDirection = FireDirection;
    ApplyRandomOffsetToRotation(OriginalFireDirection, AimError * DEGREES_TO_RADIANS, NewFireDirection);
    FireDirection = NewFireDirection;
}

native function ApplyRandomOffsetToRotation(rotator OriginalRotation, float OffsetHalfAngleRadians, out rotator NewRotation);

// Handles bullet fracture
// TODO
/*
simulated function bool HandleBallisticImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    Material HitMaterial,
    ESkeletalRegion HitRegion,
    out float Momentum,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )*/

// Handles bullet ricochet.
// For right now, all this does is fire the bullet in a perfect mirror.
simulated function DoBulletRicochet(Actor Victim, vector HitLocation, vector HitNormal, vector BulletDirection, Material HitMaterial, float Momentum, int BounceCount)
{
  local vector MirroredAngle, EndTrace;
  local vector NewHitLocation, NewHitNormal, NewExitLocation, NewExitNormal;
  local vector PreviousExitLocation;
  local Material NewHitMaterial, NewExitMaterial;
  local Actor NewVictim;
  local ESkeletalRegion NewHitRegion;

  BounceCount = BounceCount + 1;
  MirroredAngle = BulletDirection - 2 * (BulletDirection dot Normal(HitNormal)) * Normal(HitNormal);
  Momentum *= Ammo.GetRicochetMomentumModifier();
  EndTrace = HitLocation + MirroredAngle * Range;

  // Play an effect when it hits the first surface
  Ammo.SetLocation(HitLocation);
  Ammo.SetRotation(rotator(HitNormal));
  #if IG_EFFECTS
      //don't play hit effects on the sky
      if (HitMaterial == None || HitMaterial.MaterialVisualType != MVT_Sky)
      {
          Ammo.TriggerEffectEvent('BulletHit', Victim, HitMaterial);
      }
  #endif // IG_EFFECTS

  PreviousExitLocation = HitLocation;

  foreach TraceActors(
      class'Actor',
      NewVictim,
      NewHitLocation,
      NewHitNormal,
      NewHitMaterial,
      EndTrace,
      HitLocation,
      /*extent*/,
      true,
      NewHitRegion,
      true,
      true,
      NewExitLocation,
      NewExitNormal,
      NewExitMaterial
    )
  {
      Ammo.BallisticsLog("Ricochet bullet made an impact on Victim="$NewVictim$
          ", NewHitLocation="$NewHitLocation$
          ", NewHitNormal="$NewHitNormal$
          ", NewHitMaterial="$NewHitMaterial.MaterialVisualType);

      Ammo.BallisticsLog("Momentum (before drag): "$Momentum);
      // Reduce the bullet's momentum by drag
      Momentum -= Ammo.GetDrag() * VSize(NewHitLocation - PreviousExitLocation);
      Ammo.BallisticsLog("Momentum (after drag): "$Momentum);

      if(Momentum < 0.0) {
        Ammo.BallisticsLog("Momentum went < 0. Not impacting with anything (LOST BULLET)");
        break;
      }

      if(Ammo.CanRicochet(NewVictim, NewHitLocation, NewHitNormal, Normal(NewHitLocation - NewHitNormal), NewHitMaterial, Momentum, BounceCount)) {
        // the bullet ricocheted from the material
        DoBulletRicochet(NewVictim, NewHitLocation, NewHitNormal, Normal(NewHitLocation - NewHitNormal), NewHitMaterial, Momentum, BounceCount);
        break;
      } else if(!HandleBallisticImpact(NewVictim, NewHitLocation, NewHitNormal, Normal(NewHitLocation - NewHitNormal), NewHitMaterial,
                  NewHitRegion, Momentum, NewExitLocation, NewExitNormal, NewExitMaterial)) {
        // the bullet embedded itself into the material
        break;
      }

      // the bullet passed through the target
      PreviousExitLocation = NewExitLocation;
  }
}

//handles the physics simulation of a bullet hitting something in the world.
//determines how much damage a target should take, and if the shot should conseptually "penetrate" a target.
//if a shot "penetrates" a target, then BallisticFire continues to evaluate hits until the shot is
//  conseptually "buried" in a target, ie. it does not penetrate the target.
//penetration is determined based on the momentum of the bullet and the momentum-to-penetrate of a target.
//(for more information on ballistics calculations, please see documents/programming/Planning - Ballistics.doc.)
//this function is written in-terms-of HandleBallisticImpact(), which it calls for each target until the shot
//  is burried in the target.
simulated function BallisticFire(vector StartTrace, vector EndTrace)
{
	local vector HitLocation, HitNormal, ExitLocation, ExitNormal, PreviousExitLocation;
	local actor Victim;
    local Material HitMaterial, ExitMaterial; //material on object that was hit
    local float Momentum;
    local ESkeletalRegion HitRegion;

    Momentum = MuzzleVelocity * Ammo.Mass;

    Ammo.BallisticsLog("BallisticFire(): Weapon "$name
        $", shot by "$Owner.name
        $", has MuzzleVelocity="$MuzzleVelocity
        $", Ammo "$Ammo.name
        $" has Mass="$Ammo.Mass
        $".  Initial Momentum is "$Momentum
        $".");

    PreviousExitLocation = StartTrace;

    foreach TraceActors(
        class'Actor',
        Victim,
        HitLocation,
        HitNormal,
        HitMaterial,
        EndTrace,
        StartTrace,
        /*optional extent*/,
        true, //bSkeletalBoxTest
        HitRegion,
        true,   //bGetMaterial
        true,   //bFindExitLocation
        ExitLocation,
        ExitNormal,
        ExitMaterial )
    {
        Ammo.BallisticsLog("IMPACT: Momentum before drag: "$Momentum);
        Momentum -= Ammo.GetDrag() * VSize(HitLocation - PreviousExitLocation);
        Ammo.BallisticsLog("IMPACT: Momentum after drag: "$Momentum);

        if(Momentum < 0.0) {
          Ammo.BallisticsLog("Momentum went < 0. Not impacting with anything (LOST BULLET)");
          break;
        }

        //handle each ballistic impact until the bullet runs out of momentum and does not penetrate
        if (Ammo.CanRicochet(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, Momentum, 0)) {
          // the bullet ricocheted
          DoBulletRicochet(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, Momentum, 0);
          break;
        }
        else if (!HandleBallisticImpact(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, HitRegion, Momentum, ExitLocation, ExitNormal, ExitMaterial))
            break; // the bullet embedded itself in the target

        // the bullet passed through the target
        PreviousExitLocation = ExitLocation;
    }
}

simulated function DealDamage(Actor Victim, int Damage, Pawn Instigator, Vector HitLocation, Vector MomentumVector, class<DamageType> DamageType )
{
	if (Level.NetMode == NM_Client)
        return;                     //don't deal damage on clients

    // do not cause damage if this weapon is not owned by a controlled pawn.
    // (dkaplan version 136 to prevent dead players from dealing damage on the tick that they die)
    if( Pawn(Owner) == None || Pawn(Owner).Controller == None )
        return;

    Victim.TakeDamage(Damage, Pawn(Owner), HitLocation, MomentumVector, DamageType);
}

//returns true iff the bullet penetrates the Victim
//
//called by BallisticFire() for each intersection (in order) of the fire trace, until this function returns false, indicating that the
//  shot did not penetrate the latest victim.
//handles the actual determination of damage and remaining momentum as described in BallisticFire().
//if the impact is with a skeletal region of a Pawn that is protected by a piece of ProtectiveEquipment,
//  then HandleBallisticImpact() calls HandleProtectiveEquipmentBallisticImpact() to evaluate the result of that impact.
//also triggers EffectEvent(s) related to the ballistic impact.
simulated function bool HandleBallisticImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    Material HitMaterial,
    ESkeletalRegion HitRegion,
    out float Momentum,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
    local float MomentumToPenetrateVictim;
    local float MomentumLostToVictim;
    local vector MomentumVector;
    local bool PenetratesVictim;
    local int Damage;
    local SkeletalRegionInformation SkeletalRegionInformation;
    local ProtectiveEquipment Protection;
    local float DamageModifier, ExternalDamageModifier;
    local float LimbInjuryAimErrorPenalty;
    local IHaveSkeletalRegions SkelVictim;
    local Pawn  PawnVictim;
	local PlayerController OwnerPC;

    // You shouldn't be able to hit hidden actors that block zero-extent
    // traces (i.e., projectors, blocking volumes). However, the 'Victim'
    // when you hit BSP is LevelInfo, which is hidden, so we have to
    // handle that as a special case.
    if ((Victim.bHidden || Victim.DrawType == DT_None) && !(Victim.IsA('LevelInfo')))
    {
        Ammo.BallisticsLog("BallisticFire: Skipping bHidden=true Victim "$Victim.Name$" of class "$Victim.class.name);
        return true;    //penetrates, no damage or momentum lost
    }

    if (Victim.IsA('SwatDoor') || Victim.Owner.IsA('SwatDoor'))	//Handle this case on its own, because we dont wanna trigger the skeletal hit, we do that in the shotgun code
    {															//We also still wanna draw the decals
		return HandleDoorImpact(Victim, HitLocation, HitNormal, HitMaterial, ExitLocation, ExitNormal, ExitMaterial);
	}

	// officers don't hit other officers, or the player (unless we're attacking them)
	if (Owner.IsA('SwatOfficer') &&
		(Victim.IsA('SwatOfficer') || (Victim.IsA('SwatPlayer') && !Pawn(Owner).IsAttackingPlayer())))
	{
    Ammo.BallisticsLog("BallisticFire: Skipping Victim "$Victim.Name$" of class "$Victim.class.name$" because officers shouldn't hit other friendly officers/players");
		return false;   //friendly fire... blocked, no effects
	}

    // Some dynamic actors are not rendered due to the player's
    // detail settings being too low. In this case they should not block
    // bullets, to keep the visual experience consistent.
	if( (Victim.bHighDetail && Level.DetailMode == DM_Low)
         || (Victim.bSuperHighDetail && Level.DetailMode != DM_SuperHigh))
    {
        Ammo.BallisticsLog("BallisticFire: Skipping Victim "$Victim.Name$" of class "$Victim.class.name$
                " because Level.DetailMode="$GetEnum(EDetailMode, Level.DetailMode)$
                " and Victim.bHighDetail="$Victim.bHighDetail$
                " and Victim.bSuperHighDetail="$Victim.bSuperHighDetail);
        return true;    //penetrates, no damage or momentum lost
    }

    //play effects at the point of impact
    Ammo.SetLocation(HitLocation);
    Ammo.SetRotation(rotator(HitNormal));

    // Normal TraceActors() collection of material doesn't work quite right for
    // skeletal meshes, so we call this helper function to get the material manually.
    if (Victim.DrawType == DT_Mesh)
    {
        HitMaterial = Victim.GetCurrentMaterial(0); // get skin at first index
        ExitMaterial = HitMaterial;

        //if the Victim has skeletal regions, do some more work
        if (HitRegion != REGION_None && Victim.IsA('IHaveSkeletalRegions'))
        {
            //if the Victim is protected at the impacted region then handle an impact with ProtectiveEquipment

            if (Victim.IsA('ICanUseProtectiveEquipment'))
            {
                SkeletalRegionInformation = ICanUseProtectiveEquipment(Victim).GetSkeletalRegionInformation(HitRegion);
                Protection = ICanUseProtectiveEquipment(Victim).GetSkeletalRegionProtection(HitRegion);

                if (Protection != None)
                {
                    Ammo.TriggerEffectEvent('BulletHit', Protection, HitMaterial);
                    if (!HandleProtectiveEquipmentBallisticImpact(
                                Victim,
                                Protection,
                                HitRegion,
                                HitLocation,
                                HitNormal,
                                NormalizedBulletDirection,
                                Momentum))
                        return false;   //blocked by ProtectiveEquipment
                }
            }
        }
    }

    if (HitMaterial == None) // weird situation, should trigger FX but not block the bullet (or should it?)
    {
        Ammo.BallisticsLog("[WARNING!!] BallisticFire: Trace hit Victim "$Victim$" of class "$Victim.class.name$", HitMaterial is None, treating as if no momentum required to penetrate.");
        MomentumLostToVictim = 0;
    }
    else
    if (Victim.class.name == 'LevelInfo' || Ammo.RoundsNeverPenetrate)
    {
        MomentumToPenetrateVictim = Momentum;
        MomentumLostToVictim = Momentum;
    }
    else
    {
        MomentumToPenetrateVictim = Victim.GetMomentumToPenetrate(HitLocation, HitNormal, HitMaterial);
        MomentumLostToVictim = FMin(Momentum, MomentumToPenetrateVictim);
    }

    //the bullet will penetrate the victim unles it loses all of its momentum to the victim
    PenetratesVictim = (MomentumLostToVictim < Momentum);

    //calculate damage imparted to victim
    Damage = MomentumLostToVictim * Level.GetRepo().MomentumToDamageConversionFactor;

    //calculate momentum vector imparted to victim
    MomentumVector = NormalizedBulletDirection * MomentumLostToVictim;
    if (PenetratesVictim)
        MomentumVector *= Level.getRepo().MomentumImpartedOnPenetrationFraction;

    //consider adding internal damage
    if (!PenetratesVictim)
        Damage += Ammo.InternalDamage;

    //apply any external damage modifiers (maintained by the Repo)
    ExternalDamageModifier = Level.GetRepo().GetExternalDamageModifier( Owner, Victim );
    Damage = int( float(Damage) * ExternalDamageModifier );

	// damage pawns
    PawnVictim = Pawn(Victim);
    if (Damage <= 0 && SkeletalRegionInformation != None && PawnVictim != None)
	{
		Damage = 0;
    }
    if( Damage > 0 && SkeletalRegionInformation != None && PawnVictim != None)
    {
		// dbeswick: stats
		OwnerPC = PlayerController(Pawn(Owner).Controller);
		if (OwnerPC != None)
		{
			OwnerPC.Stats.Hit(class.Name, PlayerController(PawnVictim.Controller));
		}

		DamageModifier = RandRange(SkeletalRegionInformation.DamageModifier.Min, SkeletalRegionInformation.DamageModifier.Max);

        // Give the weapon the chance to override arm specific damage...
        if ( OverrideArmDamageModifier != 0 && (HitRegion == REGION_LeftArm || HitRegion == REGION_RightArm)  )
            DamageModifier = OverrideArmDamageModifier;
        Damage *= DamageModifier;

        LimbInjuryAimErrorPenalty = RandRange(SkeletalRegionInformation.AimErrorPenalty.Min, SkeletalRegionInformation.AimErrorPenalty.Max);
        PawnVictim.AccumulatedLimbInjury += LimbInjuryAimErrorPenalty;
    }

#if IG_EFFECTS
    //don't play hit effects on the sky
    if (HitMaterial == None || HitMaterial.MaterialVisualType != MVT_Sky)
    {
        if (Damage <= 0)
            Ammo.AddContextForNextEffectEvent('NoDamage');
        Ammo.TriggerEffectEvent('BulletHit', Victim, HitMaterial);
    }
#endif // IG_EFFECTS

    Ammo.BallisticsLog("  ->  Remaining Momentum is "$Momentum$". Bullet hit Victim "$Victim.name);

    if (HitMaterial != None)
        Ammo.BallisticsLog("  ... HitMaterial = "$HitMaterial);
    else
        Ammo.BallisticsLog("  ... HitMaterial = None");

    Ammo.BallisticsLog("  ... MomentumToPenetrateVictim is "$MomentumToPenetrateVictim$", so the bullet will lose "$MomentumLostToVictim$" momentum to the Victim.");

    if ( HitRegion != REGION_None && Victim.IsA( 'IHaveSkeletalRegions' ) )
    {
        Ammo.BallisticsLog("  ... Victim has SkeletalRegions.  "$GetEnum(ESkeletalRegion, HitRegion)$" was hit.");
        if (Protection != None)
            Ammo.BallisticsLog("  ... (Region is protected by "$Protection.class.name$".)");
        if ( OverrideArmDamageModifier != 0 && (HitRegion == REGION_LeftArm || HitRegion == REGION_RightArm) )
        {
            Ammo.BallisticsLog("  ... DamageModifier from the skeletal region was overriden for this arm hit, the OverrideArmDamageModifier is: "
                $OverrideArmDamageModifier);
        }
        else
        {
            Ammo.BallisticsLog("  ... DamageModifier from the skeletal region is on the Range (Min="$SkeletalRegionInformation.DamageModifier.Min
                $", Max="$SkeletalRegionInformation.DamageModifier.Max
                $"), Selected "$DamageModifier
                $".");
        }
        Ammo.BallisticsLog("  ... ExternalDamageModifier = "$ExternalDamageModifier
            $".");
        Ammo.BallisticsLog("  ... AimErrorPenalty in on Range (Min="$SkeletalRegionInformation.AimErrorPenalty.Min
            $", Max="$SkeletalRegionInformation.AimErrorPenalty.Max
            $"), Selected "$LimbInjuryAimErrorPenalty
            $".");

        if (PenetratesVictim)
            Ammo.BallisticsLog("  ... Victim was penetrated:          Damage = MomentumLostToVictim * MomentumToDamageConversionFactor * DamageModifier * ExternalDamageModifier = "$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $" * "$DamageModifier
                $" * "$ExternalDamageModifier
                $" = "$Damage);
        else
            Ammo.BallisticsLog("  ... Bullet was buried in Victim:    Damage = ((MomentumLostToVictim * MomentumToDamageConversionFactor) + InternalDamage) * DamageModifier * ExternalDamageModifier = (("$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $") + "$Ammo.InternalDamage
                $") * "$DamageModifier
                $" * "$ExternalDamageModifier
                $" = "$Damage);
    }
    else
    {
        if (PenetratesVictim)
            Ammo.BallisticsLog("  ... Victim was penetrated:          Damage = MomentumLostToVictim * MomentumToDamageConversionFactor = "$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $" = "$Damage);
        else
            Ammo.BallisticsLog("  ... Bullet was buried in Victim:    Damage = (MomentumLostToVictim * MomentumToDamageConversionFactor) + InternalDamage = ("$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $") + "$Ammo.InternalDamage
                $" = "$Damage);
    }

    // If it's something with skeletal regions, do notification
    // We check this using a separate variable to avoid accessed nones
    // every time bsp or a static mesh is hit
    SkelVictim = IHaveSkeletalRegions(Victim);
    if (SkelVictim != None)
        SkelVictim.OnSkeletalRegionHit(HitRegion, HitLocation, HitNormal, Damage, GetDamageType(), Owner);

    DealDamage(Victim, Damage, Pawn(Owner), HitLocation, MomentumVector, GetDamageType());

    Ammo.BallisticsLog("  ... Bullet will impart to victim the momentum it lost to the victim:  "$VSize(MomentumVector)$" in direction "$Normal(MomentumVector));

    Victim.TakeHitImpulse(HitLocation, MomentumVector, GetDamageType());

    //the bullet has lost momentum to its victim
    Momentum -= MomentumLostToVictim;


#if IG_EFFECTS
    if (PenetratesVictim)
    {
        Ammo.SetLocation( ExitLocation );
        Ammo.SetRotation( rotator(ExitNormal) );

        Ammo.TriggerEffectEvent('BulletExited', Victim, ExitMaterial);
    }

    if ( ShouldSpawnBloodForVictim( PawnVictim, Damage ) )
        SpawnBloodEffects( Ammo, ExitLocation, Damage, NormalizedBulletDirection );
#endif // IG_EFFECTS
    return PenetratesVictim;
}

simulated function bool HandleDoorImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    Material HitMaterial,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
	Ammo.SetLocation(HitLocation);
	Ammo.SetRotation(rotator(HitNormal));
	Ammo.TriggerEffectEvent('BulletHit', None, HitMaterial);

	Ammo.SetLocation( ExitLocation );
    Ammo.SetRotation( rotator(ExitNormal) );
    Ammo.TriggerEffectEvent('BulletExited', Victim, ExitMaterial);
	return true;
}

simulated function bool  ShouldSpawnBloodForVictim( Pawn PawnVictim, int Damage )
{
#if DONT_REQUIRE_PENETRATION_FOR_BLOOD_PROJECTORS
    return PawnVictim != None && Damage > 0;
#else
    return PenetratesVictim || PawnVictim.IsDead() || PawnVictim.IsIncapacitated());
#endif
}

simulated function bool SpawnBloodEffects(Ammunition Ammo,Vector ExitLocation, int Damage, vector Direction)
{
    local int NumPools, ct;
    local Rotator BloodRot;
    local Vector X, Y, Z;

	NumPools = Rand(3)+1;
    for ( ct = 0; ct < NumPools; ct ++ )
	{
        BloodRot = rotator(-Direction);

        Ammo.SetRotation( BloodRot );
        GetAxes( BloodRot, X, Y, Z );
        Ammo.SetLocation( ExitLocation + Y * (RandRange(-5,5)) + Z * (RandRange(-5, 5)) );

        Ammo.TriggerEffectEvent('BloodProjected');
	}
    return true;
}

//returns true iff the bullet penetrates the ProtectiveEquipment
simulated function bool HandleProtectiveEquipmentBallisticImpact(
    Actor Victim,
    ProtectiveEquipment Protection,
    ESkeletalRegion HitRegion,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    out float Momentum)
{
    local bool PenetratesProtection;
    local vector MomentumVector;
    local int Damage;
    local float MomentumLostToProtection;
    local Object.Range DamageModifierRange;
    local float DamageModifier, ExternalDamageModifier;

    //the bullet will penetrate the protection unles it loses all of its momentum to the protection
    PenetratesProtection = (Protection.GetMtP() < Momentum);

    //determine DamageModifierRange
    if (PenetratesProtection)
        DamageModifierRange = Protection.PenetratedDamageFactor;
    else
        DamageModifierRange = Protection.BlockedDamageFactor;

    //calculate damage imparted to victim
    MomentumLostToProtection = FMin(Momentum, Protection.GetMtP());
    Damage = MomentumLostToProtection * Level.GetRepo().MomentumToDamageConversionFactor;
    DamageModifier = RandRange(DamageModifierRange.Min, DamageModifierRange.Max);
    Damage *= DamageModifier;

    //apply any external damage modifiers (maintained by the Repo)
    ExternalDamageModifier = Level.GetRepo().GetExternalDamageModifier( Owner, Victim );
    Damage = int( float(Damage) * ExternalDamageModifier );

    //calculate momentum vector imparted to victim
    MomentumVector = NormalizedBulletDirection * Protection.GetMtP();
    if (PenetratesProtection)
        MomentumVector *= Level.getRepo().MomentumImpartedOnPenetrationFraction;

    Ammo.BallisticsLog("  ->  Remaining Momentum is "$Momentum$".");
    Ammo.BallisticsLog("  ... Bullet hit "$Protection.class.name$" ProtectiveEquipment on Victim "$Victim.name);
    Ammo.BallisticsLog("  ... Protection.MomentumToPenetrate is "$Protection.GetMtP()$".");

    if (PenetratesProtection)
        Ammo.BallisticsLog("  ... The ProtectiveEquipment was penetrated.  Using PenetratedDamageFactor.");
    else
        Ammo.BallisticsLog("  ... Bullet was buried in the ProtectiveEquipment  Using BlockedDamageFactor.");

    Ammo.BallisticsLog("  ... DamageModifier is on the Range (Min="$DamageModifierRange.Min$", Max="$DamageModifierRange.Max$"), selected "$DamageModifier$".");
    Ammo.BallisticsLog("  ... ExternalDamageModifier = "$ExternalDamageModifier$".");

    Ammo.BallisticsLog("  ... Damage = MomentumLostToProtection * MomentumToDamageConversionFactor * DamageModifier * ExternalDamageModifier = "$MomentumLostToProtection
        $" * "$Level.GetRepo().MomentumToDamageConversionFactor
        $" * "$DamageModifier
        $" * "$ExternalDamageModifier
        $" = "$Damage);

    IHaveSkeletalRegions(Victim).OnSkeletalRegionHit(HitRegion, HitLocation, HitNormal, Damage, GetDamageType(), Owner);

    DealDamage(Victim, Damage, Pawn(Owner), HitLocation, MomentumVector, GetDamageType());

    //the bullet has lost momentum to its target
    Momentum -= Protection.GetMtP();

    if(Ammo.CanShredArmor()) {
      Protection.OnProtectedRegionHit();
    }

    return PenetratesProtection;
}

function class<DamageType> GetDamageType()
{
    //by default, a FiredWeapon passes itself as a DamageType
    //one notable exception is the shotgun which passes the special
    //  FrangibleBreachingDamageType for breaching purposes.
    return class;
}

//Overridden from HandheldEquipment, when a FiredWeapon is given to its owner,
//  it also spawns its Ammunition if it hasn't already been set, and Initialize()s its ammo.
//Ammunition is normally set by the LoadOut for Players and Officers,
//  and is left to be spawned by the FiredWeapon for AICharacters.
//
// Executes only on the server.
function OnGivenToOwner()
{
    Super.OnGivenToOwner();

    //mplog( self$"---FiredWeapon::OnGivenToOwner(). Owner="$Owner );

    AssertWithDescription(Ammo == None,
        "[tcohen] "$name$" was just given to "$Owner$", but it already has Ammo.");

    Instigator = Pawn(Owner);

    //if the owner of this weapon hasn't already set the AmmoClass (ie. Officers),
    //  then randomly select one from EnemyUsesAmmo (ie. Enemies).
    if (AmmoClass == None)
        SelectAmmoClass();

    Ammo = Spawn(AmmoClass, self);  //owned by weapon

    AssertWithDescription(Ammo != None,
        "[tcohen] The FiredWeapon "$name
        $" (owned by "$Owner.name
        $") failed to spawn its Ammunition of class "$AmmoClass
        $".");

    Ammo.InitializeAmmo(DeathFired);
    DeathFired = 0;
}

//for enemies, FiredWeapon ammunition type is selected randomly from the set of types of ammo
//  that an enemy is allowed to use for this type of FiredWeapon.
function SelectAmmoClass()
{
    local int TotalChance;
    local int RandChance;
    local int AccumulatedChance;
    local int i;

    assertWithDescription(EnemyUsesAmmo.length > 0,
        "[tcohen] The FiredWeapon "$class.name
        $" was trying to SelectAmmoClass(), but there are no EnemyUsesAmmo options for that FiredWeapon.  Please provide at least one EnemyUsesAmmo for that FiredWeapon in SwatEquipment.ini.");

    //calculate the sum of chances of the options
    //at the same time, dynamically load and validate each ammo class
    for (i=0; i<EnemyUsesAmmo.length; ++i)
    {
        TotalChance += EnemyUsesAmmo[i].Chance;
        EnemyUsesAmmo[i].LoadedAmmoClass =
            class<Ammunition>(DynamicLoadObject(EnemyUsesAmmo[i].AmmoClass, class'Class'));

        AssertWithDescription(EnemyUsesAmmo[i].LoadedAmmoClass != None,
            "[tcohen] In the FiredWeapon "$class.name
            $", EnemyUsesAmmo option #"$i
            $" (base zero) specifies AmmoClass "$EnemyUsesAmmo[i].AmmoClass
            $", but that class is invalid.  This is configured in SwatEquipment.ini.");
    }

    RandChance = Rand(TotalChance);

    //find the Selected option
    for (i=0; i<EnemyUsesAmmo.length; ++i)
    {
        AccumulatedChance += EnemyUsesAmmo[i].Chance;

        if (AccumulatedChance >= RandChance)
        {
            AmmoClass = EnemyUsesAmmo[i].LoadedAmmoClass;

            return;
        }
    }

    assert(false);  //we should have chosen something (even if it was a 'None')
}

//This is the entrypoint into reloading a FiredWeapon.
//It will most likely be called by a Controller, a Pawn, or Tyrion, when the Pawn/hands should reload this weapon.
//The caller should first ensure that it makes sense to reload this now,
//  ie. its not busy doing something else
// Executes on both client and server.
simulated final function Reload()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::Reload()." );

    //make sure this can be used now
    ValidateReload();
    PreReload();
    GotoState('BeingReloaded');
}

simulated function PreReload()
{
    //used to send OnReloadKeyFrame() only once to Pawn & Hands,
    //  rather than once for each.
    ReloadingStatus = ActionStatus_Started;
}


//This is a latent version of Reload().  See comments there.
simulated final latent function LatentReload()
{
    if (Owner.IsA('SwatAI'))
    {
		// interrupt our equipment
		Pawn(Owner).AIInterruptEquipment();

		if (! IsIdle())
			AIInterrupt();
    }

    //make sure this can be reloaded now
    ValidateReload();

    // For AI's in COOP, let clients know that they should play the reloading
    // animation.
    if ( Level.IsCOOPServer )
        NotifyClientsToDoAIReload();

    PreReload();
    DoReloading();
}

function NotifyClientsToDoAIReload()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.IsCOOPServer );

    // Do a walk the controller list thing here.
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientDoAIReload( Pawn(Owner) );
        }
    }
}

simulated function bool PrevalidateReload()
{
    Assert( Level.NetMode != NM_Standalone );
    return ValidateReload( true ); // true means prevalidate (i.e. don't assert)
}


//do some error checking to make sure we're ready to be reloaded
//  (we've been asked to Reload(), so we had better be ready)
simulated function bool ValidateReload( optional bool Prevalidate )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::ValidateReload()." );

    if ( !Prevalidate )
    {
        if (!IsEquipped())
        {
            AssertWithDescription(false,
                "[tcohen] The HandheldEquipment "$name
                $" was called to Reload().  But it doesn't think it is equipped.");
        }

        if (!IsIdle())
        {
            AssertWithDescription(false,
                "[tcohen] The HandheldEquipment "$name
                $" was called to Reload(), but it is busy doing something else. (EquippingStatus="$EquippingStatus
                $", UnequippingStatus="$UnequippingStatus
                $", UsingStatus="$UsingStatus
                $", ReloadingStatus="$ReloadingStatus
				$", MeleeingStatus="$MeleeingStatus
                $")");
        }
    }

    return IsEquipped() && IsIdle();
}

simulated function string HandheldEquipmentStatusString()
{
    local string Result;
    Result = ", ReloadingStatus="$ReloadingStatus;
    return Result;
}

//to support the non-latent version of Reload()
simulated state BeingReloaded
{
Begin:
    DoReloading();
    GotoState('');
}

//play all reloading-related animations, over time, on the
//  first and third person models of this FiredWeapon, as well
//  as the holders of each of these models.
simulated latent private function DoReloading()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::DoReloading()." );

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    if (FirstPersonModel != None)
        FiredWeaponModel(FirstPersonModel).PlayReload();
    if (ThirdPersonModel != None)
        FiredWeaponModel(ThirdPersonModel).PlayReload();

    if (FirstPersonModel != None)
        FiredWeaponModel(FirstPersonModel).FinishReload();
    if (ThirdPersonModel != None)
        FiredWeaponModel(ThirdPersonModel).FinishReload();

    //TMC TODO if FiredWeapon is empty, then play empty on weapon

    // MCJ: If you put an assertion here in the future, remember that the pawn
    // may have died and the animation finished without sending all its
    // anim_notifies.

    ReloadingStatus = ActionStatus_Idle;

	if (GetHands() != None)
	    GetHands().IdleHoldingEquipment();

    Pawn(Owner).OnReloadingFinished();
}


//Note that latent DoReloading() is not yet complete.
simulated final function OnReloadKeyFrame()
{
    //Only propagate OnReloadKeyFrame() once.
    //Note that both the Pawn & Hands will get OnReloadKeyFrame()
    //  at the same time, whomever's model gets to key-frame first.
    if (ReloadingStatus == ActionStatus_Started)
    {
        FiredWeaponModel(ThirdPersonModel).OnReloadKeyFrame();

        if (GetHands() != None)
            FiredWeaponModel(FirstPersonModel).OnReloadKeyFrame();

        Ammo.OnReloaded();

        ReloadedHook();

        ReloadingStatus = ActionStatus_HitKeyFrame;
    }
}
simulated function ReloadedHook();    //for subclasses

//////////////////////////////////////////////////////////
//
// FIRING

// The process of Firing:
//
// When a Player fires while holding a FiredWeapon,     |   When an AI fires a FiredWeapon,
//  the following sequence of functions is called:      |    the following sequence of functions is called:
//                                                      |
// SwatGamePlayerController::Fire()                     |
// PlayerController::Fire()                             |
// HandheldEquipment::OnPlayerUse()                     |
// HandheldEquipment::Use()                             |   HandheldEquipment::LatentUse()
// HandheldEquipment::state BeingUsed                   |
// HandheldEquipment::DoUsing()                         |   HandheldEquipment::DoUsing()
// FiredWeapon::DoUsingHook()                           |   FiredWeapon::DoUsingHook()
// FiredWeapon::DoFiring()                              |   FiredWeapon::DoFiring()
//


// PreUse() gets called before GotoState('BeingUsed') in HandheldEquipment. We
// need to set Interrupted to false here, in case an interrupt comes in from
// the server in the single tick between the GotoState() and when the Begin:
// label of 'BeingUsed' starts executing (don't ask; we've actually seen it
// happen).
simulated function PreUse()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::PreUse()." );

    Super.PreUse();
    if ( CurrentFireMode == FireMode_Auto )
    {
        AutoFireShotIndex = 0;
        Pawn(Owner).OnAutoFireStarted();
    }
}


//overridden from HandheldEquipment
//
//when a FiredWeapon is "Used", it fires
simulated latent protected function DoUsingHook()
{
    DoFiring();
}

//do whatever this FiredWeapon is supposed to do when it is fired.
//this includes handling burst-fire and auto-fire, depending on the
//  FiredWeapon's CurrentFireMode.
simulated latent private function DoFiring()
{
    if ( Pawn(Owner).IsControlledByLocalHuman() )
    {
        Pawn(Owner).ServerBeginFiringWeapon( GetSlot() );
    }
    else if ( Level.IsCOOPServer && Owner.IsA('SwatAI') )
    {
        NotifyClientsAIBeginFiringWeapon();
    }

    BeginFiring();

    Pawn(Owner).OnUsingBegan();

    switch (CurrentFireMode)
    {
        case FireMode_Single:
		case FireMode_SingleTaser:
		case FireMode_DoubleTaser:
            break;

        case FireMode_Burst:
            BurstShotsRemaining = BurstShotCount;
            break;

        case FireMode_Auto:
            // MCJ: now set above in PreUse().
            //AutoFireShotIndex = 0;
            //Pawn(Owner).OnAutoFireStarted();
            break;

        default:
            assert(false);  //unexpected FireMode
    }

    //sometimes, you gotta break the rules to look pretty
    do Fire(); until (!WantsToContinueFiring() || Ammo.NeedsReload());

    if ( CurrentFireMode == FireMode_Auto && Level.IsCOOPServer && Owner.IsA('SwatAI') )
    {
        NotifyClientsAIEndFiringWeapon();
    }

    Pawn(Owner).OnUsingFinished();

    EndFiring();
    //TODO
    //  if (CurrentFireMode > FireMode_Single && !Ammo.NeedsReload())
    //      notify Server EndFiring()
    //(if Ammo.NeedsReload(), then the server should EndFiring() by itself.)
}

simulated latent function BeginFiring();

simulated latent function EndFiring();

// Should execute only on coop server.
function NotifyClientsAIBeginFiringWeapon()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.IsCOOPServer );

    // Do a walk the controller list thing here.
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIBeginFiringWeapon( Pawn(Owner), int(CurrentFireMode) );
        }
    }
}

// Should execute only on coop server.
function NotifyClientsAIEndFiringWeapon()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.IsCOOPServer );

    // Do a walk the controller list thing here.
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIEndFiringWeapon( Pawn(Owner) );
        }
    }
}


//after a weapon has fired a shot, determine whether the weapon should automatically
//  fire another shot.
//this takes care of indicating when there are more shots remaining in a burst
//  (if the CurrentFireMode is FireMode_Burst),
//  and if the owner of the FiredWeapon wants to continue auto-firing (if the
//  CurrentFireMode is FireMode_Auto).
simulated private function bool WantsToContinueFiring()
{
	if (DeathFired > 15)
	{
		return false;
	}

    switch (CurrentFireMode)
    {
        case FireMode_Single:
        case FireMode_SingleTaser:
        case FireMode_DoubleTaser:
            return false;

        case FireMode_Burst:
            return BurstShotsRemaining > 0;

        case FireMode_Auto:
            return Pawn(Owner).WantsToContinueAutoFiring();
    }

    assert(false);  //unexpected FireMode
    return false;
}

//play all animations, over time, that are related to firing this FiredWeapon,
//  and call TraceFire() to handle the logical effects of a shot.
//this includes playing animations on the first and third-person models of the
//  weapon, as well as the holders of each of these models (the Hands and the Pawn,
//  respectively).
simulated latent private function Fire()
{
    local HandheldEquipmentModel EffectsSource;
    local Pawn OtherForEffectEvents;
    local float TweenTime;
    local Pawn PawnOwner;
    local Name EffectSubsystemToIgnore; // initialized by default to ''

    // We want to play the effects for whichever model is visible to the local
    //  player.  This would be the FirstPersonModel if the gun belongs to the player's
    //  pawn and the player is viewing from a first-person perspective.  Otherwise,
    //  effects should be played for the ThirdPersonModel, since thats what you could see.
    //However, if that model was not recently rendered, then its position is
    //  not updated.  So in that case, we will trigger the effect events on the model
    //  (so that event response matching is done based on the FiredWeaponModel),
    //  but we'll tell the Effects System to play the effects on this FiredWeapon's
    //  Owner, ie. the Pawn who owns the weapon.
    //

    if (InFirstPersonView())
    {
        EffectsSource = FirstPersonModel;

        // In first person view, if bOwnerNoSee is true on the first
        // person model (meaning we can't see it in First Person),
        // then only play the sound effects, not the visual ones.
        //
        // This is only necessary when bRenderHands is false on the
        // pawn that owns this weapon. See Hands.UpdateHandsForRendering()
        // for where this is set.
        if (FirstPersonModel.bOwnerNoSee)
            EffectSubsystemToIgnore = 'VisualEffectsSubsystem';
    }
    else
    {
	    EffectsSource = ThirdPersonModel;
    }

    PawnOwner = Pawn(Owner);
    if (EffectsSource.LastRenderTime < Level.TimeSeconds - 1.0f)
        //the EffectsSource wasn't rendered recently, so we'll fall-back to playing the effects on this FiredWeapon's Owner (Pawn)
        OtherForEffectEvents = PawnOwner;

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    TweenTime = PawnOwner.GetFireTweenTime();

    if (FirstPersonModel != None)
        FirstPersonModel.PlayUse(TweenTime);
    if (ThirdPersonModel != None)
        ThirdPersonModel.PlayUse(TweenTime);

    PreRoundUsed();

    if (!NeedsReload())
    {
        TraceFire();
        Ammo.OnRoundUsed(Pawn(Owner), self);
        if (CurrentFireMode == FireMode_Burst)
            BurstShotsRemaining--;
        else
        if (CurrentFireMode == FireMode_Auto)
            AutoFireShotIndex++;

        AddAimError(AimPenalty_Fire);

        if (EffectsSource != None)
        {
            if (CurrentFireMode == FireMode_Single || CurrentFireMode == FireMode_SingleTaser)
            {
                EffectsSource.TriggerEffectEvent(
                        'Fired',
                        OtherForEffectEvents,
                        ,                                   //TargetMaterial
                        ,                                   //HitLocation
                        ,                                   //HitNormal
                        (OtherForEffectEvents != None),     //PlayOnOther
                        ,                                   //QueryOnly
                        ,                                   //Observer
                        ,                                   //ReferenceTag
                        EffectSubsystemToIgnore);
            }
            else    //burst, auto firing or double taser
            {
                EffectsSource.TriggerEffectEvent(
                        'BurstFired',
                        OtherForEffectEvents,
                        ,                                   //TargetMaterial
                        ,                                   //HitLocation
                        ,                                   //HitNormal
                        (OtherForEffectEvents != None),     //PlayOnOther
                        ,                                   //QueryOnly
                        ,                                   //Observer
                        ,                                   //ReferenceTag
                        EffectSubsystemToIgnore);
            }
        }
    }
    else
    {
        // If we needed a reload, play the gun is empty "click" sound. On the
        // server, RPC this to all clients for which the Owner is relevant.
        if (EffectsSource != None)
        {
            EffectsSource.TriggerEffectEvent( 'EmptyFired', OtherForEffectEvents,,,, (OtherForEffectEvents != None),,,, EffectSubsystemToIgnore );
            if ( (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
                 && Pawn(Owner) != None )
                Pawn(Owner).BroadcastEmptyFiredToClients();
        }
    }

    if (FirstPersonModel != None)
        FirstPersonModel.FinishUse();
    if (ThirdPersonModel != None)
        ThirdPersonModel.FinishUse();

    PostRoundUsed();

    if (TweenTime > 0)
        Sleep(TweenTime);   //wait for tween to firing position (ie. from low-ready)

	if (Pawn(Owner) != None && Pawn(Owner).Health <= 0)
	{
		DeathFired++;
	}

    // MCJ: If you put an assertion here in the future, remember that the pawn
    // may have died and the animation finished without sending all its
    // anim_notifies.
}

simulated latent function PreRoundUsed();
simulated latent function PostRoundUsed();

//switch the CurrentFireMode to the next FireMode available for this FiredWeapon
simulated function NextFireMode()
{
    local FireMode NewFireMode;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::NextFireMode()." );

    if (AvailableFireMode.length == 0)
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...1" );

        return;
    }

    FireModeIndex++;
    if (FireModeIndex >= AvailableFireMode.length)
        FireModeIndex = 0;

    NewFireMode = AvailableFireMode[FireModeIndex];
    if ( Level.NetMode == NM_Client )
    {
        Pawn(Owner).ServerSetCurrentFireMode( GetSlot(), NewFireMode );
    }
    SetCurrentFireMode( NewFireMode );

    if (Level.GetEngine().EnableDevTools)
        mplog( "...2" );
}

//returns true if this FiredWeapon supports the specified FireMode
simulated function bool HasFireMode(FireMode TestFireMode)
{
    local int i;

    if (AvailableFireMode.length == 0)
        return TestFireMode == FireMode_Single;

    for (i=0; i<AvailableFireMode.length; ++i)
        if (TestFireMode == AvailableFireMode[i])
            return true;

    return false;
}

//set this FiredWeapon's CurrentFireMode after confirming that
//  the supplied FireMode is supported by the weapon.
//also notifies the Owner that the fire mode changed.
simulated function SetCurrentFireMode(FireMode NewFireMode)
{
    if (CurrentFireMode == NewFireMode)
	    return; // no change

    CurrentFireMode = NewFireMode;

    assertWithDescription(HasFireMode(NewFireMode),
        "[tcohen] The "$class.name
        $" FiredWeapon, Owned by "$Owner.name
        $" was called to SetCurrentFireMode() to "$GetEnum(FireMode, NewFireMode)
        $".  But that FiredWeapon doesn't support that FireMode.");


    // Trigger an effect (probably a sound)
    // The effect event is triggered on the FiredWeapon, but played on the Pawn
    TriggerEffectEvent(
        'FireModeChanged',
        Owner,      //Other
        ,           //TargetMaterial
        ,           //HitLocation
        ,           //HitNormal
        true);      //PlayOnOther

    Pawn(Owner).OnFireModeChanged();
}

simulated function FireMode GetCurrentFireMode()
{
    return CurrentFireMode;
}

///////////////////////////////////////////////////////////////////////////////
//
// AimError
//

simulated function EquippedHook()
{
    AddAimError(AimPenalty_Equip);

    Enable('Tick'); //we want to Tick() while equipped so that can update AimError

    // See if the pawn had the flashlight on at the time he changed
    // equipment. If so, turn the light on for the new equipment.
    UpdateFlashlightState();

    UpdateAmmoDisplay();
}

simulated function UpdateAmmoDisplay()
{
  // This function has to be overrided..
}

simulated function UnEquippedHook()
{
    Disable('Tick');

    // Destroy the flashlight when we switch weapons. EquippedHook() on
    // new weapon will take care of turning it back on if necessary.
    if (IsFlashlightOn())
    {
	    DestroyFlashlight(ICanToggleWeaponFlashlight(Owner).GetDelayBeforeFlashlightShutoff());
    }
}

//get the FiredWeapons standard AimError based on its Owner's current condition.
//also, if the Owner is the local player, apply any current AimError penalty for the owner looking around.
simulated native function float GetBaseAimError();

//add an instantaneous penalty to this FiredWeapon's current AimError
simulated function AddAimError(AimPenaltyType Penalty)
{
    switch (Penalty)
    {
        case AimPenalty_Equip:
            PendingAimErrorPenalty += EquippedAimErrorPenalty;
            break;

        case AimPenalty_StandToWalk:
            PendingAimErrorPenalty += StandToWalkAimErrorPenalty;
            break;

        case AimPenalty_WalkToRun:
            PendingAimErrorPenalty += WalkToRunAimErrorPenalty;
            break;

        case AimPenalty_TakeDamage:
            PendingAimErrorPenalty += DamagedAimErrorPenalty;
            break;

        case AimPenalty_Fire:
            PendingAimErrorPenalty += FiredAimErrorPenalty;
            break;

        default:
            assert(false);  //unexpected AimPenaltyType
    }
}

simulated function float GetAimError()
{
    return AimError;
}

//update flashlight and AimError.
simulated event Tick(float dTime)
{
    Super.Tick(dTime);

	if (IsFlashlightOn())
	{
		UpdateFlashlightLighting(dTime);
	}

    if (class'Pawn'.static.CheckDead(Pawn(Owner)))
    {
        //in this case, we might still be equipped, but we don't want to update stuff
        Disable('Tick');
        return;
    }

	CheckTickEquipped();

    UpdateAimError(dTime);
}

simulated function CheckTickEquipped()
{
    if (!IsEquipped()) // ckline: modified assert to conditional for efficiency (avoid string concat)
    {
        assertWithDescription(false,
            "[tcohen] "$class.name$", owned by "$Owner$" is Tick()ing, but it is not Equipped.");
    }
}

//AimError at any moment in time is composed of two components:
//  - base aim error represents the weapon's accuracy based on the current condition of its owner,
//      eg. moving, standing, crouching
//  - aim error penalties are applied when an event occurs (firing, taking damage, etc.), and decay over time
//UpdateAimError() handles decaying penalties over time, and recovering accuracy when base aim error
//  is reduced due to changes in the Owner's condition (eg. going from running to standing).
simulated function UpdateAimError(float dTime)
{
    local float AimErrorRecoveryRate;
    local float TargetAimError;

    //target aim error is state-based error plus event-based penalties
    TargetAimError = GetBaseAimError() + PendingAimErrorPenalty;

    if (AimError > TargetAimError)
    {
        //determine recovery rate, which depends on how bad our accuracy is now
        if (AimError > AimErrorBreakingPoint)
            AimErrorRecoveryRate = LargeAimErrorRecoveryRate;
        else
            AimErrorRecoveryRate = SmallAimErrorRecoveryRate;

        //recover accuracy over time
        AimError = FMax(TargetAimError, AimError - dTime * AimErrorRecoveryRate);
    }
    else {
        //current aim error should be at least target aim error
        AimError = FMax(TargetAimError, AimError);
    }

//    log("[AIM] Updated AimError="$AimError);

    //clear event-based penalties which are applied once
    PendingAimErrorPenalty = 0;
}


///////////////////////////////////////////////////////////////////////////////
//
// Flashlight-enabled weapon methods
//

// Is this weapon flashlight-capable?
simulated final function bool HasFlashlight()
{
    return HasAttachedFlashlight;
}

// Is the flashlight on?
native final function bool IsFlashlightOn();

// This is called when the holder of the weapon changes its desired flashlight
// state.
simulated function OnHolderDesiredFlashlightStateChanged()
{
	local bool PawnWantsFlashlightOn;
	local Name EventName;
	local String FlashlightTextureName;
	local Material FlashlightMaterial;

    if (HasAttachedFlashlight)
    {
	    PawnWantsFlashlightOn = ICanToggleWeaponFlashlight(Owner).GetDesiredFlashlightState();
	    if (PawnWantsFlashlightOn)
	    {
		    EventName = 'FlashlightSwitchedOn';
		    FlashlightTextureName = "SWATgearTex.FlashlightLensOnShader";
	    }
	    else
	    {
		    EventName = 'FlashlightSwitchedOff';
		    FlashlightTextureName = "SWATgearTex.FlashlightLensOff";
	    }

        //the effect event is triggered on the FiredWeapon, but played on the Pawn
	    TriggerEffectEvent(
                EventName,
                Owner,      //Other
                ,           //TargetMaterial
                ,           //HitLocation
                ,           //HitNormal
                true);      //PlayOnOther

	    // change texture on 3rd person model
	    if (! InFirstPersonView())
	    {
			if (PawnWantsFlashlightOn) // turn on the glow texture on the flashlight bulb
			{
				FlashlightMaterial = Material(DynamicLoadObject( FlashlightTextureName, class'Material'));
				AssertWithDescription(FlashlightMaterial != None, "[ckline]: Couldn't DLO flashlight lens texture "$FlashlightTextureName);
			}
			else // turn off the glow texture
			{
				// hack.. force the skin to None so that GetCurrentMaterial will pull from
				// the default materials array instead of the skin
				ThirdPersonModel.Skins[FLASHLIGHT_TEXTURE_INDEX] = None;

				FlashlightMaterial = ThirdPersonModel.GetCurrentMaterial(FLASHLIGHT_TEXTURE_INDEX);
			}

			ThirdPersonModel.Skins[FLASHLIGHT_TEXTURE_INDEX] = FlashlightMaterial;
	    }

	    UpdateFlashlightState();
    }
}

// Switches the flashlight on/off depending on the desired flashlight state of
// the pawn that is holding the flashlight.
//
// NOTE: A call to UpdateFlashlightState() does NOT necessarily mean that the
// holder of the weapon turned the flashlight on/off. It just makes sure that
// the weapon's flashlight state matches the holder's desired state.
simulated function UpdateFlashlightState()
{
    local bool PawnWantsFlashlightOn;

    if (! HasAttachedFlashlight)
    {
		//Log("[ckline]: Weapon "$self$" on "$Owner$" is not flashlight-equipped, so can't toggle its state.");
		return;
    }

    PawnWantsFlashlightOn = ICanToggleWeaponFlashlight(Owner).GetDesiredFlashlightState();
    //Log("UpdateFlashlightState(): Pawn wants it on = "$PawnWantsFlashlightOn$", IsFlashlightOn = "$IsFlashlightOn()$" on "$owner);
	//LogGuardStack();

    if (PawnWantsFlashlightOn == IsFlashlightOn())
    {
		// flashlight is already at desired state
		return;
    }

    // Setup the flashlight objects if necessary
    if (PawnWantsFlashlightOn) // should be on
    {
		InitFlashlight();
        if (!IsFlashlightInitialized())
        {
		    assertWithDescription(false, "[ckline] Flashlight should be initialized but thinks it isn't. I must have messed something up.");
        }
    }
    else // flashlight should be off
    {
		if (IsFlashlightInitialized())
		{
			DestroyFlashlight(ICanToggleWeaponFlashlight(Owner).GetDelayBeforeFlashlightShutoff());
		}
    }
}

simulated function SetFlashlightRadius(float radius)
{
	if (FlashlightDynamicLight != None) {
		FlashlightDynamicLight.LightRadius = radius;
	}
}

simulated function SetFlashlightCone(float cone)
{
	if (FlashlightDynamicLight != None) {
		FlashlightDynamicLight.LightCone = cone;
	}
}

simulated private function UpdateFlashlightLighting(optional float dTime)
{
#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
    local bool bIsFlashlightProjectionVisible;
#endif
    local HandheldEquipmentModel WeaponModel;
    local Vector  PositionOffset;
    local Rotator RotationOffset, rayDirection;
	local Vector  hitLocation, hitNormal;
	local Vector  traceStart, traceEnd, PointLightPos, delta;
	local Actor   hitActor;
	local float   oldDistance, newDistance;
	//local float    maxDistance, angle;
	//local int     ind;

    if( Level.NetMode == NM_DedicatedServer )
        return;

#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
    bIsFlashlightProjectionVisible = IsFlashlightProjectionVisible();
    // If IsFlashlightProjectionVisible() returned false, determine if we're
    // past the last successfully visible timeout
    if (!bIsFlashlightProjectionVisible
    && (Level.TimeSeconds - FlashlightProjection_LastSuccessfulTestTime) < kFlashlightProjection_FailureTimeout)
    {
        bIsFlashlightProjectionVisible = true;
    }

    if (FlashlightProjection_IsInitializing)
    {
        // Snap directly to 0 or 1 if FlashlightProjection_IsInitializing is true.
        if (bIsFlashlightProjectionVisible)
            FlashlightProjection_CurrentBrightnessAlpha = 1.0;
        else
            FlashlightProjection_CurrentBrightnessAlpha = 0.0;
    }
    else
    {
        // Lerp the current alpha brightness toward 0 or 1, depending on
        // bIsFlashlightProjectionVisible.
        if (bIsFlashlightProjectionVisible)
            FlashlightProjection_CurrentBrightnessAlpha += dTime / kFlashlightProjection_BrightnessAlphaLerpTime;
        else
            FlashlightProjection_CurrentBrightnessAlpha -= dTime / kFlashlightProjection_BrightnessAlphaLerpTime;
        FlashlightProjection_CurrentBrightnessAlpha = FClamp(FlashlightProjection_CurrentBrightnessAlpha, 0.0, 1.0);
    }
#endif

	// The stuff below is only done for the pointlight-to-spotlight modeling
	if (FlashlightUseFancyLights == 1)
    {
#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
        FlashlightDynamicLight.LightBrightness = BaseFlashlightBrightness * FlashlightProjection_CurrentBrightnessAlpha;
#endif
		return;
	}

    // Set up flashlight for first person model if it is weapon is held by the player's pawn.
    if (InFirstPersonView())
    {
        if (FirstPersonModel == None)
        {
            assertWithDescription(false, "[henry] Can't update flashlight for "$self$", FirstPersonModel is None");
        }
		WeaponModel    = FirstPersonModel;
		PositionOffset = FlashlightPosition_1stPerson;
		RotationOffset = FlashlightRotation_1stPerson;
    }
    else // todo: handle 3rd person flashlight, including when controller changes
    {
        if (ThirdPersonModel == None)
        {
		    assertWithDescription(false, "[henry] Can't update flashlight for "$self$", ThirdPersonModel is None");
        }
        WeaponModel    = ThirdPersonModel;
		PositionOffset = FlashlightPosition_3rdPerson;
		RotationOffset = FlashlightRotation_3rdPerson;
    }

	traceStart   = FlashlightReferenceActor.Location;
	rayDirection = FlashlightReferenceActor.Rotation;
	// the first person uses a much smaller max distance to avoid popping when
	// the light aims from a distant wall to a nearby object.
    if (InFirstPersonView())
		traceEnd = traceStart + Vector(rayDirection) * FlashlightFirstPersonDistance;
	else
		traceEnd = traceStart + Vector(rayDirection) * MaxFlashlightDistance;

	hitActor = Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True);

	if (hitActor == None)
	{
		hitLocation = traceEnd;
	}

	if (DebugDrawFlashlightDir)
	{
		Level.GetLocalPlayerController().myHUD.AddDebugLine((traceStart + Vect(0.0,0.0,1.0)), (hitLocation +  Vect(0.0,0.0,1.0)),
															class'Engine.Canvas'.Static.MakeColor(255,120,0), 0.02);
		Level.GetLocalPlayerController().myHUD.AddDebugLine(traceStart, traceEnd,
															class'Engine.Canvas'.Static.MakeColor(255,120,200), 0.02);
	}

	delta = hitLocation - traceStart;
	oldDistance = VSize(traceStart - FlashlightDynamicLight.Location);
	newDistance = VSize(delta) * PointLightDistanceFraction;
	newDistance = oldDistance + (newDistance - oldDistance) * PointLightDistanceFadeRate;

	PointLightPos = traceStart + newDistance * Vector(FlashlightReferenceActor.Rotation);
	FlashlightDynamicLight.SetLocation(PointLightPos);

    if (InFirstPersonView())
	{
		// attenuate the radius if the light is approaching something very close
		FlashlightDynamicLight.LightRadius = MinFlashlightRadius +
			(BaseFlashlightRadius - MinFlashlightRadius) * (newDistance/FlashlightFirstPersonDistance);
	}
	else
	{
		FlashlightDynamicLight.LightRadius = MinFlashlightRadius + newDistance *	PointLightRadiusScale;
	}

	FlashlightDynamicLight.LightBrightness = BaseFlashlightBrightness +
		FMin(newDistance/MaxFlashlightDistance, 1.0) * (MinFlashlightBrightness - BaseFlashlightBrightness);
#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
    FlashlightDynamicLight.LightBrightness *= FlashlightProjection_CurrentBrightnessAlpha;
#endif
	FlashlightDynamicLight.bLightChanged = true;
}

// Sets up any additional rendering resources necessary to create the
// flashlight effect. Should only be called once during the lifetime of the
// weapon.
simulated private function InitFlashlight()
{
    local HandheldEquipmentModel WeaponModel;
    local Vector PositionOffset;
    local Rotator RotationOffset;
    local bool AttachSucceeded;
	local float saveRate;
    local float SavedLastRenderTime;

	// if the FlashlightUseFancyLights value has not been initialized yet...
	if (FlashlightUseFancyLights == -1)
	{
		// this will determine if flashlights use spots or point lights

        // If we don't support bumpmapping, then we don't have pixel shaders
        // and hence dynamic spotlights on BSP surfaces will not work
        bHighEndGraphicsBoard = bool(Level.GetLocalPlayerController().ConsoleCommand( "SUPPORTS BUMPMAP") );

        if (bHighEndGraphicsBoard)
			FlashlightUseFancyLights = 1;
		else
			FlashlightUseFancyLights = 0; // approximate spot light with moving point light
		//log("FLASHLIGHT Fancy lights: " $FlashlightUseFancyLights$" owner: "$owner);

#if 1 // HACK HACK HACK:
        // This is a hack to get around a bug in ATI's drivers where the spotlight
        // pixel shader won't work. They say they'll fix this bug around Jan 05
        // in their new drivers.
        if (bool(Level.GetLocalPlayerController().ConsoleCommand( "USE_ATI_R200_SPOTLIGHT_WORKAROUND") ))
        {
            FlashlightUseFancyLights = 0;
        }
#endif
	}



    assertWithDescription(HasAttachedFlashlight, "[ckline] Attempt to initialize flashlight resources for a weapon that is not flashlight-enabled.");
    assertWithDescription(!IsFlashlightInitialized(), "[ckline] Attempt to initialize flashlight resources twice.");
	//log( "[FLASHLIGHT] In FiredWeapon::IsInitFlashlight() on: "$owner );
	//LogGuardStack();

    // Set up flashlight for first person model if it is weapon is held by the player's pawn.
    if (InFirstPersonView())
    {
		assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up flashlight for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = FlashlightPosition_1stPerson;
		RotationOffset = FlashlightRotation_1stPerson;
		//log( "[FLASHLIGHT] In FiredWeapon::IsInitFlashlight(): First Person" );
    }
    else // todo: handle 3rd person flashlight, including when controller changes
    {
		assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up flashlight for "$self$", ThirdPersonModel is None");
		WeaponModel = ThirdPersonModel;
		PositionOffset = FlashlightPosition_3rdPerson;
		RotationOffset = FlashlightRotation_3rdPerson;
		//log( "[FLASHLIGHT] In FiredWeapon::IsInitFlashlight(): Third Person" );
    }

    assertWithDescription(FlashlightSpotLightClass   != None, "[henry] Can't spawn flashlight spotlight for weapon of class "$Class$" because FlashlightSpotLightClass is None");
    assertWithDescription(FlashlightPointLightClass  != None, "[henry] Can't spawn flashlight pointlight for weapon of class "$Class$" because FlashlightPointLightClass is None");
    assertWithDescription(FlashlightCoronaLightClass != None, "[henry] Can't spawn flashlight coronalight for weapon of class "$Class$" because FlashlightCoronaLightClass is None");

	// if we have a higher-end graphics card, then use a spotlight, otherwise,
	// use a pointlight and try to make it look a little like a spot light by
	// moving it out from the gun barrel
	if (FlashlightUseFancyLights == 1)
	{
		FlashlightDynamicLight = Spawn(FlashlightSpotLightClass,WeaponModel,,,);
		//FlashlightDynamicLight.bActorShadows = true; //doesn't seem to work
		FlashlightDynamicLight.LightCone = 8; //how wide the flashlight beam is
		FlashlightDynamicLight.LightRadius = FlashlightFirstPersonDistance; //distance the beam travels
	}
	else
		FlashlightDynamicLight = Spawn(FlashlightPointLightClass,WeaponModel,,,);

	FlashlightReferenceActor = Spawn(FlashlightCoronaLightClass,WeaponModel,,,);

	FlashlightReferenceActor.bCorona = true; // make coronas dissapear as angle to viewer approaches 90 degrees

	// save the base light params, so that they can be modified later relative
	// to these values (for the pointlight-to-spotlight modeling)
	BaseFlashlightBrightness = FlashlightDynamicLight.LightBrightness;
	BaseFlashlightRadius     = FlashlightDynamicLight.LightRadius;

    assertWithDescription(FlashlightDynamicLight!=None, "[henry] Can't init flashlight, couldn't spawn pointlight of class "$FlashlightPointLightClass);

	// If point lights instead of spot lights are being used,
	// darken the 3rd person pointlights (compared to the first person pointlight) so they don't blow out too much
	if (FlashlightUseFancyLights == 0 && !InFirstPersonView())
	{
		FlashlightDynamicLight.LightBrightness *= 0.5;
		BaseFlashlightBrightness             *= 0.5;
	}

	if (InFirstPersonView())
	{
		// This tag is used in UnRenderVisibility.cpp to give a penalty to
		// all dynamic lights except the first person's flashlight
		FlashlightDynamicLight.Tag = 'FirstPersonFlashlight';

		// no corona for the first person flashlight (it looks bad)
		FlashlightReferenceActor.bCorona = false;
	}
	else
	{
        // decrease the radius of flashlights for 3rd person so that they have a diminished importance when priority sorting the lights
		BaseFlashlightRadius             *= ThirdPersonFlashlightRadiusPenalty;
		FlashlightDynamicLight.LightRadius *= ThirdPersonFlashlightRadiusPenalty;
	}

	// Note: the bHidden flag must be false or else the light does not stay
	// attached to its parent.  But then you see the lightbulb sprite, so the
	// way to get the lightbulb sprite to go away
	// is to set the draw type to DT_None.
	if (!DebugDrawFlashlightDir)
	{
		FlashlightDynamicLight.SetDrawType(DT_None);
		FlashlightReferenceActor.SetDrawType(DT_None);
	}
	else
	{
		// but show the sprites if we are showing flashlight lines for debugging
		FlashlightDynamicLight.bHidden     = false;
		FlashlightReferenceActor.bHidden = false;
		FlashlightDynamicLight.SetDrawType(DT_Sprite);
		FlashlightReferenceActor.SetDrawType(DT_Sprite);
	}

	// attach the flashlight to the weapon model
	AttachSucceeded = WeaponModel.Owner.AttachToBone(FlashlightDynamicLight, WeaponModel.EquippedSocket);

	AssertWithDescription(AttachSucceeded,"[henry] Failed to attach flashlight light to bone '"$WeaponModel.EquippedSocket$"' on actor '"$WeaponModel.Owner$"', check log for reason (probably the bone doesn't exist)");

	// attach the flashlight reference pos to the weapon model
	AttachSucceeded = WeaponModel.Owner.AttachToBone(FlashlightReferenceActor, WeaponModel.EquippedSocket);
	AssertWithDescription(AttachSucceeded,"[henry] Failed to attach flashlight reference position to bone '"$WeaponModel.EquippedSocket$"' on actor '"$WeaponModel.Owner$"', check log for reason (probably the bone doesn't exist)");

	// Adjust the relative orientation and position of the light
	FlashlightDynamicLight.SetRelativeLocation(PositionOffset);
	FlashlightDynamicLight.SetRelativeRotation(RotationOffset);

	FlashlightReferenceActor.SetRelativeLocation(PositionOffset);
	FlashlightReferenceActor.SetRelativeRotation(RotationOffset);

	// update the attachment locations so that the flashlights are pointing in
	// the right direction on the first tick.
    // @NOTE: We're stepping around some special knowledge here that
    // UpdateAttachmentLocations no-ops when LastRenderTime >= Level.TimeSeconds.
    // Save off LastRenderTime, slam it to 0 to guarentee an update, and restore
    // the saved value.
    SavedLastRenderTime = WeaponModel.Owner.LastRenderTime;
    WeaponModel.Owner.LastRenderTime = 0.0;
	WeaponModel.Owner.UpdateAttachmentLocations();
    WeaponModel.Owner.LastRenderTime = SavedLastRenderTime;

#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
    // Initialize flashlight projection state
    FlashlightProjection_IsInitializing = true;
#endif

	// set the initial position so, in the point light case, the light doesn't animate out to it's initial position
	saveRate = PointLightDistanceFadeRate;
	PointLightDistanceFadeRate = 1;
	UpdateFlashlightLighting();
	PointLightDistanceFadeRate = saveRate;

#if ENABLE_FLASHLIGHT_PROJECTION_VISIBILITY_TESTING
    // Restore this flag back to its default value
    FlashlightProjection_IsInitializing = false;
#endif
}

// Checks whether or not the flashlight rendering resources have been initialized.
native protected function bool IsFlashlightInitialized();
native protected function bool IsFlashlightProjectionVisible();

// This function un-initializes any flashlight data that was set up when
// InitFlashlight() was called. This method is normally used to destroy the
// flashlight when the weapon is unequipped, so that the rendering components
// of the flashlight don't hang around when the weapon is not equipped (for
// example, so we don't have multiple flashlight Lights attached to
// the first-person viewport).
private function DestroyFlashlight(float SecondsBeforeDestroying)
{
    local float delay;

    assertWithDescription(IsFlashlightInitialized(), "[ckline] Attempt to destroy an uninitialized flashlight.");

    //Log("Destroying flashlight "$FlashlightDynamicLight.Name$" (after "$SecondsBeforeDestroying$" secs) for Weapon "$self$" being used by Pawn "$Owner);

	if (SecondsBeforeDestroying <= 0)
	{
		// hack to get around the fact that LifeSpan of 0 means "live forever"
	    delay = 0.01; // destroy almost instantly
	}
	else
	{
	    delay = SecondsBeforeDestroying; // destroy almost instantly
	}

	FlashlightDynamicLight.LifeSpan = delay;

	FlashlightDynamicLight = None; // for sanity

	if (FlashlightReferenceActor != None)
	{
        // Force FCoronaRender to gracefully remove the corona on next render pass
        FlashlightReferenceActor.bCorona = false;

        // Destroy the corona light automatically after 1 second, after FCoronaRender has removed it
        FlashlightReferenceActor.LifeSpan = 1 + delay;

		FlashlightReferenceActor = None; // for sanity
	}
}

function OnPlayerViewChanged()
{
    // Destroy the flashlight, then update the flashlight state to match
    // what the pawn wants.
    if (IsFlashlightInitialized())
    {
		DestroyFlashlight(ICanToggleWeaponFlashlight(Owner).GetDelayBeforeFlashlightShutoff());
    }
    UpdateFlashlightState();
}

//
// Support for AIs interrupting HandheldEquipment actions
//
// Please see comments in HandheldEquipment.uc
//

protected function AIInterruptHandheldEquipmentHook()
{
    if (ReloadingStatus > ActionStatus_Idle) AIInterrupt_Reloading();
}

private function AIInterrupt_Reloading()
{
    GotoState('');
    ReloadingStatus = ActionStatus_Idle;
}

///////////////////////////////////////////////////////////////////////////////
//
// Debugging methods
//

simulated function DrawAccuracyCone(vector SourceLocation, rotator SourceDirection)
{
    local float Rho, Theta;
    local vector CurrentEndPoint, LastEndPoint;
    local rotator CurrentDirection;
    local HUD HUD;
    local Color Blue;

    HUD = Level.GetLocalPlayerController().myHUD;
    Blue = class'Engine.Canvas'.Static.MakeColor(0,0,255);

    //Rho = AimError;

	Rho = Tan(GetAimError() * DEGREES_TO_RADIANS);

    for (Theta=0.0; Theta<360.0; Theta+=18.0) //20 segments
    {
        CurrentDirection = SourceDirection;

        ApplyPolarOffset(CurrentDirection, Rho, Theta);

        CurrentEndPoint = SourceLocation + vector(CurrentDirection) * Range;

        HUD.AddDebugLine(SourceLocation, CurrentEndPoint, Blue);

        if (LastEndPoint != vect(0,0,0))
            HUD.AddDebugLine(LastEndPoint, CurrentEndPoint, Blue);

        LastEndPoint = CurrentEndPoint;
    }
}

//angles are in degrees
simulated function ApplyPolarOffset(out rotator outDirection, float Rho, float Theta)
{
	local float  xScale, yScale;
	local vector xPlanarVec, yPlanarVec, zPlanarVec, spherePoint;
	local vector offsetSpherePoint;


	xScale = Rho * Cos(Theta * DEGREES_TO_RADIANS);
	yScale = Rho * Sin(Theta * DEGREES_TO_RADIANS);

	// To make this random circle point appear as a random point within a
	// circle on the sphere, create a plane tangent to the perfect aim
	// direction on the unit sphere.  Define "up" and "left" directions on
	// that plane and project the point in the 2d circle to a point in the
	// circle on the tangent plane.  Then normalize the point to project
	// it back to the sphere, and figure out what rotator angle it is.

	// This method does not introduce errors when the aim is pointed toward
	// the north or south poles.

	// for GetAxes, X points out of the sphere, Y points right (like the
	// x-axis of the tangent plane), and Z points up (in the tangent plane)
	GetAxes(outDirection, xPlanarVec, yPlanarVec, zPlanarVec);
	spherePoint = Vector(outDirection);

	// get the offset point on the circle plane
	offsetSpherePoint = spherePoint + (xScale * yPlanarVec) + (yScale * zPlanarVec);

	// project the point back onto the sphere
	offsetSpherePoint = Normal(offsetSpherePoint);

	// get the rotation at that point
	outDirection = Rotator(offsetSpherePoint);

    //outDirection.Pitch += Rho * Sin(Theta * DEGREES_TO_RADIANS) * DEGREES_TO_TWOBYTE;
    //outDirection.Yaw += Rho * Cos(Theta * DEGREES_TO_RADIANS) * DEGREES_TO_TWOBYTE;
}

cpptext
{
    UBOOL IsFlashlightInitialized();
    UBOOL IsFlashlightOn();
    UBOOL IsFlashlightProjectionVisible();
    void  FlashlightProjectionLineCheck(FCheckResult & Hit, const FVector & End, const FVector & Start);
    static void ApplyRandomOffsetToRotation(const FRotator & OriginalRotation, float OffsetHalfAngleRadians, FRotator & NewRotation);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    HasAttachedFlashlight=False

    BurstRateFactor=1.0
    BurstShotCount=3
    ReloadAnimationRate=1.0

    LookAimErrorQuantizationFactor=1.5

	FlashlightPointLightClass=None
    PointLightDistanceFraction=0.66
	PointLightRadiusScale=.012
    DebugDrawFlashlightDir=false
	FlashlightUseFancyLights=-1
    PointLightDistanceFadeRate=.4
    MinFlashlightBrightness=90
    MinFlashlightRadius=10
	FlashlightFirstPersonDistance=200
	MaxFlashlightDistance=800
    ThirdPersonFlashlightRadiusPenalty=.5
    RagdollDeathImpactMomentumMultiplier=30

    FlashlightProjection_StartBoneName='GripRhand'

	bAbleToMelee=true
}
