class MessageCommandGiven extends Engine.Message
	editinlinenew;

var Name Command;
var Name Team;
var Name Door;

// construct
overloaded function construct(Name inCommand, Name inTeam, name inDoor)
{
    Command = inCommand;
    Team = inTeam;
    Door = inDoor;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The Player gives a command with the CommandInterface";
}


defaultproperties
{
	specificTo	= class'CommandInterface'
}
