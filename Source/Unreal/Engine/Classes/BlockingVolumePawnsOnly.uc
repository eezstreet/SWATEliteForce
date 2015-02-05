//=============================================================================
// BlockingVolumePawnsOnly:  
// A variant of BlockingVolume that *only* blocks pawns. It does not block 
// traces, other actors, etc.
//
//=============================================================================

class BlockingVolumePawnsOnly extends BlockingVolume
    hidecategories(Object,Advanced,Collision,Display,Havok,LightColor,Movement)
    native;

var() bool bOfficersOnly;

defaultproperties
{
    bBlockZeroExtentTraces=false
    bWorldGeometry=False
    bCollideActors=True
    bBlockActors=True
    bBlockPlayers=True
    bBlockKarma=False
    bBlockHavok=False
//#if IG_SWAT // ckline: have sniper/staircase volumes occluded by geometry in editor
    bOccludedByGeometryInEditor=true
//#endif
    BrushColor=(R=236,G=250,B=69,A=0)
}