///////////////////////////////////////////////////////////////////////////////
// ReportGoal.uc - The ReportGoal class
// behavior that causes the Officer AI to report something to TOC.

class ReportGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
//var(parameters) SwatGame.SwatAI			ReportTarget;
var(parameters)	Controller				ThisController;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, /*SwatGame.SwatAI ptReportTarget,*/ Controller ourController )
{
    Super.construct(r);

   // ReportTarget = ptReportTarget;
	ThisController = ourController;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 60
    GoalName = "Report"
}