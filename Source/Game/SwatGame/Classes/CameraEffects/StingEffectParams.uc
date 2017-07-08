class StingEffectParams extends Core.Object
   notplaceable
   hidecategories(Object)
   abstract;

var() byte		  BlurAlpha                  "Motion blur blending alpha (1-255) - smaller means more blurring" ;
var() float       FadeInTime                 "Time to fade in the effect in seconds";
var() float       FadeOutTime                "Time to fade out the effect in seconds";
var() float       DoubleVisionTime "Time to show double vision in seconds (can be very large if you want double vision all the time)";
var() float       DoubleVisionFadeOutTime    "Time to fade out double vision";

var() Bool        bBlurTime                  "True if you want the motion blur effect (or only double vision)";
var() int         PassOneDivide              "how much to divide the off-screen rendering resolution by (i.e., 2 means half res)";
var() int         PassTwoDivide              "how much to divide the blur resolution by (i.e., 2 means half res)";   
var() float       MaxBlurFrameTime           "Scaling time for blur effect - larger means less blurring, start with .1 and increase This is combined with BlurAlpha for the final blur amount"; // max time in seconds for the blur to last (should be around .1 or .2)
var() float       ZoomInFraction             "Amount to zoom in on the off-screen rendered frame for perlin nopise motion (0-1)";
var() float       NoiseAmplitude             "Amplitude for Perlin noise motion on frame (0-1)";
var() float       NoiseRate                  "Rate of Perlin noise motion on frame (in cycles per second, so larger means faster";
var() float       DoubleVisionNoiseAmplitude "Perlin noise Amplitude of the double vision"; 
var() float       DoubleVisionNoiseRate      "Perlin noise rate for double vision"; 

var() Plane       TintColor                  "Color used to tint the view at the beginning of the effect";
var() float       TintTime                   "Time to show tinting (must be greater than TintFadeTime)";
var() float       TintFadeOutTime            "Time to fade out the tint effect";

defaultproperties
{
	BlurAlpha=20
	FadeInTime=0.2
	FadeOutTime=2.5
	DoubleVisionTime=2.5
	DoubleVisionFadeOutTime=.5
	bBlurTime=True
	PassOneDivide=2
    PassTwoDivide=2
    MaxBlurFrameTime=2
	ZoomInFraction=0.15
	NoiseAmplitude=0.14
    NoiseRate=1.5
	DoubleVisionNoiseAmplitude=0.25
    DoubleVisionNoiseRate=2.2
	TintColor=(X=1,Y=0.8,Z=0.5,W=1)
	TintTime=.5
	TintFadeOutTime=.25
}

