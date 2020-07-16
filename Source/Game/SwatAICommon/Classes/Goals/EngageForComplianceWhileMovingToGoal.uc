class EngageForComplianceWhileMovingToGoal extends EngageForComplianceGoal;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var(parameters) Pawn TargetPawn;
var(parameters) Vector Destination;
var(parameters) Pawn OriginalCommandGiver;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, Pawn inTargetPawn, Vector inDestination, Pawn inOriginalCommandGiver)
{
	super.construct( r, priority );

	assert(inTargetPawn != None);
	TargetPawn = inTargetPawn;
	Destination = inDestination;
	OriginalCommandGiver = inOriginalCommandGiver;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority   = 85
    GoalName   = "EngageForComplianceWhileMovingTo"
}

