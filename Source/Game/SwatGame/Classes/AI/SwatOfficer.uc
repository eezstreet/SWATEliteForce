///////////////////////////////////////////////////////////////////////////////
class SwatOfficer extends SwatAI
    implements  SwatAICommon.ISwatOfficer,
                IControllableThroughViewport,
                Engine.ICanBePepperSprayed,
                Engine.IReactToCSGas,
                Engine.ICanBeTased,
                Engine.IAmAffectedByWeight,
                Engine.ICarryGuns,
                ICanUseC2Charge,
                IInterested_GameEvent_ReportableReportedToTOC
	native;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////

var protected String         OfficerLoadOutType;
var protected OfficerLoadOut LoadOut;

var localized String OfficerFriendlyName;

var private Formation CurrentFormation;

var private SwatDoor  DoorToBlowC2On;

// config
var private config float	 MinTimeToFireFullAuto;
var private config float	 MaxTimeToFireFullAuto;

var private config Material  ViewportOverlayMaterial;

var private float			 NextTimeCanReactToHarmlessShotByPlayer;
var private config float	 DeltaReactionTimeBetweenHarmlessShot;

// When the officer stops avoiding collisions, this timer is started. When the
// timer is triggered, the officer unsets the kUBABCI_AvoidCollisions upper
// animation behavior. This helps smooth out the animation transitioning if the
// officer avoids multiple collisions in fast succession.
var Timer NotifyStoppedMovingTimer;

const kMinNotifyStoppedMovingTime = 0.75;
const kMaxNotifyStoppedMovingTime = 1.25;

cpptext
{
	virtual UBOOL IsOtherActorAThreat(AActor* otherActor);
	UOfficerCommanderAction* GetOfficerCommanderAction() { check(Commander); check(Commander->achievingAction); return Cast<UOfficerCommanderAction>(Commander->achievingAction); }

    // Provides some extra checks for actor-to-pawn collision
    // Overridden from APawn.h. If the other actor is also a SwatOfficer, they
    // should not collide.
    virtual bool WillCollide(const AActor * otherActor, const FVector & otherActorTestLocation) const
    {
        if (otherActor->IsA(ASwatOfficer::StaticClass()))
        {
            return false;
        }

        return Super::WillCollide(otherActor, otherActorTestLocation);
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// ICarryGuns implementation
simulated function int GetStartingAmmoCountForWeapon(FiredWeapon in) {
  // Identical to the one in SwatPlayer
  if(LoadOut.IsWeaponPrimary(in)) {
    return LoadOut.GetPrimaryAmmoCount();
  } else {
    return LoadOut.GetSecondaryAmmoCount();
  }
}

///////////////////////////////////////////////////////////////////////////////
//
// IAmAffectedByWeight implementation
simulated function float GetTotalBulk() {
  return LoadOut.GetTotalBulk();
}

simulated function float GetTotalWeight() {
  return LoadOut.GetTotalWeight();
}

simulated function float GetMaximumWeight() {
	return LoadOut.GetMaximumWeight();
}

simulated function float GetMaximumBulk() {
	return LoadOut.GetMaximumBulk();
}

simulated function float GetWeightMovementModifier() {
  return LoadOut.GetWeightMovementModifier();
}

simulated function float GetBulkQualifyModifier() {
  return LoadOut.GetBulkQualifyModifier();
}

simulated function float GetBulkSpeedModifier() {
	return LoadOut.GetBulkSpeedModifier();
}

simulated function bool HasA(name Class)
{
	return LoadOut.HasA(Class);
}

// Refund lightsticks
function RefundLightstick()
{
	LoadOut.AddLightstick();
}

///////////////////////////////////////////////////////////////////////////////
//
// Engine Events

event PreBeginPlay()
{
	Super.PreBeginPlay();

	AddToSquads();

	// setup the loadout for our officer (dependent on our type)
	InitLoadOut(OfficerLoadOutType);
}

event PostBeginPlay()
{
    Super.PostBeginPlay();
    // Notify the hive that our swat officer has been fully-constructed
    SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficerConstructed(self);

    UpdateOfficerLOD();
    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Register(self);

    NotifyStoppedMovingTimer = Spawn(class'Timer');
    assert(NotifyStoppedMovingTimer  != None);
    NotifyStoppedMovingTimer.TimerDelegate = NotifyStoppedMovingTimerCallback;
}

event Destroyed()
{
	warn("Officer " $ Name $" was destroyed!");

    SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficerDestroyed(self);

	// removes us from all the squads
	RemoveFromSquads();

    if (NotifyStoppedMovingTimer != None)
    {
        NotifyStoppedMovingTimer.Destroy();
        NotifyStoppedMovingTimer = None;
    }

    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.UnRegister(self);
    Super.Destroyed();
}

function EnteredZone(ZoneInfo Zone)
{
	Super.EnteredZone(Zone);

//	log(Name $ " Entered Zone " $ Zone $ " Zone.bUseFlashlight: " $ Zone.bUseFlashlight);

    // don't toggle flashlight when dead/incapacitated
    if (IsConscious())
    {
		// set our flashlight state to whatever the zone says
		SetDesiredFlashlightState(Zone.bUseFlashlight);
	}
}

protected function AddToSquads()		{ assert(false); }	// must be overridden
protected function RemoveFromSquads()	{ assert(false); }	// must be overridden

///////////////////////////////////////////////////////////////////////////////

// This updates some officer-related rendering properties based on the current
// detail level of the world.
public function UpdateOfficerLOD()
{
	local int i;
	local SimpleEquipment se;

	// Change detail settings of SimpleEquipment on swat officer
	// based on world detail settings
	for (i = Pocket.Pocket_SimpleBackPouch; i <= Pocket.Pocket_SimpleRadioPouch; ++i)
	{
		se = SimpleEquipment(Loadout.GetItemAtPocket(Pocket(i)));
		assertWithDescription(se != None, "Item at pocket "$GetEnum(Pocket, i)$" is None or not SimpleEquipment");
		if (Level.DetailMode == DM_Low)
		{
			// Hide all simpleequipment on officers
			se.bHidden		= true;
			se.CullDistance = 1; // doesn't really matter, but just in case culldistance is checked earlier in pipeline than bHidden
		}
		else if (Level.DetailMode == DM_High)
		{
			// Don't hide simpleequipment on officers, but make it disappear
			// after a certain distance
			se.bHidden		= false;
			se.CullDistance = 875;
		}
		else
		{
			// Don't hide simpleequipment on officers, and never cull it
			se.bHidden		= false;
			se.CullDistance = 0; // never cull
		}
	}

}

///////////////////////////////////////////////////////////////////////////////
//
// Resource Construction

// Create SwatOfficer specific abilities
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);

	characterResource.addAbility(new class'SwatAICommon.OfficerCommanderAction');
	characterResource.addAbility(new class'SwatAICommon.OfficerSpeechManagerAction');
	characterResource.addAbility(new class'SwatAICommon.StackedUpAction');
	characterResource.addAbility(new class'SwatAICommon.RemoveWedgeAction');
	characterResource.addAbility(new class'SwatAICommon.PlaceWedgeAction');
	characterResource.addAbility(new class'SwatAICommon.PickLockAction');
	characterResource.addAbility(new class'SwatAICommon.TryDoorAction');
	characterResource.addAbility(new class'SwatAICommon.StackUpAction');
	characterResource.addAbility(new class'SwatAICommon.CheckTrapsAction');
	characterResource.addAbility(new class'SwatAICommon.MirrorAllAction');
	characterResource.addAbility(new class'SwatAICommon.MoveAndClearAction');
	characterResource.addAbility(new class'SwatAICommon.FallInAction');
	characterResource.addAbility(new class'SwatAICommon.ThrowGrenadeAction');
	characterResource.addAbility(new class'SwatAICommon.UseBreachingChargeAction');
	characterResource.addAbility(new class'SwatAICommon.UseBreachingShotgunAction');
	characterResource.addAbility(new class'SwatAICommon.EngageForComplianceAction');
	characterResource.addAbility(new class'SwatAICommon.AttackEnemyAction');
	characterResource.addAbility(new class'SwatAICommon.RestrainAndReportAction');
	characterResource.addAbility(new class'SwatAICommon.SecureEvidenceAction');
	characterResource.addAbility(new class'SwatAICommon.DeployTaserAction');
	characterResource.addAbility(new class'SwatAICommon.DeployLessLethalShotgunAction');
	characterResource.addAbility(new class'SwatAICommon.DeployGrenadeLauncherAction');
	characterResource.addAbility(new class'SwatAICommon.DeployPepperBallAction');
	characterResource.addAbility(new class'SwatAICommon.DeployPepperSprayAction');
	characterResource.addAbility(new class'SwatAICommon.DropLightstickAction');
	characterResource.addAbility(new class'SwatAICommon.DisableTargetAction');
	characterResource.addAbility(new class'SwatAICommon.CoverAction');
	characterResource.addAbility(new class'SwatAICommon.GuardAction');
	characterResource.addAbility(new class'SwatAICommon.WatchNonHostileTargetAction');
	characterResource.addAbility(new class'SwatAICommon.MirrorDoorAction');
	characterResource.addAbility(new class'SwatAICommon.MirrorCornerAction');
  characterResource.addAbility(new class'SwatAICommon.ReportAction');
  characterResource.addAbility(new class'SwatAICommon.SWATTakeCoverAndAttackAction');
  characterResource.addAbility(new class'SwatAICommon.SWATTakeCoverAndAimAction');
  	characterResource.addAbility(new class'SwatAICommon.ShareEquipmentAction');

	// call down the chain
	Super.ConstructCharacterAI();
}

protected function ConstructMovementAI()
{
	local AI_Resource movementResource;
    movementResource = AI_Resource(movementAI);
    assert(movementResource != none);

	movementResource.addAbility(new class'SwatAICommon.MoveInFormationAction');
	movementResource.addAbility(new class'SwatAICommon.MoveOfficerToEngageAction');

	// call down the chain
	Super.ConstructMovementAI();
}

protected function ConstructWeaponAI()
{
	local AI_Resource weaponResource;
    weaponResource = AI_Resource(weaponAI);
    assert(weaponResource != none);


	weaponResource.addAbility(new class'SwatAICommon.UseOptiwandAction');
	weaponResource.addAbility(new class'SwatAICommon.UseGrenadeAction');
	weaponResource.addAbility(new class'SwatAICommon.LaunchGrenadeAction');
	weaponResource.addAbility(new class'SwatAICommon.OrderComplianceAction');
	weaponResource.addAbility(new class'SwatAICommon.ReloadAction');

	// call down the chain
	Super.ConstructWeaponAI();
}

///////////////////////////////////////////////////////////////////////////////
//
// Current Assignment

event Pawn GetCurrentAssignment()
{
	return GetOfficerCommanderAction().GetCurrentAssignment();
}

function bool IsAttackingPlayer()
{
	local Pawn CurrentAssignment;
	CurrentAssignment = GetCurrentAssignment();
	return ((CurrentAssignment != None) && CurrentAssignment.IsA('SwatPlayer'));
}

///////////////////////////////////////////////////////////////////////////////
//
// Damage / Death

function NotifyHit(float Damage, Pawn HitInstigator)
{
	local SwatPlayer PlayerInstigator;
    local bool       IsHitByPlayer;

//	log("NotifyHit - Damage: " $ Damage $ " HitInstigator: " $ HitInstigator $ " IsIncapacitated: " $ IsIncapacitated());
    IsHitByPlayer = HitInstigator.IsA( 'SwatPlayer' ) || HitInstigator.IsA( 'SniperPawn' );

	// the following doesn't need to be networked because we have no Officers in Coop
    if ( IsHitByPlayer )
	    PlayerInstigator = SwatPlayer(Level.GetLocalPlayerController().Pawn);

	if ((PlayerInstigator != None) && !IsIncapacitated())
	{
		// if we are a god we don't attack the player (request by paul)
		if (! Controller.bGodMode)
		{
			SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficerShotByPlayer(self, Damage, PlayerInstigator);
		}
	}
}

// overridden from SwatAI
function NotifyBecameIncapacitated(Pawn Incapacitator)
{
    local FiredWeapon CurrentWeapon;

    // give the killer a bonus if they're an enemy
	if ((Incapacitator != None) && Incapacitator.IsA('SwatEnemy'))
	{
		SwatEnemy(Incapacitator).GetEnemyCommanderAction().NotifyKilledOfficer(self);
	}

	// removes us from all the squads
	RemoveFromSquads();

	// notify the hive of our death
	SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficerDied(self);

    // if our flashlight is on, have it turn off after X seconds, for
    // performance
    CurrentWeapon = FiredWeapon(GetActiveItem());
    if (CurrentWeapon != None && CurrentWeapon.IsFlashlightOn())
    {
	    Log("Officer "$name$ " became incapacitated; turning flashlight off after delay");
        // NOTE: SwatPawn.GetDelayBeforeFlashlightShutoff() will return a longer
        // delay since this pawn is dead/incapacitated, instead of being an
        // instantaneous shutoff.
        SetDesiredFlashlightState(false);
    }
}

function bool ShouldBecomeIncapacitated()
{
	// officers always become incapacitated when health is less than the incapacitated amount
	return (Health <= GetIncapacitatedDamageAmount());
}

///////////////////////////////////////////////////////////////////////////////
//
// Movement Notifications

event NotifyStartedMoving()
{
    super.NotifyStartedMoving();

    if (NotifyStoppedMovingTimer != None)
    {
        NotifyStoppedMovingTimer.StopTimer();
    }

    SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AvoidCollisions);
}

event NotifyStoppedMoving()
{
    super.NotifyStoppedMoving();

    AnimSnapBaseToAim();

    if (NotifyStoppedMovingTimer != None)
    {
        NotifyStoppedMovingTimer.StartTimer(RandRange(kMinNotifyStoppedMovingTime, kMaxNotifyStoppedMovingTime));
    }
    else
    {
        // Fail-safe, in the bizarre case that NotifyStoppedMovingTimer is
        // None, we call the callback directly.
        NotifyStoppedMovingTimerCallback();
    }
}

simulated function NotifyStoppedMovingTimerCallback()
{
    UnsetUpperBodyAnimBehavior(kUBABCI_AvoidCollisions);
}

///////////////////////////////////////////////////////////////////////////////
//
// IControllableThroughViewport Interface
function Actor GetViewportOwner()
{
    return Self;
}

// Possibly offset from the controlled direction
function            OffsetViewportRotation( out Rotator ViewportRotation );

// Called to allow the viewport to modify mouse acceleration
simulated function            AdjustMouseAcceleration( out Vector MouseAccel );

// Called whenever the mouse is moving (and this controllable is being controlled)
function            OnMouseAccelerated( out Vector MouseAccel );

function string GetViewportType()
{
    return string(name);
}

function string  GetViewportDescription()
{
    return "";
}

function string  GetViewportName()
{
    return GetHumanReadableName();
}

simulated function bool   CanIssueCommands()
{
    return true;
}

function            OnBeginControlling()
{
    LockAim();
}

function            OnEndControlling()
{
    UnLockAim();
}

function Vector  GetViewportLocation()
{
    return GetViewpoint();
}

function Rotator GetViewportDirection()
{
    return Rotator(GetViewDirection());
}

function float   GetViewportPitchClamp()
{
    return 55.0;
}

function float   GetViewportYawClamp()
{
    return 0;  // Zero means no restrictions
}

function         SetRotationToViewport(Rotator inNewRotation)
{
    AimToRotation(inNewRotation);
}

function bool   ShouldDrawViewport()
{
    return !checkDead(Self) && !IsIncapacitated();
}

function Material GetViewportOverlay()
{
    return ViewportOverlayMaterial;
}

// Return the original rotation...
function Rotator    GetOriginalDirection()
{
    return Rotation;
}

// For controlling...
function float      GetViewportPitchSpeed()
{
    return 0.6;
}

// For controlling...
function float      GetViewportYawSpeed()
{
    return 0.6;
}

function bool   ShouldDrawReticle()
{
    return true;
}

simulated function        float GetFOV();
simulated function        HandleFire();
simulated function        HandleAltFire();
simulated function        HandleReload();

///////////////////////////////////////////////////////////////////////////////

function PlayTurnAwayAnimation()
{
	local name TurnAwayAnimation;

	TurnAwayAnimation = GetTurnAwayAnimation();
	if (TurnAwayAnimation != '')
	{
		AnimPlaySpecial(TurnAwayAnimation, 0.1, GetUpperBodyBone());
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Loadout

private function InitLoadOut( String LoadOutName )
{
    local DynamicLoadOutSpec LoadOutSpec;
    local CustomScenario CustomScen;

	LoadOut = Spawn(class'OfficerLoadOut', self, name("Default"$LoadOutName));
	assert(LoadOut != None);

    if( Level.IsTraining )
    	LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, name("Default"$LoadOutName));
    else
    {
        //for custom missions, force loadouts to be the loadout specified by the custom mission if not 'Any'
        CustomScen = SwatRepo( Level.GetRepo() ).GuiConfig.CurrentMission.CustomScenario;

        if( CustomScen != None &&
            self.IsA('OfficerRedOne') &&
            CustomScen.RedOneLoadOut != 'Any' )
        {
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, CustomScen.RedOneLoadOut);
        }
        else if( CustomScen != None &&
                 self.IsA('OfficerRedTwo') &&
                 CustomScen.RedTwoLoadOut != 'Any' )
        {
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, CustomScen.RedTwoLoadOut);
        }
        else if( CustomScen != None &&
                 self.IsA('OfficerBlueOne') &&
                 CustomScen.BlueOneLoadOut != 'Any' )
        {
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, CustomScen.BlueOneLoadOut);
        }
        else if( CustomScen != None &&
                 self.IsA('OfficerBlueTwo') &&
                 CustomScen.BlueTwoLoadOut != 'Any' )
        {
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, CustomScen.BlueTwoLoadOut);
        }
	    else
    	    LoadOutSpec = Spawn(class'DynamicLoadOutSpec', self, name("Current"$LoadOutName));
    }
	assert(LoadOutSpec != None);

	LoadOut.Initialize( LoadOutSpec, false );
	ReceiveLoadout();
}

// This is basically the same function as the SwatPlayer::ReceiveLoadOut.
// We don't share this functionality somehow
// a. not all subclasses of the common base class will use this functionality.
// b. the functionality will most likely diverge sometime down the road, possibly causing maintenance headaches
// c. we don't have multiple inheritance
private function ReceiveLoadOut()
{
	assert(LoadOut != None);

    log( "------LoadOut.Owner="$LoadOut.Owner );

    Skins[0] = LoadOut.GetPantsMaterial();
    Skins[1] = LoadOut.GetFaceMaterial();
    Skins[2] = LoadOut.GetNameMaterial();
    Skins[3] = LoadOut.GetVestMaterial();

    if ( LoadOut.GetPrimaryWeapon() != None && !LoadOut.GetPrimaryWeapon().IsA('NoWeapon') && !LoadOut.GetPrimaryWeapon().OfficerWontEquipAsPrimary )
    {
        LoadOut.GetPrimaryWeapon().Equip();
    }
    else if (LoadOut.GetBackupWeapon() != None && !LoadOut.GetBackupWeapon().IsA('NoWeapon'))
    {
        LoadOut.GetBackupWeapon().Equip();
    }
    else
    {
        warn("An AI Officer has no Weapon (no weapon was specified in his LoadOut).");
    }

	// make sure we have the correct animations to go with our loadout
	ChangeAnimation();
}

//Pawn override
simulated function DestroyEquipment()
{
    LoadOut.Destroy();
}


///////////////////////////////////////////////////////////////////////////////
//
// Awareness

function AwarenessProxy GetAwareness()
{
    // Officers use a shared awareness, managed by the hive
    return SwatAIRepository(Level.AIRepo).GetHive().GetAwareness();
}

function DisableAwareness()
{
    SwatAIRepository(Level.AIRepo).GetHive().DisableAwareness();
}

function EnableAwareness()
{
    SwatAIRepository(Level.AIRepo).GetHive().EnableAwareness();
}

///////////////////////////////////////////////////////////////////////////////
//
// AI Vision

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we see everyone except our own
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatOfficer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatPlayer')  ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

///////////////////////////////////////////////////////////////////////////////
//
// Formations

function Formation GetCurrentFormation()
{
	return CurrentFormation;
}

function SetCurrentFormation(Formation Formation)
{
	assert(Formation != None);

	// clear any existing formation out
	ClearFormation();

	// set the new formation
	CurrentFormation = Formation;
	CurrentFormation.AddRef();
}

function ClearFormation()
{
	if (CurrentFormation != None)
	{
		CurrentFormation.Release();
		CurrentFormation = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Animation

// officers do not play the full body hit animations
function bool ShouldPlayFullBodyHitAnimation()
{
	return false;
}

// Only allow low-ready if the officer is not aiming at a staircase aim point
protected function bool CanPawnUseLowReady()
{
    return true;
}

simulated function EAnimationSet GetStandingInjuredAnimSet()    { return kAnimationSetOfficerInjuredStanding; }
simulated function EAnimationSet GetCrouchingInjuredAnimSet()   { return kAnimationSetOfficerInjuredCrouching; }

function EUpperBodyAnimBehavior GetMovementUpperBodyAimBehavior()
{
	// by default we use low ready when moving
	return kUBAB_AimWeapon;
}

///////////////////////////////////////////////////////////////////////////////
//
// Equipment

function ThrownWeapon GetThrownWeapon(EquipmentSlot Slot)
{
	return ThrownWeapon(GetItemAtSlot(Slot));
}

function HandheldEquipment GetItemAtSlot(EquipmentSlot Slot)
{
	return LoadOut.GetItemAtSlot(Slot);
}

// overridden from ISwatAI
function float GetTimeToWaitBeforeFiring()
{
	return RandRange(0.05, 0.1);
}

// overridden from SwatAI
protected function float GetLengthOfTimeToFireFullAuto()
{
	return RandRange(MinTimeToFireFullAuto, MaxTimeToFireFullAuto);
}

///////////////////////////////////////////////////////////////////////////////
//
// ISwatOfficer implementation

function FiredWeapon GetPrimaryWeapon()
{
    return LoadOut.GetPrimaryWeapon();
}

function FiredWeapon GetBackupWeapon()
{
    return LoadOut.GetBackupWeapon();
}

function bool HasUsableWeapon()
{
	return (((GetPrimaryWeapon() != None) && !GetPrimaryWeapon().IsEmpty()) ||
		    ((GetBackupWeapon() != None) && !GetBackupWeapon().IsEmpty()));
}

native function OfficerCommanderAction GetOfficerCommanderAction();

function OfficerSpeechManagerAction	GetOfficerSpeechManagerAction()
{
	return OfficerSpeechManagerAction(GetSpeechManagerAction());
}

//ICanUseC2Charge Implementation

simulated function SetDeployedC2Charge(DeployedC2ChargeBase Charge)
{
    // @NOTE: Intentionally empty
}

simulated function DeployedC2ChargeBase GetDeployedC2Charge()
{
    if (DoorToBlowC2On != None)
    {
        if (DoorToBlowC2On.PointIsToMyLeft(Location))
        {
            if (DoorToBlowC2On.IsChargePlacedOnLeft())
            {
                return DoorToBlowC2On.GetDeployedC2ChargeLeft();
            }
        }
        else
        {
            if (DoorToBlowC2On.IsChargePlacedOnRight())
            {
                return DoorToBlowC2On.GetDeployedC2ChargeRight();
            }
        }
    }

    return None;
}

latent function ReEquipFiredWeapon()
{
	local FiredWeapon PrimaryWeapon, BackupWeapon;

	// only try and re-equip if we're conscious
	if (IsConscious())
	{
		PrimaryWeapon = GetPrimaryWeapon();
		BackupWeapon  = GetBackupWeapon();

		if ((PrimaryWeapon != None) && ! PrimaryWeapon.IsEmpty() && !PrimaryWeapon.OfficerWontEquipAsPrimary)
		{
			PrimaryWeapon.LatentEquip();
		}
		else if ((BackupWeapon != None) && ! BackupWeapon.IsEmpty())
		{
			BackupWeapon.LatentEquip();
		}
	}
}

// will re-equip a fired weapon (primary or backup) if the active item is not the primary or backup weapon
function InstantReEquipFiredWeapon()
{
	local FiredWeapon PrimaryWeapon, BackupWeapon;

	// only try and re-equip if we're conscious
	if (IsConscious())
	{
		PrimaryWeapon = GetPrimaryWeapon();
		BackupWeapon  = GetBackupWeapon();

		if ((GetActiveItem() != PrimaryWeapon) || (PrimaryWeapon == None) || PrimaryWeapon.IsEmpty())
		{
			if ((PrimaryWeapon != None) && !PrimaryWeapon.IsEmpty() && !PrimaryWeapon.OfficerWontEquipAsPrimary)
			{
				PrimaryWeapon.AIInstantEquip();
			}
			else if ((GetActiveItem() != BackupWeapon) && (BackupWeapon != None) && !BackupWeapon.IsEmpty())
			{
				BackupWeapon.AIInstantEquip();
			}
		}
	}
}

function bool HasTaser()
{
	return HasA('Taser');
}

function bool HasLauncherWhichFires(EquipmentSlot Slot)
{
	return (GetLauncherWhichFires(Slot) != None);
}

function FiredWeapon GetLauncherWhichFires(EquipmentSlot Slot)
{
	local FiredWeapon PrimaryWeapon;
	local FiredWeapon SecondaryWeapon;

	PrimaryWeapon = GetPrimaryWeapon();
	if(PrimaryWeapon == None || !PrimaryWeapon.IsA('GrenadeLauncherBase') ||
		PrimaryWeapon.IsEmpty() || PrimaryWeapon.GetFiredGrenadeEquipmentSlot() != Slot)
	{
		SecondaryWeapon = GetBackupWeapon();

		if(SecondaryWeapon == None || !SecondaryWeapon.IsA('GrenadeLauncherBase') ||
			SecondaryWeapon.IsEmpty() || SecondaryWeapon.GetFiredGrenadeEquipmentSlot() != Slot)
		{
			return None;
		}

		return SecondaryWeapon;
	}

	return PrimaryWeapon;
}

function SetDoorToBlowC2On(Door TargetDoor)
{
    DoorToBlowC2On = SwatDoor(TargetDoor);
}

///////////////////////////////////////////////////////////////////////////////
//
// Navigation

event PlayerBlockingPath()
{
	GetOfficerSpeechManagerAction().TriggerPlayerInTheWaySpeech();
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI

simulated function name GetEffectEventForReportingToTOCWhenDead()           { assertWithDescription(false, "Unexpected: reported a dead swat officer"); return ''; }
simulated function name GetEffectEventForReportingToTOCWhenArrested()       { assertWithDescription(false, "Unexpected: reported an arrested swat officer"); return ''; }

// Subclasses should override these functions with class-specific response
// effect event names. Overridden from SwatAI
simulated function name GetEffectEventForReportResponseFromTOCWhenIncapacitated()      { return 'RepliedOfficerDown'; }
simulated function name GetEffectEventForReportResponseFromTOCWhenNotIncapacitated()   { assertWithDescription(false, "Unexpected: TOC responding to a non-incapacitated swat officer"); return ''; }

// IIInterested_GameEvent_ReportableReportedToTOC implementation

function ReportToTOC(name EffectEventName, name ReplyEventName, Actor other, SwatGamePlayerController controller);
function IAmReportableCharacter GetCurrentReportableCharacter();
function SetCurrentReportableCharacter(IAmReportableCharacter InChar);

function OnReportableReportedToTOC(IAmReportableCharacter ReportableCharacter, Pawn Reporter) {
  local Controller i;
  local SwatGamePlayerController current;
  local name EffectEventName;
  local name ReplyEventName;

  if(Reporter != Self) {
    return;
  }

  EffectEventName = ReportableCharacter.GetEffectEventForReportingToTOC();
  ReplyEventName = ReportableCharacter.GetEffectEventForReportResponseFromTOC();
  SetCurrentReportableCharacter(ReportableCharacter);

  log("Officer "$Reporter$" is reporting "$ReportableCharacter);

  // Walk the controller list here to notify all clients
  for ( i = Level.ControllerList; i != None; i = i.NextController )
  {
      current = SwatGamePlayerController( i );
      if ( current != None )
      {
          ReportToTOC(EffectEventName, ReplyEventName, Actor(ReportableCharacter), current);
      }
  }
}

///////////////////////////////////////////////////////////////////////////////
//
// Harmless Shots

private function TriggerHarmlessShotSpeech()
{
	if (Level.TimeSeconds > NextTimeCanReactToHarmlessShotByPlayer)
	{
		NextTimeCanReactToHarmlessShotByPlayer = Level.TimeSeconds + DeltaReactionTimeBetweenHarmlessShot;

		GetOfficerSpeechManagerAction().TriggerReactedFirstShotSpeech();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// AFFECTED BY NON-LETHAL
//
// Non-lethal reaction interface implementations --eez
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// IReactToFlashbangGrenade implementation
/*function ReactToFlashbangGrenade(
    SwatGrenadeProjectile Grenade,
	Pawn  Instigator,
    float Damage, float DamageRadius,
    Range KarmaImpulse,
    float KarmaImpulseRadius,
    float StunRadius,
    float PlayerFlashbangStunDuration,
    float AIStunDuration,
    float MoraleModifier)
{
	if(HasProtection( 'IProtectFromFlashbang' ) )) {
		return;
	}

	if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
        return;
}*/

///////////////////////////////////////////////////////////////////////////////
//
// IReactToCSGas implementation

function ReactToCSGas(Actor GasContainer, float Duration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor)
{
	if (GasContainer.IsA('CSBallBase'))
	{
		TriggerHarmlessShotSpeech();
	}

}

///////////////////////////////////////////////////////////////////////////////
//
// ICanBePepperSprayed implementation


function ReactToBeingPepperSprayed(Actor PepperSpray, float PlayerDuration, float AIDuration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor)
{
	TriggerHarmlessShotSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// ICanBeTased implementation

function ReactToBeingTased( Actor Taser, float PlayerDuration, float AIDuration )
{
  SwatGameInfo(Level.Game).GameEvents.PawnTased.Triggered(self, Taser);
}

simulated function bool IsVulnerableToTaser()
{
    //Fix 2436: Spec says that taser should only affect players with no armor, but this makes no sense
    //
    //Paul wants players to always be vulnerable to Taser:
//    //heavy armor protects from taser
//    return (!GetLoadOut().HasHeavyArmor());
    return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Debug

function DrawLineToAssignment(HUD DrawTarget)
{
	local Pawn Assignment;

	Assignment = GetOfficerCommanderAction().GetCurrentAssignment();

	if (Assignment != None)
	{
		DrawTarget.Draw3DLine(Location, Assignment.Location, class'Canvas'.Static.MakeColor(255,0,0));
	}
}

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////

simulated function bool ReadyToTriggerEffectEvents()
{
    return HasEquippedFirstItemYet;
}

///////////////////////////////////////////////////////////////////////////////
//
// Misc

// Override superclass method so that in single player games it gives the
// proper name instead of "OfficerBlueTwo0" or some other auto-generated name
simulated function String GetHumanReadableName()
{
    if (Level.NetMode == NM_StandAlone)
    {
        return OfficerFriendlyName;
    }

    // Superclass will deal non-standalone games, etc
    return Super.GetHumanReadableName();
}

///////////////////////////////////////////////////////////////////////////////

simulated function OnLightstickKeyFrame()
{
	if (!GetItemAtSlot(SLOT_Lightstick).HasPlayedEquip())
	{
		GetItemAtSlot(SLOT_Lightstick).OnEquipKeyFrame();
	}
	else
	{
		GetItemAtSlot(SLOT_Lightstick).OnUseKeyFrame();
	}
}

///////////////////////////////////////////////////////////////////////////////

simulated function AdjustOfficerMovementSpeed() {
  local float OriginalFwd, OriginalBck, OriginalSde;
  local float ModdedFwd, ModdedBck, ModdedSde;
  local float TotalWeight;

  local AnimationSetManager AnimationSetManager;
  local AnimationSet setObject;

  AnimationSetManager = SwatRepo(Level.GetRepo()).GetAnimationSetManager();
  setObject = AnimationSetManager.GetAnimationSet(GetMovementAnimSet());

  OriginalFwd = setObject.AnimSpeedForward;
  OriginalBck = setObject.AnimSpeedBackward;
  OriginalSde = setObject.AnimSpeedSidestep;

  ModdedFwd = OriginalFwd;
  ModdedBck = OriginalBck;
  ModdedSde = OriginalSde;

  ModdedFwd *= LoadOut.GetWeightMovementModifier();
  ModdedBck *= LoadOut.GetWeightMovementModifier();
  ModdedSde *= LoadOut.GetWeightMovementModifier();

  AnimSet.AnimSpeedForward = ModdedFwd;
  AnimSet.AnimSpeedBackward = ModdedBck;
  AnimSet.AnimSpeedSidestep = ModdedSde;

  TotalWeight = LoadOut.GetTotalWeight();
}

simulated function Tick(float dTime) {
  AdjustOfficerMovementSpeed();
}

simulated function GivenEquipmentFromPawn(HandheldEquipment Equipment)
{
	Loadout.GivenEquipmentFromPawn(Equipment);
}

defaultproperties
{
	AnimRotationUrgency = kARU_VeryFast

	CollisionRadius             =  24.0
    CollisionHeight             =  68.0

    OfficerLoadOutType="OfficerLoadOut"
    // Peripheral vision is 90 degrees on either side (for a total of 180 degrees)
    PeripheralVision            = 0.0

	bAlwaysUseWalkAimErrorWhenMoving=true
	bAlwaysTestPathReachability=true
}
