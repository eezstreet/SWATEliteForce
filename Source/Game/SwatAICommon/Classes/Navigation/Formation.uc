///////////////////////////////////////////////////////////////////////////////
// Formation.uc - the Formation class
// the formation class provides a way for the Swat Officers to maintain separation
// and cohesiveness in their movement.  the formation will alw

class Formation extends Core.RefCount
	config(AI);
///////////////////////////////////////////////////////////////////////////////

var private Pawn				Leader;					// we always have a leader
var private array<Pawn>			FormationMembers;

var private array<Pawn>			OrderedMembers;

// re-order caching
var private array<vector>		CachedOrderedMembersLocations;
var private vector				CachedLeaderLocation;

// re-order timer
var private Timer				ReorderTimer;
var config float				ReorderTime;

const kOutsidePathfindingLargeZDistance       = 300.0;
const kOutsidePathfindingSmallZDistance       = 128.0;
const kOutsidePathfindingWithSmallZDistance2D = 200.0;
const kInsidePathfindingWithSmallZDistance2D  = 500.0;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

overloaded function construct()
{
	// don't use this constructor
	assert(false);
}

overloaded function construct(Pawn NewLeader)
{
	// set the leader
	SetLeader(NewLeader);    

	SpawnReorderTimer();
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function Cleanup()
{
	ClearMembers();
	CleanupTimer();
}

///////////////////////////////////////////////////////////////////////////////
//
// Reorder Timer

private function SpawnReorderTimer()
{
	assert(ReorderTimer == None);
	assert(Leader != None);

	ReorderTimer = Leader.Spawn(class'Timer');
	ReorderTimer.timerDelegate = ReorderMembers;
	ReorderTimer.startTimer(ReorderTime, true);
}

private function CleanupTimer()
{
	if (ReorderTimer != None)
	{
		ReorderTimer.stopTimer();
		ReorderTimer.timerDelegate = None;
		ReorderTimer.Destroy();
		ReorderTimer = None;
	}
}
///////////////////////////////////////////////////////////////////////////////

function Pawn GetOrderedMember(int Index)
{
	assert(Index >= 0);
	assert(Index < OrderedMembers.Length);

	return OrderedMembers[Index];
}

///////////////////////////////////////////////////////////////////////////////
private function bool IsMemberOutsidePathfindingDistance(Pawn Member)
{
	local float ZDelta, Distance2D;

	ZDelta     = Abs(Leader.Location.Z - Member.Location.Z);
	Distance2D = VSize2D(Leader.Location - Member.Location);

//	log("IsMemberOutsidePathfindingDistance - Member: " $ Member.Name $ " ZDelta: " $ ZDelta $ " Distance2D: " $ Distance2D);

	if (ZDelta > kOutsidePathfindingLargeZDistance)
		return true;
	else if (ZDelta > kOutsidePathfindingSmallZDistance)
		return (Distance2D > kOutsidePathfindingWithSmallZDistance2D);
	else
		return (Distance2D > kInsidePathfindingWithSmallZDistance2D);
}

function bool HasFormationMemberSizeChanged()
{
	if ((FormationMembers.Length != OrderedMembers.Length) || (OrderedMembers.Length != CachedOrderedMembersLocations.Length))
		return true;

//	log("formation has not changed");
	return false;
}

function bool HasFormationLocationsChanged()
{
	local int i;

	if (Leader.Location != CachedLeaderLocation)
		return true;

	for(i=0; i<OrderedMembers.Length; ++i)
	{
		if (CachedOrderedMembersLocations[i] != OrderedMembers[i].Location)
			return true;
	}

//	log("formation has not changed");
	return false;
}

private function ReorderMembers()
{
    local bool bHasFormationMemberSizeChanged;
    local bool bHasFormationLocationsChanged;
    local bool bShouldDoFullPathBasedReordering;
	local int i, j, ClosestIndex;
	local float ClosestDistance;
	local array<Pawn> CurrentFormationMembers;
	local array<float> FormationMemberDistancesToLeader;

    bHasFormationMemberSizeChanged = HasFormationMemberSizeChanged();
    bHasFormationLocationsChanged  = HasFormationLocationsChanged();
    if (bHasFormationMemberSizeChanged || bHasFormationLocationsChanged)
    {
	    if (FormationMembers.Length == 1)
	    {
		    // clear out the existing ordered members array
		    OrderedMembers.Remove(0, OrderedMembers.Length);
		    OrderedMembers[0] = FormationMembers[0];
	    }
	    else
	    {
            // If the number of pawns in the formation ever changes, do a full
            // reordering
            if (!bShouldDoFullPathBasedReordering && bHasFormationMemberSizeChanged)
            {
                bShouldDoFullPathBasedReordering = true;
            }

            // Or, if all members are within the allowable path-finding
            // distance, do a full re-ordering
            if (!bShouldDoFullPathBasedReordering)
            {
                bShouldDoFullPathBasedReordering = true;
			    for(i=0; i<FormationMembers.Length; ++i)
			    {
				    if (IsMemberOutsidePathfindingDistance(FormationMembers[i]))
                    {
                        bShouldDoFullPathBasedReordering = false;
                        break;
                    }
                }
            }

            if (bShouldDoFullPathBasedReordering)
            {
		        // clear out the existing ordered members array
		        OrderedMembers.Remove(0, OrderedMembers.Length);

                // first get the distances for each member
    		    CurrentFormationMembers = FormationMembers;
			    for(i=0; i<CurrentFormationMembers.Length; ++i)
			    {
				    FormationMemberDistancesToLeader[i] = CurrentFormationMembers[i].GetPathfindingDistanceToActor(Leader, true);
			    }

			    // for each member, get the closest to the leader and put them in order
			    for(i=0; i<FormationMembers.Length; ++i)
			    {
				    for(j=0; j<FormationMemberDistancesToLeader.Length; ++j)
				    {
					    if ((j == 0) || (FormationMemberDistancesToLeader[j] < ClosestDistance))
					    {
						    ClosestDistance = FormationMemberDistancesToLeader[j];
						    ClosestIndex    = j;
					    }
				    }

				    // add the closest member to the end of the list
				    OrderedMembers[OrderedMembers.Length] = CurrentFormationMembers[ClosestIndex];

				    // now remove this member
				    CurrentFormationMembers.Remove(ClosestIndex, 1);
				    FormationMemberDistancesToLeader.Remove(ClosestIndex, 1);
			    }
            }
	    }

	    CachedOrderedMembersLocations.Remove(0, CachedOrderedMembersLocations.Length);
	    for(i=0; i<OrderedMembers.Length; ++i)
	    {
		    CachedOrderedMembersLocations[i] = OrderedMembers[i].Location;
	    }

	    CachedLeaderLocation = Leader.Location;
    }
}

function Pawn GetPawnInFront(Pawn CurrentMember)
{
	local int OrderedMemberIndex;
	assert(! IsLeader(CurrentMember));
	assert(IsInFormation(CurrentMember));

	OrderedMemberIndex = GetOrderedIndexForMember(CurrentMember);

	if (OrderedMemberIndex == 0)
	{
		return Leader;
	}
	else
	{
		return OrderedMembers[OrderedMemberIndex - 1];
	}
}


function Pawn GetDestinationForMember(Pawn CurrentMember)
{
	local Pawn PawnInFront;

	assertWithDescription(IsInFormation(CurrentMember), "Formation::GetDestinationForMember - "@CurrentMember.Name@" could not be found in Formation:"@Name);
	assertWithDescription(! IsLeader(CurrentMember), "Formation::GetDestinationForMember - called when "@CurrentMember.Name@" is a Leader in Formation:"@Name);

	if (IsMemberOutsidePathfindingDistance(CurrentMember))
	{
		return Leader;
	}
	else
	{
		PawnInFront = GetPawnInFront(CurrentMember);

		return PawnInFront;
	}
}

///////////////////////////////////////////////////////////////////////////////

function AddMember(Pawn NewMember)
{
	assertWithDescription((! IsInFormation(NewMember)), "Formation::AddMember -"@NewMember.Name@" is already in Formation:"@Name);

	FormationMembers[FormationMembers.Length] = NewMember;

	// re-order the members based on distance
	ReorderMembers();
}

function AddMembers(array<Pawn> NewMembers)
{
	local int i;
	local Pawn NewMember;

	assertWithDescription((NewMembers.Length > 0), "Formation::AddMembers - NewMembers array passed in has no members!");

	for(i=0; i<NewMembers.Length; ++i)
	{
		NewMember = NewMembers[i];

		assertWithDescription((! IsInFormation(NewMember)), "Formation::AddMember -"@NewMember.Name@" is already in Formation:"@Name);

		FormationMembers[FormationMembers.Length] = NewMember;
	}

	// re-order the members based on distance
	ReorderMembers();
}

function RemoveMember(Pawn CurrentMember)
{
	local int MemberIndex;
	assertWithDescription(IsInFormation(CurrentMember), "Formation::RemoveMember - "@CurrentMember.Name@" could not be found in Formation:"@Name);

	MemberIndex = GetFormationIndexForMember(CurrentMember);
	FormationMembers.Remove(MemberIndex, 1);

	// re-order the members based on distance
	ReorderMembers();
}

function ClearMembers()
{
	local int i;
	local Pawn Iter;

	for(i=0; i<FormationMembers.Length; ++i)
	{
		Iter = FormationMembers[i];

		if (class'Pawn'.static.checkAlive(Iter))
		{
			ISwatOfficer(Iter).ClearFormation();
		}
	}

	FormationMembers.Remove(0, FormationMembers.Length);
}

private function int GetFormationIndexForMember(Pawn CurrentMember)
{
	local int i;
	assertWithDescription(IsInFormation(CurrentMember), "Formation::GetIndexForMember - "@CurrentMember.Name@" could not be found in Formation:"@Name);

	for(i=0; i<FormationMembers.Length; ++i)
	{
		if (FormationMembers[i] == CurrentMember)
		{
			return i;
		}
	}

	// we will never get here (see assertion above), but the compiler doesn't know that.
	assert(false);
	return -1;
}

private function int GetOrderedIndexForMember(Pawn CurrentMember)
{
	local int i;
	assertWithDescription(IsInFormation(CurrentMember), "Formation::GetIndexForMember - "@CurrentMember.Name@" could not be found in Formation:"@Name);

	for(i=0; i<OrderedMembers.Length; ++i)
	{
		if (OrderedMembers[i] == CurrentMember)
		{
			return i;
		}
	}

	// we will never get here (see assertion above), but the compiler doesn't know that.
	assert(false);
	return -1;
}

// Test to see if a Pawn is in this formation
private function bool IsInFormation(Pawn Test)
{
	local int i;

	for(i=0; i<FormationMembers.Length; ++i)
	{
		if (FormationMembers[i] == Test)
		{
			return true;
		}
	}

	// didn't find the Pawn in the formation
	return false;
}

private function SetLeader(Pawn NewLeader)
{
	assert(NewLeader != None);

	Leader = NewLeader;
}

function Pawn GetLeader()
{
	return Leader;
}

// returns true if the Pawn is the Leader, false if not
function bool IsLeader(Pawn Pawn)
{
	return (Pawn == Leader);
}

///////////////////////////////////////////////////////////////////////////////

