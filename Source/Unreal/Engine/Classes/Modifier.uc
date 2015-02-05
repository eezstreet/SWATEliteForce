class Modifier extends Material
	native
	editinlinenew
	hidecategories(Material)
	abstract;

var() editinlineuse Material Material;

function Reset()
{
	if( Material != None )
		Material.Reset();
	if( FallbackMaterial != None )
		FallbackMaterial.Reset();
}

function Trigger( Actor Other, Actor EventInstigator )
{
	if( Material != None )
		Material.Trigger( Other, EventInstigator );
	if( FallbackMaterial != None )
		FallbackMaterial.Trigger( Other, EventInstigator );
}

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_Modifier
//#endif
}