class MessageFlashbangGrenadeDetonated extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A Flashbang Grenade Detonates.";
}


defaultproperties
{
	specificTo	= class'SwatGrenadeProjectile'
}
