class ColorModifier extends Modifier
	noteditinlinenew
	native;

var() color Color;
var() bool	RenderTwoSided;
var() bool	AlphaBlend;

defaultproperties
{
	Color=(R=255,G=255,B=255,A=255)
	RenderTwoSided=true
	AlphaBlend=true

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_ColorModifier
//#endif
}
