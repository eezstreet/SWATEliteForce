class Procedure_NoOfficerTased extends SwatGame.Procedure
	implements IInterested_GameEvent_PawnTased;

var config int PenaltyPerInfraction;

var int numInfractions;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnTased.Register(self);

	numInfractions = 0;
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnTased(Pawn Pawn, Actor Taser)
{
    if (!Pawn.IsA('SwatOfficer') && !Pawn.IsA('SwatPlayer')) return;
	if (!Taser.IsA('SwatPlayer')) return;

	numInfractions++;
	TriggerPenaltyMessage(Pawn(Taser));
	GetGame().CampaignStats_TrackPenaltyIssued();
}

function string Status()
{
    return string(numInfractions);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    return PenaltyPerInfraction * numInfractions;
}

function int GetPossible()
{
	return 0;
}