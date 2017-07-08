class FadeColor extends ConstantMaterial
	native
	editinlinenew;

cpptext
{
	//
	// UConstantMaterial interface
	//
	virtual FColor GetColor(FLOAT TimeSeconds);
}

enum EColorFadeType
{
	FC_Linear,
	FC_Sinusoidal,
};

var() Color Color1;
var() Color Color2;
var() float FadePeriod;
var() float FadePhase;
var() EColorFadeType ColorFadeType;

defaultproperties
{
	ColorFadeType=FC_Linear

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_FadeColor
//#endif
}