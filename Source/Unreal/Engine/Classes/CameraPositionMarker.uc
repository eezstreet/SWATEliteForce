class CameraPositionMarker extends Actor
	hidecategories(Collision, Force, Karma, LightColor, Lighting, Object, Sound)
    placeable;


defaultproperties
{
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bBlockPlayers=false
    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=true
    bBlockKarma=false
	bHidden=true
	bStasis=true
	bStatic=true
	DrawType=DT_Sprite
	Physics=PHYS_None
	bAlwaysRelevant=true
    Texture=Material'EditorSprites.S_CameraPositionMarker'
}
