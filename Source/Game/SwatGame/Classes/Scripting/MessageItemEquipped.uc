class MessageItemEquipped extends Engine.Message
	editinlinenew;

var Name Who;
var Name What;

// construct
overloaded function construct(Name inWho, Name inWhat)
{
    Who = inWho;
    What = inWhat;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Pawn Equips a piece of Handheld Equipment";
}


defaultproperties
{
	specificTo	= class'SwatPawn'
}
