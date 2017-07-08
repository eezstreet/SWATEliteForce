//=============================================================================
// PathNode.
//=============================================================================
class PathNode extends NavigationPoint
	placeable
	native;

cpptext
{
	virtual UBOOL ReviewPath(APawn* Scout);
	virtual void CheckSymmetry(ANavigationPoint* Other);
	virtual INT AddMyMarker(AActor *S);
}

defaultproperties
{
     Texture=Texture'Engine_res.S_Pickup'
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//   SoundVolume=128
//#endif
     bPropagatesSound=True
}
