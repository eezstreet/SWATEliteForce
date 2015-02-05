///////////////////////////////////////////////////////////////////////////////
// ClearRoutePoint.uc - ClearRoutePoint class
// A point that Officer AIs will use when clearing a room.  It is a hint for 
// the route they should take to get to a ClearPoint.

class ClearRoutePoint extends Engine.PathNode
	native
	placeable;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var()	edfindable ClearPoint	ClearPoint			"The ClearPoint we are associated with";
var()	int						ClearRoutePriority	"The priority of our point out of all ClearRoutePoints to our ClearPoint";

///////////////////////////////////////////////////////////////////////////////

cpptext
{
	virtual void CheckForErrors();
	virtual void RenderEditorSelected(FLevelSceneNode* SceneNode,FRenderInterface* RI, FDynamicActor* FDA);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bHidden = true
	Texture=Texture'Swat4EditorTex.ClearRoutePoint'
	
	; Collision defaults should be the same as NavigationPoint
	CollisionRadius=+00030.000000
    CollisionHeight=+00080.000000
}