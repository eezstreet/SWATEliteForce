//=============================================================================
// The brush class.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Brush extends Actor
	hidecategories(Events, Force, Karma, LightColor, Lighting, Sound, Object)
	native;

//-----------------------------------------------------------------------------
// Variables.

// CSG operation performed in editor.
var() enum ECsgOper
{
	CSG_Active,			// Active brush.
	CSG_Add,			// Add to world.
	CSG_Subtract,		// Subtract from world.
	CSG_Intersect,		// Form from intersection with world.
	CSG_Deintersect,	// Form from negative intersection with world.
} CsgOper;

// Outdated.
var const Core.Object UnusedLightMesh;
var vector  PostPivot;

// Scaling.
// Outdated : these are only here to allow the "ucc mapconvert" commandlet to work.
//            They are NOT used by the engine/editor for anything else.
var scale MainScale;
var scale PostScale;
var scale TempScale;

// Information.
var() config color BrushColor;
var() int	PolyFlags;
var() bool  bColored;

#if IG_SHARED	// rowan: renderable brushes
var() Material	RenderMaterial;
var() Vector	RenderMaterialWorldSize;
#endif

defaultproperties
{
     MainScale=(Scale=(X=1,Y=1,Z=1),SheerRate=0,SheerAxis=SHEER_None)
     PostScale=(Scale=(X=1,Y=1,Z=1),SheerRate=0,SheerAxis=SHEER_None)
     TempScale=(Scale=(X=1,Y=1,Z=1),SheerRate=0,SheerAxis=SHEER_None)
     bStatic=True
	 bHidden=True
     bNoDelete=True
     bEdShouldSnap=True
     DrawType=DT_Brush
     bFixedRotationDir=True
}
