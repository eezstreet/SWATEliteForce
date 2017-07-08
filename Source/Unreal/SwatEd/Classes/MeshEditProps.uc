//=============================================================================
// Object to facilitate properties editing
//=============================================================================
//  Animation / Mesh editor object to expose/shuttle only selected editable 
//  parameters from UMeshAnim/ UMesh objects back and forth in the editor.
//  
 
class MeshEditProps extends Engine.MeshObject
	hidecategories(Object)
	native;	

cpptext
{
	void PostEditChange();
}

import enum ESkeletalRegion from Engine.Actor;

// Static/smooth parts
struct native FSectionDigest
{
	var() EMeshSectionMethod  MeshSectionMethod;
	var() int     MaxRigidParts;
	var() int     MinPartFaces;
	var() float   MeldSize;
};

// LOD 
struct native LODLevel
{
	var() float   DistanceFactor;
	var() float   ReductionFactor;	
	var() float   Hysteresis;
	var() int     MaxInfluences;
	var() bool    RedigestSwitch;
	var() FSectionDigest Rigidize;
};

struct native AttachSocket
{
	var() vector  A_Translation;
	var() rotator A_Rotation;
	var() name AttachAlias;	
	var() name BoneName;		
	var() float      Test_Scale;
	var() Engine.mesh       TestMesh;
	var() Engine.staticmesh TestStaticMesh;	
};

struct native MEPBonePrimSphere
{
	var() name		BoneName;
	var() vector	Offset;
	var() float		Radius;
};


struct native MEPBonePrimBox
{
	var() name		         BoneName;
    var() ESkeletalRegion        SkeletalRegion;
    var() vector	         Offset;
	var() vector	         Radii;
};

#if IG_SHARED	// rowan: skeletal static mesh standins
struct native MEPBonePrimStaticMesh
{
	var() name			BoneName;
	var() vector		Offset;
	var() staticmesh	StaticMesh;
};
#endif

var const int WBrowserAnimationPtr;
var(Mesh) vector			 Scale;
var(Mesh) vector             Translation;
var(Mesh) rotator            Rotation;
var(Mesh) vector             MinVisBound;
var(Mesh) vector			 MaxVisBound;
var(Mesh) vector             VisSphereCenter;
var(Mesh) float              VisSphereRadius;

var(Redigest) int            LODStyle; //Make drop-down box w. styles...
var(Animation) Engine.MeshAnimation DefaultAnimation;

var(Skin) array<Engine.Material>					Material;

// To be implemented: - material order specification to re-sort the sections (for multiple translucent materials )
// var(RenderOrder) array<int>					MaterialOrder;
// To be implemented: - originalmaterial names from Maya/Max
// var(OriginalMaterial) array<name>			OrigMat;

var(LOD) float            LOD_Strength;
var(LOD) array<LODLevel>  LODLevels;
var(LOD) float				SkinTesselationFactor;

// Collision cylinder: for testing/preview only, not saved with mesh (Actor property !)
var(Collision) float TestCollisionRadius;	// Radius of collision cyllinder.
var(Collision) float TestCollisionHeight;	// Half-height cyllinder.

var(Collision) array<MEPBonePrimSphere>		CollisionSpheres;		// Array of spheres linked to bones
var(Collision) array<MEPBonePrimBox>		CollisionBoxes;			// Array of boxes linked to bones
#if IG_SHARED	// rowan: skeletal static mesh standins
var(Collision) array<MEPBonePrimStaticMesh> CollisionStaticMeshes;	// Array of static meshes linked to bones
#endif

var(Attach) array<AttachSocket>   Sockets;  // Sockets, with or without adjustment coordinates / bone aliases.
var(Attach) bool  ApplyNewSockets;			// Explicit switch to apply changes 
var(Attach) bool  ContinuousUpdate;			// Continuous updating (to adjust socket angles interactively)

var(Impostor) bool      bImpostorPresent;
var(Impostor) Engine.Material  SpriteMaterial;
var(Impostor) vector    Scale3D;
var(Impostor) rotator   RelativeRotation;
var(Impostor) vector    RelativeLocation;
var(Impostor) color     ImpColor;           // Impostor base coloration.
var(Impostor) EImpSpaceMode  ImpSpaceMode;   
var(Impostor) EImpDrawMode   ImpDrawMode;
var(Impostor) EImpLightMode  ImpLightMode;

defaultproperties
{	
	Scale=(X=1,Y=1,Z=1)
	Scale3D=(X=1.0,Y=1.0,Z=1.0)
	Rotation=(Pitch=0,Yaw=0,Roll=0)
	Translation=(X=0,Y=0,Z=0)
	SkinTesselationFactor=1.0;
	ApplyNewSockets=false;
//#if IG_SHARED  // Ryan: Allow the user to choose if ContinuousUpdate is true or false
	ContinuousUpdate=true;	
//#else
//	ContinuousUpdate=false;	
//#endif
	ImpSpaceMode=ISM_PivotVertical;
	ImpDrawMode=IDM_Normal;
	ImpLightMode=ILM_Unlit;	
	
}
