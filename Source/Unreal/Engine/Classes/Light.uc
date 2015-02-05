//=============================================================================
// The light class.
//=============================================================================
class Light extends Actor
	placeable
	hidecategories(Karma, Force, Collision, Object, Sound)
	native;

var (Corona)	float	MinCoronaSize;
var (Corona)	float	MaxCoronaSize;
var (Corona)	float	CoronaRotation;
var (Corona)	float	CoronaRotationOffset;
var (Corona)	bool	UseOwnFinalBlend;

defaultproperties
{
     bStatic=True
     bHidden=True
     bNoDelete=True
     Texture=Texture'Engine_res.S_Light'
     CollisionRadius=+00024.000000
     CollisionHeight=+00024.000000
     LightType=LT_Steady
     LightBrightness=128 // ckline: changed from 64 for SWAT
     LightSaturation=255
     LightRadius=14 // ckline: changed from 64 for SWAT
     LightPeriod=32
     LightCone=128
     bMovable=False
     MinCoronaSize=0;
     MaxCoronaSize=250 // ckline: changed from 1000 for SWAT
// #if IG_ZONECONSTRAINED_LIGHTS 
     bOnlyAffectCurrentZone=true
// #endif
}
