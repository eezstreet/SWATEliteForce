///////////////////////////////////////////////////////////////////////////////

class DeployGrenadeLauncherAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Actor TargetActor;		// takes precedence unless None
var(parameters) vector TargetLocation;

var Pawn TargetPawn;

// behaviors we use
var private MoveToOpponentGoal  CurrentMoveToOpponentGoal;
var private AttackTargetGoal	CurrentAttackTargetGoal;

// the weapon
var private FiredWeapon			GrenadeLauncher;

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

	if ((GrenadeLauncher != None) && !GrenadeLauncher.IsIdle())
	{
		GrenadeLauncher.AIInterrupt();
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

latent function EquipGrenadeLauncher()
{
    GrenadeLauncher = FiredWeapon(ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_PrimaryWeapon));
    if(GrenadeLauncher == None || !GrenadeLauncher.IsA('GrenadeLauncherBase'))
      GrenadeLauncher = FiredWeapon(ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_SecondaryWeapon));
    assert(GrenadeLauncher != None && GrenadeLauncher.IsA('GrenadeLauncherBase'));
    GrenadeLauncher.LatentWaitForIdleAndEquip();
}

latent function UnequipGrenadeLauncher()
{
    // re-equip our best weapon
    ISwatOfficer(m_Pawn).ReEquipFiredWeapon();
}

latent function AttackWithGrenadeLauncher()
{
	// currently you cannot attack an arbitrary point with a non-thrown weapon,
	// but this is where the code would go if that ever becomes possible (basically, write a
	// weapon behavior to shoot at "TargetLocation")
	if (TargetActor != None)
	{
		// first we post the move goal
		CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(AI_Resource(m_Pawn.movementAI), achievingGoal.priority, TargetActor);
		assert(CurrentMoveToOpponentGoal != None);
		CurrentMoveToOpponentGoal.AddRef();

		CurrentMoveToOpponentGoal.SetRotateTowardsPointsDuringMovement(true);

		CurrentMoveToOpponentGoal.postGoal(self);

		// now add the attack target goal
		CurrentAttackTargetGoal = new class'AttackTargetGoal'(AI_Resource(m_Pawn.weaponAI), achievingGoal.priority, TargetActor);
		assert(CurrentAttackTargetGoal != None);
		CurrentAttackTargetGoal.AddRef();

		CurrentAttackTargetGoal.SetOrderedToAttackTarget(true);
		CurrentAttackTargetGoal.SetHavePerfectAim(true);
		CurrentAttacktargetGoal.SetWaitTimeBeforeFiring(1.0f);
		CurrentAttackTargetGoal.postGoal(self);

		// wait for one shot to go off
		// (the problem is with the grenade launcher that it's hard to tell when the target has been hit so this logic is based on ammo)

		// wait for weapon to be reloaded if initially
		while ( GrenadeLauncher.NeedsReload() )
			yield();
		// wait for one shot to be fired
		while ( !GrenadeLauncher.NeedsReload() )
			yield();
		Sleep(0.5f);

		CurrentMoveToOpponentGoal.unPostGoal(self);
		CurrentMoveToOpponentGoal.Release();
		CurrentMoveToOpponentGoal = None;

		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
	else
		LOG("ERROR:" @ name @ "requires a target actor");
}

state Running
{
Begin:
	TargetPawn = Pawn(TargetActor);

	if (TargetPawn != None)
	{
	    // let the officers know that the target exists
		SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficersOfTarget(TargetPawn);
	}

    EquipGrenadeLauncher();
    AttackWithGrenadeLauncher();
    UnequipGrenadeLauncher();

    succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'DeployGrenadeLauncherGoal'
}
