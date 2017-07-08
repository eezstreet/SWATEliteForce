class PepperSprayEffectParams extends Core.Object
   notplaceable
   hidecategories(Object)
   abstract;

var() byte		  BlurAlpha        "Motion blur blending alpha (1-255) - smaller means more blurring" ;
var() float       FadeInTime       "Time to fade in the effect in seconds";
var() float       FadeOutTime      "Time to fade out the effect in seconds";

var() Bool        bBlurTime        "True if you want the motion blur effect (or only the color effect)";
var() int         PassOneDivide    "how much to divide the off-screen rendering resolution by (i.e., 2 means half res)";
var() int         PassTwoDivide    "how much to divide the blur resolution by (i.e., 2 means half res)";   
var() float       MaxBlurFrameTime "Scaling time for blur effect - larger means less blurring, start with .1 and increase This is combined with BlurAlpha for the final blur amount";
var() vector      GreyColorChooser "Set the color for determining what channels to use for the grey scale (e.g., just the red, or a combination). If the channels add up to more than one, the output color will be over-brightened";
var() vector      GreyWeight       "Interpolate between the normal scene color and the grey version on a per channel basis.  This can be used to tint the output.  A value of 1 in a channel will choose 100% of the grey color";
var() float       ZoomInFraction   "Amount to zoom in on the off-screen rendered frame for perlin nopise motion (0-1)";
var() float       NoiseAmplitude   "Amplitude for Perlin noise motion on frame (0-1)";
var() float       NoiseRate        "Rate of Perlin noise motion on frame (in cycles per second, so larger means faster";

defaultproperties
{
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
}

