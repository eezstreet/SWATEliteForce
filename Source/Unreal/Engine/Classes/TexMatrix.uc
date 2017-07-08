class TexMatrix extends TexModifier
	native;

cpptext
{
	// UTexModifier interface
	virtual FMatrix* GetMatrix(FLOAT TimeSeconds) { return &Matrix; }
}

var Matrix Matrix;

defaultproperties
{
//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexMatrix
//#endif
}