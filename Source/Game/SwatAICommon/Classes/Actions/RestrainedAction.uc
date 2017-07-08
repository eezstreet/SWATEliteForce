///////////////////////////////////////////////////////////////////////////////
// RestrainedAction.uc - RestrainedAction class
// The action that causes the AI to be restrained

class RestrainedAction extends LookAtOfficersActionBase
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// our cuffs
var private HandheldEquipment			Cuffs;

// behaviors we use
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

// copied from our goal
var(parameters)	Pawn					Restrainer;	// pawn that we will be working with

// config
var config float						MinSleepTimeBeforeLookingAtOfficers;
var config float						MaxSleepTimeBeforeLookingAtOfficers;

const kPostRestrainedGoalPriority      = 93;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

    InitLookAtOfficersActionBase(kUBABCI_RestrainedAction);
}

function cleanup()
{
	super.cleanup();

    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_RestrainedAction);

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	// only swap in the compliance animations if we're not arrested yet
	if (! ISwatAI(m_Pawn).IsArrested())
	{
		ISwatAI(m_Pawn).SwapInCompliantAnimSet();
		ISwatAI(m_Pawn).SetIdleCategory('Compliant');
	}

	if ((Cuffs != None) && !Cuffs.IsEquipped())
	{
		Cuffs.AIInterrupt();

		// if we are replicating the cuffing animation on the special channel to clients (this is the server),
		// then stop the animation so we don't equip the cuffs by mistake
		if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
		{
			m_Pawn.AnimStopSpecial();
		}
	}

	if (Restrainer.IsA('SwatOfficer') && Restrainer.GetActiveItem().IsA('Cuffs') && (Restrainer.GetActiveItem().IsBeingUsed() || Restrainer.GetActiveItem().IsBeingEquipped()) && (IAmUsedOnOther(Restrainer.GetActiveItem()).GetOther() == m_Pawn))
	{
		Restrainer.GetActiveItem().AIInterrupt();
	}

	// unlock our aim (if it hasn't been done already)
	ISwatAI(m_Pawn).UnlockAim();

	// re-enable collision avoidance (if it hasn't been done already)
	m_Pawn.EnableCollisionAvoidance();
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

// rotate to the rotation that is the opposite of the restrainer's rotation
function RotateToRestrainablePosition()
{
	local Rotator DesiredRestrainRotation;

	DesiredRestrainRotation = rotator(m_Pawn.Location - Restrainer.Location);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.Priority, DesiredRestrainRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);

	// make sure the rotation is set and lock it
	ISwatAI(m_Pawn).AimToRotation(DesiredRestrainRotation);
	ISwatAI(m_Pawn).LockAim();
}

latent function Restrain()
{
    mplog( "in RestrainedAction::Restrain()." );

	// make sure we don't have the weapon if we are an enemy
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatEnemy(m_Pawn).DropAllWeapons();
		ISwatEnemy(m_Pawn).DropAllEvidence(false);
	}

	Cuffs = ISwatAI(m_Pawn).GetRestrainedHandcuffs();
	assert(Cuffs != None);

	ISwatAI(m_Pawn).SetIdleCategory('Restrained');

    // If this is a multiplayer server, play the AI's 3rd person cuff equip
    // animation on the special channel (in addition to the equipment channel,
    // which happens via Cuffs.LatentWaitForIdleAndEquip()), so that the
    // animation is replicated to clients.
    if (Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer)
    {
        m_Pawn.AnimPlaySpecial(
			Cuffs.GetThirdPersonModel().HolderEquipAnimation, 
            Cuffs.GetThirdPersonModel().HolderEquipTweenTime, 
            Cuffs.GetThirdPersonModel().HolderAnimationRootBone,
            Cuffs.EquipAnimationRate);
    }

	Cuffs.LatentWaitForIdleAndEquip();

	// we are now officially arrested
	ICanBeArrested(m_Pawn).OnArrested(Restrainer);
}

function RestrainInterrupted()
{
	if (m_Pawn.logAI)
		log("restrain interrupted on " $ m_Pawn.Name);

	if (Cuffs != None)
	{	
		// complete immediately if the cuffs weren't equipped
		if (!Cuffs.IsEquipped())
		{
			instantFail(ACT_ErrorCodes.ACT_GENERAL_FAILURE);
		}
	}
}

state Running
{
    function BeginState()
    {
        Super.BeginState();

        Cuffs = ISwatAI(m_Pawn).GetRestrainedHandcuffs();
    }

 Begin:
	if (! ISwatAI(m_Pawn).IsArrested())
	{
		useResources(class'AI_Resource'.const.RU_ARMS);

		// don't move while being restrained
		m_Pawn.DisableCollisionAvoidance();

		RotateToRestrainablePosition();

		// handle the case where we have already been restrained, 
		Restrain();

		useResources(class'AI_Resource'.const.RU_LEGS);
	}

	// let the hive know
	SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().NotifyAIBecameRestrained(m_Pawn);
	ISwatAI(m_Pawn).GetCommanderAction().NotifyRestrained();
	
	// set our idle category
	ISwatAI(m_Pawn).SetIdleCategory('Restrained');

	// swap in the restrained anim set
	ISwatAI(m_Pawn).SwapInRestrainedAnimSet();

	if (achievingGoal.priority != kPostRestrainedGoalPriority)
	{
		// set the priority lower now so that any higher priority goal 
		// (incapacitation, stunned, injury) will take over
		achievingGoal.changePriority(kPostRestrainedGoalPriority);
		ClearDummyGoals();
	}

	while (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	// re-enable collision avoidance
	m_Pawn.EnableCollisionAvoidance();

	// unlock our aim
	ISwatAI(m_Pawn).UnlockAim();

	// sleep before we start looking at officers
	sleep(RandRange(MinSleepTimeBeforeLookingAtOfficers, MaxSleepTimeBeforeLookingAtOfficers));
    LookAtNearbyOfficers();

    succeed();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'RestrainedGoal'
}
