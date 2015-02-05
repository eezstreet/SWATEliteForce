class MessageTargetInanimateDisabled extends Engine.Message
	editinlinenew;

var Name Objective;
var Name Disabler;
var int RemainingTargetInanimates;

// construct
overloaded function construct(Name inObjective, name inDisabler, int inRemainingTargetInanimates)
{
    Objective = inObjective;
    Disabler = inDisabler;
    RemainingTargetInanimates = inRemainingTargetInanimates;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Target Inanimate is Disabled.";
}


defaultproperties
{
	specificTo = class'SwatGameInfo'
}
