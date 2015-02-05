class TerrainMaterial extends RenderedMaterial
	native
	noteditinlinenew;

cpptext
{
	virtual UMaterial* CheckFallback();
	virtual UBOOL HasFallback();
}

struct native TerrainMaterialLayer
{
	var material		Texture;
	var bitmapmaterial	AlphaWeight;
	var matrix			TextureMatrix;
};

var const array<TerrainMaterialLayer> Layers;
#if IG_R // rowan: MacroTexture related
var const Texture	MacroTexture;
var const Matrix	MacroTextureTransform;
var const bool		ForceFogOverride;
#endif
var const byte RenderMethod;
var const bool FirstPass;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TerrainMaterial
//#endif
}