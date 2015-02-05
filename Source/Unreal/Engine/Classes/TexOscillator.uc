class TexOscillator extends TexModifier
	editinlinenew
	native;

cpptext
{
	// UTexModifier interface
	virtual FMatrix* GetMatrix(FLOAT TimeSeconds);
	// UObject interface
	virtual void PostEditChange();
}

enum ETexOscillationType
{
	OT_Pan,
	OT_Stretch,
	OT_StretchRepeat,
	OT_Jitter
};

var() Float UOscillationRate;
var() Float VOscillationRate;
var() Float UOscillationPhase;
var() Float VOscillationPhase;
var() Float UOscillationAmplitude;
var() Float VOscillationAmplitude;
var() ETexOscillationType UOscillationType;
var() ETexOscillationType VOscillationType;
var() float UOffset;
var() float VOffset;

var Matrix M;

// current state for OT_Jitter.
var float LastSu;
var float LastSv;
var float CurrentUJitter;
var float CurrentVJitter;

defaultproperties
{
	UOscillationRate=1
	VOscillationRate=1
	UOscillationAmplitude=0.1
	VOscillationAmplitude=0.1
	UOscillationType=OT_Pan
	VOscillationType=OT_Pan

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexOscillator
//#endif
}
