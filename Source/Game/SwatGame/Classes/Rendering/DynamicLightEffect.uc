class DynamicLightEffect extends DynamicLight
    notplaceable;

defaultproperties
{
    bNoDelete=false
    bStasis=false

	// light effects (light gunfire flashes) should not be limited to current zone
	bOnlyAffectCurrentZone=false

    // light effects should always be un-important by default
    bImportantDynamicLight=false
}
