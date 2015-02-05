class Projector extends Actor
	placeable
	hidecategories(Collision, Force, Karma, LightColor, Lighting, Object, Sound)
	native;

// Projector blending operation.

enum EProjectorBlending
{
	PB_None,
	PB_Modulate,
	PB_AlphaBlend,
	PB_Add,
	PB_AlphaModulate,
};

var() EProjectorBlending	MaterialBlendingOp,		// The blending operation between the material being projected onto and ProjTexture.
							FrameBufferBlendingOp;	// The blending operation between the framebuffer and the result of the base material blend.

// Projector properties.

var() Material	ProjTexture;
var() int		FOV;
var() int		MaxTraceDistance;
var() bool		bProjectBSP;
var() bool		bProjectTerrain;
var() bool		bProjectStaticMesh;
var() bool		bProjectParticles;
var() bool		bProjectActor;
var() bool		bLevelStatic;
var() bool		bClipBSP;
var() bool		bClipStaticMesh;
var() bool		bProjectOnUnlit;
var() bool		bGradient;
var() bool		bProjectOnBackfaces;
#if IG_SHARED && !IG_SWAT // ckline: disabled rowan's CL 52956 because it caused artifacts
var() bool
#else
var bool
#endif
                bProjectOnAlpha "If false, the projector will ignore the target surface's opacity channel when projecting onto it. You probably want to leave this set to true"; 
var bool		bProjectOnParallelBSP; // note: this parameter is unused since warfare 2110
#if IG_SHARED // henry: allow shifting of the near frustum clip plane (used in ShadowProjector.uc)
var() bool		bShiftNearClip "Activate near clip plane shifting";
var() float		NearClipShiftAmount "The projector near clip plane is shifted this many units towards the projector origin from the projector's Location.";
#endif

var() name		ProjectTag;
var() bool		bDynamicAttach;
var() bool		bNoProjectOnOwner "If true, this projector will not project on an actor that owns it. Only applicable to DynamicProjectors";
var() float		FadeInTime "Projector will fade in over this amount of time, in seconds. A value of 0 means 'appear instantly'";

// Internal state.

var const transient plane FrustumPlanes[6];
var const transient vector FrustumVertices[8];
var const transient Box Box;
var const transient ProjectorRenderInfoPtr RenderInfo;
var Texture GradientTexture;
var transient Matrix GradientMatrix;
var transient Matrix Matrix;
var transient Vector OldLocation;

// Native interface.

native function AttachProjector(optional float FadeInTime);
native function DetachProjector(optional bool Force);
native function AbandonProjector(optional float Lifetime);

native function AttachActor( Actor A );
native function DetachActor( Actor A );

simulated event PostBeginPlay()
{
	if ( Level.NetMode == NM_DedicatedServer )
	{
		GotoState('NoProjection');
		return;
	}

	AttachProjector( FadeInTime );
	if( bLevelStatic )
	{
#if IG_SHARED // ckline: projectors cannot be both bLevelStatic and bDynamicAttach!
        assertWithDescription(!bDynamicAttach, "Projector "$Name$" is both bLevelStatic=true and bDynamicAttach=true -- this is not allowed and will probably cause the game to crash soon"); 
#endif
		AbandonProjector();
		Destroy();
	}
	if( bProjectActor )
		SetCollision(True, False, False);
}

simulated event Touch( Actor Other )
{
	if(Other==None)
		return;

	if( Other.bAcceptsProjectors
	    && (ProjectTag=='' || Other.Tag==ProjectTag)
	    && (bProjectStaticMesh || Other.StaticMesh==None)
	    && !(Other.bStatic && bStatic && Other.StaticMesh!=None) )
	{
	    AttachActor(Other);
        }
}

simulated event Untouch( Actor Other )
{
	DetachActor(Other);
}
 
#if IG_SHARED	// rowan: call back before dynamic projectors are rendererd
native final function UpdateMatrix();
simulated event PreRenderCallback() {}
#endif

state NoProjection
{
	function BeginState()
	{
		Disable('Tick');
	}
}

defaultproperties
{
	MaterialBlendingOp=PB_None
	FrameBufferBlendingOp=PB_Modulate
	FOV=0
	bDirectional=True
	Texture=Texture'Engine_res.Proj_Icon'
    //MaxTraceDistance=1000
    MaxTraceDistance=200 // SWAT has smaller spaces
	bProjectBSP=True
    //bProjectTerrain=True
    bProjectTerrain=False  // SWAT does not have terrain
	bProjectStaticMesh=True
	//bProjectParticles=True
	bProjectParticles=False // Better default for SWAT
	bProjectActor=True
	bProjectOnAlpha=True
	bClipBSP=False
	bClipStaticMesh=False
	//bLevelStatic=False
	bLevelStatic=True // better default for SWAT
	bProjectOnUnlit=False
	bHidden=True
	bStatic=True
	GradientTexture=Texture'Engine_res.GRADIENT_Fade'
	bProjectOnBackfaces=False
	bDynamicAttach=False
	RemoteRole=ROLE_None
	CullDistance=0
// #if IG_SHARED // ckline TODO: turn this on (but turn off for shadowprojectors
    bOnlyAffectCurrentZone=true
// #endif
}