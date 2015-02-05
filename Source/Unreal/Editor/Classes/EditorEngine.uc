//=============================================================================
// EditorEngine: The UnrealEd subsystem.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class EditorEngine extends Engine.Engine
	native
	noexport
	transient;

#exec LOAD FILE=Editor_res.pkg

// Objects.
var const Engine.level       Level;
var const Engine.model       TempModel;
var const Engine.texture     CurrentTexture;
var const Engine.staticmesh  CurrentStaticMesh;
var const Engine.mesh		  CurrentMesh;
var const Core.class       CurrentClass;
var const Core.Object	  Trans;
var const Core.Object	  Results;
var const int         Pad[8];

// Textures.
var const Engine.texture Bad, Bkgnd, BkgndHi, BadHighlight, MaterialArrow, MaterialBackdrop;

// Used in UnrealEd for showing materials
var Engine.staticmesh	TexPropCube;
var Engine.staticmesh	TexPropSphere;

// Toggles.
var const bool bFastRebuild, bBootstrapping;

// Other variables.
var const config int AutoSaveIndex;
var const int AutoSaveCount, Mode, TerrainEditBrush, ClickFlags;
var const float MovementSpeed;
var const Core.package PackageContext;
var const vector AddLocation;
var const plane AddPlane;

// Misc.
var const array<Core.Object> Tools;
var const class BrowseClass;

// Grid.
var const int ConstraintsVtbl;
var(Grid) config bool GridEnabled;
var(Grid) config bool SnapVertices;
var(Grid) config float SnapDistance;
var(Grid) config vector GridSize;

// Rotation grid.
var(RotationGrid) config bool RotGridEnabled;
var(RotationGrid) config rotator RotGridSize;

// Advanced.
var(Advanced) config bool UseSizingBox;
var(Advanced) config bool UseAxisIndicator;
var(Advanced) config float FovAngleDegrees;
var(Advanced) config bool GodMode;
var(Advanced) config bool AutoSave;
var(Advanced) config byte AutosaveTimeMinutes;
var(Advanced) config string GameCommandLine;
var(Advanced) config array<string> EditPackages;
var(Advanced) config bool AlwaysShowTerrain;
var(Advanced) config bool UseActorRotationGizmo;
var(Advanced) config bool LoadEntirePackageWhenSaving;
#if IG_SHARED	// rowan: redraw viewports when moving actors
var(Advanced) config bool RedrawAllViewportsWhenMoving;
#endif

defaultproperties
{
     Bad=Texture'Editor_res.Bad'
     Bkgnd=Texture'Editor_res.Bkgnd'
     BkgndHi=Texture'Editor_res.BkgndHi'
	 MaterialArrow=Texture'Editor_res.MaterialArrow'
	 MaterialBackdrop=Texture'Editor_res.MaterialBackdrop'
	 BadHighlight=Texture'Editor_res.BadHighlight'
	 GridSize=(X=16,Y=16,Z=16)
	 TexPropCube=StaticMesh'Editor_res.TexPropCube'
	 TexPropSphere=StaticMesh'Editor_res.TexPropSphere'
}