class MotionBlur extends CameraEffect
	native
	noexport
	editinlinenew
	collapsecategories;

var() byte		BlurAlpha;

#if IG_MOJO // david: shouldn't be serialised
var native const int	RenderTargets[2];
var native const float	LastFrameTime;
#else
var const int	RenderTargets[2];
var const float	LastFrameTime;
#endif

defaultproperties
{
	BlurAlpha=200
	FinalEffect=False
}
