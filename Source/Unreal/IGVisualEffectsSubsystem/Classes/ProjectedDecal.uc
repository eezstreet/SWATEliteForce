// WARNING: ProjectedDecals should not be placeable; only spawned at runtime by the IGVisualEffectsSubsystem 
// for things like bullet decals, explosion marks, etc. ProjectedDecals just attach to the Target actor, then
// destroy themselves. Because of the changes made via IG_FASTER_PROJECTORS_ON_DYNAMIC_GEOMETRY, they
// will leave behind proper clipped decals on the static meshes they attach to.
//
// WARNING: ProjectedDecals will never work on SkeletalMeshes (at least, never work correctly!).

class ProjectedDecal extends Engine.Projector
	notplaceable;

var() float PreferredDistance "The distance away from the target (in the direction of the normal to the surface) at which the decal will be located. WARNING! This value must be smaller than MaxTraceDistance, or else you will not see the decal.";
var() bool  RandomOrient "If true, the decal will be given a random rotation around the normal to the surface";

var Actor Target;

simulated event PostBeginPlay()
{
	// We purposefully do not call super.PostBeginPlay() because
	// we don't want to attach and change collision settings until
	// we get to Init(). This is because the effects system positions
	// the projector after it is spawned, and if we attach before
	// init is called then the projector will not be in the correct
	// position at the time of attachment
}

simulated function Init()
{
    local Vector RX, RY, RZ;
    local Rotator R;

	// Note: UT2K3 does this is PreBeginPlay, which is probably more efficient. 
	// However, if the projector is destroyed in PreBeginPlay/PostBeginPlay, then the Spawn()
	// call that created it will return None, thus causing the Effects system 
	// to treat it as an error.
    if ( (Level.DecalStayScale == 0.f) || Level.NetMode == NM_DedicatedServer )
    {
		//Log("++++++++++++++++ PostBeginPlay() Destroying newborn ProjectedDecal "$self$" because Level.DecalStayScale="$Level.DecalStayScale$" and Level.NetMode="$Level.NetMode);
        Destroy();
        return;
    }
    
    // adjust initial orientation
    if( RandomOrient )
    {
        R.Yaw = 0;
        R.Pitch = 0;
        R.Roll = Rand(65535);
        GetAxes(R,RX,RY,RZ);
        RX = RX >> Rotation;
        RY = RY >> Rotation;
        RZ = RZ >> Rotation;         
        R = OrthoRotation(RX,RY,RZ);
        SetRotation(R);
    }
		
	// Set preferred distance from hit location
    SetLocation( Location - Vector(Rotation)*PreferredDistance );   

    
    AttachProjector();

	if( bProjectActor )
	{
		// necessary when bHardAttach is true
		SetCollision(True, False, False);
}

    SetBase(Target);

	// Additional scale factor on the decal stay scale
    if ( Level.bDropDetail )
		LifeSpan *= 0.5;
    
    // Set max lifespan of the decal
    AbandonProjector(LifeSpan*Level.DecalStayScale);
	
	// Destroy the projector actor (the actual decal geometry will stick around 
	// for the LifeSpan that was passed to AbandonProjector)
    Destroy();
}

event Tick(float DeltaTime)
{
    //AddDebugMessage(""$self);
    //log("++++++++++++++++ Tick() called on ProjectedDecal "$self);
    Super.Tick(DeltaTime);
}
event Destroyed()
{
    //log("++++++++++++++++ Destroyed() called on "$self);
    Super.Destroyed();
}

defaultproperties
{
    bNoDelete=false
    bStatic=false

    PreferredDistance=1
	FOV=1
	MaxTraceDistance=2
	bProjectBSP=true
	bProjectTerrain=true
	bProjectStaticMesh=true
	bClipBSP=true
	bClipStaticMesh=true

    MaterialBlendingOp=PB_None
	FrameBufferBlendingOp=PB_AlphaBlend

    RandomOrient=true

    bHardAttach=true

    LifeSpan = 30

	// Projected decals like bullet hits should not attach to skeletal mesh,
	// because it won't look right when the mesh animates and it's also 
	// REALLY slow. 
	bProjectActor=false

    bOnlyAffectCurrentZone=false
}
