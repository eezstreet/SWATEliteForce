///////////////////////////////////////////////////////////////////////////////
// SquadMoveToAction.uc - SquadMoveToAction class
// this action is used to organize the Officer's MoveTo behavior

class SquadMoveToAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) vector			Destination;

// behaviors we use
var private array<MoveToGoal>	MoveToGoals;

// internal
var private LevelInfo			Level;

const kMinDistanceToReplyToOrder = 100.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	ClearOutMoveToGoals();
}

private function ClearOutMoveToGoals()
{
	while (MoveToGoals.Length > 0)
	{
		if (MoveToGoals[0] != None)
		{
			MoveToGoals[0].Release();
			MoveToGoals[0] = None;
		}

		MoveToGoals.Remove(0, 1);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our move to goals fail, we succeed so we don't get reposted!
	if (goal.IsA('MoveToGoal'))
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////

latent function MoveOfficersToDestination()
{
	local int PawnIterIndex, MoveToIndex;
	local Pawn PawnIter;
	local NavigationPoint ClosestPointToDestination;
	local name DestinationRoomName;
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	
	DestinationRoomName       = SwatAIRepo.GetClosestRoomNameToPoint(Destination, CommandGiver);
	yield();

	// find the closest navigation point, but don't use any doors
	ClosestPointToDestination = SwatAIRepo.GetClosestNavigationPointInRoom(DestinationRoomName, Destination,,,'Door');
	assert(ClosestPointToDestination != None);
	yield();

	if (resource.pawn().logTyrion)
		log(Name $ " - DestinationRoomName is: " $ DestinationRoomName $ " ClosestPointToDestination: " $ ClosestPointToDestination $ " Destination: " $ Destination);

	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		MoveToGoals[MoveToIndex] = new class'MoveToGoal'(AI_Resource(PawnIter.characterAI), ClosestPointToDestination);
		assert(MoveToGoals[MoveToIndex] != None);
		MoveToGoals[MoveToIndex].AddRef();
			
		MoveToGoals[MoveToIndex].PostGoal(self);

		++MoveToIndex;
	}

	waitForAllGoalsInList(MoveToGoals);

	// cleanup!
	ClearOutMoveToGoals();
}

function TriggerRepliedMoveToSpeech()
{
	local Pawn FirstOfficer;

	FirstOfficer = GetFirstOfficer();
	if (VSize2D(Destination - FirstOfficer.Location) > kMinDistanceToReplyToOrder)
	{
		ISwatOfficer(FirstOfficer).GetOfficerSpeechManagerAction().TriggerRepliedMoveToSpeech();
	}
}

function TriggerCompletedMoveToSpeech()
{
	ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerCompletedMoveToSpeech();
}

state Running
{
Begin:
	Level = resource.pawn().Level;
	assert(Level != None);
		
	TriggerRepliedMoveToSpeech();

	WaitForZulu();

	MoveOfficersToDestination();

	TriggerCompletedMoveToSpeech();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadMoveToGoal'
}