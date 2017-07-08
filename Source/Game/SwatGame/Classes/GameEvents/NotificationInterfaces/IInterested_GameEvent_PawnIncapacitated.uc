interface IInterested_GameEvent_PawnIncapacitated;

function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat);  //please don't make WasAThreat optional... that would just hide cases where the parameter was forgotten
