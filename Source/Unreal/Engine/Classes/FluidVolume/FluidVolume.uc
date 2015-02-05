class FluidVolume extends PhysicsVolume
	native;

var (SurfaceTexturing) editinlineuse Cubemap				ReflectionMap;

var (SurfaceColor) byte										Transparency;
var (SurfaceColor) color									BaseColor;
var (SurfaceColor) color									TangentColor;
var (SurfaceColor) color									ReflectionModulator;

var (SurfaceWaves) float									SubdivisionSize;
var (SurfaceWaves) byte										EdgePolyBuffer;
var (SurfaceWaves) float									WaveHeightScaler;
var (SurfaceWaves) float									WaveSpeedScaler;
var (SurfaceWaves) editinlineuse FluidSurfaceParamaters		SurfaceParamaters;

var (SurfaceRipples) editinlineuse Texture					NormalMap;
var (SurfaceRipples) float									RippleScale;
var (SurfaceRipples) byte									RippleStrength;
var (SurfaceRipples) vector									RippleSpeed;

var (SurfaceLowDetail) editinlineuse Texture				Texture;
var (SurfaceLowDetail) float								TextureScale;
var (SurfaceLowDetail) vector								TextureSpeed;	

var const transient private noexport int Interface;	// hidden UFluidVolumeInterface

// these only get called in certain circumstances. need to use ActorEnter, ActorLeaving instead
/*
simulated event Touch(Actor Other)
{
	log("FLUID TOUCHED BY "$Other.Name);
}
simulated event UnTouch(Actor Other)
{
	log("FLUID UNTOUCHED BY "$Other.Name);	
}
*/

// effect events
simulated event ActorEnteredVolume(Actor Other)
{
	Other.TriggerEffectEvent( 'WaterEnter', None, None, Other.Location, Rotator(Other.Velocity));
}

simulated event ActorLeavingVolume(Actor Other)
{
	Other.TriggerEffectEvent( 'WaterLeave', None, None, Other.Location, Rotator(Other.Velocity));	
}

defaultproperties
{
	DrawType = DT_FluidVolume

	bUnlit = true
	bAcceptsProjectors = false

	Transparency = 127
	SubdivisionSize = 512
	WaveHeightScaler = 0.5
	WaveSpeedScaler = 1.0

	BaseColor = (R=0,G=100,B=255,A=0)
	TangentColor = (R=0,G=150,B=200,A=0)
	ReflectionModulator = (R=128,G=128,B=128,A=128)

	RippleScale = 2048
	RippleSpeed = (X=3,Y=3,Z=0)
	RippleStrength = 100

	TextureScale = 512
	TextureSpeed = (X=20,Y=20,Z=0)
	
    bWaterVolume = true
	KBuoyancy=0.9
	FluidFriction=+0.45
}