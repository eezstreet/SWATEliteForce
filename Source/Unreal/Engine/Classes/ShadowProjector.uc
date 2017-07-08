//
//	ShadowProjector
//

class ShadowProjector extends Projector
	native;

var() Actor					ShadowActor;
var() vector				LightDirection;
var() float					LightDistance;
var() bool					RootMotion;
var() bool					bBlobShadow;
var() bool					bShadowActive;
#if IG_SHARED // henry: shadow projector fix
var() bool					bDebugShadow "visualize shadow volumes";  // henry: visualize shadow volumes
var() float                 ShadowExtraBoundary "This is a fudge amount to add to the ShadowActor's bounding sphere's size to make sure the shadow volume encompassed the whole ShadowActor";
#endif
#if IG_SWAT
var() float                 ShadowExtraDrawScale "This allows us to contol the scale of the shadow texture when it is rendered onto the world";
#endif
var ShadowBitmapMaterial	ShadowTexture;

#if IG_DYNAMIC_SHADOW_DETAIL
var() int					Resolution;
native final function UpdateDetailSetting();
#endif

//
//	PostBeginPlay
//

event PostBeginPlay()
{
	local int ShadowDetail;

	Super(Actor).PostBeginPlay();
	
	//New "High"-quality shadow quality setting. Enables casting shadows on actors. -K.F.
	ShadowDetail = int(Level.GetLocalPlayerController().ConsoleCommand( "SHADOWDETAIL GET" ) );
	if (ShadowDetail >= 3) //3 = "high"
	{
		bProjectActor = true;
	}
}

//
//	Destroyed
//

event Destroyed()
{
	if(ShadowTexture != None)
	{
		ShadowTexture.ShadowActor = None;

		if(!ShadowTexture.Invalid)
			Level.ObjectPool.FreeObject(ShadowTexture);

		ShadowTexture = None;
		ProjTexture = None;
	}

	Super.Destroyed();
}

//
//	InitShadow
//

function InitShadow()
{
	local Plane BoundingSphere;

	if(ShadowActor != None)
	{
		BoundingSphere = ShadowActor.GetRenderBoundingSphere();
#if IG_SHARED // henry: shadow projector fix
		FOV = 2.0f * Atan(BoundingSphere.W + ShadowExtraBoundary, LightDistance) * 180 / PI;
#else
		FOV = Atan(BoundingSphere.W * 2.0f + 160, LightDistance) * 180 / PI;
#endif
		ShadowTexture = ShadowBitmapMaterial(Level.ObjectPool.AllocateObject(class'ShadowBitmapMaterial'));

#if 1 // HACK HACK HACK: 
        // Some older cards don't support the BORDER D3D texture addressing mode.
        // in these cases, just fall back to CLAMP mode, because otherwise
		// the shadows will tile across the surface of static meshes
        
		log("Checking for support of Border texture addressing mode");
        if (false == bool(ConsoleCommand( "SUPPORTS_BORDER_TEXTURE_ADDRESSING") ))
        {
            log("  -> Does NOT support Border texture addressing mode");
	        ShadowTexture.UClampMode=TC_Clamp;
	        ShadowTexture.VClampMode=TC_Clamp;
        }
        else
        {
            log("  -> Supports Border texture addressing mode");
        }
#endif

		ProjTexture = ShadowTexture;

		if(ShadowTexture != None)
		{
#if IG_DYNAMIC_SHADOW_DETAIL	// rowan: variable resolution
			ShadowTexture.SetResolution(Resolution);
#endif
#if IG_SWAT // ShadowExtraDrawScale allows us to better control how the shadow texture is scaled. [darren]
			SetDrawScale(ShadowExtraDrawScale * LightDistance * Tan(0.5 * FOV * Pi / 180) / (0.5 * ShadowTexture.USize));
#else
			SetDrawScale(LightDistance * Tan(0.5 * FOV * Pi / 180) / (0.5 * ShadowTexture.USize));
#endif

			ShadowTexture.Invalid = False;
			ShadowTexture.bBlobShadow = bBlobShadow;
			ShadowTexture.ShadowActor = ShadowActor;
			ShadowTexture.LightDirection = Normal(LightDirection);
			ShadowTexture.LightDistance = LightDistance;
			ShadowTexture.LightFOV = FOV;
            ShadowTexture.CullDistance = CullDistance; 

			Enable('Tick');
			AttachProjector();
			UpdateShadow();
		}
		else
			Log(Name$".InitShadow: Failed to allocate texture");
	}
	else
		Log(Name$".InitShadow: No actor");
}

//
//	UpdateShadow
//

native final function UpdateShadow();

//
//	Tick
//

function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	UpdateShadow();
}

simulated event PreRenderCallback()
{
	// update root motion position now
	if(ShadowTexture != None)
		SetLocation(ShadowTexture.GetShadowLocation());
	SetRotation(Rotator(Normal(-LightDirection)));

	// must call this after setting location/rotation
	UpdateMatrix();	

#if IG_DYNAMIC_SHADOW_DETAIL	// rowan: handle dynamic detail changes
	UpdateDetailSetting();
#endif
}

#if IG_SHARED // ckline: selectively prevent actors from receiving ShadowProjector shadows
simulated event Touch( Actor Other )
{
	if(Other==None || !Other.bAcceptsShadowProjectors)
		return;

    Super.Touch(Other);
}
#endif

//
//	Default properties
//

defaultproperties
{
	bShadowActive=True
	bProjectActor=False
	bProjectOnParallelBSP=True
	bProjectOnAlpha=True
	bClipBSP=True
	bGradient=True
	bStatic=False
	bOwnerNoSee=True
	bBlobShadow=False
	RemoteRole=ROLE_None
	// Note: SwatPawns set the culldistance in their shadows explicitly, so this will get overridden with the SwatPawn's ShadowCullDistance
    CullDistance=600.0
    bDynamicAttach=True
    bCollideActors=False
	bCollideWorld=False
    bLevelStatic=False
    
//#if IG_DYNAMIC_SHADOW_DETAIL	// rowan: variable resolution
	Resolution = 128
//#endif

// #if IG_SHARED // ckline TODO: turn this on (but turn off for shadowprojectors
    bOnlyAffectCurrentZone=false
// #endif
// #if IG_SHARED // henry: shadow projector fix
    ShadowExtraBoundary=0
// #endif
// #if IG_SWAT
    ShadowExtraDrawScale=1.0
// #endif
//#if IG_SHARED // henry: allow shifting of the near frustum clip plane so shadows won't be clipped too low on BSP walls
	bShiftNearClip=true
	NearClipShiftAmount=40
//#endif
}
