class StingCameraEffect extends SwatCameraEffect
    config(SwatEquipment)
	native
	noexport
    dependson(StingEffectParams);

var protected byte		BlurAlpha;

var private const transient int 	RenderTargets[3];   //TMC Note: this must match the size in SwatCameraEffects.h
var private       transient float	LastFrameTime;

var protected float       FadeInTime;   // time to fade in the effect in seconds
var protected float       FadeOutTime;  // time to fade out the effect in seconds
var protected float       DoubleVisionTime; // time to see double
var protected float       DoubleVisionFadeOutTime; // time to fade out double vision

var protected Bool        bBlurTime;      // apply motion blur over time or not.
var protected int         PassOneDivide;  // shrink the video res by this amount compared to the
								          // full screen on the first pass
var protected int         PassTwoDivide;  // shrink the video res by this amount compared to the
								          // full screen on the second pass
var protected float       MaxBlurFrameTime; // max time in seconds for the blur to last (should be around .1 or .2)

var protected SwatGamePlayerController PlayerController; // used to get some parameters for the effect
var private const transient int noise; // native PerlinNoise object pointer for shifting the frame around

var protected float       ZoomInFraction;  // the frame is zoomed in by this fraction during the effect
var protected float       NoiseAmplitude;  // amplitude of the noise applied to the corners while zoomed in 
                                           // (from 0 to 1, where 1 means motion across the entire image width)
var protected float       NoiseRate;       // Speed of the noise motion on the corners (in noise cycles per second)
var protected float       DoubleVisionNoiseAmplitude;
var protected float       DoubleVisionNoiseRate;

var protected Plane       TintColor;       // Color used to tint the view at the beginning of the effect
var protected float       TintTime;
var protected float       TintFadeOutTime;

var string StingGrenadeParamsClassName;            // Class name for the default parameters class for StingGrenades
var private class<StingEffectParams> StingGrenadeParamsClass;
var string LessLethalShotgunParamsClassName;       // Class name for the default parameters class Less Lethal Shotgun bean bag projectiles
var private class<StingEffectParams> LessLethalShotgunParamsClass;
var string TripleBatonRoundParamsClassName;        // Class name for the default parameters class Triple Baton Round projectiles
var private class<StingEffectParams> TripleBatonRoundParamsClass;
var string DirectGrenadeHitParamsClassName;        // Class name for the default parameters class direct projectile hit
var private class<StingEffectParams> DirectGrenadeHitParamsClass;
var string MeleeAttackParamsClassName;             // Class name for the default parameters class melee attack
var private class<StingEffectParams> MeleeAttackParamsClass;

var protected const transient float       StartTime;         // Native use only
var protected const transient float       Duration;          // Native use only
var protected transient float             EffectAlpha;       // Native use only
var protected transient float             DoubleVisionAlpha; // Native use only
var protected transient float             TintAlpha;         // Native use only

function Initialize(SwatGamePlayerController inPlayerController)
{
	// load the defaults class
    local object pclass;

    pclass = DynamicLoadObject(StingGrenadeParamsClassName, class'Class');
    assert(pclass != None);
    StingGrenadeParamsClass = class<StingEffectParams>(pclass);

    pclass = DynamicLoadObject(LessLethalShotgunParamsClassName, class'Class');
    assert(pclass != None);
    LessLethalShotgunParamsClass = class<StingEffectParams>(pclass);

    pclass = DynamicLoadObject(TripleBatonRoundParamsClassName, class'Class');
    assert(pclass != None);
    TripleBatonRoundParamsClass = class<StingEffectParams>(pclass);

	pclass = DynamicLoadObject(DirectGrenadeHitParamsClassName, class'Class');
    assert(pclass != None);
    DirectGrenadeHitParamsClass = class<StingEffectParams>(pclass);

	pclass = DynamicLoadObject(MeleeAttackParamsClassName, class'Class');
    assert(pclass != None);
    MeleeAttackParamsClass = class<StingEffectParams>(pclass);

    PlayerController = inPlayerController;
}

function OnAdded()
{
	local class<StingEffectParams> ParamsClass;
	assert(StingGrenadeParamsClass      != None);
	assert(LessLethalShotgunParamsClass != None);
	assert(TripleBatonRoundParamsClass	!= None);
	assert(DirectGrenadeHitParamsClass	!= None);
	assert(MeleeAttackParamsClass		!= None);
	assert(PlayerController             != None);


	if (PlayerController != None &&
		SwatPlayer(PlayerController.ViewTarget) != None)
	{
		switch (SwatPlayer(PlayerController.ViewTarget).LastStingWeapon)
		{
			case LessLethalShotgun:
				ParamsClass = LessLethalShotgunParamsClass;
			case TripleBatonRound:
				ParamsClass = TripleBatonRoundParamsClass;
			case DirectGrenadeHit:
				ParamsClass = DirectGrenadeHitParamsClass;
			case MeleeAttack:
				ParamsClass = MeleeAttackParamsClass;
			default:
				ParamsClass = StingGrenadeParamsClass;
		}
	}
	else 
	{
		ParamsClass = StingGrenadeParamsClass;
	}

	BlurAlpha                  = ParamsClass.Default.BlurAlpha;
	FadeInTime                 = ParamsClass.Default.FadeInTime;
	FadeOutTime                = ParamsClass.Default.FadeOutTime;
	DoubleVisionTime           = ParamsClass.Default.DoubleVisionTime;
	DoubleVisionFadeOutTime    = ParamsClass.Default.DoubleVisionFadeOutTime;

	bBlurTime                  = ParamsClass.Default.bBlurTime;
	PassOneDivide              = ParamsClass.Default.PassOneDivide;
	PassTwoDivide              = ParamsClass.Default.PassTwoDivide;
	MaxBlurFrameTime           = ParamsClass.Default.MaxBlurFrameTime;
	ZoomInFraction             = ParamsClass.Default.ZoomInFraction;
	NoiseAmplitude             = ParamsClass.Default.NoiseAmplitude;
	NoiseRate                  = ParamsClass.Default.NoiseRate;
	DoubleVisionNoiseAmplitude = ParamsClass.Default.DoubleVisionNoiseAmplitude;
	DoubleVisionNoiseRate      = ParamsClass.Default.DoubleVisionNoiseRate;

	TintColor                  = ParamsClass.Default.TintColor;
	TintTime                   = ParamsClass.Default.TintTime;
	TintFadeOutTime            = ParamsClass.Default.TintFadeOutTime;
	
	if (PlayerController.Level.TimeSeconds > (StartTime + Duration))
	{
		// initialize the LastFrameTime before the effect actually
		// renders a frame so that you won't get a huge
		// deltaT on the first frame. (see SwatCameraEffects.cpp)
		LastFrameTime              = PlayerController.Level.TimeSeconds;
	}
}


defaultproperties
{
	BlurAlpha=20
	FinalEffect=False

	FadeInTime=0.2
	FadeOutTime=2.5
	DoubleVisionTime=2.5
	DoubleVisionFadeOutTime=.5
	bBlurTime=True
	PassOneDivide=2
    PassTwoDivide=2
    MaxBlurFrameTime=2

	ZoomInFraction=0.1
	NoiseAmplitude=0.1
    NoiseRate=1.
	DoubleVisionNoiseAmplitude=0.25
    DoubleVisionNoiseRate=2.2
	TintColor=(X=1,Y=0.8,Z=0.5,W=1)
	TintTime=.5
	TintFadeOutTime=.25

	StingGrenadeParamsClassName="SwatCameraEffects.DesignerStingParams"
	LessLethalShotgunParamsClassName="SwatCameraEffects.DesignerLessLethalSGParams"
	TripleBatonRoundParamsClassName="SwatCameraEffects2.DesignerTripleBatonRoundParams"
	DirectGrenadeHitParamsClassName="SwatCameraEffects2.DesignerDirectGrenadeHitParams"
	MeleeAttackParamsClassName="SwatCameraEffects2.DesignerMeleeAttackParams"
}
