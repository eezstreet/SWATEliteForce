///////////////////////////////////////////////////////////////////////////////
// SquadStackUpAction.uc - SquadStackUpAction class
// this action is used to organize the Officer's stack up

class SquadStackUpAction extends OfficerSquadAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

struct StackUpInfo
{
	var Pawn	Officer;
	var float	Weight;
	var int     PointIndex;
};

var private StackUpGoal				CurrentStackUpGoal;
var private array<StackUpGoal>		StackUpGoals;
var private array<StackedUpGoal>	StackedUpGoals;
var private array<StackUpPoint>		StackUpPoints;

// ordering
var private array<Pawn>				UnorderedOfficers;
var private array<Pawn>				OfficersInStackUpOrder;

var private array<Pawn>				MatchedOfficersToStackupPoints;

// behaviors we use
var private PickLockGoal			CurrentPickLockGoal;
var private CloseDoorGoal			CurrentCloseDoorGoal;

// automatically copied from our goal
var(parameters) Door				TargetDoor;
var(parameters) bool				bTriggerCouldntBreachLockedSpeech;

// constants
const kDistanceToUseClosestStackUpPoint = 150.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentStackUpGoal != None)
	{
		CurrentStackUpGoal.Release();
		CurrentStackUpGoal = None;
	}

	if (CurrentPickLockGoal != None)
	{
		CurrentPickLockGoal.Release();
		CurrentPickLockGoal = None;
	}

	if (CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}

	ClearOutStackUpGoals();
	ClearOutStackedUpGoals();
	ClearStackupPointClaims();
}

private function ClearOutStackUpGoals()
{
	while (StackUpGoals.Length > 0)
	{
		if (StackUpGoals[0] != None)
		{
			StackUpGoals[0].Release();
			StackUpGoals[0] = None;
		}

		StackUpGoals.Remove(0, 1);
	}
}

protected function ClearOutStackedUpGoals()
{
	while (StackedUpGoals.Length > 0)
	{
		if (StackedUpGoals[0] != None)
		{
			StackedUpGoals[0].unPostGoal(self);
			StackedUpGoals[0].Release();
			StackedUpGoals[0] = None;
		}

		StackedUpGoals.Remove(0, 1);
	}
}

protected function ClearStackupPointClaims()
{
	local int i;

	for(i=0; i<StackUpPoints.Length; ++i)
	{
		StackUpPoints[i].ClearClaims();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

// In the case of all SquadStackUpAction and its subclasses, we only want to match actions with 
//  goals that exactly match the satisfiesGoal (otherwise the SquadStackUpAndTryDoorAction
//  can satisfy the StackUpGoal, which isn't correct)
function float selectionHeuristic( AI_Goal goal )
{
	if (satisfiesGoal == goal.class)
	{
		return 1.0;
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessing Officers

function Pawn GetFirstOfficer()
{
	local Pawn Officer;
	local int i;

	if (OfficersInStackUpOrder.Length == 0)
	{
		return squad().pawns[0];
	}
	else
	{
		for(i=0; i<OfficersInStackUpOrder.Length; ++i)
		{
			Officer = OfficersInStackUpOrder[i];

			if(class'Pawn'.static.checkConscious(Officer))
			{
				return Officer;
			}
		}
	}

	// shouldn't get here
	assert(false);
	return None;
}

function Pawn GetSecondOfficer()
{
	local Pawn Officer;
	local int i;

	for(i=1; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

		if(class'Pawn'.static.checkConscious(Officer))
		{
			return Officer;
		}
	}

	// it's perfectly ok to return none here (unlike GetFirstOfficer)
	return None;
}

function Pawn GetThirdOfficer()
{
	// it's perfectly ok to return none here (unlike GetFirstOfficer)
	if (OfficersInStackUpOrder.Length >= 3)
	{
		return OfficersInStackUpOrder[2];
	}
	else
	{
		return None;
	}
}

function Pawn GetFourthOfficer()
{
	if (OfficersInstackUpOrder.Length == 4)
	{
		// it's perfectly ok to return none here (unlike GetFirstOfficer)
		return OfficersInStackUpOrder[3];
	}
	else
	{
		return None;
	}
}

function StackUpPoint GetStackupPointForOrderedOfficer(Pawn OrderedOfficer)
{
	local int i;

	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		if (OrderedOfficer == OfficersInStackUpOrder[i])
		{
			return StackUpPoints[i];
		}
	}

	// shouldn't get here
	assert(false);
	return None;
}

function int GetStackupPointIndexForOrderedOfficer(Pawn OrderedOfficer)
{
	local int i;

	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		if (OrderedOfficer == OfficersInStackUpOrder[i])
		{
			return i;
		}
	}

	// shouldn't get here
	assert(false);
	return -1;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function PickLock(bool bMoveToPostPickLockDestination)
{
	local Pawn Officer;
	local StackUpPoint OfficerStackUpPoint;
	local int i;

	assert(OfficersInStackUpOrder.Length > 0);
	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

		if (class'Pawn'.static.checkConscious(Officer) && (ISwatOfficer(Officer).GetItemAtSlot(SLOT_Toolkit) != None))
		{
			// we've found our officer
			break;
		}
	}

	// get the first stack up point (our safe location)
	if (bMoveToPostPickLockDestination)
	{
		OfficerStackUpPoint = ISwatDoor(TargetDoor).GetStackupPoints(CommandOrigin)[i];
		assert(OfficerStackUpPoint != None);
	}

	CurrentPickLockGoal = new class'PickLockGoal'(AI_Resource(Officer.characterAI), TargetDoor, OfficerStackUpPoint);
	assert(CurrentPickLockGoal != None);
	CurrentPickLockGoal.AddRef();

	CurrentPickLockGoal.postGoal(self);
	WaitForGoal(CurrentPickLockGoal);
	CurrentPickLockGoal.unPostGoal(self);

	CurrentPickLockGoal.Release();
	CurrentPickLockGoal = None;
}

// stacks up the first officer at the first stack up point
latent function StackUpOfficer(Pawn Officer, StackupPoint Destination)
{
	assert(class'Pawn'.static.checkConscious(Officer));
	assert(Destination != None);

	CurrentStackUpGoal = new class'SwatAICommon.StackUpGoal'(AI_CharacterResource(Officer.CharacterAI), Destination);
	assert(CurrentStackUpGoal != None);
	CurrentStackUpGoal.AddRef();

	CurrentStackUpGoal.postGoal( self );
	waitForGoal(CurrentStackUpGoal);
	CurrentStackUpGoal.unPostGoal( self );

	CurrentStackUpGoal.Release();
	CurrentStackUpGoal = None;

	PostStackedUpGoal(Officer, Destination);
}

// remove the pawn that has died from any of our lists
protected function NotifyPawnDied(Pawn pawn)
{
	local int i;

	super.NotifyPawnDied(pawn);

	for(i=0; i<UnorderedOfficers.Length; ++i)
	{
		if (UnorderedOfficers[i] == pawn)
		{
			UnorderedOfficers.Remove(i, 1);
			return;
		}
	}

	for(i=0; i<OfficersInStackupOrder.Length; ++i)
	{
		if (OfficersInStackupOrder[i] == pawn)
		{
			OfficersInStackupOrder.Remove(i, 1);
			StackupPoints[i].ClearClaims();
			return;
		}
	}
}

private function PopulateUnorderedOfficers()
{
	local int i;

	assert(UnorderedOfficers.Length == 0);

	for(i=0; i<squad().pawns.length; ++i)
	{
		UnorderedOfficers[UnorderedOfficers.Length] = squad().pawns[i];
	}
}

protected function int GetNumberLivingOfficersInSquad()
{
	return squad().pawns.length;
}

private function float DeflateWeightByCloserUnorderedOfficersTo(Pawn Officer, float OfficerNavDistanceToPoint, StackUpPoint Point)
{
	local int i;
	local float IterDistance, DeflatedDistance;
	local Pawn OfficerIter;

	assert(Officer != None);

	DeflatedDistance = OfficerNavDistanceToPoint;

	for(i=0; i<UnorderedOfficers.Length; ++i)
	{
		OfficerIter = UnorderedOfficers[i];

		IterDistance = OfficerIter.GetPathfindingDistanceToActor(Point, true);

		DeflatedDistance -= (OfficerNavDistanceToPoint - IterDistance);

//		log("DeflateDistanceByCloserUnorderedOfficersTo - OfficerNavDistanceToPoint: " $ OfficerNavDistanceToPoint $ " IterDistance: " $ IterDistance $ " OfficerIter: " $ OfficerIter.Name $ " DeflatedDistance: " $ DeflatedDistance);
	}

	return DeflatedDistance;
}

private function bool IsPositionedOnWrongSideOfDoor(Pawn Officer, StackUpPoint Destination)
{
	local bool IterPointDotDoorSign, OfficerDotDoorSign, OfficerIterDotDoorSign;
	local vector DoorDirection;
	local int i;
	local Pawn OfficerIter;

	DoorDirection = vector(TargetDoor.Rotation);

	IterPointDotDoorSign = ((DoorDirection Dot Normal(Destination.Location - TargetDoor.Location)) > 0.0);
	OfficerDotDoorSign   = ((DoorDirection Dot Normal(Destination.Location - Officer.Location)) > 0.0);

//	log(Officer.Name $ " IsPositionedOnWrongSideOfDoor - IterPointDotDoorSign: " $ IterPointDotDoorSign $ " OfficerDotDoorSign: " $ OfficerDotDoorSign);

	// if we're on the other side of the door from the stack up point
	if (IterPointDotDoorSign == OfficerDotDoorSign)
	{
//		log("UnorderedOfficers.Length is: " $ UnorderedOfficers.Length);

		// check to see if all the other officers are on the other side of the door from the stack up point
		for (i=0; i<UnorderedOfficers.Length; ++i)
		{
			OfficerIter = UnorderedOfficers[i];
			
			if ((OfficerIter != Officer) && class'Pawn'.static.checkConscious(OfficerIter))
			{
				OfficerIterDotDoorSign = ((DoorDirection Dot Normal(Destination.Location - OfficerIter.Location)) > 0.0);

//				log("OfficerIter: " $ OfficerIter $ " OfficerIterDotDoorSign: " $ OfficerIterDotDoorSign);

				// if the officer is on the other side of the door than the officer we're testing, we want to apply the penalty
				if (OfficerIterDotDoorSign != IterPointDotDoorSign)
				{
					return true;
				}
			}
		}
	}

	return false;
}

latent function DetermineOfficerStackupPoints()
{
	local int i, j, HighestWeightStackUpIndex;
	local Pawn BestOfficer;

	local array<StackupInfo> StackUpInfos;
	local StackUpInfo IterInfo;
	local float HighestWeight;

	local array<int> StackupInfosToRemove;

	for(j=0; j<UnorderedOfficers.Length; ++j)
	{
		IterInfo.Officer = UnorderedOfficers[j];

		for(i=0; i<StackUpPoints.Length && i<GetNumberLivingOfficersInSquad(); ++i)
		{
			if (! StackUpPoints[i].IsClaimedByOfficer())
			{
				IterInfo.PointIndex = i;
				IterInfo.Weight     = GetStackupWeightForOfficer(IterInfo.Officer, StackUpPoints[i]);

				StackUpInfos[StackUpInfos.Length] = IterInfo;
			}

			yield();
		}
	}

	while (StackUpInfos.Length > 0)
	{
		StackupInfosToRemove.Remove(0, StackupInfosToRemove.Length);

		for(i=0; i<StackUpInfos.Length; ++i)
		{
			if ((i == 0) || (StackUpInfos[i].Weight > HighestWeight))
			{
				HighestWeight             = StackUpInfos[i].Weight;
				BestOfficer               = StackUpInfos[i].Officer;
				HighestWeightStackUpIndex = StackUpInfos[i].PointIndex;
			}
		}

		MatchedOfficersToStackupPoints[HighestWeightStackUpIndex] = BestOfficer;

		for(i=0; i<StackUpInfos.Length; ++i)
		{
			if ((StackUpInfos[i].Officer == BestOfficer) || (StackUpInfos[i].PointIndex == HighestWeightStackUpIndex))
			{
				StackupInfosToRemove[StackupInfosToRemove.Length] = i;
			}
		}

		for(i=0; i<StackupInfosToRemove.Length; ++i)
		{
			StackUpInfos.Remove(StackupInfosToRemove[i]-i, 1);
		}
	}
}

event float GetStackupWeightForOfficer(Pawn Officer, StackupPoint Point)
{
	local float Weight;
	
//	log("checking weight for Officer "$Officer.Name$" to StackupPoint "$Point);

	Weight = Officer.GetPathfindingDistanceToActor(Point, true);

//	log("Weight starts at: " $ Weight );

	Weight = DeflateWeightByCloserUnorderedOfficersTo(Officer, Weight, Point);

//	log("Weight is now: " $ Weight );

	if (IsPositionedOnWrongSideOfDoor(Officer, Point))
	{
		Weight -= 512.0;
	}

//	log("Weight finishes as: " $ Weight);

	return Weight;
}

private function int GetUnorderedOfficerIndex(Pawn Officer)
{
	local int i;

	assert(Officer != None);
	assert(! IsOfficerOrdered(Officer));

	for(i=0; i<UnorderedOfficers.Length; ++i)
	{
		if (Officer == UnorderedOfficers[i])
		{
			return i;
		}
	}

	assert(false);
	return -1;
}

private function bool IsOfficerOrdered(Pawn Officer)
{
	local int i;

	assert(Officer != None);

	for(i=0; i<UnorderedOfficers.Length; ++i)
	{
		if (Officer == UnorderedOfficers[i])
		{
			return false;
		}
	}

	return true;
}

protected function bool ShouldFirstOfficerBeStackedUp()
{
	return true;
}

private function SetOrderedStackUpPointForOfficer(Pawn Officer, StackupPoint OfficerDestination)
{	
	local int i;
	local Pawn OfficerIter;

	if (Officer.logAI)
		log("SetOrderedStackUpPointForOfficer - Officer: " $ Officer.Name$" OfficerDestination: " $OfficerDestination.Name);

	OfficerDestination.SetClaimedByOfficer(Officer);

	// set the officers in stack up order based on the index of the stack up point
	for(i=0; i<StackUpPoints.Length; ++i)
	{
		if (StackUpPoints[i] == OfficerDestination)
		{
			OfficersInStackUpOrder[i] = Officer;
			break;
		}
	}

	// remove this guy from unordered.
	for(i=0; i<UnorderedOfficers.Length; ++i)
	{
		OfficerIter = UnorderedOfficers[i];
		assert(class'Pawn'.static.checkConscious(OfficerIter));

		if (OfficerIter == Officer)
		{
			UnorderedOfficers.Remove(i, 1);
			break;
		}
	}
}

private function PostStackUpGoalOnOfficer(Pawn Officer, StackUpPoint OfficerDestination, optional bool bRunToPoint)
{
	local int StackupGoalIndex;

	assert(class'Pawn'.static.checkConscious(Officer));
	assert(OfficerDestination != None);

	SetOrderedStackUpPointForOfficer(Officer, OfficerDestination);

	// post the stacked up goal on the officer
	if ((Officer != OfficersInStackupOrder[0]) || ShouldFirstOfficerBeStackedUp())
	{
		StackupGoalIndex = StackUpGoals.Length;
	
		StackUpGoals[StackupGoalIndex] = new class'SwatAICommon.StackUpGoal'(AI_CharacterResource(Officer.CharacterAI), OfficerDestination);
		assert(StackUpGoals[StackupGoalIndex] != None);
		StackUpGoals[StackupGoalIndex].AddRef();

		if (bRunToPoint)
			StackUpGoals[StackupGoalIndex].SetRunToStackupPoint(true);

		// need to set bWakeUpPoster to true so that any stack up goal that is replaced 
		// causes the WaitForAllGoalsInList to work (kinda hacky, but there's no good 
		// solution I can think of currently) [crombie]
		StackUpGoals[StackupGoalIndex].bWakeUpPoster = true;

		StackUpGoals[StackupGoalIndex].postGoal( self );

		PostStackedUpGoal(Officer, OfficerDestination);
	}
}

private function PopulateStackUpPoints()
{
	local int i;

	StackUpPoints = ISwatDoor(TargetDoor).GetStackupPoints(CommandOrigin);
	assertWithDescription((squad().pawns.length <= StackUpPoints.Length), "SquadStackUpAction::PopulateStackUpPoints - "$TargetDoor$" has less StackUpPoints ("$StackUpPoints.Length$") than squad members ("$squad().pawns.length$").  This is bad!");
	assert(StackUpPoints.Length == 4);

	for(i=0; i<StackUpPoints.Length; ++i)
	{
		assert(StackUpPoints[i] != None);
		StackUpPoints[i].ClearClaims();
	}
}

protected function bool IsOfficerAtSideOpenPoint(Pawn Officer)
{
	local bool bIsOnLeftSide;

	bIsOnLeftSide = ISwatDoor(TargetDoor).PointIsToMyLeft(CommandOrigin);
		
	return ISwatDoor(TargetDoor).IsOfficerAtSideOpenPoint(Officer, bIsOnLeftSide);
}

private function TestForAlreadyStackedUpOfficers()
{
	local int i, j, NumLivingOfficers;
	local Pawn OfficerIter;
	
    NumLivingOfficers = UnorderedOfficers.Length;
    assert(NumLivingOfficers <= StackUpPoints.Length);

	for(i=0; i<NumLivingOfficers; ++i)
	{
		for(j=0; j<UnorderedOfficers.Length; ++j)
		{
			OfficerIter = UnorderedOfficers[j];

			// an officer is already stacked up if they are at their stack up point,
			// or if they are at the correct side open point on the door
			if (OfficerIter.ReachedDestination(StackUpPoints[i]))
			{
				if (OfficerIter.logAI)
					log("OfficerIter ("$OfficerIter.Name$") is already stacked up at point index: " $ i);

				OfficersInStackUpOrder[i] = OfficerIter;
				StackUpPoints[i].SetClaimedByOfficer(OfficerIter);
				UnorderedOfficers.Remove(j, 1);

				PostStackedUpGoal(OfficerIter, StackUpPoints[i]);
				break;
			}
		}
	}
}

protected function bool AreOfficersAlreadyStackedUp()
{
	local int i;

	if (resource.pawn().logAI)
		log("OfficersInStackUpOrder.Length: " $ OfficersInStackUpOrder.Length $ " GetNumberLivingOfficersInSquad: " $ GetNumberLivingOfficersInSquad());

	// make sure each guy is in the officers in stack up order list
	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		if (! class'Pawn'.static.checkConscious(OfficersInStackUpOrder[i]))
		{
			return false;
		}
	}

	return (OfficersInStackUpOrder.Length >= GetNumberLivingOfficersInSquad());
}

function bool CanInteractWithTargetDoor()
{
	return (! TargetDoor.IsEmptyDoorWay() && TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !ISwatDoor(TargetDoor).IsBroken());
}

function bool IsDoorOpenTowardsStackupSide()
{
	local bool bStackUpOnLeft, bDoorOpenLeft;
	local ISwatDoor SwatTargetDoor;

	SwatTargetDoor = ISwatDoor(TargetDoor);

	if (!TargetDoor.IsEmptyDoorWay() && SwatTargetDoor.IsOpen() && !SwatTargetDoor.IsBroken())
	{
		bStackUpOnLeft = SwatTargetDoor.PointIsToMyLeft(CommandOrigin);
		bDoorOpenLeft  = SwatTargetDoor.IsOpenLeft();

		// if the door is open on the same side as where we're stacking up
		if (bStackUpOnLeft == bDoorOpenLeft)
		{
			return true;
		}
	}

	return false;
}

// tests to see if we have to actually do the stacking up.
// if everyone is already in place, returns true
protected function bool NeedsToStackUp()
{
	PopulateStackUpPoints();
	PopulateUnorderedOfficers();

	// see if anyone is at there stack up point
	TestForAlreadyStackedUpOfficers();

	// if everyone's already by a stack up point
	if (AreOfficersAlreadyStackedUp())
	{
		if (resource.pawn().logAI)
			log("AI believes everyone already stacked up.");

		return false;
	}

	return true;
}

protected function TriggerOrderedToStackUpReplySpeech()
{
	local Pawn ClosestOfficerToCommandGiver;

	ClosestOfficerToCommandGiver = GetClosestOfficerTo(CommandGiver, false, false);

	if (ClosestOfficerToCommandGiver != None)
	{
		// trigger a generic reply
		ISwatOfficer(ClosestOfficerToCommandGiver).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
	}
}

// generally, use this function to stack up the squad
protected latent function StackUpSquad(optional bool bTriggerGenericOrderReply)
{
	
	if (NeedsToStackUp())
	{
		if (bTriggerGenericOrderReply)
		{
			TriggerOrderedToStackUpReplySpeech();
		}

		InternalStackUpSquad();
	}
}

protected function bool ShouldRunToStackupPoint()
{
	return false;
}

// this should only be called directly if ShouldStackUp has been called
protected latent function InternalStackUpSquad()
{
	local int i;
	local Pawn OfficerIter;
	local StackUpPoint PointIter;

	DetermineOfficerStackupPoints();

	if (resource.pawn().logAI)
		log("MatchedOfficersToStackupPoints.Length is: " $ MatchedOfficersToStackupPoints.Length);

	// tell everybody to move unordered (for now)
	for(i=0; i<MatchedOfficersToStackupPoints.Length; ++i)
	{
		OfficerIter = MatchedOfficersToStackupPoints[i];
		PointIter   = StackupPoints[i];

		if (OfficerIter != None)
		{
			if (resource.pawn().logAI)
				log("posting initial stack up goal for " $ OfficerIter.Name $ " to go to " $ StackupPoints[i]);

			PostStackUpGoalOnOfficer(OfficerIter, PointIter, ShouldRunToStackupPoint());
		}
	}

	waitForAllGoalsInList(StackUpGoals);

	ClearOutStackUpGoals();
}

function PostStackedUpGoal(Pawn Officer, StackupPoint inStackupPoint)
{
	local int NextStackedUpGoalIndex;

	assert(inStackupPoint != None);
	assert(class'Pawn'.static.checkConscious(Officer));

	NextStackedUpGoalIndex = StackedUpGoals.Length;

	StackedUpGoals[NextStackedUpGoalIndex] = new class'StackedUpGoal'(AI_Resource(Officer.characterAI), inStackupPoint);
	assert(StackedUpGoals[NextStackedUpGoalIndex] != None);
	StackedUpGoals[NextStackedUpGoalIndex].AddRef();
	StackedUpGoals[NextStackedUpGoalIndex].postGoal(self);
}

protected latent function SwapStackUpPositions(Pawn OfficerOne, Pawn OfficerTwo)
{
	local int i, NewOfficerOneStackupPointIndex, NewOfficerTwoStackupPointIndex;
	local StackupPoint NewOfficerOneStackupPoint, NewOfficerTwoStackupPoint;

	assert(class'Pawn'.static.checkConscious(OfficerOne));
	assert(class'Pawn'.static.checkConscious(OfficerTwo));

	// get the stack up points for each officer, and clear the claims on the stackup points
	NewOfficerOneStackupPointIndex = GetStackupPointIndexForOrderedOfficer(OfficerTwo);
	NewOfficerOneStackupPoint      = StackupPoints[NewOfficerOneStackupPointIndex];
	assert(NewOfficerOneStackupPoint != None);

	NewOfficerTwoStackupPointIndex = GetStackupPointIndexForOrderedOfficer(OfficerOne);
	NewOfficerTwoStackupPoint      = StackupPoints[NewOfficerTwoStackupPointIndex];
	assert(NewOfficerTwoStackupPoint != None);

	// now clear the claims and reset the ordering of the officers
	NewOfficerOneStackupPoint.ClearClaims();
	OfficersInStackupOrder[NewOfficerOneStackupPointIndex] = OfficerOne;

	NewOfficerTwoStackupPoint.ClearClaims();
	OfficersInStackupOrder[NewOfficerTwoStackupPointIndex] = OfficerTwo;

	// remove the stacked up goals on all officers
	for(i=0; i<OfficersInStackupOrder.Length; ++i)
	{
		RemoveStackedUpGoalOnOfficer(OfficersInStackupOrder[i]);
	}

	// make sure the stack up goals are cleared out
	StackUpGoals.Remove(0, StackUpGoals.Length);

	if (OfficerOne.logAI)
	{
		log("Moving " $ OfficerOne.Name $ " from " $ NewOfficerTwoStackupPoint.Name $ " to " $ NewOfficerOneStackupPoint.Name);
		log("Moving " $ OfficerTwo.Name $ " from " $ NewOfficerOneStackupPoint.Name $ " to " $ NewOfficerTwoStackupPoint.Name);
	}

	// post the stack up goals on the officers
	PostStackUpGoalOnOfficer(OfficerOne, NewOfficerOneStackupPoint, true);
	PostStackUpGoalOnOfficer(OfficerTwo, NewOfficerTwoStackupPoint, true);

	// wait
	waitForAllGoalsInList(StackUpGoals);

	// post the stacked up goals back up on the officers
	for(i=0; i<OfficersInStackupOrder.Length; ++i)
	{
		PostStackedUpGoal(OfficersInStackupOrder[i], StackUpPoints[i]);
	}
}

protected function RemoveStackedUpGoalOnOfficer(Pawn Officer)
{
	local int i;
	local StackedUpGoal OfficerStackedUpGoal;

	StackUpGoal(AI_Resource(Officer.characterAI).findGoalByName("StackUp"));
	OfficerStackedUpGoal = StackedUpGoal(AI_Resource(Officer.characterAI).findGoalByName("StackedUp"));

	if (OfficerStackedUpGoal != None)
	{
		for(i=0; i<StackedUpGoals.Length; ++i)
		{
			if (OfficerStackedUpGoal == StackedUpGoals[i])
			{
				StackedUpGoals[i].unPostGoal(Self);
				StackedUpGoals[i].Release();
				StackedUpGoals[i] = None;
				StackedUpGoals.Remove(i, 1);
			}
		}
	}
}

protected function TriggerCompletedSpeech()
{
	// if are supposed to tell the player that we need them to confirm our orders, play that speech
	if (bTriggerCouldntBreachLockedSpeech && CanInteractWithTargetDoor())
	{
		// respond that we are waiting for the Player's orders
		ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerCouldntBreachLockedDoorSpeech();
	}
	else
	{
		ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerReachedStackUpSpeech();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Some C2 breaching functions shared by subclasses

function protected bool IsC2ChargeDeployedOnThisSideOfDoor()
{
	local ISwatDoor SwatDoorTarget;
	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

    if (SwatDoorTarget.PointIsToMyLeft(CommandOrigin))
    {
        return SwatDoorTarget.IsChargePlacedOnLeft();
    }
    else
    {
        return SwatDoorTarget.IsChargePlacedOnRight();
    }
}

function protected Pawn GetC2BreachingOfficer()
{
	local int i;
	local Pawn  Officer;
    local bool bCanUseOfficer;
    local HandheldEquipment Equipment;
    local bool bIsC2ChargeDeployedOnThisSideOfDoor;
    bIsC2ChargeDeployedOnThisSideOfDoor = IsC2ChargeDeployedOnThisSideOfDoor();

	assert(OfficersInStackUpOrder.Length > 0);
	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

        if (class'Pawn'.static.checkConscious(Officer))
        {
            if (bIsC2ChargeDeployedOnThisSideOfDoor)
            {
                Equipment = ISwatOfficer(Officer).GetItemAtSlot(Slot_Detonator);
                bCanUseOfficer = (Equipment != None);
            }
            else
            {
                Equipment = ISwatOfficer(Officer).GetItemAtSlot(SLOT_Breaching);
                bCanUseOfficer = (Equipment != None && Equipment.IsA('C2Charge'));
            }

            if (bCanUseOfficer)
		    {
				return Officer;
		    }
        }
	}

	// didn't find an officer who could breach the door
	return None;
}

protected latent function MoveUpC2Breacher(Pawn Breacher)
{
	assert(class'Pawn'.static.checkConscious(Breacher));

	if (Breacher != GetFirstOfficer())
	{
		ISwatOfficer(Breacher).GetOfficerSpeechManagerAction().TriggerMoveUpC2Speech();

		MoveUpBreacher(Breacher);
	}
}

protected latent function MoveUpShotgunBreacher(Pawn Breacher)
{
	assert(class'Pawn'.static.checkConscious(Breacher));

	if (Breacher != GetFirstOfficer())
	{
		ISwatOfficer(Breacher).GetOfficerSpeechManagerAction().TriggerMoveUpBreachSGSpeech();

		MoveUpBreacher(Breacher);
	}
}

private latent function MoveUpBreacher(Pawn Breacher)
{
	assert(class'Pawn'.static.checkConscious(Breacher));
	assert(Breacher != GetFirstOfficer());

	SwapOfficerRoles(Breacher, GetFirstOfficer());
	SwapStackUpPositions(Breacher, GetFirstOfficer());
}

// overridden in SquadMoveAndClearAction
protected function SwapOfficerRoles(Pawn OfficerA, Pawn OfficerB);

///////////////////////////////////////////////////////////////////////////////

state Running
{
Begin:
	StackUpSquad(true);

	// trigger any speech if necessary
	TriggerCompletedSpeech();

	// doesn't complete until interrupted
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadStackUpGoal'
}