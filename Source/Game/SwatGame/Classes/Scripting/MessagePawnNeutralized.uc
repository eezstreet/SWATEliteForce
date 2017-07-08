class MessagePawnNeutralized extends Engine.Message
	editinlinenew;

var Name Neutralizer;
var Name Neutralizee;

// construct
overloaded function construct(Name inNeutralizer, Name inNeutralizee)
{
    Neutralizer = inNeutralizer;
    Neutralizee = inNeutralizee;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Pawn is neutralized (arrested, killed, incapacitated)";
}

defaultproperties
{
	specificTo=class'Pawn'
}
