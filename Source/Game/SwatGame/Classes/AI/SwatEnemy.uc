///////////////////////////////////////////////////////////////////////////////
class SwatEnemy extends SwatAICharacter
    implements SwatAICommon.ISwatEnemy,
        ICarryGuns,
        ICanBeSpawned
        native;
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;
import enum EnemyState from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////

const maxWeaponDistance = 200.0f;		// max distance a for a dropped weapon to be picked up

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// State Variables
var private EnemySkill					Skill;
var private bool                        bDontInvestigate;
var private EnemyState					CurrentState;
var private bool						bThreat;
var private bool						bIsSprinting;

// Config Variables
var config float						LowSkillAdditionalBaseAimError;
var config float						MediumSkillAdditionalBaseAimError;
var config float						HighSkillAdditionalBaseAimError;

var config float						LowSkillMinTimeToFireFullAuto;
var config float						LowSkillMaxTimeToFireFullAuto;
var config float						MediumSkillMinTimeToFireFullAuto;
var config float						MediumSkillMaxTimeToFireFullAuto;
var config float						HighSkillMinTimeToFireFullAuto;
var config float						HighSkillMaxTimeToFireFullAuto;

const            LowSkillMinTimeBeforeShooting = 1.0;
const            LowSkillMaxTimeBeforeShooting = 1.7;
const            MediumSkillMinTimeBeforeShooting = 0.9;
const            MediumSkillMaxTimeBeforeShooting = 1.3;
const            HighSkillMinTimeBeforeShooting = 0.6;
const            HighSkillMaxTimeBeforeShooting = 1.0;

var config float						MinDistanceToAffectMoraleOfOtherEnemiesUponDeath;

var config array<name>					ThrowWeaponDownAnimationsHG;
var config array<name>					ThrowWeaponDownAnimationsMG;
var config array<name>					ThrowWeaponDownAnimationsSMG;
var config array<name>					ThrowWeaponDownAnimationsSG;

var config float						LowSkillFullBodyHitChance;
var config float						MediumSkillFullBodyHitChance;
var config float						HighSkillFullBodyHitChance;

//can't run game with these vars compiled in; throws a
//'native class size does not match scripted class size' error -K.F.
//var config float						LowSkillComplyInstantDropChance;
//var config float						MediumSkillComplyInstantDropChance;
//var config float						HighSkillComplyInstantDropChance;

var bool								bEnteredFleeSafeguard;

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Variables

var protected FiredWeapon	PrimaryWeapon;
var protected FiredWeapon	BackupWeapon;
var WieldableEvidenceEquipment	HeldEvidence;

var private transient SwatAIData AIData;
//var private EnemySpawner	SpawnedFrom;   // the EnemySpawner that I was spawned from

var class<FiredWeapon> ReplicatedPrimaryWeaponClass;
var class<Ammunition> ReplicatedPrimaryWeaponAmmoClass;

var class<FiredWeapon> ReplicatedBackupWeaponClass;
var class<Ammunition> ReplicatedBackupWeaponAmmoClass;

var string DroppedPrimaryWeaponModelUniqueID;
var string DroppedBackupWeaponModelUniqueID;

replication
{
    reliable if ( Role == ROLE_Authority )
        ReplicatedPrimaryWeaponClass, ReplicatedPrimaryWeaponAmmoClass,
        ReplicatedBackupWeaponClass, ReplicatedBackupWeaponAmmoClass;
}


simulated function bool IsPrimaryWeapon( HandheldEquipment theItem )
{
    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---SwatEnemy::IsPrimaryWeapon(). theItem="$theItem );
        mplog( "...PrimaryWeapon="$PrimaryWeapon );
    }
    return theItem == PrimaryWeapon;
}


simulated event ReplicatedPrimaryWeaponClassInfoOnChanged()
{
    //local Vector NoDirection;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SwatEnemy::ReplicatedPrimaryWeaponClassInfoOnChanged()." );

    if( PrimaryWeapon != None )
    {
        mplog( "...destroying previous" );
        PrimaryWeapon.Destroy();
    }

    if ( ReplicatedPrimaryWeaponClass != None )
    {
        //mplog( "...spawning");
        PrimaryWeapon = Spawn( ReplicatedPrimaryWeaponClass, self );
        if (PrimaryWeapon != None)
        {
            //mplog( "...calling OnGivenToOwner()" );
            PrimaryWeapon.AmmoClass = ReplicatedPrimaryWeaponAmmoClass;
            PrimaryWeapon.OnGivenToOwner();
        }

        // AI's always equip their primary weapon if they have one.
        if (PrimaryWeapon != None)
        {
            //mplog( "...caling Equip()" );
            PrimaryWeapon.Equip();
        }
    }
}

simulated event ReplicatedBackupWeaponClassInfoOnChanged()
{
    //local Vector NoDirection;

    mplog( self$"---SwatEnemy::ReplicatedBackupWeaponClassInfoOnChanged()." );

    if( BackupWeapon != None )
    {
        mplog( "...destroying previous" );
        BackupWeapon.Destroy();
    }

    if ( ReplicatedBackupWeaponClass != None )
    {
        mplog( "...spawning");
        BackupWeapon = Spawn( ReplicatedBackupWeaponClass, self );
        if (BackupWeapon != None)
        {
            mplog( "...calling OnGivenToOwner()" );
            BackupWeapon.AmmoClass = ReplicatedBackupWeaponAmmoClass;
            BackupWeapon.OnGivenToOwner();
        }

        if ( DesiredAIEquipment == AIE_Backup && BackupWeapon != None )
        {
            mplog( "...caling Equip()" );
            BackupWeapon.Equip();
        }
    }
}


simulated event OnDesiredAIEquipmentChanged()
{
    mplog( self$"---SwatEnemy::OnDesiredAIEquipmentChanged(). NewValue="$DesiredAIEquipment );

    if ( DesiredAIEquipment == AIE_Backup )
    {
        if ( BackupWeapon != None )
        {
            BackupWeapon.Equip();
        }
    }
}


simulated event Destroyed()
{
    Super.Destroyed();

    AIData = None;
}


simulated function DestroyEquipment()
{
    mplog( self$"---SwatEnemy::DestroyEquipment()." );

    //force destroy weapons when pawn is destroyed
    if( PrimaryWeapon != None )
    {
        mplog( "...destroying primary weapon" );
        PrimaryWeapon.Destroy();
    }
    if( BackupWeapon != None )
    {
        mplog( "...destroying backup weapon" );
        BackupWeapon.Destroy();
    }

    Super.DestroyEquipment();
}

///////////////////////////////////////////////////////////////////////////////
//
// AI Vision

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we can only see SwatOfficers or SwatPlayers
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatEnemy') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function InitializeFromSpawner(Spawner Spawner)
{
    local EnemySpawner EnemySpawner;

    Super.InitializeFromSpawner(Spawner);

    //we may not have a Spawner, for example, if
    //  the console command 'summonarchetype' was used.
    if (Spawner == None) return;

    EnemySpawner = EnemySpawner(Spawner);
    assert(EnemySpawner != None);

	// set our idle category (it's ok to be '', which most likely it will be)
	SetIdleCategory(EnemySpawner.IdleCategoryOverride);

    //remember the spawner that I was spawned from
    AIData = new(None) class'SwatGame.SwatAIData';
    AIData.SpawnedFrom = EnemySpawner;

    InitializePatrolling(EnemySpawner.EnemyPatrol);
}

function InitializeFromArchetypeInstance()
{
    local EnemyArchetypeInstance Instance;
	local int i;
	local WieldableEvidenceEquipment e;

    Super.InitializeFromArchetypeInstance();

    Instance = EnemyArchetypeInstance(ArchetypeInstance);
    assert(Instance != None);   //ArchetypeInstance should always be set before InitializeFromArchetypeInstance() is called

    // setup our weapons
    InitializeWeapons(Instance);

    // set a few state variables
    Skill           = Instance.Skill;

	for (i = 0; i < Instance.Equipment.Length; ++i)
	{
		e = WieldableEvidenceEquipment(Instance.Equipment[i]);
		if (e != None)
		{
			HeldEvidence = e;
		}
	}
}

private function InitializeWeapons(EnemyArchetypeInstance Instance)
{
    PrimaryWeapon = Instance.PrimaryWeapon;
    BackupWeapon = Instance.BackupWeapon;

    ReplicatedPrimaryWeaponClass = Instance.SelectedPrimaryWeaponClass;
    ReplicatedPrimaryWeaponAmmoClass = Instance.SelectedPrimaryWeaponAmmoClass;

    ReplicatedBackupWeaponClass = Instance.SelectedBackupWeaponClass;
    ReplicatedBackupWeaponAmmoClass = Instance.SelectedBackupWeaponAmmoClass;

    if (PrimaryWeapon != None)
    {
        PrimaryWeapon.Equip();
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Resource Construction

// Create SwatEnemy specific abilities
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);

	characterResource.addAbility(new class'SwatAICommon.EnemyCommanderAction');
	characterResource.addAbility(new class'SwatAICommon.EnemySpeechManagerAction');
    characterResource.addAbility(new class'SwatAICommon.BarricadeAction');
    characterResource.addAbility(new class'SwatAICommon.InvestigateAction');
	characterResource.addAbility(new class'SwatAICommon.RestrainedAction');
	characterResource.addAbility(new class'SwatAICommon.TakeCoverAction');
	characterResource.addAbility(new class'SwatAICommon.EnemyComplianceAction');
	characterResource.addAbility(new class'SwatAICommon.EnemyCowerAction');
	characterResource.addAbility(new class'SwatAICommon.PickUpWeaponAction');

    // @NOTE: See comments below. [darren]
    ConstructCharacterAIHook(characterResource);

	// call down the chain
    Super.ConstructCharacterAI();
}

// This was added to allow guard AIs to share a lot of the enemy's code
// by being an enemy subclass, yet allowing the guard to remove some of the
// behaviors. This is in fact a bit inside-out, and it'd be better
// to have a common base class that most of this file is moved into, have
// SwatEnemy and SwatGuard inherit that base, and implement custom
// ConstructCharacterAI()'s that do exactly what they need. [darren]
protected function ConstructCharacterAIHook(AI_Resource characterResource)
{
    // By default, the base SwatEnemy class does add "hostile" behaviors
    characterResource.addAbility(new class'SwatAICommon.AttackOfficerAction');
	characterResource.addAbility(new class'SwatAICommon.TakeCoverAndAttackAction');
    characterResource.addAbility(new class'SwatAICommon.FleeAction');
	characterResource.addAbility(new class'SwatAICommon.ThreatenHostageAction');
	characterResource.addAbility(new class'SwatAICommon.ConverseWithHostagesAction');
    characterResource.addAbility(new class'SwatAICommon.RegroupAction');
}

protected function ConstructMovementAI()
{
    local AI_Resource movementResource;

	movementResource = AI_Resource(movementAI);
    assert(movementResource != none);

    super.constructMovementAI();

	movementResource.addAbility(new class'SwatAICommon.MoveToAttackOfficerAction');
}

protected function ConstructWeaponAI()
{
	local AI_Resource weaponResource;
    weaponResource = AI_Resource(weaponAI);
    assert(weaponResource != none);

	weaponResource.addAbility(new class'SwatAICommon.ReloadAction');

	// call down the chain
	Super.ConstructWeaponAI();
}

///////////////////////////////////////////////////////////////////////////////
//
// Animation

// enemies randomly choose whether they should play full body hit animations
function bool ShouldPlayFullBodyHitAnimation()
{
	local float Chance;

	switch(Skill)
	{
		case EnemySkill_High:
			Chance = HighSkillFullBodyHitChance;
			break;

		case EnemySkill_Medium:
			Chance = MediumSkillFullBodyHitChance;
			break;

		case EnemySkill_Low:
			Chance = LowSkillFullBodyHitChance;
			break;
	}

	return (FRand() < Chance);
}

// Animation Set Overrides
simulated function EAnimationSet GetStandingWalkAnimSet()
{
	local HandheldEquipment CurrentActiveItem;

	CurrentActiveItem = GetActiveItem();

	if (CurrentActiveItem != None)
	{
		if (CurrentActiveItem.IsA('SubMachineGun'))
		{
			return kAnimationSetGangWalkSMG;
		}
		else if (CurrentActiveItem.IsA('MachineGun'))
		{
			return kAnimationSetGangWalkMG;
		}
		else if (CurrentActiveItem.IsA('Shotgun'))
		{
			return kAnimationSetGangWalkSG;
		}
		else
		{
			return kAnimationSetGangWalkHG;
		}
	}
	else
	{
		return kAnimationSetGangWalk;
	}
}

simulated function EAnimationSet GetCrouchingAnimSet()	{ return kAnimationSetCrouching; }
simulated function EAnimationSet GetStandingRunAnimSet()
{
	if (bIsSprinting) // if we're sprinting from someone
	{
		return GetSprintAnimSet();
	}
	else
	{
		return GetRunAnimSet();
	}
}

private simulated function EAnimationSet GetRunAnimSet()
{
	local HandheldEquipment CurrentActiveItem;

	CurrentActiveItem = GetActiveItem();

	if (CurrentActiveItem != None)
	{
		if (CurrentActiveItem.IsA('SubMachineGun'))
		{
			return kAnimationSetGangRunSMG;
		}
		else if (CurrentActiveItem.IsA('MachineGun'))
		{
			return kAnimationSetGangRunMG;
		}
		else if (CurrentActiveItem.IsA('Shotgun'))
		{
			return kAnimationSetGangRunSG;
		}
		else
		{
			return kAnimationSetGangRunHG;
		}
	}
	else
	{
		return kAnimationSetGangSprint;
	}
}

private simulated function EAnimationSet GetSprintAnimSet()
{
	local HandheldEquipment CurrentActiveItem;

	CurrentActiveItem = GetActiveItem();

	if (CurrentActiveItem != None)
	{
		if (CurrentActiveItem.IsA('SubMachineGun'))
		{
			return kAnimationSetGangSprintSMG;
		}
		else if (CurrentActiveItem.IsA('MachineGun'))
		{
			return kAnimationSetGangSprintMG;
		}
		else if (CurrentActiveItem.IsA('Shotgun'))
		{
			return kAnimationSetGangSprintSG;
		}
		else
		{
			return kAnimationSetGangSprintHG;
		}
	}
	else
	{
		return kAnimationSetGangSprint;
	}
}

function StartSprinting() { bIsSprinting = true; }
function StopSprinting() { bIsSprinting = false; }

// Allow SwatEnemy to override their aim pose animation sets
simulated function EAnimationSet GetMachineGunAimPoseSet()
{
	assert(CharacterType != '');

	// if we're a gang member, use the gang anim poses
	if (CharacterType == 'EnemyMaleGang')
		return kAnimationSetGangMachinegun;
	else
		return kAnimationSetMachineGun;
}
// Allow SwatEnemy to override their aim pose animation sets
simulated function EAnimationSet GetHandGunAimPoseSet()
{
	assert(CharacterType != '');

	// if we're a gang member, use the gang anim poses
	if (CharacterType == 'EnemyMaleGang')
		return kAnimationSetGangHandGun;
	else
		return kAnimationSetHandGun;
}

// Enemies should not use specialized UMP aim poses
simulated function EAnimationSet GetUMPAimPoseSet()         { return GetSubMachineGunAimPoseSet(); }
simulated function EAnimationSet GetUMPLowReadyAimPoseSet() { return GetSubMachineGunLowReadyAimPoseSet(); }

///////////////////////////////////////////////////////////////////////////////
//
// Damage / Death / Incapacitation

function NotifyHit(float Damage, Pawn HitInstigator)
{
	local SwatEnemy EnemyInstigator;
    local bool       IsHitByEnemy;

    IsHitByEnemy = HitInstigator.IsA( 'SwatEnemy' );

	// the following doesn't need to be networked because we have no Officers in Coop
	if (IsHitByEnemy)
	{
    EnemyInstigator = SwatEnemy(HitInstigator);
    assert(EnemyInstigator != None);
	}

	if ((EnemyInstigator != None) && !IsIncapacitated())
	{
		// if we are a god we don't attack the player (request by paul)
		if (! Controller.bGodMode)
		{
			SwatEnemy(HitInstigator).GetEnemyCommanderAction().NotifyEnemyShotByEnemy(self, Damage, EnemyInstigator);
		}
	}
}
// enemies drop their weapons before they ragdoll
simulated function NotifyReadyToRagdoll()
{
    mplog( self$"---SwatEnemy::NotifyReadyToRagdoll()." );

	super.NotifyReadyToRagdoll();
    DropAllWeapons();
	DropAllEvidence(false);
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
	super.died(Killer, damageType, HitLocation, HitMomentum);

	if (Killer != None)
		NotifyNearbyEnemiesOfDeath(Killer.Pawn);
}

simulated function NotifyNearbyEnemiesOfDeath(Pawn Killer)
{
	local Pawn Iter;

	for (Iter = Level.pawnList; Iter != None; Iter = Iter.nextPawn)
	{
		if ((Iter != self) && Iter.IsA('SwatEnemy') && SwatEnemy(Iter).IsConscious())
		{
			if ((VSize2D(Iter.Location - Location) < MinDistanceToAffectMoraleOfOtherEnemiesUponDeath) &&
				LineOfSightTo(Iter))
			{
        if(Killer.IsA('SwatOfficer') || Killer.IsA('SwatPlayer') || Killer.IsA('NetPlayer'))
				    SwatEnemy(Iter).GetEnemyCommanderAction().NotifyNearbyEnemyKilled(self, Killer);
        else if(Killer.IsA('SwatEnemy'))
            SwatEnemy(Iter).GetEnemyCommanderAction().NotifyEnemyShotByEnemy(self, /*The actual damage is not used*/ 0.0, Killer);
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// ICarryGuns implementation
simulated function int GetStartingAmmoCountForWeapon(FiredWeapon in) {
  return 0; // This function is never called on SwatEnemy. We still need to include it though.
}

///////////////////////////////////////////////////////////////////////////////
//
// ISwatEnemy implementation

function EnemyState GetCurrentState()
{
	return CurrentState;
}

function BecomeAware()
{
	// for now we just set the enemy state.
	SetCurrentState(EnemyState_Aware);
}

function SetCurrentState(EnemyState NewState)
{
	CurrentState = NewState;

	// reset the idle category if we aren't unaware
	if (CurrentState != EnemyState_Unaware)
	{
		SetIdleCategory('');
	}
}

function EnemySkill GetEnemySkill()
{
	return Skill;
}

simulated function FiredWeapon GetPrimaryWeapon()
{
    return PrimaryWeapon;
}

simulated function FiredWeapon GetBackupWeapon()
{
    return BackupWeapon;
}

// returns true if we have a primary or backup weapon that has ammo (not empty)
function bool HasUsableWeapon()
{
	return (((GetPrimaryWeapon() != None) && !GetPrimaryWeapon().IsEmpty()) ||
		    ((GetBackupWeapon() != None) && !GetBackupWeapon().IsEmpty()));
}

function name SpawnedFromGroup()
{
	return GetSpawner().SpawnedFromGroup();
}

function EnemyCommanderAction GetEnemyCommanderAction()
{
	return EnemyCommanderAction(GetCommanderAction());
}

function EnemySpeechManagerAction GetEnemySpeechManagerAction()
{
	return EnemySpeechManagerAction(GetSpeechManagerAction());
}

simulated final function DropActiveWeapon(optional vector WeaponSpaceDropDirection, optional float DropImpulseMagnitude)
{
	local HandheldEquipment ActiveItem;

	mplog( self$"---SwatEnemy::DropActiveWeapon()." );

	if ( Level.IsCoopServer )
		NotifyClientsToDropActiveWeapon();

	ActiveItem = GetActiveItem();

	if (ActiveItem == None) return;

	if (ActiveItem == GetPrimaryWeapon() || ActiveItem == GetBackupWeapon())
	{
		DropWeapon(ActiveItem, WeaponSpaceDropDirection*DropImpulseMagnitude);
	}
}

simulated final function DropAllWeapons(optional vector WeaponSpaceDropDirection, optional float DropImpulseMagnitude)
{
	local HandheldEquipment PrimaryWeapon, BackupWeapon;
	local HandheldEquipmentModel BackupWeaponModel;

    mplog( self$"---SwatEnemy::DropAllWeapons()." );

    if ( Level.IsCoopServer )
        NotifyClientsToDropAllWeapons();

	PrimaryWeapon = GetPrimaryWeapon();

	if ((PrimaryWeapon != None) && PrimaryWeapon.IsA('FiredWeapon'))
	{
        DropWeapon(PrimaryWeapon, WeaponSpaceDropDirection*DropImpulseMagnitude);
	}

	BackupWeapon = GetBackupWeapon();

	if ((BackupWeapon != None) && BackupWeapon.IsA('FiredWeapon'))
	{
        mplog( "...1" );
		BackupWeaponModel = BackupWeapon.GetThirdPersonModel();

		if (! BackupWeaponModel.bHidden)
		{
            mplog( "...2" );
			DropWeapon(BackupWeapon, WeaponSpaceDropDirection*DropImpulseMagnitude);
		}
		else if (! BackupWeapon.IsIdle())
		{
            mplog( "...3" );
			BackupWeapon.AIInterrupt();
		}
	}
}

simulated final function DropAllEvidence(bool bIsDestroying)
{
    mplog( self$"---SwatEnemy::DropAllEvidence()." );

	if (HeldEvidence == None)
		return;

	if (!bIsDestroying)
		HeldEvidence.Drop();
	else
		HeldEvidence.DestroyEvidence();

    if ( Level.IsCoopServer )
        NotifyClientsToDropAllEvidence(bIsDestroying);

	HeldEvidence = None;
}

function NotifyClientsToDropAllWeapons()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    mplog( self$"$---SwatEnemy::NotifyClientsToDropAllWeapons()." );

    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIDroppedAllWeapons( self );
        }
    }
}

function NotifyClientsToDropActiveWeapon()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    mplog( self$"$---SwatEnemy::NotifyClientsToDropActiveWeapon()." );

    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIDroppedActiveWeapon( self );
        }
    }
}

function NotifyClientsToDropAllEvidence(bool bIsDestroying)
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    mplog( self$"$---SwatEnemy::NotifyClientsToDropAllEvidence()." );

    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIDroppedAllEvidence( self, bIsDestroying );
        }
    }
}

simulated final function DropCurrentWeapon(optional vector WeaponSpaceDropDirection, optional float DropImpulseMagnitude)
{
	local HandheldEquipment CurrentItem;

    mplog( self$"---SwatEnemy::DropCurrentWeapon()." );

	CurrentItem = GetActiveItem();

    if ((CurrentItem != None) && CurrentItem.IsA('FiredWeapon'))
	{
        mplog( "...1" );
        DropWeapon(CurrentItem, WeaponSpaceDropDirection*DropImpulseMagnitude);
	}
}

// pick up a weapon (will always become the primary weapon)
simulated final function PickUpWeaponModel(HandHeldEquipmentModel HHEModel)
{
	assert(HHEModel.HandHeldEquipment != None);
	assert(FiredWeapon(HHEModel.HandHeldEquipment) != None);

	PrimaryWeapon = FiredWeapon(Spawn( HHEModel.HandHeldEquipment.class, self ));
	PrimaryWeapon.OnGivenToOwner();

	ReplicatedPrimaryWeaponClass = PrimaryWeapon.class;
	ReplicatedPrimaryWeaponAmmoClass = PrimaryWeapon.AmmoClass;

    if (PrimaryWeapon != None)
    {
        PrimaryWeapon.Equip();
    }

	// delete weapon model on ground
	// todo: worry about replication!
	HHEModel.Destroy();
}

// Used by DropWeapon().
native event bool ActorIsInSameOrAdjacentZoneAsMe( Actor theOtherActor );

simulated final function DropWeapon(HandheldEquipment Weapon, vector WeaponSpaceImpulse)
{
    local rotator RotationBeforeDrop;
    local vector LocationBeforeDrop;
	local HandheldEquipmentModel WeaponModel;
    local bool PhysicsError;
    local bool WasPrimary;

    mplog( self$"---SwatEnemy::DropWeapon(). Weapon="$Weapon$", WeaponSpaceImpulse="$WeaponSpaceImpulse );

	assert(Weapon != None);

	// let our commander know, if we're not a client
	if ((Level.NetMode != NM_Client) && (Weapon == GetActiveItem()))
	{
		GetEnemyCommanderAction().NotifyWeaponDropped();
	}

	// disable any aim we might have
	DisableAim();

    // get the weapon model, that's what we will drop
	WeaponModel = Weapon.GetThirdPersonModel();
	assert(WeaponModel != None);

    // Cache the correct UniqueID before we lose the info we need to compute
    // it correctly.
    WeaponModel.UniqueID();
    mplog( "...WeaponModel.UniqueID()="$WeaponModel.UniqueID() );

    // Get the position of the weapon at time of drop
	RotationBeforeDrop = WeaponModel.Rotation;
    LocationBeforeDrop = WeaponModel.Location;

	// make sure the weapon isn't doing anything (like being equipped)
	Weapon.AIInterrupt();

    // Unequip the weapon and make it unavailable while simultaneously
    // bypassing the equipment system's normal unequip process of
    // playing animations, etc.
	if (Weapon == GetActiveItem())
	{
		Weapon.HACK_QuickUnequipForAIDropWeapon();
		SetActiveItem(None);
	}
	else
	{
		DetachFromBone(Weapon);
	}

	// remove any references to the weapon
	if (Weapon == GetPrimaryWeapon())
	{
	    DestroyDroppedWeapon( true );

	    WasPrimary = true;
	    //PrimaryWeaponDropped=true;
		PrimaryWeapon = None;

        ReplicatedPrimaryWeaponClass = None;
        ReplicatedPrimaryWeaponAmmoClass = None;

        if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
            DroppedPrimaryWeaponModelUniqueID = WeaponModel.UniqueID();
	}
	else
	{
		assertWithDescription((Weapon == GetBackupWeapon()), "SwatEnemy::DropWeapon - Weapon ("$Weapon$") is not the backup weapon.  Crombie's sanity check failed!");

	    DestroyDroppedWeapon( false );

	    //BackupWeaponDropped=true;
		BackupWeapon = None;

        ReplicatedBackupWeaponClass = None;
        ReplicatedBackupWeaponAmmoClass = None;

        if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
            DroppedBackupWeaponModelUniqueID = WeaponModel.UniqueID();
	}

	WeaponModel.bBlockNonZeroExtentTraces = true;
	WeaponModel.bBlockZeroExtentTraces = true;
	WeaponModel.bProjTarget = true;
	WeaponModel.SetCollision(true, false, false);
    WeaponModel.SetLocation(LocationBeforeDrop);
    WeaponModel.SetRotation(RotationBeforeDrop);

    // If the weapon model is on the other side of a wall from the pawn when
    // it's dropped, tweak it so that it won't collide with the ragdoll and
    // drop it from the pawn's location.
    if ( !ActorIsInSameOrAdjacentZoneAsMe( WeaponModel ))
    {
        mplog( self$"...was dropping "$WeaponModel$", but it was in a different zone from me. Dropping from my location..." );
        WeaponModel.HavokSetBlocking( false );
        WeaponModel.SetLocation( Location );
        WeaponModel.SetPhysics( PHYS_Falling );
    }

    PhysicsError = false;
 	// Make sure there's havok params set for the weapon model.
    if (WeaponModel.HavokDataClass == None)
    {
	    assertWithDescription(false, "SwatEnemy::DropWeapon - HavokDataClass for WeaponModel " $ WeaponModel.Name $ " is NULL.");
        PhysicsError = true;
    }

    // set the physics and give the model an impulse
    if (!PhysicsError)
    {
		// if the weapon model doesn't have a static mesh, use the DroppedStaticMesh property
		//log("WeaponModel: " $ WeaponModel.Name $ " WeaponModel.StaticMesh: " $ WeaponModel.StaticMesh);
	    if (WeaponModel.StaticMesh == None)
	    {
		    assertWithDescription((WeaponModel.DroppedStaticMesh != None), "WeaponModel " $ WeaponModel.Name $ " does not have a Dropped static mesh set for it.  It must!  Bug Shawn!!!");

		    log("setting static mesh to: " $ WeaponModel.DroppedStaticMesh);
		    WeaponModel.SetStaticMesh(WeaponModel.DroppedStaticMesh);
		    WeaponModel.SetDrawType(DT_StaticMesh);
	    }

	    WeaponModel.HavokSetBlocking(true);
	    WeaponModel.SetPhysics(PHYS_Havok);

        // convert the weapon-local impulse to world space and apply it to
        // the weapon
        Log(Name$" dropping WeaponModel "$WeaponModel.Name$" at location "$WeaponModel.Location$" with weapon-space Impulse dir="$Normal(WeaponSpaceImpulse)$" mag="$VSize(WeaponSpaceImpulse)$" (WeaponModel.bHidden="$WeaponModel.bHidden$", Weapon that owns model is "$Weapon.Name$")");
        WeaponModel.HavokImpartCOMImpulse(WeaponSpaceImpulse >> Rotation);
    }

    // Regardless of drawtype, use collision cylinder so reporting will be easier for the player
    WeaponModel.bUseCylinderCollision = true;

    // Notify the weapon that it has been dropped
    WeaponModel.OnDropped(WasPrimary);

    if ( Level.IsCOOPServer )
        WeaponModel.NotifyClientsAIDroppedWeapon(WeaponSpaceImpulse >> Rotation);

	// Swap in the correct movement animation set for not having a weapon
	// (don't want them to run around like they have a weapon)
	ChangeAnimation();
}

simulated function DestroyDroppedWeapon( bool bPrimary )
{
    local string UniqueIdentifier;
    local HandheldEquipmentModel Target;

    mplog( self$"---SwatEnemy::DestroyDroppedWeapon()." );
    mplog( "...bPrimary="$bPrimary );

    if( bPrimary )
        UniqueIdentifier = UniqueID() $ "Pocket_PrimaryWeapon";
    else
        UniqueIdentifier = UniqueID() $ "Pocket_SecondaryWeapon";

	ForEach DynamicActors(class'HandheldEquipmentModel', Target)
	{
		if( Target.IsDropped() && Target.UniqueID() == UniqueIdentifier)
        {
            mplog( "...destroying target="$Target$", with UniqueID="$UniqueIdentifier );
			Target.Destroy();
        }
	}
}

simulated private function name GetThrowWeaponDownAnimation()
{
	if (GetActiveItem().IsA('Handgun'))
	{
		return ThrowWeaponDownAnimationsHG[Rand(ThrowWeaponDownAnimationsHG.Length)];
	}
	else if (GetActiveItem().IsA('MachineGun'))
	{
		return ThrowWeaponDownAnimationsMG[Rand(ThrowWeaponDownAnimationsMG.Length)];
	}
	else if (GetActiveItem().IsA('SubMachineGun'))
	{
		return ThrowWeaponDownAnimationsSMG[Rand(ThrowWeaponDownAnimationsSMG.Length)];
	}
	else
	{
		assert(GetActiveItem().IsA('Shotgun'));

		return ThrowWeaponDownAnimationsSG[Rand(ThrowWeaponDownAnimationsSG.Length)];
	}
}

simulated latent final function ThrowWeaponDown()
{
	local float AnimationRate;
	if (GetActiveItem() != None)
	{
		AnimationRate = RandRange(1.1, 1.6);
		AnimPlaySpecial(GetThrowWeaponDownAnimation(), 0.1, '', AnimationRate);
		AnimFinishSpecial();
	}
}

function HandHeldEquipmentModel FindNearbyWeaponModel()
{
	local HandHeldEquipmentModel Target;

	ForEach DynamicActors(class'HandheldEquipmentModel', Target)
	{
		// todo: should also do a "isReachable" check probably...
		if (VDistSquared(Location, Target.Location) < maxWeaponDistance*maxWeaponDistance && FiredWeapon(Target.HandHeldEquipment) != None && Target.CanBeUsedNow())
			return Target;
 	}

	return None;
}

//Suspects who are beginning to comply have a chance to drop weapon instantly
function bool ShouldDropWeaponInstantly()
{
	local float Chance;

	switch(Skill)
	{
		//note: new ComplyInstantDropChance vars cause errors, so re-using
		//FullyBodyHitChance vars as a temporary hack
		case EnemySkill_High:
			//Chance = HighSkillComplyInstantDropChance;
			Chance = HighSkillFullBodyHitChance;
		case EnemySkill_Medium:
			//Chance = MediumSkillComplyInstantDropChance;
			Chance = MediumSkillFullBodyHitChance;
		case EnemySkill_Low:
			//Chance = LowSkillComplyInstantDropChance;
			Chance = LowSkillFullBodyHitChance;
	}
	return (FRand() < Chance);
}

///////////////////////////////////////////////////////////////////////////////
//
// Threat

function BecomeAThreat()
{
	if (! bThreat)
	{
//		if (logTyrion)
			log(Name $ " became a threat!");

		bThreat = true;

		// notify the hive that we've become a threat (so Officers deal with us appropriately)
		SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyBecameThreat(self);
	}
}

function UnbecomeAThreat() //Not imaginative name, I know -J21C
{
	if (bThreat)
	{
//		if (logTyrion)
			log(Name $ " is not a Threat anymore!");

		bThreat = false;

		// notify the hive that we've become a threat (so Officers deal with us appropriately)
		SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyBecameThreat(self);
	}
}

function bool IAmThreat()
{
	return bThreat;
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

protected function InitializeDoorKnowledge(Door inDoor, PawnDoorKnowledge DoorKnowledge)
{
	assert(inDoor != None);
	assert(inDoor.IsA('SwatDoor'));
	assert(DoorKnowledge != None);

	// if the door was initially locked, we belive that already (whether it's currently true or not)
	DoorKnowledge.SetBelievesDoorLocked(SwatDoor(inDoor).WasDoorInitiallyLocked());
}

// Enemies force locked doors to open
function bool ShouldForceOpenLockedDoors()
{
	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Awareness

function bool IsNeutralized()
{
    return (!IsConscious() || IsArrested());
}

//
// ICanBeSpawned Implementation
//

function Spawner GetSpawner()
{
    return AIData.SpawnedFrom;
}

///////////////////////////////////////////////////////////////////////////////
//
// Attacking

native event float GetAdditionalBaseAimError();

// overridden from ISwatAI
function float GetTimeToWaitBeforeFiring()
{
  switch(Skill)
  {
    case EnemySkill_High:
      return RandRange(HighSkillMinTimeBeforeShooting, HighSkillMaxTimeBeforeShooting);
    case EnemySkill_Medium:
      return RandRange(MediumSkillMinTimeBeforeShooting, MediumSkillMaxTimeBeforeShooting);
    case EnemySkill_Low:
      return RandRange(LowSkillMinTimeBeforeShooting, LowSkillMaxTimeBeforeShooting);
  }
}

// overridden from SwatAI
protected function float GetLengthOfTimeToFireFullAuto()
{
	switch(Skill)
	{
		case EnemySkill_High:
			return RandRange(HighSkillMinTimeToFireFullAuto, HighSkillMaxTimeToFireFullAuto);

		case EnemySkill_Medium:
			return RandRange(MediumSkillMinTimeToFireFullAuto, MediumSkillMaxTimeToFireFullAuto);

		case EnemySkill_Low:
			return RandRange(LowSkillMinTimeToFireFullAuto, LowSkillMaxTimeToFireFullAuto);
	}
}

// automatically become a threat if we discharge our weapon
protected function NotifyWeaponDischarged()
{
	if (! IsAThreat())
	{
		BecomeAThreat();
	}
}

function bool IsAnInvestigator()
{
	return !bDontInvestigate;
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI

simulated function name GetEffectEventForReportingToTOCWhenDead()           { return 'ReportedDeadSuspect'; }
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return 'ReportedInjSuspectSecured'; }
simulated function name GetEffectEventForReportingToTOCWhenArrested()       { return 'ReportedSuspectSecured'; }

// Subclasses should override these functions with class-specific response
// effect event names. Overridden from SwatAI
simulated function name GetEffectEventForReportResponseFromTOCWhenIncapacitated()      { return 'RepliedInjSuspectReported'; }
simulated function name GetEffectEventForReportResponseFromTOCWhenNotIncapacitated()   { return 'RepliedSuspectReported'; }

///////////////////////////////////////////////////////////////////////////////
//
// Misc

function OnUsingBegan()
{
    Super.OnUsingBegan();

    if ( GetActiveItem().IsA( 'FiredWeapon' ) )
        SwatGameInfo(Level.Game).GameEvents.EnemyFiredWeapon.Triggered( Self, GetWeaponTarget() );

}


simulated event FellOutOfWorld( eKillZType KillType )
{
    if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
    {
        // Notify the clients to destroy the enemy's dropped weapons by
        // UniqueID. Otherwise, their models might be left around but
        // unreportable.
        if ( DroppedPrimaryWeaponModelUniqueID != "" )
            NotifyClientsToDestroyDroppedWeapon( DroppedPrimaryWeaponModelUniqueID );
        if ( DroppedBackupWeaponModelUniqueID != "" )
            NotifyClientsToDestroyDroppedWeapon( DroppedBackupWeaponModelUniqueID );
    }

    Super.FellOutOfWorld( KillType );
}


function NotifyClientsToDestroyDroppedWeapon( string theUniqueID )
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    mplog( self$"$---SwatEnemy::NotifyClientsToDestroyDroppedWeapon(). UniqueID="$theUniqueID );

    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientWeaponFellOutOfWorld( theUniqueID );
        }
    }
}

function StartInvestigating()
{
	bDontInvestigate = false;
}

function StopInvestigating()
{
	bDontInvestigate = true;
}

function bool RollInvestigate()
{
	local EnemyArchetypeInstance Instance;

	if(bDontInvestigate)
	{	// not allowed to investigate sounds anymore
		return false;
	}

	Instance = EnemyArchetypeInstance(ArchetypeInstance);
	assert(Instance != None);

	return FRand() < Instance.InvestigateChance;
}

function bool RollBarricade()
{
	local EnemyArchetypeInstance Instance;

	Instance = EnemyArchetypeInstance(ArchetypeInstance);
	assert(Instance != None);

	return FRand() < Instance.BarricadeChance;
}

///////////////////////////////////////////////////////////////////////////////

simulated function bool ReadyToTriggerEffectEvents()
{
    //returns true if already equipped an item or they have no primary weapon
    return HasEquippedFirstItemYet || ( GetPrimaryWeapon() == None );
}

function bool EnteredFleeSafeguard()
{
	return bEnteredFleeSafeguard;
}

function bool HasEvidence()
{
	return HeldEvidence != None;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	AnimRotationUrgency = kARU_VeryFast

    Mesh = SkeletalMesh'SWATMaleAnimation2.MaleGang1'
    Texture = Texture'SWATgearTex.Placeholder'
}
