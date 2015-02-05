class MaterialSequence extends Modifier
	editinlinenew
	hidecategories(Modifier)
	native;
	
cpptext
{
	virtual void PostEditChange();
	virtual UBOOL CheckCircularReferences( TArray<class UMaterial*>& History );
	virtual void PreSetMaterial(FLOAT TimeSeconds);
	virtual void Serialize(FArchive& Ar);
#if IG_SHARED // ckline: support glow in material sequences
    virtual UBOOL IsGlowMaterial()
    {
	    return (SequenceItems.Num() && SequenceItems(0).Material) ? SequenceItems(0).Material->IsGlowMaterial() : 0;
    }
    virtual UBOOL IsBumpMapped()
    {
	    return (SequenceItems.Num() && SequenceItems(0).Material) ? SequenceItems(0).Material->IsBumpMapped() : 0;
    }
#endif
}

enum EMaterialSequenceAction
{
	MSA_ShowMaterial,
	MSA_FadeToMaterial,
};

struct native MaterialSequenceItem
{
	var() editinlineuse Material Material;
	var() float Time;
	var() EMaterialSequenceAction Action;
};

enum EMaterialSequenceTriggerActon
{
	MSTA_Ignore,
	MSTA_Reset,
	MSTA_Pause,
	MSTA_Stop,
};

var() array<MaterialSequenceItem> SequenceItems;
var() EMaterialSequenceTriggerActon TriggerAction;
var() bool Loop;
var() bool Paused;
var transient float CurrentTime;
var transient float LastTime;
var float TotalTime;

function Reset()
{
	CurrentTime = 0;
	LastTime = 0;
	Paused = default.Paused;
}

function Trigger( Actor Other, Actor EventInstigator )
{
	switch(TriggerAction)
	{
	case MSTA_Reset:
		CurrentTime = 0;
		LastTime = 0;
		break;
	case MSTA_Pause:
		Paused = !Paused;
		break;
	case MSTA_Stop:
		Paused = True;
		break;
	}		
}

defaultproperties
{
	Loop=True
	TriggerAction=MSTA_Ignore

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_MaterialSequence
//#endif
}