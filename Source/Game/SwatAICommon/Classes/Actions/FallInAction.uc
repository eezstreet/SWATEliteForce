///////////////////////////////////////////////////////////////////////////////
// FallInAction.uc - FallInAction class
// The Action that causes an Officer AI to fall in around the player

class FallInAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// FallInAction variables

var private MoveInFormationGoal	CurrentMoveInFormationGoal;
var private AimAroundGoal		CurrentAimAroundGoal;

var config float				FallInMinAimHoldTime; // 0.25
var config float				FallInMaxAimHoldTime; // 1

var private bool				bIsLowReady;

const kCheckFullBodyUpdateRate = 0.5;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveInFormationGoal != None)
	{
		CurrentMoveInFormationGoal.Release();
		CurrentMoveInFormationGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	// in case it's not unset
	ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_FallIn);
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (goal == CurrentMoveInFormationGoal)
	{
		assert(m_Pawn.IsA('SwatOfficer'));
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCouldntCompleteMoveSpeech();

		// if the movement fails, we fail as well
		InstantFail(errorCode);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function AimAround()
{
	CurrentAimAroundGoal = new class'SwatAICommon.AimAroundGoal'(AI_WeaponResource(m_Pawn.WeaponAI), FallInMinAimHoldTime, FallInMaxAimHoldTime);
	assert(CurrentAimAroundGoal != None);
    CurrentAimAroundGoal.SetOnlyAimIfMoving(true);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.postGoal( self );
}

latent function FollowPlayer()
{
	CurrentMoveInFormationGoal = new class'SwatAICommon.MoveInFormationGoal'(AI_MovementResource(m_Pawn.MovementAI), 90);
	assert(CurrentMoveInFormationGoal != None);
	CurrentMoveInFormationGoal.AddRef();	

    // Let the aim around action perform the aiming and rotation for us
	CurrentMoveInFormationGoal.SetRotateTowardsPointsDuringMovement(false);
	CurrentMoveInFormationGoal.SetAcceptNearbyPath(true);

	CurrentMoveInFormationGoal.postGoal( self );
}

state Running
{
Begin:
	SleepInitialDelayTime(true);		

	AimAround();
	FollowPlayer();

	// don't succeed, stick around

	// check to see if we should be doing full body animations while not moving
 Loop:
	if (VSize(m_Pawn.Velocity) > 0.0)
	{
		if (! bIsLowReady)		// starts out false
		{
			ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_FallIn);
			bIsLowReady = true;
		}
	}
	else if (bIsLowReady)
	{
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_FallIn);
		bIsLowReady = false;
	}
	
	sleep(kCheckFullBodyUpdateRate);
	goto('Loop');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'FallInGoal'
}