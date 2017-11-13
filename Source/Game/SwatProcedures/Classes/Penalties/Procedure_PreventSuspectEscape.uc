class Procedure_PreventSuspectEscape extends SwatGame.Procedure
	implements IInterested_GameEvent_SuspectEscaped;

var config int PenaltyPerEscapee;
var array<SwatPawn> Escaped;

function PostInitHook()
{
    Super.PostInitHook();

	GetGame().GameEvents.SuspectEscaped.Register(self);
}

function string Status()
{
    return string(Escaped.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    return PenaltyPerEscapee * Escaped.length;
}

function OnSuspectEscaped(SwatPawn Who)
{
    Add( Who, Escaped );
	TriggerPenaltyMessage(Who);
	GetGame().CampaignStats_TrackPenaltyIssued();
}
