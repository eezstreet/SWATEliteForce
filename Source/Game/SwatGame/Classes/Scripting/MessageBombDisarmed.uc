class MessageBombDisarmed extends Engine.Message
	editinlinenew;

var Name SpawnerGroup;
var Name Spawner;

// construct
overloaded function construct(Name inSpawnerGroup, Name inSpawner)
{
    SpawnerGroup = inSpawnerGroup;
    Spawner = inSpawner;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A bomb is disarmed.";
}

defaultproperties
{
	specificTo	= class'GameModeRD'
}
