class Cubemap extends Texture
	native
	noexport;

var() Texture Faces[6];


var transient int	CubemapRenderInterface;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_Cubemap
//#endif
}