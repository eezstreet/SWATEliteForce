//=============================================================================
// A camera, used in UnrealEd.
//=============================================================================
class Camera extends PlayerController
	native;

defaultproperties
{
     Location=(X=-500.000000,Y=-300.000000,Z=300.000000)
     Texture=Texture'Engine_res.S_Camera'
     CollisionRadius=+00016.000000
     CollisionHeight=+00039.000000
     LightBrightness=100
     LightRadius=16
	 bDirectional=1
}

