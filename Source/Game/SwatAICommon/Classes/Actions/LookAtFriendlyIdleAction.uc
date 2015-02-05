///////////////////////////////////////////////////////////////////////////////
// LookAtFriendlyIdleAction.uc - LookAtFriendlyIdleAction class
// A procedural Idle action that causes the AI to look at another friendly AI (same type)

class LookAtFriendlyIdleAction extends ProceduralIdleAction;

// !!! NOTE !!!:
// This has been commented out, due to animation changes with respect to head
// tracking. [darren]
#if 0

///////////////////////////////////////////////////////////////////////////////

const kMinLookAtTime = 1.5;
const kMaxLookAtTime = 3.0;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private LookAtActorGoal CurrentLookAtActorGoal;

var private Pawn			ViewableFriendly;


///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function bool CanUseIdleAction()
{
	ViewableFriendly = FindViewableFriendlyInRoom();
	return (Super.CanUseIdleAction() && (ViewableFriendly != None));
}

// this function is slow!  goes through the whole Pawn list
function Pawn FindViewableFriendlyInRoom()
{
	local array<Pawn> Friendlies;
	local Pawn Iter;
	local int RandomFriendlyIndex;
	local string RoomName;

	assert(m_Pawn != None);

	RoomName = m_Pawn.GetRoomName();

	for(Iter = m_Pawn.Level.PawnList; Iter != None; Iter = Iter.nextPawn)
	{
//		log("FindViewable for " $m_Pawn.Name$" - Testing " $ Iter.Name $ " - Iter.IsInRoom("$RoomName$"):"$Iter.IsInRoom(RoomName)$" ClassIsChildOf: "$ClassIsChildOf(Iter.class, m_Pawn.class)$" can look: "$ISwatAI(m_Pawn).AnimCanLookAtDesiredActor(Iter));

		// if the Iter isn't us, is alive, in the same room, a friendly, and we can look at them
		if ((Iter != m_Pawn) &&
			class'Pawn'.static.checkConscious(Iter) &&
			Iter.IsInRoom(RoomName) && /* ClassIsChildOf(Iter.class, m_Pawn.class) && */
			ISwatAI(m_Pawn).AnimCanLookAtDesiredActor(Iter))
		{
			Friendlies[Friendlies.Length] = Iter;
		}
	}

	// it's OK to return None
	if (Friendlies.Length > 0)
	{
		RandomFriendlyIndex = Rand(Friendlies.Length);
		return Friendlies[RandomFriendlyIndex];
	}
	else 
	{
		return None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentLookAtActorGoal != None)
	{
		CurrentLookAtActorGoal.Release();
		CurrentLookAtActorGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function LookAtFriendly()
{
	assert(ViewableFriendly != None);

	CurrentLookAtActorGoal = new class'LookAtActorGoal'(headResource(), ViewableFriendly, kMinLookAtTime, kMaxLookAtTime);
	assert(CurrentLookAtActorGoal != None);
	CurrentLookAtActorGoal.AddRef();

	CurrentLookAtActorGoal.postGoal(self);
	WaitForGoal(CurrentLookAtActorGoal);
	CurrentLookAtActorGoal.unPostGoal(self);

	CurrentLookAtActorGoal.Release();
	CurrentLookAtActorGoal = None;

	// just to make sure we get a new one!
	ViewableFriendly = None;
}

state Running
{
 Begin:
	LookAtFriendly();
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
#endif