class Procedure_PreventEvidenceDestruction extends SwatGame.Procedure 
	implements IInterested_GameEvent_EvidenceDestroyed;

var config int PenaltyPerEvidence;
var array<IEvidence> DestroyedEvidence;

function PostInitHook()
{
    Super.PostInitHook();

	GetGame().GameEvents.EvidenceDestroyed.Register(self);
}

function string Status()
{
    return string(DestroyedEvidence.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    return PenaltyPerEvidence * DestroyedEvidence.length;
}

function OnEvidenceDestroyed(IEvidence What)
{
    local int i;

    for (i=0; i<DestroyedEvidence.length; ++i)
        if (DestroyedEvidence[i] == What)
            return;

	DestroyedEvidence[DestroyedEvidence.length] = What;
}

defaultproperties
{
	PenaltyPerEvidence=5
}