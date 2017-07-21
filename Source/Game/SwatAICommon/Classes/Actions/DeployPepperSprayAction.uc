///////////////////////////////////////////////////////////////////////////////

class DeployPepperSprayAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn          TargetPawn;

// behaviors we use
var private MoveToOpponentGoal  CurrentMoveToOpponentGoal;
var private AttackTargetGoal	CurrentAttackTargetGoal;

// the cuffs
var private HandheldEquipment PepperSpray;

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

	if ((PepperSpray != None) && !PepperSpray.IsIdle())
	{
		PepperSpray.AIInterrupt();
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

latent function EquipPepperSpray()
{
    PepperSpray = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_PepperSpray);
    assert(PepperSpray != None && PepperSpray.IsA('PepperSpray'));
    PepperSpray.LatentWaitForIdleAndEquip();
}

latent function UnequipPepperSpray()
{
    // re-equip our best weapon
    ISwatOfficer(m_Pawn).ReEquipFiredWeapon();
}

latent function AttackWithPepperSpray()
{
    // first we post the move goal
	CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(AI_Resource(m_Pawn.movementAI), achievingGoal.priority, TargetPawn);
	assert(CurrentMoveToOpponentGoal != None);
	CurrentMoveToOpponentGoal.AddRef();

	CurrentMoveToOpponentGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToOpponentGoal.postGoal(self);

    // now add the attack target goal
	CurrentAttackTargetGoal = new class'AttackTargetGoal'(AI_Resource(m_Pawn.weaponAI), achievingGoal.priority, TargetPawn);
	assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

	CurrentAttackTargetGoal.SetOrderedToAttackTarget(true);
	CurrentAttackTargetGoal.SetHavePerfectAim(true);

	CurrentAttackTargetGoal.postGoal(self);

	// wait until the character is affected by the pepperspray and we have the pepper spray equipped
	while (! ISwatAI(TargetPawn).GetCommanderAction().IsAffectedByPepperSpray() && PepperSpray.IsEquipped())
		yield();
	
	// wait until the Officer finishes using the pepperspray
	while (PepperSpray.IsBeingUsed())
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
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerDeployingPepperSpraySpeech();
	
    EquipPepperSpray();
    AttackWithPepperSpray();
    UnequipPepperSpray();

    succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'DeployPepperSprayGoal'
}
