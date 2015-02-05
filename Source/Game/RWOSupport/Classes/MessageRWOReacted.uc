class MessageRWOReacted extends Engine.Message
	editinlinenew;

var Name RWO;

// construct
overloaded function construct(Name _RWO, Name _instigator)
{
    RWO = _RWO;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return triggeredBy$" executes a Reaction_RunScript";
}


defaultproperties
{
    specificTo = class'ReactiveWorldObject'
}
