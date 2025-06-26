///////////////////////////////////////////////////////////////////////////////
// ISwatPawn.uc - ISwatPawn interface
// we use this interface to be able to call functions on the SwatPawn because we
// the definition of SwatPawn has not been defined yet, but because SwatPawn implements
// ISwatPawn, we have a contract that says these functions will be implemented, and 
// we can cast any Pawn pointer to an SwatPawn interface to call them

interface ISwatPawn;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Stuff that is needed
simulated function HandheldEquipment GetActiveItem();


///////////////////////////////////////////////////////////////////////////////
//
// Door Belief support

function bool DoesBelieveDoorLocked(Door inDoor);
function bool DoesBelieveDoorWedged(Door inDoor);
function SetDoorLockedBelief(Door inDoor, bool bBelievesDoorLocked);
function SetDoorWedgedBelief(Door inDoor, bool bBelievesDoorWedged);

///////////////////////////////////////////////////////////////////////////////
//
// For testing if the AI is under the effects of a tactical aid

simulated function bool IsFlashbanged();    // is under effect of a flashbang
simulated function bool IsGassed();         // is under effect of a gas grenade
simulated function bool IsPepperSprayed();  // is under effect of pepperspray
simulated function bool IsStung();          // is under effect of a sting grenade
simulated function bool IsTased();          // is under effect of a taser

///////////////////////////////////////////////////////////////////////////////
