class MessageFirstShotFired extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The first shot from a FiredWeapon is fired.";
}


defaultproperties
{
	specificTo	= None
}
