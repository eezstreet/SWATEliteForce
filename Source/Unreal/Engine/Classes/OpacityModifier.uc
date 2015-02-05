//
// OpacityModfifer - used to override a shader's opacity channel (eg for shaders on terrain).
//
class OpacityModifier extends Modifier
	noteditinlinenew
	native;

var Material Opacity;
var bool bOverrideTexModifier;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_OpacityModifier
//#endif
}