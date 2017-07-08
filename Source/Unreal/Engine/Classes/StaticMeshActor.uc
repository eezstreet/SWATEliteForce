//=============================================================================
// StaticMeshActor.
// An actor that is drawn using a static mesh(a mesh that never changes, and
// can be cached in video memory, resulting in a speed boost).
//=============================================================================

class StaticMeshActor extends Actor
#if IG_SHARED
#if !IG_SWAT
	hidecategories(Events, Force, LightColor, Lighting, Object, Sound)
#else  // !IG_SWAT
    // In SWAT we still want to see Events (at least for now)
	hidecategories(Force, LightColor, Lighting, Object, Sound)
#endif // !IG_SWAT
#endif // IG_SHARED
	native
	placeable;
#if IG_SWAT
var() bool bExactProjectileCollision;		// nonzero extent projectiles should shrink to zero when hitting this actor
var(Ballistics) float OverrideMomentumToPenetrate "If this is > -1, then OverrideMomentumToPenetrate is used instead of its Material's MomentumToPenetrate when calculating impact ballistics.";

simulated function float GetMomentumToPenetrate(vector HitLocation, vector HitNormal, Material MaterialHit)
{
    if (OverrideMomentumToPenetrate > -1)
        return OverrideMomentumToPenetrate;
    else
        return MaterialHit.MomentumToPenetrate;
}
#else
var(Collision) bool bExactProjectileCollision;		// nonzero extent projectiles should shrink to zero when hitting this actor
#endif

defaultproperties
{
    //TMC added OverrideMomentumToPenetrate
    OverrideMomentumToPenetrate=-1

	DrawType=DT_StaticMesh
	bEdShouldSnap=True
	bStatic=True
	bStaticLighting=True
	bShadowCast=True
	bCollideActors=True
	bBlockActors=True
	bBlockPlayers=True
	bBlockKarma=True
//#if IG_SWAT	// ckline: static meshes block havok by default (part of havok static world)
	bMovable=False
	bBlockHavok=True
//#endif
	bWorldGeometry=True
    CollisionHeight=+000001.000000
	CollisionRadius=+000001.000000
	bAcceptsProjectors=True
	bExactProjectileCollision=true
}
