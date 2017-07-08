class FluidSurfaceInfo extends Info
	showcategories(Movement,Collision,Lighting,LightColor,Karma,Force)
	native
	noexport
	placeable;

var () enum EFluidGridType
{
	FGT_Square,
	FGT_Hexagonal
} FluidGridType;

var () float						FluidGridSpacing; // distance between grid points
var () int							FluidXSize; // num vertices in X direction
var () int							FluidYSize; // num vertices in Y direction

var () float						FluidHeightScale; // vertical scale factor

var () float						FluidSpeed; // wave speed
var () float						FluidDamping; // between 0 and 1

var () float						FluidNoiseFrequency;
var () range						FluidNoiseStrength;

var () bool							TestRipple;
var () float						TestRippleSpeed;
var () float						TestRippleStrength;
var () float						TestRippleRadius;

var () float						UTiles;
var () float						UOffset;
var	() float						VTiles;
var () float						VOffset;
var () float						AlphaCurveScale;
var () float						AlphaHeightScale;
var () byte 						AlphaMax;

var () float						ShootStrength; // How hard to ripple water when shot
var () float						ShootRadius; // How large a radius is affected when water is shot

// How much to ripple the water when interacting with actors
var () float						RippleVelocityFactor;
var () float						TouchStrength;

// Class of effect spawned when water surface it shot or touched by an actor
var () class<Actor>					ShootEffect;
var () bool							OrientShootEffect;

var () class<Actor>					TouchEffect;
var () bool							OrientTouchEffect;

// Bitmap indicating which water verts are 'clamped' ie. dont move
var const array<int>				ClampBitmap;

// Terrain used for auto-clamping water verts if below terrain level.
var () edfindable TerrainInfo		ClampTerrain;

var () bool							bShowBoundingBox;
var () bool							bUseNoRenderZ;
var () float						NoRenderZ;

// Amount of time to simulate during postload before water is first displayed
var () float						WarmUpTime;

// Rate at which fluid sim will be updated
var () float						UpdateRate;

var () color						FluidColor;

// Sim storage
var transient const array<float>	Verts0;
var transient const array<float>	Verts1;
var transient const array<byte>		VertAlpha;

var transient const int				LatestVerts;

var transient const box				FluidBoundingBox;	// Current world-space AABB
var transient const vector			FluidOrigin;		// Current bottom-left corner

var transient const float			TimeRollover;
//var transient const float			AverageTimeStep;
//var transient const int  			StepCount;
var transient const float			TestRippleAng;

var transient const FluidSurfacePrimitive Primitive;
var transient const array<FluidSurfaceOscillator>	Oscillators;
var transient const bool			bHasWarmedUp;

// Functions

// Ripple water at a particlar location.
// Ignores 'z' componenet of position.
native final function Pling(vector Position, float Strength, optional float Radius);

// Default behaviour when shot is to apply an impulse and kick the KActor.
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
simulated function PostTakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#else
simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#endif
{
	//Log("FS TakeDam:"$hitlocation@damageType);

	// Vibrate water at hit location.
	Pling(hitLocation, ShootStrength, ShootRadius);

	// If present, spawn splashy hit effect.
	if( (ShootEffect != None) && EffectIsRelevant(HitLocation,false) )
	{
		if(OrientShootEffect)
			spawn(ShootEffect, self, , hitLocation, rotator(momentum));
		else
			spawn(ShootEffect, self, , hitLocation);
	}
}

simulated function Touch(Actor Other)
{
	local vector touchLocation;

	Super.Touch(Other);

	if( (Other == None) || !Other.bDisturbFluidSurface )
		return;

	touchLocation = Other.Location;

	// Now projectiles affect water by Touch instead of TakeDamage, use ShootStrength here.
	//Log("FS Touch:"$ShootStrength@Other.CollisionRadius);


	//Pling(touchLocation, TouchStrength, Other.CollisionRadius);
	Pling(touchLocation, ShootStrength, Other.CollisionRadius);

	// JTODO: Fix for non-horizontal fluid
	touchLocation.Z = Location.Z;
	if( (TouchEffect != None) && EffectIsRelevant(touchLocation,false) )
	{
		if(OrientTouchEffect)
			spawn(TouchEffect, self, , touchLocation, rotator(Other.Velocity));
		else
			spawn(TouchEffect, self, , touchLocation);
	}
}

defaultproperties
{
	DrawType=DT_FluidSurface
	Texture=Texture'Engine_res.S_FluidSurf'

	FluidGridType=FGT_Hexagonal
	FluidGridSpacing=24
	FluidXSize=48
	FluidYSize=48
	FluidHeightScale=1

	FluidSpeed=170
	FluidDamping=0.5

	ShootStrength=-50
	ShootRadius=0
	TouchStrength=-50

	RippleVelocityFactor=-0.05

	UpdateRate=50

	FluidNoiseFrequency=60
	FluidNoiseStrength=(Min=-70,Max=70)

	TestRipple=False
	TestRippleSpeed=3000
	TestRippleStrength=-20
	TestRippleRadius=48
	
	AlphaCurveScale=0
	AlphaHeightScale=10
	AlphaMax=128
	UTiles=1
	UOffset=0
	VTiles=1
	VOffset=0

	bShowBoundingBox=False
	WarmUpTime=2

	FluidColor=(R=0,G=0,B=0,A=0)

	bUnlit=True
	bHidden=False
	bStatic=False
	bNoDelete=True
	bStaticLighting=False	
	bCollideActors=True
	bCollideWorld=False
    bProjTarget=False
	bBlockActors=False
	bBlockNonZeroExtentTraces=True
	bBlockZeroExtentTraces=True
	bBlockPlayers=False
	bWorldGeometry=False
	bEdShouldSnap=True
}