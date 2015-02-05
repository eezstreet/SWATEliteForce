///////////////////////////////////////////////////////////////////////////////

// Base class for non-officer (i.e., enemy and hostage) AIs in SWAT.
class SwatAICharacter extends SwatAI
    implements ISwatAICharacter,
               IReactToFlashbangGrenade, 
               IReactToCSGas, 
               IReactToStingGrenade, 
               IReactToDazingWeapon,
               IReactToC2Detonation, 
               Engine.ICanBeTased, 
               Engine.ICanBePepperSprayed, Engine.IReactToThrownGrenades
    abstract
    native;

import enum AIEquipment from ISwatAICharacter;

var Mesh OfficerMesh; // have to use a separate variable to work around script compiler bug
var private float InitialMorale;
var protected name VoiceType;
var protected name CharacterType;

var protected float LastTimeFlashBanged;
var protected float FlashBangedDuration;

var protected float LastTimeGassed;
var protected float GassedDuration;

var protected float LastTimePepperSprayed;
var protected float PepperSprayedDuration;

var protected float LastTimeTased;
var protected float TasedDuration;

var protected float LastTimeStung;
var protected float StungDuration;

var protected float LastTimeStunnedByC2;
var protected float StunnedByC2Duration;

var private bool bCanBeArrested;

var config string			  RestrainedHandcuffsClassName;
var private HandheldEquipment RestrainedHandcuffs;

var config float			  IncapacitatedHealthAmount;

var private bool bIsAggressive; // whether this AI is aggressive
var private bool bTaserKillsMe;
var private bool bPepperKillsMe;

// Each character AI has its own instance of an awareness object, held as an
// AwarenessProxy reference
var private AwarenessProxy	Awareness;
var private float			AwarenessCounter;
var private bool			bAwarenessDisabled;

const kMinAwarenessUpdateTime = 0.333;
const kMaxAwarenessUpdateTime = 0.666;

// In a network game, the server replicates these to the clients, where they
// use them in PostNetBeginPlay.
var private Material ReplicatedSkins[4]; // 4 is the length of the Skins array in Engine.Pawn
var private Mesh ReplicatedMesh;

var private bool bReplicatedIsFemale;

var private class<Equipment> ReplicatedEquipment1Class;
var private class<Equipment> ReplicatedEquipment2Class;
var private class<Equipment> ReplicatedEquipment3Class;
var private class<Equipment> ReplicatedEquipment4Class;

var private array<Equipment> NetEquipment;

// Replicated to clients so that they know what the AI should have equipped
// currently.
var AIEquipment DesiredAIEquipment;

// Replicated to clients so that they know when this AI should use its
// patrolling animation set.
var private bool ReplicatedShouldUsePatrolAnims;


///////////////////////////////////////////////////////////////////////////////

replication
{
    reliable if ( Role == ROLE_Authority )
        bCanBeArrested,
        CharacterType, VoiceType, ReplicatedSkins, ReplicatedMesh, bReplicatedIsFemale,
        ReplicatedEquipment1Class, ReplicatedEquipment2Class,
        ReplicatedEquipment3Class, ReplicatedEquipment4Class, DesiredAIEquipment,
        ReplicatedShouldUsePatrolAnims;
}


///////////////////////////////////////////////////////////////////////////////

simulated event PreBeginPlay()
{
	Super.PreBeginPlay();

    // * SERVER AND CLIENT
	// spawn the cuffs
	SpawnRestrainedHandcuffs();
}

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    // * SERVER ONLY
    if ( Level.NetMode != NM_Client )
    {
    CreateAwareness();
}
}

simulated event ReplicatedMeshInfoOnChanged()
{
    if (Level.GetEngine().EnableDevTools)
        mplog(self$"---SwatAICharacter::ReplicatedMeshInfoOnChanged(), About to call SwitchToMesh on client, bReplicatedIsFemale is "$bReplicatedIsFemale);
    SwitchToMesh( ReplicatedMesh );
}

simulated event ReplicatedSkinsOnChanged( int SkinIndex )
{
    if (Level.GetEngine().EnableDevTools)
        mplog(self$"---SwatAICharacter::ReplicatedSkinsOnChanged( "$SkinIndex$" ), Skins[SkinIndex] = "$Skins[SkinIndex]$", ReplicatedSkins[SkinIndex] = "$ReplicatedSkins[SkinIndex]);
    Skins[SkinIndex] = ReplicatedSkins[SkinIndex];
}

simulated event ReplicatedEquipmentClassOnChanged( class<Equipment> EquipmentClass )
{
    local Equipment theEquipment;

    theEquipment = Spawn( EquipmentClass, self );
    if (theEquipment != None)
    {
        theEquipment.OnGivenToOwner();
        NetEquipment[NetEquipment.Length]=theEquipment;
    }
}

// Override in derived class.
simulated event OnDesiredAIEquipmentChanged()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SwatAICharacter::OnDesiredAIEquipmentChanged(). NewValue="$DesiredAIEquipment );
}

// Called only on the server.
function SetDesiredAIEquipment( AIEquipment NewValue )
{
    Assert( Level.NetMode != NM_Client );

    DesiredAIEquipment = NewValue;
}


simulated event Destroyed()
{
    Super.Destroyed();
    
    // * SERVER ONLY
    if ( Level.NetMode != NM_Client )
        TermAwareness();
}


simulated function DestroyEquipment()
{
    local int i;
    
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SwatAICharacter::DestroyEquipment()." );

    for( i = 0; i < NetEquipment.Length; i++ )
    {
        if( NetEquipment[i] != None )
            NetEquipment[i].Destroy();
    }
    
    NetEquipment.Remove( 0, NetEquipment.Length );

    // We create the handcuffs separately from the rest of the equipment, so
    // we need to destroy them separately here.
    if ( RestrainedHandcuffs != None )
        RestrainedHandcuffs.Destroy();

    Super.DestroyEquipment();
}

///////////////////////////////////////////////////////////////////////////////

// you should call down the chain with this function
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterAI != None);
        
    // Create SwatAICharacter specific abilities
    if (ShouldReactToNonLethals())
    {
	    characterResource.addAbility(new class'SwatAICommon.PepperSprayedAction');
	    characterResource.addAbility(new class'SwatAICommon.GassedAction');
	    characterResource.addAbility(new class'SwatAICommon.FlashbangedAction');
	    characterResource.addAbility(new class'SwatAICommon.TasedAction');
	    characterResource.addAbility(new class'SwatAICommon.StunnedByC2Action');
	    characterResource.addAbility(new class'SwatAICommon.InitialReactionAction');
	    characterResource.addAbility(new class'SwatAICommon.StungAction');
	    characterResource.addAbility(new class'SwatAICommon.AvoidLocationAction');
    }

	super.ConstructCharacterAI();
}

///////////////////////////////////////

protected function bool ShouldReactToNonLethals()
{
    return true;
}

///////////////////////////////////////////////////////////////////////////////

simulated private function SpawnRestrainedHandcuffs()
{
	local class<HandheldEquipment> RestrainedHandcuffsClass;

	RestrainedHandcuffsClass = class<HandheldEquipment>(DynamicLoadObject(RestrainedHandcuffsClassName, class'Class'));
	assert(RestrainedHandcuffsClass != None);

	RestrainedHandcuffs = Spawn(RestrainedHandcuffsClass, self);
	assert(RestrainedHandcuffs != None);

	RestrainedHandcuffs.OnGivenToOwner();
}

simulated function HandheldEquipment GetRestrainedHandcuffs()
{
	return RestrainedHandcuffs;
}

///////////////////////////////////////
//
// Movement animation set swapping

simulated function EAnimationSet GetStandingInjuredAnimSet()				{ return kAnimationSetAICharacterInjuredStanding; }
simulated function EAnimationSet GetStandingInjuredUpStairsAnimSet()		{ return kAnimationSetAICharacterInjuredStandingUpStairs; }
simulated function EAnimationSet GetStandingInjuredDownStairsAnimSet()		{ return kAnimationSetAICharacterInjuredStandingDownStairs; }
simulated function EAnimationSet GetCrouchingInjuredAnimSet()				{ return kAnimationSetAICharacterInjuredCrouching; }

// overridden to allow AIs to determine if they should apply the patrol animation sets
simulated protected function SetAdditionalAnimSets()
{
	local PatrolGoal CurrentPatrolGoal;

	if (Level.NetMode != NM_Client)
	{
        // Default to not using the patrol anim set, until proven otherwise.
        if (Level.NetMode != NM_StandAlone)
        {
            ReplicatedShouldUsePatrolAnims = false;
        }

        // if we have a patrol, use that animation set as well.
		CurrentPatrolGoal = PatrolGoal(AI_Resource(CharacterAI).findGoalByName("Patrol"));

		// only set the animation set for the patrol if is active
		if ((CurrentPatrolGoal != None) && CurrentPatrolGoal.beingAchieved() && CurrentPatrolGoal.achievingAction.isRunning())
		{
			SetPatrolAnimMovementSet();

            // Set this replicated variable, so that pawns will use the
            // correct patrol anim set.
            if (Level.NetMode != NM_StandAlone)
            {
                ReplicatedShouldUsePatrolAnims = true;
            }
		}
	}
    // On the client, use the patrol animation set if the server says so.
    else if (ReplicatedShouldUsePatrolAnims)
    {
	    SetPatrolAnimMovementSet();
    }
}

function SetPatrolAnimMovementSet()
{
	// swap in patrol anim sets if we have a handgun or machine gun equipped, or nothing
	if ((GetActiveItem() != None) && GetActiveItem().IsA('Handgun'))
	{
		AnimSwapInSet(kAnimationSetEnemyPatrolHG);
	}
	else if ((GetActiveItem() != None) && GetActiveItem().IsA('MachineGun'))
	{
		AnimSwapInSet(kAnimationSetEnemyPatrolMG);
	}
	else if ((GetActiveItem() != None) && GetActiveItem().IsA('SubMachineGun'))
	{
		AnimSwapInSet(kAnimationSetEnemyPatrolSMG);
	}
	else if ((GetActiveItem() != None) && GetActiveItem().IsA('Shotgun'))
	{
		AnimSwapInSet(kAnimationSetEnemyPatrolSG);
	}
	else
	{
		// if we have nothing equipped, use the civilian patrol anim set
		AnimSwapInSet(kAnimationSetCivilianWalk);
	}
}

simulated function EAnimationSet GetEquipmentAimSet()
{
    // We have special compliant upper body aimposes
    if (IsCompliant())
    {
        return kAnimationSetCompliantLookAt;
    }
    else
    {
        return Super.GetEquipmentAimSet();
    }
}

function bool CanProcedurallyAnimateUpperBody()
{
    local HandheldEquipment Equipment;

    // Allow the character to look around with his head if he's handcuffed
    Equipment = GetActiveItem();
    if ((Equipment != None) && Equipment.IsA('IAmCuffed'))
    {
	    return true;
    }
    // We have special compliant upper body aimposes
    else if (IsCompliant())
    {
        return true;
    }
    else
    {
        return Super.CanProcedurallyAnimateUpperBody();
    }
}

// Returns the animation for the tactical aid that is currently affecting this pawn
// If we are compliant, we don't use the movement animations provided for SwatPawns (we use the compliant movement animations)
// In addition, for AIs the affected animations are played on the special channel
simulated function EAnimationSet GetAffectedByTacticalAidAnimSet()
{
	if (IsCompliant())
	{
		return kAnimationSetNull;
	}
	else
	{
		return Super.GetAffectedByTacticalAidAnimSet();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Movement Notifications

event NotifyStartedMoving()
{
    super.NotifyStartedMoving();
    if (IsCompliant())
    {
        SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_MovingWhileCompliant);
    }
}

event NotifyStoppedMoving()
{
    super.NotifyStoppedMoving();
    UnsetUpperBodyAnimBehavior(kUBABCI_MovingWhileCompliant);
}

///////////////////////////////////////////////////////////////////////////////
//
// Patrolling

protected function InitializePatrolling(PatrolList Patrol)
{
    // only give the enemy patrolling if we have a patrol
    if (Patrol != None)
    {
		// we are able to patrol
		CharacterAI.addAbility(new class'SwatAICommon.PatrolAction');

		// set the patrol on the commander (since the commander action hasn't been created yet)
		Commander.SetPatrol(Patrol);
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// IUseArchetype interface implementation

function InitializeFromArchetypeInstance()
{
    local CharacterArchetypeInstance Instance;

    Super.InitializeFromArchetypeInstance();

    Instance = CharacterArchetypeInstance(ArchetypeInstance);
    assert(Instance != None);   //ArchetypeInstance should always be set before InitializeFromArchetypeInstance() is called

	bIsAggressive = Instance.IsAggressive;
	InitialMorale = Instance.Morale;
	bTaserKillsMe = Instance.TaserKillsMe;
	bPepperKillsMe = Instance.PepperKillsMe;

	SetVoiceType(Instance);

    SwitchToMesh(Instance.Mesh);
    ReplicatedMesh = Instance.Mesh;

    // Some hostages/enemies use the SWAT officer skeleton with different clothing and skin. 
    // We need to handle this case separately because that skeleton has a different number of 
    // materials than the other enemy/hostage meshes. 
    if (Mesh == OfficerMesh)
    {
        Skins[0] = Instance.PantsMaterial;
        Skins[1] = Instance.FaceMaterial;
        Skins[2] = Instance.NameMaterial;
        Skins[3] = Instance.VestMaterial;

        ReplicatedSkins[0] = Skins[0];
        ReplicatedSkins[1] = Skins[1];
        ReplicatedSkins[2] = Skins[2];
        ReplicatedSkins[3] = Skins[3];
    }
    else
    {
        Skins[0] = Instance.FleshMaterial;
        Skins[1] = Instance.ClothesMaterial;

        ReplicatedSkins[0] = Skins[0];
        ReplicatedSkins[1] = Skins[1];
    }

    ReplicatedEquipment1Class = Instance.SelectedEquipment1Class;
    ReplicatedEquipment2Class = Instance.SelectedEquipment2Class;
    ReplicatedEquipment3Class = Instance.SelectedEquipment3Class;
    ReplicatedEquipment4Class = Instance.SelectedEquipment4Class;

    // Set bReplicatedIsFemale's value so that clients can properly answer
    // the IsFemale() function.
    bReplicatedIsFemale = IsFemale();
    mplog(self$"---SwatAICharacter::InitializeFromArchetypeInstance(), bReplicatedIsFemale was set to "$bReplicatedIsFemale$" on the server");

    DropToGround();
}

private function SetVoiceType(CharacterArchetypeInstance Instance)
{
	local SwatAIRepository SwatAIRepo;

	assert(Instance != None);

	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	assert(SwatAIRepo != None);
	
	CharacterType = Instance.CharacterType;
	assert(CharacterType != '');

	if (Instance.VoiceTypeOverride != '')
	{
		assertWithDescription(SwatAIRepo.VerifyVoiceTypeExists(Instance.VoiceTypeOverride), "SwatAICharacter::SetVoiceType - VoiceTypeOverride ("$Instance.VoiceTypeOverride$") specified in archetype instance " $ Instance.Name $" not found!  Check your spelling in the Archetype .ini file!");

		VoiceType = Instance.VoiceTypeOverride;
	}
	else
	{
		assertWithDescription(SwatAIRepo.VerifyCharacterTypeExists(Instance.CharacterType), "SwatAICharacter::SetVoiceType - CharacterType ("$Instance.CharacterType$") specified in archetype instance " $ Instance.Name $" not found!  Check your spelling in the Archetype .ini file!");
				
		VoiceType = SwatAIRepo.GetVoiceTypeForCharacterType(Instance.CharacterType);
	}

	assert(VoiceType != '');

	// our tag is also our voice type
	log(Name $ " VoiceType is: " $ VoiceType);
	Tag = VoiceType;
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function name GetVoiceType()
{
	return VoiceType;
}

function float GetInitialMorale()
{
	return InitialMorale;
}

function bool IsAggressive()
{
	return bIsAggressive;
}

function bool TaserKillsMe() {
	return bTaserKillsMe;
}

function bool PepperKillsMe() {
	return bPepperKillsMe;
}

simulated function bool IsFemale()
{
	local SwatAIRepository SwatAIRepo;

    // If we're a client, the server tells us whether or not this AI is a
    // female via the replicated bReplicatedIsFemale variable.
    if (Level.NetMode == NM_Client)
    {
        return bReplicatedIsFemale;
    }
    // Otherwise, we're in stand-alone, or we're a server
    else
    {
	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	assert(SwatAIRepo != None);

	// TODO - remove character type doesn't equal none test when we don't do the AnimLoadAnimPackages twice.
	return ((CharacterType != '') && SwatAIRepo.IsAFemaleCharacterType(CharacterType));
}
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization Functions

function DropToGround()
{
    // so we get a base
	SetPhysics(PHYS_Falling);
}

// returns a specific anim group name based on a config variable
// determine whether we're female based on our character type
simulated function array<string> GetAnimPackageGroups()
{
    if (Level.GetEngine().EnableDevTools)
        log( self$"---SwatAICharacter::GetAnimPackageGroups()." );

	assertWithDescription((FemaleAnimGroups.Length == MaleAnimGroups.Length), "SwatAICharacter::GetAnimPackageGroups - MaleAnimGroups length ("$MaleAnimGroups.Length$") does not match FemaleAnimGroups length ("$FemaleAnimGroups.Length$")");

    if (Level.GetEngine().EnableDevTools)
    {
        log( "...FemaleAnimGroups.Length="$FemaleAnimGroups.Length );
        log( "...MaleAnimGroups.Length  ="$MaleAnimGroups.Length );
    }

	if (IsFemale())
	{
		return FemaleAnimGroups;
	}
	else
	{
		return MaleAnimGroups;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Death

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
    Super.Died(Killer, damageType, HitLocation, HitMomentum);

	// notify the hive of our death
	SwatAIRepository(Level.AIRepo).GetHive().NotifyAIDied(self);
}

function float GetIncapacitatedDamageAmount()
{
	return IncapacitatedHealthAmount;
}

///////////////////////////////////////////////////////////////////////////////
//
// Dazing

private function bool CantBeDazed()
{
	return HasProtection('IProtectFromSting') || !IsConscious();
}

private function ApplyDazedEffect(SwatProjectile Grenade, Vector SourceLocation, float AIStingDuration)
{
	LastTimeStung = Level.TimeSeconds;
	StungDuration = AIStingDuration;
	
	GetCommanderAction().NotifyStung(Grenade, SourceLocation, StungDuration);
}

private function DirectHitByGrenade(Pawn Instigator, float Damage, float AIStingDuration)
{
	if ( CantBeDazed() )
        return;

	if (Damage > 0.0)
		TakeDamage(Damage, Instigator, Location, vect(0.0, 0.0, 0.0),
				   class<DamageType>(DynamicLoadObject("SwatEquipment.HK69GrenadeLauncher", class'Class')));

	ApplyDazedEffect(None, Location, AIStingDuration);
}

///////////////////////////////////////////////////////////////////////////////
//
// IReactToDazingWeapon implementation

function ReactToLessLeathalShotgun(
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
    if ( CantBeDazed() )
        return;

	ApplyDazedEffect(None, Location, AIStingDuration);
}

// Triple baton rounds are launched from the grenade launcher but are handle differently than a direct hit from a launched grenade
function ReactToGLTripleBaton(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
    DirectHitByGrenade(Instigator, Damage, AIStingDuration);
}

// React to a direct hit from a grenade launched from the grenade launcher
function ReactToGLDirectGrenadeHit(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
    DirectHitByGrenade(Instigator, Damage, AIStingDuration);
}

function ReactToMeleeAttack(
	class<DamageType> MeleeDamageType,
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
    if ( CantBeDazed() )
        return;

	// Only apply damage if the damage wont kill the target. You can't kill someone with the melee attack.
    if (Damage > 0.0 && Damage < Health)
        TakeDamage(Damage, Instigator, Location, vect(0.0, 0.0, 0.0), MeleeDamageType);

	ApplyDazedEffect(None, Location, AIStingDuration);
}

///////////////////////////////////////////////////////////////////////////////
//
// IReactToFlashbangGrenade implementation

function ReactToFlashbangGrenade(
    SwatGrenadeProjectile Grenade, 
	Pawn  Instigator,
    float Damage, 
    float DamageRadius, 
    Range KarmaImpulse, 
    float KarmaImpulseRadius, 
    float StunRadius,
    float PlayerStunDuration,
    float AIStunDuration,
    float MoraleModifier)
{
    local vector Direction, GrenadeLocation;
    local float Distance;
    local float Magnitude;

    if ( HasProtection( 'IProtectFromFlashbang' ) )
    {        
        return;
    }

	if (IsConscious())
	{
		if (Grenade != None)
		{
			GrenadeLocation = Grenade.Location;
			Direction       = Location - Grenade.Location;
			Distance        = VSize(Direction);
			if (Instigator == None)
				Instigator = Pawn(Grenade.Owner);
		}
		else
		{
			// Handle cheat commands and unexpecteed pathological cases
			GrenadeLocation = Location;
			Distance = 0;
			if (Instigator != None)
				Direction = Location - Instigator.Location;
			else
				Direction = Location; // just for completeness, this should never
			                          // be reached in practice, except for during debug testing
		}

		//damage - Damage should be applied constantly over DamageRadius
		if (Distance <= DamageRadius)
		{
			//event Actor::
			//  TakeDamage(int Damage,  Pawn EventInstigator,   vector HitLocation, vector Momentum,    class<DamageType> DamageType    );
				TakeDamage(Damage,      Instigator,				GrenadeLocation,    vect(0,0,0),        class'Engine.GrenadeDamageType' );
		}

		//apply karma impulse to ragdolls
		if (!isConscious())
		{
			//karma impulse - Karma impulse should be applied linearly from KarmaImpulse.Max to KarmaImpulse.Min over KarmaImpulseRadius
			if (Distance <= KarmaImpulseRadius)
			{
				Magnitude = Lerp(Distance / KarmaImpulseRadius, KarmaImpulse.Max, KarmaImpulse.Min);

				//native final function Actor::
				//  KAddImpulse(vector Impulse, vector Position, optional name BoneName );
#if WITH_KARMA
					KAddImpulse(Direction, Normal(Direction) * Magnitude);
#endif
			}
		}

		if (Distance <= StunRadius)
		{
			assert(AIStunDuration > 0.0);

			LastTimeFlashBanged = Level.TimeSeconds;
			FlashBangedDuration = AIStunDuration;

			GetCommanderAction().NotifyFlashbanged(GrenadeLocation, AIStunDuration);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// IReactToCSGas implementation

function ReactToCSGas(Actor GasContainer, float Duration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor)
{
    if ( HasProtection( 'IProtectFromCSGas' ) )
    {        
        return;
    }

	if (IsConscious())
	{
		LastTimeGassed = Level.TimeSeconds;
		GassedDuration = Duration;

		GetCommanderAction().NotifyGassed(GasContainer.Location, Duration);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// IReactToStingGrenade implementation

function ReactToStingGrenade(
    SwatProjectile Grenade, 
	Pawn  Instigator,
    float Damage, 
    float DamageRadius, 
    Range KarmaImpulse, 
    float KarmaImpulseRadius, 
    float StingRadius,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
    float MoraleModifier)
{
    local float Distance;

    if ( Grenade == None || CantBeDazed() )
        return;

	Distance = VSize(Location - Grenade.Location);

	//damage - Damage should be applied constantly over DamageRadius
	if ( Distance <= DamageRadius )
	{
		if ( Instigator == None )
			Instigator = Pawn(Grenade.Owner);

		TakeDamage(Damage, Instigator, Grenade.Location, vect(0.0, 0.0, 0.0), class'Engine.GrenadeDamageType');
	}

	if ( Distance <= StingRadius )
		ApplyDazedEffect(Grenade, Grenade.Location, AIStingDuration);
}

//
// ICanBePepperSprayed implementation
//

function ReactToBeingPepperSprayed(Actor PepperSpray, float PlayerDuration, float AIDuration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor)
{
    if ( HasProtection( 'IProtectFromPepperSpray' ) )
    {
        return;
    }
    
	if (IsConscious())
	{
	    LastTimePepperSprayed = Level.TimeSeconds;
		PepperSprayedDuration = AIDuration;
    
		GetCommanderAction().NotifyPepperSprayed(PepperSpray.Location, AIDuration);
	}
}

//
// ICanBeTased implementation
//

function ReactToBeingTased(Actor Taser, float PlayerDuration, float AIDuration)
{
	if (IsConscious())
	{
	    LastTimeTased = Level.TimeSeconds;
		TasedDuration = AIDuration;

		GetCommanderAction().NotifyTased(Taser.Location, AIDuration);
	}
}

//returns false if the ICanBeTased has some inherent protection from Taser, ie. HeavyArmor
simulated function bool IsVulnerableToTaser()
{
    return true;    //AICharacters can't be protected from Taser
}

///////////////////////////////////////////////////////////////////////////////
//
// IReactToC2Detonation implementation

function ReactToC2Detonation(Actor C2Charge, float StunRadius, float AIStunDuration)
{
	if (IsConscious())
	{
		LastTimeStunnedByC2 = Level.TimeSeconds;
		StunnedByC2Duration = AIStunDuration;

		GetCommanderAction().NotifyStunnedByC2Detonation(C2Charge.Location, AIStunDuration);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// For testing if the AI is under the effects of a tactical aid

simulated native function bool IsFlashbanged();
simulated native function bool IsGassed();
simulated native function bool IsPepperSprayed();
simulated native function bool IsStung();
simulated native function bool IsTased();
simulated native function bool IsStunnedByC2();
simulated native function bool IsStunned();

///////////////////////////////////////////////////////////////////////////////

//
// ISwatAICharacter interface overrides
//

simulated function SetCanBeArrested(bool Status)
{
    bCanBeArrested = Status;
}

//
// ICanBeArrested interface overrides
//

// returns true if we're compliant
simulated function bool CanBeArrestedNow()
{
    return bCanBeArrested && !IsArrested() && !IsBeingArrestedNow() && class.static.checkConscious(self);
}

function OnArrestBegan(Pawn Arrester)
{
    Super.OnArrestBegan(Arrester);

	GetCommanderAction().NotifyBeginArrest(Arrester);
}

function OnArrestInterrupted(Pawn Arrester)
{
    Super.OnArrestInterrupted(Arrester);

	if (IsConscious())
		GetCommanderAction().NotifyArrestInterrupted();
}

simulated function OnArrestedSwatPawn(Pawn Arrester)
{
    local HandheldEquipment thePendingItem;
    local HandheldEquipmentModel theThirdPersonModel;

    mplog( self$"---SwatAICharacter::OnArrestedSwatPawn(). Arrester="$Arrester );

    Super.OnArrestedSwatPawn(Arrester);

    // If we are on the server in a multiplayer game, make the IAmCuffed's
    // third person model replicatable, so clients will see it. On clients in
    // COOP mode, AI's don't really equip their IAmCuffed's. They see the
    // "getting cuffed" animation, but only because that anim itself is
    // replicated from the server. As a result, they're not really equipping
    // the IAmCuffed's, so we have to replicate the server's ThirdPersonModel
    // for the IAmCuffed to the clients.
    if ( Level.IsCOOPServer )
    {
        thePendingItem = GetPendingItem();
        if ( thePendingItem != None )
        {
            theThirdPersonModel = thePendingItem.GetThirdPersonModel();
            if ( theThirdPersonModel != None )
            {
                theThirdPersonModel.RemoteRole = ROLE_DumbProxy;
            }
        }
    }

    bCanBeArrested = false;
    ChangeAnimation();

	// use the slowest rotation rates when we're arrested
	AnimSetRotationUrgency(kARU_Normal);
	AnimSetAnimAimRotationUrgency(kAARU_Normal);
}


//
// IReactToThrownGrenades interface overrides
//

simulated function NotifyGrenadeThrown(SwatGrenadeProjectile ThrownGrenade)
{
	GetCommanderAction().NotifyGrenadeThrown(ThrownGrenade);
}


///////////////////////////////////////////////////////////////////////////////
//
// Awareness

private function CreateAwareness()
{
    Awareness = class'SwatAIAwareness.AwarenessFactory'.static.CreateAwarenessForPawn(self);
}

private function TermAwareness()
{
    // Terminate the awareness object
    Awareness.Term();
    Awareness = None;
}

// Implements ISwatAI::GetAwareness
function AwarenessProxy GetAwareness()
{
    return Awareness;
}

function DisableAwareness()
{
	bAwarenessDisabled = true;
}

function EnableAwareness()
{
	bAwarenessDisabled = false;
}

// tick the awareness, and reset the awareness update counter
native function ForceUpdateAwareness();

///////////////////////////////////////////////////////////////////////////////

//tcohen: This is a fail-safe mechanism in case an AI falls out of the world.
//  In some cases, this would make it impossible for the player to get a perfect
//  score, through no fault of their own.  Designers should prevent these cases,
//  but it may still be possible for it to happen after ship.  So here, if
//  an AI falls out of the world, we'll make sure that they are arrested and
//  reported.
simulated event FellOutOfWorld(eKillZType KillType)
{
    local SwatGameInfo Game;
    local SwatGamePlayerController SGPC;

    Game = SwatGameInfo(Level.Game);
    if (Game == None)
        return;             //we're on a client, or at least there's nothing we can do about it

    if (!IsArrested())
        Game.GameEvents.PawnArrested.Triggered(self, None);

    if (!HasBeenReportedToTOC())
        Game.GameEvents.ReportableReportedToTOC.Triggered(self, None);

    // On a client, if an AI falls out of the world this client won't be able
    // to report the AI, which could affect scoring, completing the mission,
    // etc. If this happens, we RPC to the server and the server auto-reports
    // the AI.
    if ( Level.NetMode == NM_Client )
    {
        SGPC = SwatGamePlayerController(Level.GetLocalPlayerController());
        if ( SGPC != None )
            SGPC.ServerRequestInteract( self, self.UniqueID() );
    }

    Super.FellOutOfWorld(KillType);
}

///////////////////////////////////////////////////////////////////////////////

function OnEscaped()
{
	SwatGameInfo(Level.Game).GameEvents.SuspectEscaped.Triggered(self);
}

defaultproperties
{
	OfficerMesh=Mesh'SWATMaleAnimation2.SwatOfficer'
    bNoRepMesh=false
	bReplicateAnimations=true
    DesiredAIEquipment=AIE_Invalid
}
