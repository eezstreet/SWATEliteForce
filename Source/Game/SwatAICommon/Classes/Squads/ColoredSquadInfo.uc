///////////////////////////////////////////////////////////////////////////////
// ColoredSquadInfo.uc - the ColoredSquadInfo class
// this is the base class for the RedTeam and the BlueTeam (hence colored)

class ColoredSquadInfo extends OfficerTeamInfo
	config(AI)
	native;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private Timer			NeedOrdersTimer;
var private config float	NeedOrdersTriggerTimeDelta;

///////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////
//
// Engine events

event Destroyed()
{
	super.destroyed();

	DestroyNeedOrdersTimer();
}

private function DestroyNeedOrdersTimer()
{
	if (NeedOrdersTimer != None)
	{
		NeedOrdersTimer.timerDelegate = None;
		NeedOrdersTimer.Destroy();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Command Goals

protected function UnpostCommandGoals()
{
	// clear out our own command goal
	ClearCommandGoal();

	// let the element know that a team specific goal is about to be given
	SwatAIRepo.GetElementSquad().RemoveCommandGoalsFor(self);
}

function bool IsSubElement()
{
	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Need Orders Speech

function TriggerNeedOrdersSpeech()
{
	 if (NeedOrdersTimer != None)
	 {
		 NeedOrdersTimer.Destroy();
	 }

	 NeedOrdersTimer = Spawn(class'Timer', self);
	 NeedOrdersTimer.timerDelegate = InternalTriggerNeedOrdersSpeech;
	 NeedOrdersTimer.startTimer(NeedOrdersTriggerTimeDelta, false);
}

function InternalTriggerNeedOrdersSpeech()
{
	local int i;
	local Pawn Officer;

	if (! IsExecutingCommandGoal())
	{
		for(i=0; i<pawns.length; ++i)
		{
			Officer = pawns[i];

			if (class'Pawn'.static.checkConscious(Officer))
			{
				TriggerSquadSpecificNeedOrdersSpeech(Officer);
				break;
			}
		}
	}

	DestroyNeedOrdersTimer();
}

// overridden by subclasses
protected function TriggerSquadSpecificNeedOrdersSpeech(Pawn OfficerSpeaker);