class Do_RescueHostages extends SwatGame.Objective_Do
    implements IInterested_GameEvent_MissionStarted,
               IInterested_GameEvent_PawnDied,
               IInterested_GameEvent_PawnIncapacitated,
               IInterested_GameEvent_PawnArrested;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.MissionStarted.Register(self);
    Game.GameEvents.PawnDied.Register(self);
    Game.GameEvents.PawnIncapacitated.Register(self);
    Game.GameEvents.PawnArrested.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.MissionStarted.UnRegister(self);
    Game.GameEvents.PawnDied.UnRegister(self);
    Game.GameEvents.PawnIncapacitated.UnRegister(self);
    Game.GameEvents.PawnArrested.UnRegister(self);
}

// IInterested_GameEvent_MissionStarted Implementation
function OnMissionStarted()
{
    // We should check for completion at mission start, in case there are no
    // enemies in the level.
    CheckComplete();
}

//IInterested_GameEvent_PawnDied Implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
	if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

	// If the person that killed them was a player or otherwise part of the player's responsibility,
	// then we have FAILED the objective because we didn't save as many as possible (we killed one)
	if(Killer.IsA('SwatPlayer') || Killer.IsA('SwatOfficer') || Killer.IsA('SniperPawn'))
	{
		SetStatus(ObjectiveStatus_Failed);
	}
	else
	{
		CheckComplete();
	}
}

//IInterested_GameEvent_PawnIncapacitated Implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
	if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

	if (SwatHostage(Pawn).WasHostageSpawnedIncapacitated())
	    return;                             //they started out that way

	CheckComplete();
}

//IInterested_GameEvent_PawnArrested Implementation
function OnPawnArrested(Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

    CheckComplete();
}

// Completion checking
private function CheckComplete()
{
	local Pawn PawnIter;
    local SwatHostage CurrentHostage;

	//if this is the last hostage, then the objective is complete
	for (PawnIter = Game.Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		CurrentHostage = SwatHostage(PawnIter);

		if ((CurrentHostage != None) && !CurrentHostage.IsArrested() && !CurrentHostage.IsIncapacitated() && !CurrentHostage.IsDead())
        {
            return;                         //we're not done yet
        }
	}

    SetStatus(ObjectiveStatus_Completed);
}
