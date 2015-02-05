class DynamicFlashlightLight extends DynamicLight
    notplaceable;

defaultproperties
{
    bStatic=false
    bNoDelete=false
    bStasis=false
	bHidden=false
    bMovable=true
	bDirectional=true
	// traces should not hit this even if the light sprite is showing
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
	bWeaponTestsPassThrough=true

	// light effects (like a gun's flashlight) should not be limited to current zone
	bOnlyAffectCurrentZone=false
    bImportantDynamicLight=true
    LightEffect=LE_Spotlight
	LightCone=25
	LightRadius=45
    LightBrightness=180
    RemoteRole=ROLE_None
}
