///////////////////////////////////////////////////////////////////////////////
// SwatWeaponAction.uc - SwatWeaponAction class
// The base Action class for all Swat Tyrion Weapon Actions

class SwatWeaponAction extends Tyrion.AI_WeaponAction
	native
    dependson(ISwatEnemy);
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;
import enum AIEquipment from ISwatAICharacter;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var protected LevelInfo Level;
var protected Pawn		m_pawn;

const kLowSkillLevelErrorAngle    = 0.2079;     // 12 degrees
const kMediumSkillLevelErrorAngle = 0.1392;     // 8  degrees
const kHighSkillLevelErrorAngle   = 0.0698;     // 4  degrees

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	m_Pawn = AI_WeaponResource(r).m_pawn;
    assert(m_Pawn != None);

	Level = m_Pawn.Level;
	assert(Level != None);

    super.initAction(r, goal);
}

///////////////////////////////////////////////////////////////////////////////
//
// Accuracy

// @TODO: Crombie
// currently just for enemies! 
// UPDATE: Not used for now!
function vector GetAimSpot(vector vTargetLocation, vector vProjStart)
{
    local vector vAimSpot;

    vAimSpot  = vTargetLocation;
    vAimSpot += GetSkillLevelAimErrorOffset(vTargetLocation, vProjStart);    

    return vAimSpot;
}

function vector GetSkillLevelAimErrorOffset(vector vTargetLocation, vector vProjStart)
{
    local float TargetDistance, OffsetRadius, OffsetAngle;
    local vector vSkillLevelAimErrorOffset;

    OffsetAngle    = GetOffsetAngleForEnemy(ISwatEnemy(m_Pawn).GetEnemySkill());
    TargetDistance = VSize(vTargetLocation - vProjStart);
    OffsetRadius   = sin(OffsetAngle) * TargetDistance;

    vSkillLevelAimErrorOffset = VRand() * (OffsetRadius * FRand());
    return vSkillLevelAimErrorOffset;
}

function float GetOffsetAngleForEnemy(EnemySkill EnemySkill)
{
    switch(EnemySkill)
    {
        case EnemySkill_Low:
            return kLowSkillLevelErrorAngle;
        case EnemySkill_Medium:
            return kMediumSkillLevelErrorAngle;
        case EnemySkill_High:
            return kHighSkillLevelErrorAngle;
        default:
            assert(false);
            return 0.0;
    }
}

function bool HasWeaponEquipped()
{
	assert(m_Pawn != None);

	return (m_Pawn.GetActiveItem() != None);
}

///////////////////////////////////////////////////////////////////////////////
//
// Random Aiming

latent function AimAndHoldAtPoint(vector Point, float MinPauseTime, float MaxPauseTime)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        LatentAimAtPoint(Point);

        sleep(RandRange(MinPauseTime, MaxPauseTime));
    }
	else
	{
		warn(m_Pawn.Name $ " cannot aim " $ m_Pawn.GetActiveItem() $ " at Point: " $ Point);
	}
}

final latent function LatentAimAtPoint(vector Point)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        ISwatAI(m_pawn).AimAtPoint(Point);

        // wait until we aim at what we want to and have a weapon equipped
        while ((! ISwatAI(m_pawn).AnimIsAimedAtDesired() && HasWeaponEquipped()) ||
			    ISwatAI(m_Pawn).AnimAreAimingChannelsMuted())
        {
//			log("aiming at point update - AnimIsAimedAtDesired: " $ ISwatAI(m_pawn).AnimIsAimedAtDesired() $ " HasWeaponEquipped: " $ HasWeaponEquipped() $ " AnimAreAimingChannelsMuted: " $ ISwatAI(m_Pawn).AnimAreAimingChannelsMuted());

            yield();
        }
    }
	else
	{
		warn(m_Pawn.Name $ " cannot aim " $ m_Pawn.GetActiveItem() $ " at Point: " $ Point);
	}
}

final function AimAtPoint(vector Point)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredPoint(Point))
    {
        ISwatAI(m_pawn).AimAtPoint(Point);
    }
}

static function bool IsAThreatBasedOnAim(Pawn PotentialThreat, Pawn Target)
{
	local HandheldEquipment ActiveItem;
	assert(PotentialThreat != None);

	// if the potential threat does not have a weapon, he's not a threat
	ActiveItem = PotentialThreat.GetActiveItem();
	if ((ActiveItem == None) || ! ActiveItem.IsA('FiredWeapon'))
		return false;

	if (Target.IsA('Pawn'))
	{
		return true;
	}
	else
	{
		return false;
	}
}

final function UpdateThreatToTarget(Actor Target)
{
	local Pawn TargetPawn;

	TargetPawn = Pawn(Target);

	// only update threat if both source and target are alive
	if (class'Pawn'.static.checkConscious(m_Pawn) && class'Pawn'.static.checkConscious(TargetPawn) && class'SwatWeaponAction'.static.IsAThreatBasedOnAim(m_Pawn, TargetPawn))
	{
		if (m_Pawn.IsA('SwatEnemy') && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}

		if (TargetPawn.IsA('SwatAI'))
		{
			// we let the target pawn's threat sensor know that we're trying to aim at them!
			SwatCharacterResource(TargetPawn.characterAI).ThreatenedSensorAction.UpdateThreatFrom(m_Pawn);
		}
	}
}

final latent function LatentAimAtActor(Actor Target)
{
    // only aim at if if we can
    if (ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Target) && HasWeaponEquipped())
    {
        ISwatAI(m_pawn).AimAtActor(Target);

        // wait until we aim at what we want to
        while ((! ISwatAI(m_pawn).AnimIsAimedAtDesired() && HasWeaponEquipped()) || 
			    ISwatAI(m_Pawn).AnimAreAimingChannelsMuted())
        {
//			log("aiming at actor update - AnimIsAimedAtDesired: " $ ISwatAI(m_pawn).AnimIsAimedAtDesired() $ " HasWeaponEquipped: " $ HasWeaponEquipped() $ " AnimAreAimingChannelsMuted: " $ ISwatAI(m_Pawn).AnimAreAimingChannelsMuted());

			UpdateThreatToTarget(Target);
            yield();
        }

		UpdateThreatToTarget(Target);
    }
}

final function AimAtActor(Actor Target)
{
	if (ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Target))
    {
		ISwatAI(m_pawn).AimAtActor(Target);
	}
}

latent function SetGunDirection( Actor Target ) // possible bug fixer
{
    local rotator rDirection;
    local vector  vDirection;
    local Coords  cTarget;
    local vector  vTarget;

    if( Target != none)
    {
		if (m_Pawn.IsA('SwatEnemy') && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}
		UpdateThreatToTarget(Target);
        cTarget = Target.GetBoneCoords('Bip01_Spine2');
        vTarget = cTarget.Origin;

        // Find the pitch between the gun and the target
        vDirection = vTarget - m_pawn.Location;
        rDirection = rotator(vDirection);

        //m_pawn.m_wWantedAimingPitch = rDirection.Pitch/256;
        //m_pawn.m_rFiringRotation = rDirection;
		ISwatAI(m_pawn).AimToRotation(rDirection);
    }
}
///////////////////////////////////////////////////////////////////////////////
//
// Firing

// Function provides basic use of the weapon
// currently just for SwatEnemy
latent function ShootWeaponAt(Actor Target)
{
    local FiredWeapon CurrentWeapon;

	assertWithDescription((Target != None), "SwatWeaponAction::ShootWeaponAt - Target is None!");
	assertWithDescription((m_Pawn != None), "SwatWeaponAction::ShootWeaponAt - m_Pawn is None!");

    CurrentWeapon = FiredWeapon(m_pawn.GetActiveItem());    

	// if the weapon's not empty, use it
    if (! CurrentWeapon.IsEmpty())
    {
		ISwatAI(m_Pawn).SetWeaponTarget(Target);
	
	    CurrentWeapon.LatentUse();

//		log("finished shooting at time " $ m_Pawn.Level.TimeSeconds);
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Weapon Switching

function FiredWeapon GetBackupWeapon()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		return ISwatEnemy(m_Pawn).GetBackupWeapon();
	}
	else
	{
		assert(m_Pawn.IsA('SwatOfficer'));

		return ISwatOfficer(m_Pawn).GetBackupWeapon();
	}
}

function FiredWeapon GetPrimaryWeapon()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		return ISwatEnemy(m_Pawn).GetPrimaryWeapon();
	}
	else
	{
		assert(m_Pawn.IsA('SwatOfficer'));

		return ISwatOfficer(m_Pawn).GetPrimaryWeapon();
	}
}

function FiredWeapon GetOtherWeapon()
{
	local FiredWeapon CurrentWeapon, PrimaryWeapon;

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
	PrimaryWeapon = GetPrimaryWeapon();

	if (CurrentWeapon == PrimaryWeapon)
		return GetBackupWeapon();
	else
		return PrimaryWeapon; 
}


latent function SwitchWeapons()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatEnemy(m_Pawn).ThrowWeaponDown();
        ISwatAICharacter(m_Pawn).SetDesiredAIEquipment( AIE_Backup );
	}

	GetBackupWeapon().LatentWaitForIdleAndEquip();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
