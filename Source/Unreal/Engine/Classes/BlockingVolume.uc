//=============================================================================
// BlockingVolume:  a bounding volume
// used to block certain classes of actors
// primary use is to provide collision for non-zero extent traces around static meshes 

//=============================================================================

class BlockingVolume extends Volume
	native;

var() bool bClampFluid;

#if IG_SWAT
var() bool bIsStairs "Set this to true if this stairway is being as a ramp for stairs";
#endif

defaultproperties
{
    bBlockZeroExtentTraces=false
    bWorldGeometry=true
    bCollideActors=True
    bBlockActors=True
    bBlockPlayers=True
    bBlockKarma=True
    bClampFluid=True
//#if IG_SWAT // ckline: have sniper/staircase volumes occluded by geometry in editor
    bOccludedByGeometryInEditor=true
//#endif
}