//=============================================================================
// DecoVolumeObject.
//
// A class that allows staticmesh actors to get spawned inside of
// deco volumes.  These are the actors that you actually see in the level.
//=============================================================================
class DecoVolumeObject extends Actor
	native;

defaultproperties
{
	bStatic=False
	DrawType=DT_StaticMesh
	bWorldGeometry=false
	bCollideActors=false
	bBlockActors=false
	bBlockPlayers=false
	CollisionRadius=0
	CollisionHeight=0
}
