class MessageStingGrenadeDetonated extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Sting Grenade Detonates.";
}


defaultproperties
{
	specificTo	= class'SwatGrenadeProjectile'
}
