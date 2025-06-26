///////////////////////////////////////////////////////////////////////////////
// ISwatEnemy.uc - ISwatEnemy interface
// we use this interface to be able to call functions on the SwatEnemy because we
// the definition of SwatEnemy has not been defined yet, but because SwatEnemy implements
// ISwatEnemy, we have a contract that says these functions will be implemented, and
// we can cast any Pawn pointer to an ISwatEnemy interface to call them

interface ISwatEnemy extends ISwatAICharacter
    native;

///////////////////////////////////////////////////////////////////////////////
//
// ISwatEnemy Enumerations

 enum EnemySkill
{
    EnemySkill_Low,
    EnemySkill_Medium,
    EnemySkill_High
};

enum EnemyState
{
    EnemyState_Unaware,
    EnemyState_Suspicious,
    EnemyState_Aware
};

///////////////////////////////////////////////////////////////////////////////
//
// State Data

function			StartInvestigating();
function 			StopInvestigating();
function bool		RollInvestigate();
function bool		RollBarricade();
function EnemyState GetCurrentState();
function			SetCurrentState(EnemyState NewState);
function EnemySkill GetEnemySkill();

function StartSprinting();
function StopSprinting();

///////////////////////////////////////////////////////////////////////////////
//
// Manager Accessors

function EnemyCommanderAction		GetEnemyCommanderAction();
function EnemySpeechManagerAction	GetEnemySpeechManagerAction();

///////////////////////////////////////////////////////////////////////////////
//
// Threat

function bool		IsAThreat();
function bool		IAmThreat();
function			BecomeAThreat();
function			UnbecomeAThreat(optional bool UseCooldown, optional float CooldownDuration);

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Usage

function FiredWeapon GetPrimaryWeapon();
function FiredWeapon GetBackupWeapon();

function PickUpWeaponModel(HandHeldEquipmentModel HHEModel);

// Tell the enemy to drop his active weapon, and give the
// falling weapon the specified impulse (in weapon-local space).
function DropActiveWeapon(optional vector WeaponSpaceDropDirection, optional float DropImpulseMagnitude);
// Tell the enemy to drop all of his weapons, if it is being shown, and give the
// falling weapon the specified impulse (in weapon-local space).
function DropAllWeapons(optional vector WeaponSpaceDropDirection, optional float DropImpulseMagnitude);
function ThrowWeaponDown();

//Get whether the suspect chooses to drop his/her weapon instantly when complying
function bool ShouldDropWeaponInstantly();

// Tell the enemy to drop any evidence he is holding
function DropAllEvidence(bool bIsDestroying);

function HandHeldEquipmentModel FindNearbyWeaponModel();

///////////////////////////////////////////////////////////////////////////////
//
// Spawner

function name SpawnedFromGroup();

function bool EnteredFleeSafeguard();

function bool HasEvidence();
