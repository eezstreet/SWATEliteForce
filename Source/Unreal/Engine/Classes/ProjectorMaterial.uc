class ProjectorMaterial extends RenderedMaterial
	native
	noteditinlinenew;

var const transient BitmapMaterial	Gradient;
var const transient Material		Projected,
									BaseMaterial;
var const transient byte			BaseMaterialBlending,
									FrameBufferBlending;
var const transient Matrix			Matrix,
									GradientMatrix;
var const transient bool			bProjected,
									bProjectOnUnlit,
									bGradient,
									bProjectOnAlpha,
									bProjectOnBackfaces,
									bStaticProjector,
									bTwoSided;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_ProjectorMaterial
//#endif
}