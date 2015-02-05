class FinalBlend extends Modifier
	showcategories(Material)
	native;

enum EFrameBufferBlending
{
	FB_Overwrite,
	FB_Modulate,
	FB_AlphaBlend,
	FB_AlphaModulate_MightNotFogCorrectly,
	FB_Translucent,
	FB_Darken,
	FB_Brighten,
	FB_Invisible,
	FB_ShadowBlend,
#if IG_SHARED	// rowan: optimised blend mode for shadows
	FB_ShadowBlendOverwrite,
#endif
};

var() EFrameBufferBlending FrameBufferBlending;
var() bool ZWrite;
var() bool ZTest;
var() bool AlphaTest;
var() bool TwoSided;
var() byte AlphaRef;

defaultproperties
{
	FrameBufferBlending=FB_Overwrite
	ZWrite=True
	ZTest=True
	TwoSided=False

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_FinalBlend
//#endif
}
