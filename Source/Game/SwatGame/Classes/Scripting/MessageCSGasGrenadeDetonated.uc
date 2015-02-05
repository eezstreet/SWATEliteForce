class MessageCSGasGrenadeDetonated extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A CSGas Grenade Detonates.";
}


defaultproperties
{
	specificTo	= class'SwatGrenadeProjectile'
}
