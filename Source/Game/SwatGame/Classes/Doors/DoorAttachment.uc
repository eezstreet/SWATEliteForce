class DoorAttachment extends Engine.StaticMeshActor
	native;

cpptext
{
    void PredictedBoxAdjustmentHook(FBox& PredictedBox);
}

defaultproperties
{
//These are all of StaticMeshActor's defaults, commented-out if unchanged
//	DrawType=DT_StaticMesh
//	bEdShouldSnap=True
	bStatic=False
	bStaticLighting=False
//	bShadowCast=True
	bCollideActors=False
	bBlockActors=False
	bBlockPlayers=False
	bBlockKarma=False
	bWorldGeometry=False
//  CollisionHeight=+000001.000000
//	CollisionRadius=+000001.000000
	bAcceptsProjectors=True
//	bExactProjectileCollision=true
    bBlockHavok=false
    bStasis=true
}
