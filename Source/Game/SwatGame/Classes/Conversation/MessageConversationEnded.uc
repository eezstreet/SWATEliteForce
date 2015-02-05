class MessageConversationEnded extends Engine.Message
    editinlinenew;

var bool Completed;

// construct
overloaded function construct(bool inCompleted)
{
    Completed = inCompleted;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A conversation ends";
}


defaultproperties
{
	specificTo	= class'Conversation'
}
