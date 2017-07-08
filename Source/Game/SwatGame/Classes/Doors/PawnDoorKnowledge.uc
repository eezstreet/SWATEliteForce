///////////////////////////////////////////////////////////////////////////////
// PawnDoorKnowledge.uc - The PawnDoorKnowledge class
// Object that contains information about a Pawn's beliefs and knowledge of a door

class PawnDoorKnowledge extends Core.Object
    native;
///////////////////////////////////////////////////////////////////////////////

var private bool	bBelievesDoorLocked;
var private bool	bBelievesDoorWedged;

///////////////////////////////////////////////////////////////////////////////

// don't make these events... native code should access them directly
// through the UPawnDoorKnowledge object reference for speed. These
// script functions are just wrappers around the native code.
native function bool DoesBelieveDoorLocked();
native function bool DoesBelieveDoorWedged();

function SetBelievesDoorLocked(bool bInBelievesDoorLocked)
{
	bBelievesDoorLocked = bInBelievesDoorLocked;
}


function SetBelievesDoorWedged(bool bInBelievesDoorWedged)
{
	bBelievesDoorWedged = bInBelievesDoorWedged;
}

cpptext
{
	UBOOL DoesBelieveDoorLocked() { return bBelievesDoorLocked; }
	UBOOL DoesBelieveDoorWedged() { return bBelievesDoorWedged; }
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bBelievesDoorLocked = false
	bBelievesDoorWedged = false
}