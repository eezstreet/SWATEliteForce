class MessageUsed extends Engine.Message
	editinlinenew;

var Name User;
var Name Usee;

// construct
overloaded function construct(Name inUser, Name inUsee)
{
    User = inUser;
    Usee = inUsee;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
    if (TriggeredBy != '')
        return triggeredBy $ " is Used";
    else
        return "Something is Used";
}

defaultproperties
{
	specificTo	= class'Actor'
}
