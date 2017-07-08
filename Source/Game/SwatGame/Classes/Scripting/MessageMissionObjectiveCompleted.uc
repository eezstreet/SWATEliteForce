class MessageMissionObjectiveCompleted extends Engine.Message
	editinlinenew;

var Name Objective;

// construct
overloaded function construct(Name inObjective)
{
    Objective = inObjective;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Mission Objective is Completed.";
}


defaultproperties
{
	specificTo = class'SwatGameInfo'
}
