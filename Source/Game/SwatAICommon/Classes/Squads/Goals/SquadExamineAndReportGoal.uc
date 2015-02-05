///////////////////////////////////////////////////////////////////////////////
// SquadExamineAndReportGoal.uc - SquadExamineAndReportGoal class
// this goal is used to organize the Officer's Examine & Report behavior

class SquadExamineAndReportGoal extends SquadCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Actor ExamineTarget;


///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Actor inExamineTarget)
{
	super.construct(r, inCommandGiver, inCommandOrigin);

	assert(inExamineTarget != None);
	ExamineTarget = inExamineTarget;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadExamineAndReport"
}