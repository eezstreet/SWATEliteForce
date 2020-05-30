class EngageForComplianceWhileMovingToAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private MoveToActorGoal		        CurrentMoveToActorGoal;
var private AimAroundGoal		        CurrentAimAroundGoal;
var private OrderComplianceGoal			CurrentOrderComplianceGoal;

// copied from our goal
var(parameters) Pawn           	TargetPawn;
var(parameters) Vector			Destination;
var(parameters) Pawn 			OriginalCommandGiver;

// config variables
var config float				DistanceFromDestinationToStartWalking;

var config float				MoveToMinAimHoldTime; // 0.25
var config float				MoveToMaxAimHoldTime; // 1

const kMinComplianceUpdateTime = 0.1;
const kMaxComplianceUpdateTime = 0.25;


///////////////////////////////////////////////////////////////////////////////
//
// Cleanup/init

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	if(CurrentOrderComplianceGoal != None)
	{
		CurrentOrderComplianceGoal.Release();
		CurrentOrderComplianceGoal = None;
	}

	// in case we have been set to use covered paths
	ISwatAI(m_Pawn).DisableFavorCoveredPath();
}

function initAction(AI_Resource r, AI_Goal goal)
{
    super.initAction(r, goal);

    ISwatAI(m_pawn).EnableFavorCoveredPath(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor().Pawns);
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (goal == CurrentMoveToActorGoal)
	{
		assert(m_Pawn.IsA('SwatOfficer'));
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCouldntCompleteMoveSpeech();

		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function AimAround()
{
	CurrentAimAroundGoal = new class'SwatAICommon.AimAroundGoal'(weaponResource(), MoveToMinAimHoldTime, MoveToMaxAimHoldTime);
	assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetOnlyAimIfMoving(true);

	CurrentAimAroundGoal.postGoal( self );
}

latent function MoveToDestination()
{	
	local NavigationPoint ClosestPointToDestination;
	local name DestinationRoomName;
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	DestinationRoomName       = SwatAIRepo.GetClosestRoomNameToPoint(Destination, OriginalCommandGiver);
	yield();

	// find the closest navigation point, but don't use any doors
	ClosestPointToDestination = SwatAIRepo.GetClosestNavigationPointInRoom(DestinationRoomName, Destination,,,'Door');
	assert(ClosestPointToDestination != None);
	yield();


	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, ClosestPointToDestination);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetShouldWalkEntireMove(true);
	//CurrentMoveToActorGoal.SetWalkThreshold(DistanceFromDestinationToStartWalking);
	CurrentMoveToActorGoal.SetUseNavigationDistanceOnSensor(true);
	CurrentMoveToActorGoal.SetShouldSucceedWhenDestinationBlocked(true);

	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
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

	if(TargetPawn.IsA('SwatHostage'))
	{
		AimAround();
	}
	
	MoveToDestination();

 	OrderTargetToComply();
	
	while (! CurrentOrderComplianceGoal.hasCompleted())
	{
		sleep(RandRange(kMinComplianceUpdateTime, kMaxComplianceUpdateTime));
	}

	MoveToDestination();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageForComplianceWhileMovingToGoal'
}