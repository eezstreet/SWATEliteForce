class DoorRoster extends Core.Object
	editinlinenew
	hideCategories(Object)
	collapsecategories
	dependsOn(SwatGUIConfig);

var(Roster) array<SwatDoor> Doors;
var(Roster) IntegerRange LockDoorCount;
var(Roster) IntegerRange OpenLeftCount;
var(Roster) IntegerRange OpenRightCount;
var(Roster) String		ArtistLabel "Not read or used. Just a label to remind yourself what this is for.";

// Locks LockDoorCount.Min - LockDoorCount.Max of the doors in Doors
function DoDoorRoster()
{
	local array<SwatDoor> DoorsLeft;
	local int i;
	local int Count;
	local int DoorNum;

	log("DoDoorRoster()");

	for(i = 0; i < Doors.Length; i++)
	{
		DoorsLeft[i] = Doors[i];
	}

	log("---DoorsLeft.Length is "$DoorsLeft.Length);

	// Lock doors
	Count = Rand(LockDoorCount.Max - LockDoorCount.Min + 1) + LockDoorCount.Min;
	log("---Chose to lock "$count$" doors");
	for(i = 0; i < Count && DoorsLeft.Length > 0; i++)
	{
		DoorNum = Rand(DoorsLeft.Length);
		log("---Locking door "$DoorNum$" which is "$DoorsLeft[DoorNum]);

		DoorsLeft[DoorNum].RosterLock();
		DoorsLeft.Remove(DoorNum, 1);
	}

	// Open doors to the left
	Count = Rand(OpenLeftCount.Max - OpenLeftCount.Min + 1) + OpenLeftCount.Min;
	for(i = 0; i < Count && DoorsLeft.Length > 0; i++)
	{
		DoorNum = Rand(DoorsLeft.Length);

		DoorsLeft[DoorNum].RosterOpenLeft();
		DoorsLeft.Remove(DoorNum, 1);
	}

	// Open doors to the right
	Count = Rand(OpenRightCount.Max - OpenRightCount.Min + 1) + OpenRightCount.Min;
	for(i = 0; i < Count && DoorsLeft.Length > 0; i++)
	{
		DoorNum = Rand(DoorsLeft.Length);

		DoorsLeft[DoorNum].RosterOpenRight();
		DoorsLeft.Remove(DoorNum, 1);
	}
}
