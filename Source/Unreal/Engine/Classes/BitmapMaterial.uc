class BitmapMaterial extends RenderedMaterial
	abstract
	native
	noexport;

var(TextureFormat) const editconst enum ETextureFormat
{
	TEXF_P8,
	TEXF_RGBA7,
	TEXF_RGB16,
	TEXF_DXT1,
	TEXF_RGB8,
	TEXF_RGBA8,
	TEXF_NODATA,
	TEXF_DXT3,
	TEXF_DXT5,
	TEXF_L8,
	TEXF_G16,
	TEXF_RRRGGGBBB,
#if IG_BUMPMAP	// rowan: compressed normalmap texture format
	TEXF_CxV8U8,
	TEXF_DXT5N,
	TEXF_3DC,
#endif
} Format;

var(Texture) enum ETexClampMode
{
	TC_Wrap,
	TC_Clamp,
#if IG_SHARED	// henry: for border mode texture clamping
	TC_Border,  // extend the texture with a solid border color beyond the UV range
#endif
} UClampMode, VClampMode;

var const byte  UBits, VBits;
var const int   USize, VSize;
var(Texture) const int UClamp "What to do beyond the U 0-1 range: either wrap: wrao around, Clamp: extend the edge pixels, or Border: extend with the border color";
var(Texture) const int VClamp "What to do beyond the V 0-1 range: either wrap: wrao around, Clamp: extend the edge pixels, or Border: extend with the border color";
#if IG_SHARED	// henry: for border mode texture clamping
var(Texture) const Color BorderColor "If the clamp mode is Border, this is the color that will be extended out beyond the bitmap area";
#endif

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_BitmapMaterial
//#endif
}
