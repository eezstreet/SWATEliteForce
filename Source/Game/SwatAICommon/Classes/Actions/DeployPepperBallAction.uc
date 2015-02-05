///////////////////////////////////////////////////////////////////////////////

class DeployPepperBallAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn			TargetPawn;

// behaviors we use
var private MoveToOpponentGoal  CurrentMoveToOpponentGoal;
var private AttackTargetGoal	CurrentAttackTargetGoal;

// the weapon
var private HandheldEquipment	CSBallLauncher;		// the pepper ball gun

// config
var config int					MaxNumberPepperBallsToFire;

///////////////////////////////////////////////////////////////////////////////
// 
// Cleanup

function cleanup()
{
    if (CurrentMoveToOpponentGoal != None)
    {
        CurrentMoveToOpponentGoal.Release();
        CurrentMoveToOpponentGoal = None;
    }
	
	if (CurrentAttackTargetGoal != None)
    {
        CurrentAttackTargetGoal.Release();
        CurrentAttackTargetGoal = None;
    }

	if ((CSBallLauncher != None) && !CSBallLauncher.IsIdle())
	{
		CSBallLauncher.AIInterrupt();
	}
	
	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

    super.cleanup();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
    super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
	    log(goal.name $ " was not achieved.  failing.");

    // just fail
    InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function EquipCSBallLauncher()
{
    CSBallLauncher = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_PrimaryWeapon);
	if(!CSBallLauncher.IsA('CSBallLauncher'))
	{
		// It's possibly a secondary weapon, so check that. --eez
		CSBallLauncher = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_SecondaryWeapon);
	}
    assert(CSBallLauncher != None && CSBallLauncher.IsA('CSBallLauncher'));
    CSBallLauncher.LatentWaitForIdleAndEquip();
}

latent function UnequipCSBallLauncher()
{
    // re-equip our best weapon
    ISwatOfficer(m_Pawn).ReEquipFiredWeapon();
}

latent function AttackWithCSBallLauncher()
{
	local int NumRemainingAmmoToStopFiring;

	// first we post the move goal
	CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(AI_Resource(m_Pawn.movementAI), achievingGoal.priority, TargetPawn);
	assert(CurrentMoveToOpponentGoal != None);
	CurrentMoveToOpponentGoal.AddRef();

	CurrentMoveToOpponentGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToOpponentGoal.postGoal(self);

	NumRemainingAmmoToStopFiring = FiredWeapon(CSBallLauncher).Ammo.RoundsRemainingBeforeReload() - MaxNumberPepperBallsToFire;

    // now add the attack target goal
	CurrentAttackTargetGoal = new class'AttackTargetGoal'(AI_Resource(m_Pawn.weaponAI), achievingGoal.priority, TargetPawn);
	assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

	CurrentAttackTargetGoal.SetOrderedToAttackTarget(true);
	CurrentAttackTargetGoal.SetHavePerfectAim(true);
	CurrentAttackTargetGoal.postGoal(self);

	// wait until the character is tased
	while (! ISwatAI(TargetPawn).IsGassed() &&  CSBallLauncher.IsEquipped() && (FiredWeapon(CSBallLauncher).Ammo.RoundsRemainingBeforeReload() > NumRemainingAmmoToStopFiring))
		yield();

	CurrentMoveToOpponentGoal.unPostGoal(self);
	CurrentMoveToOpponentGoal.Release();
	CurrentMoveToOpponentGoal = None;

	CurrentAttackTargetGoal.unPostGoal(self);
	CurrentAttackTargetGoal.Release();
	CurrentAttackTargetGoal = None;
}

state Running
{
Begin:
    // let the officers know that the target exists
    SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficersOfTarget(TargetPawn);

	// trigger the speech
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerDeployingPepperBallSpeech();

    EquipCSBallLauncher();
    AttackWithCSBallLauncher();
    UnequipCSBallLauncher();

    succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'DeployPepperBallGoal'
}
