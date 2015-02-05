interface IInterested_GameEvent_PawnDied;

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat);  //please don't make WasAThreat optional... that would just hide cases where the parameter was forgotten
