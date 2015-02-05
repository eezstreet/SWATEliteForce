class MessageMissionObjectiveFailed extends Engine.Message
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
	return "A Mission Objective is Failed.";
}


defaultproperties
{
	specificTo = class'SwatGameInfo'
}
