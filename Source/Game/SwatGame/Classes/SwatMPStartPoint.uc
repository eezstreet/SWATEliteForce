// This class represents a start point for a player in a multiplayer game. It
// is explicitly NOT a subclass of PlayerStart because we don't want it to
// interfere with the single-player navigation and awareness code.
class SwatMPStartPoint extends Engine.Actor 

	native;

var editconst float LastSpawnCampTime; 
var() editconst SwatMPStartCluster Cluster "This is the start cluster with which this start point is associated";
var	const bool	bNotBased;		// used by path builder - if true, no error reported if node doesn't have a valid base

///////////////////////////////////////////////////////////////////////////////

cpptext 
{
	virtual void CheckForErrors();
	virtual void PostEditChange();
	virtual void RenderEditorSelected(FLevelSceneNode* SceneNode,FRenderInterface* RI, FDynamicActor* FDA);
	virtual void FindBase();
	virtual UBOOL ShouldBeBased();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{	
    bDirectional=True
	DrawType=DT_Sprite
    Texture=Texture'EditorSprites.SwatMPStartPoint'
	bNotBased=false
    bNoDelete=true
    bHidden=true
    bCollideWhenPlacing=true

	// WARNING: these collision sizes should be the same as the ones in SwatPawn
    CollisionRadius=24
    CollisionHeight=68

    bCollideActors=true
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=true

    bStatic=false
    bStasis=true
    Physics=PHYS_None
}
