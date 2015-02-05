///////////////////////////////////////////////////////////////////////////////
// StackupPoint.uc - StackupPoint class
// A point that Officers will stack-up at based on priority

class StackupPoint extends BaseDoorPoint
	notplaceable
    native;
///////////////////////////////////////////////////////////////////////////////

import enum AIThrowSide from SwatAICommon.ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// StackupPoint variables

var	  private Pawn			OfficerClaimer;
var   protected Texture		StackupPointIcons[4];

var() bool					CanThrowFromPoint;
var() AIThrowSide			ThrowSide;
var() private int			AlternatePriority;

// For Debugging
var	  array<vector>			StackupPathToDoor;
var private Actor			BlockedOpenLeft;
var private Actor			BlockedOpenRight;

///////////////////////////////////////////////////////////////////////////////
//
// Officer Claiming

function bool IsClaimedByOfficer()
{
	return (OfficerClaimer != None);
}

function SetClaimedByOfficer(Pawn Officer)
{
	OfficerClaimer = Officer;
}

function ClearClaims()
{
	OfficerClaimer = None;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}