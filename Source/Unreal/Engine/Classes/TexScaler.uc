class TexScaler extends TexModifier
	editinlinenew
	native;

cpptext
{
	// UTexModifier interface
	virtual FMatrix* GetMatrix(FLOAT TimeSeconds);
}

var Matrix M;
var() float UScale;
var() float VScale;
var() float UOffset;
var() float VOffset;

defaultproperties
{
	UScale=1.0
	VScale=1.0

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexScaler
//#endif
}
