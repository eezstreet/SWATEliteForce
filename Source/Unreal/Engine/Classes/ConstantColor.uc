class ConstantColor extends ConstantMaterial
	native
	editinlinenew;

cpptext
{
	//
	// UConstantMaterial interface
	//
	virtual FColor GetColor(FLOAT TimeSeconds) { return Color; }
}

var() Color Color;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_ConstantColor
//#endif
}