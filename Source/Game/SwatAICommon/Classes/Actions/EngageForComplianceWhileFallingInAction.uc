class EngageForComplianceWhileFallingInAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// FallInAction variables

// copied from our goal
var(parameters) Pawn					TargetPawn;

var private MoveInFormationGoal	CurrentMoveInFormationGoal;
var private AimAroundGoal		CurrentAimAroundGoal;
var private ReloadGoal			CurrentReloadGoal;
var private OrderComplianceGoal			CurrentOrderComplianceGoal;

var config float				FallInMinAimHoldTime; // 0.25
var config float				FallInMaxAimHoldTime; // 1

var private bool				bIsLowReady;

const kMinComplianceUpdateTime = 0.1;
const kMaxComplianceUpdateTime = 0.25;

///////////////////////////////////////////////////////////////////////////////
//
// Selection heuristic

function float selectionHeuristic( AI_Goal Goal )
{
	if(IsFallingIn())
	{
		return 1.0;
	}
	return 0.0;
}

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
	
	if (CurrentReloadGoal != None)
	{
		CurrentReloadGoal.Release();
		CurrentReloadGoal = None;
	}

	if(CurrentOrderComplianceGoal != None)
	{
		CurrentOrderComplianceGoal.Release();
		CurrentOrderComplianceGoal = None;
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

function ReloadWeapons()
{
	CurrentReloadGoal = new class'SwatAICommon.ReloadGoal'(AI_WeaponResource(m_Pawn.WeaponAI));
	assert(CurrentReloadGoal != None);
	CurrentReloadGoal.AddRef();	

	CurrentReloadGoal.postGoal( self );
}

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

private function OrderTargetToComply()
{
	assert(CurrentOrderComplianceGoal == None);

	CurrentOrderComplianceGoal = new class'OrderComplianceGoal'(AI_WeaponResource(m_Pawn.WeaponAI), TargetPawn);
	assert(CurrentOrderComplianceGoal != None);
	CurrentOrderComplianceGoal.AddRef();

	CurrentOrderComplianceGoal.postGoal(self);
}

state Running
{
Begin:
	SleepInitialDelayTime(true);		

	ReloadWeapons();
	if(TargetPawn.IsA('SwatHostage'))
	{	// Disregard hostages as being a threat, just aim around
		AimAround();
	}
	FollowPlayer();

	// don't succeed, stick around

	// check to see if we should be doing full body animations while not moving
 	OrderTargetToComply();
	
	while (! CurrentOrderComplianceGoal.hasCompleted())
	{
		sleep(RandRange(kMinComplianceUpdateTime, kMaxComplianceUpdateTime));
	}

	// Post a Fall In goal ?
	//(new class'FallInGoal'(AI_CharacterResource(m_Pawn.CharacterAI))).postGoal(self);

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageForComplianceGoal'
}