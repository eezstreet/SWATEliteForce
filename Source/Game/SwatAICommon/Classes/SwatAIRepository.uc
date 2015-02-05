///////////////////////////////////////////////////////////////////////////////
class SwatAIRepository extends Engine.AIRepository
	native;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Singleton Variables
var private IdleActionsList					IdleActions;
var private InitialReactionsList			InitialReactions;

// Script-declared TMaps are always transient even if not declared so, hence
// we need to serialize this native to ensure references are counted properly
// during Garbage Collection
var private transient const map<name, NavigationPointList>	RoomNavigationPoints;

var private CharacterTypesList				CharacterTypes;

var private ElementSquadInfo				ElementSquad;
var private RedSquadInfo					RedSquad;
var private BlueSquadInfo					BlueSquad;
	
var private Hive							HiveMind;
var private Pawn							CurrentEnemyInHostageConversation;

///////////////////////////////////////////////////////////////////////////////
//
// Event Initialization

event PreBeginPlay()
{
    Super.PreBeginPlay();

	CreateCharacterTypesList();
    CreateIdleActionClassesList();
	CreateInitialReactionClassesList();
    
	CreateHive();
	CreateOfficerSquads();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
}

///////////////////////////////////////////////////////////////////////////////
//
// Character Types

private function CreateCharacterTypesList()
{
	CharacterTypes = Spawn(class'CharacterTypesList', self);
	assert(CharacterTypes != None);
}

function name GetVoiceTypeForCharacterType(name CharacterType)
{
	assert(CharacterType != '');
	return CharacterTypes.GetVoiceTypeForCharacterType(CharacterType);
}

// determine if the character type is a female, or not
function bool IsAFemaleCharacterType(name inCharacterType)
{
	assert(inCharacterType != '');

	return CharacterTypes.IsAFemaleCharacterType(inCharacterType);
}

// debug function to verify a voice type override exists
function bool VerifyVoiceTypeExists(name inVoiceType)
{
	assert(inVoiceType != '');

	return CharacterTypes.VerifyVoiceTypeExists(inVoiceType);
}

// debug function to verify a character type override exists
function bool VerifyCharacterTypeExists(name inCharacterType)
{
	assert(inCharacterType != '');

	return CharacterTypes.VerifyCharacterTypeExists(inCharacterType);
}

///////////////////////////////////////////////////////////////////////////////
//
// Officer Squads

// Hive
private function CreateHive()
{
	HiveMind = new(self) class'Hive'();
	assert(HiveMind != None);

	HiveMind.SwatAIRepo = self;
}

function Hive GetHive() { return HiveMind; }

// Tyrion Squads
private function CreateOfficerSquads()
{
	// create each squad
	ElementSquad = Spawn(class'ElementSquadInfo');
	assert(ElementSquad != None);
	ElementSquad.SwatAIRepo = self;
    ElementSquad.Label = 'Element';

	RedSquad = Spawn(class'RedSquadInfo');
	assert(RedSquad != None);
	RedSquad.SwatAIRepo = self;
    RedSquad.Label = 'RedTeam';

	BlueSquad = Spawn(class'BlueSquadInfo');
	assert(BlueSquad != None);
	BlueSquad.SwatAIRepo = self;
    BlueSquad.Label = 'BlueTeam';
}

// Squad Accessors
native function ElementSquadInfo	GetElementSquad();
native function RedSquadInfo		GetRedSquad();
native function BlueSquadInfo		GetBlueSquad();

// test to see if a particular officer is moving and clearing.
// since the Officers don't have a reverse lookup for seeing which squad they are in,
// we have to figure that out too
function bool IsOfficerMovingAndClearing(Pawn Officer)
{
	assert(Officer != None);

	return(ElementSquad.IsMovingAndClearing() ||
		  (RedSquad.IsOfficerOnTeam(Officer) && RedSquad.IsMovingAndClearing()) ||
		  (BlueSquad.IsOfficerOnTeam(Officer) && BlueSquad.IsMovingAndClearing()));
}

// reverse lookup function to see what sub element an officer is on
function OfficerTeamInfo GetSubElement(Pawn Officer)
{
	if (RedSquad.IsOfficerOnTeam(Officer))
		return RedSquad;
	else
		return BlueSquad;
}

///////////////////////////////////////////////////////////////////////////////
//
// Door Beliefs Notifications

function UpdateDoorKnowledgeForOfficers(Door TargetDoor)
{
	local ISwatDoor SwatTargetDoor;
	local bool bDoorBroken, bDoorLocked, bDoorWedged;

	assert(TargetDoor != None);
	SwatTargetDoor = ISwatDoor(TargetDoor);
	assert(SwatTargetDoor != None);

//	log("SwatTargetDoor.IsBroken(): " $ SwatTargetDoor.IsBroken() $ " SwatTargetDoor.IsLocked(): " $ SwatTargetDoor.IsLocked());

	bDoorBroken = SwatTargetDoor.IsBroken();
	bDoorLocked = SwatTargetDoor.IsLocked();
	bDoorWedged = SwatTargetDoor.IsWedged();

	if (! bDoorBroken)
	{
		if (bDoorLocked)
		{
			// it's locked!  let everyone know.
			NotifyOfficersDoorLocked(TargetDoor);
		}

		// need to know if a door is locked AND wedged, so there's no else if here
		if (bDoorWedged)
		{
			// it's wedged!  let everyone know.
			NotifyOfficersDoorWedged(TargetDoor);
		}
	}
	
	// if it's broken, or not wedged and locked, it can be opened
	if ((!bDoorLocked && !bDoorWedged) || SwatTargetDoor.IsBroken())
	{
		// it's open!  let everyone know.
		NotifyOfficersDoorCanOpen(TargetDoor);
	}
}

private function NotifyOfficersDoorLocked(Door TargetDoor)
{
	local int i;
	local Pawn OfficerIter;

	// notify all of the AI Officers.
	for(i=0; i<GetElementSquad().pawns.length; ++i)
	{
		OfficerIter = GetElementSquad().pawns[i];

		if ((OfficerIter != None) && OfficerIter.isAlive())
		{
			ISwatPawn(OfficerIter).SetDoorLockedBelief(TargetDoor, true);
		}
	}

	// notify the player Officer
	// note that this could be BAD if there are ever more than one players
	ISwatPawn(Level.GetLocalPlayerController().Pawn).SetDoorLockedBelief(TargetDoor, true);
}

function NotifyOfficersDoorWedged(Door TargetDoor)
{
	local int i;
	local Pawn OfficerIter;

	// notify all of the AI Officers.
	for(i=0; i<GetElementSquad().pawns.length; ++i)
	{
		OfficerIter = GetElementSquad().pawns[i];

		if ((OfficerIter != None) && OfficerIter.isAlive())
		{
			ISwatPawn(OfficerIter).SetDoorWedgedBelief(TargetDoor, true);
		}
	}

	// notify the player Officer
	// note that this could be BAD if there are ever more than one players
	ISwatPawn(Level.GetLocalPlayerController().Pawn).SetDoorWedgedBelief(TargetDoor, true);
}

function NotifyOfficersDoorWedgeRemoved(Door TargetDoor)
{
	local int i;
	local Pawn OfficerIter;

	// notify all of the AI Officers.
	for(i=0; i<GetElementSquad().pawns.length; ++i)
	{
		OfficerIter = GetElementSquad().pawns[i];

		if ((OfficerIter != None) && OfficerIter.isAlive())
		{
			ISwatPawn(OfficerIter).SetDoorWedgedBelief(TargetDoor, false);
		}
	}

	// notify the player Officer
	// note that this could be BAD if there are ever more than one players
	ISwatPawn(Level.GetLocalPlayerController().Pawn).SetDoorWedgedBelief(TargetDoor, false);
}

private function NotifyOfficersDoorCanOpen(Door TargetDoor)
{
	local int i;
	local Pawn OfficerIter;

	// notify all of the AI Officers.
	for(i=0; i<GetElementSquad().pawns.length; ++i)
	{
		OfficerIter = GetElementSquad().pawns[i];

		if ((OfficerIter != None) && OfficerIter.isAlive())
		{
			ISwatPawn(OfficerIter).SetDoorLockedBelief(TargetDoor, false);
			ISwatPawn(OfficerIter).SetDoorWedgedBelief(TargetDoor, false);
		}
	}

	// notify the player Officer
	// note that this could be BAD if there are ever more than one players
	ISwatPawn(Level.GetLocalPlayerController().Pawn).SetDoorLockedBelief(TargetDoor, false);
	ISwatPawn(Level.GetLocalPlayerController().Pawn).SetDoorWedgedBelief(TargetDoor, false);
}

///////////////////////////////////////////////////////////////////////////////
//
// Idle Actions

private function CreateIdleActionClassesList()
{
    IdleActions = Spawn(class'IdleActionsList', self);
    assert(IdleActions != None);
}

function IdleActionsList GetIdleActions()
{
    return IdleActions;
}

///////////////////////////////////////////////////////////////////////////////
//
// Initial Reactions

private function CreateInitialReactionClassesList()
{
	InitialReactions = Spawn(class'InitialReactionsList', self);
	assert(InitialReactions != None);
}

function InitialReactionsList GetInitialReactions()
{
	return InitialReactions;
}

///////////////////////////////////////////////////////////////////////////////
//
// Enemy Hostage Conversations

function bool IsEnemyHostageConversationActive()
{
	return (CurrentEnemyInHostageConversation != None);
}

function ActivateEnemyHostageConversation(Pawn inEnemy)
{
	assert(CurrentEnemyInHostageConversation == None);

	CurrentEnemyInHostageConversation = inEnemy;
}

function DeactivateEnemyHostageConversation(Pawn inEnemy)
{
	if (CurrentEnemyInHostageConversation == inEnemy)
	{
		CurrentEnemyInHostageConversation = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Rooms

// These methods are a hack to work around the fact that we haven't implemented
// script-side support for TMaps yet. 
native function SetNavigationPointListForRoom(name RoomName, NavigationPointList NavPoints);
native function NavigationPointList GetRoomNavigationPoints(name RoomName);

function AddNavigationPointToRoomList(NavigationPoint NavPoint, name RoomName)
{
    local NavigationPointList NavPointList;

    // using the RoomName, get the cooresponding NavPointList from the Hash, if any
    NavPointList = GetRoomNavigationPoints(RoomName);

    // if we didn't find a NavPointList, that means we need to create one.  create one and add it to the hash
    if (NavPointList == None)
    {
        NavPointList = GetNewNavigationPointList();
        assert(NavPointList != None);

        SetNavigationPointListForRoom(RoomName, NavPointList);
    }
    
    // now add the NavPoint to the list for the Room
    NavPointList.Add(NavPoint);

    // debug code -- uncomment to watch navigation points get added
//    log(Name@" Added "@NavPoint.Name@" to NavPointList for Room"@NavPoint.RoomName);
//    RoomNavigationPoints.Profile();
}

function bool DoesRoomHaveAny(name RoomName, name PointClassName)
{
	local int i;
	local NavigationPointList RoomNavPointList;
	local NavigationPoint Iter;
    local int NumRoomNavPoints;

	assertWithDescription((RoomName != ''), "SwatAIRepository::DoesRoomHaveAny - RoomName passed in is empty, a Navigation Point is missing a room name in this map!  Check for Errors in UnrealEd!");
	assertWithDescription((PointClassName != ''), "SwatAIRepository::DoesRoomHaveAny - PointClassName is empty!");

	RoomNavPointList = GetRoomNavigationPoints(RoomName);	
    NumRoomNavPoints = RoomNavPointList.GetSize();	
	for(i=0; i<NumRoomNavPoints; ++i)
	{
		Iter = RoomNavPointList.GetEntryAt(i);

		if (Iter.IsA('PointClassName'))
		{
			return true;
		}
	}

	// didn't find any!
	return false;
}

native event NavigationPointList GetRoomNavigationPointsOfType(name RoomName, name PointClassName, optional vector Location, optional float MinimumDistanceFromLocation);

function NavigationPoint GetClosestNavigationPointInRoom(name RoomName, vector Location, optional float MinimumDistanceFromLocation, optional name PointClassName, optional name ExclusionPointClassName)
{
	local NavigationPointList RoomNavPointList;
	local NavigationPoint ClosestPoint, IterPoint;
	local float ClosestDistance, IterDistance;
	local int i;
    local int NumRoomNavPoints;

	assertWithDescription((RoomName != ''), "SwatAIRepository::GetClosestNavigationPointInRoom - RoomName passed in is empty, a Navigation Point is missing a room name in this map!  Check for Errors in UnrealEd!");

	RoomNavPointList = GetRoomNavigationPoints(RoomName);
	
	// go through each point int he room and see if it matches up with what the caller wants
    NumRoomNavPoints = RoomNavPointList.GetSize();
    for(i=0; i<NumRoomNavPoints; ++i)
    {
        IterPoint = RoomNavPointList.GetEntryAt(i);

		if ((PointClassName == '') || IterPoint.IsA(PointClassName))
		{
			// don't find points that we're not supposed to use
			if ((ExclusionPointClassName == '') || !IterPoint.IsA(ExclusionPointClassName))
			{
				IterDistance = VSize(IterPoint.Location - Location);

				if ((MinimumDistanceFromLocation == 0.0) || (IterDistance >= MinimumDistanceFromLocation))
				{
					if ((ClosestPoint == None) || (IterDistance < ClosestDistance))
					{
						ClosestPoint    = IterPoint;
						ClosestDistance = IterDistance;
					}
				}
			}
		}
	}

	return ClosestPoint;
}

function NavigationPoint FindRandomPointInRoom(name RoomName, optional name PointClassName)
{
    local NavigationPointList RoomPoints;
    local NavigationPoint RandomPoint;

    RoomPoints  = GetRoomNavigationPointsOfType(RoomName, PointClassName);
    RandomPoint = RoomPoints.GetRandomEntry();

	// all done with this list
	ReleaseNavigationPointList(RoomPoints);

    return RandomPoint;
}

function FleePoint FindUnclaimedFleePointInRoom(name RoomName)
{
    local NavigationPointList RoomPoints;
	local int i;
	local FleePoint Iter, RandomPoint;

    RoomPoints = GetRoomNavigationPointsOfType(RoomName, 'FleePoint');
    
	for(i=0; i<RoomPoints.GetSize(); ++i)
	{
		Iter = FleePoint(RoomPoints.GetEntryAt(i));

		if (Iter.GetFleePointUser() != None)
		{
			RoomPoints.Remove(Iter);
		}
	}

	RandomPoint = FleePoint(RoomPoints.GetRandomEntry());

	// all done with this list
	ReleaseNavigationPointList(RoomPoints);

    return RandomPoint;
}

function NavigationPointList GetNavigationPointsInRoomThatCanHitPoint(name RoomName, vector Point)
{
	local int i;
	local NavigationPointList NavigationPointsThatCanHitPoint, RoomPoints;
	local NavigationPoint Iter;

	NavigationPointsThatCanHitPoint = GetNewNavigationPointList();
	RoomPoints = GetRoomNavigationPoints(RoomName);

	for(i=0; i<RoomPoints.GetSize(); ++i)
	{
		Iter = RoomPoints.GetEntryAt(i);

		if (FastTrace(Point, Iter.GetAimLocation(None)) == true)
		{
			NavigationPointsThatCanHitPoint.Add(Iter);
		}
	}

	return NavigationPointsThatCanHitPoint;
}

// WARNING! This function is very slow!
native function name GetClosestRoomNameToPoint(vector Point, Pawn TestPawn);

///////////////////////////////////////////////////////////////////////////////
//
// NavigationPointList Creation / Destruction
// * These functions should be the only way to create NavigationPointLists *

event ReleaseNavigationPointList(NavigationPointList NavPointList)
{
	assert(NavPointList != None);

	// first empty the list
	NavPointList.Empty();

	// now give it back to the object pool
	Level.ObjectPool.FreeObject(NavPointList);
}

event NavigationPointList GetNewNavigationPointList()
{
	local NavigationPointList NavPointList;

	NavPointList = NavigationPointList(Level.ObjectPool.AllocateObject(class'NavigationPointList'));

	assert(NavPointList != None);
	assertWithDescription((NavPointList.GetSize() == 0), "SwatAIRepository::GetNewNavigationPointList - NavPointList GetSize > 0!");

	return NavPointList;
}


///////////////////////////////////////////////////////////////////////////////
//
// Navigation

function NavigationPoint FindClosestNavigationPointTo(vector TestLocation)
{
    return FindClosestOfNavigationPointClass(class'NavigationPoint', TestLocation);
} 

native event NavigationPointList FindAllOfNavigationPointClass(class<NavigationPoint> ClassType, optional NavigationPointList ExcludeList);

// finds the closest of class NavigationPoint to a location
// we can exclude multiple NavigationPoints that we don't want to be tested
native event NavigationPoint FindClosestOfNavigationPointClass(class<NavigationPoint> ClassType, vector TestLocation, optional NavigationPointList ExcludeList);


///////////////////////////////////////////////////////////////////////////////
//
// Room Tests

native function bool DoesRoomContainAIs(name RoomName, optional name SpecifiedAIClassName, optional bool bMustMoveFreely);
native function Pawn GetClosestUncompliantViewableAIInRoom(name RoomName, Pawn TestCharacter, optional name SpecifiedAIClassName);
