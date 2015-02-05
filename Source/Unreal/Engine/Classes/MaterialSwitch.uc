class MaterialSwitch extends Modifier
	editinlinenew
	hidecategories(Modifier)
	native;

cpptext
{
	virtual void PostEditChange();
	virtual UBOOL CheckCircularReferences( TArray<class UMaterial*>& History );
}

var() transient int Current;
var() editinlineuse array<Material> Materials;

function Reset()
{
	Current = 0;
	if( Materials.Length > 0 )
		Material = Materials[0];
	else
		Material = None;

	if( Material != None )
		Material.Reset();
	if( FallbackMaterial != None )
		FallbackMaterial.Reset();
}

#if IG_SHARED
function bool Set(int Index)
{
	if (Index >= 0 && Index < Materials.length)
	{
		Current = Index;
		Material = Materials[Current];
		return true;
	}

	return false;
}
#endif // IG

function Trigger( Actor Other, Actor EventInstigator )
{
	Current++;
	if( Current >= Materials.Length )
		Current = 0;

	if( Materials.Length > 0 )
		Material = Materials[Current];
	else
		Material = None;

	if( Material != None )
		Material.Trigger( Other, EventInstigator );
	if( FallbackMaterial != None )
		FallbackMaterial.Trigger( Other, EventInstigator );
}

defaultproperties
{
	Current=0

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_MaterialSwitch
//#endif
}