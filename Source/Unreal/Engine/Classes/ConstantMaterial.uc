class ConstantMaterial extends RenderedMaterial
	editinlinenew
	abstract
	native;

cpptext
{
	//
	// UConstantMaterial interface
	//
	virtual FColor GetColor(FLOAT TimeSeconds) { return FColor(0,0,0,0); }
}

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_ConstantMaterial
//#endif
}