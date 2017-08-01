///////////////////////////////////////////////////////////////////////////////
// SwatAI.uc
// UnrealScript file for ASwatAI class - Base class of all AIs in SWAT
///////////////////////////////////////////////////////////////////////////////

class SwatAI extends SwatRagdollPawn
    implements  SwatAICommon.ISwatAI,
                IUseArchetype,
                SwatAIAwareness.IAwarenessOuter,
                ICanThrowWeapons,
                IEffectObserver,
                IAmReportableCharacter // For reporting to TOC when AI is dead/incapacitated/restrained
    native
    abstract
    dependson(UpperBodyAnimBehaviorClients);
///////////////////////////////////////////////////////////////////////////////

import enum AIThrowSide from SwatAICommon.ISwatAI;
import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// SwatAI Variables

// Our Vision Notifier
var VisionNotifier                      Vision;

// Our Hearing Notifier
var HearingNotifier                     Hearing;

// Incapacitated
var private bool						bIsIncapacitated;

// Compliant
var private bool						bIsCompliant;

// Where we "See" from
var name                                EyeBoneName;
var const int                           EyeBoneIndex;
var private const vector				CurrentViewPoint;
var private const rotator				CurrentViewDirection;
var private const float					LastViewUpdateTime;

// the current type of idles we want to use (specified by the artist)
var private name						IdleCategory;

// the last time we updated the idle
var private float						LastIdleUpdateTime;

// Each AI has its own instance of a knowledge object, to manage what it
// knows about other objects in the world.
var private AIKnowledge                 AIKnowledge;

// Each AI has its own instance of a take cover object.
var private AICoverFinder               AICoverFinder;

// Our pending door
var private SwatDoor					PendingDoor;

// For debugging ais
var bool                                bShowBlackboardDebugInfo;
var bool                                bShowTyrionCharacterDebugInfo;
var bool								bShowTyrionMovementDebugInfo;
var bool								bShowTyrionWeaponDebugInfo;
var bool								bShowTyrionHeadDebugInfo;
var bool                                bShowMoraleHistoryDebugInfo;
var bool								bShowAimingDebugInfo;

// Sensing
var bool								bVisionDisabled;
var bool								bVisionDisabledPermanently;
var bool								bHearingDisabled;
var bool								bHearingDisabledPermanently;

// Movement
var private float						PlayerBlockingPathStartTime;
var config float						PlayerBlockingPathTime;
var protected bool						bAlwaysTestPathReachability;
var config float						PathReachabilityRenderedRecentlyDelta;

// Upper body animation behavior data
struct native UpperBodyAnimBehaviorEntry
{
    var EUpperBodyAnimBehavior behavior;
    var int clientId;
};

// This array is ordered from highest to lowest priority
var private array<UpperBodyAnimBehaviorEntry> UpperBodyAnimBehaviorEntries;

// Config animations - Flashbang
var config array<name>					FBStandingReactionAnimations;
var config array<name>					FBStandingNoWeaponReactionAnimations;
var config array<name>					FBCrouchingReactionAnimations;
var config array<name>					FBCrouchingNoWeaponReactionAnimations;
var config array<name>					FBCompliantReactionAnimations;
var config array<name>					FBRestrainedReactionAnimations;

var config array<name>					FBStandingAffectedAnimations;
var config array<name>					FBStandingNoWeaponAffectedAnimations;
var config array<name>					FBCrouchingAffectedAnimations;
var config array<name>					FBCrouchingNoWeaponAffectedAnimations;
var config array<name>					FBCompliantAffectedAnimations;
var config array<name>					FBRestrainedAffectedAnimations;

var config array<name>					FBStandingRecoveryAnimations;
var config array<name>					FBStandingNoWeaponRecoveryAnimations;
var config array<name>					FBCrouchingRecoveryAnimations;
var config array<name>					FBCrouchingNoWeaponRecoveryAnimations;
var config array<name>					FBCompliantRecoveryAnimations;
var config array<name>					FBRestrainedRecoveryAnimations;

// Config animations - Gassed
var config array<name>					GasStandingReactionAnimations;
var config array<name>					GasStandingNoWeaponReactionAnimations;
var config array<name>					GasCrouchingReactionAnimations;
var config array<name>					GasCrouchingNoWeaponReactionAnimations;
var config array<name>					GasCompliantReactionAnimations;
var config array<name>					GasRestrainedReactionAnimations;

var config array<name>					GasStandingAffectedAnimations;
var config array<name>					GasStandingNoWeaponAffectedAnimations;
var config array<name>					GasCrouchingAffectedAnimations;
var config array<name>					GasCrouchingNoWeaponAffectedAnimations;
var config array<name>					GasCompliantAffectedAnimations;
var config array<name>					GasRestrainedAffectedAnimations;

var config array<name>					GasStandingRecoveryAnimations;
var config array<name>					GasStandingNoWeaponRecoveryAnimations;
var config array<name>					GasCrouchingRecoveryAnimations;
var config array<name>					GasCrouchingNoWeaponRecoveryAnimations;
var config array<name>					GasCompliantRecoveryAnimations;
var config array<name>					GasRestrainedRecoveryAnimations;

// Config animations - Tased
var config array<name>					TasedStandingReactionAnimations;
var config array<name>					TasedCrouchingReactionAnimations;
var config array<name>					TasedCompliantReactionAnimations;
var config array<name>					TasedRestrainedReactionAnimations;

var config array<name>					TasedStandingAffectedAnimations;
var config array<name>					TasedCrouchingAffectedAnimations;
var config array<name>					TasedCompliantAffectedAnimations;
var config array<name>					TasedRestrainedAffectedAnimations;

var config array<name>					TasedStandingRecoveryAnimations;
var config array<name>					TasedCrouchingRecoveryAnimations;
var config array<name>					TasedCompliantRecoveryAnimations;
var config array<name>					TasedRestrainedRecoveryAnimations;

// Config animations - Stung
var config array<name>					StungStandingReactionAnimations;
var config array<name>					StungStandingNoWeaponReactionAnimations;
var config array<name>					StungCrouchingReactionAnimations;
var config array<name>					StungCrouchingNoWeaponReactionAnimations;
var config array<name>					StungCompliantReactionAnimations;
var config array<name>					StungRestrainedReactionAnimations;

var config array<name>					StungStandingAffectedAnimations;
var config array<name>					StungStandingNoWeaponAffectedAnimations;
var config array<name>					StungCrouchingAffectedAnimations;
var config array<name>					StungCrouchingNoWeaponAffectedAnimations;
var config array<name>					StungCompliantAffectedAnimations;
var config array<name>					StungRestrainedAffectedAnimations;

var config array<name>					StungStandingRecoveryAnimations;
var config array<name>					StungStandingNoWeaponRecoveryAnimations;
var config array<name>					StungCrouchingRecoveryAnimations;
var config array<name>					StungCrouchingNoWeaponRecoveryAnimations;
var config array<name>					StungCompliantRecoveryAnimations;
var config array<name>					StungRestrainedRecoveryAnimations;

// Config animations - Flinching
var config array<name>					StandingFlinchAnimations;
var config array<name>					CrouchingFlinchAnimations;
var config array<name>					CompliantFlinchAnimations;
var config array<name>					RestrainedFlinchAnimations;

//when the SwatAI releases a ThrownWeapon (AnimNotify_Use), the initial location of the projectile
//  will be set to the Pawn's Location + ThrownProjectileInitialOffset
var config vector                       UnderhandThrownProjectileInitialOffset;
var config vector                       OverhandThrownProjectileInitialOffset;
var config int                          ThrownProjectilePitch;  //in degrees
var config name							ThrowShortAnimation;
var config name							ThrowLongAnimation;
var config name							ThrowFromLeftAnimation;
var config name							ThrowFromRightAnimation;

var config float						ThrowAnimationTweenTime;
var config float						MaxUnderhandThrowDistance;
var config float						ZPositiveOffsetForOverhandThrow;
var config vector						ShoulderOffset;

var config float						MinLastRenderedTimeDeltaForRelevency;

var config float						MinTimeBetweenFireHG;
var config float						MaxTimeBetweenFireHG;

var config float						MinTimeBetweenFireSMGSingleShot;
var config float						MaxTimeBetweenFireSMGSingleShot;
var config float						MinTimeBetweenFireSMGBurst;
var config float						MaxTimeBetweenFireSMGBurst;
var config float						MinTimeBetweenFireSMGFullAuto;
var config float						MaxTimeBetweenFireSMGFullAuto;

var config float						MinTimeBetweenFireMGSingleShot;
var config float						MaxTimeBetweenFireMGSingleShot;
var config float						MinTimeBetweenFireMGFullBurst;
var config float						MaxTimeBetweenFireMGFullBurst;
var config float						MinTimeBetweenFireMGFullAuto;
var config float						MaxTimeBetweenFireMGFullAuto;

var config float						MinTimeBetweenFireShotgun;
var config float						MaxTimeBetweenFireShotgun;

var private float						EndTimeToStopFiringFullAuto;

var config array<name>					TurnAwayAnimationHG;
var config array<name>					TurnAwayAnimationSG;
var config array<name>					TurnAwayAnimationMG;
var config array<name>					TurnAwayAnimationSMG;
var config array<name>					TurnAwayAnimationPB;

var protected ArchetypeInstance         ArchetypeInstance;

var protected bool						bUsesAwarenessForPathfindingCost;

var private bool                        bUsesCoverForPathfindingCost;
var private array<Pawn>                 OtherPawnsToFavorCoveredPathFrom;
const kAIPathCostNotInCover = 10000.0;
const kAIPathCostInLowCover =  1000.0;
const kAIPathCostInCover    =     0.0;

var protected Actor						CurrentWeaponTarget;
var private vector						CurrentWeaponTargetLocation;
var private float						NextCanHitWeaponTraceToggleTime;
var private bool						bCanHitUsesWeaponTrace;

var private vector						vGrenadeTargetLocation;
var private AIThrowSide					ThrowSide;

var private bool                        bHasBeenReportedToTOC;
var private name                        SpawnedFromName;

var protected CommanderGoal				Commander;
var protected SpeechManagerGoal			SpeechManager;

var private vector						LastVelocity;

//LatentAITriggerEffectEvent() support

var private IGSoundEffectsSubsystem.SoundInstance LatentSound;
var private bool MoveMouthDuringEffect;

var private array<StaircaseAimVolume> TouchingStaircaseAimVolumes;

// LockAim will disable any subsequent calls to AimAtPoint, AimAtActor, and
// AimToRotation. These calls will only have effect after UnlockAim is called.
// @HACK: This locking/unlocking mechanism should be replaced by a more robust
// priority-based system, similar to how ISwatAI::SetUpperBodyAnimBehavior
// works.
var private bool bIsAimLocked;

var private bool bDebugPathLines;

const kMinCanHitWeaponTraceToggleTime = 1.0;
const kMaxCanHitWeaponTraceToggleTime = 3.0;

const kPalmOffsetFromShoulder = 45.0;

const MaxAIWaitForEffectEventToFinish = 10.0;

//these variables used to manage effect event termination criterion
var private Name CurrentEffectEventName;
var private int CurrentSeed;
var private bool bEffectEventStillPlaying;
var private bool bDebugSensor;

///////////////////////////////////////////////////////////////////////////////

replication
{
    reliable if ( Role == ROLE_Authority )
        SpawnedFromName, bHasBeenReportedToTOC, bIsIncapacitated, bIsCompliant;
}


///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Initialization Events

simulated event PreBeginPlay()
{
    // If EnableDevTools=true in [Engine.GameEngine] in Swat4.ini, this will
    // be on by default.
    logAI = Level.GetEngine().EnableDevTools;

    Super.PreBeginPlay();

    // * SERVER ONLY
    // Find our anchor - we must find one
    if ( Level.NetMode != NM_Client )
        FindAnchor(true);
}

simulated event PostBeginPlay()
{
	//log(Name $ " PostBeginPlay!");

    Super.PostBeginPlay();

    // * SERVER ONLY
    if ( Level.NetMode != NM_Client )
    {
        // Setup Vision Bone
        SetupVisionBone();

        // Create Tyrion Resources
        CreateTyrionResources();

        InitKnowledge();
        InitCoverFinder();
    }

    // * SERVER & CLIENT
	InitAimPoses();

	// just set aim urgency to fast for now
	SetAimUrgency(false);

    assertWithDescription(((Level.NetMode == NM_Client) || (Controller != None)), "AI '"$self$"' has no controller after PostBeginPlay!");
    //Log("AI '"$self$"' using controller: "$Controller);
}

private simulated function InitAimPoses()
{
	// setup the low ready
	SetLowReady(CanPawnUseLowReady());
}

simulated event Destroyed()
{
    Super.Destroyed();

    // * SERVER ONLY
    if ( Level.NetMode != NM_Client )
    {
        TermKnowledge();
        CleanupTyrion();
        CleanupSensing();
    }
}

// called after the character AI is created but before it is initialized
function CharacterAICreated()
{
    // Will be called on server only.

    // Create Low Level Sensing Notifiers
    CreateVisionNotifier();
    CreateHearingNotifier();
}

private function CleanupTyrion()
{
	CleanupClassGoals();

	characterAI.cleanup();
	movementAI.cleanup();
	weaponAI.cleanup();

	characterAI.deleteSensors();
	movementAI.deleteSensors();
	weaponAI.deleteSensors();

	characterAI.deleteRemovedActions();
	movementAI.deleteRemovedActions();
	weaponAI.deleteRemovedActions();
}

// call down the chain for class-specific goals
protected function CleanupClassGoals()
{
	if (Commander != None)
	{
		Commander.Release();
		Commander = None;
	}

	if (SpeechManager != None)
	{
		SpeechManager.Release();
		SpeechManager = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Private Initialization Functions

// Sets the EyeBoneIndex to the correct bone index for the bone set in EyeBoneName
native function SetupVisionBone();

// Note that these have to be created before Pawn::PostBeginPlay
private function CreateTyrionResources()
{
    ConstructCharacterAI();
    ConstructMovementAI();
    ConstructWeaponAI();
}

// you should call down the chain with this function
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterAI != None);

    // Create Swat specific abilities
	characterResource.addAbility(new class'SwatAICommon.TakeCoverAction');
	characterResource.addAbility(new class'SwatAICommon.MoveToAction');				// this could be officer only, but other types might want to use it
	characterResource.addAbility(new class'SwatAICommon.IncapacitatedAction');
	characterResource.addAbility(new class'SwatAICommon.ReactToBeingShotAction');

	SetupCommanderGoal();
	SetupSpeechManagerGoal();

    // Create all of the idling abilities, both procedural and data (animator) driven
    SetupIdling();
}

private function SetupCommanderGoal()
{
	Commander = new class'CommanderGoal'(AI_Resource(characterAI));
	assert(Commander != None);
	Commander.AddRef();

	Commander.postGoal(None);
}

private function SetupSpeechManagerGoal()
{
	SpeechManager = new class'SpeechManagerGoal'(AI_Resource(characterAI));
	assert(SpeechManager != None);
	SpeechManager.AddRef();

	SpeechManager.postGoal(None);
}

protected function ConstructMovementAI()
{
    local AI_Resource movementResource;
    movementResource = AI_Resource(movementAI);
    assert(movementResource != none);

    // Create Tyrion abilities
    movementResource.addAbility(new class'Tyrion.AI_DummyMovement');

    // Create Swat specific abilities
	movementResource.addAbility(new class'SwatAICommon.MoveToDoorAction');
	movementResource.addAbility(new class'SwatAICommon.OpenDoorAction');
	movementResource.addAbility(new class'SwatAICommon.CloseDoorAction');
    movementResource.addAbility(new class'SwatAICommon.MoveToOpponentAction');
    movementResource.addAbility(new class'SwatAICommon.MoveToActorAction');
	movementResource.addAbility(new class'SwatAICommon.MoveToLocationAction');
    movementResource.addAbility(new class'SwatAICommon.RotateTowardActorAction');
    movementResource.addAbility(new class'SwatAICommon.RotateTowardPointAction');
	movementResource.addAbility(new class'SwatAICommon.RotateTowardRotationAction');
}

protected function ConstructWeaponAI()
{
    local AI_Resource weaponResource;
    weaponResource = AI_Resource(weaponAI);
    assert(weaponResource != None);

    // Create Tyrion abilities
    weaponResource.addAbility(new class'Tyrion.AI_DummyWeapon');

    // Create Swat specific abilities
    weaponResource.addAbility(new class'SwatAICommon.AimAroundAction');
    weaponResource.addAbility(new class'SwatAICommon.AimBetweenPointsAction');
    weaponResource.addAbility(new class'SwatAICommon.AttackTargetAction');
	weaponResource.addAbility(new class'SwatAICommon.AimAtTargetAction');
	weaponResource.addAbility(new class'SwatAICommon.AimAtPointAction');
	weaponResource.addAbility(new class'SwatAICommon.IdleAimAroundAction');
}

private function CleanupSensing()
{
	if (Vision != None)
	{
		Vision.CleanupVisionNotifier();
		Vision.Release();
		Vision = None;
	}

	if (Hearing != None)
	{
		Hearing.Release();
		Hearing = None;
	}
}

private function CreateVisionNotifier()
{
    Vision = new(self) class'VisionNotifier';
    assert(Vision != None);
	Vision.AddRef();

    Vision.InitializeVisionNotifier(self);
}

private function CreateHearingNotifier()
{
	Hearing = new(self) class'HearingNotifier';
	assert(Hearing != None);
	Hearing.AddRef();

	Hearing.InitializeHearingNotifier(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// Engine notifications

event EndCrouch(float HeightAdjust)
{
	Super.EndCrouch(HeightAdjust);

	GetCommanderAction().ResetIdling();
}

event StartCrouch(float HeightAdjust)
{
	Super.StartCrouch(HeightAdjust);

	GetCommanderAction().ResetIdling();
}

simulated function OnActiveItemEquipped()
{
	Super.OnActiveItemEquipped();

//	log("active item: " $ GetActiveItem() $ " equipped");

    if ( Level.NetMode != NM_Client )
        GetCommanderAction().ResetIdling();
}

///////////////////////////////////////////////////////////////////////////////
//
// Idling Functions

private function SetupIdling()
{
    local IdleGoal IdleGoal;

    // create and post the Idle goal -- should be done before adding any Idle Action
    IdleGoal = new class'SwatAICommon.IdleGoal'(AI_CharacterResource(CharacterAI));
    assert(IdleGoal != None);

    IdleGoal.postGoal( None );

    // now, add all of the necessary Idle Actions to our abilites
    AddIdleActions();
}


// CanUseIdle -
// * We return true if we can use the Idle  at any point, this only does a type check based on the Pawn's class
//   and the Enum specified in the IdleDefinition
// * We return false if the Pawn class is not the correct type
private function bool CanUseIdle(IdleDefinition Idle)
{
    if (Idle.IdleCharacterType == AllTypesIdle)	// all types actually just refers to swat ai characters (hostages or enemies)
    {
        return (ClassIsChildOf(Class, class'SwatAICharacter'));
    }
    else if (Idle.IdleCharacterType == OnlyWeaponUsersIdle)
    {
        return (ClassIsChildOf(Class, class'SwatEnemy') || ClassIsChildOf(Class, class'SwatOfficer'));
    }
    else if (Idle.IdleCharacterType == EnemyIdle)
    {
        return ClassIsChildOf(Class, class'SwatEnemy');
    }
    else if (Idle.IdleCharacterType == OfficerIdle)
    {
        return ClassIsChildOf(Class, class'SwatOfficer');
    }
    else if (Idle.IdleCharacterType == HostageIdle)
    {
        return ClassIsChildOf(Class, class'SwatHostage');
    }
    else
    {
        // didn't find one, this is bad!
        assert(false);
        return false;
    }
}

private function AddIdleActions()
{
    local IdleActionsList IdleActionsList;
    local IdleDefinition DefinitionIter;
    local AnimatorIdleAction NewAnimatorIdleAction;
    local ProceduralIdleAction NewProceduralIdleAction;
    local string ProceduralIdleActionClassName;
    local class<ProceduralIdleAction> ProceduralIdleActionClass;
    local int i;

    IdleActionsList = SwatAIRepository(Level.AIRepo).GetIdleActions();

//    log("IdleActionsList.AnimatorIdleDefinitions.Length is "@IdleActionsList.AnimatorIdleDefinitions.Length);

    // first do the animator defined idles
    for(i=0; i<IdleActionsList.AnimatorIdleDefinitions.Length; ++i)
    {
        DefinitionIter = IdleActionsList.AnimatorIdleDefinitions[i];

		assertWithDescription((AnimatorIdleDefinition(DefinitionIter).AnimationName != ''), "DefinitionIter: " $ DefinitionIter $ " has no AnimationName ! ");

        if (CanUseIdle(DefinitionIter))
        {
            // create the new action and push it onto the character resource
            NewAnimatorIdleAction = new class'SwatAICommon.AnimatorIdleAction'(DefinitionIter);
            assert(NewAnimatorIdleAction != None);

            CharacterAI.addAbility(NewAnimatorIdleAction);
        }
    }

    // now do the procedural defined idles
    for(i=0; i<IdleActionsList.ProceduralIdleDefinitions.Length; ++i)
    {
        DefinitionIter = IdleActionsList.ProceduralIdleDefinitions[i];

        if (CanUseIdle(DefinitionIter))
        {
            ProceduralIdleActionClassName = "SwatAICommon." $ ProceduralIdleDefinition(DefinitionIter).ProceduralClassName;
            ProceduralIdleActionClass     = class<ProceduralIdleAction>(DynamicLoadObject(ProceduralIdleActionClassName,class'Class'));
            assertWithDescription((ProceduralIdleActionClass != None), "Could not find procedural idle action class named: "@ProceduralIdleActionClassName);

            // create the new action and push it onto the character resource
            NewProceduralIdleAction = new ProceduralIdleActionClass(DefinitionIter);
            assert(NewProceduralIdleAction != None);

            CharacterAI.addAbility(NewProceduralIdleAction);
        }
    }
}

// Sets the IdleCategory variable, which lets the Idle behavior know we're only
// interested in a particular type of idles
// the value passed in can be '' (that's why there's no asserts)
function SetIdleCategory(name inIdleCategory)
{
	local bool bResetIdling;

	if (logTyrion)
		log("SetIdleCategory changed to: " $ inIdleCategory);

	// only reset idling if the idle category changes
	if (IdleCategory != inIdleCategory)
	{
		bResetIdling = true;
	}

	IdleCategory = inIdleCategory;

	// reset any idling going on, if we've started
	if (bResetIdling && (Commander != None) && (Commander.achievingAction != None))
	{
		GetCommanderAction().ResetIdling();
	}
}

function name GetIdleCategory()
{
	return IdleCategory;
}

///////////////////////////////////////////////////////////////////////////////
//
// Low-Level Vision Implementation

// Register to be notified when we see / no longer see a Pawn
function RegisterVisionNotification(IVisionNotification Registrant)
{
    Vision.RegisterVisionNotification(Registrant);
}

function UnregisterVisionNotification(IVisionNotification Registrant)
{
    Vision.UnregisterVisionNotification(Registrant);
}

function bool IsVisible(Pawn TestPawn)
{
	return Vision.IsVisible(TestPawn);
}

native function vector GetViewDirection();
native function vector GetViewPoint();

// returns true if we're in the same or adjacent zone as one of the officers,
//  or if we've been rendered recently
// otherwise returns false
native function bool IsRelevantToPlayerOrOfficers();

// is this AI in view of any officers?
function bool IsUnobservedByOfficers()
{
	local ElementSquadInfo Element;
	local int i;

	if (PlayerCanSeeMe())
		return false;

	Element = SwatAIRepository(Level.AIRepo).GetElementSquad();

	// make it so we see the player
	for(i=0; i<Element.Pawns.Length; ++i)
	{
		if (SwatOfficer(Element.Pawns[i]).IsVisible(self))
			return false;
	}
	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Compliance / Restrained

function HandheldEquipment GetRestrainedHandcuffs()
{
	// overridden in subclass SwatAICharacter
	assert(false);
	return None;
}

function NotifyBecameCompliant()
{
	// set our collision to not block players or actors
	SetCollision(bCollideActors, false, false);

    DispatchMessage(new class'MessageAICharacterComplied'(Label));
}

///////////////////////////////////////////////////////////////////////////////
//
// Low-Level Hearing Implementation

// Register to be notified when we see / no longer see a Pawn
function RegisterHearingNotification(IHearingNotification Registrant)
{
    Hearing.RegisterHearingNotification(Registrant);
}

function UnregisterHearingNotification(IHearingNotification Registrant)
{
    Hearing.UnregisterHearingNotification(Registrant);
}

///////////////////////////////////////////////////////////////////////////////
//
// Movement Notifications

event NotifyStartedMoving();
event NotifyStoppedMoving();

///////////////////////////////////////////////////////////////////////////////
//
// Idling Weights

function bool IsIdleCurrent()
{
	return (Level.TimeSeconds == LastIdleUpdateTime);
}

function ChooseIdle()
{
	local BaseIdleAction IdleAction;
	local array<BaseIdleAction> UsableIdleActions;
	local float TotalIdleWeight, RandomValue, SummedWeight;
	local int i;
//	local bool bFoundIdle;

	TotalIdleWeight = 0.0;

	// go through each base idle action on the pawn and find the total weight
	//  as well as all the usable Idle Actions
	for(i=0; i<characterAI.abilities.length; ++i)
	{
		if (characterAI.abilities[i].IsA('BaseIdleAction'))
		{
			IdleAction = BaseIdleAction(characterAI.abilities[i]);

			// manually set the pawn because it is not set yet
			IdleAction.SetPawn(self);

			// reset any existing current idles
			IdleAction.SetCurrentIdle(false);

			if (IdleAction.CanUseIdleAction())
			{
				TotalIdleWeight += IdleAction.GetIdleWeight();
				UsableIdleActions[UsableIdleActions.Length] = IdleAction;
			}
		}
	}

	// now pick a random number based on the total weight
	RandomValue = FRand() * TotalIdleWeight;

//	if (logTyrion)
//		log(self@"Random Value is:"@RandomValue);

	// now go through the idle actions and find one the one that cooresponds to this random value
	for(i=0; i<UsableIdleActions.Length; ++i)
	{
		SummedWeight += UsableIdleActions[i].GetIdleWeight();

//		if (logTyrion)
//			log(self@"SummedWeight:"@SummedWeight@" UsableIdleActions[i]:"@UsableIdleActions[i].Name);

		// found our current idle, all done
		if (RandomValue < SummedWeight)
		{
			UsableIdleActions[i].SetCurrentIdle(true);
//			bFoundIdle = true;
			break;
		}
	}

//	assert(bFoundIdle);

	// set the idle update time
	LastIdleUpdateTime = Level.TimeSeconds;
}

///////////////////////////////////////////////////////////////////////////////
//
// Navigation

event float GetExtraCostForPoint(NavigationPoint Point)
{
	return GetAwarenessCostForPoint(Point);

	// Cover seems to cause oscillation problems in pathfinding -- see bug 1639
	// so cost based on cover is disabled for now [crombie]
//    return GetAwarenessCostForPoint(Point) + GetCoverCostForPoint(Point);
}

function EnableFavorLowThreatPath()
{
    bUsesAwarenessForPathfindingCost = true;
}

function DisableFavorLowThreatPath()
{
    bUsesAwarenessForPathfindingCost = false;
}

function float GetAwarenessCostForPoint(NavigationPoint Point)
{
    local AwarenessPoint ClosestAwarenessPoint;
    local AwarenessProxy.AwarenessKnowledge KnowledgeOfPoint;
    local float Cost;

    if (bUsesAwarenessForPathfindingCost)
    {
        ClosestAwarenessPoint = Point.GetClosestAwarenessPoint();
        if (ClosestAwarenessPoint != None)
        {
            KnowledgeOfPoint = GetAwareness().GetKnowledge(ClosestAwarenessPoint);
            Cost = KnowledgeOfPoint.Threat * 10000.0;
        }
    }

    /*
    if (Cost > 0.0)
    {
        log("cost for "@Point.Name@" is "@Cost@" Threat is:"@KnowledgeOfPoint.Threat@" Confidence is:"@KnowledgeOfPoint.Confidence);
    }
    */

    return Cost;
}

function float GetCoverCostForPoint(NavigationPoint Point)
{
    local AICoverFinder.AICoverResult CoverResult;
    local float Cost;

    // Only calculate cover cost for points in the same zone as our pawn
    if (bUsesCoverForPathfindingCost && Region.ZoneNumber == Point.Region.ZoneNumber)
    {
        CoverResult = AICoverFinder.IsLocationInCover(OtherPawnsToFavorCoveredPathFrom, Point.Location);
        switch (CoverResult.coverLocationInfo)
        {
            case kAICLI_NotInCover: Cost = kAIPathCostNotInCover; break;
            case kAICLI_InLowCover: Cost = kAIPathCostInLowCover; break;
            case kAICLI_InCover:    Cost = kAIPathCostInCover;    break;
        }
    }

    return Cost;
}

// subclasses should override
event PlayerBlockingPath();

///////////////////////////////////////

function EnableFavorCoveredPath(array<Pawn> otherPawnsToCoverFrom)
{
    bUsesCoverForPathfindingCost = true;
    OtherPawnsToFavorCoveredPathFrom = otherPawnsToCoverFrom;
}

///////////////////////////////////////

function DisableFavorCoveredPath()
{
    bUsesCoverForPathfindingCost = false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

function SetPendingDoor(Door inPendingDoor)
{
	assert(inPendingDoor != None);
	assert(inPendingDoor.IsA('SwatDoor'));

	PendingDoor = SwatDoor(inPendingDoor);
}

function ClearPendingDoor()
{
	PendingDoor = None;
}

// some AIs (enemies) can force locked doors to be open
// however by default SwatAIs cannot
function bool ShouldForceOpenLockedDoors()
{
	return false;
}

function InteractWithPendingDoor()
{
	if ((PendingDoor != None) && PendingDoor.CanInteract())
	{
		PendingDoor.Interact(self, ShouldForceOpenLockedDoors());
	}
}

function NotifyBlockingDoorClose(Door BlockedDoor)
{
	GetCommanderAction().NotifyBlockingDoorClose(BlockedDoor);
}

function NotifyBlockingDoorOpen(Door BlockedDoor)
{
	GetCommanderAction().NotifyBlockingDoorOpen(BlockedDoor);
}

///////////////////////////////////////////////////////////////////////////////
//
// Animation

// by default AIs play the full body hit animations
function bool ShouldPlayFullBodyHitAnimation()
{
	return true;
}

function SwapInCompliantAnimSet()
{
	AnimSwapInSet(kAnimationSetCompliant);
}

function SwapInRestrainedAnimSet()
{
	AnimSwapInSet(kAnimationSetRestrained);
}

// Flashbang Animations
function name GetFBReactionAnimation()
{
	local int RandomIndex;

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(FBRestrainedReactionAnimations.Length);
		return FBRestrainedReactionAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(FBCompliantReactionAnimations.Length);
		return FBCompliantReactionAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBCrouchingReactionAnimations.Length);
			return FBCrouchingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBCrouchingNoWeaponReactionAnimations.Length);
			return FBCrouchingNoWeaponReactionAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBStandingReactionAnimations.Length);
			return FBStandingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBStandingNoWeaponReactionAnimations.Length);
			return FBStandingNoWeaponReactionAnimations[RandomIndex];
		}
	}
}

function name GetFBAffectedAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(FBRestrainedAffectedAnimations.Length);
		return FBRestrainedAffectedAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(FBCompliantAffectedAnimations.Length);
		return FBCompliantAffectedAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBCrouchingAffectedAnimations.Length);
			return FBCrouchingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBCrouchingNoWeaponAffectedAnimations.Length);
			return FBCrouchingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBStandingAffectedAnimations.Length);
			return FBStandingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBStandingNoWeaponAffectedAnimations.Length);
			return FBStandingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
}

function name GetFBRecoveryAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(FBRestrainedRecoveryAnimations.Length);
		return FBRestrainedRecoveryAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(FBCompliantRecoveryAnimations.Length);
		return FBCompliantRecoveryAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBCrouchingRecoveryAnimations.Length);
			return FBCrouchingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBCrouchingNoWeaponRecoveryAnimations.Length);
			return FBCrouchingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(FBStandingRecoveryAnimations.Length);
			return FBStandingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(FBStandingNoWeaponRecoveryAnimations.Length);
			return FBStandingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
}

// Gassed animations
function name GetGasReactionAnimation()
{
	local int RandomIndex;

	// return a reaction based on whether we're restrained, compliant, crouching, or standing
	if (IsArrested())
	{
		RandomIndex = Rand(GasRestrainedReactionAnimations.Length);
		return GasRestrainedReactionAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(GasCompliantReactionAnimations.Length);
		return GasCompliantReactionAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasCrouchingReactionAnimations.Length);
			return GasCrouchingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasCrouchingNoWeaponReactionAnimations.Length);
			return GasCrouchingNoWeaponReactionAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasStandingReactionAnimations.Length);
			return GasStandingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasStandingNoWeaponReactionAnimations.Length);
			return GasStandingNoWeaponReactionAnimations[RandomIndex];
		}
	}
}

function name GetGasAffectedAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(GasRestrainedAffectedAnimations.Length);
		return GasRestrainedAffectedAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(GasCompliantAffectedAnimations.Length);
		return GasCompliantAffectedAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasCrouchingAffectedAnimations.Length);
			return GasCrouchingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasCrouchingNoWeaponAffectedAnimations.Length);
			return GasCrouchingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasStandingAffectedAnimations.Length);
			return GasStandingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasStandingNoWeaponAffectedAnimations.Length);
			return GasStandingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
}

function name GetGasRecoveryAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(GasRestrainedRecoveryAnimations.Length);
		return GasRestrainedRecoveryAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(GasCompliantRecoveryAnimations.Length);
		return GasCompliantRecoveryAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasCrouchingRecoveryAnimations.Length);
			return GasCrouchingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasCrouchingNoWeaponRecoveryAnimations.Length);
			return GasCrouchingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(GasStandingRecoveryAnimations.Length);
			return GasStandingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(GasStandingNoWeaponRecoveryAnimations.Length);
			return GasStandingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
}

// Stung animations
function name GetStungReactionAnimation()
{
	local int RandomIndex;

	// return a reaction based on whether we're restrained, compliant, crouching, or standing
	if (IsArrested())
	{
		RandomIndex = Rand(StungRestrainedReactionAnimations.Length);
		return StungRestrainedReactionAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(StungCompliantReactionAnimations.Length);
		return StungCompliantReactionAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungCrouchingReactionAnimations.Length);
			return StungCrouchingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungCrouchingNoWeaponReactionAnimations.Length);
			return StungCrouchingNoWeaponReactionAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungStandingReactionAnimations.Length);
			return StungStandingReactionAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungStandingNoWeaponReactionAnimations.Length);
			return StungStandingNoWeaponReactionAnimations[RandomIndex];
		}
	}
}

function name GetStungAffectedAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(StungRestrainedAffectedAnimations.Length);
		return StungRestrainedAffectedAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(StungCompliantAffectedAnimations.Length);
		return StungCompliantAffectedAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungCrouchingAffectedAnimations.Length);
			return StungCrouchingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungCrouchingNoWeaponAffectedAnimations.Length);
			return StungCrouchingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungStandingAffectedAnimations.Length);
			return StungStandingAffectedAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungStandingNoWeaponAffectedAnimations.Length);
			return StungStandingNoWeaponAffectedAnimations[RandomIndex];
		}
	}
}

function name GetStungRecoveryAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(StungRestrainedRecoveryAnimations.Length);
		return StungRestrainedRecoveryAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(StungCompliantRecoveryAnimations.Length);
		return StungCompliantRecoveryAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungCrouchingRecoveryAnimations.Length);
			return StungCrouchingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungCrouchingNoWeaponRecoveryAnimations.Length);
			return StungCrouchingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
	else
	{
		if (GetActiveItem() != None)
		{
			RandomIndex = Rand(StungStandingRecoveryAnimations.Length);
			return StungStandingRecoveryAnimations[RandomIndex];
		}
		else
		{
			RandomIndex = Rand(StungStandingNoWeaponRecoveryAnimations.Length);
			return StungStandingNoWeaponRecoveryAnimations[RandomIndex];
		}
	}
}

// Tased animations
function name GetTasedReactionAnimation()
{
	local int RandomIndex;

	// return a reaction based on whether we're restrained, compliant, crouching, or standing
	if (IsArrested())
	{
		RandomIndex = Rand(TasedRestrainedReactionAnimations.Length);
		return TasedRestrainedReactionAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(TasedCompliantReactionAnimations.Length);
		return TasedCompliantReactionAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		RandomIndex = Rand(TasedCrouchingReactionAnimations.Length);
		return TasedCrouchingReactionAnimations[RandomIndex];
	}
	else
	{
		RandomIndex = Rand(TasedStandingReactionAnimations.Length);
		return TasedStandingReactionAnimations[RandomIndex];
	}
}

function name GetTasedAffectedAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(TasedRestrainedAffectedAnimations.Length);
		return TasedRestrainedAffectedAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(TasedCompliantAffectedAnimations.Length);
		return TasedCompliantAffectedAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		RandomIndex = Rand(TasedCrouchingAffectedAnimations.Length);
		return TasedCrouchingAffectedAnimations[RandomIndex];
	}
	else
	{
		RandomIndex = Rand(TasedStandingAffectedAnimations.Length);
		return TasedStandingAffectedAnimations[RandomIndex];
	}
}

function name GetTasedRecoveryAnimation()
{
	local int RandomIndex;
	// TODO: if our arms are up, we play a different animation

	// return a reaction based on whether we're standing, restrained, or compliant
	if (IsArrested())
	{
		RandomIndex = Rand(TasedRestrainedRecoveryAnimations.Length);
		return TasedRestrainedRecoveryAnimations[RandomIndex];
	}
	else if (IsCompliant())
	{
		RandomIndex = Rand(TasedCompliantRecoveryAnimations.Length);
		return TasedCompliantRecoveryAnimations[RandomIndex];
	}
	else if (bIsCrouched)
	{
		RandomIndex = Rand(TasedCrouchingRecoveryAnimations.Length);
		return TasedCrouchingRecoveryAnimations[RandomIndex];
	}
	else
	{
		RandomIndex = Rand(TasedStandingRecoveryAnimations.Length);
		return TasedStandingRecoveryAnimations[RandomIndex];
	}
}

function name GetTurnAwayAnimation()
{
	if (GetActiveItem() != None)
	{
		if (GetActiveItem().IsA('MachineGun'))
		{
			return TurnAwayAnimationMG[Rand(TurnAwayAnimationMG.Length)];
		}
		else if (GetActiveItem().IsA('SubMachineGun'))
		{
			return TurnAwayAnimationSMG[Rand(TurnAwayAnimationSMG.Length)];
		}
		else if (GetActiveItem().IsA('Shotgun'))
		{
			return TurnAwayAnimationSG[Rand(TurnAwayAnimationSG.Length)];
		}
		else if (GetActiveItem().IsA('CSBallLauncher'))
		{
			return TurnAwayAnimationPB[Rand(TurnAwayAnimationPB.Length)];
		}
		else
		{
			return TurnAwayAnimationHG[Rand(TurnAwayAnimationHG.Length)];
		}
	}
}

// Overridden from SwatPawn
simulated function EAnimationSet GetMovementAnimSet()
{
    // On the client, if the BeginArrested flag is set to true, swap in the
    // cuffed movement anim set. This hides a slight glitch between when the
    // special arresting animation ends, and the bIsArrested flag gets
    // replicated, where the animation starts to swap to a non-arrested pose.
    if (Level.NetMode == NM_Client && IsBeingArrestedNow())
    {
        return GetRestrainedAnimSet();
    }
    else
    {
        return Super.GetMovementAnimSet();
    }
}

// If the AI has no active item, don't use the kAnimationSetInjuredCrouching set, since it
// sasumed a gun and we won't be using upper body aiming.
simulated function EAnimationSet GetCrouchingInjuredAnimSet() { if (GetActiveItem() == None) return kAnimationSetCrouching; else return Super.GetCrouchingInjuredAnimSet(); }

simulated function EAnimationSet GetFlashbangedAnimSet()    { if (!ShouldUseCuffedAnims()) return kAnimationSetAIFlashbanged;   else return kAnimationSetFlashbangedCuffed; }
simulated function EAnimationSet GetGassedAnimSet()         { if (!ShouldUseCuffedAnims()) return kAnimationSetAIGassed;        else return kAnimationSetGassedCuffed; }
simulated function EAnimationSet GetPepperSprayedAnimSet()  { if (!ShouldUseCuffedAnims()) return kAnimationSetAIPepperSprayed; else return kAnimationSetPepperSprayedCuffed; }
simulated function EAnimationSet GetStungAnimSet()          { if (!ShouldUseCuffedAnims()) return kAnimationSetAIStung;         else return kAnimationSetStungCuffed; }
simulated function EAnimationSet GetTasedAnimSet()          { if (!ShouldUseCuffedAnims()) return kAnimationSetAITased;         else return kAnimationSetTasedCuffed; }


///////////////////////////////////////////////////////////////////////////////
//
// Aiming

function AimAtPoint(vector Point)
{
    local bool bShouldSnapBaseToAim;

//	log(Name $ " told to aim at Point: " $ Point);
    if (!bIsAimLocked)
    {
        if ((AnimAimType != kAAT_Point || AnimAimPoint != Point) &&
            GetUpperBodyAnimBehavior() == kUBAB_FullBody)
        {
            bShouldSnapBaseToAim = true;
        }

        AnimSetAimPoint(Point);

	    if (bShouldSnapBaseToAim)
        {
		    AnimSnapBaseToAim();
        }
    }
}

function AimAtActor(Actor Target)
{
    local bool bShouldSnapBaseToAim;

    if (Target != None && !bIsAimLocked)
    {
        if ((AnimAimType != kAAT_Actor || AnimAimActor != Target) &&
            GetUpperBodyAnimBehavior() == kUBAB_FullBody)
        {
            bShouldSnapBaseToAim = true;
        }

	    AnimSetAimActor(Target);

	    if (bShouldSnapBaseToAim)
        {
		    AnimSnapBaseToAim();
        }
    }
}

function AimToRotation(rotator DesiredRotation)
{
    local bool bShouldSnapBaseToAim;

//	log(Name $ " told to aim to rotation: " $ DesiredRotation $ " bIsAimLocked: " $ bIsAimLocked);
    if (!bIsAimLocked)
    {
        if ((AnimAimType != kAAT_Rotation || AnimAimRotator != DesiredRotation) &&
            GetUpperBodyAnimBehavior() == kUBAB_FullBody)
        {
            bShouldSnapBaseToAim = true;
        }

    	AnimSetAimRotation(DesiredRotation);

	    if (bShouldSnapBaseToAim)
        {
		    AnimSnapBaseToAim();
        }
    }
}

// LockAim will disable any subsequent calls to AimAtPoint, AimAtActor, and
// AimToRotation. These calls will only have effect after UnlockAim is called.
// @HACK: This locking/unlocking mechanism should be replaced by a more robust
// priority-based system, similar to how ISwatAI::SetUpperBodyAnimBehavior
// works.
function LockAim()
{
    bIsAimLocked = true;
}

function UnlockAim()
{
    bIsAimLocked = false;
}

function bool GetLockAim()
{
	return bIsAimLocked;
}

function SetLockAim(bool newValue)
{
	bIsAimLocked = newValue;
}

function bool CanProcedurallyAnimateUpperBody()
{
    // By default, check the usable weapon to determine if the pawn can procedurally influence the upper body
    return HasUsableWeapon();
}

// @RENAME
function DisableAim()
{
	AnimAimUnset();
}

// most of the AI's weapons fire at the target directly - this function should return true when that's not the case
function bool FireWhereAiming()
{
	return false;
}

///////////////////////////////////////////////////////////////////////////////

function SetUpperBodyAnimBehavior(EUpperBodyAnimBehavior behavior, optional EUpperBodyAnimBehaviorClientId clientId)
{
    local EUpperBodyAnimBehavior previousDominantBehavior;
    local EUpperBodyAnimBehavior newDominantBehavior;
//	log(Name $ " SetUpperBodyAnimBehavior - behavior: " $ behavior $ " clientId: " $ clientId);

	if (! bDeleteMe)
	{
        previousDominantBehavior = GetDominantUpperBodyAnimBehavior();
		SetUpperBodyAnimBehaviorForClient(behavior, clientId);
        newDominantBehavior      = GetDominantUpperBodyAnimBehavior();

		SetUpperBodyAnimBehaviorPawnState(newDominantBehavior, previousDominantBehavior);
	}
}

function UnsetUpperBodyAnimBehavior(optional EUpperBodyAnimBehaviorClientId clientId)
{
    local EUpperBodyAnimBehavior previousDominantBehavior;
    local EUpperBodyAnimBehavior newDominantBehavior;
//	log(Name $ " UnsetUpperBodyAnimBehaviorForClient - clientId: " $ clientId);

	if (! bDeleteMe)
	{
        previousDominantBehavior = GetDominantUpperBodyAnimBehavior();
		UnsetUpperBodyAnimBehaviorForClient(clientId);
         newDominantBehavior      = GetDominantUpperBodyAnimBehavior();

		SetUpperBodyAnimBehaviorPawnState(newDominantBehavior, previousDominantBehavior);
    }
}

function EUpperBodyAnimBehavior GetUpperBodyAnimBehavior()
{
    if (AnimGetFlag(kAF_Aim) == false)
    {
        return kUBAB_FullBody;
    }
    else if (IsLowReady())
    {
        return kUBAB_LowReady;
    }
    else
    {
        return kUBAB_AimWeapon;
    }
}

function EUpperBodyAnimBehavior GetMovementUpperBodyAimBehavior()
{
	// by default we use full body (SwatOfficer overrides this)
	return kUBAB_FullBody;
}

///////////////////
// Upper body anim behavior helper functions

private function SetUpperBodyAnimBehaviorPawnState(EUpperBodyAnimBehavior newDominantBehavior, EUpperBodyAnimBehavior previousDominantBehavior)
{
    local bool bCanProcedurallyAnimateUpperBody;
    local bool bCanPawnUseLowReady;
	local bool bWasUsingAim;

    bCanProcedurallyAnimateUpperBody = CanProcedurallyAnimateUpperBody();
    bCanPawnUseLowReady = CanPawnUseLowReady();

    // If the pawn can't procedurally animate the upper body, slam the
    // newDominantBehavior to kUBAB_FullBody.
    if (!bCanProcedurallyAnimateUpperBody)
    {
         newDominantBehavior = kUBAB_FullBody;
    }
    // Otherwise, we can procedurally animate the upper body. If the caller
    // wanted to use the kUBAB_LowReady, but the pawn can't do it, slam the
    // newDominantBehavior to kUBAB_AimWeapon.
    else if (newDominantBehavior == kUBAB_LowReady && !bCanPawnUseLowReady)
    {
        newDominantBehavior = kUBAB_AimWeapon;
    }

	bWasUsingAim = AnimGetFlag(kAF_Aim);

    switch (newDominantBehavior)
    {
        case kUBAB_FullBody:
            AnimSetFlag(kAF_Aim, false);

            if (previousDominantBehavior != kUBAB_FullBody)
            {
			    // snap our base to our aim position
			    AnimSnapBaseToAim();
            }
        break;

        case kUBAB_LowReady:
            SetLowReady(true);
            AnimSetFlag(kAF_Aim, true);
        break;

        case kUBAB_AimWeapon:
            SetLowReady(false);
            AnimSetFlag(kAF_Aim, true);

			if (! bWasUsingAim)
			{
				GetCommanderAction().ResetIdling();
			}
        break;
    }
}

private function SetUpperBodyAnimBehaviorForClient(EUpperBodyAnimBehavior behavior, EUpperBodyAnimBehaviorClientId clientId)
{
    local int i;
    local int numEntries;

    // UpperBodyAnimBehaviorEntries is ordered from highest to lowest priority.
    // Find the index for this client's entry.
    numEntries = UpperBodyAnimBehaviorEntries.length;
    for (i = 0; i < numEntries; i++)
    {
        if (UpperBodyAnimBehaviorEntries[i].clientId <= clientId)
        {
            break;
        }
    }

    // If we stopped on a valid entry, and its client id is the one we're
    // setting, update that existing entry.
    if (i < numEntries && UpperBodyAnimBehaviorEntries[i].clientId == clientId)
        {
            UpperBodyAnimBehaviorEntries[i].behavior = behavior;
        }
    // Otherwise, insert a new entry
    else
    {
        UpperBodyAnimBehaviorEntries.Insert(i, 1);
        UpperBodyAnimBehaviorEntries[i].behavior = behavior;
        UpperBodyAnimBehaviorEntries[i].clientId = clientId;
    }
}

private function UnsetUpperBodyAnimBehaviorForClient(EUpperBodyAnimBehaviorClientId clientId)
{
    local int i;
    local int numEntries;

    // Find the entry for this client, and remove it
    numEntries = UpperBodyAnimBehaviorEntries.length;
    for (i = 0; i < numEntries; i++)
    {
        if (UpperBodyAnimBehaviorEntries[i].clientId == clientId)
        {
            UpperBodyAnimBehaviorEntries.Remove(i, 1);
            return;
        }
    }
}

private function EUpperBodyAnimBehavior GetDominantUpperBodyAnimBehavior()
{
    // UpperBodyAnimBehaviorEntries is ordered from highest to lowest priority
    if (UpperBodyAnimBehaviorEntries.length > 0)
    {
        return UpperBodyAnimBehaviorEntries[0].behavior;
    }
    // Default to fullbody
    else
        {
        return kUBAB_FullBody;
        }
    }

///////////////////////////////////////////////////////////////////////////////

// Aim Test
function bool AnimIsWeaponAimSet()
{
    return AnimIsAimSet();
}

function rotator GetAimOrientation()
{
	return AnimGetAimRotation();
}

// Notifications from staircase aiming volumes
function OnTouchedStaircaseAimVolume(StaircaseAimVolume StaircaseAimVolume)
{
    local int i;
    local AimAroundAction aimAroundAction;

    // Uniquely add volume to member array
    for (i = 0; i < TouchingStaircaseAimVolumes.length; i++)
    {
        if (TouchingStaircaseAimVolumes[i] == StaircaseAimVolume)
        {
            break;
        }
    }

    if (i == TouchingStaircaseAimVolumes.length)
    {
        TouchingStaircaseAimVolumes[TouchingStaircaseAimVolumes.length] = StaircaseAimVolume;

        // Notify the aim around action
        aimAroundAction = GetAimAroundAction();
        if (aimAroundAction != None)
        {
            aimAroundAction.ForceReevaluation();
        }
    }
}

function OnUntouchedStaircaseAimVolume(StaircaseAimVolume StaircaseAimVolume)
{
    local int i;
    local AimAroundAction aimAroundAction;

    // Remove volume from member array
    for (i = 0; i < TouchingStaircaseAimVolumes.length; i++)
    {
        if (TouchingStaircaseAimVolumes[i] == StaircaseAimVolume)
        {
            TouchingStaircaseAimVolumes.Remove(i, 1);

            // Notify the aim around action
            aimAroundAction = GetAimAroundAction();
            if (aimAroundAction != None)
            {
                aimAroundAction.ForceReevaluation();
            }

            break;
        }
    }
}

function int GetNumTouchingStaircaseAimVolumes()
{
    return TouchingStaircaseAimVolumes.length;
}

function StaircaseAimVolume GetTouchingStaircaseAimVolumeAtIndex(int index)
{
    assert(index >= 0 && index < TouchingStaircaseAimVolumes.length);
    return TouchingStaircaseAimVolumes[index];
}

function AimAroundAction GetAimAroundAction()
{
    local AI_Resource resource;
    local AimAroundAction aimAroundAction;
    local int i;

    if (WeaponAI != None)
    {
        resource = AI_Resource(WeaponAI);
        if (resource != None)
        {
            for (i = 0; i < resource.runningActions.length; i++)
            {
				aimAroundAction = AimAroundAction(resource.runningActions[i]);
                if (aimAroundAction != None)
                {
                    return aimAroundAction;
                }
            }
        }
    }

    return None;
}

///////////////////////////////////////////////////////////////////////////////
//
// Attacking

// Override from Pawn.uc
// Returns the rotation of the aiming bone
simulated function rotator AdjustAim(Ammunition FiredAmmunition, vector projStart, int aimerror)
{
	return AnimGetAimRotation();
}

// Get the aim rotation
simulated function Rotator GetAimRotation()
{
    local vector TargetLocation;
	local HandheldEquipment ActiveItem;

	ActiveItem = GetActiveItem();

	if (FireWhereAiming())
	{
		return AnimGetAimRotation();
	}
    else if (CurrentWeaponTarget != None)
    {
        TargetLocation = CurrentWeaponTarget.GetFireLocation(ActiveItem);
    }
    else
    {
        TargetLocation = CurrentWeaponTargetLocation;
    }

	// if it's a cs ball launcher, we need to take gravity into account
	if ((ActiveItem != None) && ActiveItem.IsA('CSBallLauncher'))
	{
		return GetCSBallLauncherAimRotation(TargetLocation);
	}
	else
	{
		return rotator(TargetLocation - GetAimOrigin());
	}
}

simulated private function Rotator GetCSBallLauncherAimRotation(vector TargetLocation)
{
	local float Distance, Grav, ProjectileSpeed, Angle;
	local vector AimOrigin, OriginalAim;
	local HandheldEquipment ActiveItem;
	local Rotator PaintballAimRotation;

	ActiveItem = GetActiveItem();
	assert(ActiveItem.IsA('CSBallLauncher'));

	AimOrigin = GetAimOrigin();
	Distance  = VSize(TargetLocation - AimOrigin);

	// we need an angle (for perfect aiming, of course)
    // R = (vi^2 / g) * (sin 2 theta)
    // (R * g) / vi^2 = sin 2 theta
    // theta = (asin((R*g) / vi^2) / 2)
    Grav              = - PhysicsVolume.Gravity.Z * 0.5;            // multiplied by 0.5 cause unreal's use of gravity in UnPhysic.cpp is real strange
	ProjectileSpeed   = FiredWeapon(ActiveItem).MuzzleVelocity;
	Angle             = asin((Distance * Grav) / (ProjectileSpeed * ProjectileSpeed)) / 2.0;

	OriginalAim       = TargetLocation - AimOrigin;

//	log("ProjectileSpeed:"@ProjectileSpeed@" Grav:"@Grav@" Angle:"@Angle);

	PaintballAimRotation = rotator(OriginalAim);
	PaintballAimRotation.Pitch += RADIANS_TO_TWOBYTE * Angle;

	return PaintballAimRotation;
}

//simulated native function vector GetAimOrigin();
//
//This function is supposed to get the Aim Origin for the weapons so that pawns
//can aim correctly. However, there is something wrong in it because it crashes
//at times. And we can't check what Irrational did because it is native. So I'm
//rewriting this to make it work.

simulated function vector GetAimOrigin()
{
	return Location + EyePosition();
}

simulated function vector EyePosition()
{
    local vector vEyeHeight;
	local FiredWeapon ActiveItem;

	ActiveItem = FiredWeapon(GetActiveItem());

    if(bIsCrouched)
		{
			if(ActiveItem.bAimAtHead)
			vEyeHeight.Z = 40;
			else
			vEyeHeight.Z = 0;
		}
	else
		{
			if(ActiveItem.bAimAtHead)
			vEyeHeight.Z = 32;
			else
			vEyeHeight.Z = 0;
		}

	return vEyeHeight;
}

simulated function vector GetEyeLocation()
{
    local Coords  cTarget;
    local vector  vTarget;

    cTarget = GetBoneCoords('Bone01Eye');
    vTarget = cTarget.Origin;

	return vTarget;
}

function SetAimUrgency(bool Fast)
{
    local EAnimAimRotationUrgency Urgency;

    if (Fast)
    {
        Urgency = kAARU_Fast;
    }
    else
    {
        Urgency = kAARU_Normal;
    }

    AnimSetAnimAimRotationUrgency(Urgency);
}

native event bool CanHitTargetAt(Actor Target, vector AILocation);

//
//native event bool CanHit(Actor Target);
//
// Whatever Irrational did with this function, we don't know because it's native...
// However, it's not correct because SWAT will very frequently not hit their target.

simulated function SEFDebugSensor()
{
  bDebugSensor = !bDebugSensor;
}

event bool CanHit(Actor Target)
{
  local FiredWeapon TheWeapon;
  local bool Value;
  local vector MuzzleLocation, EndTrace, StartTrace;
  local rotator MuzzleDirection;

  TheWeapon = FiredWeapon(GetActiveItem());

  /*
  // The below code seems to be janky, but what the game actually tends to use for aiming at things.
  // Maybe we should be using stuff like GetAimOrigin() to get the actual position?
  if (CurrentWeaponTarget != None)
  {
      EndTrace = CurrentWeaponTarget.GetFireLocation(TheWeapon);
  }
  else if(!TheWeapon.bIsLessLethal)
  {
      EndTrace = CurrentWeaponTargetLocation;
  }
  else
  {
    EndTrace = Target.Location;
  }
  */

  EndTrace = Target.Location;

  if(TheWeapon == None || !TheWeapon.WillHitIntendedTarget(Target, !TheWeapon.bIsLessLethal, EndTrace))
  {
    Value = false;
  }
  else
  {
    Value = true;
  }

  if(bDebugSensor)
  {
    TheWeapon.GetPerfectFireStart(MuzzleLocation, MuzzleDirection);
	StartTrace = GetEyeLocation();
    EndTrace = Target.Location;

    if(Value)
    {
      Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(0,255,0), 3.0f);
    }
    else
    {
      Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(255,0,0), 3.0f);
    }
  }

  return Value;
}

function bool HasUsableWeapon()
{
	return false;
}

protected function Actor GetWeaponTarget()
{
    return CurrentWeaponTarget;
}

native function SetWeaponTarget(Actor Target);

event SetWeaponTargetLocation(vector TargetLocation)
{
	CurrentWeaponTarget = None;
    CurrentWeaponTargetLocation = TargetLocation;
}

// by default we try to use the burst mode first,
// then the single shot mode,
// and then, if we have to, the auto fire mode
function FireMode GetDefaultAIFireModeForWeapon(FiredWeapon Weapon)
{
	assert(Weapon != None);

	if(Weapon.Owner.IsA('SwatEnemy')) {
    // the thing holding me is a suspect
		if (Weapon.HasFireMode(FireMode_Burst))
		{
			return FireMode_Burst;
		}
		else if (Weapon.HasFireMode(FireMode_Auto))
		{
			return FireMode_Auto;
		}
		else if (Weapon.HasFireMode(FireMode_Single) || Weapon.HasFireMode(FireMode_SingleTaser))
		{
			return FireMode_Single;
		}
		else
		{
 		// sanity check!
			assert(Weapon.HasFireMode(FireMode_DoubleTaser));

			return FireMode_DoubleTaser;
		}
	}
	else if (Weapon.HasFireMode(FireMode_Burst))
	{
		return FireMode_Burst;
	}
	else if (Weapon.HasFireMode(FireMode_Single))
	{
		return FireMode_Single;
	}
    else if (Weapon.HasFireMode(FireMode_SingleTaser))
    {
        return FireMode_SingleTaser;
    }
	else if (Weapon.HasFireMode(FireMode_Auto))
	{
		return FireMode_Auto;
	}
	else
	{
		// sanity check!
		assert(Weapon.HasFireMode(FireMode_DoubleTaser));

		return FireMode_DoubleTaser;
	}
}

function float GetTimeToWaitBeforeFiring()
{
  return 0.0; // For most NPCs this is 0 - only implemented in SwatEnemy
}

// return weapon specific time values for this AI
function float GetTimeToWaitBetweenFiring(FiredWeapon Weapon)
{
	local FireMode CurrentFireMode;

	CurrentFireMode = Weapon.GetCurrentFireMode();

	if (Weapon.IsA('Handgun'))
	{
		return RandRange(MinTimeBetweenFireHG, MaxTimeBetweenFireHG);
	}
	else if (Weapon.IsA('SubMachineGun'))
	{
		if (CurrentFireMode == FireMode_Single)
		{
			return RandRange(MinTimeBetweenFireSMGSingleShot, MaxTimeBetweenFireSMGSingleShot);
		}
		else if (CurrentFireMode == FireMode_Burst)
		{
			return RandRange(MinTimeBetweenFireSMGBurst, MaxTimeBetweenFireSMGBurst);
		}
		else
		{
			return RandRange(MinTimeBetweenFireSMGFullAuto, MaxTimeBetweenFireSMGFullAuto);
		}
	}
	else if (Weapon.IsA('MachineGun'))
	{
		if (CurrentFireMode == FireMode_Single)
		{
			return RandRange(MinTimeBetweenFireMGSingleShot, MaxTimeBetweenFireMGSingleShot);
		}
		else if (CurrentFireMode == FireMode_Burst)
		{
			return RandRange(MinTimeBetweenFireMGFullBurst, MaxTimeBetweenFireMGFullBurst);
		}
		else
		{
			return RandRange(MinTimeBetweenFireMGFullAuto, MaxTimeBetweenFireMGFullAuto);
		}
	}
	else
	{
		return RandRange(MinTimeBetweenFireShotgun, MaxTimeBetweenFireShotgun);
	}
}

// must be overridden
protected function float GetLengthOfTimeToFireFullAuto() { assert(false); return 0.0; }

// sets the length of time to fire for
private function SetLengthOfTimeToFireFullAuto()
{
	EndTimeToStopFiringFullAuto = Level.TimeSeconds + GetLengthOfTimeToFireFullAuto();
	assert(EndTimeToStopFiringFullAuto >= Level.TimeSeconds);
}

private function WeaponDischargedAt(Pawn TargetPawn)
{
	// only update threat if the target is alive
	if (class'Pawn'.static.checkConscious(TargetPawn))
	{
		NotifyWeaponDischarged();

		if (TargetPawn.IsA('SwatAI'))
		{
			// notify the threat sensor action
			SwatCharacterResource(TargetPawn.characterAI).ThreatenedSensorAction.UpdateThreatFrom(self);
		}
	}
}

// allow subclasses to extend functionality
protected function NotifyWeaponDischarged();

// called whenever we use our active item
simulated function OnUsingBegan()
{
	local FiredWeapon CurrentWeapon;
	local Pawn CurrentPawnTarget;
	Super.OnUsingBegan();

	CurrentWeapon = FiredWeapon(GetActiveItem());
	if (CurrentWeapon != None)
	{
		CurrentPawnTarget = Pawn(CurrentWeaponTarget);
		if (CurrentPawnTarget != None)
		{
			WeaponDischargedAt(CurrentPawnTarget);
		}
	}
}

// set our end time (completely overridden from SwatPawn)
simulated function OnAutoFireStarted()
{
	bWantsToContinueAutoFiring = true;

	SetLengthOfTimeToFireFullAuto();
}

// stop auto firing if our time has come (completely overridden from SwatPawn)
simulated function bool WantsToContinueAutoFiring()
{
    return bWantsToContinueAutoFiring && (Level.TimeSeconds < EndTimeToStopFiringFullAuto) && CanHitCurrentTarget();
}

simulated private function bool CanHitCurrentTarget()
{
	if (CurrentWeaponTarget != None)
	{
		return CanHit(CurrentWeaponTarget);
	}
	else
	{
		return true;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Damage / Death

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
  local CharacterSpeechManagerAction SpeechManagerAction;
	log(Name $ " Died - IsIncapacitated: " $ IsIncapacitated() $ " ShouldBecomeIncapacitated: " $ ShouldBecomeIncapacitated());

  SpeechManagerAction = GetSpeechManagerAction();

	if (ShouldBecomeIncapacitated())
	{
		BecomeIncapacitated(,Killer.Pawn);
	}
	else
	{
		if (! IsIncapacitated() && SpeechManagerAction != None)
			GetSpeechManagerAction().TriggerDiedSpeech();

		// we are no longer incapacitated, we are dead!
		SetIncapacitated(false);

		// make sure our idle goal gets cleared out
		GetCommanderAction().RemoveGoalsToDie();

		Super.Died(Killer, damageType, HitLocation, HitMomentum);
	}
}

simulated protected function TriggerPawnDied(Controller Killer)
{
	// if we're not incapacitated, trigger the pawn died trigger
	// we have already triggered the incapacitated trigger by this point
	if (! IsIncapacitated())
	{
		if (Killer != None)
			SwatGameInfo(Level.Game).GameEvents.PawnDied.Triggered(self, Killer.Pawn, IsAThreat() && !IsCompliant() && !IsArrested());
		else
			SwatGameInfo(Level.Game).GameEvents.PawnDied.Triggered(self, None, IsAThreat() && !IsCompliant() && !IsArrested());
	}
}

function BecomeIncapacitated(optional name IncapaciatedIdleCategoryOverride, optional Pawn Incapacitator)
{
	// set our health to 1 if it's lower than 1 (barely alive)
	Health = Max(1, Health);

	if (! IsIncapacitated())
	{
		SetIncapacitated(true);
		if (Incapacitator != None)
			dispatchMessage(new class'MessagePawnNeutralized'(Incapacitator.Label, Label));
		else
			dispatchMessage(new class'MessagePawnNeutralized'('', Label));

		log(Name $ " is now incapacitated - IncapaciatedIdleCategoryOverride is " $ IncapaciatedIdleCategoryOverride);

		// set the patrol on the commander (since the commander action hasn't necessarily been created yet)
		Commander.BecomeIncapacitated(IncapaciatedIdleCategoryOverride);

		// allow subclasses to do things based on being incapacitated
		NotifyBecameIncapacitated(Incapacitator);

		// notify the game events system that we are incapacitated
		SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.Triggered(self, Incapacitator, IsAThreat() && !IsCompliant() && !IsArrested());
	}
}

// override me
function NotifyBecameIncapacitated(Pawn Incapacitator);

simulated function PostTakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation,
                                  Vector momentum, class<DamageType> damageType)
{
//	log("PostTakeDamage on " $ Name $ " Damage: " $ Damage $ " InstigatedBy: " $ InstigatedBy);

	// notify subclasses that we've been hit
	NotifyHit(Damage, InstigatedBy);

	Super.PostTakeDamage(Damage, InstigatedBy, HitLocation, Momentum, damageType);

	// become incapacitated if we should
	if (ShouldBecomeIncapacitated())
	{
		BecomeIncapacitated(,instigatedBy);
	}
}

function NotifyHit(float Damage, Pawn HitInstigator);

//
//IHaveSkeletalRegions overrides
//

// Notification that we were hit
// Overridden from SwatPawn
// message is forwarded to the commander
function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType, Actor Instigator)
{
	local Pawn Attacker;

	log("OnSkeletalRegionHit on " $ Name $ " Damage type: " $ DamageType);

	Attacker = Pawn(Instigator);

	// don't react if we're a client or if we got hit by a less lethal
	if (Level.NetMode != NM_Client)
	{
		// a check for being incapacitated is done in the commander
		GetCommanderAction().OnSkeletalRegionHit(RegionHit, HitLocation, HitNormal, Damage, DamageType);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Flinching

function name GetFlinchAnimation()
{
	if (IsCompliant())
	{
		return CompliantFlinchAnimations[Rand(CompliantFlinchAnimations.Length)];
	}
	else if (IsArrested())
	{
		return RestrainedFlinchAnimations[Rand(RestrainedFlinchAnimations.Length)];
	}
	else if (bIsCrouched)
	{
		return CrouchingFlinchAnimations[Rand(CrouchingFlinchAnimations.Length)];
	}
	else
	{
		return StandingFlinchAnimations[Rand(StandingFlinchAnimations.Length)];
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Action Accessors

native function CommanderAction GetCommanderAction();

function CharacterSpeechManagerAction GetSpeechManagerAction()
{
  if(SpeechManager.achievingAction == None) {
    return None;
  }
	assert(SpeechManager != None);
	assert(CharacterSpeechManagerAction(SpeechManager.achievingAction) != None);

	return CharacterSpeechManagerAction(SpeechManager.achievingAction);
}

///////////////////////////////////////////////////////////////////////////////
//
// Designer Debugging Info. Implementation

function DrawVisionCone(HUD DrawTarget)
{
	DrawTarget.Draw3DCone(GetViewPoint(), GetViewDirection(), SightRadius,
						  Acos(PeripheralVision) * 180.0f / PI,
						  class'Canvas'.Static.MakeColor(0,255,0), 8);
}

function DrawDebugAIMovement(HUD DrawTarget)
{
	local int i;
	local vector LineOrigin;

	if (Controller != None)
	{
		// draw to our movetarget and route cache
		if (Controller.MoveTarget != None)
		{
			DrawTarget.Draw3DLine(Location, Controller.MoveTarget.Location, class'Canvas'.Static.MakeColor(0,255,0));
			LineOrigin = Controller.MoveTarget.Location;

			if (Controller.MoveTarget == Controller.RouteCache[0])
			{
				for(i=1; i<16; ++i)
				{
					if (Controller.RouteCache[i] != None)
					{
						DrawTarget.Draw3DLine(LineOrigin, Controller.RouteCache[i].Location, class'Canvas'.Static.MakeColor(255,0,255));
						LineOrigin = Controller.RouteCache[i].Location;
					}
				}
			}
		}
		else if (Controller.MoveTimer > 0.0)
		{
			DrawTarget.Draw3DLine(Location, Controller.Destination, class'Canvas'.Static.MakeColor(200,200,255));
		}
	}
}

event DebugTyrionInfo(AI_Resource Resource)
{
    local int i;

    assert(Resource != None);

    AddDebugMessage(" ");

	if (Resource.goals.length > 0)
	{
		AddDebugMessage(Resource.Name $ " Goals", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < Resource.goals.length; i++ )
			AddDebugMessage("  " $ AI_Goal(Resource.goals[i]).goalName $ " (" $ AI_Goal(Resource.goals[i]).Priority $ ")");
	}

	if (Resource.runningActions.length > 0)
	{
		AddDebugMessage("Running " $ Resource.Name $ " Actions", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < Resource.runningActions.length; i++ )
			AddDebugMessage("  " $ Resource.runningActions[i].name);
	}

	if (Resource.idleActions.length > 0)
	{
		AddDebugMessage("Idle " $ Resource.Name $ " Actions", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < Resource.idleActions.length; i++ )
			AddDebugMessage("  " $ Resource.idleActions[i].name);
	}
}

event ShowAimingDebugInfo()
{
    local int i;
    local Color Color;
    local String ClientIdString;
    local String BehaviorString;

	if (class'Pawn'.static.checkConscious(self))
    {
	switch(AnimAimType)
	{
		case kAAT_Rotation:
			    AddDebugMessage("Aiming to Rotation " $ AnimAimRotator, class'Canvas'.Static.MakeColor(255,255,0));
			break;

		case kAAT_Point:
			    AddDebugMessage("Aiming at Point " $ AnimAimPoint, class'Canvas'.Static.MakeColor(255,255,0));
			break;

		case kAAT_Actor:
			    AddDebugMessage("Aiming at Actor " $ AnimAimActor, class'Canvas'.Static.MakeColor(255,255,0));
			break;
	}

	    AddDebugMessage(" ");
        AddDebugMessage("Upper Body Anim Behaviors", class'Canvas'.Static.MakeColor(255,255,255));
        AddDebugMessage("(most-to-least dominant):", class'Canvas'.Static.MakeColor(255,255,255));

        // UpperBodyAnimBehaviorEntries is ordered from highest to lowest priority
        for (i = 0; i < UpperBodyAnimBehaviorEntries.length; i++)
        {
            // Make the dominant priority brighter
            if (i == 0)
            {
                Color = class'Canvas'.Static.MakeColor(0,255,0);
            }
            else
            {
                Color = class'Canvas'.Static.MakeColor(0,192,0);
            }

            ClientIdString = String(GetEnum(enum'EUpperBodyAnimBehaviorClientId', UpperBodyAnimBehaviorEntries[i].clientId));
            BehaviorString = String(GetEnum(enum'EUpperBodyAnimBehavior', UpperBodyAnimBehaviorEntries[i].behavior));

            // Trim the "kUBABCI_" off of ClientIdString
            ClientIdString = Right(ClientIdString, Len(ClientIdString) - Len("kUBABCI_"));
            // Trim "kUBAB_" off of BehaviorString
            BehaviorString = Right(BehaviorString, Len(BehaviorString) - Len("kUBAB_"));

            AddDebugMessage("   "$ClientIdString$" - "$BehaviorString, Color);
        }
    }
}

function EnableVision()
{
	if (! bVisionDisabledPermanently)
	{
		bVisionDisabled = false;
	}
}

function DisableVision(bool bDisableVisionPermanently)
{
	bVisionDisabled = true;

	// if vision is already disabled permanently, don't change it
	if (! bVisionDisabledPermanently)
	{
		bVisionDisabledPermanently = bDisableVisionPermanently;
	}
}

function bool IsHearingEnabled()
{
	return !bHearingDisabled;
}

function EnableHearing()
{
	if (! bHearingDisabledPermanently)
	{
		bHearingDisabled = false;
	}
}

function DisableHearing(bool bDisableHearingPermanently)
{
	bHearingDisabled = true;

	// if hearing's already disabled permanently, don't change it
	if (! bHearingDisabledPermanently)
	{
		bHearingDisabledPermanently = bDisableHearingPermanently;
	}
}

function ArchetypeInstance GetArchetypeInstance()
{
    return ArchetypeInstance;
}

///////////////////////////////////////////////////////////////////////////////
//
//IUseArchetype interface implementation

function InitializeFromSpawner(Spawner Spawner)
{
    SpawnedFromName = Spawner.Name;
}

function Internal_InitializeFromArchetypeInstance(ArchetypeInstance inInstance)  //FINAL!
{
    ArchetypeInstance = inInstance;

    InitializeFromArchetypeInstance();

	// make sure we have the correct animations to go with our equipment
	ChangeAnimation();
}
function InitializeFromArchetypeInstance();

//Pawn override
simulated function DestroyEquipment()
{
    if ( Level.NetMode != NM_Client )
        ArchetypeInstance.DestroyEquipment();
}

///////////////////////////////////////////////////////////////////////////////
//
// AIKnowledge initialization, termination and accessor

private function InitKnowledge()
{
    AIKnowledge = new class'SwatAICommon.AIKnowledge';

    // Register the knowledge object for vision notifications
    assert(AIKnowledge != None);
    AIKnowledge.Init(Self, Vision);
}

///////////////////////////////////////

private function TermKnowledge()
{
    // Unregister the knowledge object for vision notifications
    assertWithDescription(AIKnowledge != None, "It appears an AI object has gotten its event Destroyed() without getting its event PostBeginPlay(). Look into why..");
    if (AIKnowledge != None)
    {
        AIKnowledge.Term();
        AIKnowledge = None;
    }
}

///////////////////////////////////////

function AIKnowledge GetKnowledge()
{
    return AIKnowledge;
}

///////////////////////////////////////////////////////////////////////////////
//
// Default Awareness implementations. Overridden by subclasses.

function AwarenessProxy GetAwareness()
{
    return None;
}

function DisableAwareness();
function EnableAwareness();

///////////////////////////////////////////////////////////////////////////////

function SetIsCompliant(bool Status)
{
	bIsCompliant = Status;
}

function SetIncapacitated(bool bInIsIncapacitated)
{
	bIsIncapacitated = bInIsIncapacitated;
}

function bool IsDisabled()
{
	// bit of a hacky test but it will do in lieu of an AI lodding system
	return !bCollideActors && !bBlockActors && !bBlockPlayers;
}

native function bool IsOtherActorAThreat(Actor otherActor);

function bool GetKnownLocationOfPawn(Pawn otherPawn, out vector location)
{
    local AIKnowledge.KnowledgeAboutPawn knowledge;
    if (AIKnowledge.GetLastKnownKnowledgeAboutPawn(otherPawn, knowledge))
    {
        location = knowledge.Location;
        return true;
    }

    return false;
}

// overridden from Pawn.uc
// returns true if we aren't compliant or arrested
native event bool CanMoveFreely();

// overridden by SwatCharacter
function bool IsAggressive()
{
	return false;
}

// overridden by SwatCharacter
function float GetInitialMorale()
{
	// invalid morale value
	return -1.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Taking cover

function InitCoverFinder()
{
    AICoverFinder = new class'SwatAICommon.AICoverFinder'(self);
}

function AICoverFinder GetCoverFinder()
{
    return AICoverFinder;
}

///////////////////////////////////////////////////////////////////////////////
//
// Running from a point

function NavigationPoint FindRunToPoint(vector PointToRunAwayFrom, float MinDistanceToRunAway)
{
    // Find the point that has the highest confidence and lowest threat to move to.
    local int i;
    local array<AwarenessProxy.AwarenessKnowledge> PotentiallyVisibleSet;
    local AwarenessProxy.AwarenessKnowledge Knowledge;
    local NavigationPoint NavigationPoint;
    local float DistSq;
    local float Weight;

    local NavigationPoint BestRunToPoint;
    local float BestRunToPointWeight;

    PotentiallyVisibleSet = GetAwareness().GetPotentiallyVisibleKnowledge(self);

    for (i = 0; i < PotentiallyVisibleSet.Length; ++i)
    {
        Knowledge = PotentiallyVisibleSet[i];
        NavigationPoint = Knowledge.aboutAwarenessPoint.GetClosestNavigationPoint();

//		log("NavigationPoint is: " $ NavigationPoint $ " Anchor is: " $ Anchor);

        if ((NavigationPoint != None) && !NavigationPoint.IsA('Door') && (NavigationPoint != Anchor))
        {
            DistSq = VDistSquared(Location, NavigationPoint.Location);

			// If within our desired distance..
            if (DistSq >= MinDistanceToRunAway)
            {
                // Calculate the weight, based on confidence, threat and distance.
                // We favor high confidence, low threat points.
                Weight = Knowledge.confidence - (Knowledge.threat * 2.0);
                if (BestRunToPoint == None || Weight > BestRunToPointWeight)
                {
                    BestRunToPoint = NavigationPoint;
                    BestRunToPointWeight = Weight;
                }
            }
        }
    }

    return BestRunToPoint;
}

///////////////////////////////////////////////////////////////////////////////
//
// Grenade Usage

private function UseGrenadeAction GetUseGrenadeBehavior()
{
	local UseGrenadeGoal CurrentUseGrenadeGoal;
	local UseGrenadeAction CurrentUseGrenadeAction;

	CurrentUseGrenadeGoal = UseGrenadeGoal(AI_Resource(weaponAI).findGoalByName("UseGrenade"));
	assert(CurrentUseGrenadeGoal != None);

	CurrentUseGrenadeAction = UseGrenadeAction(CurrentUseGrenadeGoal.achievingAction);
	assert(CurrentUseGrenadeAction != None);

	return CurrentUseGrenadeAction;
}

function vector GetThrowOriginOffset(bool bIsUnderhandThrow, rotator Orientation)
{
	local vector ThrowOriginOffset;

	if (bIsUnderhandThrow)
	{
		ThrowOriginOffset = UnderhandThrownProjectileInitialOffset >> Orientation;
	}
	else	// it's an overhand throw
	{
		ThrowOriginOffset = OverhandThrownProjectileInitialOffset >> Orientation;
	}

	return ThrowOriginOffset;
}

function vector GetThrowOrigin(bool bIsUnderhandThrow, rotator Orientation)
{
	return Location + GetThrowOriginOffset(bIsUnderhandThrow, Orientation);
}

// returns the angle, in Radians
function float GetThrowAngle()
{
	return ThrownProjectilePitch * DEGREES_TO_RADIANS;
}


///////////////////////////////////////////////////////////////////////////////
//
// ICanThrowWeapons implementation

function GetThrownProjectileParams(out vector outLocation, out rotator outRotation)
{
	// start location for the grenade is where the weapon's third person model is
	outLocation       = GetActiveItem().GetThirdPersonModel().Location;

	// rotation is based off of the target location as well as the pitch required to get it there
    outRotation.Yaw   = rotator(vGrenadeTargetLocation - outLocation).Yaw;
    outRotation.Pitch = WrapAngle0To2Pi(rotator(vGrenadeTargetLocation - outLocation).Pitch) + (ThrownProjectilePitch * DEGREES_TO_TWOBYTE);

//	log("Straight line pitch: " $ (rotator(vGrenadeTargetLocation - outLocation).Pitch) $ " Normal Pitch: " $ (ThrownProjectilePitch * DEGREES_TO_TWOBYTE) $ " Combined: " $ outRotation.Pitch);
//	log("out location is: " $ outLocation);
}

simulated function name GetPreThrowAnimation() { return ''; }   //AIs use a combined pull-pin-and-throw animation

simulated function name GetThrowAnimation(float ThrowSpeed)
{
	if (ThrowSide == kThrowFromCenter)
	{
		if (IsUnderhandThrowTo(vGrenadeTargetLocation))
		{
			return ThrowShortAnimation;
		}
		else
		{
			return ThrowLongAnimation;
		}
	}
	else if (ThrowSide == kThrowFromRight)
	{
		return ThrowFromRightAnimation;
	}
	else
	{
		// sanity check!
		assert(ThrowSide == kThrowFromLeft);

		return ThrowFromLeftAnimation;
	}
}

simulated function name GetPawnThrowRootBone()
{
	// AIs don't have a root bone for the throwing animation
	return '';
}

//Returns the tween time used for a Pawn's throw animation
simulated function float GetPawnThrowTweenTime()
{
	return ThrowAnimationTweenTime;
}

function bool IsUnderhandThrow(vector Origin, vector TargetLocation)
{
	return ((VSize(TargetLocation - Origin) < MaxUnderhandThrowDistance) &&
			((TargetLocation.Z - Origin.Z) < ZPositiveOffsetForOverhandThrow));
}

function bool IsUnderhandThrowTo(vector TargetLocation)
{
	return IsUnderhandThrow(Location, TargetLocation);
}

function SetGrenadeTargetLocation(vector vInGrenadeTargetLocation)
{
	vGrenadeTargetLocation = vInGrenadeTargetLocation;
}

function SetThrowSide(AIThrowSide inThrowSide)
{
	ThrowSide = inThrowSide;
}

//***************************************
// Interface to Pawn's Controller - overridden from Pawn.uc

// always return false
simulated function bool IsPlayerPawn()
{
	return false;
}

// always return false
simulated function bool IsHumanControlled()
{
	return false;
}

simulated function bool HasBeenReportedToTOC()
{
    return bHasBeenReportedToTOC;
}

simulated function ToggleDebugPathLines()
{
    bDebugPathLines = !bDebugPathLines;
}

// LatentAITriggerEffectEvent
//
// This is an AI-specific implementation because it makes some assumptions which
//  may only be appropriate for use for AI's purposes, eg.
//  play a sound, and then when that's done, play another one.

latent function LatentAITriggerEffectEvent(
    name EffectEvent,                   //The name of the effect event to trigger.  Should be a verb in past tense, eg. 'Landed'.
    // -- Optional Parameters --        // -- Optional Parameters --
    optional Actor Other,               //The "other" Actor involved in the effect event, if any.
    optional Material TargetMaterial,   //The Material involved in the effect event, eg. the matterial that a 'BulletHit'.
    optional vector HitLocation,        //The location in world-space (if any) at which the effect event occurred.
    optional rotator HitNormal,         //The normal to the involved surface (if any) at the HitLocation.
    optional bool PlayOnOther,          //If true, then any effects played will be associated with Other rather than Self.
    optional bool MoveMouth)            //If true, the AI will move its mouth for the duration of the effect
{
	local float MaxTime;

	if (logTyrion)
		log(Name $ " triggering effect event " $ EffectEvent $ " Tag is: " $ Tag $ " Time is: " $ level.timeseconds);

	// if we can't find a response to the effect event, don't play it!
	if (! TriggerEffectEvent(EffectEvent,,,,,,true))
	{
		return;
	}

	// reset the sound played and move mouth variable - * it is totally acceptable for this function to get interrupted and end prematurely *
	LatentSound = None;

    bEffectEventStillPlaying = true;
    AITriggerEffectEvent(EffectEvent, Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, Tag, MoveMouth, Rand( 10000 ) );

#if 1 //dkaplan
    //force timeout after XX seconds to ensure AI doesn't get stuck on a server if nobody hears the sound
    MaxTime = Level.TimeSeconds + MaxAIWaitForEffectEventToFinish;

    while( bEffectEventStillPlaying && MaxTime > Level.TimeSeconds )
    {
        Sleep( 0.03 );
    }
#else
    if (LatentSound == None)
    {
        Warn("[tcohen] SwatAI::LatentAITriggerEffectEvent() it seems like no sound was played in response to TriggerEffectEvent()");
        return;
    }

    //sleep until the sound starts
    Sleep(LatentSound.Delay);

    // Carlos: The sound could have potentially been stopped during the above sleep delay, making LatentSound invalid, and possibly
    // triggering  assertions in the sound code
    if (LatentSound == None || LatentSound.ActualSound == None)
    {
        Warn("[tcohen] SwatAI::LatentAITriggerEffectEvent() it seems like no sound was played in response to TriggerEffectEvent()");
        return;
    }
    //sleep while the sound is playing
    Sleep(LatentSound.GetDuration());
#endif
}

simulated function AITriggerEffectEvent(
    name EffectEvent,                   //The name of the effect event to trigger.  Should be a verb in past tense, eg. 'Landed'.
    // -- Optional Parameters --        // -- Optional Parameters --
    optional Actor Other,               //The "other" Actor involved in the effect event, if any.
    optional Material TargetMaterial,   //The Material involved in the effect event, eg. the matterial that a 'BulletHit'.
    optional vector HitLocation,        //The location in world-space (if any) at which the effect event occurred.
    optional rotator HitNormal,         //The normal to the involved surface (if any) at the HitLocation.
    optional bool PlayOnOther,          //If true, then any effects played will be associated with Other rather than Self.
    optional name ReferenceTag,
    optional bool MoveMouth,            //If true, the AI will move its mouth for the duration of the effect
    optional int Seed)                  //seed value used for determining effect responses
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    MoveMouthDuringEffect = MoveMouth;

    CurrentEffectEventName = EffectEvent;
    CurrentSeed = Seed;

    SetSeedForNextEffectEvent( CurrentSeed );

    TriggerEffectEvent(EffectEvent, Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther,
        false,          //QueryOnly wouldn't make sense in the context of LatentAITriggerEffectEvent
        self,	        //we are the EffectObserver
		ReferenceTag);

    // If we're a multiplayer server, RPC this ai effect event trigger to each client
    if (Level.NetMode != NM_Standalone && Level.NetMode != NM_Client)
    {
        theLocalPlayerController = Level.GetLocalPlayerController();
        for (i = Level.ControllerList; i != None; i = i.NextController)
        {
            current = SwatGamePlayerController(i);
            if (current != None && current != theLocalPlayerController)
            {
                current.ClientAITriggerEffectEvent(self, UniqueID(), string(EffectEvent), Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, string(ReferenceTag), MoveMouth, CurrentSeed);
            }
        }
    }
}

// Yeah, an odd name for a function in SwatAI. Basically the BroadcastEffectEvent
// call in RagdollPawn uses this method to determine the tag to pass to clients
// when a pawn dies. The default implementation returns an empty string, but AIs
// should return their Tag. It's too late in the project for a different fix.
simulated function Name GetPlayerTag()
{
    return Tag;
}

function ServerOnEffectStopped( string EffectName, int Seed )
{
//log( self$"::ServerOnEffectStopped( "$EffectName$", "$Seed$" ) at time " $ Level.TimeSeconds $ "... CurrentEffectEventName = "$CurrentEffectEventName$", CurrentSeed = "$CurrentSeed );
    if( name(EffectName) == CurrentEffectEventName && Seed == CurrentSeed )
        bEffectEventStillPlaying = false;

    RestartInterruptedActionSpeech( name(EffectName) );
}

function RestartInterruptedActionSpeech( name PreviousEffectEvent )
{
    if( PreviousEffectEvent != 'ReactedTaser' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "Tased" ) );
    if( PreviousEffectEvent != 'ReactedSting' && PreviousEffectEvent != 'ReactedBeanBag' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "Stung" ) );
    if( PreviousEffectEvent != 'ReactedGas' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "Gassed" ) );
    if( PreviousEffectEvent != 'ReactedPepper' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "PepperSprayed" ) );
    if( PreviousEffectEvent != 'ReactedBang' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "Flashbanged" ) );
    if( PreviousEffectEvent != 'ReactedBreach' )
        RestartStunnedActionSpeech( AI_Resource(characterAI).findGoalByName( "StunnedByC2" ) );
}

function RestartStunnedActionSpeech(AI_Goal goal)
{
	if( goal != None && goal.achievingAction != None && StunnedAction(goal.achievingAction) != None )
        StunnedAction(goal.achievingAction).TriggerStunnedSpeech();
}


//IEffectObserver implementation

simulated function OnEffectInitialized(Actor inInitializedEffect)
{
    LatentSound = IGSoundEffectsSubsystem.SoundInstance(inInitializedEffect);
//	log(Name $ " OnEffectInitialized - inInitializedEffect: " $ inInitializedEffect $ " LatentSound: " $ LatentSound);

    assertWithDescription(LatentSound != None,
        "[tcohen] SwatAI::OnEffectInitialized() an effect was created, but it was not a sound.  "
        $"SwatAI only expects to get an OnEffectInitialized() call for a sound played "
        $"in response to a LatentAITriggerEffectEvent() call.");
}

simulated function OnEffectStarted(Actor inStartedEffect)
{
    if (MoveMouthDuringEffect)
        StartMouthMovement();
}

simulated function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
	local IGSoundEffectsSubsystem.SoundInstance StoppedSoundInstance;
	StoppedSoundInstance = IGSoundEffectsSubsystem.SoundInstance(inStoppedEffect);

//	log(Name $ " OnEffectStopped - inStoppedEffect: " $ inStoppedEffect $ " StoppedSoundInstance: " $ StoppedSoundInstance $ " LatentSound: " $ LatentSound);

	// we only care about the current latent sound, other stopped sounds do not matter
	if (StoppedSoundInstance == LatentSound)
	{
		//LatentSound = None;
		StopMouthMovement();

//log( self$"::OnEffectStopped() ... CurrentEffectEventName = "$CurrentEffectEventName$", CurrentSeed = "$CurrentSeed );
		if( Level.NetMode != NM_DedicatedServer )
		    SwatGamePlayerController(Level.GetLocalPlayerController()).ServerOnEffectStopped( self, UniqueID(), string(CurrentEffectEventName), CurrentSeed );
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// ICanBeUsed implementation
//
// Allows the player to report the status of an unconscious or arrested ai to
// toc.

simulated function bool CanBeUsedNow()
{
//log( self$"::CanBeUsedNow() ... bHasBeenReportedToTOC = "$bHasBeenReportedToTOC$", class.static.checkConscious(self) = "$class.static.checkConscious(self)$", IsArrested() = "$IsArrested() );
    return !bHasBeenReportedToTOC && (!class.static.checkConscious(self) || IsArrested());
}

simulated function OnUsed(Pawn Other)
{
    assert(!bHasBeenReportedToTOC);

    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Triggered(self, Other);
}

simulated function PostUsed()
{
    bHasBeenReportedToTOC = true;
}

simulated function String UniqueID()
{
    return String(SpawnedFromName);
}

simulated function bool IsDOA()
{
  return false;
}

///////////////////////////////////////
// IAmReportableCharacter implementation

// Provides the effect event name to use when this ai is being reported to TOC
simulated final function name GetEffectEventForReportingToTOC()
{
    if (IsDOA())
    {
        return 'ReportedDOA';
    }
    else if (IsDead())
    {
        return GetEffectEventForReportingToTOCWhenDead();
    }
    else if (IsIncapacitated())
    {
        return GetEffectEventForReportingToTOCWhenIncapacitated();
    }
    else if (IsArrested())
    {
        return GetEffectEventForReportingToTOCWhenArrested();
    }
    else
    {
        return '';
    }
}

// Provides the effect event name to use when TOC is responding to a report
// about this ai
simulated final function name GetEffectEventForReportResponseFromTOC()
{
    if (IsDOA())
    {
       return 'RepliedDOAReported';
    }
    else if (IsIncapacitated())
    {
        return GetEffectEventForReportResponseFromTOCWhenIncapacitated();
    }
    else
    {
        return GetEffectEventForReportResponseFromTOCWhenNotIncapacitated();
    }
}

// Subclasses should override these functions with class-specific reporting
// effect event names
simulated function name GetEffectEventForReportingToTOCWhenDead()           { return ''; }
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return ''; }
simulated function name GetEffectEventForReportingToTOCWhenArrested()       { return ''; }

// Subclasses should override these functions with class-specific response
// effect event names
simulated function name GetEffectEventForReportResponseFromTOCWhenIncapacitated()      { return ''; }
simulated function name GetEffectEventForReportResponseFromTOCWhenNotIncapacitated()   { return ''; }

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	logTyrion                   = false
	logAI						= false
	ControllerClassName="SwatGame.SwatAIController"
	bRotateToDesired            = false

	RotationRate=(Pitch=4096,Yaw=60000,Roll=3072)

	AnimRotationUrgency         = kARU_Fast
    AnimAimRotationUrgency      = kAARU_Fast

	// by default we disable the aim flag unless we're aiming -- it will be turned on when we need it
	AnimFlags(2)                = 0

    EyeBoneName                 = eye_R
    // Peripheral vision is 60 degrees on either side (for a total of 120 degrees)
    PeripheralVision            = 0.5

    Physics                     = PHYS_Walking

	ShoulderOffset				= (X=0.0,Y=15.0,Z=42.0)
	PlayerBlockingPathStartTime = -1.0

	bAlwaysTestPathReachability = false
}
