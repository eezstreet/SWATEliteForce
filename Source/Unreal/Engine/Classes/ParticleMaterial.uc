class ParticleMaterial extends RenderedMaterial
	native
	noteditinlinenew;

struct ParticleProjectorInfo
{
	var bitmapmaterial		BitmapMaterial;
	var matrix				Matrix;
	var int					Projected;
	var int					BlendMode;
};

var const int				ParticleBlending;
var const int				BlendBetweenSubdivisions;
var const int				RenderTwoSided;
var const int				UseTFactor;
var const bitmapmaterial	BitmapMaterial;
var const int				AlphaTest;
var const int				AlphaRef;
var const int				ZTest;
var const int				ZWrite;
var const int				Wireframe;		

var transient bool							AcceptsProjectors;
var transient const int						NumProjectors;
var transient const ParticleProjectorInfo	Projectors[8];

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_ParticleMaterial
//#endif
}