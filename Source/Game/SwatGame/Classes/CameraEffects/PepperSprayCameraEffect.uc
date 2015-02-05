class PepperSprayCameraEffect extends SwatCameraEffect
    config(SwatEquipment)
	native
	noexport
    dependsOn(PepperSprayEffectParams);

//TMC Note: this must match the size in SwatCameraEffects.h

var protected byte		BlurAlpha;   // from 0 to 255

var private const transient int	  RenderTargets[2];   
var private       transient float LastFrameTime;

var protected float       FadeInTime;   // time to fade in the effect in seconds
var protected float       FadeOutTime;  // time to fade out the effect in seconds

var protected Bool        bBlurTime;      // apply motion blur over time or not.
var protected int         PassOneDivide;  // shrink the video res by this amount compared to the
								          // full screen on the first pass
var protected int         PassTwoDivide;  // shrink the video res by this amount compared to the
								          // full screen on the second pass
var protected float       MaxBlurFrameTime; // max time in seconds for the blur to last (should be around .1 or .2)
var protected vector      GreyColorChooser; // Color use to set the grey level using a dot product with the frame's color
var protected vector      GreyWeight;       // Weighting between blown-out grey and full color

var protected SwatGamePlayerController PlayerController; // used to get some parameters for the effect
var private const transient int noise; // native PerlinNoise object pointer for shifting the frame around

var protected float       ZoomInFraction;  // the frame is zoomed in by this fraction during the effect
var protected float       NoiseAmplitude;  // amplitude of the noise applied to the corners while zoomed in 
                                           // (from 0 to 1, where 1 means motion across the entire image width)
var protected float       NoiseRate;       // Speed of the noise motion on the corners (in noise cycles per second)

var string ParamsClassName;                // Class name for the default parameters class
var private class<PepperSprayEffectParams> ParamsClass;

var protected const transient float       StartTime;   // Native use only
var protected const transient float       Duration;    // Native use only
var protected const transient float       EffectAlpha; // Native use only

function Initialize(SwatGamePlayerController inPlayerController)
{
	// load the defaults class
    local object pclass;
    pclass = DynamicLoadObject(ParamsClassName,class'Class');
    assert(pclass != None);
    ParamsClass = class<PepperSprayEffectParams>(pclass);

    PlayerController = inPlayerController;
}

// Reread the default values every time the effect is run so that the
// parameters can easily be edited interactively.
function OnAdded()
{
	assert(ParamsClass != None);

	BlurAlpha           = ParamsClass.Default.BlurAlpha;
	FadeInTime          = ParamsClass.Default.FadeInTime;
	FadeOutTime         = ParamsClass.Default.FadeOutTime;

	bBlurTime           = ParamsClass.Default.bBlurTime;
	PassOneDivide       = ParamsClass.Default.PassOneDivide;
	PassTwoDivide       = ParamsClass.Default.PassTwoDivide;
	MaxBlurFrameTime    = ParamsClass.Default.MaxBlurFrameTime;
	GreyColorChooser    = ParamsClass.Default.GreyColorChooser;
	GreyWeight          = ParamsClass.Default.GreyWeight;
	ZoomInFraction      = ParamsClass.Default.ZoomInFraction;
	NoiseAmplitude      = ParamsClass.Default.NoiseAmplitude;
	NoiseRate           = ParamsClass.Default.NoiseRate;

	// initialize the LastFrameTime before the effect actually
	// renders a frame so that you won't get a huge
	// deltaT on the first frame. (see SwatCameraEffects.cpp)
	LastFrameTime       = PlayerController.Level.TimeSeconds;
}

defaultproperties
{
	FinalEffect=False

	BlurAlpha=10
	FadeInTime=0.3
	FadeOutTime=2.5
	bBlurTime=True
	PassOneDivide=2
    PassTwoDivide=2
    MaxBlurFrameTime=2
	GreyColorChooser=(X=0.2,Y=0.6,Z=0.4)
	GreyWeight=(X=0.4,Y=0.7,Z=0.8)
	ZoomInFraction=0.1
	NoiseAmplitude=0.1
    NoiseRate=1.
    ParamsClassName="SwatCameraEffects.DesignerPepperSprayParams"
}

