//=============================================================================
// Material: Abstract material class
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Material extends Core.Object
	native
	hidecategories(Object)
	collapsecategories
	noexport;

var() Material FallbackMaterial;

var Material DefaultMaterial;
var const transient bool UseFallback;	// Render device should use the fallback.
var const transient bool Validated;		// Material has been validated as renderable.

#if IG_RENDERER	// rowan: material type enum... lets us do fast casting on materials
// NOTE: THIS MUST BE KEPT IN SYNC WITH DECL IN UNMATERIAL.H
enum EMaterialType
{
	MT_Material,
		// combiner
		MT_Combiner,
		
#if IG_GLOW // glow material type
		MT_GlowMaterial,
		MT_BlurMaterial,
#endif

		// modifiers
		MT_ModifierStart,
		MT_Modifier,
			MT_ColorModifier,
			MT_FinalBlend,
			MT_MaterialSequence,
			MT_MaterialSwitch,
			MT_OpacityModifier,

			// texture modifiers
			MT_TexModifierStart,
			MT_TexModifier,
				MT_TexCoordSource,
				MT_TexEnvMap,
				MT_TexMatrix,
				MT_TexOscillator,
				MT_TexPanner,
				MT_TexRotator,
				MT_TexScaler,
			MT_TexModifierEnd,
		MT_ModifierEnd,

		// rendered materials
		MT_RenderedMaterialStart,
		MT_RenderedMaterial,
			MT_Shader,
			MT_ProjectorMaterial,
			MT_ParticleMaterial,
			MT_TerrainMaterial,
			MT_VertexColor,
			
			// constant materials
			MT_ConstantMaterialStart,
			MT_ConstantMaterial,
				MT_ConstantColor,
				MT_FadeColor,
			MT_ConstantMaterialEnd,

			// bitmap materials
			MT_BitmapMaterialStart,
			MT_BitmapMaterial,
				MT_ScriptedTexture,
				MT_ShadowBitmapMaterial,

				// textures
				MT_TextureStart,
				MT_Texture,
					MT_Cubemap,
				MT_TextureEnd,
			MT_BitmapMaterialEnd,
		MT_RenderedMaterialEnd,

	// henry: for screen buffer effects
	MT_DesaturateMaterial,
};
var const EMaterialType MaterialType;	// NOTE: this has to be an int, so the native impl can use an enum directly
#endif	// IG_RENDERER

#if IG_EFFECTS
//WARNING!  Please do not change or move entries in this enum!
//  ONLY add new MaterialVisualTypes to the END of this list.
//This list should be kept in sync with System/material_visual_types.lst,
//  which is read by the IGEffectsConfigurator.
//This list should also be kept in sync with the same enum declared
//  in UnMaterial.h
enum EMaterialVisualType
{
    MVT_Default,
    MVT_Concrete,
    MVT_Stone,
    MVT_ThinGlass,
    MVT_ThickGlass,
    MVT_ThinCloth,
    MVT_ThickCloth,
    MVT_ThinMetal,
    MVT_ThickMetal,
    MVT_Wood,
    MVT_Plastic,
    MVT_Cardboard,
    MVT_Plaster,
    MVT_Water,
    MVT_Flesh,
    MVT_Carpet,
    MVT_Dirt,
    MVT_WaterPipe,
    MVT_Plant,
    MVT_RedBrick,
    MVT_OpaqueGlass,
	MVT_MetalGrate,
    MVT_Mirror,
    MVT_Roaches,
    MVT_WoodDebris,
    MVT_WoodCharred,
    MVT_SteamPipe,
    MVT_Sky,
    MVT_Electronics
};
//tcohen: these are clasifications of the material for purposes of the effects system
var(MaterialType) int MaterialSoundType;
var(MaterialType) EMaterialVisualType MaterialVisualType;
#endif  //IG_EFFECTS

#if IG_SWAT //tcohen: ballistics
var(Ballistics) float MomentumToPenetrate "A bullet will penetrate this material if-and-only-if it impacts with more than this Momentum.  A bullet's Momentum is its Mass times the MuzzleVelocity of the FiredWeapon from which it was fired, minus any Momentum that the bullet has already lost (due to prior impact(s)).  The bullet will impart 10% of its Momentum to a KActor it hits if it penetrates the KActor, or 100% of its Momentum if it doesn't penetrate the KActor.";
#endif

function Reset()
{
	if( FallbackMaterial != None )
		FallbackMaterial.Reset();
}

function Trigger( Actor Other, Actor EventInstigator )
{
	if( FallbackMaterial != None )
		FallbackMaterial.Trigger( Other, EventInstigator );
}

defaultproperties
{
	FallbackMaterial=None
	DefaultMaterial=Texture'Engine_res.DefaultTexture'

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_Material
//#endif

    MomentumToPenetrate=10000
}
