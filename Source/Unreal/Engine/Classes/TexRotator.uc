class TexRotator extends TexModifier
	editinlinenew
	native;

cpptext
{
	// UTexModifier interface
	virtual FMatrix* GetMatrix(FLOAT TimeSeconds);
	void PostLoad()
	{
		Super::PostLoad();
		//!!OLDVER
		if( ConstantRotation )
		{
			ConstantRotation = 0;
			TexRotationType = TR_ConstantlyRotating;
		}
	}
}

enum ETexRotationType
{
	TR_FixedRotation,
	TR_ConstantlyRotating,
	TR_OscillatingRotation,
};

var Matrix M;
var() ETexRotationType TexRotationType;
var() rotator Rotation;
var deprecated bool ConstantRotation;
var() float UOffset;
var() float VOffset;
var() rotator OscillationRate;
var() rotator OscillationAmplitude;
var() rotator OscillationPhase;

defaultproperties
{
	TexRotationType=TR_FixedRotation

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexRotator
//#endif
}
