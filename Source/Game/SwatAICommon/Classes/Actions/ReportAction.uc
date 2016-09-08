///////////////////////////////////////////////////////////////////////////////
// RestrainAndReportAction.uc - StackUpAction class
// The Action that causes the Officers to report something to TOC

class ReportAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) ISwatAI			ReportTarget;
var(parameters)	Controller				ThisController;

latent function Report() {
	// If the AI has been reported to TOC, we shouldn't bother with it
	if(!ReportTarget.CanBeUsedNow())
	{
		succeed();
		return;
	}
	ThisController.ServerRequestInteract(ICanBeUsed(ReportTarget), "");

	succeed();
}

state Running
{
Begin:
	Report();
}

defaultproperties
{
    satisfiesGoal = class'ReportGoal'
}
