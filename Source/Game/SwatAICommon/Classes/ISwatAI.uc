///////////////////////////////////////////////////////////////////////////////
// ISwatAI.uc - ISwatAI interface
// we use this interface to be able to call functions on the SwatAI because we
// the definition of SwatAI has not been defined yet, but because SwatAI implements
// ISwatAI, we have a contract that says these functions will be implemented, and 
// we can cast any Pawn pointer to an ISwatAI interface to call them

interface ISwatAI extends ISwatPawn native
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum FireMode from Engine.FiredWeapon;
import enum EAnimPlayType from Engine.Pawn;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// Shared AI Enums

enum AIDoorUsageSide
{
	kUseDoorFront,
	kUseDoorBack,
	kUseDoorCenter
};

enum AIDoorCloseSide
{
	kCloseFromLeft,
	kCloseFromRight
};

enum AIThrowSide
{
	kThrowFromCenter,
	kThrowFromLeft,
	kThrowFromRight
};

enum EUpperBodyAnimBehavior
{
    // Disables all procedural upper body animating, and instead lets the
    // lower channel, full-body animations control the upper body.
    kUBAB_FullBody,
    // Enables procedural upper body animating, using the low-ready animations
    // (if the pawn does not support low ready, it changes this state to
    // kUBAB_AimWeapon internally).
    kUBAB_LowReady,
    // Enables procedural upper body animating, using the aiming-weapon
    // animations.
    kUBAB_AimWeapon,
};

///////////////////////////////////////////////////////////////////////////////
//
// Vision & Hearing notification registration functions

function RegisterVisionNotification(IVisionNotification Registrant);
function UnregisterVisionNotification(IVisionNotification Registrant);

function RegisterHearingNotification(IHearingNotification Registrant);
function UnregisterHearingNotification(IHearingNotification Registrant);

function DisableVision(bool bDisableVisionPermanently);
function EnableVision();

function DisableHearing(bool bDisableHearingPermanently);
function EnableHearing();

function bool IsVisible(Pawn TestPawn);

///////////////////////////////////////////////////////////////////////////////
//
// Doors

function SetPendingDoor(Door inPendingDoor);
function ClearPendingDoor();
function bool ShouldForceOpenLockedDoors();

///////////////////////////////////////////////////////////////////////////////
//
// Awareness / Knowledge

function AwarenessProxy GetAwareness();
function DisableAwareness();

function EnableFavorLowThreatPath();
function DisableFavorLowThreatPath();

function AIKnowledge GetKnowledge();

///////////////////////////////////////////////////////////////////////////////
//
// Taking cover

function AICoverFinder GetCoverFinder();

function EnableFavorCoveredPath(array<Pawn> otherPawnsToCoverFrom);
function DisableFavorCoveredPath();

///////////////////////////////////////////////////////////////////////////////
//
// Running from a point

function NavigationPoint FindRunToPoint(vector PointToRunAwayFrom, float MinDistanceToRunAway);

///////////////////////////////////////////////////////////////////////////////
//
// Viewing

function vector GetViewDirection();
function vector GetViewPoint();

///////////////////////////////////////////////////////////////////////////////
//
// Compliance / Restrained

function NotifyBecameCompliant();
function IssueComplianceTo(Pawn TargetPawn);
function bool CanIssueComplianceTo(Pawn TargetPawn);
function HandheldEquipment GetRestrainedHandcuffs();
function Pawn GetArrester();

///////////////////////////////////////////////////////////////////////////////
//
// State Tests / Manipulators

function bool IsCompliant();
function bool IsArrested();
function bool IsOtherActorAThreat(Actor otherActor);
function bool IsAggressive();

function float GetInitialMorale();
function bool IsIntenseInjury();

function SetIsCompliant(bool Status);

function bool IsRelevantToPlayerOrOfficers();

function bool IsDisabled();	// has AI switched off?

///////////////////////////////////////////////////////////////////////////////
//
// Action Accessors

function CommanderAction				GetCommanderAction();
function CharacterSpeechManagerAction	GetSpeechManagerAction();

///////////////////////////////////////////////////////////////////////////////
//
// Idling

function bool IsIdleCurrent();
function ChooseIdle();

function SetIdleCategory(name inIdleCategory);
function name GetIdleCategory();

///////////////////////////////////////////////////////////////////////////////
//
// Playing Special Animations

function int AnimGetSpecialChannel();
function int AnimGetQuickHitChannel();
function AnimStopSpecial();
function AnimStopEquipment();
function AnimSetIdle(name NewIdleAnimation, float TweenTime);
function name GetUpperBodyBone();
function AnimStopQuickHit();
function int AnimPlayQuickHit(Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
function int AnimPlayEquipment(EAnimPlayType AnimPlayType, Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
function bool ShouldPlayFullBodyHitAnimation();

///////////////////////////////////////////////////////////////////////////////
//
// Triggering effect events

function LatentAITriggerEffectEvent(name EffectEvent,                   //The name of the effect event to trigger.  Should be a verb in past tense, eg. 'Landed'.
									// -- Optional Parameters --        // -- Optional Parameters --
									optional Actor Other,               //The "other" Actor involved in the effect event, if any.
									optional Material TargetMaterial,   //The Material involved in the effect event, eg. the matterial that a 'BulletHit'.
									optional vector HitLocation,        //The location in world-space (if any) at which the effect event occurred.
									optional rotator HitNormal,         //The normal to the involved surface (if any) at the HitLocation.
									optional bool PlayOnOther,          //If true, then any effects played will be associated with Other rather than Self.
                                    optional bool MoveMouth);           //If true, the AI will move its mouth for the duration of the effect

///////////////////////////////////////////////////////////////////////////////
//
// Attacking

function FireMode GetDefaultAIFireModeForWeapon(FiredWeapon Weapon);
function float GetTimeToWaitBetweenFiring(FiredWeapon Weapon);

///////////////////////////////////////////////////////////////////////////////
//
// Animation

function SwapInRestrainedAnimSet();
function SwapInCompliantAnimSet();

// Flashbang animations
function name GetFBReactionAnimation();
function name GetFBAffectedAnimation();
function name GetFBRecoveryAnimation();

// Gassed animations
function name GetGasReactionAnimation();
function name GetGasAffectedAnimation();
function name GetGasRecoveryAnimation();

// Stung animations
function name GetStungReactionAnimation();
function name GetStungAffectedAnimation();
function name GetStungRecoveryAnimation();

// Tased animations
function name GetTasedReactionAnimation();
function name GetTasedAffectedAnimation();
function name GetTasedRecoveryAnimation();

// Flinching
function name GetFlinchAnimation();

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Usage

function SetWeaponTarget(Actor Target);
function SetWeaponTargetLocation(vector TargetLocation);
function bool HasUsableWeapon();

function bool HasFiredWeaponEquipped();

function vector GetThrowOriginOffset(bool bIsUnderhandThrow, rotator Orientation);
function vector GetThrowOrigin(bool bIsUnderhandThrow, rotator Orientation);
function float GetThrowAngle();
function SetGrenadeTargetLocation(vector vInGrenadeTargetLocation);
function SetThrowSide(AIThrowSide inThrowSide);
function bool IsUnderhandThrow(vector Origin, vector TargetLocation);
function bool IsUnderhandThrowTo(vector TargetLocation);

///////////////////////////////////////////////////////////////////////////////
//
// Ragdoll

function float GetRagdollSimulationTimeout();
function DisableRagdoll(optional bool bKeepHavokPhysics);

///////////////////////////////////////////////////////////////////////////////
//
// Aiming

// Aim at something
function AimAtPoint(vector Point);
function AimAtActor(Actor Target);
function AimToRotation(rotator DesiredRotation);

// LockAim will disable any subsequent calls to AimAtPoint, AimAtActor, and
// AimToRotation. These calls will only have effect after UnlockAim is called.
// @HACK: This locking/unlocking mechanism should be replaced by a more robust
// priority-based system, similar to how ISwatAI::SetUpperBodyAnimBehavior
// works.
function LockAim();
function UnlockAim();
function bool GetLockAim();
function SetLockAim(bool newValue);

// Get the aim rotation
function Rotator	GetAimRotation();

// Set the urgency of the aiming
// Setting Fast to false results in Normal speed
function      SetAimUrgency(bool Fast);

// Disable aim
function	  DisableAim();

// most of the AI's weapons fire at the target directly - this function should return true when that's not the case
function bool FireWhereAiming();

// A given client of SetUpperBodyAnimBehavior can specify an integer id, unique
// to the client, that is used to manage which client wants which behavior. On
// top of this, a priority system provides a way of resolving who "wins" when
// multiple clients want different upper body anim behaviors. The greater the
// priority value, the higher the priority it has. The clientId is used as the
// priority value.
//
// If no clientId is passed in, then the default upper body anim behavior is
// changed.
//
// These clientIds are managed in UpperBodyAnimBehaviorClients.uc.
function SetUpperBodyAnimBehavior(EUpperBodyAnimBehavior behavior, optional EUpperBodyAnimBehaviorClientId clientId);
function UnsetUpperBodyAnimBehavior(optional EUpperBodyAnimBehaviorClientId clientId);
function EUpperBodyAnimBehavior GetUpperBodyAnimBehavior();

function EUpperBodyAnimBehavior GetMovementUpperBodyAimBehavior();

// Aim Tests (implemented in SwatPawn)
function bool AnimIsAimedAtDesired();
function bool AnimCanAimAtDesiredPoint(vector Point);
function bool AnimCanAimAtDesiredActor(Actor Actor);
function bool AnimCanAimAtDesiredRotation(Rotator Rotation);

// Aim Tests (implemented in SwatAI)
function bool AnimIsWeaponAimSet();

// Get the origin for our aiming
function vector AnimGetAimOrigin();

// Get the orientation of our aiming
function rotator GetAimOrientation();

function float GetAnimBaseYaw();
function AnimSnapBaseToAim();

function bool AnimAreAimingChannelsMuted();

function bool CanPawnUseLowReady();

// whether we're turning or not
function bool IsTurning();

// is this AI in view of any officers?
function bool IsUnobservedByOfficers();

// Notifications from staircase aiming volumes
function OnTouchedStaircaseAimVolume(StaircaseAimVolume StaircaseAimVolume);
function OnUntouchedStaircaseAimVolume(StaircaseAimVolume StaircaseAimVolume);

// Returns true if the pawn is touching 1 or more staircase aim volumes
function int GetNumTouchingStaircaseAimVolumes();
function StaircaseAimVolume GetTouchingStaircaseAimVolumeAtIndex(int index);
