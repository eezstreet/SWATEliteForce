///////////////////////////////////////////////////////////////////////////////
// RestrainAndReportAction.uc - StackUpAction class
// The Action that causes the Officers to report something to TOC

class ReportAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
//var(parameters) SwatGame.SwatAI			ReportTarget;
var(parameters)	Controller				ThisController;

state Running
{
Begin:
	// If the AI has been reported to TOC already, we don't want to bother with it
	/*if(!ReportTarget.CanBeUsedNow())
	{
		succeed();
	}*/
	//ThisController.ServerRequestInteract(ReportTarget, ReportTarget.UniqueID());
	succeed();
}

defaultproperties
{
    satisfiesGoal = class'ReportGoal'
}